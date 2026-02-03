//
//  DiscTimelineView.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 03.02.2026.
//

import SwiftUI

struct DiscTimelineView: View {
    let from: Disc
    let to: Disc
    let size: CGFloat
    let delay: Double
    let animStart: Date

    private let flipDuration: Double = 0.52
    private let dropDuration: Double = 0.35
    private let fadeDuration: Double = 0.18

    var body: some View {
        TimelineView(.animation) { ctx in
            let t = ctx.date.timeIntervalSince(animStart)
            let progress = self.progress(at: t)

            let isFlip = (from != .empty && to != .empty && from != to)
            let isDrop = (from == .empty && to != .empty)
            let isFade = (from != .empty && to == .empty)

            let visible: Disc = isFlip ? (progress < 0.5 ? from : to) : to

            // squash в середине flip
            let squashMid: CGFloat = 0.22
            let s = sin(.pi * progress) // 0..1..0
            let squashX: CGFloat = isFlip ? (1.0 - (1.0 - squashMid) * CGFloat(s)) : 1.0

            // rotation для flip
            let angle: Double = isFlip ? (progress * 180.0) : 0.0

            // drop/fade
            let opacity: Double = isDrop ? progress : (isFade ? (1.0 - progress) : 1.0)
            let scale: CGFloat =
                isDrop ? (0.82 + 0.18 * CGFloat(progress))
              : isFade ? (1.0 - 0.08 * CGFloat(progress))
              : 1.0

            ZStack {
                discImage(visible)
                    .frame(width: size, height: size)
                    .opacity(opacity)
                    .scaleEffect(scale)
                    .scaleEffect(x: squashX, y: 1.0, anchor: .center)
            }
            .rotation3DEffect(.degrees(angle), axis: (x: 0, y: 1, z: 0))
        }
    }

    private func progress(at time: Double) -> Double {
        // нет изменения — нет анимации
        if from == to { return 1.0 }

        let start = delay
        let local = time - start
        if local <= 0 { return 0.0 }

        let dur: Double
        if from == .empty && to != .empty { dur = dropDuration }
        else if from != .empty && to == .empty { dur = fadeDuration }
        else { dur = flipDuration }

        return min(1.0, max(0.0, local / dur))
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
