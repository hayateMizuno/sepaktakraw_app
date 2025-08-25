//
//  CurrentStageSection.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/16.
//

//
//  CurrentStageSection.swift
//  sepaktakraw_app
//
//  Created by YourName on 2025/08/XX.
//

import SwiftUI

struct CurrentStageSection: View {
    let rallyStage: RallyStage // RallyStageはScoreViewから渡される
    let currentActionTeam: Team? // 現在アクションを行うチームもScoreViewから渡される
    let currentTeamColor: Color // 現在のチームカラーもScoreViewから渡される

    /// 現在の状況を説明するテキスト
    private var currentStageDescription: String {
        guard let team = currentActionTeam else { return "チーム情報なし" }
        let teamName = team.name
        switch rallyStage {
        case .serving: return "\(teamName) のサーブ"
        case .receiving: return "\(teamName) のレシーブ"
        case .setting: return "\(teamName) のトス"
        case .attacking: return "\(teamName) のアタック"
        }
    }

    var body: some View {
        Text(currentStageDescription)
            .font(.title2)
            .padding()
            .background(currentTeamColor.opacity(0.2))
            .cornerRadius(10)
    }
}

// MARK: - Preview

#Preview {
    @MainActor
    struct CurrentStageSectionPreview: View {
        // ViewModelは不要なので、ダミーデータを直接作成
        let mockTeamA = Team(name: "Home Team", color: .blue)

        var body: some View {
            VStack(spacing: 20) {
                CurrentStageSection(rallyStage: .serving, currentActionTeam: mockTeamA, currentTeamColor: mockTeamA.color)
                CurrentStageSection(rallyStage: .receiving, currentActionTeam: mockTeamA, currentTeamColor: mockTeamA.color)
                CurrentStageSection(rallyStage: .setting, currentActionTeam: mockTeamA, currentTeamColor: mockTeamA.color)
                CurrentStageSection(rallyStage: .attacking, currentActionTeam: mockTeamA, currentTeamColor: mockTeamA.color)
            }
        }
    }
    return CurrentStageSectionPreview()
}
