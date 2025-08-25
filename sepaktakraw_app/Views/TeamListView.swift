//
//  TeamListView.swift
//  sepaktakraw_app
//

import SwiftUI
import SwiftData

struct TeamListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var teams: [Team]

    @State private var teamToDelete: Team?
    @State private var isShowingDeleteAlert = false
    @State private var isShowingAddTeamSheet = false
    @State private var newTeamName = ""
    @State private var selectedColor: Color = .red
    @State private var selectedTeam: Team? = nil // This holds the Team whose color is being edited

    // State to hold the color *currently selected in the ColorPicker*
    @State private var colorBeingEdited: Color = .red // Initialize with a default color

    var body: some View {
        NavigationStack {
            List {
                ForEach(teams) { team in
                    HStack {
                        Text(team.name)
                            .padding(6)
                            .background(team.color)
                            .cornerRadius(8)
                            .foregroundColor(.white)
                            .onTapGesture {
                                selectedTeam = team // Assign the team to open the sheet
                                colorBeingEdited = team.color // Initialize colorBeingEdited with team's current color
                            }
                        
                        Spacer()
                    }
                }
                .onDelete(perform: askToDelete)
            }
            .sheet(item: $selectedTeam) { team in // 'team' here is a let constant
                TeamColorEditSheet(team: team, colorBeingEdited: $colorBeingEdited) { updatedColor in
                    // This closure is called when the sheet signals a color update
                    team.color = updatedColor // Apply the changes to the SwiftData model
                    try? modelContext.save() // Save context after update
                }
            }
            
            .navigationTitle("チーム一覧")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { isShowingAddTeamSheet = true }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $isShowingAddTeamSheet) {
                AddTeamSheet(
                    newTeamName: $newTeamName,
                    selectedColor: $selectedColor,
                    addTeamAction: addTeam,
                    dismissAction: {
                        isShowingAddTeamSheet = false
                        newTeamName = ""
                    }
                )
            }
            .alert("チームを削除", isPresented: $isShowingDeleteAlert, presenting: teamToDelete) { team in
                Button("削除", role: .destructive) {
                    delete(team)
                }
                Button("キャンセル", role: .cancel) {}
            } message: { team in
                Text("「\(team.name)」を削除しますか？所属する全ての選手データも削除され、この操作は元に戻せません。")
            }
        }
    }
    
    private func askToDelete(at offsets: IndexSet) {
        if let first = offsets.first {
            teamToDelete = teams[first]
            isShowingDeleteAlert = true
        }
    }
    
    private func delete(_ team: Team) {
        modelContext.delete(team)
    }
    
    private func addTeam() {
        guard !newTeamName.isEmpty else { return }
        let newTeam = Team(name: newTeamName)
        newTeam.color = selectedColor
        modelContext.insert(newTeam)
        newTeamName = ""
    }
}

// MARK: - Helper Views for Sheets

// チーム追加用のシートを新しい構造体として切り出す
struct AddTeamSheet: View {
    @Binding var newTeamName: String
    @Binding var selectedColor: Color
    let addTeamAction: () -> Void
    let dismissAction: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            TextField("チーム名", text: $newTeamName)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding(.horizontal)
            
            ColorPicker("チームカラー", selection: $selectedColor)
                .padding(.horizontal)
            
            HStack {
                Button("キャンセル", action: dismissAction)
                    .buttonStyle(.bordered)
                
                Spacer()
                
                Button("追加") {
                    addTeamAction()
                    dismissAction()
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

// チームの色編集用のシートを新しい構造体として切り出す
struct TeamColorEditSheet: View {
    // Teamオブジェクト自体を直接受け取る (SwiftDataは変更を自動追跡)
    @Bindable var team: Team // Use @Bindable for direct modification in SwiftData
    @Binding var colorBeingEdited: Color // To control the ColorPicker's selection
    @Environment(\.dismiss) var dismiss // To dismiss the sheet
    
    // Closure to communicate the updated color back to TeamListView
    let onColorUpdate: (Color) -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("チームの色を変更")
                .font(.headline)
            
            ColorPicker("色を選択", selection: $colorBeingEdited) // Bind to the @State variable
                .padding()
            
            Button("完了") {
                onColorUpdate(colorBeingEdited) // Pass the final color back
                dismiss() // Dismiss the sheet
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onAppear {
            colorBeingEdited = team.color // Initialize the @State variable when sheet appears
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
