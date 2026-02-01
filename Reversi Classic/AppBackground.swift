//
//  AppBackground.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 01.02.2026.
//

import SwiftUI

struct AppBackground: View {
    var body: some View {
        GeometryReader { geo in
            Image("BG")
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: geo.size.width, height: geo.size.height)
                .clipped()
                .ignoresSafeArea()
                .accessibilityHidden(true)
        }
        .ignoresSafeArea()
    }
}

