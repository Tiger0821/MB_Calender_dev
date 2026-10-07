import SwiftUI
import WatchKit
import WidgetKit

/* Timetable on the Apple Watch: the day's classes over the sky outside, a
   widget for the Smart Stack that says what is on and what is next, and the
   reminders before each class.

   It has no setup of its own. The phone hands it the profile (DeviceLink),
   and until it has, there is nothing to show but a line saying so. */
@main
struct TimetableWatchApp: App {
    @Environment(\.scenePhase) private var scenePhase
    @State private var profile = Timetable.profile

    init() {
        ReminderPresenter.shared.install()
        // with the app in front the system shows a reminder silently, so the
        // tap on the wrist is given here
        ReminderPresenter.shared.shown = { WKInterfaceDevice.current().play(.notification) }
        DeviceLink.shared.start()
    }

    var body: some Scene {
        WindowGroup {
            WatchDayView(profile: profile)
                .task {
                    DeviceLink.shared.received = {
                        Task { @MainActor in
                            profile = Timetable.profile
                            await Self.settle()
                        }
                    }
                    await Self.settle()
                }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active {
                profile = Timetable.profile
                Task { await Self.settle() }
            }
        }
        // the reminders are laid down some four days ahead; this tops them up
        // on days the app is not opened
        .backgroundTask(.appRefresh("reminders")) {
            await Self.settle()
        }
    }

    /// Lay the reminders down again, tell the phone how far they run, have
    /// the widget lay out afresh, and ask to be woken tomorrow to do it again.
    static func settle() async {
        let until = await ClassReminders.schedule()
        DeviceLink.shared.report(remindersUntil: until)
        WidgetCenter.shared.reloadAllTimelines()
        WKApplication.shared().scheduleBackgroundRefresh(withPreferredDate: .now.addingTimeInterval(12 * 3600),
                                                         userInfo: nil) { _ in }
    }
}
