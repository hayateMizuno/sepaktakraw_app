//
//  ScoreDisplaySection.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/16.
//

import SwiftUI
import SwiftData

// MARK: - ScoreDisplaySection

/// スコア表示セクション
/// 両チームのスコア、選手情報、サーブ権表示を行う
struct ScoreDisplaySection: View {
    // MARK: - Properties
    
    /// スコア管理用のビューモデル
    @ObservedObject var viewModel: ScoreViewModel
    
    /// チームA
    let teamA: Team
    
    /// チームB
    let teamB: Team
    
    // MARK: - Helper Methods
    
    /// チームの選手を表示順（フィーダー、サーバー、ストライカー）で取得
    /// - Parameter team: 対象チーム
    /// - Returns: 並び替えられた選手配列
    private func getOrderedPlayersForTeam(_ team: Team) -> [Player] {
        let players = team.players
        var orderedPlayers: [Player] = []
        
        // 表示順：フィーダー → サーバー → ストライカー
        if let feeder = players.first(where: { $0.position == .feeder }) {
            orderedPlayers.append(feeder)
        }
        if let server = players.first(where: { $0.position == .tekong }) {
            orderedPlayers.append(server)
        }
        if let striker = players.first(where: { $0.position == .striker }) {
            orderedPlayers.append(striker)
        }
        
        return orderedPlayers
    }
    
    /// ポジション名を日本語で取得
    /// - Parameter position: 選手のポジション
    /// - Returns: 日本語のポジション名
    private func getJapanesePositionName(for position: Position) -> String {
        switch position {
        case .feeder:
            return "トサー"
        case .tekong:
            return "サーバー"
        case .striker:
            return "アタッカー"
        }
    }
    
    /// 最後に得点したチームを取得（未使用だが将来的に使用可能性のため保持）
    /// - Returns: チームAが最後に得点した場合はtrue
    private func getLastScoringTeam() -> Bool {
        // 最新の得点イベントから判定
        if let lastPointEvent = viewModel.scoreEvents.last(where: { $0.scoringTeam == "A" || $0.scoringTeam == "B" }) {
            return lastPointEvent.scoringTeam == "A"
        }
        
        // 得点イベントがない場合は現在のスコアから判定
        if viewModel.scoreA > viewModel.scoreB {
            return true
        } else if viewModel.scoreB > viewModel.scoreA {
            return false
        } else {
            // 同点の場合は現在のサーブ権の逆
            return !viewModel.isServeA
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 16) {
            // メインスコア表示
            HStack(spacing: 20) {
                // チームA表示
                teamDisplayView(
                    team: teamA,
                    score: viewModel.scoreA,
                    hasServeRight: viewModel.isServeA,
                    serveArrowPointsRight: true
                )
                
                // 中央の区切り文字
                Text("—")
                    .font(.system(size: 50, weight: .bold))
                    .foregroundColor(.black)
                    .offset(y: -5) // サーブ矢印の高さ分を考慮して調整
                
                // チームB表示
                teamDisplayView(
                    team: teamB,
                    score: viewModel.scoreB,
                    hasServeRight: !viewModel.isServeA,
                    serveArrowPointsRight: false
                )
            }
            .padding()
            
            // ゲーム結果メッセージ表示
            if !viewModel.gameOutcomeMessage.isEmpty {
                Text(viewModel.gameOutcomeMessage)
                    .font(.headline)
                    .foregroundColor(.blue)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    // MARK: - Helper Views
    
    /// チーム表示ビュー（再利用可能）
    /// - Parameters:
    ///   - team: 表示するチーム
    ///   - score: チームのスコア
    ///   - hasServeRight: サーブ権を持っているか
    ///   - serveArrowPointsRight: サーブ矢印が右向きか
    @ViewBuilder
    private func teamDisplayView(team: Team, score: Int, hasServeRight: Bool, serveArrowPointsRight: Bool) -> some View {
        VStack(spacing: 8) {
            // チーム名表示
            Text(team.name)
                .font(.headline)
                .fontWeight(.bold)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(team.color.opacity(0.2))
                .foregroundColor(team.color)
                .cornerRadius(8)
                .multilineTextAlignment(.center)
            
//            // 選手情報表示
//            VStack(spacing: 2) {
//                ForEach(getOrderedPlayersForTeam(team), id: \.id) { player in
//                    Text("\(getJapanesePositionName(for: player.position)): \(player.name)")
//                        .font(.caption2)
//                        .foregroundColor(.secondary)
//                        .multilineTextAlignment(.center)
//                }
//            }
            
            // スコア表示
            Text("\(score)")
                .font(.system(size: 70, weight: .bold))
                .foregroundColor(team.color)
                .frame(width: 100)
                .multilineTextAlignment(.center)
            
            // サーブ権矢印表示
            Group {
                if hasServeRight {
                    ServeArrowView(isPointingRight: serveArrowPointsRight)
                } else {
                    // サーブ権がない場合でもスペースを確保（レイアウト安定化）
                    ServeArrowView(isPointingRight: serveArrowPointsRight)
                        .hidden()
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Helper Views

/// カスタム矢印シェイプ
struct ArrowShape: Shape {
    /// 矢印の向き（右向きかどうか）
    let isPointingRight: Bool
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        // 矢印の各部分の比率設定
        let bodyWidthRatio: CGFloat = 0.7    // 本体の幅比率
        let headLengthRatio: CGFloat = 0.3   // 矢印頭部の長さ比率
        let headWidthRatio: CGFloat = 1.0    // 矢印頭部の幅比率
        
        let bodyWidth = rect.width * bodyWidthRatio
        _ = rect.width * headLengthRatio
        let headWidth = rect.height * headWidthRatio
        let bodyHeight = rect.height / 2
        
        if isPointingRight {
            // 右向き矢印の描画
            path.move(to: CGPoint(x: 0, y: rect.height / 2 - bodyHeight / 2))
            path.addLine(to: CGPoint(x: bodyWidth, y: rect.height / 2 - bodyHeight / 2))
            path.addLine(to: CGPoint(x: bodyWidth, y: rect.height / 2 - headWidth / 2))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2))
            path.addLine(to: CGPoint(x: bodyWidth, y: rect.height / 2 + headWidth / 2))
            path.addLine(to: CGPoint(x: bodyWidth, y: rect.height / 2 + bodyHeight / 2))
            path.addLine(to: CGPoint(x: 0, y: rect.height / 2 + bodyHeight / 2))
        } else {
            // 左向き矢印の描画
            path.move(to: CGPoint(x: rect.width, y: rect.height / 2 - bodyHeight / 2))
            path.addLine(to: CGPoint(x: rect.width - bodyWidth, y: rect.height / 2 - bodyHeight / 2))
            path.addLine(to: CGPoint(x: rect.width - bodyWidth, y: rect.height / 2 - headWidth / 2))
            path.addLine(to: CGPoint(x: 0, y: rect.height / 2))
            path.addLine(to: CGPoint(x: rect.width - bodyWidth, y: rect.height / 2 + headWidth / 2))
            path.addLine(to: CGPoint(x: rect.width - bodyWidth, y: rect.height / 2 + bodyHeight / 2))
            path.addLine(to: CGPoint(x: rect.width, y: rect.height / 2 + bodyHeight / 2))
        }
        
        path.closeSubpath()
        return path
    }
}

/// サーブ権表示矢印ビュー
struct ServeArrowView: View {
    /// 矢印の向き（右向きかどうか）
    let isPointingRight: Bool
    
    var body: some View {
        ZStack {
            // カスタム矢印シェイプの描画
            ArrowShape(isPointingRight: isPointingRight)
                .fill(Color.green)
            
            // 矢印内のテキスト
            Text("SERVE")
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.white)
        }
        .frame(width: 80, height: 40)
    }
}

// MARK: - Preview

#Preview {
    @MainActor
    struct ScoreDisplaySectionPreview: View {
        private static let previewMatchID = UUID()

        @StateObject var mockViewModel: ScoreViewModel = {
            let vm = ScoreViewModel(teamAServesFirst: true, matchID: previewMatchID)
            vm.scoreA = 15
            vm.scoreB = 12
            vm.isServeA = true
            vm.scoreEvents.append(ScoreEvent(scoreA: 1, scoreB: 0, scoringTeam: "A", timestamp: Date(), playerName: "田中", actionType: .serve, isSuccess: true, hasServeRight: true))
            vm.gameOutcomeMessage = ""
            return vm
        }()
        
        let mockTeamA: Team = {
            let team = Team(name: "東京チーム", color: .blue)
            // ✨ エラー修正: dominantFoot を追加
            let p1 = Player(name: "田中 太郎", position: .tekong, dominantFoot: .right, team: team)
            let p2 = Player(name: "佐藤 次郎", position: .feeder, dominantFoot: .right, team: team)
            let p3 = Player(name: "鈴木 三郎", position: .striker, dominantFoot: .left, team: team)
            team.players = [p1, p2, p3]
            return team
        }()
        
        let mockTeamB: Team = {
            let team = Team(name: "大阪チーム", color: .red)
            // ✨ エラー修正: dominantFoot を追加
            let p4 = Player(name: "高橋 四郎", position: .tekong, dominantFoot: .right, team: team)
            let p5 = Player(name: "伊藤 五郎", position: .feeder, dominantFoot: .left, team: team)
            let p6 = Player(name: "渡辺 六郎", position: .striker, dominantFoot: .right, team: team)
            team.players = [p4, p5, p6]
            return team
        }()

        var body: some View {
            VStack(spacing: 20) {
                Button("サーブ権切り替え") {
                    mockViewModel.isServeA.toggle()
                }
                .buttonStyle(.borderedProminent)
                
                ScoreDisplaySection(
                    viewModel: mockViewModel,
                    teamA: mockTeamA,
                    teamB: mockTeamB
                )
                
                Spacer()
            }
            .background(Color(.systemGroupedBackground))
        }
    }
    
    return ScoreDisplaySectionPreview()
}
