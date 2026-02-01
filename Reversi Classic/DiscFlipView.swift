//
//  DiscFlipView.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 01.02.2026.
//

import SwiftUI

struct DiscFlipView: View {
    let from: Disc
    let to: Disc
    let size: CGFloat
    let delay: Double

    @State private var progress: Double = 1.0
    @State private var scheduled: DispatchWorkItem?
    @State private var token: UUID = UUID()

    var body: some View {
        let isFlip = (from != .empty && to != .empty && from != to)
        let isDrop = (from == .empty && to != .empty)
        let isFadeOut = (from != .empty && to == .empty)

        
        let visible: Disc = isFlip
            ? (progress < 0.5 ? from : to)
            : to

        
        let squashMid: CGFloat = 0.22
        let s = sin(.pi * progress) // 0..1..0
        let squashX = isFlip ? (1.0 - (1.0 - squashMid) * CGFloat(s)) : 1.0

        
        let angle = isFlip ? (progress * 180.0) : 0.0

        
        let opacity: Double = isDrop ? progress : (isFadeOut ? (1.0 - progress) : 1.0)
        let scale: CGFloat = isDrop
            ? (0.82 + 0.18 * CGFloat(progress)) // лёгкое “приземление”
            : (isFadeOut ? (1.0 - 0.08 * CGFloat(progress)) : 1.0)

        return ZStack {
            discImage(visible)
                .frame(width: size, height: size)
                .opacity(opacity)
                .scaleEffect(scale)
                .scaleEffect(x: squashX, y: 1.0, anchor: .center)
        }
        .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0))
        .onAppear {
            startIfNeeded()
        }
        .onChange(of: key) { _ in
            startIfNeeded()
        }
        .onDisappear {
            cancel()
        }
    }

    
    private var key: String {
        "\(from.rawValue)-\(to.rawValue)-\(delay)"
    }

    private func cancel() {
        scheduled?.cancel()
        scheduled = nil
        token = UUID()
    }

    private func startIfNeeded() {
        cancel()

        
        guard from != to else {
            progress = 1.0
            return
        }

        progress = 0.0
        let myToken = token

        let work = DispatchWorkItem {
            guard myToken == token else { return }

            
            let duration: Double
            if from == .empty && to != .empty {
                duration = 0.35
                withAnimation(.spring(response: duration, dampingFraction: 0.72)) {
                    progress = 1.0
                }
            } else if from != .empty && to == .empty {
                duration = 0.18
                withAnimation(.easeInOut(duration: duration)) {
                    progress = 1.0
                }
            } else {                                    
                duration = 0.52
                withAnimation(.easeInOut(duration: duration)) {
                    progress = 1.0
                }
            }
        }

        scheduled = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    @ViewBuilder
    private func discImage(_ disc: Disc) -> some View {
        switch disc {
        case .empty:
            EmptyView()
        case .black:
            Image("blackStone")
                .resizable()
                .scaledToFit()
                .shadow(color: .black.opacity(0.35), radius: 2, y: 1)
        case .white:
            Image("whiteStone")
                .resizable()
                .scaledToFit()
                .shadow(color: .black.opacity(0.25), radius: 2, y: 1)
        }
    }
}
