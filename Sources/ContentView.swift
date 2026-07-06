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
        Preset(label: "50 / 15", work: 50, rest: 15),
        Preset(label: "15 / 3", work: 15, rest: 3),
        Preset(label: "12 / 3", work: 12, rest: 3),
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
            Divider()
            footer
        }
        .padding(16)
        .frame(width: 300)
        .onAppear { model.requestNotificationPermission() }
    }

    private var header: some View {
        HStack {
            Text("\(model.phase.icon) \(model.phase.displayName)中")
                .font(.headline)
            Spacer()
            Text("今日: \(model.completedToday) 🍅")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
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
                SoundPlayer.play(selection.wrappedValue)
            } label: {
                Image(systemName: "play.circle")
            }
            .buttonStyle(.borderless)
            .help("試聴")
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
