import ActivityKit
import Foundation

/* Starting, scheduling and stopping the school day's Live Activity.

   One Live Activity carries one whole day and needs nothing from the app
   once it is up (see ClassActivity). What it does need is to be started, and
   only a running app can do that — so every time the app runs, `refresh`
   puts today's up if it should be showing and books the next school
   morning's with the system, which starts a booked one by itself at its
   time. Opening the app once between school days is enough to keep that
   going; a Shortcuts automation running the Start Classes action each
   morning does away with even that.

   The system keeps a Live Activity in the Dynamic Island for eight hours,
   and on the Lock Screen for four more after that. A day started at 06:00 is
   therefore gone from the island at 14:00 and from the Lock Screen at 18:00,
   and still changes with the bells until then. */
enum ClassActivityManager {
    static let enabledKey = "liveActivity"
    static let startKey = "liveActivityStart"

    /// Whether the day should be put on the Lock Screen at all.
    static var isEnabled: Bool {
        get { UserDefaults.standard.bool(forKey: enabledKey) }
        set { UserDefaults.standard.set(newValue, forKey: enabledKey) }
    }

    /// When in the morning it goes up, in minutes after midnight: 06:00
    /// unless changed.
    static var startMinutes: Int {
        get { UserDefaults.standard.object(forKey: startKey) as? Int ?? 6 * 60 }
        set { UserDefaults.standard.set(newValue, forKey: startKey) }
    }

    /// False when Live Activities are turned off for the app in Settings.
    static var isAllowed: Bool { ActivityAuthorizationInfo().areActivitiesEnabled }

    enum Status: Equatable {
        case off
        case notAllowed
        /// Up now, for the day with this label.
        case showing(String)
        /// Booked to go up at this time.
        case booked(Date)
        /// On, with nothing to show: no school day in sight.
        case idle
    }

    private typealias Day = Activity<ClassActivityAttributes>

    /// The ones still to be seen: up now, or booked.
    private static var live: [Day] {
        Day.activities.filter { $0.activityState == .active || $0.activityState == .pending || $0.activityState == .stale }
    }

    private static func isFor(_ activity: Day, _ date: Date) -> Bool {
        guard let first = activity.attributes.blocks.first else { return false }
        return Timetable.calendar.isDate(first.start, inSameDayAs: date)
    }

    /// When the Live Activity for the school day `date` goes up.
    private static func startTime(on date: Date) -> Date {
        let cal = Timetable.calendar
        return cal.date(byAdding: .minute, value: startMinutes, to: cal.startOfDay(for: date))!
    }

    /// What to take down first, when what is up or booked is out of date.
    enum Reset {
        case nothing
        /// The ones booked and not yet up: the time they go up has changed.
        case bookings
        /// All of it: the profile, and with it the timetable, has changed.
        case everything
    }

    @MainActor private static var queue: Task<Status, Never>?

    /* Put things as they should be at `now`: take down any day that is over,
       put today's up if its time has come (or at once, with `showNow`), and
       book the next one. Safe to call as often as wanted; calls are taken one
       at a time, since two at once could each find nothing up and both put
       the day up.

       A day swiped off the Lock Screen is put back by the next call. The
       system stops reporting a Live Activity once it has been cleared, so
       there is no telling that case from one that never came up — and of
       the two mistakes, bringing back what was cleared is the smaller. */
    @MainActor @discardableResult
    static func refresh(now: Date = .now, showNow: Bool = false, reset: Reset = .nothing) async -> Status {
        let previous = queue
        let task = Task { @MainActor () -> Status in
            _ = await previous?.value
            return await settle(now: now, showNow: showNow, reset: reset)
        }
        queue = task
        return await task.value
    }

    private static func settle(now: Date, showNow: Bool, reset: Reset) async -> Status {
        #if DEBUG
        if isTesting { return .off }
        #endif
        let nextDay = Timetable.nextSchoolDay(after: now)
        for activity in Day.activities {
            guard let last = activity.attributes.blocks.last else { continue }
            let outOfDate = switch reset {
            case .nothing: false
            case .bookings: activity.activityState == .pending
            case .everything: true
            }
            // only today's and the next school day's have any business being there
            let stray = !isFor(activity, now) && !(nextDay.map { isFor(activity, $0) } ?? false)
            if last.end <= now || !isEnabled || outOfDate || stray { await end(activity) }
        }
        guard isEnabled else { return .off }
        guard isAllowed else { return .notAllowed }

        var status = Status.idle
        // today, while there is still some of it left
        if let today = ClassActivityAttributes(day: now, made: now), let last = today.blocks.last, last.end > now {
            let goesUp = startTime(on: now)
            if let existing = live.first(where: { isFor($0, now) }) {
                if existing.activityState == .pending, showNow || goesUp <= now {
                    // booked for later today, and wanted now
                    await end(existing)
                    if (try? start(today)) != nil { status = .showing(today.day) }
                } else {
                    status = existing.activityState == .pending ? .booked(goesUp) : .showing(today.day)
                }
            } else if showNow || goesUp <= now {
                if (try? start(today)) != nil { status = .showing(today.day) }
            } else if (try? book(today, at: goesUp)) != nil {
                status = .booked(goesUp)
            }
        }
        // and the next school day
        if let next = nextDay, let day = ClassActivityAttributes(day: next, made: startTime(on: next)) {
            let goesUp = startTime(on: next)
            let booked = live.contains { isFor($0, next) } || (try? book(day, at: goesUp)) != nil
            if booked, status == .idle { status = .booked(goesUp) }
        }
        return status
    }

    @discardableResult
    static func start(_ day: ClassActivityAttributes) throws -> Activity<ClassActivityAttributes> {
        try Activity.request(attributes: day,
                             content: ActivityContent(state: .init(), staleDate: nil),
                             pushType: nil)
    }

    /* Hand the day to the system to start by itself at `date`. The system
       insists on telling the user when it does; the sound for that is a clip
       of silence, since the time is early and the Lock Screen says it all. */
    @discardableResult
    private static func book(_ day: ClassActivityAttributes, at date: Date) throws -> Activity<ClassActivityAttributes> {
        let first = day.blocks.first
        let body = first.map { "First: \($0.title) at \(Timetable.hhmm($0.start))" } ?? day.day
        return try Activity.request(attributes: day,
                                    content: ActivityContent(state: .init(), staleDate: nil),
                                    pushType: nil,
                                    style: .standard,
                                    alertConfiguration: AlertConfiguration(title: "Today's classes",
                                                                           body: LocalizedStringResource(stringLiteral: body),
                                                                           sound: .named("silence.caf")),
                                    start: date)
    }

    static func endAll() async {
        for activity in Day.activities {
            await end(activity)
        }
    }

    /* Take one down, without waiting on the system for longer than a couple
       of seconds. Asked to end a Live Activity left over from before the
       device was restarted, the system never answered — and with the calls
       taken one at a time, everything behind that one would wait for ever
       too, and no day would go up again until the app was closed. */
    private static func end(_ activity: Activity<ClassActivityAttributes>) async {
        let first = FirstOnly()
        await withCheckedContinuation { (done: CheckedContinuation<Void, Never>) in
            Task {
                await activity.end(nil, dismissalPolicy: .immediate)
                if first.claim() { done.resume() }
            }
            Task {
                try? await Task.sleep(for: .seconds(2))
                if first.claim() { done.resume() }
            }
        }
    }

    /// True the first time it is asked, and never again.
    private final class FirstOnly: @unchecked Sendable {
        private let lock = NSLock()
        private var claimed = false

        func claim() -> Bool {
            lock.withLock {
                defer { claimed = true }
                return !claimed
            }
        }
    }

    #if DEBUG
    /// Set while a LIVE_TEST run is on, so the usual tidying leaves it alone.
    static var isTesting = false

    /// A made-up day of three short blocks, to watch the panels change.
    static func testDay(blockSeconds: TimeInterval) -> ClassActivityAttributes {
        let start = Date.now.addingTimeInterval(blockSeconds)
        let names = [("Econ", "5F HS3", "DP Econ", "Econ", true), ("Break", "", "Break", "Break", false),
                     ("Comp. Sc.", "6F-DP VA Studio", "DP Comp. Sc.", "CS", true)]
        let blocks = names.enumerated().map { index, n in
            ClassActivityAttributes.Block(title: n.0, place: n.1,
                                          start: start.addingTimeInterval(Double(index) * blockSeconds),
                                          end: start.addingTimeInterval(Double(index + 1) * blockSeconds),
                                          isLesson: n.4, tint: n.2, short: n.3)
        }
        return ClassActivityAttributes(day: "Test · Week 0", blocks: blocks, made: .now)
    }

    /// Books the made-up day to start `seconds` from now, to check the system starts it.
    static func bookTestDay(in seconds: TimeInterval) throws {
        var day = testDay(blockSeconds: 25)
        day.blocks = day.blocks.map { block in
            var block = block
            block.start += seconds
            block.end += seconds
            return block
        }
        day.made = Date.now.addingTimeInterval(seconds)
        try book(day, at: Date.now.addingTimeInterval(seconds))
    }
    #endif
}
