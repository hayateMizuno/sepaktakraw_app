//
//  PlayerListView.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/15.
//

import SwiftUI
import SwiftData

/// チームに所属する選手の一覧を表示する画面
struct PlayerListView: View {
    @Bindable var team: Team
    @Environment(\.modelContext) private var modelContext
    
    @State private var playerToDelete: Player?
    @State private var isShowingDeleteAlert = false
    @State private var isShowingAddPlayerSheet = false

    // 選手リストをソート済みの計算プロパティとして定義
    private var sortedPlayers: [Player] {
        team.players.sorted(by: { $0.name < $1.name })
    }

    var body: some View {
        List {
            // sortedPlayersプロパティを使用
            ForEach(sortedPlayers) { player in
                            // ✨ 修正: NavigationLinkを追加し、タップで編集画面に遷移
                            NavigationLink(destination: AddEditPlayerView(playerToEdit: player)) {
                                PlayerRowView(player: player)
                            }
                        }
        }
        .navigationTitle("\(team.name) の選手")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isShowingAddPlayerSheet = true }) {
                    Text("選手追加")
                }
            }
        }
        .sheet(isPresented: $isShowingAddPlayerSheet) {
            AddEditPlayerView(team: team)
        }
        .alert("選手を削除", isPresented: $isShowingDeleteAlert, presenting: playerToDelete) { player in
            Button("削除", role: .destructive) { delete(player) }
            Button("キャンセル", role: .cancel) {}
        } message: { player in
            Text("「\(player.name)」を削除しますか？この操作は元に戻せません。")
        }
    }
    
    private func delete(_ player: Player) {
        modelContext.delete(player)
    }
}

// ✨ 追加: 選手の行表示用の新しいビュー
struct PlayerRowView: View {
    let player: Player
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(player.name)
                .font(.headline)
            
            HStack(spacing: 12) {
                Label(player.position.displayName, systemImage: "figure.walk")
                Label(player.dominantFoot.rawValue, systemImage: "foot")
                
                if let attackType = player.attackType {
                    Label(attackType.rawValue, systemImage: "bolt.fill")
                }
                if let serverType = player.serverType {
                    Label(serverType.rawValue, systemImage: "airplane")
                }
            }
            .font(.caption)
            .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}


/// 新しい選手を追加するためのフォーム画面
struct AddEditPlayerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // 編集対象の選手 (nilの場合は新規追加モード)
    var playerToEdit: Player?
    // 新規追加の場合の所属チーム
    var team: Team?

    @State private var name: String = ""
    @State private var position: Position = .striker
    @State private var dominantFoot: DominantFoot = .right
    @State private var attackType: AttackType = .rolling
    @State private var serverType: ServerType = .inside
    
    // 編集モードかどうかを判定
    private var isEditing: Bool {
        playerToEdit != nil
    }

    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("選手名", text: $name)
                    Picker("ポジション", selection: $position) {
                        ForEach(Position.allCases, id: \.self) { pos in
                            Text(pos.displayName).tag(pos)
                        }
                    }
                    Picker("利き足", selection: $dominantFoot) {
                        ForEach(DominantFoot.allCases, id: \.self) { foot in
                            Text(foot.rawValue).tag(foot)
                        }
                    }
                }
                
                if position == .striker {
                    Section(header: Text("アタッカー情報")) {
                        Picker("得意なアタック", selection: $attackType) {
                            ForEach(AttackType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }
                
                if position == .tekong {
                    Section(header: Text("サーバー情報")) {
                        Picker("得意なサーブ", selection: $serverType) {
                            ForEach(ServerType.allCases, id: \.self) { type in
                                Text(type.rawValue).tag(type)
                            }
                        }
                    }
                }
            }
            .navigationTitle(isEditing ? "選手情報を編集" : "新しい選手を追加")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if !isEditing {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("キャンセル") { dismiss() }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("保存") { save() }
                        .disabled(!isFormValid)
                }
            }
            .onAppear(perform: setupForm) // 画面表示時にフォームの初期値を設定
        }
    }
    
    /// フォームの初期値を設定する (編集モードの場合)
    private func setupForm() {
        if let player = playerToEdit {
            name = player.name
            position = player.position
            dominantFoot = player.dominantFoot
            attackType = player.attackType ?? .rolling
            serverType = player.serverType ?? .inside
        }
    }
    
    /// 選手情報を保存する (新規追加・更新の両方に対応)
    private func save() {
        guard isFormValid else { return }
        
        if let player = playerToEdit {
            // 編集モードの場合: 既存の選手の情報を更新
            player.name = name
            player.position = position
            player.dominantFoot = dominantFoot
            player.attackType = (position == .striker) ? attackType : nil
            player.serverType = (position == .tekong) ? serverType : nil
        } else if let team = team {
            // 新規追加モードの場合: 新しい選手を作成
            let newPlayer = Player(
                name: name,
                position: position,
                dominantFoot: dominantFoot,
                team: team,
                attackType: (position == .striker) ? attackType : nil,
                serverType: (position == .tekong) ? serverType : nil
            )
            modelContext.insert(newPlayer)
        }
        
        try? modelContext.save()
        dismiss()
    }
}
// MARK: - Preview
#Preview {
    // プレビュー用のダミーデータを作成
    let container = PreviewSampleData.container
    let fetchDescriptor = FetchDescriptor<Team>()
    let team = try! container.mainContext.fetch(fetchDescriptor).first!
    
    return NavigationStack {
        PlayerListView(team: team)
            .modelContainer(container)
    }
}
