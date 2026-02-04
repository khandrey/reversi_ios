//
//  SoundManager.swift
//  Reversi Classic
//
//  Created by Andrey hisamov on 04.02.2026.
//

import AVFoundation

final class SoundManager {

    static let shared = SoundManager()

    var soundEnabled: Bool = true

    private var movePlayer: AVAudioPlayer?
    private var flipPlayer: AVAudioPlayer?

    private init() {
        preparePlayers()
    }

    private func preparePlayers() {
        movePlayer = makePlayer(name: "move", ext: "wav")
        flipPlayer = makePlayer(name: "flip", ext: "wav")

        movePlayer?.prepareToPlay()
        flipPlayer?.prepareToPlay()
    }

    private func makePlayer(name: String, ext: String) -> AVAudioPlayer? {
        guard let url = Bundle.main.url(forResource: name, withExtension: ext) else {
            print("Sound not found: \(name).\(ext)")
            return nil
        }

        do {
            let player = try AVAudioPlayer(contentsOf: url)
            player.volume = 0.8
            return player
        } catch {
            print("Failed to load sound \(name): \(error)")
            return nil
        }
    }

    // MARK: - Public API

    func playMove() {
        guard soundEnabled else { return }
        movePlayer?.stop()
        movePlayer?.currentTime = 0
        movePlayer?.play()
    }

    func playFlip() {
        guard soundEnabled else { return }
        flipPlayer?.stop()
        flipPlayer?.currentTime = 0
        flipPlayer?.play()
    }
}
