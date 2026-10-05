import SwiftUI

/* How each block looks, shared by the app and the widgets so a subject is the
   same colour everywhere. */
extension Timetable {
    static func tint(for subject: String) -> Color {
        switch subject {
        case let s where s.hasPrefix("DP Chi"): .red
        case "DP Eng B-2": .blue
        case "Eng Lit": .indigo
        case let s where s.hasPrefix("DP MA"): .orange
        case "DP Comp. Sc.": .teal
        case "DP Econ": .green
        case "DP Bus Man": .mint
        case let s where s.hasPrefix("DP TOK"): .purple
        case core: .gray
        case let s where s.hasPrefix("G:") || s == "Guidance": .brown
        default: .pink   // the clubs
        }
    }

    /// A name for tight spaces: "G: Weekly Alignment" is "Weekly Alignment".
    static func shortName(_ subject: String) -> String {
        var s = displayName(subject)
        if s.hasPrefix("G: ") { s = String(s.dropFirst(3)) }
        if let bracket = s.firstIndex(of: "[") { s = String(s[..<bracket]).trimmingCharacters(in: .whitespaces) }
        return s
    }
}

extension Segment {
    var tint: Color {
        switch kind {
        case .lessons(let items): Timetable.tint(for: items[0].subject)
        case .gap(let label): label == "Lunch" ? .yellow : .gray
        }
    }

    var shortTitle: String {
        switch kind {
        case .lessons(let items): items.map { Timetable.shortName($0.subject) }.joined(separator: " or ")
        case .gap(let label): label
        }
    }

    var symbol: String {
        switch kind {
        case .lessons(let items) where items[0].subject == Timetable.core: "graduationcap"
        case .lessons: "book.closed"
        case .gap("Lunch"): "fork.knife"
        case .gap("Break"): "cup.and.saucer"
        case .gap: "leaf"
        }
    }
}
