//
//  StatButton.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/16.
//

// 📁 Components/StatButton.swift

import SwiftUI

struct StatButton: View {
    let title: String
    let systemImage: String
    var color: Color = .blue
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack {
                Image(systemName: systemImage)
                    .font(.title2) // 少しサイズを調整
                Text(title)
                    .font(.caption)
                    .fontWeight(.bold)
            }
            .frame(maxWidth: .infinity, minHeight: 60)
            .background(color.opacity(0.15))
            .foregroundColor(color)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(color.opacity(0.3), lineWidth: 1)
            )
        }
        .buttonStyle(.plain) // タップ時の見た目をシンプルに
    }
}

#Preview {
    Grid {
        GridRow {
            StatButton(title: "アタック成功", systemImage: "checkmark.circle.fill", color: .green) {}
            StatButton(title: "アタック失敗", systemImage: "xmark.circle.fill", color: .red) {}
        }
    }
    .padding()
}
