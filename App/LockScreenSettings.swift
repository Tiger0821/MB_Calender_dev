import SwiftUI

/* The switch for the Live Activity: the day on the Lock Screen and in the
   Dynamic Island, changing with the bells. It says what state things are in,
   takes the time it should go up in the morning, and offers it at once. */
struct LockScreenSettings: View {
    /// The minute it is: the status is looked at again each time it changes,
    /// so "goes up at 6:00" doesn't outstay 6:00.
    let now: Date
    @AppStorage(ClassActivityManager.enabledKey) private var enabled = false
    @AppStorage(ClassActivityManager.startKey) private var startMinutes = 6 * 60
    @State private var status = ClassActivityManager.Status.off
    @Environment(\.scenePhase) private var scenePhase

    private var startTime: Binding<Date> {
        Binding {
            let cal = Timetable.calendar
            return cal.date(byAdding: .minute, value: startMinutes, to: cal.startOfDay(for: .now)) ?? .now
        } set: { date in
            let c = Timetable.calendar.dateComponents([.hour, .minute], from: date)
            startMinutes = (c.hour ?? 6) * 60 + (c.minute ?? 0)
        }
    }

    var body: some View {
        Toggle(isOn: $enabled) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Show the day's classes")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.primary)
                Text(statusText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .task(id: now) { status = await ClassActivityManager.refresh() }
        .onChange(of: enabled) {
            Task { status = await ClassActivityManager.refresh() }
        }
        .onChange(of: startMinutes) {
            // what is booked was booked for the old time
            Task { status = await ClassActivityManager.refresh(reset: .bookings) }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { status = await ClassActivityManager.refresh() } }
        }
        if enabled {
            Divider()
            DatePicker("Goes up at", selection: startTime, displayedComponents: .hourAndMinute)
                .font(.body)
                .foregroundStyle(.primary)
            if case .showing = status {
            } else if status != .notAllowed {
                Button("Show now") {
                    Task { status = await ClassActivityManager.refresh(showNow: true) }
                }
                .font(.body.weight(.semibold))
                .foregroundStyle(.tint)
            }
            Divider()
            Text("It follows the bells by itself: the class you're in, the time left, and what's next. iOS keeps it in the Dynamic Island for 8 hours and on the Lock Screen for 12.")
            Text("Each time you open this app the next school morning is set up. To have it happen without opening the app, add a Shortcuts automation that runs Start Classes each morning.")
            Text("Swiping it off the Lock Screen clears it until the app is next opened.")
        }
    }

    private var statusText: String {
        switch status {
        case .off: "Off"
        case .notAllowed: "Live Activities are turned off for Timetable in Settings."
        case .showing(let day): "On the Lock Screen now · \(day)"
        case .booked(let date): "Goes up \(date.formatted(.dateTime.weekday(.wide).hour().minute()))"
        case .idle: "On · no school day coming up"
        }
    }
}
