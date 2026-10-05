import Foundation

/* The TIMETABLE section of the userscript, in Swift. The rows in
   TimetableData are the whole of each form's fortnight; everything here cuts
   one form's down to the classes one person takes and lays each day out the
   way the dock does — parallel option blocks under one time, the holes
   between them named Free, Break or Lunch, and any period before 16:05 with
   nothing of yours in it shown as IB Core. Where the userscript has its
   classes written into it (TT_MINE, TT_CLUBS), here they come from the
   Profile that setup fills in, so one build serves a whole year group. */

/// One taught slot: a row of TimetableData that survived the cut.
struct Lesson: Hashable, Sendable {
    var subject: String
    /// 0-4 are Week 1, 5-9 Week 2.
    let day: Int
    /// Minutes after midnight.
    let start: Int
    let end: Int
    var staff: [String]
    var rooms: [String]

    var name: String { Timetable.displayName(subject) }
    var room: String { rooms.count == 1 ? rooms[0] : rooms.isEmpty ? "" : "\(rooms.count) rooms" }
}

/// A stretch of one day: a class (or several running in parallel), or the gap
/// between two of them.
struct Segment: Hashable, Sendable {
    enum Kind: Hashable, Sendable {
        case lessons([Lesson])
        case gap(String)
    }

    let start: Int
    let end: Int
    let kind: Kind

    var isLesson: Bool {
        if case .lessons = kind { return true }
        return false
    }

    var lessons: [Lesson] {
        if case .lessons(let items) = kind { return items }
        return []
    }

    var title: String {
        switch kind {
        case .lessons(let items): return items.map(\.name).joined(separator: " or ")
        case .gap(let label): return label
        }
    }

    var place: String {
        lessons.map(\.room).filter { !$0.isEmpty }.joined(separator: " · ")
    }

    var staff: String {
        lessons.flatMap(\.staff).joined(separator: ", ")
    }

    var minutes: Int { end - start }
}

/// A segment pinned to a real date.
struct TimedSegment: Hashable, Sendable, Identifiable {
    let segment: Segment
    let cycleDay: Int
    let start: Date
    let end: Date

    var id: Date { start }
    var interval: ClosedRange<Date> { start...end }

    func progress(at date: Date) -> Double {
        min(1, max(0, date.timeIntervalSince(start) / end.timeIntervalSince(start)))
    }

    func contains(_ date: Date) -> Bool { start <= date && date < end }
}

/// What a widget shows at one moment.
struct Snapshot: Sendable {
    let date: Date
    /// The block running now — a class, or Free / Break / Lunch. Nil before
    /// school, after it, and at weekends.
    let current: TimedSegment?
    /// Classes still to come, soonest first: the rest of today, or once today
    /// is over, the whole of the next school day.
    let upcoming: [TimedSegment]
    /// The whole day being shown: today until its last block ends, then the
    /// next school day.
    let day: [TimedSegment]
    /// The date `day` falls on.
    let dayDate: Date

    var isToday: Bool { Timetable.calendar.isDate(dayDate, inSameDayAs: date) }

    /// The block to lead with: the one running, or failing that the next.
    var focus: TimedSegment? { current ?? upcoming.first }

    /// "Today", "Tomorrow", or the weekday the shown day falls on.
    var dayLabel: String {
        let cal = Timetable.calendar
        if cal.isDate(dayDate, inSameDayAs: date) { return "Today" }
        if let tomorrow = cal.date(byAdding: .day, value: 1, to: date), cal.isDate(dayDate, inSameDayAs: tomorrow) {
            return "Tomorrow"
        }
        return dayDate.formatted(.dateTime.weekday(.wide))
    }
}

/* What a form is offered, sorted for setup to ask about. Two classes clash
   when they are on at the same time on some day, and nobody takes both of a
   pair that clash — which is all it takes to sort them: a class that clashes
   with nothing is everyone's, and the rest fall into sets to choose within. */
struct Catalog {
    struct Choice: Identifiable, Hashable {
        /// The name the timetable gives it.
        let subject: String
        let staff: String
        /// The other classes that are on while this one is.
        let clashes: Set<String>

        var id: String { subject }
        /// "DP Chi A-2" is "Chi A-2". The TOK groups keep their numbers
        /// here, since setup is where one is picked over the other.
        var name: String {
            let spelled = Timetable.spelled(subject)
            return spelled.hasPrefix("DP ") ? String(spelled.dropFirst(3)) : spelled
        }
    }

    /// Guidance and the clubs: on everyone's timetable, so never asked about.
    let everyone: [String]
    /// The sets to choose within, in the order they first come up in the week.
    let sets: [[Choice]]
    /// SL revision classes, under the class each one is for.
    let revision: [String: [Choice]]

    /// Every class that can be picked.
    var choices: [Choice] { sets.flatMap { $0 } + revision.values.flatMap { $0 } }
}

enum Timetable {
    // MARK: - Whose timetable

    private struct State {
        var profile: Profile?
        var layout: (lessons: [Lesson], lines: [[Segment]])?
    }

    private static let lock = NSLock()
    private static var state = State(profile: Profile.load())

    /// Whose timetable is laid out: nil until setup has been done. Setting
    /// it lays the fortnight out afresh.
    static var profile: Profile? {
        get { lock.withLock { state.profile } }
        set { lock.withLock { if newValue != state.profile { state = State(profile: newValue) } } }
    }

    /// Read the saved profile again. The widgets do this before laying out a
    /// timeline, since the app may have changed it since they last looked.
    static func reload() {
        profile = Profile.load()
    }

    /// The form's own page on the published Prime Timetable (TT_SOURCE).
    static var source: URL {
        let form = TimetableData.forms.first { $0.name == profile?.form } ?? TimetableData.forms[0]
        let id = TimetableData.publication
        return URL(string: "https://primetimetable.com/publish/?id=\(id)&rp=1&inc=1&time=6#id=\(id)&view=1&classId=\(form.id)")!
    }

    static let core = "IB Core"
    static let schoolEnd = minutes("16:05")
    /// The standard bells, for an hour nobody in the form is timetabled in.
    static let bells = ["08:35-09:25", "09:25-10:10", "10:20-11:05", "11:05-11:50",
                        "12:50-13:40", "13:40-14:25", "14:35-15:20", "15:20-16:05"]
    static let lunch = (start: 11 * 60 + 50, end: 12 * 60 + 50)

    /// The grid carries no dates. Week 2 is pinned to the week of Mon 7 Sep
    /// 2026 and the rest alternate (TT_ANCHOR); if the cycle ever reads a week
    /// out, this is the only line to change.
    static let anchor = DateComponents(year: 2026, month: 9, day: 7)

    static let dayNames = ["Mon", "Tue", "Wed", "Thu", "Fri"]
    /// The two halves of the fortnight, marked as the dock marks them.
    static let weekMarks = ["\u{0661}", "\u{0662}"]

    static var calendar: Calendar {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = .current
        cal.locale = .current
        return cal
    }

    static func minutes<S: StringProtocol>(_ hhmm: S) -> Int {
        let parts = hhmm.split(separator: ":")
        return Int(parts[0])! * 60 + Int(parts[1])!
    }

    static func hhmm(_ minutes: Int) -> String {
        String(format: "%02d:%02d", minutes / 60, minutes % 60)
    }

    /// The time of day to the second, as "12:22:45".
    static func clock(_ date: Date) -> String {
        let c = calendar.dateComponents([.hour, .minute, .second], from: date)
        return String(format: "%02d:%02d:%02d", c.hour ?? 0, c.minute ?? 0, c.second ?? 0)
    }

    /// The timetable has "DP ESS SL Rrevision"; it is shown spelled right.
    static func spelled(_ subject: String) -> String {
        subject.replacingOccurrences(of: "Rrevision", with: "Revision")
    }

    /// The DP prefix comes off, and TOK loses its group number; every other
    /// trailing "-N" stays, so Eng B-2 is still Eng B-2 (ttName). The one
    /// departure from the userscript: the timetable's "G: Agency [EE, CAS, CC]"
    /// block is shown as Guidance, here and in every widget.
    static func displayName(_ subject: String) -> String {
        if subject.hasPrefix("G: Agency") { return "Guidance" }
        var s = spelled(subject)
        if s.hasPrefix("DP ") { s = String(s.dropFirst(3)).trimmingCharacters(in: .whitespaces) }
        if s.hasPrefix("TOK-"), s.dropFirst(4).allSatisfy(\.isNumber) { s = "TOK" }
        return s
    }

    // MARK: - The fortnight

    static var lessons: [Lesson] { layout().lessons }

    /// Each of the ten days laid out, gaps included.
    static var lines: [[Segment]] { layout().lines }

    /// Laid out once for each profile and kept until it changes.
    private static func layout() -> (lessons: [Lesson], lines: [[Segment]]) {
        lock.withLock {
            if let layout = state.layout { return layout }
            let lessons = build(for: state.profile)
            let layout = (lessons: lessons, lines: (0..<10).map { line($0, of: lessons) })
            state.layout = layout
            return layout
        }
    }

    /// Every lesson a form is offered, before anything is picked from it.
    static func offered(to form: String) -> [Lesson] {
        (TimetableData.rows[form] ?? "").split(separator: "\n").map(parse)
    }

    static func catalog(for form: String) -> Catalog {
        catalogs[form] ?? Catalog(everyone: [], sets: [], revision: [:])
    }

    private static let catalogs = Dictionary(uniqueKeysWithValues: TimetableData.forms.map { ($0.name, sort(offered(to: $0.name))) })

    private static func sort(_ lessons: [Lesson]) -> Catalog {
        let slots = Dictionary(grouping: lessons, by: \.subject)
        func clash(_ a: String, _ b: String) -> Bool {
            slots[a]!.contains { x in slots[b]!.contains { y in x.day == y.day && x.start < y.end && y.start < x.end } }
        }
        func first(_ subject: String) -> (Int, Int) {
            slots[subject]!.map { ($0.day, $0.start) }.min { $0 < $1 }!
        }
        func choice(_ subject: String, against others: [String]) -> Catalog.Choice {
            Catalog.Choice(subject: subject, staff: slots[subject]![0].staff.joined(separator: ", "),
                           clashes: Set(others.filter { $0 != subject && clash(subject, $0) }))
        }

        // revision classes are extras; they are asked about after the class they are for
        let revision = slots.keys.filter { $0.localizedCaseInsensitiveContains("evision") }.sorted()
        let main = slots.keys.filter { !revision.contains($0) }.sorted { first($0) < first($1) }
        let choices = main.map { choice($0, against: main) }

        var sets: [[Catalog.Choice]] = []
        var placed: Set<String> = []
        for start in choices where !start.clashes.isEmpty && !placed.contains(start.subject) {
            // everything reachable from one class through clashes is one set
            var members: Set<String> = []
            var frontier = [start.subject]
            while let next = frontier.popLast() {
                guard members.insert(next).inserted else { continue }
                frontier += choices.first { $0.subject == next }!.clashes.subtracting(members)
            }
            placed.formUnion(members)
            sets.append(choices.filter { members.contains($0.subject) }.sorted { $0.subject < $1.subject })
        }

        var under: [String: [Catalog.Choice]] = [:]
        for extra in revision {
            // "DP Chi A-2 SL Revision" is for "DP Chi A-2": the longest class name it starts with
            guard let parent = main.filter({ extra.hasPrefix($0) }).max(by: { $0.count < $1.count }) else { continue }
            under[parent, default: []].append(choice(extra, against: []))
        }
        return Catalog(everyone: choices.filter { $0.clashes.isEmpty }.map(\.subject), sets: sets, revision: under)
    }

    private static func parse(_ row: Substring) -> Lesson {
        let f = row.split(separator: "~", omittingEmptySubsequences: false).map(String.init)
        func list(_ i: Int) -> [String] {
            i < f.count ? f[i].split(separator: ";").map(String.init) : []
        }
        return Lesson(subject: f[0], day: Int(f[1])!, start: minutes(f[2]), end: minutes(f[3]),
                      staff: list(4), rooms: list(5))
    }

    /// One person's lessons: the classes they picked and everyone's, with
    /// their clubs named. Nothing until there is a profile.
    private static func build(for profile: Profile?) -> [Lesson] {
        guard let profile else { return [] }
        let rows = offered(to: profile.form)
        let mine = profile.subjects.union(catalog(for: profile.form).everyone)

        var taught = rows.filter { mine.contains($0.subject) }
        for i in taught.indices {
            let week = taught[i].day < 5 ? 0 : 1
            if let club = profile.clubs.first(where: { $0.subject == taught[i].subject && ($0.week == nil || $0.week == week) }) {
                taught[i].subject = club.name
                taught[i].staff = club.staff.isEmpty ? [] : [club.staff]
                taught[i].rooms = club.room.isEmpty ? [] : [club.room]
            } else if taught[i].staff.count > 3 {
                // a slot shared by all the clubs lists every one's teacher and room, which says nothing about yours
                taught[i].staff = []
                taught[i].rooms = []
            }
        }

        /* Any period before 16:05 with none of your classes in it is IB Core.
           The periods are the ones the whole form is timetabled in that day,
           so the rows keep to the real bells and the breaks stay breaks. */
        var periods = rows.map { (day: $0.day, start: $0.start, end: $0.end) }
        for d in 0..<10 {
            for bell in bells {
                let p = bell.split(separator: "-")
                periods.append((day: d, start: minutes(p[0]), end: minutes(p[1])))
            }
        }
        for d in 0..<10 {
            let day = taught.filter { $0.day == d }
            guard let from = day.map(\.start).min() else { continue }
            var taken = day.map { (start: $0.start, end: $0.end) }
            let open = periods
                .filter { $0.day == d && $0.start >= from && $0.end <= schoolEnd }
                .sorted { ($0.start, $0.end) < ($1.start, $1.end) }
            for p in open where !taken.contains(where: { $0.start < p.end && p.start < $0.end }) {
                taught.append(Lesson(subject: core, day: d, start: p.start, end: p.end, staff: [], rooms: []))
                taken.append((start: p.start, end: p.end))
            }
        }
        return taught
    }

    /// One cycle day, in order: parallel option blocks share a segment, and
    /// the stretches between classes become segments of their own (ttLine).
    private static func line(_ day: Int, of lessons: [Lesson]) -> [Segment] {
        let list = lessons.filter { $0.day == day }.sorted {
            $0.start != $1.start ? $0.start < $1.start : $0.subject.localizedCompare($1.subject) == .orderedAscending
        }
        var slots: [(start: Int, end: Int, items: [Lesson])] = []
        for lesson in list {
            if let last = slots.last, last.start == lesson.start, last.end == lesson.end {
                slots[slots.count - 1].items.append(lesson)
            } else {
                slots.append((lesson.start, lesson.end, [lesson]))
            }
        }

        var out: [Segment] = []
        var prev: Int?
        for slot in slots {
            if let prev, slot.start > prev { out += gaps(from: prev, to: slot.start) }
            prev = slot.end
            out.append(Segment(start: slot.start, end: slot.end, kind: .lessons(slot.items)))
        }
        return out
    }

    /// One "Free" row would swallow the lunch hour whole, so any gap crossing
    /// it is split (ttGaps).
    private static func gaps(from: Int, to: Int) -> [Segment] {
        var parts: [(start: Int, end: Int, label: String?)] = []
        let ls = max(from, lunch.start), le = min(to, lunch.end)
        if ls < le {
            if from < ls { parts.append((from, ls, nil)) }
            parts.append((ls, le, "Lunch"))
            if le < to { parts.append((le, to, nil)) }
        } else {
            parts.append((from, to, nil))
        }
        return parts.filter { $0.end > $0.start }.map {
            Segment(start: $0.start, end: $0.end, kind: .gap($0.label ?? ($0.end - $0.start <= 15 ? "Break" : "Free")))
        }
    }

    // MARK: - Dates

    static func monday(of date: Date) -> Date {
        let cal = calendar
        let day = cal.startOfDay(for: date)
        let back = (cal.component(.weekday, from: day) + 5) % 7
        return cal.date(byAdding: .day, value: -back, to: day)!
    }

    /// 0 for Week 1, 1 for Week 2.
    static func week(of date: Date) -> Int {
        let cal = calendar
        let pinned = monday(of: cal.date(from: anchor)!)
        let days = cal.dateComponents([.day], from: pinned, to: monday(of: date)).day ?? 0
        let weeks = Int((Double(days) / 7).rounded())
        return (weeks % 2 + 2) % 2 == 0 ? 1 : 0
    }

    /// Monday-Friday as 0-4; nil at weekends.
    static func weekday(of date: Date) -> Int? {
        let w = calendar.component(.weekday, from: date)
        return (2...6).contains(w) ? w - 2 : nil
    }

    /// 0-9, or nil at weekends.
    static func cycleDay(of date: Date) -> Int? {
        weekday(of: date).map { week(of: date) * 5 + $0 }
    }

    static func day(of date: Date) -> [TimedSegment] {
        guard let d = cycleDay(of: date) else { return [] }
        let cal = calendar
        let midnight = cal.startOfDay(for: date)
        return lines[d].map {
            TimedSegment(segment: $0, cycleDay: d,
                         start: cal.date(byAdding: .minute, value: $0.start, to: midnight)!,
                         end: cal.date(byAdding: .minute, value: $0.end, to: midnight)!)
        }
    }

    /// The first day after `date` with any classes on it.
    static func nextSchoolDay(after date: Date) -> Date? {
        let cal = calendar
        let today = cal.startOfDay(for: date)
        for offset in 1...14 {
            let d = cal.date(byAdding: .day, value: offset, to: today)!
            if !day(of: d).isEmpty { return d }
        }
        return nil
    }

    static func snapshot(at now: Date) -> Snapshot {
        let today = day(of: now)
        if let last = today.last, now < last.end {
            let current = today.first { $0.contains(now) }
            let from = current?.end ?? now
            return Snapshot(date: now, current: current,
                            upcoming: today.filter { $0.start >= from && $0.segment.isLesson },
                            day: today, dayDate: now)
        }
        if let next = nextSchoolDay(after: now) {
            let day = day(of: next)
            return Snapshot(date: now, current: nil, upcoming: day.filter(\.segment.isLesson),
                            day: day, dayDate: next)
        }
        return Snapshot(date: now, current: nil, upcoming: [], day: [], dayDate: now)
    }

    /// Every moment from `now` on at which what a widget shows changes — each
    /// bell, and each midnight so "Tomorrow" becomes "Today" — through the end
    /// of the next two school days.
    static func changes(after now: Date) -> [Date] {
        let cal = calendar
        var dates: Set<Date> = []
        var cursor = cal.startOfDay(for: now)
        var schoolDays = 0
        for _ in 0..<21 {
            dates.insert(cursor)
            let segments = day(of: cursor)
            for s in segments {
                dates.insert(s.start)
                dates.insert(s.end)
            }
            if let last = segments.last, last.end > now {
                schoolDays += 1
                if schoolDays == 2 { break }
            }
            cursor = cal.date(byAdding: .day, value: 1, to: cursor)!
        }
        return dates.filter { $0 > now }.sorted()
    }
}
