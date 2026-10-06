import AppIntents

/* The Shortcuts action. An app can only start a Live Activity while it is on
   screen — except from an action like this one, which the system lets run in
   the background. So a Shortcuts automation set for a time each morning
   (Automation › Time of Day › Start Classes, Run Immediately) puts the day up
   without the app having been opened at all. */
struct StartClassesIntent: LiveActivityIntent {
    static let title: LocalizedStringResource = "Start Classes"
    static let description = IntentDescription("Puts today's classes on the Lock Screen and in the Dynamic Island, and books the next school morning.")

    func perform() async throws -> some IntentResult {
        ClassActivityManager.isEnabled = true
        await ClassActivityManager.refresh(showNow: true)
        return .result()
    }
}

struct TimetableShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: StartClassesIntent(),
                    phrases: ["Start classes in \(.applicationName)", "Show my classes in \(.applicationName)"],
                    shortTitle: "Start Classes",
                    systemImageName: "calendar.day.timeline.left")
    }
}
