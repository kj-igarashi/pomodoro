import SwiftUI

@main
struct PomodoroApp: App {
    @State private var model = TimerModel()

    var body: some Scene {
        MenuBarExtra {
            ContentView(model: model)
        } label: {
            Text(model.menuBarTitle)
        }
        .menuBarExtraStyle(.window)
    }
}
