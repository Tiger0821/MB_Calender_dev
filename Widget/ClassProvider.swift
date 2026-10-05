import WidgetKit

struct ClassEntry: TimelineEntry {
    let date: Date
    let snapshot: Snapshot

    init(date: Date) {
        self.date = date
        snapshot = Timetable.snapshot(at: date)
    }

    /// A moment on the next school day (today, if it is one), for previews.
    static func sample(_ hour: Int, _ minute: Int) -> ClassEntry {
        let cal = Timetable.calendar
        var day = cal.startOfDay(for: .now)
        // before setup there are no school days at all, so the search has an end
        for _ in 0..<14 where Timetable.day(of: day).isEmpty { day = cal.date(byAdding: .day, value: 1, to: day)! }
        return ClassEntry(date: cal.date(bySettingHour: hour, minute: minute, second: 0, of: day)!)
    }
}

/* The timetable only changes when setup is done again, and the app reloads
   the widgets when it is, so a whole timeline can be laid out in one go: an
   entry at every bell, and at every midnight, through the next two school
   days. Countdowns and progress bars between bells are drawn by the system
   from each entry's interval, so nothing needs to wake up once a minute. */
struct ClassProvider: TimelineProvider {
    func placeholder(in context: Context) -> ClassEntry {
        ClassEntry(date: .now)
    }

    func getSnapshot(in context: Context, completion: @escaping (ClassEntry) -> Void) {
        Timetable.reload()
        completion(ClassEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<ClassEntry>) -> Void) {
        // the app may have been through setup since this process last looked
        Timetable.reload()
        let now = Date.now
        let entries = ([now] + Timetable.changes(after: now)).map(ClassEntry.init)
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}
