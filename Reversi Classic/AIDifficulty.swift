//
//  AIDifficulty.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 01.02.2026.
//

import Foundation

enum AIDifficulty: String, CaseIterable, Identifiable {
    case easy
    case medium
    case hard

    var id: String { rawValue }

    var title: String {
        switch self {
        case .easy: return String(localized:"easy") //  "Лёгкий"
        case .medium: return String(localized:"middle") // "Средний"
        case .hard: return String(localized:"hard") // "Сложный"
        }
    }
}
