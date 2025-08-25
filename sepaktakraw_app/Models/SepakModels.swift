//
//  SepakModels.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/14.
//

import Foundation
import SwiftData
import SwiftUI

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
}

// 1回のプレー(スタッツ)を表す
struct Stat: Codable, Identifiable {
    var id = UUID()
    let type: StatType // プレーの種類
    let isSuccess: Bool // 成功したかどうか
    var failureReason: FailureReason? = nil // 失敗した場合の理由
}

// チーム
@Model
class Team {
    var id: UUID
    var name: String
    // ColorをRGBAの各コンポーネントに分解して保存
    var red: Double
    var green: Double
    var blue: Double
    var opacity: Double // alpha値
    
    @Relationship(deleteRule: .cascade, inverse: \Player.team)
    var players: [Player] = []

    init(name: String, color: Color = .red) {
        self.id = UUID()
        self.name = name
        // ColorからRGBAコンポーネントを抽出（修正版）
        let resolvedColor = color.resolve(in: EnvironmentValues())
        self.red = Double(resolvedColor.red)
        self.green = Double(resolvedColor.green)
        self.blue = Double(resolvedColor.blue)
        self.opacity = Double(resolvedColor.opacity)
    }
    
    // 計算プロパティとしてColorを公開（修正版）
    var color: Color {
        get {
            Color(red: red, green: green, blue: blue, opacity: opacity)
        }
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
    // SwiftDataでStatを直接保存するためのプロパティ（修正版）
    var statsData: Data = Data()
    
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
    
    init(name: String, position: Position, team: Team? = nil) {
        self.id = UUID()
        self.name = name
        self.position = position
        self.team = team
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
    // 必要に応じて、試合結果やセット数などのプロパティを追加
    
    init(date: Date, teamA: Team?, teamB: Team?, teamAServesFirst: Bool) {
        self.id = UUID()
        self.date = date
        self.teamA = teamA
        self.teamB = teamB
        self.scoreA = 0
        self.scoreB = 0
        self.teamAServesFirst = teamAServesFirst
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
}
