//
//  ReversiEngine.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 01.02.2026.
//

import Foundation

enum Disc: Int, Codable {
    case empty = 0
    case black = 1   // player by default
    case white = 2   // iphone by default


    var opponent: Disc {
        switch self {
        case .black: return .white
        case .white: return .black
        case .empty: return .empty
        }
    }
}

struct Move: Hashable {
    let r: Int
    let c: Int
}

struct ReversiEngine {
    static let size = 8

    private(set) var board: [[Disc]] = Array(
        repeating: Array(repeating: .empty, count: size),
        count: size
    )

    private(set) var currentTurn: Disc = .black
    private(set) var isGameOver: Bool = false
    private(set) var lastMove: Move? = nil

    init() {
        reset()
    }

    mutating func reset() {
        board = Array(repeating: Array(repeating: .empty, count: Self.size), count: Self.size)
        board[3][3] = .white
        board[3][4] = .black
        board[4][3] = .black
        board[4][4] = .white

        currentTurn = .black
        isGameOver = false
        lastMove = nil
    }

    func count(_ disc: Disc) -> Int {
        board.flatMap { $0 }.filter { $0 == disc }.count
    }

    func inBounds(_ r: Int, _ c: Int) -> Bool {
        (0..<Self.size).contains(r) && (0..<Self.size).contains(c)
    }

    private let directions: [(Int, Int)] = [
        (-1, -1), (-1, 0), (-1, 1),
        ( 0, -1),          ( 0, 1),
        ( 1, -1), ( 1, 0), ( 1, 1)
    ]

    func flipsForMove(_ move: Move, as disc: Disc) -> [Move] {
        guard inBounds(move.r, move.c), board[move.r][move.c] == .empty else { return [] }
        guard disc != .empty else { return [] }

        var allFlips: [Move] = []

        for (dr, dc) in directions {
            var r = move.r + dr
            var c = move.c + dc

            var line: [Move] = []
            var sawOpponent = false

            while inBounds(r, c) {
                let cell = board[r][c]
                if cell == disc.opponent {
                    sawOpponent = true
                    line.append(Move(r: r, c: c))
                } else if cell == disc {
                    if sawOpponent {
                        allFlips.append(contentsOf: line)
                    }
                    break
                } else { // empty
                    break
                }

                r += dr
                c += dc
            }
        }

        return allFlips
    }

    func isValidMove(_ move: Move, as disc: Disc) -> Bool {
        !flipsForMove(move, as: disc).isEmpty
    }

    func validMoves(for disc: Disc) -> [Move] {
        guard disc != .empty else { return [] }
        var moves: [Move] = []
        for r in 0..<Self.size {
            for c in 0..<Self.size {
                let m = Move(r: r, c: c)
                if isValidMove(m, as: disc) {
                    moves.append(m)
                }
            }
        }
        return moves
    }

    @discardableResult
    mutating func applyMove(_ move: Move) -> [Move]? {
        guard !isGameOver else { return nil }
        let disc = currentTurn
        let flips = flipsForMove(move, as: disc)
        guard !flips.isEmpty else { return nil }

        board[move.r][move.c] = disc
        for f in flips {
            board[f.r][f.c] = disc
        }

        lastMove = move
        advanceTurnAfterMove()

        return [move] + flips
    }

    
    mutating func advanceTurnAfterMove() {
        let next = currentTurn.opponent
        let nextMoves = validMoves(for: next)
        if !nextMoves.isEmpty {
            currentTurn = next
            return
        }

        let myMoves = validMoves(for: currentTurn)
        if !myMoves.isEmpty {
            return
        }

        isGameOver = true
    }

    
    mutating func ensureTurnIsPlayableOrGameOver() {
        if isGameOver { return }
        let moves = validMoves(for: currentTurn)
        if moves.isEmpty {
            let next = currentTurn.opponent
            if validMoves(for: next).isEmpty {
                isGameOver = true
            } else {
                currentTurn = next
            }
        }
    }
}

