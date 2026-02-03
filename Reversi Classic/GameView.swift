//
//  GameView.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 01.02.2026.
//


import SwiftUI

struct GameView: View {
    
    @Environment(\.dismiss) private var dismiss
    
    @State private var engine = ReversiEngine()
    @State private var thinking = false
    @State private var cascadeDelay: [Move: Double] = [:]
    
    @State private var prevBoard: [[Disc]] = []
    
    @State private var aiNotBefore: Date = .distantPast
    @State private var boardRevision: Int = 0
    
    @State private var animStart: Date = .distantPast
    @State private var showGameOverOverlay = false

    
    private let flipDuration: Double = 0.52   // как в DiscFlipView для flip
    private let dropDuration: Double = 0.35   // empty -> stone
    private let animBuffer: Double = 0.08     // небольшой запас
    
    // @State private var difficulty: AIDifficulty = .easy
    let difficulty: AIDifficulty
    
    private let player: Disc = .black
    private let ai: Disc = .white

    var body: some View {
        ZStack {
            AppBackground()

            VStack(spacing: 14) {
                header

                boardView
                    .padding(.horizontal, 12)

                if thinking {
                    
                    Text(LocalizedStringKey("iPhone_thinking"))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.yellow)
                        .padding(.vertical, 6)
                        .padding(.horizontal, 12)
                        .background(.black.opacity(0.35))
                        .clipShape(Capsule())
                }
                
                // footer

                Spacer(minLength: 0)
            }
            .padding(.top, 10)
            
            if showGameOverOverlay {
                GameOverOverlay(
                    outcome: currentOutcome(),
                    onDismiss: { showGameOverOverlay = false },
                    onRestart: {
                        engine.reset()
                        prevBoard = engine.board
                        cascadeDelay = [:]
                        animStart = Date()
                        thinking = false
                        showGameOverOverlay = false
                    }
                )
            }
            
        }
        .navigationBarHidden(true)
        .safeAreaInset(edge: .top, spacing: 0) {
            GameTopBar(
                onBack: { dismiss() },
                onRestart: {
                    engine.reset()
                    prevBoard = engine.board
                    thinking = false
                    cascadeDelay = [:]
                    bumpBoardRevision()
                    animStart = Date()
                }
            )
        }
        .onAppear {
            if prevBoard.isEmpty { prevBoard = engine.board }
            maybeAIMove()
        }
        .onChange(of: engine.currentTurn) { _ in maybeAIMove() }
    }


    private var header: some View {
        VStack(spacing: 6) {
            HStack {
                turnBadge
                Spacer()
                scoreBadge
            }
            .padding(.horizontal, 16)

            if engine.isGameOver {
                /*
                Text(gameOverText())
                    .font(.headline)
                    .padding(.top, 4)
                 */
                
            }
            /*
            else if thinking {
                Text("iPhone turn")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .foregroundColor(.yellow)
            } else {
                Text(engine.currentTurn == player ? "Your turn" : "iPhone turn")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .foregroundColor(.yellow)
            }
             */
        }
    }

    
    
    private var turnBadge: some View {
        
        
        
        HStack(spacing: 10) {
            // var turn_color: Color = .white
            // if(engine.currentTurn == player) { turn_color = .black }
            Circle()
                .frame(width: 14, height: 14)
                .opacity(0) // place for lamp for future
                .overlay(
                    Circle()
                        .frame(width: 14, height: 14)
                        .opacity(1)
                )
                .foregroundColor(engine.currentTurn == player ? .black : .white)

            Text(engine.currentTurn == player ? LocalizedStringKey("your_turn") : LocalizedStringKey("iphone_turn"))
                .font(.headline)
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var scoreBadge: some View {
        let b = engine.count(.black)
        let w = engine.count(.white)
        return HStack(spacing: 12) {
            Text("\(String(localized:"black")): \(b)")
            Text("\(String(localized:"white")): \(w)")
        }
        .font(.subheadline)
        .padding(.vertical, 6)
        .padding(.horizontal, 10)
        .background(.thinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
/*
    private var footer: some View {
        let playerMoves = engine.validMoves(for: player).count
        let aiMoves = engine.validMoves(for: ai).count

        return VStack(spacing: 8) {
            HStack {
                Text("Your turns: \(playerMoves)")
                Spacer()
                Text("iPhone turns: \(aiMoves)")
            }
            .font(.footnote)
            .foregroundStyle(.secondary)
            .padding(.horizontal, 16)

            if !engine.isGameOver && engine.validMoves(for: engine.currentTurn).isEmpty {
                Text("No more turns — skipping turn.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .onAppear {
                        // skipping turn
                        DispatchQueue.main.async {
                            engine.ensureTurnIsPlayableOrGameOver()
                        }
                    }
            }
        }
    }
*/
    private var boardView: some View {
        let possible = Set(engine.validMoves(for: engine.currentTurn))

        return GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = side / CGFloat(ReversiEngine.size)

            VStack(spacing: 0) {
                ForEach(0..<ReversiEngine.size, id: \.self) { r in
                    HStack(spacing: 0) {
                        ForEach(0..<ReversiEngine.size, id: \.self) { c in
                            let disc = engine.board[r][c]
                            let move = Move(r: r, c: c)
                            let isHint = possible.contains(move) && disc == .empty

                            let current = engine.board[r][c]
                            let previous = (prevBoard.isEmpty ? current : prevBoard[r][c])
                            let d = delay(for: Move(r: r, c: c))
                            
                            ZStack {
                                Rectangle()
                                    .fill(Color.green.opacity(0.35))
                                    .overlay(
                                        Rectangle().stroke(Color.black.opacity(0.25), lineWidth: 1)
                                    )

                                if isHint {
                                    Circle()
                                        .fill(Color.white.opacity(0.20))
                                        .frame(width: cell * 0.28, height: cell * 0.28)
                                }

                                /*
                                DiscFlipView(
                                    from: previous,
                                    to: current,
                                    size: cell * 0.78,
                                    delay: delay(for: move)
                                )
                                 
                                DiscFlipView(
                                    from: previous,
                                    to: current,
                                    size: cell * 0.78,
                                    delay: delay(for: move),
                                    revision: boardRevision
                                )
                                 */
                                DiscTimelineView(
                                    from: previous,
                                    to: current,
                                    size: cell * 0.78,
                                    delay: d,
                                    animStart: animStart
                                )

                            }
                            .frame(width: cell, height: cell)
                            .contentShape(Rectangle())
                            .onTapGesture {
                                handleTap(r: r, c: c)
                            }
                        }
                    }
                }
            }
            .frame(width: side, height: side)
            .background(Color.green.opacity(0.45))
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .aspectRatio(1, contentMode: .fit)
    }

    @ViewBuilder
    private func discView(_ disc: Disc, size: CGFloat) -> some View {
        switch disc {
        case .empty:
            EmptyView()
        case .black:
            Circle()
                .fill(Color.black)
                .frame(width: size, height: size)
                .shadow(radius: 1, y: 1)
        case .white:
            Circle()
                .fill(Color.white)
                .frame(width: size, height: size)
                .overlay(Circle().stroke(Color.black.opacity(0.25), lineWidth: 1))
                .shadow(radius: 1, y: 1)
        }
    }

   
    private func handleTap(r: Int, c: Int) {
        guard !engine.isGameOver else { return }
        guard !thinking else { return }
        guard engine.currentTurn == player else { return }

        let origin = Move(r: r, c: c)

        prevBoard = engine.board
        if let changed = engine.applyMove(origin) {
            buildCascadeDelay(changed: changed, origin: origin)
            bumpBoardRevision()
            animStart = Date()
            armAIAfterBoardAnimation()
            if engine.isGameOver {
                showGameOverOverlay = true
            }

        }
    }

    private func bumpBoardRevision() {
        boardRevision &+= 1
    }
    
    private func armAIAfterBoardAnimation() {
        let maxDelay = cascadeDelay.values.max() ?? 0
        // При ходе всегда есть постановка + часть клеток flip.
        // Берём “самую длинную” разумную оценку.
        let total = maxDelay + max(flipDuration, dropDuration) + animBuffer
        aiNotBefore = Date().addingTimeInterval(total)
    }

    
    private func delay(for move: Move) -> Double {
        cascadeDelay[move] ?? 0
    }
    private func buildCascadeDelay(changed: [Move], origin: Move) {
        
        let step: Double = 0.07   // задержка между "кольцами"
        

        // Сортируем по расстоянию от клетки хода (Chebyshev — как “квадратные кольца”)
        func dist(_ m: Move) -> Int {
            max(abs(m.r - origin.r), abs(m.c - origin.c))
        }

        let sorted = changed.sorted {
            let d0 = dist($0), d1 = dist($1)
            if d0 != d1 { return d0 < d1 }
            // tie-breaker для стабильности
            if $0.r != $1.r { return $0.r < $1.r }
            return $0.c < $1.c
        }

        var map: [Move: Double] = [:]
        for m in sorted {
            map[m] = Double(dist(m)) * step
        }

        cascadeDelay = map
    }

    private func maybeAIMove() {
        guard !engine.isGameOver else { return }
        guard engine.currentTurn == ai else { return }
        guard !thinking else { return }

        let now = Date()
        if now < aiNotBefore {
            let wait = aiNotBefore.timeIntervalSince(now)
            DispatchQueue.main.asyncAfter(deadline: .now() + wait) {
                maybeAIMove()
            }
            return
        }

        startAIMoveComputation()
    }

    private func startAIMoveComputation() {
        thinking = true

        let snapshot = engine
        let difficultySnapshot = difficulty

        Task.detached(priority: .userInitiated) {
            let move = ReversiAI.chooseMove(engine: snapshot, for: ai, difficulty: difficultySnapshot)

            await MainActor.run {
                defer { thinking = false }

                guard let move else {
                    
                    engine.ensureTurnIsPlayableOrGameOver()
                    return
                }

                prevBoard = engine.board
                if let changed = engine.applyMove(move) {
                    buildCascadeDelay(changed: changed, origin: move)
                    bumpBoardRevision()
                    animStart = Date()
                    if engine.isGameOver {
                        showGameOverOverlay = true
                    }

                }
            }
        }
    }

    
    /*
    private func maybeAIMove() {
        guard !engine.isGameOver else { return }
        guard engine.currentTurn == ai else { return }
        guard !thinking else { return }

        // let move = SimpleAI.chooseMove(engine: engine, for: ai)
        let move = ReversiAI.chooseMove(engine: engine, for: ai, difficulty: difficulty)
        
        if move == nil {
            
            engine.ensureTurnIsPlayableOrGameOver()
            return
        }

        thinking = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
            prevBoard = engine.board

            if let changed = engine.applyMove(move!) {
                buildCascadeDelay(changed: changed, origin: move!)
            }
            thinking = false
        }

    }
*/
    
    private func gameOverText() -> String {
        let b = engine.count(.black)
        let w = engine.count(.white)
        if b > w { return "Win! \(b) : \(w)" }
        if w > b { return "Lose. \(b) : \(w)" }
        return "Dead heat. \(b) : \(w)"
    }
    
    private func currentOutcome() -> GameOutcome {
        let myCount = engine.count(player)
        let aiCount = engine.count(ai)
        if myCount > aiCount { return .playerWin }
        if aiCount > myCount { return .aiWin }
        return .draw
    }
}

