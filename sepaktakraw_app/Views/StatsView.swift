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
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationStack {
            VStack {
                Picker("統計タイプ", selection: $selectedTab) {
                    Text("チーム別").tag(0)
                    Text("選手別").tag(1)
                    Text("試合別").tag(2)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding()
                
                switch selectedTab {
                case 0:
                    TeamStatsView()
                case 1:
                    PlayerStatsView()
                case 2:
                    MatchStatsView()
                default:
                    Spacer()
                }
            }
            .navigationTitle("統計")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - チーム別統計画面
struct TeamStatsView: View {
    @Query(sort: \Team.name) private var teams: [Team]
    
    var body: some View {
        List {
            ForEach(teams) { team in
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
    @Query private var matches: [Match]
    
    private var teamStats: TeamStatistics {
        calculateTeamStats(for: team, allMatches: matches)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Circle().fill(team.color).frame(width: 20, height: 20)
                Text(team.name).font(.headline).fontWeight(.semibold)
                Spacer()
                Text("\(teamStats.totalMatches)試合").font(.caption).foregroundColor(.secondary)
            }
            HStack(spacing: 16) {
                StatPill(title: "勝利", value: "\(teamStats.wins)", color: .green)
                StatPill(title: "敗北", value: "\(teamStats.losses)", color: .red)
                StatPill(title: "勝率", value: String(format: "%.1f%%", teamStats.winRate), color: .blue)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - チーム詳細統計画面
struct TeamDetailStatsView: View {
    let team: Team
    
    var body: some View {
        List {
            Section("チーム概要") {
                TeamOverviewSection(team: team)
            }
            
            Section("選手一覧") {
                ForEach(team.players.sorted(by: { $0.position.sortOrder < $1.position.sortOrder })) { player in
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
    @Query private var matches: [Match]
    
    private var teamStats: TeamStatistics {
        calculateTeamStats(for: team, allMatches: matches)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Circle().fill(team.color).frame(width: 30, height: 30)
                VStack(alignment: .leading) {
                    Text(team.name).font(.title2).fontWeight(.bold)
                    Text("\(team.players.count)名の選手").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
            }
            
            HStack(spacing: 16) {
                StatCard(title: "総試合数", value: "\(teamStats.totalMatches)", color: .blue)
                StatCard(title: "勝利", value: "\(teamStats.wins)", color: .green)
                StatCard(title: "敗北", value: "\(teamStats.losses)", color: .red)
                StatCard(title: "勝率", value: String(format: "%.0f%%", teamStats.winRate), color: .orange)
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
                Text(getStatTypeDisplayName(aggregate.statType)).font(.subheadline)
                Spacer()
                VStack(alignment: .trailing) {
                    Text("\(aggregate.successful)/\(aggregate.total)").font(.caption).foregroundColor(.secondary)
                    Text(String(format: "%.1f%%", aggregate.successRate)).font(.subheadline).fontWeight(.semibold).foregroundColor(getSuccessRateColor(aggregate.successRate))
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - 選手別統計画面
struct PlayerStatsView: View {
    @Query(sort: \Team.name) private var teams: [Team]
    
    private var allPlayers: [Player] {
        teams.flatMap { $0.players }.sorted(by: { $0.name < $1.name })
    }
    
    var body: some View {
        List {
            ForEach(allPlayers) { player in
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
                Text(player.name).font(.headline).fontWeight(.semibold)
                HStack(spacing: 8) {
                    Text(player.position.displayName).font(.caption).padding(.horizontal, 8).padding(.vertical, 2).background(Color.blue.opacity(0.1)).cornerRadius(4)
                    if let team = player.team {
                        HStack(spacing: 4) {
                            Circle().fill(team.color).frame(width: 8, height: 8)
                            Text(team.name).font(.caption).foregroundColor(.secondary)
                        }
                    }
                }
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                Text("\(player.stats.count)").font(.headline).fontWeight(.semibold)
                Text("総プレー数").font(.caption).foregroundColor(.secondary)
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
            Section("統計詳細 (全期間)") {
                ForEach(StatType.allCases, id: \.self) { statType in
                    if let stats = statsByType[statType], !stats.isEmpty {
                        PlayerStatDetailRow(statType: statType, stats: stats)
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
                    Text(player.name).font(.title2).fontWeight(.bold)
                    Text(player.position.displayName).font(.subheadline).padding(.horizontal, 12).padding(.vertical, 4).background(Color.blue.opacity(0.1)).cornerRadius(6)
                }
                Spacer()
                if let team = player.team {
                    VStack(alignment: .trailing) {
                        Circle().fill(team.color).frame(width: 40, height: 40)
                        Text(team.name).font(.caption).foregroundColor(.secondary)
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
    
    private var successfulCount: Int { stats.filter { $0.isSuccess }.count }
    private var successRate: Double {
        guard !stats.isEmpty else { return 0.0 }
        return (Double(successfulCount) / Double(stats.count)) * 100
    }
    
    var body: some View {
        HStack {
            Text(getStatTypeDisplayName(statType)).font(.subheadline)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text("\(successfulCount)/\(stats.count)").font(.caption).foregroundColor(.secondary)
                Text(String(format: "%.1f%%", successRate)).font(.subheadline).fontWeight(.semibold).foregroundColor(getSuccessRateColor(successRate))
            }
        }
        .padding(.vertical, 4)
    }
}

struct RecentStatsSection: View {
    let player: Player
    
    private var recentStats: [Stat] {
        Array(player.stats.suffix(10).reversed())
    }
    
    var body: some View {
        ForEach(recentStats) { stat in
            HStack {
                Text(getStatTypeDisplayName(stat.type)).font(.caption)
                Spacer()
                Image(systemName: stat.isSuccess ? "checkmark.circle.fill" : "xmark.circle.fill").foregroundColor(stat.isSuccess ? .green : .red).font(.caption)
                if let reason = stat.failureReason, !stat.isSuccess {
                    Text(getFailureReasonDisplayName(reason)).font(.caption2).foregroundColor(.secondary)
                }
            }
            .padding(.vertical, 2)
        }
    }
}

// MARK: - 試合別統計画面
struct MatchStatsView: View {
    @Query(sort: \Match.date, order: .reverse) private var matches: [Match]
    
    var body: some View {
        List {
            ForEach(matches) { match in
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
                Text(formatDate(match.date, dateStyle: .medium, timeStyle: .short)).font(.subheadline).fontWeight(.semibold)
                Spacer()
                Text("\(match.scoreA) - \(match.scoreB)").font(.title3).fontWeight(.bold).foregroundColor(.primary)
            }
            HStack {
                if let teamA = match.teamA {
                    TeamLabel(team: teamA, isWinner: match.scoreA > match.scoreB)
                }
                Text("vs").font(.caption).foregroundColor(.secondary).padding(.horizontal, 8)
                if let teamB = match.teamB {
                    TeamLabel(team: teamB, isWinner: match.scoreB > match.scoreA)
                }
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

struct TeamLabel: View {
    let team: Team
    let isWinner: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Circle().fill(team.color).frame(width: 12, height: 12)
            Text(team.name).font(.subheadline).fontWeight(isWinner ? .semibold : .regular).foregroundColor(isWinner ? .primary : .secondary)
            if isWinner {
                Image(systemName: "crown.fill").foregroundColor(.yellow).font(.caption)
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
            
            if let teamA = match.teamA {
                Section("\(teamA.name) の統計") {
                    TeamMatchStatsSection(team: teamA, match: match)
                }
            }
            
            if let teamB = match.teamB {
                Section("\(teamB.name) の統計") {
                    TeamMatchStatsSection(team: teamB, match: match)
                }
            }
        }
        .navigationTitle(formatDate(match.date, dateStyle: .short))
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MatchResultSection: View {
    let match: Match
    
    var body: some View {
        VStack(spacing: 16) {
            Text(formatDate(match.date, dateStyle: .full, timeStyle: .short)).font(.headline).foregroundColor(.secondary)
            HStack {
                TeamScoreDetailView(team: match.teamA)
                Spacer()
                VStack {
                    Text("\(match.scoreA) - \(match.scoreB)").font(.title).fontWeight(.bold)
                    Text(getWinnerName() + " の勝利").font(.caption).foregroundColor(.secondary)
                }
                Spacer()
                TeamScoreDetailView(team: match.teamB)
            }
        }
        .padding(.vertical, 12)
    }
    
    private func getWinnerName() -> String {
        if match.scoreA > match.scoreB {
            return match.teamA?.name ?? "チームA"
        } else if match.scoreB > match.scoreA {
            return match.teamB?.name ?? "チームB"
        } else {
            return "引き分け"
        }
    }
}

struct TeamScoreDetailView: View {
    let team: Team?
    
    var body: some View {
        VStack {
            if let team = team {
                Circle().fill(team.color).frame(width: 40, height: 40)
                Text(team.name).font(.subheadline).fontWeight(.semibold)
            }
        }
    }
}


struct TeamMatchStatsSection: View {
    let team: Team
    let match: Match
    
    var body: some View {
        ForEach(team.players) { player in
            PlayerMatchStatsRow(player: player, match: match)
        }
    }
}

struct PlayerMatchStatsRow: View {
    let player: Player
    let match: Match

    private var playsInThisMatch: Int {
        player.stats.filter { $0.matchID == match.id }.count
    }
    
    var body: some View {
        HStack {
            Text(player.name).font(.subheadline)
            Text("(\(player.position.displayName))").font(.caption).foregroundColor(.secondary)
            Spacer()
            Text("\(playsInThisMatch)プレー").font(.caption).foregroundColor(.secondary)
        }
        .padding(.leading, 16)
    }
}

// MARK: - ヘルパービュー
struct StatPill: View {
    let title: String, value: String, color: Color
    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.caption).fontWeight(.semibold).foregroundColor(color)
            Text(title).font(.caption2).foregroundColor(.secondary)
        }
        .padding(.horizontal, 8).padding(.vertical, 4).background(color.opacity(0.1)).cornerRadius(6)
    }
}

struct StatCard: View {
    let title: String, value: String, color: Color
    var body: some View {
        VStack(spacing: 4) {
            Text(value).font(.headline).fontWeight(.bold).foregroundColor(color)
            Text(title).font(.caption).foregroundColor(.secondary).multilineTextAlignment(.center)
        }
        .frame(minWidth: 60).padding(.vertical, 8).padding(.horizontal, 12).background(color.opacity(0.1)).cornerRadius(8)
    }
}

// MARK: - データ構造
struct TeamStatistics {
    let totalMatches: Int, wins: Int, losses: Int, winRate: Double
}

struct StatTypeAggregate: Identifiable {
    var id: StatType { statType }
    let statType: StatType, successful: Int, total: Int, successRate: Double
}

// MARK: - ヘルパー関数
private func calculateTeamStats(for team: Team, allMatches: [Match]) -> TeamStatistics {
    let teamMatches = allMatches.filter { $0.teamA?.id == team.id || $0.teamB?.id == team.id }
    let totalMatches = teamMatches.count
    guard totalMatches > 0 else { return TeamStatistics(totalMatches: 0, wins: 0, losses: 0, winRate: 0.0) }
    let wins = teamMatches.filter { ($0.teamA?.id == team.id && $0.scoreA > $0.scoreB) || ($0.teamB?.id == team.id && $0.scoreB > $0.scoreA) }.count
    let losses = totalMatches - wins
    let winRate = (Double(wins) / Double(totalMatches)) * 100
    return TeamStatistics(totalMatches: totalMatches, wins: wins, losses: losses, winRate: winRate)
}

private func calculateAggregateStats(for team: Team) -> [StatTypeAggregate] {
    var aggregates: [StatType: (successful: Int, total: Int)] = [:]
    for player in team.players {
        for stat in player.stats {
            let current = aggregates[stat.type] ?? (successful: 0, total: 0)
            aggregates[stat.type] = (successful: current.successful + (stat.isSuccess ? 1 : 0), total: current.total + 1)
        }
    }
    return aggregates.map { (statType, data) in
        let successRate = data.total > 0 ? (Double(data.successful) / Double(data.total)) * 100 : 0
        return StatTypeAggregate(statType: statType, successful: data.successful, total: data.total, successRate: successRate)
    }.sorted { $0.total > $1.total }
}

func getStatTypeDisplayName(_ statType: StatType) -> String {
    // ✨ エラー修正: return文を追加
    switch statType {
    case .serve: return "サーブ"
    case .serve_feint: return "フェイントサーブ"
    case .attack: return "アタック"
    case .attack_feint: return "フェイントアタック"
    case .block: return "ブロック"
    case .receive: return "レシーブ"
    case .setting: return "トス"
    case .heading: return "ヘディング"
    case .rollspike: return "ローリング"
    case .sunbackspike: return "シザース"
    }
}

func getFailureReasonDisplayName(_ reason: FailureReason) -> String {
    // ✨ エラー修正: return文を追加
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
    // ✨ エラー修正: return文を追加
    switch rate {
    case 80...: return .green
    case 60..<80: return .blue
    case 40..<60: return .orange
    default: return .red
    }
}

func formatDate(_ date: Date, dateStyle: DateFormatter.Style = .short, timeStyle: DateFormatter.Style = .none) -> String {
    let formatter = DateFormatter()
    formatter.dateStyle = dateStyle
    formatter.timeStyle = timeStyle
    formatter.locale = Locale(identifier: "ja_JP")
    return formatter.string(from: date)
}

// MARK: - プレビュー
#Preview {
    HomeView()
        .modelContainer(PreviewSampleData.container)
}
