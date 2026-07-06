import SwiftUI

struct Preset: Identifiable {
    let id = UUID()
    let label: String
    let work: Int
    let rest: Int
}

struct ContentView: View {
    @Bindable var model: TimerModel

    private let sounds = SoundPlayer.availableSounds()
    private let presets: [Preset] = [
        Preset(label: "25 / 5", work: 25, rest: 5),
        Preset(label: "45 / 5", work: 45, rest: 5),
        Preset(label: "50 / 10", work: 50, rest: 10),
    ]

    var body: some View {
        VStack(spacing: 14) {
            header
            timerDisplay
            controls
            Divider()
            presetSection
            customSection
            Divider()
            soundSection
            volumeSection
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 300)
        .onAppear { model.requestNotificationPermission() }
    }

    private var header: some View {
        Text("\(model.phase.icon) \(model.phase.displayName)中")
            .font(.headline)
            .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var timerDisplay: some View {
        ZStack {
            Circle()
                .stroke(.quaternary, lineWidth: 8)
            Circle()
                .trim(from: 0, to: model.progress)
                .stroke(model.phase == .work ? Color.red : Color.green,
                        style: StrokeStyle(lineWidth: 8, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.2), value: model.progress)
            Text(model.timeString)
                .font(.system(size: 44, weight: .semibold, design: .rounded))
                .monospacedDigit()
        }
        .frame(width: 160, height: 160)
        .padding(.vertical, 4)
    }

    private var controls: some View {
        HStack(spacing: 12) {
            Button(action: model.toggle) {
                Label(model.isRunning ? "一時停止" : "開始",
                      systemImage: model.isRunning ? "pause.fill" : "play.fill")
                    .frame(maxWidth: .infinity)
            }
            .keyboardShortcut(.space, modifiers: [])

            Button(action: model.skip) {
                Image(systemName: "forward.fill")
            }
            .help("次のフェーズへスキップ")

            Button(action: model.reset) {
                Image(systemName: "arrow.counterclockwise")
            }
            .help("リセット")
        }
        .buttonStyle(.bordered)
        .controlSize(.large)
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("プリセット").font(.caption).foregroundStyle(.secondary)
            HStack(spacing: 6) {
                ForEach(presets) { p in
                    Button(p.label) {
                        model.workMinutes = p.work
                        model.restMinutes = p.rest
                    }
                    .buttonStyle(.bordered)
                    .font(.caption)
                    .tint(isSelected(p) ? .accentColor : nil)
                }
            }
        }
    }

    private func isSelected(_ p: Preset) -> Bool {
        model.workMinutes == p.work && model.restMinutes == p.rest
    }

    private var customSection: some View {
        VStack(spacing: 6) {
            Stepper("作業  \(model.workMinutes) 分", value: $model.workMinutes, in: 1...180)
            Stepper("休憩  \(model.restMinutes) 分", value: $model.restMinutes, in: 1...180)
        }
        .font(.callout)
    }

    private var soundSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            soundRow(title: "作業終了音", selection: $model.workEndSound)
            soundRow(title: "休憩終了音", selection: $model.restEndSound)
        }
    }

    private func soundRow(title: String, selection: Binding<String>) -> some View {
        HStack {
            Text(title).font(.caption).frame(width: 68, alignment: .leading)
            Picker("", selection: selection) {
                ForEach(sounds, id: \.self) { Text($0).tag($0) }
            }
            .labelsHidden()
            Button {
                SoundPlayer.play(selection.wrappedValue, volumePercent: model.soundVolume)
            } label: {
                Image(systemName: "play.circle")
            }
            .buttonStyle(.borderless)
            .help("試聴")
        }
    }

    private var volumeSection: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text("効果音の音量").font(.caption).foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(model.soundVolume))%")
                    .font(.caption).monospacedDigit().foregroundStyle(.secondary)
            }
            HStack(spacing: 8) {
                Image(systemName: "speaker.fill")
                    .font(.caption2).foregroundStyle(.secondary)
                Slider(value: $model.soundVolume, in: 0...200, step: 10)
                Image(systemName: "speaker.wave.3.fill")
                    .font(.caption2).foregroundStyle(.secondary)
            }
            Text("100% ＝ 標準。上げると増幅（上げすぎると音割れ）")
                .font(.caption2).foregroundStyle(.tertiary)
        }
    }

    private var footer: some View {
        HStack {
            Toggle("ログイン時に起動", isOn: $model.launchAtLogin)
                .toggleStyle(.checkbox)
                .font(.caption)
            Spacer()
            Button("終了") { NSApplication.shared.terminate(nil) }
                .font(.caption)
        }
    }
}
