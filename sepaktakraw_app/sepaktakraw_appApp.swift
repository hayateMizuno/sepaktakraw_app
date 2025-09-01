//
//  sepaktakraw_appApp.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/05.
//

import SwiftUI
import SwiftData

@main
struct sepaktakraw_appApp: App {
    var body: some Scene {
        WindowGroup {
            HomeView()
        }
        .modelContainer(for: [Team.self, Player.self, Match.self]) { result in
            switch result {
            case .success(let container):
                // ✨ 修正: アプリ起動時にサンプルデータとBotチームを作成する
                Task { @MainActor in
                    do {
                        let context = container.mainContext
                        let descriptor = FetchDescriptor<Team>()
                        let existingTeams = try context.fetch(descriptor)
                        
                        // ユーザーが作成したチームがまだない場合のみサンプルデータを投入
                        if existingTeams.filter({ !$0.isBotTeam }).isEmpty {
                            print("No user teams found. Inserting sample data...")
                            insertSampleData(into: context)
                        } else {
                            print("User teams found. Skipping sample data insertion.")
                        }
                        
                        // Botチームが存在するか確認し、なければ作成
                        if existingTeams.filter({ $0.isBotTeam }).isEmpty {
                            print("Bot team not found. Creating one...")
                            createBotTeam(into: context)
                        } else {
                            print("Bot team already exists.")
                        }
                        
                        try context.save()
                        
                    } catch {
                        print("Failed to set up initial data: \(error.localizedDescription)")
                    }
                }
            case .failure(let error):
                print("Failed to create ModelContainer: \(error.localizedDescription)")
            }
        }
    }

    /// 初回起動用のサンプルデータを挿入する
    private func insertSampleData(into context: ModelContext) {
        let teamA = Team(name: "千葉大学A", color: .red)
        let teamB = Team(name: "千葉大学B", color: .blue)

        let player1 = Player(name: "はると", position: .tekong, dominantFoot: .right, team: teamA, serverType: .inside)
        let player2 = Player(name: "はやて", position: .feeder, dominantFoot: .left, team: teamA)
        let player3 = Player(name: "エイジ", position: .striker, dominantFoot: .right, team: teamA, attackType: .rolling)
        
        let player4 = Player(name: "かづま", position: .tekong, dominantFoot: .left, team: teamB, serverType: .instep)
        let player5 = Player(name: "ともや", position: .feeder, dominantFoot: .right, team: teamB)
        let player6 = Player(name: "こうせい", position: .striker, dominantFoot: .right, team: teamB, attackType: .sunback)
        
        teamA.players = [player1, player2, player3]
        teamB.players = [player4, player5, player6]
        
        context.insert(teamA)
        context.insert(teamB)
    }
    
    /// Botチームを作成する
    private func createBotTeam(into context: ModelContext) {
        let bot = Team(name: "対戦相手 (Bot)", color: .gray, isBotTeam: true)
        let bot1 = Player(name: "Bot Striker", position: .striker, dominantFoot: .right, team: bot, isBotPlayer: true)
        let bot2 = Player(name: "Bot Feeder", position: .feeder, dominantFoot: .right, team: bot, isBotPlayer: true)
        let bot3 = Player(name: "Bot Tekong", position: .tekong, dominantFoot: .right, team: bot, isBotPlayer: true)
        bot.players = [bot1, bot2, bot3]
        context.insert(bot)
    }
}
