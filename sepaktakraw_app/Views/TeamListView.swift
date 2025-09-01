//
//  TeamListView.swift
//  sepaktakraw_app
//

import SwiftUI
import SwiftData

struct TeamListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(filter: #Predicate<Team> { !$0.isBotTeam }, sort: \Team.name) private var userTeams: [Team]
    @Query(filter: #Predicate<Team> { $0.isBotTeam }) private var botTeamQuery: [Team]
    
    private var botTeam: Team? { botTeamQuery.first }

    @State private var teamToDelete: Team?
    @State private var isShowingDeleteAlert = false
    @State private var isShowingAddTeamSheet = false
    @State private var newTeamName = ""
    @State private var selectedColor: Color = .red

    var body: some View {
        NavigationStack {
            List {
                if let botTeam = botTeam {
                    Section(header: Text("BOT")) {
                        HStack {
                            Circle().fill(botTeam.color).frame(width: 20, height: 20)
                            Text(botTeam.name)
                            Spacer()
                            Image(systemName: "lock.fill").foregroundColor(.secondary)
                        }
                    }
                }
                
                Section(header: Text("マイチーム")) {
                    ForEach(userTeams) { team in
                        NavigationLink(destination: PlayerListView(team: team)) {
                            HStack {
                                Circle().fill(team.color).frame(width: 20, height: 20)
                                Text(team.name)
                            }
                        }
                    }
                    .onDelete(perform: askToDelete)
                }
            }
            .navigationTitle("チーム・選手登録")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        isShowingAddTeamSheet = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .alert("チームを削除", isPresented: $isShowingDeleteAlert, presenting: teamToDelete) { team in
                Button("削除", role: .destructive) { delete(team) }
                Button("キャンセル", role: .cancel) {}
            } message: { team in
                Text("「\(team.name)」を削除しますか？所属する全ての選手データも削除され、この操作は元に戻せません。")
            }
        }
        // ✨ 修正: .sheetモディファイアをNavigationStackの末尾に移動
        .sheet(isPresented: $isShowingAddTeamSheet) {
            AddTeamSheet(
                newTeamName: $newTeamName,
                selectedColor: $selectedColor,
                addTeamAction: addTeam,
                dismissAction: {
                    isShowingAddTeamSheet = false
                    newTeamName = ""
                    selectedColor = .red
                }
            )
        }
    }
    
    private func askToDelete(at offsets: IndexSet) {
        if let first = offsets.first {
            teamToDelete = userTeams[first]
            isShowingDeleteAlert = true
        }
    }
    
    private func delete(_ team: Team) {
        modelContext.delete(team)
    }
    
    private func addTeam() {
        guard !newTeamName.isEmpty else { return }
        let newTeam = Team(name: newTeamName, color: selectedColor, isBotTeam: false)
        modelContext.insert(newTeam)
        // ✨ 追加: 変更を明示的に保存し、処理をより確実にする
        try? modelContext.save()
        newTeamName = ""
    }
}

/// チーム追加用のシート
struct AddTeamSheet: View {
    @Binding var newTeamName: String
    @Binding var selectedColor: Color
    let addTeamAction: () -> Void
    let dismissAction: () -> Void

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("チーム情報")) {
                    TextField("チーム名", text: $newTeamName)
                    ColorPicker("チームカラー", selection: $selectedColor)
                }
            }
            .navigationTitle("新しいチームを追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル", action: dismissAction)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("追加") {
                        addTeamAction()
                        dismissAction()
                    }
                    .disabled(newTeamName.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

// MARK: - Preview (for TeamListView)

#Preview {
    @MainActor
    struct TeamListViewPreview: View {
        var body: some View {
            TeamListView()
                .modelContainer(PreviewSampleData.container)
        }
    }
    return TeamListViewPreview()
}
