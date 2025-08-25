//
//  TeamScoreView.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/14.
//

import SwiftUI

struct TeamScoreView: View {
    let teamName: String
    @Binding var score: Int
    @Binding var isServing: Bool
    let isMyServe: Bool
    var onAddPoint: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            Text(teamName)
                .font(.title)
                .fontWeight(.bold)
            
            Text("\(score)")
                .font(.system(size: 100, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5) // スコアが大きくなっても収まるように
            
            Button(action: onAddPoint) {
                Image(systemName: "plus")
                    .font(.largeTitle)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(teamName == "Team A" ? Color("teamAColor") : Color("teamBColor")) // Assetsの色を使用
                    .clipShape(Circle())
                    .shadow(radius: 3)
            }
            
            // サーブ権の表示
            Text("SERVE")
                .font(.caption)
                .fontWeight(.bold)
                .foregroundColor(.green)
                .opacity(isServing == isMyServe ? 1.0 : 0.0) // 表示/非表示を切り替え
                .padding(.top, 5)
        }
    }
}

