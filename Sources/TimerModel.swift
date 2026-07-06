import Foundation
import AppKit
import Observation
import UserNotifications
import ServiceManagement

enum Phase: String {
    case work
    case rest

    var displayName: String { self == .work ? "作業" : "休憩" }
    var icon: String { self == .work ? "🍅" : "☕️" }
    var endTitle: String { self == .work ? "作業終了！" : "休憩終了！" }
    var endBody: String { self == .work ? "休憩を始めましょう ☕️" : "作業を再開しましょう 🍅" }
}

@Observable
final class TimerModel {

    // MARK: - 永続化する設定
    var workMinutes: Int {
        didSet {
            defaults.set(workMinutes, forKey: "workMinutes")
            refreshIfIdle()
        }
    }
    var restMinutes: Int {
        didSet {
            defaults.set(restMinutes, forKey: "restMinutes")
            refreshIfIdle()
        }
    }
    var workEndSound: String {
        didSet { defaults.set(workEndSound, forKey: "workEndSound") }
    }
    var restEndSound: String {
        didSet { defaults.set(restEndSound, forKey: "restEndSound") }
    }

    // MARK: - 実行時の状態
    var phase: Phase = .work
    var remaining: Int = 25 * 60
    var isRunning: Bool = false
    var completedToday: Int = 0

    private let defaults = UserDefaults.standard
    private var timer: Timer?
    private var endDate: Date?

    init() {
        let w = defaults.object(forKey: "workMinutes") as? Int ?? 25
        let r = defaults.object(forKey: "restMinutes") as? Int ?? 5
        workMinutes = w
        restMinutes = r
        workEndSound = defaults.string(forKey: "workEndSound") ?? "Glass"
        restEndSound = defaults.string(forKey: "restEndSound") ?? "Ping"
        remaining = w * 60
        loadTodayCount()
    }

    // MARK: - 派生値
    var currentTotal: Int { (phase == .work ? workMinutes : restMinutes) * 60 }

    var progress: Double {
        guard currentTotal > 0 else { return 0 }
        return 1.0 - Double(remaining) / Double(currentTotal)
    }

    var timeString: String {
        let m = remaining / 60
        let s = remaining % 60
        return String(format: "%02d:%02d", m, s)
    }

    var menuBarTitle: String { "\(phase.icon) \(timeString)" }

    // MARK: - 操作
    func toggle() { isRunning ? pause() : start() }

    func start() {
        if remaining <= 0 { remaining = currentTotal }
        endDate = Date().addingTimeInterval(TimeInterval(remaining))
        isRunning = true
        scheduleTimer()
    }

    func pause() {
        syncRemaining()
        isRunning = false
        timer?.invalidate()
        timer = nil
        endDate = nil
    }

    func skip() { advance(playSound: false) }

    func reset() {
        timer?.invalidate()
        timer = nil
        isRunning = false
        endDate = nil
        phase = .work
        remaining = currentTotal
    }

    // MARK: - 内部処理
    private func scheduleTimer() {
        timer?.invalidate()
        let t = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            self?.tick()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func tick() {
        guard isRunning, let end = endDate else { return }
        let rem = Int(end.timeIntervalSinceNow.rounded())
        remaining = max(0, rem)
        if rem <= 0 { advance(playSound: true) }
    }

    private func syncRemaining() {
        if let end = endDate {
            remaining = max(0, Int(end.timeIntervalSinceNow.rounded()))
        }
    }

    /// 現フェーズを終え、次フェーズ(work↔rest)へ。isRunning中なら自動で継続。
    private func advance(playSound: Bool) {
        timer?.invalidate()
        timer = nil
        let finished = phase

        if playSound {
            SoundPlayer.play(finished == .work ? workEndSound : restEndSound)
            postNotification(for: finished)
        }
        if finished == .work { incrementTodayCount() }

        phase = (finished == .work) ? .rest : .work
        remaining = currentTotal

        if isRunning {
            endDate = Date().addingTimeInterval(TimeInterval(remaining))
            scheduleTimer()
        } else {
            endDate = nil
        }
    }

    /// 停止中に時間設定を変えたら、表示も新しい長さに合わせる。
    private func refreshIfIdle() {
        if !isRunning {
            remaining = currentTotal
            endDate = nil
        }
    }

    // MARK: - 今日の完了数（日付が変わったらリセット）
    private func loadTodayCount() {
        if defaults.string(forKey: "countDay") == Self.dayKey() {
            completedToday = defaults.integer(forKey: "countValue")
        } else {
            completedToday = 0
        }
    }

    private func incrementTodayCount() {
        let today = Self.dayKey()
        if defaults.string(forKey: "countDay") != today {
            completedToday = 0
        }
        completedToday += 1
        defaults.set(completedToday, forKey: "countValue")
        defaults.set(today, forKey: "countDay")
    }

    private static func dayKey() -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }

    // MARK: - 通知バナー（ベストエフォート）
    func requestNotificationPermission() {
        guard Bundle.main.bundleIdentifier != nil else { return }
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func postNotification(for finished: Phase) {
        guard Bundle.main.bundleIdentifier != nil else { return }
        let content = UNMutableNotificationContent()
        content.title = finished.endTitle
        content.body = finished.endBody
        let req = UNNotificationRequest(
            identifier: UUID().uuidString, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(req, withCompletionHandler: nil)
    }

    // MARK: - ログイン時に起動
    var launchAtLogin: Bool {
        get { SMAppService.mainApp.status == .enabled }
        set {
            do {
                if newValue {
                    try SMAppService.mainApp.register()
                } else {
                    try SMAppService.mainApp.unregister()
                }
            } catch {
                NSLog("launchAtLogin error: \(error.localizedDescription)")
            }
        }
    }
}
