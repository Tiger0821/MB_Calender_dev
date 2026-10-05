import SwiftUI

/// A holiday's count in a line: "21 days", "Today", or — under a day away —
/// the hours, minutes and seconds running down. Shared by the app and the
/// widgets; the system keeps the clock ticking in both.
struct CountdownLabel: View {
    let countdown: Countdown
    let now: Date

    var body: some View {
        switch countdown {
        case .today: Text("Today")
        case .timer(let start): Text(timerInterval: now...start, countsDown: true)
        case .days(let days): Text("\(days) days")
        }
    }
}
