import Foundation
import UserNotifications

/* A nudge before each class: one a quarter of an hour ahead and one five
   minutes ahead, saying what it is and where.

   They are local notifications, laid down ahead of time for the school days
   to come, so nothing has to be running when one is due. The system keeps
   no more than 64 for an app, which is some four school days of them; they
   are laid down afresh each time the app is opened, and whenever the classes
   change.

   Both the phone and the watch can do this, and only one should, or every
   class would be announced twice. The watch is the better of the two — what
   it posts taps the wrist whatever the phone is doing, where a phone's is
   only passed on to the watch while the phone is locked — so once the watch
   has said it has them (see DeviceLink) the phone stands down. */
enum ClassReminders {
    /// Minutes before a class starts.
    static let leads = [15, 5]
    /// The system's limit is 64; a few are left spare.
    private static let most = 60

    private static let key = "classReminders"
    static var isOn: Bool {
        get { UserDefaults.standard.object(forKey: key) as? Bool ?? true }
        set { UserDefaults.standard.set(newValue, forKey: key) }
    }

    struct Reminder {
        let fire: Date
        let title: String
        let body: String
    }

    /* Every reminder from `now` on, soonest first. A double period is one
       class, announced once: its second half starts the moment the first
       ends, in the same room. */
    static func upcoming(after now: Date, limit: Int = most) -> [Reminder] {
        let cal = Timetable.calendar
        var out: [Reminder] = []
        var day = cal.startOfDay(for: now)
        for _ in 0..<21 where out.count < limit {
            let segments = Timetable.day(of: day)
            for (index, item) in segments.enumerated() where item.segment.isLesson {
                if index > 0, segments[index - 1].segment.isLesson,
                   segments[index - 1].segment.title == item.segment.title { continue }
                for lead in leads {
                    let fire = item.start.addingTimeInterval(TimeInterval(-lead * 60))
                    guard fire > now else { continue }
                    let place = item.segment.place
                    out.append(Reminder(fire: fire,
                                        title: "\(item.segment.shortTitle) in \(lead) min",
                                        body: (place.isEmpty ? "" : "\(place) · ") + "starts \(Timetable.hhmm(item.start))"))
                }
            }
            day = cal.date(byAdding: .day, value: 1, to: day)!
        }
        return Array(out.sorted { $0.fire < $1.fire }.prefix(limit))
    }

    /* Clear what was laid down and lay it down again. `standDown` is the
       phone leaving it to the watch. Returns the moment of the last one laid
       down, which is how long this device has them covered for. */
    @discardableResult
    static func schedule(standDown: Bool = false) async -> Date? {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        guard isOn, !standDown, Timetable.profile != nil else { return nil }
        // asks for leave the first time; refused, there is nothing to lay down
        guard (try? await center.requestAuthorization(options: [.alert, .sound])) == true else { return nil }
        let now = Date.now
        let reminders = upcoming(after: now)
        for reminder in reminders {
            let content = UNMutableNotificationContent()
            content.title = reminder.title
            content.body = reminder.body
            content.sound = .default
            content.interruptionLevel = .timeSensitive
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: max(1, reminder.fire.timeIntervalSince(now)),
                                                            repeats: false)
            let id = "class-\(Int(reminder.fire.timeIntervalSince1970))"
            try? await center.add(UNNotificationRequest(identifier: id, content: content, trigger: trigger))
        }
        return reminders.last?.fire
    }
}

/// Shows a reminder even while the app is the one on screen, where the
/// system would otherwise keep it back.
final class ReminderPresenter: NSObject, UNUserNotificationCenterDelegate {
    static let shared = ReminderPresenter()
    /// Called as one is shown: the watch taps the wrist itself here, since
    /// with the app in front the system does not.
    var shown: (() -> Void)?

    func install() {
        UNUserNotificationCenter.current().delegate = self
    }

    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        shown?()
        return [.banner, .list, .sound]
    }
}
