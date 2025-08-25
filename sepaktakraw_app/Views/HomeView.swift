//
//  HomeView.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/15.
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        // 画面遷移を管理するためのNavigationStack
        NavigationStack {
            VStack(spacing: 20) {
                Spacer()
                
                // タイトル
                VStack {
                    Image(systemName: "figure.sepaktakraw")
                        .font(.system(size: 60))
                        .foregroundColor(.orange)
                    Text("Sepak Takraw Scorer")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                // 各機能へのナビゲーションボタン
                VStack(spacing: 15) {
                    // スコア入力画面へ
                    NavigationLink(destination: MatchSetupView()) {
                        Label("スコア入力", systemImage: "pencil.and.scribble")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    // チーム・選手登録画面へ (今は仮の画面)
                    NavigationLink(destination: TeamListView()) {
                        Label("チーム・選手登録", systemImage: "person.2.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    
                    // 記録閲覧画面へ (今は仮の画面)
                    NavigationLink(destination: Text("記録閲覧画面（作成予定）")) {
                        Label("記録を見返す", systemImage: "list.bullet.clipboard.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.gray)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                }
                
                Spacer()
            }
            .padding()
        }
    }
}

#Preview {
    HomeView()
        .modelContainer(PreviewSampleData.container) // ★ 作成したコンてナを適用
}
