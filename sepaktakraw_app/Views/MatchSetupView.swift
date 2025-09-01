//
//  MatchSetupView.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/15.
//

import SwiftUI
import SwiftData

// ✨ 追加: 画面遷移の状態を管理するための型
enum MatchSetupNavigation: Hashable {
    case scoreView(Match)
}

struct MatchSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Team.name) private var teams: [Team]
    
    @State private var teamA: Team?
    @State private var teamB: Team?
    
    @State private var teamASuffix: String = "A"
    @State private var teamBSuffix: String = "B"
    private let suffixes = ["A", "B", "C", "D"]
    
    @State private var selectedPlayersA: [Player] = []
    @State private var selectedPlayersB: [Player] = []
    
    @State private var isShowingPlayerSelectionA = false
    @State private var isShowingPlayerSelectionB = false
    
    @State private var teamAServesFirst = true
    @State private var navigationPath = NavigationPath()
    
    private var isReadyToStart: Bool {
        guard teamA != nil, teamB != nil else { return false }
        return selectedPlayersA.count == 3 && selectedPlayersB.count == 3
    }
    
    private var isSameTeamSelected: Bool {
        guard let teamA = teamA, let teamB = teamB else { return false }
        return !teamA.isBotTeam && teamA.id == teamB.id
    }
    
    var body: some View {
        // ✨ 修正: NavigationStackにpathをバインドする
        NavigationStack(path: $navigationPath) {
            Form {
                // ✨ 修正: チームAとBのセクションを分割して、コンパイラエラーを回避
                Section(header: Text("チームA")) {
                    Picker("チームを選択", selection: $teamA) {
                        Text("未選択").tag(nil as Team?)
                        ForEach(teams) { team in
                            Text(team.name).tag(team as Team?)
                        }
                    }
                    if let team = teamA, !team.isBotTeam {
                        Button(action: { isShowingPlayerSelectionA = true }) {
                            playerSelectionButtonLabel(for: "出場選手", selectedPlayers: selectedPlayersA)
                        }
                    }
                }
                
                Section(header: Text("チームB")) {
                    Picker("チームを選択", selection: $teamB) {
                        Text("未選択").tag(nil as Team?)
                        ForEach(teams) { team in
                            Text(team.name).tag(team as Team?)
                        }
                    }
                    if let team = teamB, !team.isBotTeam {
                        Button(action: { isShowingPlayerSelectionB = true }) {
                            playerSelectionButtonLabel(for: "出場選手", selectedPlayers: selectedPlayersB)
                        }
                    }
                }
                
                if isSameTeamSelected {
                    Section(header: Text("チーム名の区別")) {
                        HStack {
                            Text(teamA?.name ?? "チーム")
                            Picker("チームA サフィックス", selection: $teamASuffix) {
                                ForEach(suffixes.filter { $0 != teamBSuffix }, id: \.self) { suffix in
                                    Text(suffix).tag(suffix)
                                }
                            }.pickerStyle(.segmented)
                        }
                        HStack {
                            Text(teamB?.name ?? "チーム")
                            Picker("チームB サフィックス", selection: $teamBSuffix) {
                                ForEach(suffixes.filter { $0 != teamASuffix }, id: \.self) { suffix in
                                    Text(suffix).tag(suffix)
                                }
                            }.pickerStyle(.segmented)
                        }
                    }
                }
                
                Section(header: Text("最初のサーブ")) {
                    Picker("最初のサーブ", selection: $teamAServesFirst) {
                        Text(teamA?.name ?? "チームA").tag(true)
                        Text(teamB?.name ?? "チームB").tag(false)
                    }
                    .pickerStyle(.segmented)
                    .disabled(teamA == nil || teamB == nil)
                }
                
                Section {
                    Button("試合開始") {
                        let newMatch = createAndSaveMatch()
                        navigationPath.append(MatchSetupNavigation.scoreView(newMatch))
                    }
                    .disabled(!isReadyToStart)
                    .font(.headline)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .foregroundColor(isReadyToStart ? .accentColor : .gray)
                } footer: {
                    if !isReadyToStart && (teamA != nil || teamB != nil) {
                        Text("両チームの出場選手（Bot以外は3名）を選択してください。")
                            .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("試合設定")
            .onChange(of: teamA) { selectedPlayersA = [] }
            .onChange(of: teamB) { selectedPlayersB = [] }
            .sheet(isPresented: $isShowingPlayerSelectionA) {
                if let team = teamA {
                    PlayerSelectionSheet(team: team, selectedPlayers: $selectedPlayersA, disabledPlayerIDs: isSameTeamSelected ? Set(selectedPlayersB.map(\.id)) : [])
                }
            }
            .sheet(isPresented: $isShowingPlayerSelectionB) {
                if let team = teamB {
                    PlayerSelectionSheet(team: team, selectedPlayers: $selectedPlayersB, disabledPlayerIDs: isSameTeamSelected ? Set(selectedPlayersA.map(\.id)) : [])
                }
            }
            .navigationDestination(for: MatchSetupNavigation.self) { value in
                switch value {
                case .scoreView(let match): ScoreView(match: match)
                }
            }
        }
    }
    
    @ViewBuilder
    private func playerSelectionButtonLabel(for teamTitle: String, selectedPlayers: [Player]) -> some View {
        HStack {
            Text("\(teamTitle) の選手を選択")
            Spacer()
            if selectedPlayers.isEmpty {
                Text("未選択")
                    .foregroundColor(.secondary)
            } else {
                Text("\(selectedPlayers.count)名 選択済み")
                    .foregroundColor(.accentColor)
            }
        }
    }
    
    private func createAndSaveMatch() -> Match {
        guard let teamA = teamA, let teamB = teamB else {
            fatalError("Match creation failed due to nil teams.")
        }
        
        let newMatch = Match(date: Date(), teamA: teamA, teamB: teamB, teamAServesFirst: teamAServesFirst)
        // ✨ 重要: 試合に参加する選手をMatchオブジェクトに直接保存する
        newMatch.participatingPlayersA = selectedPlayersA
        newMatch.participatingPlayersB = selectedPlayersB
        
        modelContext.insert(newMatch)
        
        do {
            try modelContext.save()
        } catch {
            print("Error saving new match: \(error.localizedDescription)")
        }
        
        return newMatch
    }
}


#Preview {
    MatchSetupView()
        .modelContainer(PreviewSampleData.container)
}
