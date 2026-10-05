import SwiftUI
import WidgetKit

@main
struct TimetableApp: App {
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        // the widgets lay out two days at a time; opening the app is a good
        // moment to have them lay out afresh
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { WidgetCenter.shared.reloadAllTimelines() }
        }
    }
}
