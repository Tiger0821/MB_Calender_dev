import SwiftUI
import WidgetKit

/// The boxes that can be moved around, in the order they come in.
enum Box: String, CaseIterable {
    case now, holiday, days, timetable

    /// A saved order, with anything missing from it put back at the end.
    static func order(from saved: String) -> [Box] {
        var boxes: [Box] = []
        for name in saved.split(separator: ",") {
            if let box = Box(rawValue: String(name)), !boxes.contains(box) { boxes.append(box) }
        }
        return boxes + allCases.filter { !boxes.contains($0) }
    }
}

/* The dock, as an app: today's date and the time, what's on now, the next
   national holiday, a picker for any of the ten days in the cycle, and the
   picked day underneath. It follows the clock until a day is picked by hand;
   Today brings it back. The four boxes can be put in any order — touch and
   hold one to move it — and the order is kept. Behind it all is the sky as it
   is outside, when the weather is known.

   Nothing else is on the page. The settings, and where everything comes
   from, are a page of their own off the right-hand edge: a swipe in from
   that edge, or the gear by the clock, slides it across. */
struct ContentView: View {
    /// A cycle day (0-9) picked by hand; nil follows the clock.
    @State private var picked: Int?
    @AppStorage("boxOrder") private var savedOrder = ""
    /// The page's scroll position, so a box held at the edge can scroll it.
    @State private var scrollPosition = ScrollPosition()
    @State private var scroller = Scroller()
    @State private var weather = WeatherModel()
    /// The strip of open sky under the date, measured on the page, and where
    /// the page starts on the screen: together they place the sun.
    @State private var skyWindow = CGRect.zero
    @State private var pageOrigin = CGPoint.zero
    @Environment(\.scenePhase) private var scenePhase
    /// Whose timetable it is; nil until setup has been done.
    @State private var profile = Timetable.profile
    /// Setup again, to change the name, the form or the classes.
    @State private var editing = false
    /// Whether the settings page is across the screen.
    @State private var settingsOpen = false
    /// While a finger is pulling it: how far across it is, 0 (away) to 1.
    @State private var pull: CGFloat?

    private var boxOrder: Binding<[Box]> {
        Binding {
            Box.order(from: savedOrder)
        } set: { boxes in
            savedOrder = boxes.map(\.rawValue).joined(separator: ",")
        }
    }

    var body: some View {
        Group {
            if let profile {
                GeometryReader { geo in
                    let span = geo.size.width + geo.safeAreaInsets.leading + geo.safeAreaInsets.trailing
                    let across = pull ?? (settingsOpen ? 1 : 0)
                    ZStack {
                        // the day's rows are laid out from the profile without being handed it,
                        // so a changed profile gets a page of its own rather than a stale one
                        page(for: profile)
                            .id(profile)
                            // it gives way as settings comes over it, a little, and dims
                            .offset(x: -across * span * 0.3)
                            .overlay {
                                Color.black.opacity(0.35 * across)
                                    .ignoresSafeArea()
                                    .allowsHitTesting(false)
                            }
                            .allowsHitTesting(across == 0)
                            .accessibilityHidden(settingsOpen)
                            .gesture(EdgeSwipe(edge: .right) { state, distance, speed in
                                pulled(state, fraction: -distance / span, speed: -speed, opening: true)
                            })
                        SettingsPanel(profile: profile) {
                            editing = true
                        } close: {
                            withAnimation(.snappy(duration: 0.3)) { settingsOpen = false }
                        }
                        .offset(x: (1 - across) * span)
                        .accessibilityHidden(!settingsOpen)
                        .gesture(EdgeSwipe(edge: .left) { state, distance, speed in
                            pulled(state, fraction: distance / span, speed: speed, opening: false)
                        })
                    }
                }
                // a knock as it opens, and a lighter one as it goes
                .sensoryFeedback(trigger: settingsOpen) { _, open in
                    open ? .impact(weight: .medium) : .impact(weight: .light)
                }
            } else {
                SetupView(existing: nil) { use($0) }
            }
        }
        .sheet(isPresented: $editing) {
            SetupView(existing: profile) {
                use($0)
                editing = false
            } cancel: {
                editing = false
            }
        }
    }

    /* A finger pulling the settings page in from the right edge, or pushing
       it back from the left. `fraction` is how far across the screen it has
       come and `speed` how fast, both in the direction of the swipe. The page
       follows the finger; let go and it carries on if it was past a third of
       the way or moving quickly, and goes back otherwise. */
    private func pulled(_ state: UIGestureRecognizer.State, fraction: CGFloat, speed: CGFloat, opening: Bool) {
        let fraction = min(1, max(0, fraction))
        switch state {
        case .began, .changed:
            pull = opening ? fraction : 1 - fraction
        case .ended:
            let carriesOn = fraction > 0.35 || speed > 600
            withAnimation(.snappy(duration: 0.3)) {
                settingsOpen = opening ? carriesOn : !carriesOn
                pull = nil
            }
        default:
            withAnimation(.snappy(duration: 0.3)) { pull = nil }
        }
    }

    /// Take up a profile from setup: keep it, lay the fortnight out for it,
    /// and have the widgets do the same.
    private func use(_ new: Profile) {
        new.save()
        Timetable.profile = new
        withAnimation(.snappy) {
            profile = new
            picked = nil
        }
        WidgetCenter.shared.reloadAllTimelines()
        // a day already on the Lock Screen was laid out for the old profile
        Task { await ClassActivityManager.refresh(reset: .everything) }
    }

    private func page(for profile: Profile) -> some View {
        TimelineView(.everyMinute) { context in
            let now = context.date
            let snapshot = Timetable.snapshot(at: now)
            let today = Timetable.cycleDay(of: now)
            let shown = picked ?? snapshot.day.first?.cycleDay ?? today ?? 0
            let phase = weather.current?.phase(at: now)
            let scene = weather.current.map { SkyScene(sky: $0.sky, phase: phase ?? .day, wind: $0.wind) }

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    DateHeader()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        // beside the clock, where the date above it has the full width
                        .overlay(alignment: .bottomTrailing) {
                            Button {
                                withAnimation(.snappy(duration: 0.3)) { settingsOpen = true }
                            } label: {
                                Image(systemName: "gearshape")
                                    .font(.body.weight(.medium))
                                    .frame(width: 38, height: 38)
                            }
                            .buttonStyle(.plain)
                            .glassEffect(.regular.interactive(), in: .circle)
                            .offset(y: 6)
                            .accessibilityLabel("Settings")
                        }
                    SkyStrip(profile: profile, weather: weather.current, isDay: phase != .night) {
                        editing = true
                    }
                    .onGeometryChange(for: CGRect.self) { proxy in
                        proxy.frame(in: .named("page"))
                    } action: { frame in
                        skyWindow = frame
                    }
                    ReorderableStack(order: boxOrder, scroller: scroller) { box in
                        switch box {
                        case .now: NowCard(snapshot: snapshot, now: now)
                        case .holiday: HolidayCard(now: now)
                        case .days: DayPicker(picked: $picked, shown: shown, today: today)
                        case .timetable:
                            VStack(alignment: .leading, spacing: 6) {
                                dayHeader(shown, today: today, snapshot: snapshot)
                                DayList(day: shown, live: shown == today, now: now)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassEffect(.regular, in: .rect(cornerRadius: 28))
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 12)
                .padding(.bottom, 40)
                .coordinateSpace(.named("page"))
            }
            .scrollPosition($scrollPosition)
            // keep the Lock Screen's day going: today's up, the next one booked
            .task(id: now) { await ClassActivityManager.refresh() }
            .onScrollGeometryChange(for: ScrollExtent.self) { geometry in
                let top = -geometry.contentInsets.top
                return ScrollExtent(offset: geometry.contentOffset.y, top: top,
                                    bottom: max(top, geometry.contentSize.height + geometry.contentInsets.bottom
                                                - geometry.containerSize.height),
                                    leading: geometry.contentInsets.leading)
            } action: { _, extent in
                scroller.offset = extent.offset
                scroller.range = extent.top...extent.bottom
                let origin = CGPoint(x: extent.leading, y: -extent.top)
                if origin != pageOrigin { pageOrigin = origin }
            }
            .onGeometryChange(for: CGRect.self) { proxy in
                proxy.frame(in: .global)
            } action: { frame in
                scroller.frame = frame
            }
            .onAppear {
                let position = $scrollPosition
                scroller.scrollTo = { position.wrappedValue.scrollTo(y: $0) }
            }
            .background {
                backdrop(scene, tint: snapshot.focus?.segment.tint ?? .accentColor)
                    .ignoresSafeArea()
            }
            // the backdrop again over the top of the screen, thinning out just below the
            // status bar, so the page fades away as it slides up under the clock
            .overlay {
                backdrop(scene, tint: snapshot.focus?.segment.tint ?? .accentColor)
                    .mask(alignment: .top) {
                        LinearGradient(stops: [.init(color: .black, location: 0.6), .init(color: .clear, location: 1)],
                                       startPoint: .top, endPoint: .bottom)
                            .frame(height: pageOrigin.y + 8)
                    }
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
            // every sky is dark at the top, so over one the page is always in its dark colours
            .preferredColorScheme(scene == nil ? nil : .dark)
        }
        .task {
            // look again every couple of minutes; refresh decides whether it is time to fetch
            while !Task.isCancelled {
                await weather.refresh()
                try? await Task.sleep(for: .seconds(120))
            }
        }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await weather.refresh() } }
        }
    }

    /// What is behind the page: the sky when the weather is known, and
    /// otherwise a wash of the colour of whatever is on.
    @ViewBuilder
    private func backdrop(_ scene: SkyScene?, tint: Color) -> some View {
        if let scene {
            PixelSky(scene: scene, window: skyWindow.offsetBy(dx: pageOrigin.x, dy: pageOrigin.y))
        } else {
            LinearGradient(colors: [tint.opacity(0.28), .clear], startPoint: .top, endPoint: .center)
                .background(Color(.systemBackground))
        }
    }

    private static let weekdays = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

    /// Which day the list underneath is: "Tomorrow · Monday · Week 2", with
    /// the way back to the clock once a day has been picked by hand.
    private func dayHeader(_ day: Int, today: Int?, snapshot: Snapshot) -> some View {
        let lead: String? = day == today ? "Today"
            : !snapshot.isToday && snapshot.day.first?.cycleDay == day ? snapshot.dayLabel
            : nil
        let name = Self.weekdays[day % 5]
        return HStack(alignment: .firstTextBaseline, spacing: 6) {
            Text(lead == name ? name : lead ?? name)
                .font(.title3.weight(.bold))
            Text((lead == nil || lead == name ? "" : name + " · ") + "Week \(day / 5 + 1)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            if picked != nil {
                Button("Today") {
                    withAnimation(.snappy) { picked = nil }
                }
                .font(.subheadline.weight(.semibold))
            }
        }
        .padding(.horizontal, 12)
    }
}

/// How far the page is scrolled, how far it can go either way, and how far
/// in from the left edge of the screen it starts.
private struct ScrollExtent: Equatable {
    var offset: CGFloat
    var top: CGFloat
    var bottom: CGFloat
    var leading: CGFloat
}

// MARK: - Date and time

/// Today's date, and the time to the second.
struct DateHeader: View {
    var body: some View {
        // from midnight, so each tick lands on the second
        TimelineView(.periodic(from: Timetable.calendar.startOfDay(for: .now), by: 1)) { context in
            VStack(alignment: .leading, spacing: 0) {
                Text(context.date.formatted(.dateTime.weekday(.wide).day().month(.wide)))
                    .font(.largeTitle.weight(.bold))
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(Timetable.clock(context.date))
                    .font(.title2.weight(.medium).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            .accessibilityElement(children: .combine)
        }
    }
}

// MARK: - Who, and the weather

/* Under the date: whose timetable this is — a name and a form, which open
   setup again when tapped — and, when the weather is known, the reading. With
   weather the strip is kept tall, so there is open sky beside the two for the
   sun or moon and the clouds to show in, clear of the boxes. */
struct SkyStrip: View {
    let profile: Profile
    let weather: Weather?
    let isDay: Bool
    let edit: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: edit) {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle")
                    Text(profile.name)
                        .fontWeight(.semibold)
                        .lineLimit(1)
                    Text(profile.form)
                        .font(.footnote.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(.tint.opacity(0.35), in: .capsule)
                }
                .font(.subheadline)
                .padding(.horizontal, 14)
                .frame(minHeight: 38)
                .contentShape(.capsule)
            }
            .buttonStyle(.plain)
            .glassEffect(.regular.interactive(), in: .capsule)
            .accessibilityLabel("\(profile.name), \(profile.form)")
            .accessibilityHint("Changes your name, form and classes")
            if let weather {
                WeatherReading(weather: weather, isDay: isDay)
            }
        }
        .frame(maxWidth: .infinity, minHeight: weather == nil ? nil : 112, alignment: .bottomLeading)
    }
}

/// The temperature and the conditions, then the place and the day's high and low.
struct WeatherReading: View {
    let weather: Weather
    let isDay: Bool

    var body: some View {
        let range = [weather.high.map { "H " + Weather.degrees($0) }, weather.low.map { "L " + Weather.degrees($0) }]
            .compactMap { $0 }.joined(separator: "  ")
        let detail = [weather.place, range].filter { !$0.isEmpty }
        VStack(alignment: .leading, spacing: 2) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Text(Weather.degrees(weather.temperature))
                    .font(.title2.weight(.bold))
                Label(weather.sky.label(isDay: isDay), systemImage: weather.sky.symbol(isDay: isDay))
                    .font(.subheadline.weight(.semibold))
            }
            if !detail.isEmpty {
                Text(detail.joined(separator: " · "))
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: .rect(cornerRadius: 20))
        .accessibilityElement(children: .combine)
    }
}

// MARK: - Holidays

/* The next national holiday and how long until it: whole days while it is
   more than a day off, then hours, minutes and seconds. The few after it are
   listed underneath. */
struct HolidayCard: View {
    let now: Date
    /// The column the later holidays' symbols sit in; it grows with the text size.
    @ScaledMetric(relativeTo: .subheadline) private var iconWidth: CGFloat = 22

    var body: some View {
        let upcoming = Holidays.upcoming(at: now)
        if let next = upcoming.first {
            let countdown = Holidays.countdown(to: next, at: now)
            VStack(alignment: .leading, spacing: 12) {
                Label(countdown == .today ? "Holiday today" : "Next holiday", systemImage: next.symbol)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(.red)
                HStack(alignment: .center, spacing: 12) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(next.name)
                            .font(.title2.weight(.bold))
                            .lineLimit(2)
                            .minimumScaleFactor(0.7)
                        Text("\(next.localName) · \(next.dateText)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let off = next.dayOffText {
                            Text(off)
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                    }
                    Spacer(minLength: 0)
                    CountdownBadge(countdown: countdown, now: now)
                }
                let later = upcoming.dropFirst().prefix(3)
                if !later.isEmpty {
                    Divider()
                    ForEach(later) { holiday in
                        let name = Text(holiday.name).font(.subheadline.weight(.semibold))
                        let date = Text(Holidays.short(holiday.start)).font(.footnote).foregroundStyle(.secondary)
                        HStack(spacing: 10) {
                            Image(systemName: holiday.symbol)
                                .foregroundStyle(.red)
                                .frame(width: iconWidth)
                            // on one line while there is room; with larger text the date drops under the name
                            ViewThatFits(in: .horizontal) {
                                HStack(spacing: 4) {
                                    name.lineLimit(1)
                                    Spacer(minLength: 4)
                                    date.lineLimit(1)
                                }
                                VStack(alignment: .leading, spacing: 0) {
                                    name
                                    date
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            CountdownLabel(countdown: Holidays.countdown(to: holiday, at: now), now: now)
                                .font(.footnote.weight(.semibold).monospacedDigit())
                                .frame(minWidth: 62, alignment: .trailing)
                        }
                    }
                }
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .glassEffect(.regular.tint(Color.red.opacity(0.08)), in: .rect(cornerRadius: 28))
        }
    }
}

/// The count, large: "6 days", or the clock running down once it is under one.
struct CountdownBadge: View {
    let countdown: Countdown
    let now: Date

    var body: some View {
        VStack(alignment: .trailing, spacing: -2) {
            switch countdown {
            case .today:
                Text("Today")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
            case .timer(let start):
                Text(timerInterval: now...start, countsDown: true)
                    .font(.system(size: 34, weight: .bold, design: .rounded).monospacedDigit())
                    .multilineTextAlignment(.trailing)
                Text("to go")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            case .days(let days):
                Text("\(days)")
                    .font(.system(size: 46, weight: .bold, design: .rounded))
                Text("days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .foregroundStyle(.red)
    }
}


// MARK: - Now

struct NowCard: View {
    let snapshot: Snapshot
    let now: Date

    var body: some View {
        let tint = snapshot.focus?.segment.tint ?? .accentColor
        VStack(alignment: .leading, spacing: 10) {
            if let current = snapshot.current {
                Label("Now", systemImage: current.segment.symbol)
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(current.segment.tint)
                Text(current.segment.shortTitle)
                    .font(.largeTitle.weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Details(segment: current.segment)
                ProgressView(value: current.progress(at: now))
                    .tint(current.segment.tint)
                HStack {
                    Text("\(minutesLeft(current)) min left")
                    Spacer()
                    Text("until \(Timetable.hhmm(current.segment.end))")
                }
                .font(.subheadline.monospacedDigit())
                .foregroundStyle(.secondary)
                if let next = snapshot.upcoming.first {
                    Divider()
                    NextLine(item: next, label: "Next")
                }
            } else if let next = snapshot.upcoming.first {
                Label("Next · \(snapshot.dayLabel)", systemImage: "arrow.forward.circle")
                    .font(.caption.weight(.bold))
                    .textCase(.uppercase)
                    .foregroundStyle(next.segment.tint)
                Text(next.segment.shortTitle)
                    .font(.largeTitle.weight(.bold))
                    .lineLimit(2)
                    .minimumScaleFactor(0.6)
                Text("\(Timetable.hhmm(next.segment.start))–\(Timetable.hhmm(next.segment.end))")
                    .font(.headline.monospacedDigit())
                Details(segment: next.segment)
                if snapshot.isToday {
                    Text("in \(minutesLeft(until: next.start)) min")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            } else {
                Label("Nothing on the timetable", systemImage: "calendar")
                    .font(.headline)
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(.regular.tint(tint.opacity(0.15)), in: .rect(cornerRadius: 28))
    }

    private func minutesLeft(_ item: TimedSegment) -> Int { minutesLeft(until: item.end) }

    private func minutesLeft(until date: Date) -> Int {
        max(0, Int((date.timeIntervalSince(now) / 60).rounded(.up)))
    }
}

/// Room and teacher, under a name.
struct Details: View {
    let segment: Segment

    var body: some View {
        let parts = [segment.place, segment.staff].filter { !$0.isEmpty }
        if !parts.isEmpty {
            Text(parts.joined(separator: " · "))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct NextLine: View {
    let item: TimedSegment
    let label: String

    var body: some View {
        HStack(spacing: 10) {
            Text(label)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Capsule()
                .fill(item.segment.tint)
                .frame(width: 4, height: 30)
            VStack(alignment: .leading, spacing: 0) {
                Text(item.segment.title)
                    .font(.subheadline.weight(.semibold))
                Text([Timetable.hhmm(item.segment.start), item.segment.place].filter { !$0.isEmpty }.joined(separator: " · "))
                    .font(.footnote.monospacedDigit())
                    .foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - The ten days

/* Each week gets a row of its own, marked ١ and ٢ in the gutter as the dock
   marks them. The published timetable numbers Week 1's columns and names
   Week 2's, so the rows carry 1-5 and Mon-Fri. */
struct DayPicker: View {
    @Binding var picked: Int?
    let shown: Int
    let today: Int?

    var body: some View {
        VStack(spacing: 6) {
            ForEach(0..<2, id: \.self) { week in
                HStack(spacing: 6) {
                    Text(Timetable.weekMarks[week])
                        .font(.title3)
                        .foregroundStyle(.secondary)
                        .frame(width: 24)
                        .accessibilityHidden(true)
                    ForEach(0..<5, id: \.self) { weekday in
                        dayButton(week * 5 + weekday)
                    }
                }
            }
        }
        .padding(10)
        .glassEffect(.regular, in: .rect(cornerRadius: 24))
    }

    private func dayButton(_ day: Int) -> some View {
        let week = day / 5, weekday = day % 5
        let isShown = day == shown
        return Button {
            withAnimation(.snappy) { picked = day }
        } label: {
            VStack(spacing: 3) {
                Text(week == 0 ? "\(weekday + 1)" : Timetable.dayNames[weekday])
                    .font(.subheadline.weight(isShown ? .bold : .regular))
                Circle()
                    .fill(day == today ? Color.yellow : .clear)
                    .frame(width: 5, height: 5)
            }
            .frame(maxWidth: .infinity, minHeight: 44)
            .foregroundStyle(isShown ? Color.primary : .secondary)
            .background {
                if isShown { Capsule().fill(.tint.opacity(0.2)) }
            }
            .contentShape(.capsule)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(Timetable.dayNames[weekday]), Week \(week + 1)")
        .accessibilityAddTraits(isShown ? .isSelected : [])
    }
}

/// One day, in order. When it is today, what's done is greyed back and the
/// block running now fills across as it runs down.
struct DayList: View {
    let day: Int
    let live: Bool
    let now: Date

    var body: some View {
        let cal = Timetable.calendar
        let minute = Double(cal.component(.hour, from: now) * 60 + cal.component(.minute, from: now))
            + Double(cal.component(.second, from: now)) / 60
        let line = Timetable.lines[day]
        VStack(spacing: 4) {
            if line.isEmpty {
                Text("Nothing on this day.")
                    .foregroundStyle(.secondary)
                    .padding()
            }
            ForEach(Array(line.enumerated()), id: \.offset) { _, segment in
                let isNow = live && Double(segment.start) <= minute && minute < Double(segment.end)
                let isDone = live && minute >= Double(segment.end)
                let progress = isNow ? (minute - Double(segment.start)) / Double(segment.minutes) : 0
                Group {
                    if segment.isLesson {
                        LessonRow(segment: segment, isNow: isNow, minutesLeft: Int((Double(segment.end) - minute).rounded(.up)))
                    } else {
                        GapRow(segment: segment)
                    }
                }
                .background(alignment: .leading) {
                    if isNow {
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 16).fill(segment.tint.opacity(0.08))
                            GeometryReader { geo in
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(segment.tint.opacity(0.22))
                                    .frame(width: max(16, geo.size.width * progress))
                            }
                        }
                    }
                }
                .opacity(isDone ? 0.45 : 1)
            }
        }
    }
}

/* The width of the time column down the left of a day, and the gap either
   side of the colour bar. Both grow with the text size in Settings, so a time
   is never broken over two lines and the rows stay in line with each other. */
struct RowMetrics: DynamicProperty {
    @ScaledMetric(relativeTo: .subheadline) var time: CGFloat = 54
    @ScaledMetric(relativeTo: .subheadline) var gap: CGFloat = 12
}

struct LessonRow: View {
    let segment: Segment
    let isNow: Bool
    let minutesLeft: Int
    var metrics = RowMetrics()

    var body: some View {
        HStack(alignment: .top, spacing: metrics.gap) {
            VStack(alignment: .trailing, spacing: 1) {
                Text(Timetable.hhmm(segment.start))
                    .font(.subheadline.weight(.semibold).monospacedDigit())
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                Text("\(segment.minutes) min")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            .frame(width: metrics.time, alignment: .trailing)
            RoundedRectangle(cornerRadius: 2)
                .fill(segment.tint)
                .frame(width: 4)
            VStack(alignment: .leading, spacing: 8) {
                ForEach(segment.lessons, id: \.self) { lesson in
                    VStack(alignment: .leading, spacing: 1) {
                        Text(lesson.name)
                            .font(.body.weight(.semibold))
                        let detail = [lesson.room, lesson.staff.joined(separator: ", ")].filter { !$0.isEmpty }
                        if !detail.isEmpty {
                            Text(detail.joined(separator: " · "))
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            Spacer(minLength: 0)
            if isNow {
                Text("\(minutesLeft) min")
                    .font(.footnote.weight(.semibold).monospacedDigit())
                    .foregroundStyle(segment.tint)
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .fixedSize(horizontal: false, vertical: true)
    }
}

struct GapRow: View {
    let segment: Segment
    var metrics = RowMetrics()

    var body: some View {
        HStack(spacing: metrics.gap) {
            Text(Timetable.hhmm(segment.start))
                .font(.footnote.monospacedDigit())
                .lineLimit(1)
                .frame(width: metrics.time, alignment: .trailing)
            Image(systemName: segment.symbol)
                .frame(width: 4)
            Text("\(segment.title) — \(segment.minutes) min")
            Spacer(minLength: 0)
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
    }
}

#Preview {
    ContentView()
}
