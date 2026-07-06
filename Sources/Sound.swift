import AppKit
import AVFoundation

/// Mac備え付けの音（/System/Library/Sounds）だけを扱うファサード。
enum SoundPlayer {
    static let systemSoundsPath = "/System/Library/Sounds"

    /// 実機にある .aiff を列挙。取得できなければ標準14音にフォールバック。
    static func availableSounds() -> [String] {
        let fm = FileManager.default
        if let files = try? fm.contentsOfDirectory(atPath: systemSoundsPath) {
            let names = files
                .filter { $0.hasSuffix(".aiff") }
                .map { String($0.dropLast(5)) }
                .sorted()
            if !names.isEmpty { return names }
        }
        return ["Basso", "Blow", "Bottle", "Frog", "Funk", "Glass", "Hero",
                "Morse", "Ping", "Pop", "Purr", "Sosumi", "Submarine", "Tink"]
    }

    static func url(for name: String) -> URL? {
        let u = URL(fileURLWithPath: systemSoundsPath).appendingPathComponent("\(name).aiff")
        return FileManager.default.fileExists(atPath: u.path) ? u : nil
    }

    /// volumePercent: 100=標準。100超で増幅（システム音量を超えて大きくできる）。
    static func play(_ name: String, volumePercent: Double = 100) {
        SoundEngine.shared.play(name, volumePercent: volumePercent)
    }
}

/// AVAudioEngine + EQ で再生し、効果音だけ音量を増幅できるようにする。
final class SoundEngine {
    static let shared = SoundEngine()

    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let eq = AVAudioUnitEQ(numberOfBands: 1)

    private init() {
        eq.bands[0].bypass = true          // バンドは使わず globalGain だけで増幅
        engine.attach(player)
        engine.attach(eq)
    }

    func play(_ name: String, volumePercent: Double) {
        guard volumePercent > 0 else { return }
        guard let url = SoundPlayer.url(for: name),
              let file = try? AVAudioFile(forReading: url) else {
            NSSound(named: NSSound.Name(name))?.play()   // フォールバック
            return
        }

        let fmt = file.processingFormat
        engine.stop()
        engine.disconnectNodeInput(engine.mainMixerNode)
        engine.disconnectNodeInput(eq)
        engine.connect(player, to: eq, format: fmt)
        engine.connect(eq, to: engine.mainMixerNode, format: fmt)
        eq.globalGain = gainDB(for: volumePercent)

        do {
            engine.prepare()
            try engine.start()
        } catch {
            NSSound(named: NSSound.Name(name))?.play()
            return
        }
        player.scheduleFile(file, at: nil, completionHandler: nil)
        player.play()
    }

    /// パーセントを dB へ。EQ globalGain の許容範囲(-96...24)にクランプ。
    private func gainDB(for percent: Double) -> Float {
        let db = 20.0 * log10(percent / 100.0)
        return Float(min(max(db, -96.0), 24.0))
    }
}
