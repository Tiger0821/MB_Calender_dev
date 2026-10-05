import SwiftUI

/* A column of boxes that can be rearranged by hand: touch and hold one and it
   lifts off the page, follows the finger, and the others slide out of its way;
   let go and it settles into the gap. The order lives with the caller, so it
   can be saved.

   What moves under the finger is a copy drawn over the column. The real box
   stays in the layout, invisible, holding the gap open — so the column
   reflows by ordinary layout, and the copy never has to chase it.

   The boxes can be very different heights (the timetable is several times the
   day picker), and the column can be longer than the screen. So a box changes
   places when its leading edge passes the middle of its neighbour, rather
   than middle past middle, and holding it near the top or bottom of the
   screen scrolls the page under it. */
struct ReorderableStack<ID: Hashable, Content: View>: View {
    @Binding var order: [ID]
    var spacing: CGFloat = 18
    /// The scroll view the column sits in, if it should scroll while a box is
    /// held at its edge.
    var scroller: Scroller?
    @ViewBuilder var content: (ID) -> Content

    /// Where each box sits, in the column's own coordinates.
    @State private var frames: [ID: CGRect] = [:]
    @State private var lift: Lift?
    @State private var raised = false

    private struct Lift {
        let id: ID
        /// The box's frame when it was picked up.
        let frame: CGRect
        /// Where the finger was at that moment, on screen, and how far it has
        /// moved since.
        let touch: CGPoint
        var moved = CGSize.zero
        /// How far the page was scrolled when it was picked up, and now. The
        /// page only moves under a lifted box when this view scrolls it, so
        /// the difference is exactly how far the box has been carried.
        let startOffset: CGFloat
        var offset: CGFloat
        /// Set on letting go: the gap the copy flies back to.
        var landing: CGRect?

        /// The top edge of the copy, in the column's coordinates.
        var top: CGFloat { frame.minY + moved.height + offset - startOffset }
    }

    private let space = "reorderable-stack"

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: spacing) {
                ForEach(order, id: \.self) { id in
                    content(id)
                        .opacity(lift?.id == id ? 0 : 1)
                        .overlay {
                            if lift?.id == id {
                                RoundedRectangle(cornerRadius: 26)
                                    .strokeBorder(.tertiary, style: StrokeStyle(lineWidth: 1.5, dash: [6, 6]))
                            }
                        }
                        .onGeometryChange(for: CGRect.self) { proxy in
                            proxy.frame(in: .named(space))
                        } action: { frame in
                            frames[id] = frame
                        }
                        // the whole box takes the touch, not just the text in it
                        .contentShape(.rect(cornerRadius: 26))
                        .gesture(HoldAndDrag { state, point in
                            handle(id, state, point)
                        })
                }
            }

            if let lift {
                let origin = origin(of: lift)
                content(lift.id)
                    .frame(width: lift.frame.width, height: lift.frame.height)
                    .scaleEffect(raised ? 1.03 : 1)
                    .shadow(color: .black.opacity(raised ? 0.22 : 0), radius: 22, y: 10)
                    .offset(x: origin.x, y: origin.y)
                    .allowsHitTesting(false)
                    .onAppear {
                        withAnimation(.snappy(duration: 0.2)) { raised = true }
                    }
            }
        }
        .coordinateSpace(.named(space))
        .sensoryFeedback(.impact(weight: .medium), trigger: lift?.id)
        .sensoryFeedback(.selection, trigger: order)
        // while a box is in the air, keep checking whether it is being held
        // at an edge — a finger held still sends nothing to react to
        .task(id: lift?.id) {
            guard lift != nil else { return }
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(16))
                scrollAtEdge()
            }
        }
    }

    private func origin(of lift: Lift) -> CGPoint {
        if let landing = lift.landing { return landing.origin }
        // it travels up and down with the finger, and only leans sideways
        return CGPoint(x: lift.frame.minX + lift.moved.width * 0.15, y: lift.top)
    }

    private func handle(_ id: ID, _ state: UIGestureRecognizer.State, _ point: CGPoint) {
        switch state {
        case .began:
            guard let frame = frames[id] else { return }
            let offset = scroller?.offset ?? 0
            raised = false
            lift = Lift(id: id, frame: frame, touch: point, startOffset: offset, offset: offset)
        case .changed:
            guard let current = lift, current.id == id, current.landing == nil else { return }
            lift?.moved = CGSize(width: point.x - current.touch.x, height: point.y - current.touch.y)
            makeWay()
        case .ended, .cancelled, .failed:
            guard lift?.id == id, lift?.landing == nil else { return }
            drop()
        default:
            break
        }
    }

    /// Moves the gap to where the lifted box now belongs: up past every box
    /// whose middle its top edge has crossed, or down past every box whose
    /// middle its bottom edge has.
    private func makeWay() {
        guard let lift, let from = order.firstIndex(of: lift.id) else { return }
        let top = lift.top, bottom = lift.top + lift.frame.height
        var to = from
        while to > 0, let above = frames[order[to - 1]], top < above.midY { to -= 1 }
        if to == from {
            while to < order.count - 1, let below = frames[order[to + 1]], bottom > below.midY { to += 1 }
        }
        guard to != from else { return }
        withAnimation(.snappy(duration: 0.3)) {
            order.move(fromOffsets: IndexSet(integer: from), toOffset: to > from ? to + 1 : to)
        }
    }

    /// Scrolls the page a step when the lifted box is being held near the top
    /// or bottom of the screen — faster the nearer the edge — and carries the
    /// box along so it stays under the finger. Only once the finger has
    /// actually headed that way: picking up a box that happens to sit at an
    /// edge shouldn't set the page moving.
    private func scrollAtEdge() {
        guard let scroller, let lift, lift.landing == nil else { return }
        let finger = lift.touch.y + lift.moved.height
        let reach: CGFloat = 110, fastest: CGFloat = 14
        let top = scroller.frame.minY + 60, bottom = scroller.frame.maxY
        var step: CGFloat = 0
        if lift.moved.height < -12, finger < top + reach {
            step = -min(1, (top + reach - finger) / reach) * fastest
        } else if lift.moved.height > 12, finger > bottom - reach {
            step = min(1, (finger - (bottom - reach)) / reach) * fastest
        }
        let target = min(max(lift.offset + step, scroller.range.lowerBound), scroller.range.upperBound)
        guard abs(target - lift.offset) > 0.5 else { return }
        scroller.scrollTo(target)
        self.lift?.offset = target
        makeWay()
    }

    /// The copy flies to the gap, and only then gives way to the real box.
    private func drop() {
        guard let id = lift?.id else { return }
        withAnimation(.snappy(duration: 0.28)) {
            lift?.landing = frames[id] ?? lift?.frame
            raised = false
        } completion: {
            // a box picked up again in the meantime has no landing yet
            if lift?.landing != nil { lift = nil }
        }
    }
}

/* What a ReorderableStack needs to know about the scroll view around it, and
   the one thing it needs to do to it. A plain object rather than view state:
   it is written on every frame of scrolling, and nothing should redraw for
   that. */
final class Scroller {
    /// How far the page is scrolled, and how far it can be either way.
    var offset: CGFloat = 0
    var range: ClosedRange<CGFloat> = 0...0
    /// The scroll view's frame on screen.
    var frame = CGRect.zero
    var scrollTo: (CGFloat) -> Void = { _ in }
}

/* A long press that keeps reporting where the finger is once it has been
   recognised. UIKit's recogniser is used rather than SwiftUI's long-press-
   then-drag because it leaves the scroll view alone: a swipe still scrolls
   the page, and only a finger held still lifts a box. */
struct HoldAndDrag: UIGestureRecognizerRepresentable {
    let action: (UIGestureRecognizer.State, CGPoint) -> Void

    func makeUIGestureRecognizer(context: Context) -> UILongPressGestureRecognizer {
        let recognizer = UILongPressGestureRecognizer()
        recognizer.minimumPressDuration = 0.35
        return recognizer
    }

    func handleUIGestureRecognizerAction(_ recognizer: UILongPressGestureRecognizer, context: Context) {
        // the window's coordinates stay put while the boxes move
        action(recognizer.state, recognizer.location(in: nil))
    }
}
