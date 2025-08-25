//
//  MatchSetupView.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/15.
//

import SwiftUI
import SwiftData

struct MatchSetupView: View {
    @Environment(\.modelContext) private var modelContext // Add modelContext to save the new Match
    @Query private var teams: [Team]
    
    @State private var teamA: Team?
    @State private var teamB: Team?
    
    @State private var teamAServesFirst = true
    
    // The previous isReadyToStart logic is fine.
    private var isReadyToStart: Bool {
        guard let teamA = teamA, let teamB = teamB else { return false }
        // Ensure both teams have at least one player to start a match
        return !teamA.players.isEmpty && !teamB.players.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("対戦チームを選択")) {
                    Picker("チームA", selection: $teamA) {
                        Text("未選択").tag(nil as Team?)
                        ForEach(teams) { team in
                            Text(team.name).tag(team as Team?)
                        }
                    }
                    
                    Picker("チームB", selection: $teamB) {
                        Text("未選択").tag(nil as Team?)
                        // Filter out teamA so a team cannot play against itself
                        ForEach(teams.filter { $0.id != teamA?.id }) { team in
                            Text(team.name).tag(team as Team?)
                        }
                    }
                }
                
                Section(header: Text("最初のサーブ")) {
                    Picker("最初のサーブ", selection: $teamAServesFirst) {
                        Text(teamA?.name ?? "チームA").tag(true)
                        Text(teamB?.name ?? "チームB").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .disabled(teamA == nil || teamB == nil) // Disable if teams aren't selected
                }
                
                Section {
                    // ★ 修正点: NavigationLinkのdestinationをMatchオブジェクトを受け取るScoreViewに合わせる
                    // isReadyToStartがtrueの時はteamAとteamBがnilでないことが保証される
                    // Ensure isReadyToStart implies teamA and teamB are non-nil (which it does)
                    if isReadyToStart { // Only show link if ready
                        // Use a programmatic navigation to create and save the Match before presenting ScoreView
                        NavigationLink(destination: ScoreView(match: createAndSaveMatch())) {
                            Text("試合開始")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .disabled(!isReadyToStart) // Disable if not ready
                    } else {
                        // Show a disabled button or text if not ready, for better UX
                        Text("試合開始")
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .foregroundColor(.gray) // Indicate it's disabled
                    }
                } footer: {
                    if !isReadyToStart && (teamA != nil || teamB != nil) {
                        Text("両チームに最低1人の選手が登録されている必要があります。")
                            .foregroundColor(.red)
                    } else if teamA == nil || teamB == nil {
                        Text("対戦チームを両方選択してください。")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("試合設定")
            // When teamA selection changes, reset teamB if it's the same team
            .onChange(of: teamA) {
                if teamA != nil && teamA?.id == teamB?.id {
                    teamB = nil
                }
            }
        }
    }
    
    // Helper function to create and save a Match object
    private func createAndSaveMatch() -> Match {
        // We can force unwrap here because isReadyToStart ensures teamA and teamB are non-nil
        let newMatch = Match(date: Date(), teamA: teamA!, teamB: teamB!, teamAServesFirst: teamAServesFirst)
        modelContext.insert(newMatch)
        
        // It's good practice to save explicitly after inserting,
        // although ModelContainer might auto-save depending on context.
        do {
            try modelContext.save()
            print("Match created and saved: \(newMatch.id)")
        } catch {
            print("Error saving new match: \(error.localizedDescription)")
        }
        
        return newMatch
    }
}

// MARK: - Preview

#Preview {
    MatchSetupView()
        .modelContainer(PreviewSampleData.container)
}
