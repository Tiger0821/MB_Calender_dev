import Foundation

/* Taiwan's national holidays, from the government's office calendars for 2026
   (民國115年) and 2027 (116年) as approved by the Executive Yuan. Only the ones
   still to come when this was written (4 Oct 2026) are listed. The festivals
   that follow the lunar calendar move every year, so this list has to be
   extended by hand when the 2028 calendar is published — until then the
   countdown simply runs out after New Year's Day 2028. */
struct Holiday: Hashable, Sendable, Identifiable {
    let name: String
    let localName: String
    /// The first day, as "2026-10-10".
    let day: String
    /// How many days in a row it runs: 1 for everything but Lunar New Year.
    var length = 1
    /// The weekday given off in its place when it lands on a weekend.
    var dayOff: String?
    var symbol = "flag.fill"

    var id: String { day }

    /// Midnight at the start of the first day.
    var start: Date { Holidays.date(day) }

    /// Midnight after the last day.
    var end: Date { Timetable.calendar.date(byAdding: .day, value: length, to: start)! }

    /// "Sat, Oct 10", or the whole run for one that lasts several days.
    var dateText: String {
        let first = Holidays.short(start)
        guard length > 1 else { return first }
        return first + " – " + Holidays.short(Timetable.calendar.date(byAdding: .day, value: length - 1, to: start)!)
    }

    /// "Fri, Oct 9 off", when the day off isn't the day itself.
    var dayOffText: String? {
        dayOff.map { Holidays.short(Holidays.date($0)) + " off" }
    }

    /// The days school is off for it, as "2026-10-09": the weekday given in
    /// its place when it lands on a weekend, and otherwise each day it runs.
    var daysOff: [String] {
        if let dayOff { return [dayOff] }
        return (0..<length).map { Holidays.iso(Timetable.calendar.date(byAdding: .day, value: $0, to: start)!) }
    }

    /// Why one of those days is off: "National holiday", or for a day given
    /// in place of one at a weekend, "Day off for Sat, Oct 10".
    var offReason: String {
        dayOff == nil ? "National holiday" : "Day off for " + Holidays.short(start)
    }
}

/// A weekday with no school on it, and the national holiday it is off for.
struct DayOff: Hashable, Sendable {
    let date: Date
    let holiday: Holiday
}

/// How far off a holiday is, in the terms it is shown in.
enum Countdown: Equatable, Sendable {
    /// It is on now.
    case today
    /// Under a day to go: count the hours, minutes and seconds down to this moment.
    case timer(Date)
    /// Whole days to go, counting today.
    case days(Int)
}

enum Holidays {
    static let all: [Holiday] = [
        Holiday(name: "National Day", localName: "國慶日", day: "2026-10-10", dayOff: "2026-10-09"),
        Holiday(name: "Retrocession Day", localName: "臺灣光復節", day: "2026-10-25", dayOff: "2026-10-26"),
        Holiday(name: "Constitution Day", localName: "行憲紀念日", day: "2026-12-25", symbol: "building.columns.fill"),

        Holiday(name: "New Year's Day", localName: "元旦", day: "2027-01-01", symbol: "party.popper.fill"),
        Holiday(name: "Lunar New Year", localName: "春節", day: "2027-02-04", length: 7, symbol: "fireworks"),
        Holiday(name: "Peace Memorial Day", localName: "和平紀念日", day: "2027-02-28", dayOff: "2027-03-01", symbol: "bird.fill"),
        Holiday(name: "Children's Day", localName: "兒童節", day: "2027-04-04", dayOff: "2027-04-06", symbol: "balloon.2.fill"),
        Holiday(name: "Tomb Sweeping Day", localName: "清明節", day: "2027-04-05", symbol: "leaf.fill"),
        Holiday(name: "Labor Day", localName: "勞動節", day: "2027-05-01", dayOff: "2027-04-30", symbol: "hammer.fill"),
        Holiday(name: "Dragon Boat Festival", localName: "端午節", day: "2027-06-09", symbol: "sailboat.fill"),
        Holiday(name: "Mid-Autumn Festival", localName: "中秋節", day: "2027-09-15", symbol: "moon.stars.fill"),
        Holiday(name: "Teachers' Day", localName: "教師節", day: "2027-09-28", symbol: "graduationcap.fill"),
        Holiday(name: "National Day", localName: "國慶日", day: "2027-10-10", dayOff: "2027-10-11"),
        Holiday(name: "Retrocession Day", localName: "臺灣光復節", day: "2027-10-25"),
        Holiday(name: "Constitution Day", localName: "行憲紀念日", day: "2027-12-25", dayOff: "2027-12-24", symbol: "building.columns.fill"),

        Holiday(name: "New Year's Day", localName: "元旦", day: "2028-01-01", dayOff: "2027-12-31", symbol: "party.popper.fill"),
    ]

    static func date(_ iso: String) -> Date {
        let parts = iso.split(separator: "-").map { Int($0)! }
        return Timetable.calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))!
    }

    static func short(_ date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).day().month(.abbreviated))
    }

    /// The day `date` falls on, as "2026-10-10".
    static func iso(_ date: Date) -> String {
        let c = Timetable.calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", c.year ?? 0, c.month ?? 0, c.day ?? 0)
    }

    /// Every day school is off, and the holiday it is off for.
    private static let daysOff: [String: Holiday] = {
        var days: [String: Holiday] = [:]
        for holiday in all {
            for day in holiday.daysOff where days[day] == nil { days[day] = holiday }
        }
        return days
    }()

    /// The holiday that gives `date` off school, if one does. The timetable
    /// knows nothing of holidays, so this is what keeps a day's classes off
    /// the page, out of the widgets and unannounced when there are none.
    static func off(on date: Date) -> Holiday? {
        daysOff[iso(date)]
    }

    /// The holidays not yet over, soonest first.
    static func upcoming(at now: Date) -> [Holiday] {
        all.filter { $0.end > now }
    }

    /// Days while it is more than a day away; the clock once it is under one.
    static func countdown(to holiday: Holiday, at now: Date) -> Countdown {
        let start = holiday.start
        if now >= start { return .today }
        if start.timeIntervalSince(now) <= 24 * 60 * 60 { return .timer(start) }
        let cal = Timetable.calendar
        return .days(cal.dateComponents([.day], from: cal.startOfDay(for: now), to: start).day ?? 0)
    }
}
