import AVFoundation
import SwiftUI

@MainActor
class SoundManager {
    static let shared = SoundManager()

    private var players: [String: AVAudioPlayer] = [:]
    @AppStorage("soundEnabled") var soundEnabled = true

    func preload() {
        let sounds = SoundEffect.allCases.map(\.fileName)
        for name in sounds {
            if let url = Bundle.main.url(forResource: name, withExtension: "wav") ??
                Bundle.main.url(forResource: name, withExtension: "caf") ??
                Bundle.main.url(forResource: name, withExtension: "mp3") {
                do {
                    let player = try AVAudioPlayer(contentsOf: url)
                    player.prepareToPlay()
                    players[name] = player
                } catch {}
            }
        }
    }

    func play(_ sound: SoundEffect) {
        guard soundEnabled else { return }
        guard let player = players[sound.fileName] else { return }
        player.currentTime = 0
        player.play()
    }

    enum SoundEffect: String, CaseIterable {
        case coinSave = "coin-clink"
        case success = "chime-success"
        case levelUp = "level-up"
        case cardScratch = "card-scratch"
        case epicReveal = "epic-reveal"

        var fileName: String { rawValue }
    }
}
