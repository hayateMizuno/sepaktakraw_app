//
//  PlayerCell.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/16.
//

// 📁 Components/PlayerCell.swift

import SwiftUI

struct PlayerCell: View {
    let player: Player?
    let position: Position // 表示するポジション
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                // 上段：ポジション名
                Text(position.displayName)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                // 下段：選手名
                Text(player?.name ?? "未登録")
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                    .foregroundColor(.primary)
                    .padding(.vertical, 8)
                    .frame(maxWidth: .infinity)
                    .background(isSelected ? Color.accentColor.opacity(0.2) : Color.secondary.opacity(0.1))
                    .cornerRadius(8)
            }
        }
        .buttonStyle(.plain) // ボタンのデフォルトスタイルを無効化
    }
}
