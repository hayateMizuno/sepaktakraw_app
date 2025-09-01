//
//  EnhancedStatsComponents.swift
//  sepaktakraw_app
//
//  Created by Claude on 2025/09/01.
//

import SwiftUI
import SwiftData
import Charts

// MARK: - 統計データマネージャー
class StatsManager: ObservableObject {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    // チームの試合履歴を取得
    func getMatchHistory(for team: Team) -> [Match] {
        // 修正点：比較に使うIDを先に定数として取り出す
        let teamID = team.id
        
        let descriptor = FetchDescriptor<Match>(
            predicate: #Predicate<Match> { match in
                // 修正点：ローカル定数 'teamID' を使って比較する
                match.teamA?.id == teamID || match.teamB?.id == teamID
            },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        
        return (try? modelContext.fetch(descriptor)) ?? []
    }
    
    // 選手の試合履歴から統計を計算
    func getPlayerMatchStats(player: Player) -> PlayerMatchStats {
        let totalMatches = 0
        let wins = 0
        let losses = 0
        
        // 実際の実装では、選手が参加した試合を特定し、
        // その試合結果から勝敗を判定する必要があります
        // 簡略化のため、ダミーデータを使用
        
        let statsByType = Dictionary(grouping: player.stats) { $0.type }
        
        return PlayerMatchStats(
            totalMatches: totalMatches,
            wins: wins,
            losses: losses,
            statsByType: statsByType
        )
    }
    
    // チームの詳細統計を計算
    func getTeamDetailedStats(for team: Team) -> TeamDetailedStats {
        let matches = getMatchHistory(for: team)
        var wins = 0
        var losses = 0
        var totalPointsFor = 0
        var totalPointsAgainst = 0
        
        // 比較用のIDをループの外で一度だけ取得
        let teamID = team.id
        
        for match in matches {
            if match.teamA?.id == teamID {
                totalPointsFor += match.scoreA
                totalPointsAgainst += match.scoreB
                if match.scoreA > match.scoreB {
                    wins += 1
                } else {
                    losses += 1
                }
            } else if match.teamB?.id == teamID {
                totalPointsFor += match.scoreB
                totalPointsAgainst += match.scoreA
                if match.scoreB > match.scoreA {
                    wins += 1
                } else {
                    losses += 1
                }
            }
        }
        
        let winRate = matches.isEmpty ? 0.0 : (Double(wins) / Double(matches.count)) * 100
        let avgPointsFor = matches.isEmpty ? 0.0 : Double(totalPointsFor) / Double(matches.count)
        let avgPointsAgainst = matches.isEmpty ? 0.0 : Double(totalPointsAgainst) / Double(matches.count)
        
        return TeamDetailedStats(
            totalMatches: matches.count,
            wins: wins,
            losses: losses,
            winRate: winRate,
            totalPointsFor: totalPointsFor,
            totalPointsAgainst: totalPointsAgainst,
            avgPointsFor: avgPointsFor,
            avgPointsAgainst: avgPointsAgainst,
            recentMatches: Array(matches.prefix(5))
        )
    }
}

// MARK: - データ構造
struct PlayerMatchStats {
    let totalMatches: Int
    let wins: Int
    let losses: Int
    let statsByType: [StatType: [Stat]]
    
    var winRate: Double {
        guard totalMatches > 0 else { return 0.0 }
        return (Double(wins) / Double(totalMatches)) * 100
    }
}

struct TeamDetailedStats {
    let totalMatches: Int
    let wins: Int
    let losses: Int
    let winRate: Double
    let totalPointsFor: Int
    let totalPointsAgainst: Int
    let avgPointsFor: Double
    let avgPointsAgainst: Double
    let recentMatches: [Match]
}

struct StatTrend {
    let statType: StatType
    let dataPoints: [StatDataPoint]
}

struct StatDataPoint {
    let date: Date
    let successRate: Double
    let attempts: Int
}

// MARK: - 高度な統計ビュー
struct AdvancedPlayerStatsView: View {
    let player: Player
    @StateObject private var statsManager: StatsManager
    
    // modelContextをinitで受け取るように変更
    init(player: Player, modelContext: ModelContext) {
        self.player = player
        self._statsManager = StateObject(wrappedValue: StatsManager(modelContext: modelContext))
    }
    
    private var playerStats: PlayerMatchStats {
        statsManager.getPlayerMatchStats(player: player)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // 基本情報カード
                PlayerBasicInfoCard(player: player, stats: playerStats)
                
                // 成功率推移グラフ
                PlayerTrendChartView(player: player)
                
                // ポジション別パフォーマンス
                PositionPerformanceView(player: player)
                
                // 詳細統計テーブル
                DetailedStatsTableView(player: player)
            }
            .padding()
        }
        .navigationTitle("詳細統計")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct PlayerBasicInfoCard: View {
    let player: Player
    let stats: PlayerMatchStats
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                VStack(alignment: .leading, spacing: 8) {
                    Text(player.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(player.position.displayName)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(player.team?.color.opacity(0.2) ?? Color.blue.opacity(0.2))
                        .cornerRadius(6)
                    
                    if let team = player.team {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(team.color)
                                .frame(width: 16, height: 16)
                            
                            Text(team.name)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 8) {
                    Text("\(stats.totalMatches)")
                        .font(.title)
                        .fontWeight(.bold)
                        .foregroundColor(.blue)
                    
                    Text("試合出場")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f%%", stats.winRate))
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(getSuccessRateColor(stats.winRate))
                    
                    Text("勝率")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // 統計サマリー
            LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 16) {
                StatSummaryItem(
                    title: "総プレー",
                    value: "\(player.stats.count)",
                    color: .blue
                )
                
                StatSummaryItem(
                    title: "成功率",
                    value: String(format: "%.1f%%", calculateOverallSuccessRate()),
                    color: .green
                )
                
                StatSummaryItem(
                    title: "勝利貢献",
                    value: "\(stats.wins)勝",
                    color: .orange
                )
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
    
    private func calculateOverallSuccessRate() -> Double {
        guard !player.stats.isEmpty else { return 0.0 }
        let successfulStats = player.stats.filter { $0.isSuccess }.count
        return (Double(successfulStats) / Double(player.stats.count)) * 100
    }
}

struct StatSummaryItem: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

struct PlayerTrendChartView: View {
    let player: Player
    
    private var trendData: [StatTrend] {
        generateTrendData(for: player)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("成功率推移")
                .font(.headline)
                .fontWeight(.semibold)
            
            if !trendData.isEmpty {
                ForEach(trendData.prefix(3), id: \.statType) { trend in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(getStatTypeDisplayName(trend.statType))
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Spacer()
                            
                            if let latest = trend.dataPoints.last {
                                Text(String(format: "%.1f%%", latest.successRate))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(getSuccessRateColor(latest.successRate))
                            }
                        }
                        
                        // ここに実際のチャートを配置（Chart フレームワークを使用）
                        SimpleTrendLineView(dataPoints: trend.dataPoints)
                            .frame(height: 60)
                    }
                    .padding()
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
                }
            } else {
                Text("データが不足しています")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 100)
                    .background(Color(.systemGray6))
                    .cornerRadius(8)
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func generateTrendData(for player: Player) -> [StatTrend] {
        let statsByType = Dictionary(grouping: player.stats) { $0.type }
        
        return statsByType.compactMap { (statType, stats) in
            guard stats.count >= 5 else { return nil }
            
            // 簡略化: 最新10個のスタッツから5個ずつのグループを作成
            let recentStats = Array(stats.suffix(10))
            let chunkSize = 2
            var dataPoints: [StatDataPoint] = []
            
            for i in stride(from: 0, to: recentStats.count, by: chunkSize) {
                let chunk = Array(recentStats[i..<min(i + chunkSize, recentStats.count)])
                let successCount = chunk.filter { $0.isSuccess }.count
                let successRate = Double(successCount) / Double(chunk.count) * 100
                
                dataPoints.append(StatDataPoint(
                    date: Date().addingTimeInterval(-Double(recentStats.count - i) * 3600),
                    successRate: successRate,
                    attempts: chunk.count
                ))
            }
            
            return StatTrend(statType: statType, dataPoints: dataPoints)
        }
    }
}

struct SimpleTrendLineView: View {
    let dataPoints: [StatDataPoint]
    
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                guard !dataPoints.isEmpty else { return }
                
                let maxRate = dataPoints.map { $0.successRate }.max() ?? 100
                let minRate = dataPoints.map { $0.successRate }.min() ?? 0
                let range = max(maxRate - minRate, 20) // 最小レンジを20%に設定
                
                let stepX = geometry.size.width / CGFloat(max(dataPoints.count - 1, 1))
                
                for (index, point) in dataPoints.enumerated() {
                    let x = CGFloat(index) * stepX
                    let normalizedRate = (point.successRate - minRate) / range
                    let y = geometry.size.height * (1 - normalizedRate)
                    
                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(Color.blue, lineWidth: 2)
            
            // データポイントを円で表示
            ForEach(dataPoints.indices, id: \.self) { index in
                let point = dataPoints[index]
                let maxRate = dataPoints.map { $0.successRate }.max() ?? 100
                let minRate = dataPoints.map { $0.successRate }.min() ?? 0
                let range = max(maxRate - minRate, 20)
                
                let stepX = geometry.size.width / CGFloat(max(dataPoints.count - 1, 1))
                let x = CGFloat(index) * stepX
                let normalizedRate = (point.successRate - minRate) / range
                let y = geometry.size.height * (1 - normalizedRate)
                
                Circle()
                    .fill(Color.blue)
                    .frame(width: 6, height: 6)
                    .position(x: x, y: y)
            }
        }
    }
}

struct PositionPerformanceView: View {
    let player: Player
    
    private var positionStats: [(StatType, Double)] {
        getPositionRelevantStats()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(player.position.displayName)としてのパフォーマンス")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 8) {
                ForEach(positionStats, id: \.0) { statType, successRate in
                    HStack {
                        Text(getStatTypeDisplayName(statType))
                            .font(.subheadline)
                        
                        Spacer()
                        
                        ProgressView(value: successRate / 100)
                            .frame(width: 100)
                        
                        Text(String(format: "%.1f%%", successRate))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(getSuccessRateColor(successRate))
                            .frame(width: 50, alignment: .trailing)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func getPositionRelevantStats() -> [(StatType, Double)] {
        let statsByType = Dictionary(grouping: player.stats) { $0.type }
        
        // ポジション別の重要な統計を定義
        let relevantStats: [StatType]
        switch player.position {
        case .tekong:
            relevantStats = [.serve, .serve_feint, .receive]
        case .feeder:
            relevantStats = [.setting, .receive, .block]
        case .striker:
            relevantStats = [.attack, .attack_feint, .heading, .rollspike]
        }
        
        return relevantStats.compactMap { statType in
            guard let stats = statsByType[statType], !stats.isEmpty else { return nil }
            let successCount = stats.filter { $0.isSuccess }.count
            let successRate = (Double(successCount) / Double(stats.count)) * 100
            return (statType, successRate)
        }
    }
}

struct DetailedStatsTableView: View {
    let player: Player
    
    private var statsSummary: [StatTypeSummary] {
        getDetailedStatsSummary()
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("詳細統計")
                .font(.headline)
                .fontWeight(.semibold)
            
            VStack(spacing: 1) {
                // ヘッダー
                HStack {
                    Text("プレータイプ")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("成功/試行")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 80, alignment: .center)
                    
                    Text("成功率")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                        .frame(width: 60, alignment: .trailing)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(.systemGray5))
                
                // データ行
                ForEach(statsSummary, id: \.statType) { summary in
                    HStack {
                        Text(getStatTypeDisplayName(summary.statType))
                            .font(.subheadline)
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                        Text("\(summary.successful)/\(summary.total)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .frame(width: 80, alignment: .center)
                        
                        Text(String(format: "%.1f%%", summary.successRate))
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(getSuccessRateColor(summary.successRate))
                            .frame(width: 60, alignment: .trailing)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color(.systemBackground))
                }
            }
            .background(Color(.systemGray6))
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
    
    private func getDetailedStatsSummary() -> [StatTypeSummary] {
        let statsByType = Dictionary(grouping: player.stats) { $0.type }
        
        return statsByType.map { (statType, stats) in
            let successful = stats.filter { $0.isSuccess }.count
            let total = stats.count
            let successRate = total > 0 ? (Double(successful) / Double(total)) * 100 : 0
            
            return StatTypeSummary(
                statType: statType,
                successful: successful,
                total: total,
                successRate: successRate
            )
        }.sorted { $0.total > $1.total }
    }
}

struct StatTypeSummary {
    let statType: StatType
    let successful: Int
    let total: Int
    let successRate: Double
}
