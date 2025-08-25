//
//  PlayerListView.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/15.
//

import SwiftUI
import SwiftData

struct PlayerListView: View {
    // 表示対象のチーム
    @Bindable var team: Team
    
    @Environment(\.modelContext) private var modelContext
    
    // ★ 1. アラート管理用のState変数を追加
    @State private var playerToDelete: Player?
    @State private var isShowingDeleteAlert = false
    
    @State private var isShowingAddPlayerSheet = false
    @State private var newPlayerName = ""
    @State private var selectedPosition = Position.tekong

    var body: some View {
        let sortedPlayers = team.players.sorted(by: { $0.name < $1.name })
        
        List {
            ForEach(team.players.sorted(by: { $0.name < $1.name })) { player in
                VStack(alignment: .leading) {
                    Text(player.name).font(.headline)
                    Text(player.position.displayName).font(.subheadline).foregroundColor(.gray)
                }
            }
            // ★ 2. スワイプ削除のアクションを追加
            .onDelete { offsets in
                // ForEachで使っている配列(sortedPlayers)から対象を特定する
                if let first = offsets.first {
                    playerToDelete = sortedPlayers[first]
                    isShowingDeleteAlert = true
                }
            }
        }
        .navigationTitle("\(team.name) の選手")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isShowingAddPlayerSheet = true }) {
                    Image(systemName: "plus")
                }
            }
        }
        .sheet(isPresented: $isShowingAddPlayerSheet) {
            // 選手追加用のフォーム
            NavigationStack {
                Form {
                    TextField("選手名", text: $newPlayerName)
                    Picker("ポジション", selection: $selectedPosition) {
                        ForEach(Position.allCases, id: \.self) { position in
                            Text(position.displayName).tag(position)
                        }
                    }
                }
                .navigationTitle("新しい選手を追加")
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") { isShowingAddPlayerSheet = false }
                    }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("保存") { addPlayer() }
                    }
                }
            }
        }
        .alert("選手を削除", isPresented: $isShowingDeleteAlert, presenting: playerToDelete) { player in
            Button("削除", role: .destructive) {
                delete(player)
            }
            Button("キャンセル", role: .cancel) {}
        } message: { player in
            Text("「\(player.name)」を削除しますか？この操作は元に戻せません。")
        }
    }
    
    private func delete(_ player: Player) {
            // データベースから選手を削除する
            modelContext.delete(player)
        }
    
    private func addPlayer() {
        guard !newPlayerName.isEmpty else { return }
        let newPlayer = Player(name: newPlayerName, position: selectedPosition)
        team.players.append(newPlayer) // チームに選手を追加するだけでOK
        isShowingAddPlayerSheet = false
        newPlayerName = ""
    }
}
