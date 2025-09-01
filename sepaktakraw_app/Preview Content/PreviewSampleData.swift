//
//  PreviewSampleData.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/16.
//

import SwiftUI
import SwiftData

@MainActor
class PreviewSampleData {
    static let container: ModelContainer = {
        do {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let container = try ModelContainer(for: Team.self, Player.self, Match.self, configurations: config)
            
            let teamA = Team(name: "千葉大学A", color: .red)
            let teamB = Team(name: "千葉大学B", color: .blue)

            // ✨ エラー修正: 全てのPlayerに dominantFoot を追加
            let player1 = Player(name: "はると", position: .tekong, dominantFoot: .right, team: teamA, serverType: .inside)
            let player2 = Player(name: "はやて", position: .feeder, dominantFoot: .left, team: teamA)
            let player3 = Player(name: "エイジ", position: .striker, dominantFoot: .right, team: teamA, attackType: .rolling)
            
            let player4 = Player(name: "かづま", position: .tekong, dominantFoot: .left, team: teamB, serverType: .instep)
            let player5 = Player(name: "ともや", position: .feeder, dominantFoot: .right, team: teamB)
            let player6 = Player(name: "こうせい", position: .striker, dominantFoot: .right, team: teamB, attackType: .sunback)
            
            teamA.players = [player1, player2, player3]
            teamB.players = [player4, player5, player6]

            let sampleMatch = Match(date: Date(), teamA: teamA, teamB: teamB, teamAServesFirst: true)
            
            container.mainContext.insert(teamA)
            container.mainContext.insert(teamB)
            container.mainContext.insert(sampleMatch)

            return container
        } catch {
            fatalError("Failed to create container: \(error.localizedDescription)")
        }
    }()
}
