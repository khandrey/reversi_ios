//
//  GameTopBar.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 01.02.2026.
//

import SwiftUI

struct GameTopBar: View {
    let onBack: () -> Void
    let onRestart: () -> Void

    private let buttonAspect: CGFloat = 1092.0 / 387.0

    private let barHeight: CGFloat = 88
    private let buttonHeight: CGFloat = 36

    var body: some View {
        GeometryReader { geo in
            let buttonWidth = buttonHeight * buttonAspect

            let sidePadding: CGFloat = 24 + max(geo.safeAreaInsets.leading, geo.safeAreaInsets.trailing)

            ZStack {
                
                Image("toolbarBG")
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: barHeight)
                    .clipped()

                
                HStack {
                    Button(action: onBack) {
                        Image("goBack")
                            .resizable()
                            .scaledToFit()
                            .frame(width: buttonWidth, height: buttonHeight)
                            .contentShape(Rectangle())
                    }

                    Spacer(minLength: 0)

                    Button(action: onRestart) {
                        Image("startAgain")
                            .resizable()
                            .scaledToFit()
                            .frame(width: buttonWidth, height: buttonHeight)
                            .contentShape(Rectangle())
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, sidePadding)
            }
            .frame(width: geo.size.width, height: barHeight)
        }
        .frame(height: barHeight)
    }
}
