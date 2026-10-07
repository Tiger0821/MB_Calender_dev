import SwiftUI

/* A few words set in pixels, to go with the pixel sky behind the app: each
   letter is a small grid of squares, drawn as squares, so it stays sharp at
   any size where a bitmap font scaled up would blur.

   It only knows the letters it has been asked for so far — the greeting on
   the watch's widget. A letter that is not in `glyphs` is left as a gap, so
   new wording needs its letters drawn here first. */
struct PixelText: View {
    let text: String
    /// The side of one square, in points. Two is four of the watch's own
    /// pixels, which is small enough to read as lettering and large enough
    /// to see the squares.
    var pixel: CGFloat = 2
    var colors: [Color] = [Color(red: 1.0, green: 0.92, blue: 0.45), Color(red: 1.0, green: 0.62, blue: 0.2)]

    var body: some View {
        let cells = Self.cells(for: text)
        PixelShape(cells: cells.lit, pixel: pixel)
            .fill(LinearGradient(colors: colors, startPoint: .top, endPoint: .bottom))
            .frame(width: CGFloat(cells.width) * pixel, height: CGFloat(Self.rows) * pixel)
            // the letters stand on the seventh row, so beside ordinary text
            // it lines up on that and lets the tails hang below
            .alignmentGuide(.firstTextBaseline) { $0[.bottom] - 2 * pixel }
            .alignmentGuide(.lastTextBaseline) { $0[.bottom] - 2 * pixel }
            .accessibilityLabel(text)
    }

    /// Seven rows for a capital, and two below the line for a tail.
    static let rows = 9

    /// Every lit square of the text, a column of space between letters.
    static func cells(for text: String) -> (lit: [(x: Int, y: Int)], width: Int) {
        var lit: [(x: Int, y: Int)] = []
        var x = 0
        for character in text {
            guard let glyph = glyphs[character] else {
                x += 3
                continue
            }
            for (y, row) in glyph.enumerated() {
                for (dx, mark) in row.enumerated() where mark == "#" {
                    lit.append((x + dx, y))
                }
            }
            x += (glyph.first?.count ?? 0) + 1
        }
        return (lit, max(0, x - 1))
    }

    static let glyphs: [Character: [String]] = [
        "G": [".###.",
              "#...#",
              "#....",
              "#.###",
              "#...#",
              "#...#",
              ".###.",
              ".....",
              "....."],
        "o": ["....",
              "....",
              ".##.",
              "#..#",
              "#..#",
              "#..#",
              ".##.",
              "....",
              "...."],
        "d": ["...#",
              "...#",
              ".###",
              "#..#",
              "#..#",
              "#..#",
              ".###",
              "....",
              "...."],
        "m": [".....",
              ".....",
              "##.#.",
              "#.#.#",
              "#.#.#",
              "#.#.#",
              "#.#.#",
              ".....",
              "....."],
        // three wide and not four: an arm reaching further left a hole
        // under it, and "mor ning" read as two words
        "r": ["...",
              "...",
              "#.#",
              "##.",
              "#..",
              "#..",
              "#..",
              "...",
              "..."],
        "n": ["....",
              "....",
              "###.",
              "#..#",
              "#..#",
              "#..#",
              "#..#",
              "....",
              "...."],
        "i": ["#",
              ".",
              "#",
              "#",
              "#",
              "#",
              "#",
              ".",
              "."],
        "g": ["....",
              "....",
              ".###",
              "#..#",
              "#..#",
              "#..#",
              ".###",
              "...#",
              ".##."],
    ]
}

/// The lit squares as one shape, so they fill as a piece.
private struct PixelShape: Shape {
    let cells: [(x: Int, y: Int)]
    let pixel: CGFloat

    func path(in rect: CGRect) -> Path {
        var path = Path()
        for cell in cells {
            path.addRect(CGRect(x: rect.minX + CGFloat(cell.x) * pixel, y: rect.minY + CGFloat(cell.y) * pixel,
                                width: pixel, height: pixel))
        }
        return path
    }
}
