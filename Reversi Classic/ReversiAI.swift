//
//  SimpleAI.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 01.02.2026.
//

import Foundation

struct ReversiAI {

    // MARK: - Public

    static func chooseMove(engine: ReversiEngine, for me: Disc, difficulty: AIDifficulty) -> Move? {
        let moves = engine.validMoves(for: me)
        guard !moves.isEmpty else { return nil }

        switch difficulty {
        case .easy:
            return chooseGreedy(engine: engine, me: me)

        case .medium:
            // “чуть сложнее” = depth 3 (AI -> Player -> AI)
            return chooseAlphaBeta(engine: engine, me: me, depth: 3, advanced: false)

        case .hard:
            let empties = countEmpties(engine.board)
            let depth = (empties <= 10) ? 6 : 4
            return chooseAlphaBeta(engine: engine, me: me, depth: depth, advanced: true)
        }
    }

    // MARK: - Easy (greedy)

    private static func chooseGreedy(engine: ReversiEngine, me: Disc) -> Move? {
        let moves = engine.validMoves(for: me)
        guard !moves.isEmpty else { return nil }

        func score(_ m: Move) -> Int {
            let flips = engine.flipsForMove(m, as: me).count
            return flips + (isCorner(m) ? 500 : 0)
        }
        return moves.max(by: { score($0) < score($1) })
    }

    // MARK: - AlphaBeta (Medium/Hard)

    private static func chooseAlphaBeta(engine: ReversiEngine, me: Disc, depth: Int, advanced: Bool) -> Move? {
        // Важно: ход выбираем из позиции engine, предполагая что ходит "me".
        var candidates = engine.validMoves(for: me)
        guard !candidates.isEmpty else { return nil }

        // Сортировка ходов (сильно ускоряет и улучшает качество при альфа–бета)
        candidates.sort { moveOrderScore($0, engine: engine, me: me, advanced: advanced) >
                          moveOrderScore($1, engine: engine, me: me, advanced: advanced) }

        var bestMove: Move? = nil
        var bestValue = Int.min
        var alpha = Int.min / 4
        let beta = Int.max / 4

        for m in candidates {
            var e = engine
            guard e.applyMove(m) != nil else { continue }

            let v = negamax(engine: e, depth: depth - 1, alpha: -beta, beta: -alpha, me: me, advanced: advanced)
            let value = -v

            if value > bestValue {
                bestValue = value
                bestMove = m
            }
            if value > alpha { alpha = value }
        }

        return bestMove
    }

    /// Negamax alpha-beta from perspective of "me".
    /// engine.currentTurn определяет, кто ходит сейчас.
    private static func negamax(engine: ReversiEngine, depth: Int, alpha: Int, beta: Int, me: Disc, advanced: Bool) -> Int {
        if engine.isGameOver {
            return terminalScore(engine: engine, me: me)
        }
        if depth <= 0 {
            return evaluate(engine: engine, me: me, advanced: advanced)
        }

        var a = alpha
        let b = beta

        let sideToMove = engine.currentTurn
        let moves = engine.validMoves(for: sideToMove)

        if moves.isEmpty {
            // пас
            var e = engine
            e.ensureTurnIsPlayableOrGameOver()
            return -negamax(engine: e, depth: depth - 1, alpha: -b, beta: -a, me: me, advanced: advanced)
        }

        // move ordering
        var ordered = moves
        ordered.sort { moveOrderScore($0, engine: engine, me: sideToMove, advanced: advanced) >
                       moveOrderScore($1, engine: engine, me: sideToMove, advanced: advanced) }

        var best = Int.min / 4

        for m in ordered {
            var e = engine
            guard e.applyMove(m) != nil else { continue }

            let v = -negamax(engine: e, depth: depth - 1, alpha: -b, beta: -a, me: me, advanced: advanced)
            if v > best { best = v }
            if v > a { a = v }
            if a >= b { break } // cut
        }

        return best
    }

    // MARK: - Evaluation

    private static func evaluate(engine: ReversiEngine, me: Disc, advanced: Bool) -> Int {
        if engine.isGameOver {
            return terminalScore(engine: engine, me: me)
        }

        let opp = me.opponent
        let board = engine.board

        let material = engine.count(me) - engine.count(opp)
        let myMob = engine.validMoves(for: me).count
        let oppMob = engine.validMoves(for: opp).count
        let mobility = myMob - oppMob

        let myCorners = countCorners(board, disc: me)
        let oppCorners = countCorners(board, disc: opp)
        let corners = myCorners - oppCorners

        // Позиционные веса (классика Othello): углы — супер, X/C — опасно
        let positional = positionalScore(board, me: me)

        // Фронтир: фишки, прилегающие к пустым — чаще “плохие”
        let frontier = frontierScore(board, me: me)

        // Стабильность краёв: насколько “закреплены” края от углов
        let stability = advanced ? stableEdgeScore(board, me: me) : 0

        // Возможные ходы соперника в углы/края прямо сейчас
        let oppCornerMovesNow = opponentCornerMoves(engine: engine, opponent: opp)
        let oppEdgeMovesNow = opponentEdgeMoves(engine: engine, opponent: opp)

        // “Отложенные углы”: насколько мы открыли сопернику путь к углу через 1 ход (Hard only)
        let delayedCornerThreat = advanced ? delayedCornerThreatScore(engine: engine, me: me) : 0

        if !advanced {
            // Medium: depth=3 уже даёт силу, эвристика проще
            return
                8 * mobility +
                500 * corners +
                2 * material +
                3 * positional +
                (-3) * frontier +
                (-250) * oppCornerMovesNow
        } else {
            // Hard: углы/угрозы доминируют, + стабильность, + наказание за “отложенный угол”
            return
                10 * mobility +
                900 * corners +
                2 * material +
                6 * positional +
                (-6) * frontier +
                30 * stability +
                (-600) * oppCornerMovesNow +
                (-60)  * oppEdgeMovesNow +
                (-120) * delayedCornerThreat
        }
    }

    private static func terminalScore(engine: ReversiEngine, me: Disc) -> Int {
        let diff = engine.count(me) - engine.count(me.opponent)
        if diff > 0 { return 50_000 + diff }
        if diff < 0 { return -50_000 + diff }
        return 0
    }

    // MARK: - Move ordering

    private static func moveOrderScore(_ m: Move, engine: ReversiEngine, me: Disc, advanced: Bool) -> Int {
        // Быстрое приближение “качества” хода для сортировки
        if isCorner(m) { return 10_000 }
        if isXSquare(m) { return -3_000 }
        if isCSquare(m) { return -800 }

        // края полезны, но не как углы
        let edge = isEdge(m) ? 600 : 0

        // больше переворотов — чуть лучше (для ordering)
        let flips = engine.flipsForMove(m, as: me).count * 10

        // hard: дополнительно наказываем за “подпуск” соперника к углам сразу
        if advanced {
            var e = engine
            _ = e.applyMove(m)
            let opp = me.opponent
            let oppCorners = opponentCornerMoves(engine: e, opponent: opp)
            return edge + flips - oppCorners * 200
        }

        return edge + flips
    }

    // MARK: - Board feature helpers

    private static func countEmpties(_ board: [[Disc]]) -> Int {
        var n = 0
        for r in 0..<ReversiEngine.size {
            for c in 0..<ReversiEngine.size {
                if board[r][c] == .empty { n += 1 }
            }
        }
        return n
    }

    private static func isCorner(_ m: Move) -> Bool {
        let n = ReversiEngine.size - 1
        return (m.r == 0 || m.r == n) && (m.c == 0 || m.c == n)
    }

    private static func isEdge(_ m: Move) -> Bool {
        let n = ReversiEngine.size - 1
        return m.r == 0 || m.r == n || m.c == 0 || m.c == n
    }

    // X-squares: (1,1), (1,6), (6,1), (6,6)
    private static func isXSquare(_ m: Move) -> Bool {
        let n = ReversiEngine.size - 1
        return (m.r == 1 && m.c == 1)
            || (m.r == 1 && m.c == n - 1)
            || (m.r == n - 1 && m.c == 1)
            || (m.r == n - 1 && m.c == n - 1)
    }

    // C-squares: adjacent to corners on edges
    private static func isCSquare(_ m: Move) -> Bool {
        let n = ReversiEngine.size - 1
        let cSquares: Set<Move> = [
            Move(r: 0, c: 1), Move(r: 1, c: 0),
            Move(r: 0, c: n - 1), Move(r: 1, c: n),
            Move(r: n - 1, c: 0), Move(r: n, c: 1),
            Move(r: n - 1, c: n), Move(r: n, c: n - 1)
        ]
        return cSquares.contains(m)
    }

    private static func countCorners(_ board: [[Disc]], disc: Disc) -> Int {
        let n = ReversiEngine.size - 1
        let corners = [(0,0),(0,n),(n,0),(n,n)]
        return corners.reduce(0) { acc, p in acc + (board[p.0][p.1] == disc ? 1 : 0) }
    }

    private static func opponentCornerMoves(engine: ReversiEngine, opponent: Disc) -> Int {
        engine.validMoves(for: opponent).filter { isCorner($0) }.count
    }

    private static func opponentEdgeMoves(engine: ReversiEngine, opponent: Disc) -> Int {
        engine.validMoves(for: opponent).filter { isEdge($0) }.count
    }

    // Позиционная матрица весов (классика)
    private static func positionalScore(_ board: [[Disc]], me: Disc) -> Int {
        // 8x8
        let W: [[Int]] = [
            [120, -20,  20,   5,   5,  20, -20, 120],
            [-20, -40,  -5,  -5,  -5,  -5, -40, -20],
            [ 20,  -5,  15,   3,   3,  15,  -5,  20],
            [  5,  -5,   3,   3,   3,   3,  -5,   5],
            [  5,  -5,   3,   3,   3,   3,  -5,   5],
            [ 20,  -5,  15,   3,   3,  15,  -5,  20],
            [-20, -40,  -5,  -5,  -5,  -5, -40, -20],
            [120, -20,  20,   5,   5,  20, -20, 120]
        ]

        var s = 0
        let opp = me.opponent
        for r in 0..<ReversiEngine.size {
            for c in 0..<ReversiEngine.size {
                if board[r][c] == me { s += W[r][c] }
                else if board[r][c] == opp { s -= W[r][c] }
            }
        }
        return s
    }

    // Фронтир: у кого больше фишек рядом с пустыми — хуже
    private static func frontierScore(_ board: [[Disc]], me: Disc) -> Int {
        let opp = me.opponent
        let dirs = [(-1,-1),(-1,0),(-1,1),(0,-1),(0,1),(1,-1),(1,0),(1,1)]
        func inBounds(_ r: Int, _ c: Int) -> Bool {
            (0..<ReversiEngine.size).contains(r) && (0..<ReversiEngine.size).contains(c)
        }

        var meFront = 0
        var oppFront = 0

        for r in 0..<ReversiEngine.size {
            for c in 0..<ReversiEngine.size {
                let d = board[r][c]
                guard d != .empty else { continue }

                var nearEmpty = false
                for (dr, dc) in dirs {
                    let rr = r + dr, cc = c + dc
                    if inBounds(rr, cc), board[rr][cc] == .empty {
                        nearEmpty = true
                        break
                    }
                }

                if nearEmpty {
                    if d == me { meFront += 1 }
                    else if d == opp { oppFront += 1 }
                }
            }
        }

        return meFront - oppFront
    }

    // Приближение “стабильных” краёв: сколько подряд занято от углов по ребрам
    private static func stableEdgeScore(_ board: [[Disc]], me: Disc) -> Int {
        let n = ReversiEngine.size - 1
        let opp = me.opponent

        func runFromCorner(_ cells: [(Int,Int)], corner: (Int,Int)) -> Int {
            let cornerDisc = board[corner.0][corner.1]
            guard cornerDisc != .empty else { return 0 }

            var run = 0
            for (r,c) in cells {
                if board[r][c] == cornerDisc { run += 1 } else { break }
            }

            // если угол наш — это плюс, если соперника — минус
            return (cornerDisc == me ? run : -run)
        }

        // top edge from (0,0) to right
        let topFromLeft = (0...n).map { (0,$0) }
        let topFromRight = (0...n).reversed().map { (0,$0) }

        let bottomFromLeft = (0...n).map { (n,$0) }
        let bottomFromRight = (0...n).reversed().map { (n,$0) }

        let leftFromTop = (0...n).map { ($0,0) }
        let leftFromBottom = (0...n).reversed().map { ($0,0) }

        let rightFromTop = (0...n).map { ($0,n) }
        let rightFromBottom = (0...n).reversed().map { ($0,n) }

        var s = 0
        s += runFromCorner(topFromLeft, corner: (0,0))
        s += runFromCorner(topFromRight, corner: (0,n))
        s += runFromCorner(bottomFromLeft, corner: (n,0))
        s += runFromCorner(bottomFromRight, corner: (n,n))

        s += runFromCorner(leftFromTop, corner: (0,0))
        s += runFromCorner(leftFromBottom, corner: (n,0))
        s += runFromCorner(rightFromTop, corner: (0,n))
        s += runFromCorner(rightFromBottom, corner: (n,n))

        // небольшая корректировка: если соперник доминирует на краях — будет минус
        _ = opp // (оставлено для ясности)
        return s
    }

    /// “Отложенный угол”: если после текущей позиции у соперника есть ход, после которого у него появляется угол.
    /// Это ловит ситуации “поставил у стены — через пару ходов отдаёшь угол”.
    private static func delayedCornerThreatScore(engine: ReversiEngine, me: Disc) -> Int {
        let opp = me.opponent

        // Если у оппонента уже есть угол — это и так учитывается
        if opponentCornerMoves(engine: engine, opponent: opp) > 0 { return 3 }

        let oppMoves = engine.validMoves(for: opp)
        if oppMoves.isEmpty { return 0 }

        var threats = 0
        for om in oppMoves {
            var e = engine
            guard e.applyMove(om) != nil else { continue }

            // После хода оппонента: если у него (или у нас) открывается возможность хода в угол
            // С точки зрения нас опасно, если ОППОНЕНТ в следующем цикле сможет взять угол
            // (то есть после нашего ответа он снова получит угол; depth search обычно это ловит,
            // но штраф помогает “не подпускать” заранее).
            let cornersAfterOpp = opponentCornerMoves(engine: e, opponent: opp)
            if cornersAfterOpp > 0 { threats += 1 }
        }

        // чем больше таких ходов у соперника — тем опаснее позиция
        return threats
    }
}
