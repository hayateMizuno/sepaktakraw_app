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
    @Environment(\.presentationMode) var presentationMode // 戻る処理用
    @State private var isShowingResetAlert = false
    @State private var isShowingRallyChangeAlert = false
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
        // ✨ 修正: ViewModelの初期化時にmatchIDを渡す
        _viewModel = StateObject(wrappedValue: ScoreViewModel(teamAServesFirst: match.teamAServesFirst, matchID: match.id))
    }
    
    // MARK: - Computed Properties
    
    private var teamAInfo: Team {
        guard let team = selectedMatch.teamA else { fatalError("Team A is nil in selected match.") }
        return team
    }
    
    private var teamBInfo: Team {
        guard let team = selectedMatch.teamB else { fatalError("Team B is nil in selected match.") }
        return team
    }
    
    private var playersA: [Player] { selectedMatch.participatingPlayersA }
    private var playersB: [Player] { selectedMatch.participatingPlayersB }
    
    private var servingTeamInfo: Team { viewModel.isServeA ? teamAInfo : teamBInfo }
    private var servingTeamPlayers: [Player] { viewModel.isServeA ? playersA : playersB }
    
    private var receivingTeamInfo: Team { viewModel.isServeA ? teamBInfo : teamAInfo }
    private var receivingTeamPlayers: [Player] { viewModel.isServeA ? playersB : playersA }
    
    private var currentActionTeamInfo: Team {
        switch rallyStage {
        case .serving: return servingTeamInfo
        case .receiving, .setting, .attacking: return viewModel.rallyFlowReversed ? servingTeamInfo : receivingTeamInfo
        case .blocking: return viewModel.rallyFlowReversed ? receivingTeamInfo : servingTeamInfo
        case .gameEnd: return servingTeamInfo
        }
    }
    
    private var currentActionTeamPlayers: [Player] {
        switch rallyStage {
        case .serving: return servingTeamPlayers
        case .receiving, .setting, .attacking: return viewModel.rallyFlowReversed ? servingTeamPlayers : receivingTeamPlayers
        case .blocking: return viewModel.rallyFlowReversed ? receivingTeamPlayers : servingTeamPlayers
        case .gameEnd: return servingTeamPlayers
        }
    }
    
    private var currentTeamColor: Color { currentActionTeamInfo.color }
    private var rallyStage: RallyStage { viewModel.rallyStage }
    
    private var canChangeRally: Bool {
        return rallyStage == .receiving || rallyStage == .setting || rallyStage == .attacking
    }
    
    // MARK: - Body
    
    var body: some View {
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
        .navigationBarBackButtonHidden(true) // 標準の戻るボタンを非表示
        .onAppear { autoSelectPlayer(for: rallyStage) }
        .onChange(of: rallyStage) { _, newStage in autoSelectPlayer(for: newStage) }
        .onChange(of: viewModel.isServeA) { _, _ in if rallyStage == .serving { autoSelectPlayer(for: .serving) } }
        .toolbar {
            // ✨ 追加: カスタムの「戻る」ボタンを配置
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }) {
                    Image(systemName: "chevron.left")
                    Text("試合設定")
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 12) {
                    if canChangeRally {
                        Button(action: { isShowingRallyChangeAlert = true }) {
                            Image(systemName: "arrow.left.arrow.right.circle").foregroundColor(.orange)
                        }
                    }
                    Button(action: {
                        viewModel.undo()
                        autoSelectPlayer(for: viewModel.rallyStage)
                        detailSelectionState = .none
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                    }.disabled(!viewModel.canUndo)
                    
                    Button(action: { isShowingResetAlert = true }) {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        .alert("リセット確認", isPresented: $isShowingResetAlert) {
            Button("リセット", role: .destructive) {
                viewModel.resetGame()
                autoSelectPlayer(for: viewModel.rallyStage)
                detailSelectionState = .none
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("本当にゲームをリセットしますか？この操作は元に戻せません。")
        }
        .alert("ラリー変更確認", isPresented: $isShowingRallyChangeAlert) {
            Button("変更", role: .destructive) {
                switchServeAndReceive()
            }
            Button("キャンセル", role: .cancel) {}
        } message: {
            Text("攻守を交代してラリーを継続しますか？\n（\(currentActionTeamInfo.name) → \(currentActionTeamInfo.id == teamAInfo.id ? teamBInfo.name : teamAInfo.name)）")
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
                
                if canChangeRally {
                    rallyChangeSection
                        .frame(height: 50)
                }
                
                Spacer()
                
                inlineActionSelectionSection
                    .frame(height: 140)
                
                Spacer(minLength: 20)
            }
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
    }
    
    @ViewBuilder
    private func portraitLayout(geometry: GeometryProxy) -> some View {
        let isVeryCompact = geometry.size.height < 700
        let isExtraCompact = geometry.size.height < 600
        
        VStack(spacing: isExtraCompact ? 4 : (isVeryCompact ? 6 : 8)) {
            scoreSection
                .frame(height: isExtraCompact ? 100 : (isVeryCompact ? 120 : 160))
                .padding(.horizontal, 12)
            
            timelineSection
                .frame(height: isExtraCompact ? 120 : (isVeryCompact ? 140 : 150))
                .padding(.horizontal, 12)
            
            currentStageSection
                .frame(height: isExtraCompact ? 35 : (isVeryCompact ? 40 : 50))
                .padding(.horizontal, 12)
            
            playerSelectionSection
                .frame(height: isExtraCompact ? 90 : (isVeryCompact ? 110 : 130))
                .padding(.horizontal, 8)
            
            if canChangeRally {
                rallyChangeSection
                    .frame(height: isExtraCompact ? 35 : (isVeryCompact ? 40 : 45))
                    .padding(.horizontal, 8)
            }
            
            if !isExtraCompact {
                Spacer(minLength: 10)
            }
            
            inlineActionSelectionSection
                .frame(height: isExtraCompact ? 100 : (isVeryCompact ? 120 : 130))
                .padding(.horizontal, 8)
            
            Spacer(minLength: isExtraCompact ? 5 : 10)
        }
        .padding(.top, 4)
        .frame(maxWidth: .infinity)
    }
    
    // MARK: - UI Sections
    
    @ViewBuilder
    private var scoreSection: some View {
        // ✨ 修正: チーム情報を渡す
        ScoreDisplaySection(viewModel: viewModel, teamA: teamAInfo, teamB: teamBInfo)
    }
    
    @ViewBuilder
    private var timelineSection: some View {
        // ✨ 修正: チーム情報を渡す
        ScoreTimelineView(teamA: teamAInfo, teamB: teamBInfo, scoreEvents: viewModel.scoreEvents)
    }
    
    @ViewBuilder
    private var currentStageSection: some View {
        // ✨ 修正: `currentActionTeam` -> `currentActionTeamInfo`
        CurrentStageSection(rallyStage: rallyStage, currentActionTeam: currentActionTeamInfo, currentTeamColor: currentTeamColor)
    }
    
    @ViewBuilder
    private var playerSelectionSection: some View {
        // ✨ 修正: Playerリストを渡す
        PlayerSelectionSection(
            viewModel: viewModel,
            selectedPlayer: $selectedPlayer,
            // ✨ 修正: currentActionTeamPlayers を渡すように変更
            playersForSelection: currentActionTeamPlayers,
            currentTeamColor: currentTeamColor
        )
    }
    
    @ViewBuilder
    private var rallyChangeSection: some View {
        VStack(spacing: 4) {
            Text("ラリー変更")
                .font(.caption2)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            Button(action: { isShowingRallyChangeAlert = true }) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.left.arrow.right.circle")
                        .foregroundColor(.orange)
                        .font(.title3)
                    
                    Text("攻守交代")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    Text("(\(currentActionTeamInfo.name) → \(currentActionTeamInfo == teamAInfo ? teamBInfo.name : teamAInfo.name))")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                )
                .cornerRadius(8)
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
    
    @ViewBuilder
    private var inlineActionSelectionSection: some View {
        VStack(spacing: 8) {
            Text("アクション選択")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            switch rallyStage {
            case .serving:      serveActionSelection
            case .receiving:    receiveActionSelection
            case .setting:      setActionSelection
            case .attacking:    attackActionSelection
            case .blocking:     blockActionSelection
            case .gameEnd:      gameEndDisplay
            }
        }
    }
    
    // MARK: - Action Selections
    
    @ViewBuilder
    private var serveActionSelection: some View {
        VStack(spacing: 8) {
            if detailSelectionState == .serveType {
                Text("サーブタイプを選択")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    ActionButton(title: "通常サーブ", systemImage: "arrow.up.circle", color: .blue) { handleServeType(.normal) }
                    ActionButton(title: "フェイントサーブ", systemImage: "eye.slash.circle", color: .purple) { handleServeType(.feint) }
                }
            } else {
                HStack(spacing: 12) {
                    ActionButton(title: "成功", systemImage: "checkmark.circle", color: .green) {
                        pendingServeSuccess = true
                        detailSelectionState = .serveType
                    }
                    ActionButton(title: "失敗", systemImage: "xmark.circle", color: .red) {
                        pendingServeSuccess = false
                        // ✨ 修正: ViewModelのメソッドを直接呼び出す
                        processRallyEvent(type: .serve, isSuccess: false, reason: .fault)
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private var receiveActionSelection: some View {
        HStack(spacing: 12) {
            ActionButton(title: "成功", systemImage: "checkmark.circle", color: .green) { processRallyEvent(type: .receive, isSuccess: true) }
            ActionButton(title: "失敗", systemImage: "xmark.circle", color: .red) { processRallyEvent(type: .receive, isSuccess: false, reason: .fault) }
        }
    }
    
    @ViewBuilder
    private var setActionSelection: some View {
        VStack(spacing: 8) {
            if detailSelectionState == .setFailureReason {
                Text("失敗理由を選択")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 8) {
                    ActionButton(title: "オーバーセット", systemImage: "arrow.up.circle", color: .orange) { handleSetFailure(.overSet) }
                    ActionButton(title: "チャンスボール", systemImage: "circle.dotted", color: .blue) { handleSetFailure(.chanceBall) }
                }
            } else {
                HStack(spacing: 12) {
                    ActionButton(title: "成功", systemImage: "checkmark.circle", color: .green) { processRallyEvent(type: .setting, isSuccess: true) }
                    ActionButton(title: "失敗", systemImage: "xmark.circle", color: .red) { detailSelectionState = .setFailureReason }
                }
            }
        }
    }
    
    @ViewBuilder
    private var attackActionSelection: some View {
        VStack(spacing: 8) {
            if detailSelectionState == .attackOutcome, let attackChoice = pendingAttackChoice {
                attackOutcomeSelection(for: attackChoice)
            } else {
                HStack(spacing: 8) {
                    ActionButton(title: "得点", systemImage: "star.circle", color: .green) { pendingAttackChoice = .point; detailSelectionState = .attackOutcome }
                    ActionButton(title: "相手得点", systemImage: "minus.circle", color: .red) { pendingAttackChoice = .opponentPoint; detailSelectionState = .attackOutcome }
                    ActionButton(title: "ラリー継続", systemImage: "arrow.clockwise.circle", color: .blue) { pendingAttackChoice = .rallyContinue; detailSelectionState = .attackOutcome }
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
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 6) {
                    ActionButton(title: "通常アタック", systemImage: "arrow.clockwise", color: .green) { handleAttackPoint(.attack) }
                    ActionButton(title: "フェイント", systemImage: "eye.slash", color: .green) { handleAttackPoint(.attack_feint) }
                    ActionButton(title: "ヘディング", systemImage: "person.circle", color: .green) { handleAttackPoint(.heading) }
                    ActionButton(title: "ネットタッチ・オーバー", systemImage: "scissors", color: .green) { handleAttackFailure(.fault) }
                }
            case .opponentPoint:
                HStack(spacing: 6) {
                    ActionButton(title: "アウト", systemImage: "arrow.up.circle", color: .red) { handleAttackFailure(.out) }
                    ActionButton(title: "ネット", systemImage: "network", color: .red) { handleAttackFailure(.net) }
                    ActionButton(title: "ネットタッチ・オーバー", systemImage: "xmark.circle", color: .red) { handleAttackFailure(.fault) }
                }
            case .rallyContinue:
                HStack(spacing: 8) {
                    ActionButton(title: "ブロックされた", systemImage: "shield.circle", color: .blue) { handleAttackBlocked() }
                    ActionButton(title: "レシーブされた", systemImage: "arrow.down.circle", color: .cyan) { handleAttackReceived() }
                }
            }
        }
    }
    
    @ViewBuilder
    private var blockActionSelection: some View {
        HStack(spacing: 8) {
            ActionButton(title: "ブロック\nカバーした", systemImage: "arrow.clockwise.circle", color: .green) { processBlockCover() }
            ActionButton(title: "相手に拾われた", systemImage: "arrow.right.circle", color: .blue) { processBlockToReceive() }
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
    
    // MARK: - Action Handling Methods
    
    private func switchServeAndReceive() {
        viewModel.switchRallyFlow()
        DispatchQueue.main.async {
            self.autoSelectPlayer(for: .receiving)
            self.detailSelectionState = .none
        }
    }
    
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
        // ✨ 修正: ViewModelの状態を直接変更
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
        case .point: return "アタックタイプを選択"
        case .opponentPoint: return "失敗理由を選択"
        case .rallyContinue: return "継続理由を選択"
        }
    }
    
    // MARK: - Helper Functions
    
    private func autoSelectPlayer(for stage: RallyStage) {
        DispatchQueue.main.async {
            switch stage {
            case .serving:
                // ✨ 修正: `servingTeamPlayers` からサーバーを探す
                selectedPlayer = servingTeamPlayers.first { $0.position == .tekong }
            case .receiving, .blocking, .gameEnd:
                selectedPlayer = nil
            case .setting:
                // ✨ 修正: `currentActionTeamPlayers` からフィーダーを探す
                selectedPlayer = currentActionTeamPlayers.first { $0.position == .feeder }
            case .attacking:
                // ✨ 修正: `currentActionTeamPlayers` からストライカーを探す
                selectedPlayer = currentActionTeamPlayers.first { $0.position == .striker }
            }
        }
    }
    
    // ✨ 修正: Statの生成と保存をViewModelに一任する
    private func processRallyEvent(type: StatType, isSuccess: Bool, reason: FailureReason? = nil) {
        guard let player = selectedPlayer else {
            // サーブなど、選手が自動で決まる場合
            if let server = servingTeamPlayers.first(where: { $0.position == .tekong }), (type == .serve || type == .serve_feint) {
                viewModel.processRallyEvent(player: server, type: type, isSuccess: isSuccess, reason: reason)
            }
            return
        }
        viewModel.processRallyEvent(player: player, type: type, isSuccess: isSuccess, reason: reason)
    }
    
    // ✨ 修正: Statの生成と保存をViewModelに一任する
    private func processSetFailureWithReceive(reason: FailureReason) {
        guard let player = selectedPlayer else { return }
        viewModel.processSetFailure(player: player, reason: reason)
    }
    
    // ✨ 修正: Statの生成と保存をViewModelに一任する
    private func processAttackReceivedInternal() {
        guard let player = selectedPlayer else { return }
        // ✨ エラー修正: 引数の順序をモデル定義に合わせる
        let stat = Stat(type: .attack, matchID: selectedMatch.id, isSuccess: false, failureReason: .received)
        viewModel.processAttackReceived(player: player, originalStat: stat)
    }
    
    // ✨ 修正: Statの生成と保存をViewModelに一任する
    private func processBlockCover() {
        guard let player = selectedPlayer else { return }
        // ✨ エラー修正: 引数の順序をモデル定義に合わせる
        let stat = Stat(type: .block, matchID: selectedMatch.id, isSuccess: true, failureReason: .blockCover)
        viewModel.processBlockCover(player: player, originalStat: stat)
    }
    
    // ✨ 修正: Statの生成と保存をViewModelに一任する
    private func processBlockToReceive() {
        guard let player = selectedPlayer else { return }
        // ✨ エラー修正: 引数の順序をモデル定義に合わせる
        let stat = Stat(type: .block, matchID: selectedMatch.id, isSuccess: false, failureReason: .received)
        viewModel.processBlockCounterAttack(player: player, originalStat: stat)
    }
}
// MARK: - 追加定義

enum ServeType {
    case normal, feint
}

enum AttackChoice {
    case point, opponentPoint, rallyContinue
}

// MARK: - Helper Views (変更なし)

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
    
    // SwiftDataのコンテナをプレビュー用にセットアップ
    let container = PreviewSampleData.container
    
    // コンテナから最初の試合データを取得
    let fetchDescriptor = FetchDescriptor<Match>()
    let match = try! container.mainContext.fetch(fetchDescriptor).first!
    
    return ScoreView(match: match)
        .modelContainer(container)
}
