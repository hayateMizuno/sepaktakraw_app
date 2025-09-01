//
//  ScoreViewModel.swift
//  sepaktakraw_app
//
//  Created by 折田研究室 on 2025/08/14.
//

import Foundation
import SwiftUI

// 得点イベントのデータ構造（ViewModelファイル内で定義）
struct ScoreEvent: Identifiable {
    let id = UUID()
    let scoreA: Int
    let scoreB: Int
    let scoringTeam: String // "A", "B", または "None"
    let timestamp: Date
    let playerName: String
    let actionType: StatType
    let isSuccess: Bool
    let hasServeRight: Bool // サーブ権を持っているかどうか
}

//fileprivate struct GameState {
//    let scoreA: Int, scoreB: Int, isServeA: Bool
//}

struct RallyAction {
    let player: Player, stat: Stat, stageBeforeAction: RallyStage, previousScoreEventsCount: Int
}

enum TeamSide { case teamA, teamB }

class ScoreViewModel: ObservableObject {
    @Published var scoreA = 0
    @Published var scoreB = 0
    @Published var gameOutcomeMessage = ""
    @Published var isSetFinished = false
    @Published var isServeA: Bool
    @Published var rallyStage: RallyStage = .serving
    @Published var scoreEvents: [ScoreEvent] = []
    
    // ラリー中の攻守交代のための状態フラグ
    @Published var rallyFlowReversed = false
    
    private var pointHistory: [GameState] = []
    private var rallyActionHistory: [RallyAction] = []
    private let initialServeIsTeamA: Bool
    private let matchID: UUID
    
    init(teamAServesFirst: Bool, matchID: UUID) {
        self.isServeA = teamAServesFirst
        self.initialServeIsTeamA = teamAServesFirst
        self.matchID = matchID
        scoreEvents.append(ScoreEvent(scoreA: 0, scoreB: 0, scoringTeam: "None", timestamp: Date(), playerName: "Game Start", actionType: .serve, isSuccess: true, hasServeRight: teamAServesFirst))
    }
    
    var canUndo: Bool { !rallyActionHistory.isEmpty || scoreEvents.count > 1 }
    
    /// ラリー中の攻守交代メソッド
    func switchRallyFlow() {
        DispatchQueue.main.async {
            // ラリーフローを反転
            self.rallyFlowReversed.toggle()
            
            // レシーブ段階に設定（攻守交代後の状態）
            self.rallyStage = .receiving
            
            // イベントログに記録
            self.scoreEvents.append(ScoreEvent(
                scoreA: self.scoreA,
                scoreB: self.scoreB,
                scoringTeam: self.isServeA ? "A" : "B",
                timestamp: Date(),
                playerName: "Rally Switch",
                actionType: .receive,
                isSuccess: true,
                hasServeRight: self.isServeA
            ))
        }
    }
    
    func undo() {
        // UIの更新を引き起こす変更を遅延させる
        DispatchQueue.main.async { // ✨ DispatchQueue.main.async を追加
            if !self.rallyActionHistory.isEmpty {
                let lastAction = self.rallyActionHistory.removeLast()
                            // ✨ 該当プレイヤーのstats配列から、追加したStatをIDで検索して削除
                            if let lastStatIndex = lastAction.player.stats.lastIndex(where: { $0.id == lastAction.stat.id }) {
                                lastAction.player.stats.remove(at: lastStatIndex)
                            }
                if self.scoreEvents.count > lastAction.previousScoreEventsCount {
                    self.scoreEvents.removeLast(self.scoreEvents.count - lastAction.previousScoreEventsCount)
                }
                self.rallyStage = lastAction.stageBeforeAction
                if let lastValidEvent = self.scoreEvents.last {
                    self.scoreA = lastValidEvent.scoreA
                    self.scoreB = lastValidEvent.scoreB
                    self.isServeA = lastValidEvent.hasServeRight
                } else {
                    self.scoreA = 0
                    self.scoreB = 0
                    self.isServeA = self.initialServeIsTeamA
                    self.rallyStage = .serving
                }
                
                // ラリーフローもリセット
                self.rallyFlowReversed = false
                
                self.checkGameStatus()
            } else if self.scoreEvents.count > 1 {
                self.scoreEvents.removeLast()
                if let lastEvent = self.scoreEvents.last {
                    self.scoreA = lastEvent.scoreA
                    self.scoreB = lastEvent.scoreB
                    self.isServeA = lastEvent.hasServeRight
                    self.rallyStage = .serving
                }
                
                // ラリーフローもリセット
                self.rallyFlowReversed = false
                
                self.checkGameStatus()
            }
        }
    }

    func processRallyEvent(player: Player, type: StatType, isSuccess: Bool, reason: FailureReason? = nil) {
        let stat = Stat(type: type, matchID: self.matchID, isSuccess: isSuccess, failureReason: reason)
        player.addStat(stat)
        rallyActionHistory.append(RallyAction(player: player, stat: stat, stageBeforeAction: self.rallyStage, previousScoreEventsCount: scoreEvents.count))
        
        let currentScoringTeamName = isServeA ? "A" : "B"
        scoreEvents.append(ScoreEvent(scoreA: scoreA, scoreB: scoreB, scoringTeam: currentScoringTeamName, timestamp: Date(), playerName: player.name, actionType: type, isSuccess: isSuccess, hasServeRight: isServeA))
        
        // UIの更新を遅延させる
        DispatchQueue.main.async { // ✨ DispatchQueue.main.async を追加
            if isSuccess {
                switch self.rallyStage {
                case .serving:
                    self.rallyStage = .receiving
                    // サーブ成功時にラリーフローをリセット
                    self.rallyFlowReversed = false
                case .receiving: self.rallyStage = .setting
                case .setting: self.rallyStage = .attacking
                case .attacking:
                    let winnerIsTeamA = self.rallyFlowReversed ? self.isServeA : !self.isServeA
                    self.addPoint(forTeamA: winnerIsTeamA, player: player, type: type, isSuccess: isSuccess)
                case .blocking:
                    let winnerIsTeamA = self.rallyFlowReversed ? !self.isServeA : self.isServeA
                    self.addPoint(forTeamA: winnerIsTeamA, player: player, type: type, isSuccess: isSuccess)
                case .gameEnd:
                    break // ゲーム終了時は何もしない
                }
            } else {
                let winnerIsTeamA: Bool
                if self.rallyStage == .serving {
                    winnerIsTeamA = !self.isServeA
                } else {
                    winnerIsTeamA = self.rallyFlowReversed ? !self.isServeA : self.isServeA
                }
                self.addPoint(forTeamA: winnerIsTeamA, player: player, type: type, isSuccess: isSuccess)
            }
        }
    }
    
    func processAttackReceived(player: Player, originalStat: Stat) {
        rallyActionHistory.append(RallyAction(player: player, stat: originalStat, stageBeforeAction: self.rallyStage, previousScoreEventsCount: scoreEvents.count))
        
        let currentScoringTeamName = isServeA ? "A" : "B"
        scoreEvents.append(ScoreEvent(scoreA: scoreA, scoreB: scoreB, scoringTeam: currentScoringTeamName, timestamp: Date(), playerName: player.name, actionType: originalStat.type, isSuccess: originalStat.isSuccess, hasServeRight: isServeA))
        
        // UIの更新を遅延させる
        DispatchQueue.main.async { // ✨ DispatchQueue.main.async を追加
            self.isServeA.toggle()
            self.rallyStage = .receiving
            // 攻守が変わったのでラリーフローをリセット
            self.rallyFlowReversed = false
        }
    }
    
    func processSetFailure(player: Player, reason: FailureReason) {
        // ✨ エラー修正: Stat生成時にmatchIDを渡す
        let stat = Stat(type: .setting, matchID: self.matchID, isSuccess: false, failureReason: reason)
        player.addStat(stat)
        rallyActionHistory.append(RallyAction(player: player, stat: stat, stageBeforeAction: self.rallyStage, previousScoreEventsCount: scoreEvents.count))
        
        let currentScoringTeamName = isServeA ? "A" : "B"
        scoreEvents.append(ScoreEvent(scoreA: scoreA, scoreB: scoreB, scoringTeam: currentScoringTeamName, timestamp: Date(), playerName: player.name, actionType: .setting, isSuccess: false, hasServeRight: isServeA))
        
        // UIの更新を遅延させる
        DispatchQueue.main.async { // ✨ DispatchQueue.main.async を追加
            self.isServeA.toggle()
            self.rallyStage = .attacking
            // 攻守が変わったのでラリーフローをリセット
            self.rallyFlowReversed = false
        }
    }
    
    func processBlockCover(player: Player, originalStat: Stat) {
        rallyActionHistory.append(RallyAction(player: player, stat: originalStat, stageBeforeAction: self.rallyStage, previousScoreEventsCount: scoreEvents.count))
        
        let currentScoringTeamName = isServeA ? "A" : "B"
        scoreEvents.append(ScoreEvent(scoreA: scoreA, scoreB: scoreB, scoringTeam: currentScoringTeamName, timestamp: Date(), playerName: player.name, actionType: originalStat.type, isSuccess: originalStat.isSuccess, hasServeRight: isServeA))
        
        // UIの更新を遅延させる
        DispatchQueue.main.async { // ✨ DispatchQuery.main.async を追加
            self.rallyStage = .receiving
        }
    }
    
    func processBlockCounterAttack(player: Player, originalStat: Stat) {
        rallyActionHistory.append(RallyAction(player: player, stat: originalStat, stageBeforeAction: self.rallyStage, previousScoreEventsCount: scoreEvents.count))
        
        let currentScoringTeamName = isServeA ? "A" : "B"
        scoreEvents.append(ScoreEvent(scoreA: scoreA, scoreB: scoreB, scoringTeam: currentScoringTeamName, timestamp: Date(), playerName: player.name, actionType: originalStat.type, isSuccess: originalStat.isSuccess, hasServeRight: isServeA))
        
        // UIの更新を遅延させる
        DispatchQueue.main.async { // ✨ DispatchQueue.main.async を追加
            self.isServeA.toggle()
            self.rallyStage = .attacking
            // 攻守が変わったのでラリーフローをリセット
            self.rallyFlowReversed = false
        }
    }
    
    func addPoint(forTeamA: Bool, player: Player, type: StatType, isSuccess: Bool) {
        // スコアを直接更新し、その後にイベントを追加
        if forTeamA { scoreA += 1 } else { scoreB += 1 }
        
        let scoringTeamName = forTeamA ? "A" : "B"
        
        // scoreEventsに得点イベントを追加
        scoreEvents.append(ScoreEvent(scoreA: scoreA, scoreB: scoreB, scoringTeam: scoringTeamName, timestamp: Date(), playerName: player.name, actionType: type, isSuccess: isSuccess, hasServeRight: isServeA))
        
        // UIの更新（rallyStageとisServeA）を遅延させる
        DispatchQueue.main.async { // ✨ DispatchQueue.main.async を追加
            self.isServeA.toggle()
            self.rallyStage = .serving
            self.rallyActionHistory.removeAll()
            // 新しいラリー開始時にフローをリセット
            self.rallyFlowReversed = false
            self.checkGameStatus()
        }
    }
    
    func resetGame() {
        // UIの更新を遅延させる
        DispatchQueue.main.async { // ✨ DispatchQueue.main.async を追加
            self.scoreA = 0
            self.scoreB = 0
            self.isServeA = self.initialServeIsTeamA
            self.gameOutcomeMessage = ""
            self.isSetFinished = false
            self.scoreEvents.removeAll()
            self.scoreEvents.append(ScoreEvent(scoreA: 0, scoreB: 0, scoringTeam: "None", timestamp: Date(), playerName: "Game Start", actionType: .serve, isSuccess: true, hasServeRight: self.initialServeIsTeamA))
            self.pointHistory.removeAll()
            self.rallyActionHistory.removeAll()
            self.rallyStage = .serving
            // ラリーフローもリセット
            self.rallyFlowReversed = false
        }
    }

    func checkGameStatus() {
        // この関数は@PublishedであるgameOutcomeMessageとisSetFinishedを設定します。
        // もしこれが@Publishedプロパティの変更内から呼び出される場合、警告の原因になる可能性があります。
        // ただし、通常は遅延された更新チェーンの最後に呼び出されるため安全です。
        // 警告が続く場合は、この処理も遅延させる必要があるかもしれません。
        self.isSetFinished = false
        if (scoreA == 15 && scoreB < 14) || scoreA == 17 {
            self.gameOutcomeMessage = "Team A WINS!"; self.isSetFinished = true; return
        }
        if (scoreB == 15 && scoreA < 14) || scoreB == 17 {
            self.gameOutcomeMessage = "Team B WINS!"; self.isSetFinished = true; return
        }
        if scoreA >= 14 && scoreB >= 14 {
            if scoreA == scoreB { self.gameOutcomeMessage = "Deuce! First to 17 wins!" }
            else if scoreA == 16 { self.gameOutcomeMessage = "Team A Set Point!" }
            else if scoreB == 16 { self.gameOutcomeMessage = "Team B Set Point!" }
            else { self.gameOutcomeMessage = "Deuce! First to 17 wins!" }
        } else if scoreA == 14 { self.gameOutcomeMessage = "Team A Set Point!" }
        else if scoreB == 14 { self.gameOutcomeMessage = "Team B Set Point!" }
        else { self.gameOutcomeMessage = "" }
    }
}
