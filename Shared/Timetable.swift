import Foundation

/* The TIMETABLE section of the userscript, in Swift. The rows in
   TimetableData are the whole of 11B's fortnight; everything here cuts them
   down to the classes actually taken and lays each day out the way the dock
   does — parallel option blocks under one time, the holes between them named
   Free, Break or Lunch, and any period before 16:05 with nothing of yours in
   it shown as IB Core. The constants mirror TT_MINE, TT_SKIP, TT_CLUBS and
   TT_ANCHOR there, so a change to one belongs in the other. */

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

enum Timetable {
    /// The published Prime Timetable the rows were read from (TT_SOURCE).
    static let source = URL(string: "https://primetimetable.com/publish/?id=3d9e5ee3-c15b-41f7-810c-0e16e6cafa92&rp=1&inc=1&time=6#id=3d9e5ee3-c15b-41f7-810c-0e16e6cafa92&view=1&classId=6e80eda3-3061-41f2-9b6e-7cff2454c3dd")!

    /// The classes taken (TT_MINE). Edit this list if an option changes.
    static let mine: Set<String> = [
        "DP Chi A-2", "DP Chi A-2 SL Revision",   // Chinese A: Lang & Lit
        "DP Eng B-2",                             // English B
        "Eng Lit",                                // the school's own literature class
        "DP MAI HL",                              // Mathematics AI HL
        "DP Comp. Sc.",                           // Computer Science
        "DP Econ",                                // Economics
        "DP Bus Man",                             // Business Management
        "DP TOK-1",                               // TOK group 1
        "Guidance", "G: Agency [EE, CAS, CC]", "G: Weekly Alignment",
        "Service Clubs", "Academic Clubs",
    ]

    /// Slots on the timetable that aren't attended (TT_SKIP). Chinese revision
    /// is once a week: Week 1 Wednesday and Week 2 Thursday, not Week 1 Monday.
    static let skip: [(subject: String, day: Int)] = [
        ("DP Chi A-2 SL Revision", 0),
    ]

    /// The timetable only says "Service Clubs" and "Academic Clubs", so which
    /// club is yours is filled in here (TT_CLUBS). `week` is 0 for Week 1
    /// only, 1 for Week 2 only, nil for both.
    struct Club {
        let subject: String
        let week: Int?
        let name: String
        let staff: String
        let room: String
    }

    static let clubs: [Club] = [
        Club(subject: "Service Clubs", week: 0, name: "台東服務隊", staff: "Claire Huang", room: "1F Library"),
        Club(subject: "Service Clubs", week: 1, name: "Scout Club", staff: "Jun-Wei Lee", room: "1F"),
        Club(subject: "Academic Clubs", week: nil, name: "Finance Club", staff: "", room: "2F"),
    ]

    static let core = "IB Core"
    static let schoolEnd = minutes("16:05")
    /// The standard bells, for an hour nobody in 11B is timetabled in.
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

    /// The DP prefix comes off, and TOK loses its group number; every other
    /// trailing "-N" stays, so Eng B-2 is still Eng B-2 (ttName). The one
    /// departure from the userscript: the timetable's "G: Agency [EE, CAS, CC]"
    /// block is shown as Guidance, here and in every widget.
    static func displayName(_ subject: String) -> String {
        if subject.hasPrefix("G: Agency") { return "Guidance" }
        var s = subject
        if s.hasPrefix("DP ") { s = String(s.dropFirst(3)).trimmingCharacters(in: .whitespaces) }
        if s.hasPrefix("TOK-"), s.dropFirst(4).allSatisfy(\.isNumber) { s = "TOK" }
        return s
    }

    // MARK: - The fortnight

    static let lessons: [Lesson] = build()

    /// Each of the ten days laid out, gaps included.
    static let lines: [[Segment]] = (0..<10).map(line)

    private static func parse(_ row: Substring) -> Lesson {
        let f = row.split(separator: "~", omittingEmptySubsequences: false).map(String.init)
        func list(_ i: Int) -> [String] {
            i < f.count ? f[i].split(separator: ";").map(String.init) : []
        }
        return Lesson(subject: f[0], day: Int(f[1])!, start: minutes(f[2]), end: minutes(f[3]),
                      staff: list(4), rooms: list(5))
    }

    private static func build() -> [Lesson] {
        let rows = TimetableData.raw.split(separator: "\n").map(parse)

        var taught = rows.filter { row in
            mine.contains(row.subject) && !skip.contains { $0.subject == row.subject && $0.day == row.day }
        }
        for i in taught.indices {
            let week = taught[i].day < 5 ? 0 : 1
            if let club = clubs.first(where: { $0.subject == taught[i].subject && ($0.week == nil || $0.week == week) }) {
                taught[i].subject = club.name
                taught[i].staff = club.staff.isEmpty ? [] : [club.staff]
                taught[i].rooms = club.room.isEmpty ? [] : [club.room]
            }
        }

        /* Any period before 16:05 with none of your classes in it is IB Core.
           The periods are the ones the whole of 11B is timetabled in that day,
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
    private static func line(_ day: Int) -> [Segment] {
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
