import Foundation

/* Picking classes, as setup does it. The phone asks its questions on one
   kind of page and the watch on another, but what a pick does to the profile
   is the same on both, and is here so that it stays the same. */
extension Profile {
    /// The revision classes that go with what has been picked so far.
    var revision: [Catalog.Choice] {
        Timetable.catalog(for: form).revision.filter { subjects.contains($0.key) }.flatMap(\.value).sorted { $0.subject < $1.subject }
    }

    mutating func pick(form new: String) {
        guard new != form else { return }
        form = new
        // what the other form offered may not be on this one's timetable
        subjects.formIntersection(Timetable.catalog(for: new).choices.map(\.subject))
    }

    /// Pick a class, dropping any picked ones that are on at the same time;
    /// or put it back. Revision goes when the class it is for does.
    mutating func toggle(_ choice: Catalog.Choice) {
        if subjects.contains(choice.subject) {
            subjects.remove(choice.subject)
        } else {
            subjects.subtract(choice.clashes)
            subjects.insert(choice.subject)
        }
        for (parent, extras) in Timetable.catalog(for: form).revision where !subjects.contains(parent) {
            subjects.subtract(extras.map(\.subject))
        }
    }
}
