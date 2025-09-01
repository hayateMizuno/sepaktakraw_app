//
//  StatsView.swift
//  sepaktakraw_app
//
//  Created by Claude on 2025/09/01.
//

import SwiftUI
import SwiftData

// MARK: - メイン統計画面
struct StatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var teams: [Team]
    @Query private var matches: [Match]
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                // タブ選択
                Picker("統計タイプ", selection: $selectedTab) {
                    Text("チーム別").tag(0)
                    Text("選手別").tag(1)
                    Text("試合別").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                // タブに応じたコンテンツ
                TabView(selection: $selectedTab) {
                    TeamStatsView()
                        .tag(0)
                    
                    PlayerStatsView()
                        .tag(1)
                    
                    MatchStatsView()
                        .tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - チーム別統計画面
struct TeamStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var teams: [Team]
    
    var body: some View {
        List {
            ForEach(teams, id: \.id) { team in
                NavigationLink(destination: TeamDetailStatsView(team: team)) {
                    TeamStatsRow(team: team)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct TeamStatsRow: View {
    let team: Team
    
    private var teamStats: TeamStatistics {
        calculateTeamStats(for: team)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle()
                    .fill(team.color)
                    .frame(width: 20, height: 20)
                
                Text(team.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(teamStats.totalMatches)試合")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            HStack(spacing: 16) {
                StatPill(title: "勝利", value: "\(teamStats.wins)", color: .green)
                StatPill(title: "敗北", value: "\(teamStats.losses)", color: .red)
                StatPill(title: "勝率", value: String(format: "%.1f%%", teamStats.winRate), color: .blue)
            }
        }
        .padding(.vertical, 4)
    }
    
    private func calculateTeamStats(for team: Team) -> TeamStatistics {
        // SwiftDataクエリから試合データを取得する実装が必要
        // 簡略化のため、ダミーデータを返す
        return TeamStatistics(totalMatches: 5, wins: 3, losses: 2, winRate: 60.0)
    }
}

// MARK: - チーム詳細統計画面
struct TeamDetailStatsView: View {
    let team: Team
    @Environment(\.modelContext) private var modelContext
    
    var body: some View {
        List {
            Section("チーム概要") {
                TeamOverviewSection(team: team)
            }
            
            Section("選手一覧") {
                ForEach(team.players.sorted(by: { $0.position.sortOrder < $1.position.sortOrder }), id: \.id) { player in
                    NavigationLink(destination: PlayerDetailStatsView(player: player)) {
                        PlayerStatsRow(player: player)
                    }
                }
            }
            
            Section("チーム統計") {
                TeamAggregateStatsSection(team: team)
            }
        }
        .navigationTitle(team.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct TeamOverviewSection: View {
    let team: Team
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(team.color)
                    .frame(width: 30, height: 30)
                
                VStack(alignment: .leading) {
                    Text(team.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text("\(team.players.count)名の選手")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatCard(title: "総試合数", value: "5", color: .blue)
                StatCard(title: "勝利", value: "3", color: .green)
                StatCard(title: "敗北", value: "2", color: .red)
                StatCard(title: "勝率", value: "60%", color: .orange)
            }
        }
        .padding(.vertical, 8)
    }
}

struct TeamAggregateStatsSection: View {
    let team: Team
    
    private var aggregateStats: [StatTypeAggregate] {
        calculateAggregateStats(for: team)
    }
    
    var body: some View {
        ForEach(aggregateStats, id: \.statType) { aggregate in
            HStack {
                Text(getStatTypeDisplayName(aggregate.statType))
                    .font(.subheadline)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(aggregate.successful)/\(aggregate.total)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text(String(format: "%.1f%%", aggregate.successRate))
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(getSuccessRateColor(aggregate.successRate))
                }
            }
            .padding(.vertical, 2)
        }
    }
    
    private func calculateAggregateStats(for team: Team) -> [StatTypeAggregate] {
        var aggregates: [StatType: (successful: Int, total: Int)] = [:]
        
        for player in team.players {
            for stat in player.stats {
                let current = aggregates[stat.type] ?? (successful: 0, total: 0)
                aggregates[stat.type] = (
                    successful: current.successful + (stat.isSuccess ? 1 : 0),
                    total: current.total + 1
                )
            }
        }
        
        return aggregates.map { (statType, data) in
            let successRate = data.total > 0 ? (Double(data.successful) / Double(data.total)) * 100 : 0
            return StatTypeAggregate(
                statType: statType,
                successful: data.successful,
                total: data.total,
                successRate: successRate
            )
        }.sorted { $0.total > $1.total }
    }
}

// MARK: - 選手別統計画面
struct PlayerStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var teams: [Team]
    
    private var allPlayers: [Player] {
        teams.flatMap { $0.players }
    }
    
    var body: some View {
        List {
            ForEach(allPlayers, id: \.id) { player in
                NavigationLink(destination: PlayerDetailStatsView(player: player)) {
                    PlayerStatsRow(player: player)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct PlayerStatsRow: View {
    let player: Player
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(player.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                HStack(spacing: 8) {
                    Text(player.position.displayName)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(4)
                    
                    if let team = player.team {
                        HStack(spacing: 4) {
                            Circle()
                                .fill(team.color)
                                .frame(width: 8, height: 8)
                            
                            Text(team.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(player.stats.count)")
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text("総プレー数")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - 選手詳細統計画面
struct PlayerDetailStatsView: View {
    let player: Player
    
    private var statsByType: [StatType: [Stat]] {
        Dictionary(grouping: player.stats, by: { $0.type })
    }
    
    var body: some View {
        List {
            Section("選手情報") {
                PlayerInfoSection(player: player)
            }
            
            Section("統計詳細") {
                ForEach(StatType.allCases, id: \.self) { statType in
                    let stats = statsByType[statType] ?? []
                    if !stats.isEmpty {
                        PlayerStatDetailRow(
                            statType: statType,
                            stats: stats
                        )
                    }
                }
            }
            
            Section("最近の記録") {
                RecentStatsSection(player: player)
            }
        }
        .navigationTitle(player.name)
        .navigationBarTitleDisplayMode(.large)
    }
}

struct PlayerInfoSection: View {
    let player: Player
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text(player.name)
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    Text(player.position.displayName)
                        .font(.subheadline)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(6)
                }
                
                Spacer()
                
                if let team = player.team {
                    VStack(alignment: .trailing) {
                        Circle()
                            .fill(team.color)
                            .frame(width: 40, height: 40)
                        
                        Text(team.name)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            HStack(spacing: 16) {
                StatCard(title: "総プレー数", value: "\(player.stats.count)", color: .blue)
                StatCard(title: "成功率", value: String(format: "%.1f%%", calculateOverallSuccessRate()), color: .green)
            }
        }
        .padding(.vertical, 8)
    }
    
    private func calculateOverallSuccessRate() -> Double {
        guard !player.stats.isEmpty else { return 0.0 }
        let successfulStats = player.stats.filter { $0.isSuccess }.count
        return (Double(successfulStats) / Double(player.stats.count)) * 100
    }
}

struct PlayerStatDetailRow: View {
    let statType: StatType
    let stats: [Stat]
    
    private var successfulCount: Int {
        stats.filter { $0.isSuccess }.count
    }
    
    private var successRate: Double {
        guard !stats.isEmpty else { return 0.0 }
        return (Double(successfulCount) / Double(stats.count)) * 100
    }
    
    var body: some View {
        HStack {
            Text(getStatTypeDisplayName(statType))
                .font(.subheadline)
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(successfulCount)/\(stats.count)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Text(String(format: "%.1f%%", successRate))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(getSuccessRateColor(successRate))
            }
        }
        .padding(.vertical, 4)
    }
}

struct RecentStatsSection: View {
    let player: Player
    
    private var recentStats: [Stat] {
        Array(player.stats.suffix(10))
    }
    
    var body: some View {
        ForEach(recentStats.indices, id: \.self) { index in
            let stat = recentStats[index]
            HStack {
                Text(getStatTypeDisplayName(stat.type))
                    .font(.caption)
                
                Spacer()
                
                Image(systemName: stat.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill")
                    .foregroundColor(stat.isSuccess ? .green : .red)
                    .font(.caption)
                
                if let reason = stat.failureReason, !stat.isSuccess {
                    Text(getFailureReasonDisplayName(reason))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - 試合別統計画面
struct MatchStatsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var matches: [Match]
    
    var body: some View {
        List {
            ForEach(matches.sorted(by: { $0.date > $1.date }), id: \.id) { match in
                NavigationLink(destination: MatchDetailStatsView(match: match)) {
                    MatchStatsRow(match: match)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}

struct MatchStatsRow: View {
    let match: Match
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(formatDate(match.date))
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text("\(match.scoreA) - \(match.scoreB)")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            HStack {
                if let teamA = match.teamA {
                    TeamLabel(team: teamA, isWinner: match.scoreA > match.scoreB)
                }
                
                Text("vs")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, 8)
                
                if let teamB = match.teamB {
                    TeamLabel(team: teamB, isWinner: match.scoreB > match.scoreA)
                }
                
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TeamLabel: View {
    let team: Team
    let isWinner: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(team.color)
                .frame(width: 12, height: 12)
            
            Text(team.name)
                .font(.subheadline)
                .fontWeight(isWinner ? .semibold : .regular)
                .foregroundColor(isWinner ? .primary : .secondary)
            
            if isWinner {
                Image(systemName: "crown.fill")
                    .foregroundColor(.yellow)
                    .font(.caption)
            }
        }
    }
}

// MARK: - 試合詳細統計画面
struct MatchDetailStatsView: View {
    let match: Match
    
    var body: some View {
        List {
            Section("試合結果") {
                MatchResultSection(match: match)
            }
            
            Section("チーム統計") {
                if let teamA = match.teamA {
                    TeamMatchStatsSection(team: teamA, match: match, isTeamA: true)
                }
                
                if let teamB = match.teamB {
                    TeamMatchStatsSection(team: teamB, match: match, isTeamA: false)
                }
            }
        }
        .navigationTitle("試合詳細")
        .navigationBarTitleDisplayMode(.large)
    }
}

struct MatchResultSection: View {
    let match: Match
    
    var body: some View {
        VStack(spacing: 16) {
            Text(formatDate(match.date))
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                VStack {
                    if let teamA = match.teamA {
                        Circle()
                            .fill(teamA.color)
                            .frame(width: 40, height: 40)
                        
                        Text(teamA.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                VStack {
                    Text("\(match.scoreA) - \(match.scoreB)")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text(match.scoreA > match.scoreB ?
                         (match.teamA?.name ?? "チームA") + " の勝利" :
                         (match.teamB?.name ?? "チームB") + " の勝利")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                VStack {
                    if let teamB = match.teamB {
                        Circle()
                            .fill(teamB.color)
                            .frame(width: 40, height: 40)
                        
                        Text(teamB.name)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .padding(.vertical, 12)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .full
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct TeamMatchStatsSection: View {
    let team: Team
    let match: Match
    let isTeamA: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle()
                    .fill(team.color)
                    .frame(width: 20, height: 20)
                
                Text(team.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Text(isTeamA ? "\(match.scoreA)点" : "\(match.scoreB)点")
                    .font(.title3)
                    .fontWeight(.bold)
            }
            
            // この試合での各選手の統計を表示
            ForEach(team.players, id: \.id) { player in
                PlayerMatchStatsRow(player: player)
            }
        }
        .padding(.vertical, 8)
    }
}

struct PlayerMatchStatsRow: View {
    let player: Player
    
    var body: some View {
        HStack {
            Text(player.name)
                .font(.subheadline)
            
            Text("(\(player.position.displayName))")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Spacer()
            
            // 簡略化された統計表示
            Text("\(player.stats.count)プレー")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.leading, 16)
    }
}

// MARK: - ヘルパービュー
struct StatPill: View {
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(color)
            
            Text(title)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

struct StatCard: View {
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
                .multilineTextAlignment(.center)
        }
        .frame(minWidth: 60)
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

// MARK: - データ構造
struct TeamStatistics {
    let totalMatches: Int
    let wins: Int
    let losses: Int
    let winRate: Double
}

struct StatTypeAggregate {
    let statType: StatType
    let successful: Int
    let total: Int
    let successRate: Double
}

// MARK: - ヘルパー関数
func getStatTypeDisplayName(_ statType: StatType) -> String {
    switch statType {
    case .serve: return "サーブ"
    case .serve_feint: return "フェイントサーブ"
    case .attack: return "アタック"
    case .attack_feint: return "フェイントアタック"
    case .block: return "ブロック"
    case .receive: return "レシーブ"
    case .setting: return "セット"
    case .heading: return "ヘディング"
    case .rollspike: return "ロールスパイク"
    case .sunbackspike: return "サンバックスパイク"
    }
}

func getFailureReasonDisplayName(_ reason: FailureReason) -> String {
    switch reason {
    case .out: return "アウト"
    case .blocked: return "ブロック"
    case .net: return "ネット"
    case .fault: return "フォルト"
    case .received: return "レシーブ"
    case .overSet: return "オーバーセット"
    case .chanceBall: return "チャンスボール"
    case .blockCover: return "ブロックカバー"
    case .over: return "オーバー"
    }
}

func getSuccessRateColor(_ rate: Double) -> Color {
    switch rate {
    case 80...: return .green
    case 60..<80: return .blue
    case 40..<60: return .orange
    default: return .red
    }
}



// MARK: - プレビュー
#Preview {
    StatsView()
        .modelContainer(PreviewSampleData.container)
}
