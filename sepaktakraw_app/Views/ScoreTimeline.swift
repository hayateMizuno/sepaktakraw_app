//
//  ScoreTimelineView.swift
//  sepaktakraw_app
//
//  Simplified vertical score timeline display component
//

import SwiftUI

struct ScoreTimelineView: View {
    let teamA: Team
    let teamB: Team
    let scoreEvents: [ScoreEvent] // ViewModelから直接受け取る
    
    // 実際に得点が発生したイベントのみをフィルタリング
    private var scoringEvents: [ScoreEvent] {
        var previousScoreA = 0
        var previousScoreB = 0
        var actualScoringEvents: [ScoreEvent] = []
        
        for event in scoreEvents {
            // 前回のスコアと比較して実際に得点が発生したかチェック
            let scoreAIncreased = event.scoreA > previousScoreA
            let scoreBIncreased = event.scoreB > previousScoreB
            
            if scoreAIncreased || scoreBIncreased {
                // 得点が発生した場合のみ追加
                actualScoringEvents.append(event)
            }
            
            // 次の比較のために現在のスコアを保存
            previousScoreA = event.scoreA
            previousScoreB = event.scoreB
        }
        
        return actualScoringEvents
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // ヘッダー
            HStack {
                Text("SCORE TIMELINE")
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                
                Spacer()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color.black.opacity(0.3))
            
            // チーム名ヘッダーとタイムライン本体を横並びに配置
            HStack(spacing: 0) {
                // 左側：チーム名表示
                VStack(spacing: 4) {
                    Text(teamA.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(teamA.color)
                        .frame(height: 40)
                    
                    Text(teamB.name)
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(teamB.color)
                        .frame(height: 40)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 8)
                .background(Color.black.opacity(0.2))
                .frame(width: 80)
                
                // 右側：タイムライン本体（横スクロール可能）
                if scoringEvents.isEmpty {
                    // 得点がない場合のメッセージ
                    HStack {
                        Text("まだ得点がありません")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.6))
                            .padding()
                        Spacer()
                    }
                    .frame(height: 96)
                } else {
                    ScrollViewReader { proxy in
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHStack(spacing: 0) {
                                // 実際の得点イベントのみ表示（時系列順）
                                ForEach(Array(scoringEvents.enumerated()), id: \.element.id) { index, event in
                                    let nextEvent = index < scoringEvents.count - 1 ? scoringEvents[index + 1] : nil
                                    
                                    HStack(spacing: 0) {
                                        // 得点イベント（得点したチームの丸のみ表示）
                                        HorizontalScorePointView(
                                            event: event,
                                            teamAColor: teamA.color,
                                            teamBColor: teamB.color,
                                            isLatest: index == scoringEvents.count - 1 // 最後の得点をハイライト
                                        )
                                        .id("score-\(index)") // スクロール用のID
                                        
                                        // 次の得点への接続線（最後の得点以外）
                                        if let nextEvent = nextEvent {
                                            HorizontalConnectingLineView(
                                                fromTeam: event.scoringTeam,
                                                toTeam: nextEvent.scoringTeam,
                                                teamAColor: teamA.color,
                                                teamBColor: teamB.color
                                            )
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 12)
                        }
                        .frame(height: 96)
                        .onChange(of: scoringEvents.count) { _, newCount in
                            // 得点が更新されたら最新の得点（一番右）までスクロール
                            if newCount > 0 {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                    withAnimation(.easeInOut(duration: 0.8)) {
                                        proxy.scrollTo("score-\(newCount - 1)", anchor: .trailing)
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(
            LinearGradient(
                colors: [Color.black.opacity(0.8), Color.black.opacity(0.6)],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.3), lineWidth: 1)
        )
    }
}

// 横向きタイムライン用の得点表示ビュー
struct HorizontalScorePointView: View {
    let event: ScoreEvent
    let teamAColor: Color
    let teamBColor: Color
    let isLatest: Bool
    
    private var scoringTeamColor: Color {
        event.scoringTeam == "A" ? teamAColor : teamBColor
    }
    
    private var currentScore: Int {
        event.scoringTeam == "A" ? event.scoreA : event.scoreB
    }
    
    var body: some View {
        VStack(spacing: 12) {
            if event.scoringTeam == "A" {
                // チーム Aが得点した場合、上側に丸を表示
                VStack(spacing: 4) {
                    Text("\(currentScore)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(teamAColor)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1.5)
                                )
                        )
                    
                    // スコア表示
                    Text("\(event.scoreA)-\(event.scoreB)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(height: 40)
                
                // 下側は空白
                Color.clear
                    .frame(height: 40)
                
            } else {
                // チーム Bが得点した場合、下側に丸を表示
                // 上側は空白
                Color.clear
                    .frame(height: 40)
                
                VStack(spacing: 4) {
                    Text("\(currentScore)")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(teamBColor)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1.5)
                                )
                        )
                    
                    // スコア表示
                    Text("\(event.scoreA)-\(event.scoreB)")
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(height: 40)
            }
        }
        .frame(width: 50)
        .overlay(
            // 最新の得点をハイライト
            isLatest ? Rectangle()
                .fill(scoringTeamColor.opacity(0.5))
                .frame(height: 4)
                .animation(.easeInOut(duration: 0.5), value: isLatest)
            : nil,
            alignment: .top
        )
    }
}

// 横向き用の接続線
struct HorizontalConnectingLineView: View {
    let fromTeam: String
    let toTeam: String
    let teamAColor: Color
    let teamBColor: Color
    
    private var fromColor: Color {
        fromTeam == "A" ? teamAColor : teamBColor
    }
    
    private var toColor: Color {
        toTeam == "A" ? teamAColor : teamBColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            let height = geometry.size.height
            
            Path { path in
                if fromTeam == toTeam {
                    // 同じチームが連続で得点した場合は直線
                    let yPosition = fromTeam == "A" ? 26 : height - 26 // 丸の中心位置
                    path.move(to: CGPoint(x: 0, y: yPosition))
                    path.addLine(to: CGPoint(x: 18, y: yPosition))
                } else {
                    // 異なるチームが得点した場合は曲線
                    let startY = fromTeam == "A" ? 26 : height - 26
                    let endY = toTeam == "A" ? 26 : height - 26
                    let midY = height / 2
                    
                    path.move(to: CGPoint(x: 0, y: startY))
                    path.addQuadCurve(
                        to: CGPoint(x: 18, y: endY),
                        control: CGPoint(x: 9, y: midY)
                    )
                }
            }
            .stroke(
                LinearGradient(
                    colors: [fromColor, toColor],
                    startPoint: .leading,
                    endPoint: .trailing
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
        }
        .frame(width: 18)
    }
}

// 得点したチームの丸のみを表示するビュー（縦向き用 - 使用されなくなった）
struct ScorePointView: View {
    let event: ScoreEvent
    let teamAColor: Color
    let teamBColor: Color
    let isLatest: Bool
    
    private var scoringTeamColor: Color {
        event.scoringTeam == "A" ? teamAColor : teamBColor
    }
    
    private var currentScore: Int {
        event.scoringTeam == "A" ? event.scoreA : event.scoreB
    }
    
    var body: some View {
        HStack(spacing: 12) {
            if event.scoringTeam == "A" {
                // チーム Aが得点した場合、左側に丸を表示
                VStack(spacing: 4) {
                    Text("\(currentScore)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(teamAColor)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1.5)
                                )
                        )
                    
                    // スコア表示
                    Text("\(event.scoreA) - \(event.scoreB)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(width: 60)
                
                Spacer()
                
                // 右側は空白
                Color.clear
                    .frame(width: 60)
                
            } else {
                // チーム Bが得点した場合、右側に丸を表示
                // 左側は空白
                Color.clear
                    .frame(width: 60)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("\(currentScore)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(
                            Circle()
                                .fill(teamBColor)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: 1.5)
                                )
                        )
                    
                    // スコア表示
                    Text("\(event.scoreA) - \(event.scoreB)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(width: 60)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 4)
        .overlay(
            // 最新の得点をハイライト
            isLatest ? Rectangle()
                .fill(scoringTeamColor.opacity(0.5))
                .frame(width: 4)
                .animation(.easeInOut(duration: 0.5), value: isLatest)
            : nil,
            alignment: .leading
        )
    }
}

// 得点した丸同士を繋ぐ線
struct ConnectingLineView: View {
    let fromTeam: String
    let toTeam: String
    let teamAColor: Color
    let teamBColor: Color
    
    private var fromColor: Color {
        fromTeam == "A" ? teamAColor : teamBColor
    }
    
    private var toColor: Color {
        toTeam == "A" ? teamAColor : teamBColor
    }
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            
            Path { path in
                if fromTeam == toTeam {
                    // 同じチームが連続で得点した場合は直線
                    let xPosition = fromTeam == "A" ? 46 : width - 46 // 丸の中心位置
                    path.move(to: CGPoint(x: xPosition, y: 0))
                    path.addLine(to: CGPoint(x: xPosition, y: 18))
                } else {
                    // 異なるチームが得点した場合は曲線
                    let startX = fromTeam == "A" ? 46 : width - 46
                    let endX = toTeam == "A" ? 46 : width - 46
                    let midX = width / 2
                    
                    path.move(to: CGPoint(x: startX, y: 0))
                    path.addQuadCurve(
                        to: CGPoint(x: endX, y: 18),
                        control: CGPoint(x: midX, y: 9)
                    )
                }
            }
            .stroke(
                LinearGradient(
                    colors: [fromColor, toColor],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                style: StrokeStyle(lineWidth: 2, lineCap: .round)
            )
        }
        .frame(height: 18)
        .padding(.horizontal, 12)
    }
}

// MARK: - Preview用のサンプルデータ

#Preview {
    struct SimpleTimelinePreview: View {
        var body: some View {
            // 実際の使用状況に近いサンプルデータ（得点以外のプレーも含む）
            let sampleEvents: [ScoreEvent] = [
                // ゲーム開始
                ScoreEvent(scoreA: 0, scoreB: 0, scoringTeam: "None", timestamp: Date().addingTimeInterval(-320), playerName: "Game Start", actionType: .serve, isSuccess: true, hasServeRight: true),
                
                // サーブ失敗（得点なし）
                ScoreEvent(scoreA: 0, scoreB: 0, scoringTeam: "None", timestamp: Date().addingTimeInterval(-310), playerName: "田中", actionType: .serve, isSuccess: false, hasServeRight: false),
                
                // チームAが1点目を獲得
                ScoreEvent(scoreA: 1, scoreB: 0, scoringTeam: "A", timestamp: Date().addingTimeInterval(-300), playerName: "田中", actionType: .serve, isSuccess: true, hasServeRight: true),
                
                // アタック失敗（得点なし）
                ScoreEvent(scoreA: 1, scoreB: 0, scoringTeam: "None", timestamp: Date().addingTimeInterval(-290), playerName: "山田", actionType: .attack, isSuccess: false, hasServeRight: false),
                
                // チームBが1点目を獲得
                ScoreEvent(scoreA: 1, scoreB: 1, scoringTeam: "B", timestamp: Date().addingTimeInterval(-280), playerName: "佐藤", actionType: .attack, isSuccess: true, hasServeRight: false),
                
                // ヘディング成功だが得点なし
                ScoreEvent(scoreA: 1, scoreB: 1, scoringTeam: "None", timestamp: Date().addingTimeInterval(-270), playerName: "鈴木", actionType: .heading, isSuccess: true, hasServeRight: false),
                
                // チームAが2点目を獲得
                ScoreEvent(scoreA: 2, scoreB: 1, scoringTeam: "A", timestamp: Date().addingTimeInterval(-260), playerName: "山田", actionType: .attack, isSuccess: true, hasServeRight: true),
                
                // サーブ失敗
                ScoreEvent(scoreA: 2, scoreB: 1, scoringTeam: "None", timestamp: Date().addingTimeInterval(-250), playerName: "田中", actionType: .serve, isSuccess: false, hasServeRight: false),
                
                // チームBが2点目を獲得
                ScoreEvent(scoreA: 2, scoreB: 2, scoringTeam: "B", timestamp: Date().addingTimeInterval(-240), playerName: "高橋", actionType: .serve, isSuccess: true, hasServeRight: false),
                
                // チームAが3点目を獲得
                ScoreEvent(scoreA: 3, scoreB: 2, scoringTeam: "A", timestamp: Date().addingTimeInterval(-220), playerName: "田中", actionType: .heading, isSuccess: true, hasServeRight: true),
                
                // チームAが4点目を獲得（連続得点）
                ScoreEvent(scoreA: 4, scoreB: 2, scoringTeam: "A", timestamp: Date().addingTimeInterval(-200), playerName: "山田", actionType: .attack, isSuccess: true, hasServeRight: true),
            ]
            
            let sampleTeamA = Team(name: "Home", color: .blue)
            let sampleTeamB = Team(name: "Away", color: .red)
            
            VStack(spacing: 20) {
                Text("得点時のみ更新されるスコアタイムライン")
                    .font(.headline)
                
                ScoreTimelineView(
                    teamA: sampleTeamA,
                    teamB: sampleTeamB,
                    scoreEvents: sampleEvents
                )
                .frame(width: 300)
                
                Spacer()
            }
            .padding()
            .background(Color.gray.opacity(0.1))
        }
    }
    
    return SimpleTimelinePreview()
}
