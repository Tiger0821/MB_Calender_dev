import ActivityKit
import Foundation

/* The school day as a Live Activity: the class you're in, the time left in
   it, and what's next — on the Lock Screen and in the Dynamic Island.

   A Live Activity can't be handed a timeline the way a widget can; its
   content only changes when the app updates it, and the app isn't running
   during the school day. So the whole day goes in up front, as attributes,
   and the view lays every block out at once and lets the clock uncover them
   in turn (see TimeSwitch in the widget). Nothing has to be updated after it
   starts. */
struct ClassActivityAttributes: ActivityAttributes {
    /// Nothing changes once the day is laid out.
    struct ContentState: Codable, Hashable {
        var revision = 0
    }

    /// One stretch of the day: a class, or the gap between two.
    struct Block: Codable, Hashable {
        var title: String
        var place: String
        var start: Date
        var end: Date
        var isLesson: Bool
        /// The subject, or the gap's name, for its colour.
        var tint: String
        /// A few letters for the Dynamic Island.
        var short: String
    }

    /// "Mon · Week 2"
    var day: String
    var blocks: [Block]
    /// When the activity was made, which the wait for the first bell counts from.
    var made: Date

    /// The first class at or after `index`, to show as what's next.
    func lesson(after index: Int) -> Block? {
        blocks.dropFirst(index + 1).first(where: \.isLesson)
    }
}

extension ClassActivityAttributes {
    /// The day `date` falls on, or nil when there is no school.
    init?(day date: Date, made: Date = .now) {
        let segments = Timetable.day(of: date)
        guard let first = segments.first else { return nil }
        self.day = "\(Timetable.dayNames[first.cycleDay % 5]) · Week \(first.cycleDay / 5 + 1)"
        self.made = made
        self.blocks = segments.map { item in
            let segment = item.segment
            return Block(title: segment.shortTitle, place: segment.place, start: item.start, end: item.end,
                         isLesson: segment.isLesson,
                         tint: segment.lessons.first?.subject ?? segment.title,
                         short: segment.abbreviation)
        }
    }
}
