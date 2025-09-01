//
//  SepakModels.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/14.
//

import Foundation
import SwiftData
import SwiftUI


// 利き足
enum DominantFoot: String, Codable, CaseIterable {
    case right = "右足"
    case left = "左足"
}

// アタッカーの得意なアタック
enum AttackType: String, Codable, CaseIterable {
    case rolling = "ローリング"
    case sunback = "シザース"
}

// サーバーの得意なサーブ
enum ServerType: String, Codable, CaseIterable {
    case inside = "インサイド"
    case instep = "インステップ"
}

//失敗の理由
enum FailureReason: String, Codable, CaseIterable {
    case out // アウト
    case blocked // ブロックされる
    case net // ネットにかかる
    case fault // サーブフォルト、ネットタッチなど
    case received //レシーブされた
    case overSet //トスがオーバー
    case chanceBall //チャンスボールで返した
    case blockCover //ブロックカバー
    case over   //オーバー
}

// 1回のプレー(スタッツ)を表す
struct Stat: Codable, Identifiable {
    var id = UUID()
    let type: StatType // プレーの種類
    let matchID: UUID // 試合に対するID
    let isSuccess: Bool // 成功したかどうか
    var failureReason: FailureReason? = nil // 失敗した場合の理由
}

// チーム
@Model
class Team {
    var id: UUID
    var name: String
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double
    
    // ✨ 修正: Botチームかどうかを識別するフラグを追加
    var isBotTeam: Bool
    
    @Relationship(deleteRule: .cascade, inverse: \Player.team)
    var players: [Player] = []
    
    init(name: String, color: Color = .red, isBotTeam: Bool = false) {
        self.id = UUID()
        self.name = name
        let resolvedColor = color.resolve(in: EnvironmentValues())
        self.red = Double(resolvedColor.red)
        self.green = Double(resolvedColor.green)
        self.blue = Double(resolvedColor.blue)
        self.opacity = Double(resolvedColor.opacity)
        self.isBotTeam = isBotTeam
    }
    
    var color: Color {
        get { Color(red: red, green: green, blue: blue, opacity: opacity) }
        set {
            let resolvedColor = newValue.resolve(in: EnvironmentValues())
            self.red = Double(resolvedColor.red)
            self.green = Double(resolvedColor.green)
            self.blue = Double(resolvedColor.blue)
            self.opacity = Double(resolvedColor.opacity)
        }
    }
}

// 選手
@Model
class Player {
    var id: UUID
    var name: String
    var position: Position
    var team: Team? // どのチームに所属しているか
    var dominantFoot: DominantFoot
    var attackType: AttackType? // アタッカーのみ
    var serverType: ServerType?   // サーバーのみ
    // SwiftDataでStatを直接保存するためのプロパティ（修正版）
    var statsData: Data = Data()
    
    // ✨ 追加: Bot選手かどうかを識別するフラグ
    var isBotPlayer: Bool = false
    
    // 計算プロパティでStatsを管理
    var stats: [Stat] {
        get {
            guard !statsData.isEmpty else { return [] }
            do {
                return try JSONDecoder().decode([Stat].self, from: statsData)
            } catch {
                print("Error decoding stats: \(error)")
                return []
            }
        }
        set {
            do {
                statsData = try JSONEncoder().encode(newValue)
            } catch {
                print("Error encoding stats: \(error)")
            }
        }
        
    }
    
    init(name: String, position: Position, dominantFoot: DominantFoot, team: Team? = nil, attackType: AttackType? = nil, serverType: ServerType? = nil, isBotPlayer: Bool = false) {
        self.id = UUID()
        self.name = name
        self.position = position
        self.dominantFoot = dominantFoot
        self.team = team
        self.attackType = attackType
        self.serverType = serverType
        self.isBotPlayer = isBotPlayer
    }
    
    /// 統計を追加する便利メソッド
    func addStat(_ stat: Stat) {
        var currentStats = stats
        currentStats.append(stat)
        stats = currentStats
    }
    
    /// 指定された種類のプレーの成功率を計算して返す (例: 75.0 %)
    /// - Parameter type: 成功率を計算したいプレーの種類 (例: .attack)
    /// - Returns: 成功率(パーセント)
    func successRate(for type: StatType) -> Double {
        // 1. 全スタッツの中から、指定された種類のプレーだけを抜き出す
        let relevantStats = stats.filter { $0.type == type }
        
        // 2. 試行回数が0の場合は、0%を返す (0での割り算を防ぐ)
        guard !relevantStats.isEmpty else {
            return 0.0
        }
        
        // 3. 抜き出したプレーの中から、成功したものの数を数える
        let successfulAttempts = relevantStats.filter { $0.isSuccess }.count
        
        // 4. 全体の試行回数を取得
        let totalAttempts = relevantStats.count
        
        // 5. 「成功数 ÷ 全体の試行回数 * 100」を計算して返す
        return (Double(successfulAttempts) / Double(totalAttempts)) * 100
    }
}

@Model
class Match {
    var id: UUID
    var date: Date
    var teamA: Team? // チームAへのリレーション
    var teamB: Team? // チームBへのリレーション
    var scoreA: Int
    var scoreB: Int
    var teamAServesFirst: Bool // チームAが最初にサーブしたかどうか
    // ✨ 追加: 同じチームの場合の区別用サフィックス
    var teamASuffix: String?
    var teamBSuffix: String?
    // 試合に参加した選手を保存するためのリレーションシップ
    @Relationship(deleteRule: .nullify)
    var participatingPlayersA: [Player] = []
    
    @Relationship(deleteRule: .nullify)
    var participatingPlayersB: [Player] = []
    
    init(date: Date, teamA: Team?, teamB: Team?, teamAServesFirst: Bool) {
        self.id = UUID()
        self.date = date
        self.teamA = teamA
        self.teamB = teamB
        self.scoreA = 0
        self.scoreB = 0
        self.teamAServesFirst = teamAServesFirst
        self.teamASuffix = teamASuffix
        self.teamBSuffix = teamBSuffix
    }
}


// ポジションの種類を定義するEnum
enum Position: String, CaseIterable, Codable {
    case tekong  // テコン（サーバー）
    case feeder  // フィーダー（トサー）
    case striker // ストライカー（アタッカー）
    
    // 画面に表示するときの名前
    var displayName: String {
        switch self {
        case .tekong:
            return "サーバー"
        case .feeder:
            return "トサー"
        case .striker:
            return "アタッカー"
        }
    }
    
    var sortOrder: Int {
        switch self {
        case .feeder: return 1 // トサーが一番左
        case .tekong: return 2 // サーバーが真ん中
        case .striker: return 3 // アタッカーが一番右
        }
    }
}

// これから記録するスタッツの種類
enum StatType: String, Codable, CaseIterable {
    case serve
    case serve_feint
    case attack
    case attack_feint
    case block
    case receive
    case setting
    case heading
    case rollspike
    case sunbackspike
}
