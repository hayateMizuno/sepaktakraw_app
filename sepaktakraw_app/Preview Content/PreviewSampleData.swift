//
//  PreviewSampleData.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/16.
//

import SwiftUI
import SwiftData

@MainActor
struct PreviewSampleData {
    // プレビュー用のModelContainerを生成し、サンプルデータを投入する
    static let container: ModelContainer = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            // ✨ 修正点: ModelContainerのfor:パラメータにMatch.selfを追加
            let container = try ModelContainer(for: Team.self, Player.self, Match.self, configurations: config)
            
            // サンプルチームと選手を作成
            let teamA = Team(name: "千葉大学A", color: .red) // 赤
            let teamB = Team(name: "千葉大学B", color: .blue) // 青

            let player1 = Player(name: "はると", position: .tekong, team: teamA)
            let player2 = Player(name: "はやて", position: .feeder, team: teamA)
            let player3 = Player(name: "エイジ", position: .striker, team: teamA)
            
            let player4 = Player(name: "かづま", position: .tekong, team: teamB)
            let player5 = Player(name: "ともや", position: .feeder, team: teamB)
            let player6 = Player(name: "こうせい", position: .striker, team: teamB)
            
            // チームに選手を追加
            teamA.players.append(contentsOf: [player1, player2, player3])
            teamB.players.append(contentsOf: [player4, player5, player6])

            // ✨ 追加: サンプルMatchデータを作成し、コンテナに挿入
            let sampleMatch = Match(date: Date(), teamA: teamA, teamB: teamB, teamAServesFirst: true)
            
            // データベースに保存
            container.mainContext.insert(teamA)
            container.mainContext.insert(teamB)
            container.mainContext.insert(sampleMatch) // Matchも挿入

            return container
        } catch {
            fatalError("Failed to create container: \(error.localizedDescription)")
        }
    }()
}
