//
//  PlayerSelectionSection.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/16.
//

import SwiftUI
import SwiftData

// MARK: - Position Extension は既存のファイルで定義済みのため削除

// MARK: - PlayerSelectionSection

/// 選手選択セクション
/// ラリー段階に応じて適切な選手の選択を行うUI
struct PlayerSelectionSection: View {
    // MARK: - Properties
    
    /// スコア管理用のビューモデル
    @ObservedObject var viewModel: ScoreViewModel
    
    /// 現在選択中の選手
    @Binding var selectedPlayer: Player?
    
    /// 現在アクションを行うチーム
    let currentActionTeam: Team
    
    /// 現在のアクションチームのカラー（UI表示用）
    let currentTeamColor: Color

    // MARK: - Helper Methods
    
    /// 選手を左からフィーダー、サーバー、ストライカーの順で並べる
    /// - Returns: 並び替えられた選手配列
    private func getOrderedPlayers() -> [Player] {
        let players = currentActionTeam.players
        
        // Position enumにsortOrderプロパティがある場合はそれを使用
        let orderedPlayers = players.sorted { $0.position.sortOrder < $1.position.sortOrder }
        
        // sortOrderが定義されていない場合のフォールバック処理
        if orderedPlayers.isEmpty {
            var fallbackOrder: [Player] = []
            
            // 手動で順序を決定
            if let feeder = players.first(where: { $0.position == .feeder }) {
                fallbackOrder.append(feeder)
            }
            if let tekong = players.first(where: { $0.position == .tekong }) {
                fallbackOrder.append(tekong)
            }
            if let striker = players.first(where: { $0.position == .striker }) {
                fallbackOrder.append(striker)
            }
            
            return fallbackOrder
        }
        
        return orderedPlayers
    }
    
    /// ポジション名を日本語で取得（修正版）
    /// - Parameter position: 選手のポジション
    /// - Returns: 日本語のポジション名
    private func getJapanesePositionName(for position: Position) -> String {
        return position.displayName
    }
    
    /// 選手が選択可能かどうかを判定
    /// - Parameter player: 判定する選手
    /// - Returns: 選択可能な場合はtrue
    private func isPlayerSelectable(_ player: Player) -> Bool {
        // セットが終了している場合は選択不可
        if viewModel.isSetFinished {
            return false
        }
        
        // サーブ段階では自動選択されるため手動選択は不可
        if viewModel.rallyStage == .serving {
            return false
        }
        
        // その他の段階では全選手が選択可能
        return true
    }

    // MARK: - Body
    
    var body: some View {
        // セットが終了している場合はセクション全体を非表示
        if !viewModel.isSetFinished {
            VStack(alignment: .leading, spacing: 5) {
                // セクションタイトル
                HStack {
                    Text("選手選択")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    // 現在のラリー段階を表示（修正版）
                    Text("段階: \(rallyStageDisplayName)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                // 選手選択ボタン一覧
                HStack(spacing: 10) {
                    ForEach(getOrderedPlayers(), id: \.id) { player in
                        PlayerSelectionButton(
                            player: player,
                            positionName: getJapanesePositionName(for: player.position),
                            selectionColor: currentTeamColor,
                            isSelected: selectedPlayer?.id == player.id,
                            isSelectable: isPlayerSelectable(player)
                        ) {
                            // 選択可能な場合のみ選手を選択
                            if isPlayerSelectable(player) {
                                selectedPlayer = player
                                print("👤 Player selected: \(player.name) (\(player.position.rawValue))")
                            }
                        }
                    }
                }
                
                // 選択状態の説明テキスト
                selectionStatusText
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    // MARK: - Helper Views
    
    /// 現在のラリー段階の表示名
    private var rallyStageDisplayName: String {
        switch viewModel.rallyStage {
        case .serving:
            return "サーブ"
        case .receiving:
            return "レシーブ"
        case .setting:
            return "トス"
        case .attacking:
            return "アタック"
        }
    }
    
    /// 選択状態の説明テキスト
    @ViewBuilder
    private var selectionStatusText: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
                .font(.caption)
            
            Text(getSelectionStatusMessage())
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Spacer()
        }
    }
    
    /// 選択状態に応じた説明メッセージを取得
    /// - Returns: 説明メッセージ
    private func getSelectionStatusMessage() -> String {
        if viewModel.rallyStage == .serving {
            return "サーブ段階では自動でサーバーが選択されます"
        } else if selectedPlayer != nil {
            return "選択中: \(selectedPlayer!.name)"
        } else {
            switch viewModel.rallyStage {
            case .receiving:
                return "レシーブを行う選手を選択してください"
            case .setting:
                return "セットを行う選手を選択してください（通常はフィーダー）"
            case .attacking:
                return "アタックを行う選手を選択してください（通常はストライカー）"
            default:
                return "選手を選択してください"
            }
        }
    }
}

// MARK: - Preview

#Preview {
    @MainActor
    struct PlayerSelectionSectionPreview: View {
        @StateObject var mockViewModel: ScoreViewModel = {
            let vm = ScoreViewModel(teamAServesFirst: true)
            vm.rallyStage = .setting // プレビュー用の段階設定
            vm.isSetFinished = false // セット継続中
            return vm
        }()
        
        @State var selectedPlayer: Player?
        
        // モックチームA
        let mockTeamA: Team = {
            let team = Team(name: "Home Team", color: .blue)
            team.players = [
                Player(name: "田中 太郎", position: .tekong, team: team),
                Player(name: "佐藤 次郎", position: .feeder, team: team),
                Player(name: "鈴木 三郎", position: .striker, team: team)
            ]
            return team
        }()
        
        // モックチームB
        let mockTeamB: Team = {
            let team = Team(name: "Away Team", color: .red)
            team.players = [
                Player(name: "高橋 四郎", position: .tekong, team: team),
                Player(name: "伊藤 五郎", position: .feeder, team: team),
                Player(name: "渡辺 六郎", position: .striker, team: team)
            ]
            return team
        }()
        
        var body: some View {
            VStack(spacing: 20) {
                // 段階切り替え用のコントロール（プレビュー用）
                Picker("Rally Stage", selection: $mockViewModel.rallyStage) {
                    Text("サーブ").tag(RallyStage.serving)
                    Text("レシーブ").tag(RallyStage.receiving)
                    Text("セット").tag(RallyStage.setting)
                    Text("アタック").tag(RallyStage.attacking)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal)
                
                // メインコンポーネント
                PlayerSelectionSection(
                    viewModel: mockViewModel,
                    selectedPlayer: $selectedPlayer,
                    currentActionTeam: mockTeamA, // テスト対象のチーム
                    currentTeamColor: mockTeamA.color
                )
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
            .onAppear {
                // プレビュー用の初期選択（セット段階でフィーダーを選択）
                if mockViewModel.rallyStage == .setting {
                    selectedPlayer = mockTeamA.players.first(where: { $0.position == .feeder })
                }
            }
            .onChange(of: mockViewModel.rallyStage) { _, newStage in
                // 段階変更時の自動選択（プレビュー用）
                switch newStage {
                case .serving:
                    selectedPlayer = mockTeamA.players.first(where: { $0.position == .tekong })
                case .receiving:
                    selectedPlayer = nil
                case .setting:
                    selectedPlayer = mockTeamA.players.first(where: { $0.position == .feeder })
                case .attacking:
                    selectedPlayer = mockTeamA.players.first(where: { $0.position == .striker })
                }
            }
        }
    }
    
    return PlayerSelectionSectionPreview()
}
