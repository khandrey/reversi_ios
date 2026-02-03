//
//  DifficultySelectView.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 01.02.2026.
//

import SwiftUI

struct DifficultySelectView: View {
    @Environment(\.dismiss) private var dismiss

    private let buttonAspect: CGFloat = 928.0 / 256.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                AppBackground()

                // Логотип ближе к верху
                VStack {
                    Image("LogoTitleWithBG")
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 24)
                        .padding(.top, max(16, geo.safeAreaInsets.top + 10))

                    Spacer()
                }

                // Контент (поднимаем выше центра + скролл на маленьких экранах)
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        Text("select_difficulty_title") // локализуемый ключ
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundColor(.yellow)
                            .shadow(color: .black.opacity(0.45), radius: 1, y: 1)
                            .padding(.top, 6)

                        NavigationLink {
                            GameView(difficulty: .easy)
                        } label: {
                            menuButton(titleKey: "difficulty_easy", availableWidth: geo.size.width)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            GameView(difficulty: .medium)
                        } label: {
                            menuButton(titleKey: "difficulty_medium", availableWidth: geo.size.width)
                        }
                        .buttonStyle(.plain)

                        NavigationLink {
                            GameView(difficulty: .hard)
                        } label: {
                            menuButton(titleKey: "difficulty_hard", availableWidth: geo.size.width)
                        }
                        .buttonStyle(.plain)

                        Button {
                            dismiss()
                        } label: {
                            menuButton(titleKey: "back", availableWidth: geo.size.width)
                        }
                        .buttonStyle(.plain)

                        // небольшой нижний отступ, чтобы на iPhone с home indicator не прилипало
                        Spacer(minLength: 16)
                    }
                    .frame(maxWidth: .infinity)
                    // Strat block position.
                    .padding(.top, geo.size.height * 0.32)
                    .padding(.bottom, max(16, geo.safeAreaInsets.bottom + 10))
                }
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    private func menuButton(titleKey: String, availableWidth: CGFloat) -> some View {
        let w = min(availableWidth * 0.78, 360)
        let h = w / buttonAspect

        return ZStack {
            Image("ButtonBG")
                .resizable()
                .scaledToFit() // полностью, без обрезки
                .frame(width: w, height: h)

            Text(LocalizedStringKey(titleKey))
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.yellow)
                .shadow(color: .black.opacity(0.45), radius: 1, y: 1)
        }
        .contentShape(Rectangle())
        .accessibilityLabel(Text(LocalizedStringKey(titleKey)))
    }
}
