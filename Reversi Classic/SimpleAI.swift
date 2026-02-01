//
//  SimpleAI.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 01.02.2026.
//

import Foundation

struct SimpleAI {
    
    static func chooseMove(engine: ReversiEngine, for disc: Disc) -> Move? {
        let moves = engine.validMoves(for: disc)
        guard !moves.isEmpty else { return nil }

        
        func score(_ m: Move) -> Int {
            let flips = engine.flipsForMove(m, as: disc).count
            let isCorner = (m.r == 0 || m.r == ReversiEngine.size - 1) && (m.c == 0 || m.c == ReversiEngine.size - 1)
            return flips + (isCorner ? 100 : 0)
        }

        return moves.max(by: { score($0) < score($1) })
    }
}

