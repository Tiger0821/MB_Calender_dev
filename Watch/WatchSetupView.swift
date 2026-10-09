import SwiftUI

/* Setup on the wrist: the phone's, with what wants a keyboard taken out.
   Your form, then each set of classes that are on at the same time — so
   only one of them can be yours — then any SL revision that goes with what
   you picked, one question to a page. What it ends with is a Profile.

   It does not ask your name, which the watch shows nowhere, or what your
   clubs are called. Both are kept as they are, so a profile that came from
   the phone with them still has them when its classes are changed here. */
struct WatchSetupView: View {
    /// Called with the finished profile.
    let done: (Profile) -> Void

    @State private var draft: Profile
    @State private var step = 0

    init(existing: Profile?, done: @escaping (Profile) -> Void) {
        self.done = done
        _draft = State(initialValue: existing ?? Profile())
    }

    private enum Step: Hashable {
        case form, set(Int), revision
    }

    private var catalog: Catalog { Timetable.catalog(for: draft.form) }

    /// The pages still to come depend on the form, and on what is picked from it.
    private var steps: [Step] {
        var steps: [Step] = [.form]
        guard !draft.form.isEmpty else { return steps }
        steps += catalog.sets.indices.map { .set($0) }
        if !draft.revision.isEmpty { steps.append(.revision) }
        return steps
    }

    private var current: Step { steps[min(step, steps.count - 1)] }
    private var isLast: Bool { !draft.form.isEmpty && step >= steps.count - 1 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 6) {
                page
                bottomBar
            }
            .padding(.horizontal, 4)
        }
        // a page of its own for each question, so each opens at its top
        .id(current)
        .transition(.opacity)
    }

    private var bottomBar: some View {
        HStack(spacing: 6) {
            if step > 0 {
                Button {
                    go(to: step - 1)
                } label: {
                    Image(systemName: "chevron.left")
                }
                .accessibilityLabel("Back")
            }
            Button(isLast ? "Done" : "Next") {
                isLast ? done(draft) : go(to: step + 1)
            }
            .buttonStyle(.borderedProminent)
            .disabled(draft.form.isEmpty)
        }
        .padding(.top, 6)
    }

    private func go(to index: Int) {
        withAnimation(.snappy) { step = max(0, min(index, steps.count - 1)) }
    }

    // MARK: - The pages

    @ViewBuilder private var page: some View {
        switch current {
        case .form:
            question("Which form are you in?", "Each form has its own timetable.") {
                ForEach(TimetableData.forms, id: \.name) { form in
                    row(form.name, picked: draft.form == form.name) {
                        draft.pick(form: form.name)
                        go(to: step + 1)
                    }
                }
            }
        case .set(let index):
            let set = catalog.sets[index]
            // when every class in the set clashes with every other, it is one or none
            let oneOnly = set.allSatisfy { choice in choice.clashes.isSuperset(of: set.map(\.subject).filter { $0 != choice.subject }) }
            question(oneOnly ? "Which of these do you take?" : "Which of these are yours?",
                     oneOnly ? "They're on at the same time: one, or none."
                             : "Picking one drops any on at the same time.") {
                ForEach(set) { choice in
                    row(choice.name, picked: draft.subjects.contains(choice.subject), tint: Timetable.tint(for: choice.subject)) {
                        let adding = !draft.subjects.contains(choice.subject)
                        draft.toggle(choice)
                        if oneOnly && adding { go(to: step + 1) }
                    }
                }
                if oneOnly {
                    row("None of these", picked: set.allSatisfy { !draft.subjects.contains($0.subject) }) {
                        for choice in set where draft.subjects.contains(choice.subject) { draft.toggle(choice) }
                        go(to: step + 1)
                    }
                }
            }
        case .revision:
            question("Any SL revision?", "Leave them off if you don't go.") {
                ForEach(draft.revision) { choice in
                    row(choice.name, picked: draft.subjects.contains(choice.subject), tint: Timetable.tint(for: choice.subject)) {
                        draft.toggle(choice)
                    }
                }
            }
        }
    }

    private func question(_ title: String, _ detail: String, @ViewBuilder answers: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            // the pages after the form aren't known until it is picked
            Text("\(step + 1) of \(steps.count)")
                .font(.caption2.monospacedDigit())
                .foregroundStyle(.secondary)
            Text(title)
                .font(.headline)
                .fixedSize(horizontal: false, vertical: true)
            Text(detail)
                .font(.footnote)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.bottom, 4)
            answers()
        }
    }

    /// One answer: a name in its class's colour, and a mark when it is picked.
    private func row(_ title: String, picked: Bool, tint: Color? = nil, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 6) {
                if let tint {
                    RoundedRectangle(cornerRadius: 1.5)
                        .fill(tint)
                        .frame(width: 3, height: 20)
                }
                Text(title)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Spacer(minLength: 4)
                Image(systemName: picked ? "checkmark.circle.fill" : "circle")
                    .foregroundStyle(picked ? AnyShapeStyle(.tint) : AnyShapeStyle(.tertiary))
            }
        }
        .accessibilityAddTraits(picked ? .isSelected : [])
    }
}

#Preview("First time") {
    WatchSetupView(existing: nil) { _ in }
}
