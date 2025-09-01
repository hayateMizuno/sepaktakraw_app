//
//  PlayerSelectionSection.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/16.
//

import SwiftUI
import SwiftData

/// 選手選択セクション
/// ラリー段階に応じて適切な選手の選択を行うUI
struct PlayerSelectionSection: View {
    @ObservedObject var viewModel: ScoreViewModel
    @Binding var selectedPlayer: Player?
    
    // 表示すべき選手の配列を直接受け取る
    let playersForSelection: [Player]
    
    let currentTeamColor: Color

    /// 選手が選択可能かどうかを判定
    private func isPlayerSelectable(_ player: Player) -> Bool {
        if viewModel.isSetFinished {
            return false
        }
        if viewModel.rallyStage == .serving {
            return false
        }
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
                    
                    // 現在のラリー段階を表示
                    Text("段階: \(rallyStageDisplayName)")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                
                // 選手選択ボタン一覧
                HStack(spacing: 10) {
                    // ✨ 修正: playersForSelection を直接ソートして使用
                    ForEach(playersForSelection.sorted { $0.position.sortOrder < $1.position.sortOrder }) { player in
                        PlayerSelectionButton(
                            player: player,
                            positionName: player.position.displayName,
                            selectionColor: currentTeamColor,
                            isSelected: selectedPlayer?.id == player.id,
                            isSelectable: isPlayerSelectable(player)
                        ) {
                            // 選択可能な場合のみ選手を選択
                            if isPlayerSelectable(player) {
                                selectedPlayer = player
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
        case .serving: return "サーブ"
        case .receiving: return "レシーブ"
        case .setting: return "トス"
        case .attacking: return "アタック"
        case .blocking: return "ブロック"
        case .gameEnd: return "ゲーム終了"
        }
    }
    
    @ViewBuilder
    private var selectionStatusText: some View {
        HStack {
            Image(systemName: "info.circle").foregroundColor(.blue).font(.caption)
            Text(getSelectionStatusMessage()).font(.caption2).foregroundColor(.secondary)
            Spacer()
        }
    }
    
    private func getSelectionStatusMessage() -> String {
        if viewModel.rallyStage == .serving {
            return "サーブ段階では自動でサーバーが選択されます"
        } else if let player = selectedPlayer {
            return "選択中: \(player.name)"
        } else {
            switch viewModel.rallyStage {
            case .receiving: return "レシーブを行う選手を選択してください"
            case .setting: return "セットを行う選手を選択してください（通常はフィーダー）"
            case .attacking: return "アタックを行う選手を選択してください（通常はストライカー）"
            case .blocking: return "ブロックを行う選手を選択してください"
            default: return "選手を選択してください"
            }
        }
    }
}



// MARK: - Preview
#Preview {
    @MainActor
    struct PlayerSelectionSectionPreview: View {
        private static let previewMatchID = UUID()
        
        @StateObject var mockViewModel: ScoreViewModel = {
            let vm = ScoreViewModel(teamAServesFirst: true, matchID: previewMatchID)
            vm.rallyStage = .setting
            return vm
        }()
        
        @State var selectedPlayer: Player?
        
        // プレビュー用のチームと選手データ
        let mockPlayers: [Player] = {
            let team = Team(name: "Home Team", color: .blue)
            return [
                Player(name: "田中 太郎", position: .tekong, dominantFoot: .right, team: team),
                Player(name: "佐藤 次郎", position: .feeder, dominantFoot: .right, team: team),
                Player(name: "鈴木 三郎", position: .striker, dominantFoot: .left, team: team)
            ]
        }()
        
        var body: some View {
            VStack(spacing: 20) {
                PlayerSelectionSection(
                    viewModel: mockViewModel,
                    selectedPlayer: $selectedPlayer,
                    playersForSelection: mockPlayers,
                    currentTeamColor: .blue
                )
                Spacer()
            }
            .padding()
            .background(Color(.systemGray6))
        }
    }
    
    return PlayerSelectionSectionPreview()
        .modelContainer(PreviewSampleData.container)
}
