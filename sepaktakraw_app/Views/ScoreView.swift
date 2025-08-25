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

// MARK: - Main View

/// セパタクロー試合のスコア記録画面（フローチャート対応版）
struct ScoreView: View {
    // MARK: - State Properties
    
    @StateObject private var viewModel: ScoreViewModel
    @Environment(\.modelContext) private var modelContext
    @State private var isShowingResetAlert = false
    @Bindable var selectedMatch: Match
    @State private var selectedPlayer: Player?
    @State private var isDetailSelectionActive = false
    @State private var recordedOutcomeIsSuccess: Bool = true
    @State private var isChoosingAttackOutcome = false
    @State private var isChoosingBlockOutcome = false
    @State private var selectedAttackType: StatType? = nil
    @State private var gameState: GameState = .rally
    
    // 新しい状態管理プロパティ
    @State private var isShowingServeOptions = false
    @State private var isShowingReceiveOptions = false
    @State private var isShowingSetOptions = false
    @State private var isShowingAttackOptions = false
    @State private var isShowingBlockOptions = false

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
                print("🔍 ScoreView appeared - Stage: \(rallyStage)")
                DispatchQueue.main.async {
                    autoSelectPlayer(for: rallyStage)
                }
            }
            .onChange(of: rallyStage) { _, newStage in
                print("🔄 Rally stage changed to: \(newStage)")
                DispatchQueue.main.async {
                    autoSelectPlayer(for: newStage)
                }
            }
            .onChange(of: viewModel.isServeA) { _, newIsServeA in
                print("🔄 Serve team changed - isServeA: \(newIsServeA)")
                if rallyStage == .serving {
                    DispatchQueue.main.async {
                        autoSelectPlayer(for: .serving)
                    }
                }
            }
            .onChange(of: selectedPlayer) { _, newPlayer in
                print("👤 Selected player changed to: \(newPlayer?.name ?? "nil")")
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        Button(action: {
                            viewModel.undo()
                            autoSelectPlayer(for: viewModel.rallyStage)
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
                    }
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("本当にゲームをリセットしますか？この操作は元に戻せません。")
            }
            // フローチャート対応の選択シート
            .sheet(isPresented: $isShowingServeOptions) {
                ServeOptionsSheet(
                    selectedPlayer: $selectedPlayer,
                    servingTeam: servingTeam,
                    onServeAction: handleServeAction
                )
            }
            .sheet(isPresented: $isShowingReceiveOptions) {
                ReceiveOptionsSheet(
                    selectedPlayer: $selectedPlayer,
                    receivingTeam: receivingTeam,
                    onReceiveAction: handleReceiveAction
                )
            }
            .sheet(isPresented: $isShowingSetOptions) {
                SetOptionsSheet(
                    selectedPlayer: $selectedPlayer,
                    receivingTeam: receivingTeam,
                    onSetAction: handleSetAction
                )
            }
            .sheet(isPresented: $isShowingAttackOptions) {
                AttackOptionsSheet(
                    selectedPlayer: $selectedPlayer,
                    receivingTeam: receivingTeam,
                    onAttackAction: handleAttackAction
                )
            }
            .sheet(isPresented: $isShowingBlockOptions) {
                BlockOptionsSheet(
                    selectedPlayer: $selectedPlayer,
                    servingTeam: servingTeam,
                    onBlockAction: handleBlockAction
                )
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
                
                // フローチャート対応ボタンセクション
                flowchartButtonSection
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
            
            // フローチャート対応ボタンセクション
            flowchartButtonSection
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
    
    // MARK: - フローチャート対応ボタンセクション
    
    @ViewBuilder
    private var flowchartButtonSection: some View {
        VStack(spacing: 8) {
            Text("アクション選択")
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                switch rallyStage {
                case .serving:
                    ActionButton(
                        title: "サーブ",
                        systemImage: "arrow.up.circle",
                        color: .blue,
                        action: { isShowingServeOptions = true }
                    )
                    
                case .receiving:
                    ActionButton(
                        title: "レシーブ",
                        systemImage: "arrow.down.circle",
                        color: .green,
                        action: { isShowingReceiveOptions = true }
                    )
                    
                case .setting:
                    ActionButton(
                        title: "セット",
                        systemImage: "arrow.up.right.circle",
                        color: .orange,
                        action: { isShowingSetOptions = true }
                    )
                    
                case .attacking:
                    ActionButton(
                        title: "アタック",
                        systemImage: "bolt.circle",
                        color: .red,
                        action: { isShowingAttackOptions = true }
                    )
                    
                case .blocking:
                    ActionButton(
                        title: "ブロック",
                        systemImage: "shield.circle",
                        color: .purple,
                        action: { isShowingBlockOptions = true }
                    )
                    
                case .gameEnd:
                    Text("ゲーム終了")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                }
            }
        }
    }
    
    // MARK: - フローチャートアクション処理
    
    private func handleServeAction(_ action: ServeAction) {
        guard let player = selectedPlayer else { return }
        
        switch action {
        case .success:
            processRallyEvent(type: .serve, isSuccess: true)
            
        case .fault:
            processRallyEvent(type: .serve, isSuccess: false, reason: .fault)
            
        case .out:
            processRallyEvent(type: .serve, isSuccess: false, reason: .out)
            
        case .net:
            processRallyEvent(type: .serve, isSuccess: false, reason: .net)
        }
    }
    
    private func handleReceiveAction(_ action: ReceiveAction) {
        guard let player = selectedPlayer else { return }
        
        switch action {
        case .success:
            processRallyEvent(type: .receive, isSuccess: true)
            
        case .fault:
            processRallyEvent(type: .receive, isSuccess: false, reason: .fault)
            
        case .block:
            // レシーブ成功としてブロック段階へ
            processRallyEvent(type: .receive, isSuccess: true)
            viewModel.rallyStage = .blocking
        }
    }
    
    private func handleSetAction(_ action: SetAction) {
        guard let player = selectedPlayer else { return }
        
        switch action {
        case .success:
            processRallyEvent(type: .setting, isSuccess: true)
            
        case .overSet:
            processSetFailureWithReceive(reason: .overSet)
            
        case .chanceBall:
            processSetFailureWithReceive(reason: .chanceBall)
            
        case .fault:
            processRallyEvent(type: .setting, isSuccess: false, reason: .fault)
        }
    }
    
    private func handleAttackAction(_ action: AttackAction) {
        guard let player = selectedPlayer else { return }
        
        selectedAttackType = action.attackType
        
        switch action.outcome {
        case .point:
            processRallyEvent(type: action.attackType, isSuccess: true)
            
        case .fault:
            processRallyEvent(type: action.attackType, isSuccess: false, reason: .fault)
            
        case .out:
            processRallyEvent(type: action.attackType, isSuccess: false, reason: .out)
            
        case .net:
            processRallyEvent(type: action.attackType, isSuccess: false, reason: .net)
            
        case .blocked:
            // ブロック段階へ移行
            viewModel.rallyStage = .blocking
            
        case .received:
            processAttackReceived()
        }
    }
    
    private func handleBlockAction(_ action: BlockAction) {
        guard let player = selectedPlayer else { return }
        
        switch action {
        case .blockCover:
            processBlockCover()
            
        case .blockToReceive:
            processBlockToReceive()
            
        case .over:
            // オーバー（ブロック失敗）
            processRallyEvent(type: .block, isSuccess: false, reason: .over)
            
        case .chanceball:
            // チャンスボール（ブロック結果）
            processRallyEvent(type: .block, isSuccess: false, reason: .chanceBall)
        }
    }
    
    // MARK: - Helper Functions (既存のメソッドをそのまま使用)
    
    private func autoSelectPlayer(for stage: RallyStage) {
        print("🔧 autoSelectPlayer called for stage: \(stage)")
        let previousPlayer = selectedPlayer
        
        DispatchQueue.main.async {
            switch stage {
            case .serving:
                let server = self.servingTeam.players.first { $0.position == .tekong }
                self.selectedPlayer = server
                print("   - Serving team: \(self.servingTeam.name)")
                print("   - Selected server: \(server?.name ?? "none found")")
                
            case .receiving:
                self.selectedPlayer = nil
                print("   - Receiving: Reset player selection")
                
            case .setting:
                let feeder = self.receivingTeam.players.first { $0.position == .feeder }
                self.selectedPlayer = feeder
                print("   - Receiving team: \(self.receivingTeam.name)")
                print("   - Selected feeder: \(feeder?.name ?? "none found")")
                
            case .attacking:
                let striker = self.receivingTeam.players.first { $0.position == .striker }
                self.selectedPlayer = striker
                print("   - Receiving team: \(self.receivingTeam.name)")
                print("   - Selected striker: \(striker?.name ?? "none found")")
                
            case .blocking:
                // ブロック段階では任意の選手が対応可能
                self.selectedPlayer = nil
                print("   - Blocking: Reset player selection")
                
            case .gameEnd:
                self.selectedPlayer = nil
                print("   - Game ended: Reset player selection")
            }
            
            if previousPlayer?.id != self.selectedPlayer?.id {
                print("   - Player changed from \(previousPlayer?.name ?? "nil") to \(self.selectedPlayer?.name ?? "nil")")
            }
        }
    }
    
    // 既存のメソッドをそのまま使用
    private func processRallyEvent(type: StatType, isSuccess: Bool, reason: FailureReason? = nil) {
        guard let player = selectedPlayer else {
            if type == .serve {
                if let server = servingTeam.players.first(where: { $0.position == .tekong }) {
                    print("🎯 Processing serve event with auto-selected server: \(server.name)")
                    processRallyEventInternal(player: server, type: type, isSuccess: isSuccess, reason: reason)
                } else {
                    print("⚠️ processRallyEvent: Server player not found for serve action.")
                }
            } else {
                print("⚠️ processRallyEvent: No player selected for \(type) action.")
            }
            return
        }
        processRallyEventInternal(player: player, type: type, isSuccess: isSuccess, reason: reason)
    }

    private func processRallyEventInternal(player: Player, type: StatType, isSuccess: Bool, reason: FailureReason? = nil) {
        print("🎯 Processing rally event:")
        print("   - Player: \(player.name)")
        print("   - Type: \(type)")
        print("   - Success: \(isSuccess)")
        print("   - Reason: \(String(describing: reason))")
        print("   - Current Stage: \(rallyStage)")
        
        let stat = Stat(type: type, isSuccess: isSuccess, failureReason: reason)
        player.addStat(stat)
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Error saving model context: \(error)")
        }
        
        viewModel.processRallyEvent(
            player: player,
            type: type,
            isSuccess: isSuccess,
            reason: reason
        )
        
        resetInputStates()
        
        print("🔄 After processing - New Stage: \(viewModel.rallyStage)")
    }
    
    private func processAttackReceived() {
        guard let player = selectedPlayer, let attackType = selectedAttackType else {
            print("⚠️ processAttackReceived: Missing player or attack type")
            return
        }
        
        let stat = Stat(type: attackType, isSuccess: false, failureReason: .received)
        player.addStat(stat)
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Error saving model context: \(error)")
        }
        
        viewModel.processAttackReceived(player: player, originalStat: stat)
        resetInputStates()
    }
    
    private func processSetFailureWithReceive(reason: FailureReason) {
        guard let player = selectedPlayer else {
            print("⚠️ processSetFailureWithReceive: No player selected")
            return
        }
        
        print("🔄 Processing set failure with receive:")
        print("   - Player: \(player.name)")
        print("   - Reason: \(String(describing: reason))")
        
        processRallyEvent(type: .setting, isSuccess: false, reason: reason)
        
        DispatchQueue.main.async {
            if reason == .overSet || reason == .chanceBall {
                viewModel.rallyStage = .receiving
                print("   - Adjusted stage to receiving for continuing rally")
            }
        }
    }
    
    private func processBlockCover() {
        guard let player = selectedPlayer, let attackType = selectedAttackType else {
            print("⚠️ processBlockCover: Missing player or attack type")
            return
        }
        
        print("🛡️ Processing block cover:")
        print("   - Player: \(player.name)")
        print("   - Attack type: \(attackType)")
        
        let stat = Stat(type: attackType, isSuccess: false, failureReason: .blockCover)
        player.addStat(stat)
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Error saving model context: \(error)")
        }
        
        viewModel.processBlockCover(player: player, originalStat: stat)
        resetInputStates()
    }
    
    private func processBlockToReceive() {
        guard let player = selectedPlayer, let attackType = selectedAttackType else {
            print("⚠️ processBlockToReceive: Missing player or attack type")
            return
        }
        
        print("🔄 Processing block to receive:")
        print("   - Player: \(player.name)")
        print("   - Attack type: \(attackType)")
        
        let stat = Stat(type: attackType, isSuccess: false, failureReason: .blocked)
        player.addStat(stat)
        
        do {
            try modelContext.save()
        } catch {
            print("❌ Error saving model context: \(error)")
        }
        
        viewModel.isServeA.toggle()
        viewModel.rallyStage = .receiving
        
        viewModel.scoreEvents.append(ScoreEvent(
            scoreA: viewModel.scoreA,
            scoreB: viewModel.scoreB,
            scoringTeam: viewModel.isServeA ? "A" : "B",
            timestamp: Date(),
            playerName: player.name,
            actionType: attackType,
            isSuccess: false,
            hasServeRight: viewModel.isServeA
        ))
        
        resetInputStates()
    }

    private func resetInputStates() {
        isDetailSelectionActive = false
        isChoosingAttackOutcome = false
        isChoosingBlockOutcome = false
        selectedAttackType = nil
        isShowingServeOptions = false
        isShowingReceiveOptions = false
        isShowingSetOptions = false
        isShowingAttackOptions = false
        isShowingBlockOptions = false
    }
}

// MARK: - フローチャートアクション定義

enum ServeAction {
    case success, fault, out, net
}

enum ReceiveAction {
    case success, fault, block
}

enum SetAction {
    case success, overSet, chanceBall, fault
}

struct AttackAction {
    let attackType: StatType
    let outcome: AttackOutcome
    
    enum AttackOutcome {
        case point, fault, out, net, blocked, received
    }
}

enum BlockAction {
    case blockCover, blockToReceive, over, chanceButton
}

// MARK: - フローチャート対応シート

struct ServeOptionsSheet: View {
    @Binding var selectedPlayer: Player?
    let servingTeam: Team
    let onServeAction: (ServeAction) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("サーブ結果を選択")
                    .font(.title2)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    FlowchartActionButton(
                        title: "成功",
                        systemImage: "checkmark.circle",
                        color: .green,
                        action: { onServeAction(.success); dismiss() }
                    )
                    
                    FlowchartActionButton(
                        title: "フォルト",
                        systemImage: "xmark.circle",
                        color: .red,
                        action: { onServeAction(.fault); dismiss() }
                    )
                    
                    FlowchartActionButton(
                        title: "アウト",
                        systemImage: "arrow.up.circle",
                        color: .orange,
                        action: { onServeAction(.out); dismiss() }
                    )
                    
                    FlowchartActionButton(
                        title: "ネット",
                        systemImage: "network",
                        color: .purple,
                        action: { onServeAction(.net); dismiss() }
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("サーブ")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ReceiveOptionsSheet: View {
    @Binding var selectedPlayer: Player?
    let receivingTeam: Team
    let onReceiveAction: (ReceiveAction) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("レシーブ結果を選択")
                    .font(.title2)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    FlowchartActionButton(
                        title: "成功",
                        systemImage: "checkmark.circle",
                        color: .green,
                        action: { onReceiveAction(.success); dismiss() }
                    )
                    
                    FlowchartActionButton(
                        title: "フォルト",
                        systemImage: "xmark.circle",
                        color: .red,
                        action: { onReceiveAction(.fault); dismiss() }
                    )
                    
                    FlowchartActionButton(
                        title: "ブロック",
                        systemImage: "shield.circle",
                        color: .blue,
                        action: { onReceiveAction(.block); dismiss() }
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("レシーブ")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct SetOptionsSheet: View {
    @Binding var selectedPlayer: Player?
    let receivingTeam: Team
    let onSetAction: (SetAction) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("セット結果を選択")
                    .font(.title2)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    FlowchartActionButton(
                        title: "成功",
                        systemImage: "checkmark.circle",
                        color: .green,
                        action: { onSetAction(.success); dismiss() }
                    )
                    
                    FlowchartActionButton(
                        title: "オーバーセット",
                        systemImage: "arrow.up.circle",
                        color: .orange,
                        action: { onSetAction(.overSet); dismiss() }
                    )
                    
                    FlowchartActionButton(
                        title: "チャンスボール",
                        systemImage: "circle.dotted",
                        color: .blue,
                        action: { onSetAction(.chanceBall); dismiss() }
                    )
                    
                    FlowchartActionButton(
                        title: "フォルト",
                        systemImage: "xmark.circle",
                        color: .red,
                        action: { onSetAction(.fault); dismiss() }
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("セット")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct AttackOptionsSheet: View {
    @Binding var selectedPlayer: Player?
    let receivingTeam: Team
    let onAttackAction: (AttackAction) -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var selectedAttackType: StatType = .spike
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("アタック結果を選択")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // アタックタイプ選択
                VStack(alignment: .leading) {
                    Text("アタックタイプ")
                        .font(.headline)
                    
                    Picker("Attack Type", selection: $selectedAttackType) {
                        Text("ローリング").tag(StatType.rollspike)
                        Text("シザース").tag(StatType.sunbackspike)
                        Text("フェイント").tag(StatType.attack_feint)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                // アタック結果選択
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    FlowchartActionButton(
                        title: "ポイント",
                        systemImage: "star.circle",
                        color: .green,
                        action: {
                            onAttackAction(AttackAction(attackType: selectedAttackType, outcome: .point))
                            dismiss()
                        }
                    )
                    
                    FlowchartActionButton(
                        title: "フォルト",
                        systemImage: "xmark.circle",
                        color: .red,
                        action: {
                            onAttackAction(AttackAction(attackType: selectedAttackType, outcome: .fault))
                            dismiss()
                        }
                    )
                    
                    FlowchartActionButton(
                        title: "アウト",
                        systemImage: "arrow.up.circle",
                        color: .orange,
                        action: {
                            onAttackAction(AttackAction(attackType: selectedAttackType, outcome: .out))
                            dismiss()
                        }
                    )
                    
                    FlowchartActionButton(
                        title: "ネット",
                        systemImage: "network",
                        color: .purple,
                        action: {
                            onAttackAction(AttackAction(attackType: selectedAttackType, outcome: .net))
                            dismiss()
                        }
                    )
                    
                    FlowchartActionButton(
                        title: "ブロック",
                        systemImage: "shield.circle",
                        color: .blue,
                        action: {
                            onAttackAction(AttackAction(attackType: selectedAttackType, outcome: .blocked))
                            dismiss()
                        }
                    )
                    
                    FlowchartActionButton(
                        title: "レシーブされた",
                        systemImage: "arrow.down.circle",
                        color: .cyan,
                        action: {
                            onAttackAction(AttackAction(attackType: selectedAttackType, outcome: .received))
                            dismiss()
                        }
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("アタック")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct BlockOptionsSheet: View {
    @Binding var selectedPlayer: Player?
    let servingTeam: Team
    let onBlockAction: (BlockAction) -> Void
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("ブロック結果を選択")
                    .font(.title2)
                    .fontWeight(.bold)
                
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    FlowchartActionButton(
                        title: "ブロックカバー\n(アタームループ)",
                        systemImage: "arrow.clockwise.circle",
                        color: .green,
                        action: { onBlockAction(.blockCover); dismiss() }
                    )
                    
                    FlowchartActionButton(
                        title: "ブロック→レシーブ\n(サーブ権移動)",
                        systemImage: "arrow.right.circle",
                        color: .blue,
                        action: { onBlockAction(.blockToReceive); dismiss() }
                    )
                    
                    FlowchartActionButton(
                        title: "オーバー",
                        systemImage: "arrow.up.circle",
                        color: .orange,
                        action: { onBlockAction(.over); dismiss() }
                    )
                    
                    FlowchartActionButton(
                        title: "チャンスボール",
                        systemImage: "circle.dotted",
                        color: .purple,
                        action: { onBlockAction(.chanceball); dismiss() }
                    )
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("ブロック")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
            }
        }
    }
}

// MARK: - フローチャート用ボタンコンポーネント

struct FlowchartActionButton: View {
    let title: String
    let systemImage: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.title2)
                    .foregroundColor(color)
                
                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
                    .foregroundColor(.primary)
            }
            .frame(maxWidth: .infinity, minHeight: 80)
            .padding(12)
            .background(color.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Helper Views (既存のコンポーネント)

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
                    .font(.caption2)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
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
        
        let teamA = Team(name: "チームA", color: .blue)
        let teamB = Team(name: "チームB", color: .red)
        
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
