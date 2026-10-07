import SwiftUI
import WidgetKit

/* The Smart Stack's widget on the Apple Watch: the class that is on and how
   long it has left, and the class after it, each with its room. Nothing
   else — not the rest of the day, and not who teaches it.

   This is a widget and not the Live Activity, and that is the point of it.
   A Live Activity on the watch cannot change by itself as the day goes on
   (see DayStrip in the phone's widget), but a widget is given a timeline: an
   entry for every bell, each drawn for its own moment, with the countdown
   between bells run by the system. */
@main
struct TimetableWatchWidgets: WidgetBundle {
    var body: some Widget {
        NowNextWatchWidget()
    }
}

struct WatchEntry: TimelineEntry {
    let date: Date
    let snapshot: Snapshot

    /// How long before the first bell the morning's greeting comes up.
    static let greetingLead: TimeInterval = 2 * 3600
    /// How long before the first bell the countdown takes the greeting's place.
    static let countdownLead: TimeInterval = 30 * 60

    init(date: Date) {
        self.date = date
        snapshot = Timetable.snapshot(at: date)
    }

    /* What the Smart Stack goes by in choosing which widget to bring to the
       top: from the greeting until the last bell this one has something to
       say, and the rest of the time it has not. The stack does the choosing;
       this is only the widget's word on when it is worth a look. */
    var relevance: TimelineEntryRelevance? {
        let day = Timetable.day(of: date)
        guard let first = day.first, let last = day.last,
              date >= first.start.addingTimeInterval(-Self.greetingLead), date < last.end else {
            return TimelineEntryRelevance(score: 0)
        }
        return TimelineEntryRelevance(score: 100)
    }
}

struct WatchProvider: TimelineProvider {
    func placeholder(in context: Context) -> WatchEntry { WatchEntry(date: .now) }

    func getSnapshot(in context: Context, completion: @escaping (WatchEntry) -> Void) {
        Timetable.reload()
        completion(WatchEntry(date: .now))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WatchEntry>) -> Void) {
        // the phone may have handed over a new profile since this last ran
        Timetable.reload()
        let now = Date.now
        var dates = Set(Timetable.changes(after: now))
        // and the two moments of a morning that are not bells: when the
        // greeting comes up, and when the countdown takes its place
        if let end = dates.max() {
            var day = Timetable.calendar.startOfDay(for: now)
            while day < end {
                if let first = Timetable.day(of: day).first {
                    for lead in [WatchEntry.greetingLead, WatchEntry.countdownLead] {
                        let mark = first.start.addingTimeInterval(-lead)
                        if mark > now, mark < end { dates.insert(mark) }
                    }
                }
                day = Timetable.calendar.date(byAdding: .day, value: 1, to: day)!
            }
        }
        let entries = ([now] + dates.sorted()).map(WatchEntry.init)
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct NowNextWatchWidget: Widget {
    var body: some WidgetConfiguration {
        StaticConfiguration(kind: "NowNextWatch", provider: WatchProvider()) { entry in
            NowNextWatchView(entry: entry)
                .containerBackground(.black, for: .widget)
        }
        .configurationDisplayName("Now & Next")
        .description("The class that is on, the time it has left, and the one after it.")
        .supportedFamilies([.accessoryRectangular, .accessoryInline])
    }
}

struct NowNextWatchView: View {
    @Environment(\.widgetFamily) private var family
    let entry: WatchEntry

    var body: some View {
        let snapshot = entry.snapshot
        let current = snapshot.current
        // what follows: the next class that is not the one on now carrying on
        let next = snapshot.upcoming.first { $0.segment.title != current?.segment.title || !(current?.segment.isLesson ?? false) }
        if family == .accessoryInline {
            inline(current: current, next: next)
        } else {
            /* The tile is not the same height on every watch — some 47 points
               on the smallest, nearer 58 on an Ultra — and what does not fit
               is cut off without a word. So it is laid out at full size where
               that fits, and a size or two down where it does not. */
            ViewThatFits(in: .vertical) {
                panel(snapshot, current: current, next: next, scale: 1)
                panel(snapshot, current: current, next: next, scale: 0.9)
                panel(snapshot, current: current, next: next, scale: 0.8)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
        }
    }

    private func panel(_ snapshot: Snapshot, current: TimedSegment?, next: TimedSegment?, scale: CGFloat) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            if let current {
                now(current, until: classEnd(of: current, in: snapshot.day), scale: scale)
                if let next { line(next, lead: "Next", scale: scale) }
            } else if Timetable.profile == nil {
                Text("Open Timetable on your iPhone")
                    .font(.system(size: 13 * scale, weight: .semibold))
            } else if let next, snapshot.isToday {
                // before the first bell: nearer to it, more is made of it
                let wait = next.start.timeIntervalSince(entry.date)
                let then = snapshot.upcoming.first { $0.start > next.start && $0.segment.title != next.segment.title }
                if wait <= WatchEntry.countdownLead {
                    imminent(next, then: then, scale: scale)
                } else if wait <= WatchEntry.greetingLead {
                    morning(next, then: then, scale: scale)
                } else {
                    line(next, lead: snapshot.dayLabel, scale: scale)
                }
            } else if let next {
                line(next, lead: snapshot.dayLabel, scale: scale)
            } else {
                Text("No classes")
                    .font(.system(size: 15 * scale, weight: .semibold))
            }
        }
    }

    /// A class by name, in its colour, with its room after it.
    private func title(_ segment: Segment, scale: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text(segment.shortTitle)
                .font(.system(size: 16 * scale, weight: .bold))
                .foregroundStyle(segment.isLesson ? Timetable.tint(for: segment.lessons.first?.subject ?? "") : Color.white)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
                .widgetAccentable()
            if !segment.place.isEmpty {
                Text(segment.place)
                    .font(.system(size: 12 * scale, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
    }

    /// A countdown in a width of its own: left to itself it takes all the
    /// width it is offered.
    private func countdown(to end: Date, size: CGFloat, width: CGFloat, alignment: Alignment) -> some View {
        Text(timerInterval: entry.date...max(end, entry.date), countsDown: true)
            .font(.system(size: size, weight: .semibold).monospacedDigit())
            .multilineTextAlignment(alignment == .trailing ? .trailing : .leading)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .frame(width: width, alignment: alignment)
    }

    /// The class that is on (or the break), its room, and its time left.
    @ViewBuilder
    private func now(_ item: TimedSegment, until end: Date, scale: CGFloat) -> some View {
        title(item.segment, scale: scale)
        HStack(alignment: .firstTextBaseline, spacing: 3) {
            countdown(to: end, size: 15 * scale, width: 62 * scale, alignment: .leading)
            Text("left")
                .font(.system(size: 12 * scale))
                .foregroundStyle(.secondary)
        }
    }

    /* The morning, from two hours before the first bell: a greeting set in
       pixels (PixelText) with the line to itself, the first class and its
       room with the time until it small at the end of the line, and the
       class after that. The greeting and the countdown shared the top line
       at first, and it was a squeeze: the two together are as wide as the
       tile. */
    @ViewBuilder
    private func morning(_ item: TimedSegment, then: TimedSegment?, scale: CGFloat) -> some View {
        PixelText(text: "Good morning", pixel: scale == 1 ? 2 : 1.5)
            .padding(.bottom, 1)
        let countdown = Text(timerInterval: entry.date...max(item.start, entry.date), countsDown: true)
            .font(.system(size: 12 * scale, weight: .semibold).monospacedDigit())
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            // the class keeps its width; on a narrow watch it is the
            // countdown that is set smaller to go in what is left
            title(item.segment, scale: scale)
                .layoutPriority(1)
            Spacer(minLength: 2)
            /* "in" and the countdown are one text, so the gap between them
               is a space and stays one: as two views, with the countdown
               hard to the right of a width of its own, "in" stood as far
               from its number as from what came before it. (One text set
               inside another, where they were once joined with "+": that
               was deprecated in watchOS 26.) */
            Text("\(Text(verbatim: "in ").font(.system(size: 11 * scale)).foregroundStyle(.secondary))\(countdown)")
                .multilineTextAlignment(.trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: 58 * scale, alignment: .trailing)
        }
        if let then { line(then, lead: "Next", scale: scale) }
    }

    /* The last half hour before the first bell: the greeting has been said,
       and the countdown takes its line and is made the largest thing on the
       tile, since by now it is the thing being looked for. */
    @ViewBuilder
    private func imminent(_ item: TimedSegment, then: TimedSegment?, scale: CGFloat) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 4) {
            Text("Starts in")
                .font(.system(size: 12 * scale))
                .foregroundStyle(.secondary)
            countdown(to: item.start, size: 20 * scale, width: 64 * scale, alignment: .leading)
        }
        title(item.segment, scale: scale)
        if let then { line(then, lead: "Next", scale: scale) }
    }

    /// A class to come on one line: when it starts, its name, and where.
    private func line(_ item: TimedSegment, lead: String, scale: CGFloat) -> some View {
        let segment = item.segment
        let place = segment.place.isEmpty ? "" : " · \(segment.place)"
        let when = Text(verbatim: "\(lead) \(Timetable.hhmm(item.start)) ").foregroundStyle(.secondary)
        let name = Text(verbatim: segment.shortTitle).fontWeight(.semibold)
        let room = Text(verbatim: place).foregroundStyle(.secondary)
        return Text("\(when)\(name)\(room)")
            .font(.system(size: 12 * scale))
            .lineLimit(1)
            .minimumScaleFactor(0.75)
    }

    @ViewBuilder
    private func inline(current: TimedSegment?, next: TimedSegment?) -> some View {
        if let current, current.segment.isLesson {
            Text("\(current.segment.shortTitle) until \(Timetable.hhmm(classEnd(of: current, in: entry.snapshot.day)))")
        } else if let next {
            Text("\(next.segment.shortTitle) at \(Timetable.hhmm(next.start))")
        } else {
            Text("No classes")
        }
    }

    /// Where the class that is on ends: for a double period, the end of its
    /// second half, as the phone's island counts it.
    private func classEnd(of item: TimedSegment, in day: [TimedSegment]) -> Date {
        var end = item.end
        guard item.segment.isLesson else { return end }
        for later in day where later.start == end && later.segment.isLesson && later.segment.title == item.segment.title {
            end = later.end
        }
        return end
    }
}
