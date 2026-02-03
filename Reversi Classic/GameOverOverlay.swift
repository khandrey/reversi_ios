//
//  GameOverOverlay.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 03.02.2026.
//

import SwiftUI

enum GameOutcome {
    case playerWin
    case aiWin
    case draw
}

struct GameOverOverlay: View {
    let outcome: GameOutcome
    let onDismiss: () -> Void
    let onRestart: () -> Void

    @Environment(\.locale) private var locale

    var body: some View {
        ZStack {
            // затемнение фона
            Color.black.opacity(0.55)
                .ignoresSafeArea()

            VStack(spacing: 14) {
                Image(assetName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 320)
                    .shadow(color: .black.opacity(0.5), radius: 10, y: 6)

                HStack(spacing: 12) {
                    Button(action: onRestart) {
                        Text("start_again")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .background(.black.opacity(0.35))
                            .clipShape(Capsule())
                    }

                    Button(action: onDismiss) {
                        Text("ok")
                            .font(.system(size: 17, weight: .bold, design: .rounded))
                            .foregroundColor(.yellow)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 18)
                            .background(.black.opacity(0.35))
                            .clipShape(Capsule())
                    }
                }
            }
            .padding(.horizontal, 24)
        }
        .transition(.opacity)
    }

    private var languageCode: String {
        locale.language.languageCode?.identifier ?? "en"
    }

    private var assetName: String {
        let lang = (languageCode == "ru") ? "ru" : "en"

        switch outcome {
        case .playerWin:
            return "GameOver_PlayerWin_\(lang)"
        case .aiWin:
            return "GameOver_AIWin_\(lang)"
        case .draw:
            return "GameOver_Draw_\(lang)"
        }
    }
}
