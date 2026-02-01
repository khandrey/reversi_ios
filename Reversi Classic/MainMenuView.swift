//
//  MainMenuView.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 01.02.2026.
//


import SwiftUI

struct MainMenuView: View {
    
    private let buttonAspect: CGFloat = 928.0 / 256.0

    var body: some View {
        GeometryReader { geo in
            ZStack {
                AppBackground()
                    .ignoresSafeArea()

                
                VStack {
                    Image("LogoTitleWithBG")
                        .resizable()
                        .scaledToFit()
                        .padding(.horizontal, 24)
                        .padding(.top, max(16, geo.safeAreaInsets.top + 10))

                    Spacer()
                }

                
                VStack(alignment: .center, spacing: 16) {
                    NavigationLink {
                        GameView()
                    } label: {
                        menuButton(title: "Начать игру", availableWidth: geo.size.width)
                    }
                    .buttonStyle(.plain)

                    
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
                .padding(.top, geo.size.height / 2)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    
    private func menuButton(title: String, availableWidth: CGFloat) -> some View {
        
        let w = min(availableWidth * 0.78, 360)
        let h = w / buttonAspect

        return ZStack {
            Image("ButtonBG")
                .resizable()
                .scaledToFit()
                .frame(width: w, height: h)

            Text(title)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.yellow)
                .shadow(color: .black.opacity(0.45), radius: 1, y: 1)
        }
        
        .contentShape(Rectangle())
        .accessibilityLabel(title)
    }
}

