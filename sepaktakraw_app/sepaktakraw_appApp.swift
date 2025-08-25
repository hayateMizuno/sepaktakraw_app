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
        .modelContainer(for: [Team.self, Player.self]) { result in // forの後にクロージャを追加
            switch result {
            case .success(let container):
                // 初回起動時のみサンプルデータを追加
                do {
                    let descriptor = FetchDescriptor<Team>()
                    let existingTeams = try container.mainContext.fetch(descriptor)
                    
                    if existingTeams.isEmpty {
                        print("No existing teams found. Inserting sample data...")
                        insertSampleData(into: container.mainContext)
                        try container.mainContext.save()
                        print("Sample data inserted successfully.")
                    } else {
                        print("Existing teams found. Skipping sample data insertion.")
                    }
                } catch {
                    print("Failed to fetch or insert sample data: \(error.localizedDescription)")
                }
            case .failure(let error):
                print("Failed to create ModelContainer: \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Sample Data Insertion Logic

    private func insertSampleData(into context: ModelContext) {
        let teamA = Team(name: "千葉大学A", color: .red)
        let teamB = Team(name: "千葉大学B", color: .blue)

        let player1 = Player(name: "はると", position: .tekong, team: teamA)
        let player2 = Player(name: "はやて", position: .feeder, team: teamA)
        let player3 = Player(name: "エイジ", position: .striker, team: teamA)
        
        let player4 = Player(name: "かづま", position: .tekong, team: teamB)
        let player5 = Player(name: "ともや", position: .feeder, team: teamB)
        let player6 = Player(name: "こうせい", position: .striker, team: teamB)
        
        teamA.players.append(contentsOf: [player1, player2, player3])
        teamB.players.append(contentsOf: [player4, player5, player6])
        
        context.insert(teamA)
        context.insert(teamB)
    }
}
