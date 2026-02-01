//
//  ReversiApp.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 01.02.2026.
//

import SwiftUI

@main
struct ReversiApp: App {
    init() {
            NavigationBarAppearance.applyToolbarImageBackground()
        }
    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
