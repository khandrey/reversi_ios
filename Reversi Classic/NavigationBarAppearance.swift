//
//  NavigationBarAppearance.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 01.02.2026.
//

import SwiftUI
import UIKit

enum NavigationBarAppearance {
    static func applyToolbarImageBackground() {
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()

        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear

        if let img = UIImage(named: "toolbarBG") {
            appearance.backgroundImage = img
        }

        
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]

        let navBar = UINavigationBar.appearance()
        navBar.standardAppearance = appearance
        navBar.scrollEdgeAppearance = appearance
        navBar.compactAppearance = appearance
    }
}
