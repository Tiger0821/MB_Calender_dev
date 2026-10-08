import SwiftUI
import WidgetKit

/* Today: the whole day as the dock lays it out — what's done greyed back,
   the block running now filled in with its countdown, the rest to come. Once
   the last block ends it turns over to the next school day. */
struct TodayWidget: Widget {
    let kind = "Today"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: ClassProvider()) { entry in
            DayView(entry: entry)
                .widgetTextSize()
                .containerBackground(for: .widget) { Backdrop(tint: entry.snapshot.focus?.segment.tint) }
        }
        .configurationDisplayName("Today")
        .description("The whole day, with the current block marked.")
        .supportedFamilies([.systemLarge])
    }
}

struct DayView: View {
    let entry: ClassEntry

    /// A break or lunch takes this much of a class's height.
    private static let gap: CGFloat = 0.62
    private static let header: CGFloat = 28

    var body: some View {
        GeometryReader { geo in
            content(height: geo.size.height)
        }
    }

    private func content(height: CGFloat) -> some View {
        let snapshot = entry.snapshot
        let (rows, unit) = fit(snapshot, room: height - Self.header)
        return VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(snapshot.dayLabel)
                    .font(.system(size: 17, weight: .semibold))
                    .widgetAccentable()
                if let first = snapshot.day.first {
                    Text("\(Timetable.dayNames[first.cycleDay % 5]) · Week \(first.cycleDay / 5 + 1)")
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 4)
                if let now = snapshot.current {
                    TimeLeft(segment: now)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(now.segment.tint)
                } else if let holiday = snapshot.holidayToday {
                    // the day below is the next school day; today is a day off
                    Label("No class today · \(holiday.localName)", systemImage: holiday.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(.red)
                }
            }
            .lineLimit(1)
            .frame(height: Self.header, alignment: .top)

            if rows.isEmpty {
                Text(Timetable.profile == nil ? "Open Timetable to set it up." : "Nothing on the timetable.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            ForEach(rows) { item in
                DayRow(item: item, now: entry.date, unit: unit,
                       height: item.segment.isLesson ? unit : unit * Self.gap)
            }
            Spacer(minLength: 0)
        }
    }

    /* Which rows to show, and how tall to make a class. Every row gets a
       height of its own and the text is sized to the row, rather than the
       other way about: a widget's frame doesn't grow, so rows that took their
       height from the text ran into each other as soon as the phone's text
       size was turned up.

       The day's rows share out the room between them, up to a comfortable
       height. Short breaks are left out unless one is on now. If the day
       still doesn't fit at the smallest readable height, the blocks already
       over make way from the top — keeping one, so the current block isn't
       the first thing you see — and after that the end of the day does. */
    private func fit(_ snapshot: Snapshot, room: CGFloat) -> (rows: [TimedSegment], unit: CGFloat) {
        let all = snapshot.day.filter { $0.segment.title != "Break" || $0.contains(entry.date) }
        let smallest: CGFloat = 29, largest: CGFloat = 42
        func units(_ rows: ArraySlice<TimedSegment>) -> CGFloat {
            rows.reduce(0) { $0 + ($1.segment.isLesson ? 1 : Self.gap) }
        }
        var rows = all[...]
        let keep = max(0, (all.firstIndex { $0.end > entry.date } ?? 0) - 1)
        while units(rows) * smallest > room, rows.startIndex < keep { rows = rows.dropFirst() }
        while units(rows) * smallest > room, rows.count > 1 { rows = rows.dropLast() }
        let total = units(rows)
        return (Array(rows), total > 0 ? min(largest, room / total) : largest)
    }
}

struct DayRow: View {
    let item: TimedSegment
    let now: Date
    /// The height of a class row, which the text is sized from.
    let unit: CGFloat
    let height: CGFloat

    var body: some View {
        let segment = item.segment
        let isNow = item.contains(now)
        let title = min(16, unit * 0.40), detail = min(13, unit * 0.33)
        HStack(spacing: 8) {
            Text(Timetable.hhmm(segment.start))
                .font(.system(size: detail).monospacedDigit())
                .foregroundStyle(.secondary)
                .lineLimit(1)
                .fixedSize()
                .frame(width: detail * 3.3, alignment: .leading)
            if segment.isLesson {
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(segment.tint)
                    .frame(width: 3)
                    .padding(.vertical, 3)
                    .widgetAccentable()
                VStack(alignment: .leading, spacing: 0) {
                    Text(segment.shortTitle)
                        .font(.system(size: title, weight: .semibold))
                        .lineLimit(1)
                    if !segment.place.isEmpty {
                        Text(segment.place)
                            .font(.system(size: detail))
                            .foregroundStyle(.secondary)
                            .lineLimit(1)
                    }
                }
            } else {
                Image(systemName: segment.symbol)
                    .font(.system(size: detail))
                    .foregroundStyle(.secondary)
                    .frame(width: 3)
                Text("\(segment.title) — \(segment.minutes) min")
                    .font(.system(size: detail))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            if isNow {
                Text(timerInterval: item.interval, countsDown: true)
                    .font(.system(size: detail, weight: .semibold).monospacedDigit())
                    .multilineTextAlignment(.trailing)
                    .lineLimit(1)
                    .frame(width: detail * 4.6, alignment: .trailing)
            } else if segment.isLesson {
                Text("\(segment.minutes)m")
                    .font(.system(size: detail))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                    .fixedSize()
            }
        }
        .padding(.horizontal, 6)
        .frame(height: height)
        .background {
            if isNow {
                RowFill(item: item, height: height)
                    .background(segment.tint.opacity(0.12))
                    .clipShape(.rect(cornerRadius: 8))
            }
        }
        .opacity(item.end <= now ? 0.4 : 1)
    }
}

/* The row of the block that is on, filling from left to right as the block
   runs, the way the app's does. A widget can't redraw as time passes; what it
   can show is a progress bar the system fills in — so this is one, made as
   tall as the row and sat behind the text rather than under it, where a bar
   of its own ran into the room number. */
struct RowFill: View {
    let item: TimedSegment
    let height: CGFloat

    var body: some View {
        ProgressView(timerInterval: item.interval, countsDown: false) {
            EmptyView()
        } currentValueLabel: {
            EmptyView()
        }
        .progressViewStyle(.linear)
        .tint(item.segment.tint.opacity(0.36))
        // a few points tall with round ends: stretched past the row both
        // ways, what is left inside it has square corners and a straight edge
        .scaleEffect(x: 1.05, y: height, anchor: .center)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview("Today", as: .systemLarge) {
    TodayWidget()
} timeline: {
    ClassEntry.sample(10, 40)
    ClassEntry.sample(12, 10)
    ClassEntry.sample(15, 30)
}
