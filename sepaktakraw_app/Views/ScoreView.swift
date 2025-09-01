//
//  ScoreView.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/14.
//

import SwiftUI
import SwiftData

// MARK: - Enums

/// ラリーの進行段階を定義（フローチャートに対応）
enum RallyStage {
    case serving        // サーブ段階
    case receiving      // レシーブ段階
    case setting        // セット段階
    case attacking      // アタック段階
    case blocking       // ブロック段階
    case gameEnd        // ゲーム終了
}

/// ゲーム状態の詳細管理
enum GameState {
    case rally          // ラリー中
    case setFinished    // セット終了
    case gameFinished   // ゲーム終了
}

// MARK: - 詳細選択状態
enum DetailSelectionState {
    case none
    case serveType      // サーブタイプ選択
    case setFailureReason  // セット失敗理由選択
    case attackOutcome  // アタック結果選択
}

// MARK: - Main View

/// セパタクロー試合のスコア記録画面（フローチャート対応版）
struct ScoreView: View {
    // MARK: - State Properties
    
    @StateObject private var viewModel: ScoreViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingResetAlert = false
    @Bindable var selectedMatch: Match
    @State private var selectedPlayer: Player?
    @State private var gameState: GameState = .rally
    @State private var detailSelectionState: DetailSelectionState = .none
    @State private var pendingServeSuccess: Bool = false
    @State private var pendingSetFailure: Bool = false
    @State private var pendingAttackChoice: AttackChoice? = nil
    
    // MARK: - Initialization
    
    init(match: Match) {
        _selectedMatch = Bindable(wrappedValue: match)
        _viewModel = StateObject(wrappedValue: ScoreViewModel(teamAServesFirst: match.teamAServesFirst))
    }
    
    // MARK: - Computed Properties
    
    private var teamA: Team {
        guard let team = selectedMatch.teamA else {
            fatalError("Team A is nil in selected match. Match data may be corrupted.")
        }
        return team
    }
    
    private var teamB: Team {
        guard let team = selectedMatch.teamB else {
            fatalError("Team B is nil in selected match. Match data may be corrupted.")
        }
        return team
    }
    
    private var servingTeam: Team { viewModel.isServeA ? teamA : teamB }
    private var receivingTeam: Team { viewModel.isServeA ? teamB : teamA }
    
    private var currentActionTeam: Team {
        switch rallyStage {
        case .serving:
            return servingTeam
        case .receiving, .setting, .attacking:
            return receivingTeam
        case .blocking:
            return servingTeam
        case .gameEnd:
            return servingTeam
        }
    }
    
    private var currentTeamColor: Color { currentActionTeam.color }
    private var rallyStage: RallyStage { viewModel.rallyStage }

    // MARK: - Body
    
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let isLandscape = geometry.size.width > geometry.size.height
                let isCompact = geometry.size.width < 700
                
                if isLandscape && !isCompact {
                    landscapeLayout
                } else {
                    portraitLayout(geometry: geometry)
                }
            }
            .navigationTitle("Rally Scorer")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                autoSelectPlayer(for: rallyStage)
            }
            .onChange(of: rallyStage) { _, newStage in
                DispatchQueue.main.async {
                    autoSelectPlayer(for: newStage)
                    detailSelectionState = .none
                }
            }
            .onChange(of: viewModel.isServeA) { _, newIsServeA in
                if rallyStage == .serving {
                    DispatchQueue.main.async {
                        autoSelectPlayer(for: .serving)
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            viewModel.undo()
                            autoSelectPlayer(for: viewModel.rallyStage)
                            detailSelectionState = .none
                        }) {
                            Image(systemName: "arrow.uturn.backward")
                        }
                        .disabled(!viewModel.canUndo)
                    }
                }
            }
            .alert("リセット確認", isPresented: $isShowingResetAlert) {
                Button("リセット", role: .destructive) {
                    viewModel.resetGame()
                    DispatchQueue.main.async {
                        autoSelectPlayer(for: viewModel.rallyStage)
                        detailSelectionState = .none
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("本当にゲームをリセットしますか？この操作は元に戻せません。")
            }
        }
    }
    
    // MARK: - Layout Views
    
    @ViewBuilder
    private var landscapeLayout: some View {
        HStack(spacing: 16) {
            VStack(spacing: 12) {
                scoreSection
                    .frame(height: 200)
                
                timelineSection
                    .frame(height: 120)
                
                Spacer()
            }
            .frame(maxWidth: 400)
            
            VStack(spacing: 16) {
                currentStageSection
                    .frame(maxHeight: 80)
                
                playerSelectionSection
                    .frame(height: 160)
                
                inlineActionSelectionSection
                    .frame(height: 140)
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View {
        let availableHeight = geometry.size.height - 150
        let isVeryCompact = geometry.size.height < 700
        
        VStack(spacing: isVeryCompact ? 6 : 10) {
            scoreSection
                .frame(height: isVeryCompact ? 120 : 160)
                .padding(.horizontal, 12)
            
            timelineSection
                .frame(height: isVeryCompact ? 140 : 150)
                .padding(.horizontal, 12)
            
            currentStageSection
                .frame(height: isVeryCompact ? 40 : 50)
                .padding(.horizontal, 12)
            
            playerSelectionSection
                .frame(height: isVeryCompact ? 110 : 130)
                .padding(.horizontal, 8)
            
            inlineActionSelectionSection
                .frame(height: isVeryCompact ? 120 : 130)
                .padding(.horizontal, 8)
            
            Spacer(minLength: 0)
        }
        .padding(.top, 8)
        .frame(maxHeight: availableHeight)
    }
    
    // MARK: - UI Sections
    
    @ViewBuilder
    private var scoreSection: some View {
        ScoreDisplaySection(viewModel: viewModel, teamA: teamA, teamB: teamB)
    }
    
    @ViewBuilder
    private var timelineSection: some View {
        ScoreTimelineView(
            teamA: teamA,
            teamB: teamB,
            scoreEvents: viewModel.scoreEvents
        )
    }
    
    @ViewBuilder
    private var currentStageSection: some View {
        CurrentStageSection(
            rallyStage: rallyStage,
            currentActionTeam: currentActionTeam,
            currentTeamColor: currentTeamColor
        )
    }
    
    @ViewBuilder
    private var playerSelectionSection: some View {
        PlayerSelectionSection(
            viewModel: viewModel,
            selectedPlayer: $selectedPlayer,
            currentActionTeam: currentActionTeam,
            currentTeamColor: currentTeamColor
        )
    }
    
    // MARK: - インラインアクション選択セクション
    
    @ViewBuilder
    private var inlineActionSelectionSection: some View {
        VStack(spacing: 8) {
            Text("アクション選択")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            switch rallyStage {
            case .serving:
                serveActionSelection
                
            case .receiving:
                receiveActionSelection
                
            case .setting:
                setActionSelection
                
            case .attacking:
                attackActionSelection
                
            case .blocking:
                blockActionSelection
                
            case .gameEnd:
                gameEndDisplay
            }
        }
    }
    
    // MARK: - サーブアクション選択
    
    @ViewBuilder
    private var serveActionSelection: some View {
        VStack(spacing: 8) {
            if detailSelectionState == .serveType {
                // サーブタイプ選択
                Text("サーブタイプを選択")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ActionButton(
                        title: "通常サーブ",
                        systemImage: "arrow.up.circle",
                        color: .blue,
                        action: { handleServeType(.normal) }
                    )
                    
                    ActionButton(
                        title: "フェイントサーブ",
                        systemImage: "eye.slash.circle",
                        color: .purple,
                        action: { handleServeType(.feint) }
                    )
                }
            } else {
                // 成功/失敗選択
                HStack(spacing: 12) {
                    ActionButton(
                        title: "成功",
                        systemImage: "checkmark.circle",
                        color: .green,
                        action: {
                            pendingServeSuccess = true
                            detailSelectionState = .serveType
                        }
                    )
                    
                    ActionButton(
                        title: "失敗",
                        systemImage: "xmark.circle",
                        color: .red,
                        action: {
                            pendingServeSuccess = false
                            processRallyEvent(type: .serve, isSuccess: false, reason: .fault)
                        }
                    )
                }
            }
        }
    }
    
    // MARK: - レシーブアクション選択
    
    @ViewBuilder
    private var receiveActionSelection: some View {
        HStack(spacing: 12) {
            ActionButton(
                title: "成功",
                systemImage: "checkmark.circle",
                color: .green,
                action: { processRallyEvent(type: .receive, isSuccess: true) }
            )
            
            ActionButton(
                title: "失敗",
                systemImage: "xmark.circle",
                color: .red,
                action: { processRallyEvent(type: .receive, isSuccess: false, reason: .fault) }
            )
        }
    }
    
    // MARK: - セットアクション選択
    
    @ViewBuilder
    private var setActionSelection: some View {
        VStack(spacing: 8) {
            if detailSelectionState == .setFailureReason {
                // 失敗理由選択
                Text("失敗理由を選択")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ActionButton(
                        title: "オーバーセット",
                        systemImage: "arrow.up.circle",
                        color: .orange,
                        action: { handleSetFailure(.overSet) }
                    )
                    
                    ActionButton(
                        title: "チャンスボール",
                        systemImage: "circle.dotted",
                        color: .blue,
                        action: { handleSetFailure(.chanceBall) }
                    )
                }
            } else {
                // 成功/失敗選択
                HStack(spacing: 12) {
                    ActionButton(
                        title: "成功",
                        systemImage: "checkmark.circle",
                        color: .green,
                        action: { processRallyEvent(type: .setting, isSuccess: true) }
                    )
                    
                    ActionButton(
                        title: "失敗",
                        systemImage: "xmark.circle",
                        color: .red,
                        action: { detailSelectionState = .setFailureReason }
                    )
                }
            }
        }
    }
    
    // MARK: - アタックアクション選択
    
    @ViewBuilder
    private var attackActionSelection: some View {
        VStack(spacing: 8) {
            if detailSelectionState == .attackOutcome, let attackChoice = pendingAttackChoice {
                // アタック結果の詳細選択
                attackOutcomeSelection(for: attackChoice)
            } else {
                // 基本3択
                HStack(spacing: 8) {
                    ActionButton(
                        title: "得点",
                        systemImage: "star.circle",
                        color: .green,
                        action: {
                            pendingAttackChoice = .point
                            detailSelectionState = .attackOutcome
                        }
                    )
                    
                    ActionButton(
                        title: "相手得点",
                        systemImage: "minus.circle",
                        color: .red,
                        action: {
                            pendingAttackChoice = .opponentPoint
                            detailSelectionState = .attackOutcome
                        }
                    )
                    
                    ActionButton(
                        title: "ラリー継続",
                        systemImage: "arrow.clockwise.circle",
                        color: .blue,
                        action: {
                            pendingAttackChoice = .rallyContinue
                            detailSelectionState = .attackOutcome
                        }
                    )
                }
            }
        }
    }
    
    @ViewBuilder
    private func attackOutcomeSelection(for choice: AttackChoice) -> some View {
        VStack(spacing: 8) {
            Text(getAttackOutcomeTitle(for: choice))
                .font(.caption)
                .foregroundColor(.secondary)
            
            switch choice {
                    case .point:
                        // 得点の場合のアタックタイプ選択 - 2×2レイアウト
                        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
                            ActionButton(
                                title: "通常アタック",
                                systemImage: "arrow.clockwise",
                                color: .green,
                                action: { handleAttackPoint(.attack) }
                            )
                            
                            ActionButton(
                                title: "フェイント",
                                systemImage: "eye.slash",
                                color: .green,
                                action: { handleAttackPoint(.attack_feint) }
                            )
                            ActionButton(
                                title: "ヘディング",
                                systemImage: "person.circle",
                                color: .green,
                                action: { handleAttackPoint(.heading) }
                            )
                            ActionButton(
                                title: "ネットタッチ・オーバー",
                                systemImage: "scissors",
                                color: .green,
                                action: { handleAttackFailure(.fault) }
                            )
                        }
                
            case .opponentPoint:
                // 相手得点の場合の失敗理由選択
                HStack(spacing: 6) {
                    ActionButton(
                        title: "アウト",
                        systemImage: "arrow.up.circle",
                        color: .red,
                        action: { handleAttackFailure(.out) }
                    )
                    ActionButton(
                        title: "ネット",
                        systemImage: "network",
                        color: .red,
                        action: { handleAttackFailure(.net) }
                    )
                    ActionButton(
                        title: "ネットタッチ・オーバー",
                        systemImage: "xmark.circle",
                        color: .red,
                        action: { handleAttackFailure(.fault) }
                    )
                }
                
            case .rallyContinue:
                // ラリー継続の場合の選択
                HStack(spacing: 8) {
                    ActionButton(
                        title: "ブロックされた",
                        systemImage: "shield.circle",
                        color: .blue,
                        action: { handleAttackBlocked() }
                    )
                    ActionButton(
                        title: "レシーブされた",
                        systemImage: "arrow.down.circle",
                        color: .cyan,
                        action: { handleAttackReceived() }
                    )
                }
            }
        }
    }
    
    // MARK: - ブロックアクション選択
    
    @ViewBuilder
    private var blockActionSelection: some View {
        HStack(spacing: 8) {
            ActionButton(
                title: "ブロック\nカバーした",
                systemImage: "arrow.clockwise.circle",
                color: .green,
                action: { processBlockCover() }
            )
            
            ActionButton(
                title: "相手に拾われた",
                systemImage: "arrow.right.circle",
                color: .blue,
                action: { processBlockToReceive() }
            )
        }
    }
    
    @ViewBuilder
    private var gameEndDisplay: some View {
        Text("ゲーム終了")
            .font(.title2)
            .fontWeight(.bold)
            .foregroundColor(.primary)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }
    
    // MARK: - 攻守交代処理
        
        /// ラリー内で攻守を交代してレシーブ段階に移行（サーブ権は維持）
        private func switchServeAndReceive() {
            print("🔄 Manual attack/defense switch initiated")
            
            // サーブ権は変更せず、レシーブ段階に設定
            viewModel.rallyStage = .receiving
            
            // イベントログに記録（任意）
            viewModel.scoreEvents.append(ScoreEvent(
                scoreA: viewModel.scoreA,
                scoreB: viewModel.scoreB,
                scoringTeam: viewModel.isServeA ? "A" : "B",
                timestamp: Date(),
                playerName: "Rally Switch",
                actionType: .receive,
                isSuccess: true,
                hasServeRight: viewModel.isServeA
            ))
            
            // プレイヤー選択をリセット
            DispatchQueue.main.async {
                self.autoSelectPlayer(for: .receiving)
            }
            
            print("🔄 Rally switched to receiving stage")
            print("🔄 Serve right remains with team: \(viewModel.isServeA ? "A" : "B")")
        }

    
    // MARK: - アクション処理メソッド
    
    private func handleServeType(_ type: ServeType) {
        let statType: StatType = (type == .normal) ? .serve : .serve_feint
        processRallyEvent(type: statType, isSuccess: pendingServeSuccess)
        detailSelectionState = .none
    }
    
    private func handleSetFailure(_ reason: FailureReason) {
        processSetFailureWithReceive(reason: reason)
        detailSelectionState = .none
    }
    
    private func handleAttackPoint(_ attackType: StatType) {
        processRallyEvent(type: attackType, isSuccess: true)
        resetAttackState()
    }
    
    private func handleAttackFailure(_ reason: FailureReason) {
        processRallyEvent(type: .attack, isSuccess: false, reason: reason)
        resetAttackState()
    }
    
    private func handleAttackBlocked() {
        viewModel.rallyStage = .blocking
        resetAttackState()
    }
    
    private func handleAttackReceived() {
        processAttackReceivedInternal()
        resetAttackState()
    }
    
    private func resetAttackState() {
        detailSelectionState = .none
        pendingAttackChoice = nil
    }
    
    private func getAttackOutcomeTitle(for choice: AttackChoice) -> String {
        switch choice {
        case .point:
            return "アタックタイプを選択"
        case .opponentPoint:
            return "失敗理由を選択"
        case .rallyContinue:
            return "継続理由を選択"
        }
    }
    
    // MARK: - Helper Functions
    
    private func autoSelectPlayer(for stage: RallyStage) {
        DispatchQueue.main.async {
            switch stage {
            case .serving:
                let server = self.servingTeam.players.first { $0.position == .tekong }
                self.selectedPlayer = server
                
            case .receiving:
                self.selectedPlayer = nil
                
            case .setting:
                let feeder = self.receivingTeam.players.first { $0.position == .feeder }
                self.selectedPlayer = feeder
                
            case .attacking:
                let striker = self.receivingTeam.players.first { $0.position == .striker }
                self.selectedPlayer = striker
                
            case .blocking:
                self.selectedPlayer = nil
                
            case .gameEnd:
                self.selectedPlayer = nil
            }
        }
    }
    
    private func processRallyEvent(type: StatType, isSuccess: Bool, reason: FailureReason? = nil) {
        guard let player = selectedPlayer else {
            if type == .serve || type == .serve_feint {
                if let server = servingTeam.players.first(where: { $0.position == .tekong }) {
                    processRallyEventInternal(player: server, type: type, isSuccess: isSuccess, reason: reason)
                }
            }
            return
        }
        processRallyEventInternal(player: player, type: type, isSuccess: isSuccess, reason: reason)
    }

    private func processRallyEventInternal(player: Player, type: StatType, isSuccess: Bool, reason: FailureReason? = nil) {
        let stat = Stat(type: type, isSuccess: isSuccess, failureReason: reason)
        player.addStat(stat)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving model context: \(error)")
        }
        
        viewModel.processRallyEvent(
            player: player,
            type: type,
            isSuccess: isSuccess,
            reason: reason
        )
    }
    
    private func processSetFailureWithReceive(reason: FailureReason) {
        guard selectedPlayer != nil else { return }
        
        processRallyEvent(type: .setting, isSuccess: false, reason: reason)
        
        DispatchQueue.main.async {
            if reason == .overSet || reason == .chanceBall {
                viewModel.rallyStage = .receiving
            }
        }
    }
    
    private func processAttackReceivedInternal() {
        guard let player = selectedPlayer else { return }
        
        let stat = Stat(type: .rollspike, isSuccess: false, failureReason: .received)
        player.addStat(stat)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving model context: \(error)")
        }
        
        viewModel.processAttackReceived(player: player, originalStat: stat)
    }
    
    private func processBlockCover() {
        guard let player = selectedPlayer else { return }
        
        let stat = Stat(type: .rollspike, isSuccess: false, failureReason: .blockCover)
        player.addStat(stat)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving model context: \(error)")
        }
        
        viewModel.processBlockCover(player: player, originalStat: stat)
    }
    
    private func processBlockToReceive() {
        guard let player = selectedPlayer else { return }
        
        let stat = Stat(type: .rollspike, isSuccess: false, failureReason: .blocked)
        player.addStat(stat)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving model context: \(error)")
        }
        
        viewModel.isServeA.toggle()
        viewModel.rallyStage = .receiving
        
        viewModel.scoreEvents.append(ScoreEvent(
            scoreA: viewModel.scoreA,
            scoreB: viewModel.scoreB,
            scoringTeam: viewModel.isServeA ? "A" : "B",
            timestamp: Date(),
            playerName: player.name,
            actionType: .rollspike,
            isSuccess: false,
            hasServeRight: viewModel.isServeA
        ))
    }
}

// MARK: - 追加定義

enum ServeType {
    case normal, feint
}

enum AttackChoice {
    case point, opponentPoint, rallyContinue
}

// MARK: - Helper Views

struct PlayerSelectionButton: View {
    let player: Player
    let positionName: String
    let selectionColor: Color
    let isSelected: Bool
    let isSelectable: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(positionName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .fontWeight(.medium)
                
                Text(player.name)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .foregroundColor(isSelectable ? .primary : .secondary)
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(selectionColor)
                        .font(.caption)
                } else {
                    Image(systemName: "circle")
                        .foregroundColor(isSelectable ? .gray : .gray.opacity(0.5))
                        .font(.caption)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(8)
            .background(
                isSelected ?
                selectionColor.opacity(0.15) :
                (isSelectable ? Color.gray.opacity(0.05) : Color.gray.opacity(0.02))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(
                        isSelected ? selectionColor :
                        (isSelectable ? Color.gray.opacity(0.3) : Color.gray.opacity(0.15)),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(!isSelectable)
    }
}

struct ActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 50)
            .padding(8)
            .background(color.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Preview

#Preview {
    @Previewable @State var previewMatch: Match? = nil
    @Previewable @State var previewContainer: ModelContainer? = nil
    
    Group {
        if let match = previewMatch, let container = previewContainer {
            ScoreView(match: match)
                .modelContainer(container)
        } else {
            ProgressView("Loading...")
        }
    }
    .task {
        let container = try! ModelContainer(
            for: Team.self, Match.self, Player.self,
            configurations: ModelConfiguration(isStoredInMemoryOnly: true)
        )
        
        let context = container.mainContext
        
        let teamA = Team(name: "チーム A", color: .blue)
        let teamB = Team(name: "チーム B", color: .red)
        
        let playerA1 = Player(name: "選手A1", position: .tekong, team: teamA)
        let playerA2 = Player(name: "選手A2", position: .feeder, team: teamA)
        let playerA3 = Player(name: "選手A3", position: .striker, team: teamA)
        
        let playerB1 = Player(name: "選手B1", position: .tekong, team: teamB)
        let playerB2 = Player(name: "選手B2", position: .feeder, team: teamB)
        let playerB3 = Player(name: "選手B3", position: .striker, team: teamB)
        
        teamA.players = [playerA1, playerA2, playerA3]
        teamB.players = [playerB1, playerB2, playerB3]
        
        let match = Match(date: Date(), teamA: teamA, teamB: teamB, teamAServesFirst: true)
        
        context.insert(teamA)
        context.insert(teamB)
        context.insert(playerA1)
        context.insert(playerA2)
        context.insert(playerA3)
        context.insert(playerB1)
        context.insert(playerB2)
        context.insert(playerB3)
        context.insert(match)
        
        try! context.save()
        
        previewMatch = match
        previewContainer = container
    }
}
