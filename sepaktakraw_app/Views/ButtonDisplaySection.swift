//
//  ButtonDisplaySection.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/16.
//

import SwiftUI
import SwiftData

// MARK: - StatType Extension (追加)

extension StatType {
    var displayName: String {
        switch self {
        case .serve:
            return "通常サーブ"
        case .serve_feint:
            return "サーブフェイント"
        case .receive:
            return "レシーブ"
        case .setting:
            return "セット"
        case .attack:
            return "通常アタック"
        case .attack_feint:
            return "アタックフェイント"
        case .heading:
            return "ヘディング"
        default:
            return rawValue.capitalized
        }
    }
}

// MARK: - ButtonDisplaySection

/// ラリー進行に応じたアクションボタン表示セクション
/// 段階的なボタン表示でユーザーの操作を誘導する
struct ButtonDisplaySection: View {
    // MARK: - Properties
    
    /// 現在のラリー段階
    let rallyStage: RallyStage
    
    /// 記録するアクション結果（成功/失敗）
    @Binding var recordedOutcomeIsSuccess: Bool
    
    /// アタック結果選択画面の表示フラグ
    @Binding var isChoosingAttackOutcome: Bool
    
    /// ブロック結果選択画面の表示フラグ
    @Binding var isChoosingBlockOutcome: Bool
    
    /// 選択中のアタックタイプ
    @Binding var selectedAttackType: StatType?
    
    /// 詳細選択画面の表示フラグ
    @Binding var isDetailSelectionActive: Bool
    
    /// 現在選択中の選手（プロセスメソッドで使用）
    @Binding var selectedPlayer: Player?
    
    /// スコア管理用のビューモデル
    @ObservedObject var viewModel: ScoreViewModel
    
    /// SwiftDataのモデルコンテキスト（環境から自動取得）
    @Environment(\.modelContext) private var modelContext

    // MARK: - Action Closures
    // 親ビューのメソッドを呼び出すためのクロージャ
    
    let processRallyEventAction: (StatType, Bool, FailureReason?) -> Void
    let processAttackReceivedAction: () -> Void
    let processSetFailureWithReceiveAction: (FailureReason) -> Void
    let processBlockCoverAction: () -> Void
    let processBlockToReceiveAction: () -> Void

    // MARK: - Helper Methods
    
    /// 戻るボタンを表示すべきかどうか判定
    /// - Returns: 戻るボタンを表示する場合はtrue
    private func shouldShowBackButton() -> Bool {
        return rallyStage == .serving ||
               rallyStage == .attacking ||
               (rallyStage == .setting && !recordedOutcomeIsSuccess)
    }

    // MARK: - Body
    
    var body: some View {
        VStack {
            // 状態に応じてボタンセットを切り替え
            if isChoosingBlockOutcome {
                blockOutcomeButtons
            } else if isChoosingAttackOutcome {
                attackOutcomeButtons
            } else if isDetailSelectionActive {
                detailSelectionButtons
            } else {
                outcomeSelectionButtons
            }
        }
    }

    // MARK: - Button UI Definitions

    /// 【ステップ1】成功・失敗選択ボタン
    @ViewBuilder
    private var outcomeSelectionButtons: some View {
        HStack(spacing: 12) {
            // 成功ボタン
            Button {
                recordedOutcomeIsSuccess = true
                handleOutcomeSelection(isSuccess: true)
            } label: {
                Label("成功", systemImage: "checkmark")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            
            // 失敗ボタン
            Button {
                recordedOutcomeIsSuccess = false
                handleOutcomeSelection(isSuccess: false)
            } label: {
                Label("失敗", systemImage: "xmark")
                    .frame(maxWidth: .infinity, minHeight: 44)
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
        // 選手が選択されていないか、セットが終了している場合は無効化
        .disabled(selectedPlayer == nil || viewModel.isSetFinished)
    }
    
    /// 【ステップ2】詳細選択ボタン（アクションタイプと失敗理由）
    @ViewBuilder
    private var detailSelectionButtons: some View {
        VStack(spacing: 12) {
            // ラリー段階と成功/失敗に応じてボタンを表示
            switch (rallyStage, recordedOutcomeIsSuccess) {
            case (.serving, true):
                serveSuccessDetailButtons
            case (.serving, false):
                serveFailDetailButtons
            case (.setting, false):
                setFailDetailButtons
            case (.attacking, true):
                attackSuccessDetailButtons
            case (.setting, true):
                // セット成功の場合は即座に記録（詳細選択不要）
                Text("セット成功を記録中...")
                    .onAppear {
                        processRallyEventAction(.setting, true, nil)
                    }
            default:
                EmptyView()
            }
            
            // 戻るボタン（該当する段階でのみ表示）
            if shouldShowBackButton() {
                Button("選び直す") {
                    isDetailSelectionActive = false
                }
                .padding(.top, 8)
            }
        }
    }

    /// サーブ成功時の詳細選択ボタン
    @ViewBuilder
    private var serveSuccessDetailButtons: some View {
        VStack(spacing: 8) {
            Text("サーブの種類を選択")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ActionButton(title: "通常サーブ", systemImage: "arrow.forward.circle", color: .blue) {
                    processRallyEventAction(.serve, true, nil)
                }
                ActionButton(title: "フェイント", systemImage: "wand.and.stars", color: .purple) {
                    processRallyEventAction(.serve_feint, true, nil)
                }
            }
        }
    }
    
    /// サーブ失敗時の詳細選択ボタン
    @ViewBuilder
    private var serveFailDetailButtons: some View {
        VStack(spacing: 8) {
            Text("失敗したサーブの種類を選択")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ActionButton(title: "通常サーブ", systemImage: "arrow.forward.circle", color: .orange) {
                    processRallyEventAction(.serve, false, .fault)
                }
                ActionButton(title: "フェイント", systemImage: "wand.and.stars", color: .gray) {
                    processRallyEventAction(.serve_feint, false, .fault)
                }
            }
        }
    }
    
    /// セット失敗時の詳細選択ボタン
    @ViewBuilder
    private var setFailDetailButtons: some View {
        VStack(spacing: 12) {
            Text("セット失敗の詳細を選択")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // 続行可能な失敗（相手がレシーブ可能）
            HStack(spacing: 12) {
                ActionButton(title: "オーバーセット", systemImage: "arrow.up.and.down.and.arrow.left.and.right", color: .orange) {
                    processSetFailureWithReceiveAction(.overSet)
                }
                ActionButton(title: "チャンスボール", systemImage: "gift.fill", color: .purple) {
                    processSetFailureWithReceiveAction(.chanceBall)
                }
            }
            
            // ラリー終了の失敗
            ActionButton(title: "フォルト (ラリー終了)", systemImage: "xmark.octagon.fill", color: .red) {
                processRallyEventAction(.setting, false, .fault)
            }
        }
    }

    /// アタック成功時の種類選択ボタン
    @ViewBuilder
    private var attackSuccessDetailButtons: some View {
        VStack(spacing: 8) {
            Text("アタックの種類を選択")
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 12) {
                ActionButton(title: "通常アタック", systemImage: "bolt.circle", color: .green) {
                    selectedAttackType = .attack
                    isChoosingAttackOutcome = true
                }
                ActionButton(title: "フェイント", systemImage: "wand.and.stars", color: .purple) {
                    selectedAttackType = .attack_feint
                    isChoosingAttackOutcome = true
                }
                ActionButton(title: "ヘディング", systemImage: "figure.soccer", color: .cyan) {
                    selectedAttackType = .heading
                    isChoosingAttackOutcome = true
                }
            }
        }
    }
    
    /// 【ステップ3】アタックの最終結果選択ボタン
    @ViewBuilder
    private var attackOutcomeButtons: some View {
        VStack(spacing: 12) {
            Text("アタック結果を選択")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("選択中: \(selectedAttackType?.displayName ?? "不明")")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ActionButton(title: "得点", systemImage: "checkmark.circle.fill", color: .green) {
                        processRallyEventAction(selectedAttackType ?? .attack, true, nil)
                    }
                    ActionButton(title: "ブロックされた", systemImage: "hand.raised.slash.fill", color: .orange) {
                        isChoosingBlockOutcome = true
                    }
                }
                GridRow {
                    ActionButton(title: "レシーブされた", systemImage: "figure.arms.open", color: .indigo) {
                        processAttackReceivedAction()
                    }
                    ActionButton(title: "アウト", systemImage: "xmark.circle", color: .red) {
                        processRallyEventAction(selectedAttackType ?? .attack, false, .fault)
                    }
                }
            }
            
            Button("選び直す") {
                isChoosingAttackOutcome = false
            }
            .padding(.top, 8)
        }
    }
    
    /// 【ステップ4】ブロック後の結果選択ボタン
    @ViewBuilder
    private var blockOutcomeButtons: some View {
        VStack(spacing: 12) {
            Text("ブロック後の結果を選択")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("選択中: \(selectedAttackType?.displayName ?? "不明")")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Grid(horizontalSpacing: 12, verticalSpacing: 12) {
                GridRow {
                    ActionButton(title: "ブロックアウト\n（得点）", systemImage: "checkmark.circle.fill", color: .green) {
                        processRallyEventAction(selectedAttackType ?? .attack, true, nil)
                    }
                    ActionButton(title: "ブロックイン\n（失点）", systemImage: "xmark.circle.fill", color: .red) {
                        processRallyEventAction(selectedAttackType ?? .attack, false, .blocked)
                    }
                }
                GridRow {
                    ActionButton(title: "ブロックカバー\n（続行）", systemImage: "arrow.triangle.2.circlepath", color: .blue) {
                        processBlockCoverAction()
                    }
                    ActionButton(title: "相手レシーブ\n（続行）", systemImage: "figure.arms.open", color: .purple) {
                        processBlockToReceiveAction()
                    }
                }
            }
            
            Button("選び直す") {
                isChoosingBlockOutcome = false
                isChoosingAttackOutcome = true
            }
            .padding(.top, 8)
        }
    }

    // MARK: - Helper Functions
    
    /// 成功・失敗選択時の処理
    /// - Parameter isSuccess: 成功かどうか
    private func handleOutcomeSelection(isSuccess: Bool) {
        if rallyStage == .receiving {
            // レシーブ段階：直接レシーブイベントを処理
            processRallyEventAction(.receive, isSuccess, isSuccess ? nil : .fault)
        } else {
            // その他の段階：詳細選択画面に進む
            isDetailSelectionActive = true
        }
    }
}

// MARK: - Preview

#Preview {
    @MainActor
    struct ButtonDisplaySectionPreview: View {
        private static let previewMatchID = UUID()

        @StateObject var mockViewModel: ScoreViewModel = {
            let vm = ScoreViewModel(teamAServesFirst: true, matchID: previewMatchID)
            vm.rallyStage = .attacking
            vm.scoreA = 10
            vm.scoreB = 8
            return vm
        }()

        @State var recordedOutcomeIsSuccess: Bool = true
        @State var isChoosingAttackOutcome: Bool = false
        @State var isChoosingBlockOutcome: Bool = false
        @State var selectedAttackType: StatType? = .attack
        @State var isDetailSelectionActive: Bool = false
        @State var selectedPlayer: Player? = {
            let mockTeam = Team(name: "Test Team", color: .blue)
            // ✨ エラー修正: dominantFoot を追加
            return Player(name: "Test Striker", position: .striker, dominantFoot: .right, team: mockTeam)
        }()

        var body: some View {
            ScrollView {
                ButtonDisplaySection(
                    rallyStage: mockViewModel.rallyStage,
                    recordedOutcomeIsSuccess: $recordedOutcomeIsSuccess,
                    isChoosingAttackOutcome: $isChoosingAttackOutcome,
                    isChoosingBlockOutcome: $isChoosingBlockOutcome,
                    selectedAttackType: $selectedAttackType,
                    isDetailSelectionActive: $isDetailSelectionActive,
                    selectedPlayer: $selectedPlayer,
                    viewModel: mockViewModel,
                    processRallyEventAction: { type, isSuccess, reason in
                        print("🎯 Rally Event: \(type), Success: \(isSuccess), Reason: \(reason?.rawValue ?? "none")")
                    },
                    processAttackReceivedAction: { print("🏐 Attack Received") },
                    processSetFailureWithReceiveAction: { reason in print("🔄 Set Failure with Receive: \(reason.rawValue)") },
                    processBlockCoverAction: { print("🛡️ Block Cover") },
                    processBlockToReceiveAction: { print("🔄 Block to Receive") }
                )
                .padding()
            }
            .background(Color(.systemGray6))
        }
    }
    
    return ButtonDisplaySectionPreview()
        .modelContainer(PreviewSampleData.container)
}
