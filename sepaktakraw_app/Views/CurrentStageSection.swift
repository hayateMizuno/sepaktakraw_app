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
    let rallyStage: RallyStage
    let currentActionTeam: Team?
    let currentTeamColor: Color
    
    private var description: String {
        guard let team = currentActionTeam else { return "..." }
        switch rallyStage {
        case .serving: return "\(team.name) のサーブ"
        case .receiving: return "\(team.name) のレシーブ"
        case .setting: return "\(team.name) のセット"
        case .attacking: return "\(team.name) のアタック"
        case .blocking: return "\(team.name) のブロック"
        case .gameEnd: return "ゲーム終了"
        }
    }
    
    var body: some View {
        Text(description)
            .font(.headline)
            .fontWeight(.semibold)
            .padding(.horizontal)
            .padding(.vertical, 8)
            .frame(maxWidth: .infinity)
            .background(currentTeamColor.opacity(0.15))
            .cornerRadius(8)
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
