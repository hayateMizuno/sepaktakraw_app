//
//  PlayerSelectionView.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/16.
//

// 📁 Components/PlayerSelectionView.swift

import SwiftUI

struct PlayerSelectionView: View {
    let team: Team
    @Binding var selectedPlayer: Player?
    
    // チームから各ポジションの選手を探す
    private var feeder: Player? { team.players.first { $0.position == .feeder } }
    private var tekong: Player? { team.players.first { $0.position == .tekong } }
    private var striker: Player? { team.players.first { $0.position == .striker } }
    
    var body: some View {
        HStack(spacing: 8) {
            // トサー
            PlayerCell(
                player: feeder,
                position: .feeder,
                isSelected: selectedPlayer?.id == feeder?.id
            ) {
                selectedPlayer = feeder
            }
            
            // サーバー
            PlayerCell(
                player: tekong,
                position: .tekong,
                isSelected: selectedPlayer?.id == tekong?.id
            ) {
                selectedPlayer = tekong
            }
            
            // アタッカー
            PlayerCell(
                player: striker,
                position: .striker,
                isSelected: selectedPlayer?.id == striker?.id
            ) {
                selectedPlayer = striker
            }
        }
    }
}
