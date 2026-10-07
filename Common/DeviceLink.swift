import Foundation
import WatchConnectivity

/* The line between the phone and the watch.

   The watch has no setup of its own: whose timetable it is, is decided on
   the phone, and an app group does not reach from one device to the other.
   So the phone hands the profile across here, and whether reminders are
   wanted; and the watch says back how far ahead it has reminders laid down,
   which is what lets the phone leave them to it (see ClassReminders).

   Both ways it is the "application context": the latest word only, kept by
   the system and delivered when the other side is next about. Nothing is
   lost if the other device is out of reach when it is sent. */
final class DeviceLink: NSObject, WCSessionDelegate {
    static let shared = DeviceLink()
    /// Something has come from the other device.
    var received: (() -> Void)?

    func start() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    private var session: WCSession? {
        WCSession.isSupported() && WCSession.default.activationState == .activated ? WCSession.default : nil
    }

    func session(_ session: WCSession, activationDidCompleteWith state: WCSessionActivationState, error: Error?) {
        #if os(iOS)
        send()
        #else
        take(session.receivedApplicationContext)
        #endif
        received?()
    }

    func session(_ session: WCSession, didReceiveApplicationContext context: [String: Any]) {
        #if os(watchOS)
        take(context)
        #endif
        received?()
    }

    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) { session.activate() }

    /// Hand the watch the profile and whether reminders are wanted.
    func send() {
        guard let session, session.isPaired, session.isWatchAppInstalled,
              let profile = Timetable.profile, let data = try? JSONEncoder().encode(profile) else { return }
        try? session.updateApplicationContext(["profile": data, "reminders": ClassReminders.isOn])
    }

    /// Whether the watch has said it has reminders laid down from here on.
    var watchHasReminders: Bool {
        guard let session, session.isPaired, session.isWatchAppInstalled,
              let until = session.receivedApplicationContext["remindersUntil"] as? Date else { return false }
        return until > .now
    }
    #else
    private func take(_ context: [String: Any]) {
        if let on = context["reminders"] as? Bool { ClassReminders.isOn = on }
        if let data = context["profile"] as? Data, let profile = try? JSONDecoder().decode(Profile.self, from: data),
           profile != Timetable.profile {
            profile.save()
            Timetable.profile = profile
        }
    }

    /// Tell the phone how far ahead reminders are laid down here; nil for none.
    func report(remindersUntil until: Date?) {
        try? session?.updateApplicationContext(["remindersUntil": until ?? Date.distantPast])
    }
    #endif
}
