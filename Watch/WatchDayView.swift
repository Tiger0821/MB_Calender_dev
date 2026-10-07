import SwiftUI

/* The day on the watch: the phone's page with everything taken off it that
   the watch has no room for, or already says. No date and no clock — the
   watch has its own at the top of the screen — no teachers, no holiday, no
   picker. What is left is each class with the time it starts and its room,
   the breaks between them, and behind it all the same sky.

   It follows the clock, as the phone's does: today until the last bell, and
   after that the next school day, which is then named at the top since it is
   not the day the watch is showing the time of. */
struct WatchDayView: View {
    let profile: Profile?
    @State private var weather = WeatherModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        TimelineView(.everyMinute) { context in
            let now = context.date
            let snapshot = Timetable.snapshot(at: now)
            ScrollViewReader { reader in
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        if profile == nil {
                            Text("Open Timetable on your iPhone to choose your classes.")
                                .font(.footnote)
                                .padding(10)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(.black.opacity(0.4), in: .rect(cornerRadius: 12))
                        } else if snapshot.day.isEmpty {
                            Text("No classes")
                                .font(.headline)
                        } else {
                            if !snapshot.isToday {
                                Text(snapshot.dayLabel)
                                    .font(.footnote.weight(.semibold))
                                    .foregroundStyle(.white.opacity(0.8))
                                    .padding(.leading, 6)
                            }
                            ForEach(snapshot.day) { item in
                                WatchRow(item: item, isOn: item.contains(now), isOver: item.end <= now, now: now)
                                    .id(item.id)
                            }
                        }
                    }
                    .padding(.horizontal, 4)
                }
                // open on the class that is on, not on the morning
                .onAppear {
                    if let current = snapshot.current { reader.scrollTo(current.id, anchor: .center) }
                }
            }
            .background { sky(at: now) }
        }
        .task { await weather.refresh() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await weather.refresh() } }
        }
    }

    /// The sky as it is outside; a plain dusk until the weather is known.
    @ViewBuilder
    private func sky(at now: Date) -> some View {
        if let current = weather.current {
            PixelSky(scene: SkyScene(sky: current.sky, phase: current.phase(at: now), wind: current.wind),
                     // the sun or moon in the corner the clock leaves free
                     window: CGRect(x: 0, y: 28, width: 120, height: 40))
                // dimmed, so the rows read over a bright noon
                .overlay(Color.black.opacity(0.25).ignoresSafeArea())
        } else {
            LinearGradient(colors: [Color(red: 0.1, green: 0.16, blue: 0.3), .black], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        }
    }
}

/// One stretch of the day: a class with its start and its room, or a break.
struct WatchRow: View {
    let item: TimedSegment
    let isOn: Bool
    let isOver: Bool
    let now: Date

    var body: some View {
        let segment = item.segment
        if segment.isLesson {
            let tint = Timetable.tint(for: segment.lessons.first?.subject ?? "")
            HStack(alignment: .top, spacing: 6) {
                Text(Timetable.hhmm(item.start))
                    .font(.system(size: 13, weight: .semibold).monospacedDigit())
                    .frame(width: 40, alignment: .leading)
                RoundedRectangle(cornerRadius: 1.5)
                    .fill(tint)
                    .frame(width: 3)
                VStack(alignment: .leading, spacing: 1) {
                    Text(segment.shortTitle)
                        .font(.system(size: 15, weight: .semibold))
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                    if !segment.place.isEmpty {
                        Text(segment.place)
                            .font(.system(size: 12))
                            .foregroundStyle(.white.opacity(0.7))
                            .lineLimit(1)
                    }
                    if isOn {
                        // the system counts it down between the minute's redraws
                        Text("\(Text(timerInterval: now...item.end, countsDown: true)) left")
                            .font(.system(size: 12, weight: .semibold).monospacedDigit())
                            .foregroundStyle(tint)
                    }
                }
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.black.opacity(isOn ? 0.6 : 0.38), in: .rect(cornerRadius: 12))
            .overlay {
                if isOn { RoundedRectangle(cornerRadius: 12).strokeBorder(tint, lineWidth: 1.5) }
            }
            .opacity(isOver ? 0.5 : 1)
        } else {
            HStack(spacing: 6) {
                Text(Timetable.hhmm(item.start))
                    .font(.system(size: 11).monospacedDigit())
                    .frame(width: 40, alignment: .leading)
                Image(systemName: segment.title == "Lunch" ? "fork.knife" : "cup.and.saucer")
                    .font(.system(size: 10))
                Text("\(segment.title) · \(segment.minutes) min")
                    .font(.system(size: 11))
                    .lineLimit(1)
            }
            .foregroundStyle(.white.opacity(isOn ? 0.95 : 0.6))
            .padding(.horizontal, 8)
            .padding(.vertical, 1)
            .opacity(isOver ? 0.5 : 1)
        }
    }
}
