//
//  PlayerSelectionSheet.swift
//  sepaktakraw_app
//
//  Created by セパタクローアプリ開発 on 2025/09/01.
//

import SwiftUI
import SwiftData

/// 試合に出場する選手を3人選択するためのシート
struct PlayerSelectionSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    let team: Team
    @Binding var selectedPlayers: [Player]
    
    // ✨ 修正: 選択不可にする選手のIDセットを追加
    let disabledPlayerIDs: Set<Player.ID>
    
    @State private var temporarySelection: Set<Player.ID>
    
    // ✨ 修正: initを修正して disabledPlayerIDs を受け取れるようにする
    init(team: Team, selectedPlayers: Binding<[Player]>, disabledPlayerIDs: Set<Player.ID> = []) {
        self.team = team
        self._selectedPlayers = selectedPlayers
        self.disabledPlayerIDs = disabledPlayerIDs
        self._temporarySelection = State(initialValue: Set(selectedPlayers.wrappedValue.map { $0.id }))
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(team.players) { player in
                    Button(action: { toggleSelection(for: player) }) {
                        HStack {
                            Image(systemName: temporarySelection.contains(player.id) ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(disabledPlayerIDs.contains(player.id) ? .gray : .accentColor)
                            
                            VStack(alignment: .leading) {
                                Text(player.name)
                                    .foregroundColor(disabledPlayerIDs.contains(player.id) ? .secondary : .primary)
                                Text(player.position.displayName).font(.caption).foregroundColor(.secondary)
                            }
                        }
                    }
                    // ✨ 修正: isDisabled関数を呼び出す
                    .disabled(isDisabled(player: player))
                }
            }
            .navigationTitle("\(team.name) の選手選択")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("完了") {
                        selectedPlayers = team.players.filter { temporarySelection.contains($0.id) }
                        dismiss()
                    }
                    .disabled(temporarySelection.count != 3)
                }
            }
        }
    }
    
    private func toggleSelection(for player: Player) {
        if temporarySelection.contains(player.id) {
            temporarySelection.remove(player.id)
        } else {
            if temporarySelection.count < 3 {
                temporarySelection.insert(player.id)
            }
        }
    }
    
    // ✨ 修正: isDisabled関数を追加
    private func isDisabled(player: Player) -> Bool {
        if disabledPlayerIDs.contains(player.id) {
            return true
        }
        return temporarySelection.count >= 3 && !temporarySelection.contains(player.id)
    }
}

// MARK: - Preview
#Preview {
    struct PlayerSelectionSheetPreview: View {
        @State private var previewSelectedPlayers: [Player] = []
        
        private var team: Team {
            let container = PreviewSampleData.container
            let fetchDescriptor = FetchDescriptor<Team>()
            return try! container.mainContext.fetch(fetchDescriptor).first!
        }
        
        var body: some View {
            PlayerSelectionSheet(team: team, selectedPlayers: $previewSelectedPlayers, disabledPlayerIDs: [])
                .modelContainer(PreviewSampleData.container)
        }
    }
    
    return PlayerSelectionSheetPreview()
}
