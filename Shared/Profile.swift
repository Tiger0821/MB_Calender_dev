import Foundation

/* Whose timetable this is: a name, a form, and the classes picked from what
   that form is offered. Setup asks for it the first time the app is opened,
   and again whenever the name under the clock is tapped. It is kept in the
   app group's defaults, where the widgets can read it too. */
struct Profile: Codable, Hashable {
    var name = ""
    /// "11A" or "11B": one of TimetableData.forms.
    var form = ""
    /// The classes taken, by the names the timetable gives them. Guidance
    /// and the clubs are everyone's and are not listed.
    var subjects: Set<String> = []
    var clubs: [Club] = []

    /* The timetable only says "Service Clubs" and "Academic Clubs", so which
       club is yours is filled in here. `week` is 0 for Week 1 only, 1 for
       Week 2 only, nil for both. */
    struct Club: Codable, Hashable {
        var subject: String
        var week: Int?
        var name: String
        var room = ""
        var staff = ""
    }

    /// The app group the app and its widgets share. It is named again in the
    /// two .entitlements files; if the bundle ids change, change all three.
    static let group = "group.com.tigercho.ManageBacTimetable"

    private static let key = "profile"
    private static var defaults: UserDefaults { UserDefaults(suiteName: group) ?? .standard }

    static func load() -> Profile? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(Profile.self, from: data)
    }

    func save() {
        Self.defaults.set(try? JSONEncoder().encode(self), forKey: Self.key)
    }
}
