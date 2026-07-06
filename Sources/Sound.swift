import AppKit

/// Mac備え付けの音（/System/Library/Sounds）だけを扱う。
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

    static func play(_ name: String) {
        NSSound(named: NSSound.Name(name))?.play()
    }
}
