import SwiftUI

/* The sky behind the page, as pixel art, filling the background with the
   weather outside the way Weather does: sun or moon, stars, clouds on the
   wind, rain, snow, fog and lightning, over a line of hills. It is painted
   small — one pixel of it is about four and a half points across — into a
   frame of plain bytes fifteen times a second, then scaled up unsmoothed so
   every pixel stays square. Nothing here is an image file; each scene is
   worked out from the weather and the clock. */

/// What to paint.
struct SkyScene: Equatable {
    var sky: Sky
    var phase: DayPhase
    /// km/h: pushes the clouds along and leans the rain.
    var wind: Double
}

// MARK: - Pixels

/// One pixel, its bytes in the order the image reads them.
struct Pixel: Equatable {
    var r: UInt8
    var g: UInt8
    var b: UInt8
    var spare: UInt8 = 255

    init(r: UInt8, g: UInt8, b: UInt8) {
        self.r = r
        self.g = g
        self.b = b
    }

    init(_ hex: UInt32) {
        self.init(r: UInt8(hex >> 16 & 0xFF), g: UInt8(hex >> 8 & 0xFF), b: UInt8(hex & 0xFF))
    }

    /// Part of the way towards another colour.
    func mixed(_ other: Pixel, _ amount: Double) -> Pixel {
        let t = min(1, max(0, amount))
        func mix(_ from: UInt8, _ to: UInt8) -> UInt8 { UInt8((Double(from) + (Double(to) - Double(from)) * t).rounded()) }
        return Pixel(r: mix(r, other.r), g: mix(g, other.g), b: mix(b, other.b))
    }
}

/// The frame the sky is painted into. Writes that land off its edges are dropped.
struct PixelCanvas {
    let width: Int
    let height: Int
    private var pixels: [Pixel]

    init(width: Int, height: Int) {
        self.width = width
        self.height = height
        pixels = Array(repeating: Pixel(0), count: width * height)
    }

    subscript(x: Int, y: Int) -> Pixel {
        get { pixels[y * width + x] }
        set {
            if x >= 0, x < width, y >= 0, y < height { pixels[y * width + x] = newValue }
        }
    }

    /// Lay a colour over what is there, part way.
    mutating func blend(_ x: Int, _ y: Int, _ color: Pixel, _ amount: Double) {
        guard x >= 0, x < width, y >= 0, y < height else { return }
        pixels[y * width + x] = pixels[y * width + x].mixed(color, amount)
    }

    var image: CGImage? {
        let data = pixels.withUnsafeBytes { Data($0) }
        guard let provider = CGDataProvider(data: data as CFData) else { return nil }
        return CGImage(width: width, height: height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: width * 4,
                       space: CGColorSpace(name: CGColorSpace.sRGB)!,
                       bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue),
                       provider: provider, decode: nil, shouldInterpolate: false, intent: .defaultIntent)
    }
}

/// A fixed scatter: the same number, from 0 up to 1, every time for the same
/// seed. It puts each star, cloud and raindrop where it was last frame.
private func scatter(_ seed: Int) -> Double {
    var x = UInt64(truncatingIfNeeded: seed) &* 0x9E37_79B9_7F4A_7C15
    x ^= x >> 31
    x &*= 0xBF58_476D_1CE4_E5B9
    x ^= x >> 29
    return Double(x >> 11) / Double(1 << 53)
}

/// The ordered-dither pattern: a threshold from 0 to 1 for each pixel, in a
/// four by four tile. Stippling one colour into the next against it is what
/// keeps the sky to a few flat colours.
private let ditherTile: [Double] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5].map { ($0 + 0.5) / 16 }

private func threshold(_ x: Int, _ y: Int) -> Double {
    ditherTile[(y & 3) * 4 + (x & 3)]
}

// MARK: - Colours

private enum Mood {
    case fair, grey, wet, snow
}

private extension Sky {
    var mood: Mood {
        switch self {
        case .clear, .mostlyClear, .partlyCloudy: .fair
        case .overcast, .fog, .drizzle: .grey
        case .rain, .heavyRain, .thunderstorm: .wet
        case .snow: .snow
        }
    }
}

/* The top of every sky is dark enough for the date to be read in white over
   it; the pale colours are kept to the horizon, behind the boxes. */
private struct SkyPalette {
    /// The top of the sky, the middle, and the horizon.
    let sky: [Pixel]
    /// A cloud's lit rim, its body, and its underside.
    let cloud: [Pixel]
    /// The far hills, the near ones, and the pines on them.
    let land: [Pixel]

    init(_ scene: SkyScene) {
        let hex: [UInt32] = switch (scene.sky.mood, scene.phase) {
        case (.fair, .day): [0x1B58A6, 0x3D84D6, 0x8FC6F2, 0xFFFFFF, 0xE6F0FA, 0xB4CBE4, 0x3E8E5C, 0x2E7049, 0x1F5236]
        case (.fair, .twilight): [0x2A2D72, 0xB0567C, 0xF6A65E, 0xFFE3C7, 0xF0B4A3, 0xB07397, 0x4A3B6B, 0x33284F, 0x231B39]
        case (.fair, .night): [0x060A22, 0x101843, 0x242D66, 0x55608F, 0x3A4472, 0x262E55, 0x141F3A, 0x0D1528, 0x080E1C]
        case (.grey, .day): [0x4A5A6E, 0x6F8196, 0xA9B7C4, 0xD5DCE4, 0xB4BECA, 0x8D99A8, 0x4F6B5C, 0x3C5548, 0x2B3F35]
        case (.grey, .twilight): [0x3A3550, 0x6D5A70, 0xB08A84, 0xC9B4B8, 0xA08C98, 0x74667A, 0x3D3550, 0x2B2640, 0x1D1A2E]
        case (.grey, .night): [0x0C1018, 0x1A212E, 0x2D3644, 0x3A4352, 0x2A3240, 0x1C222D, 0x121A22, 0x0C1218, 0x070B10]
        case (.wet, .day): [0x2F3B4D, 0x4A5A70, 0x74869B, 0x8A97A8, 0x6B788A, 0x4E596A, 0x3A5247, 0x2A3D34, 0x1D2B25]
        case (.wet, .twilight): [0x29283D, 0x47435C, 0x766A7A, 0x7A7388, 0x5A546A, 0x3F3B4E, 0x2C2A3E, 0x1F1D2E, 0x151420]
        case (.wet, .night): [0x070A12, 0x111722, 0x222B3A, 0x2C3442, 0x1F2632, 0x151A24, 0x0E141B, 0x090E13, 0x05080C]
        case (.snow, .day): [0x5C6F8A, 0x8CA0BA, 0xCBD8E6, 0xF4F7FB, 0xDCE4EE, 0xB6C2D2, 0xF1F5FA, 0xD5DFEA, 0x3A5247]
        case (.snow, .twilight): [0x3B3A5E, 0x7A6F8E, 0xC7A9A8, 0xE6D9DE, 0xC2B2C0, 0x8F829A, 0xE3DCE6, 0xC1B8CC, 0x3A3550]
        case (.snow, .night): [0x0E1424, 0x1E2A45, 0x3A4A6C, 0x4A5878, 0x36425F, 0x252E47, 0xAEBBD3, 0x8494B3, 0x1A2438]
        }
        let colors = hex.map { Pixel($0) }
        sky = Array(colors[0..<3])
        cloud = Array(colors[3..<6])
        land = Array(colors[6..<9])
    }
}

// MARK: - Clouds

/// A cloud as a small tile of tones: 0 for nothing, then 1 its lit rim, 2 its
/// body and 3 its underside.
private struct CloudSprite {
    let width: Int
    let height: Int
    let tones: [UInt8]

    /// Small, middling and large.
    static let all = [CloudSprite(width: 14, height: 7, seed: 1), CloudSprite(width: 22, height: 10, seed: 2),
                      CloudSprite(width: 32, height: 13, seed: 3)]

    /// A row of round puffs, biggest in the middle, cut off flat underneath.
    init(width: Int, height: Int, seed: Int) {
        let count = max(3, width / 6)
        var puffs: [(x: Double, y: Double, r: Double)] = []
        for i in 0..<count {
            let along = Double(i) / Double(count - 1)
            let r = (0.26 + 0.28 * sin(along * .pi) + 0.08 * scatter(seed * 50 + i)) * Double(height)
            puffs.append((x: 0.5 + r + along * (Double(width) - 1 - 2 * r), y: Double(height) - 0.55 * r, r: r))
        }
        func inside(_ x: Int, _ y: Int) -> Bool {
            guard x >= 0, x < width, y >= 0, y < height else { return false }
            // a slab along the bottom closes the gaps between the puffs, its last row a little shorter
            let inset = y == height - 1 ? 3 : 2
            if y >= height - 3, x >= inset, x < width - inset { return true }
            return puffs.contains { puff in
                let dx = Double(x) + 0.5 - puff.x, dy = Double(y) + 0.5 - puff.y
                return dx * dx + dy * dy <= puff.r * puff.r
            }
        }
        var tones = [UInt8](repeating: 0, count: width * height)
        for y in 0..<height {
            for x in 0..<width where inside(x, y) {
                tones[y * width + x] = !inside(x, y - 1) ? 1 : !inside(x, y + 1) || !inside(x, y + 2) ? 3 : 2
            }
        }
        self.width = width
        self.height = height
        self.tones = tones
    }
}

// MARK: - The painter

struct SkyPainter {
    let scene: SkyScene
    let width: Int
    let height: Int
    /// The middle of the sun or moon.
    let bodyX: Int
    let bodyY: Int
    /// The first row the clouds may use, so they stay out from behind the date.
    let cloudTop: Int
    /// Painted once and left as it is: no lightning.
    var still = false

    func paint(at time: Double) -> PixelCanvas {
        let palette = SkyPalette(scene)
        var canvas = PixelCanvas(width: width, height: height)
        paintSky(&canvas, palette)
        if scene.sky.mood == .fair {
            if scene.phase == .night {
                paintStars(&canvas, time)
                paintMoon(&canvas)
            } else {
                paintSun(&canvas, time)
            }
        }
        paintClouds(&canvas, palette, time)
        paintHills(&canvas, palette)
        switch scene.sky {
        case .fog:
            paintFog(&canvas, time)
        case .drizzle, .rain, .heavyRain:
            paintRain(&canvas, time)
        case .thunderstorm:
            paintRain(&canvas, time)
            if !still { paintLightning(&canvas, time) }
        case .snow:
            paintSnow(&canvas, time)
        default:
            break
        }
        return canvas
    }

    /// Sixteen flat bands from the top colour through the middle to the
    /// horizon, the lower part of each stippled into the next.
    private func paintSky(_ canvas: inout PixelCanvas, _ palette: SkyPalette) {
        let bands = 16
        let shades = (0..<bands).map { band -> Pixel in
            let t = Double(band) / Double(bands - 1)
            return t < 0.5 ? palette.sky[0].mixed(palette.sky[1], t * 2) : palette.sky[1].mixed(palette.sky[2], t * 2 - 1)
        }
        for y in 0..<height {
            let along = Double(y) / Double(max(1, height - 1)) * Double(bands - 1)
            let band = min(Int(along), bands - 2)
            let into = along - Double(band)
            for x in 0..<width {
                canvas[x, y] = shades[into > 0.4 + 0.6 * threshold(x, y) ? band + 1 : band]
            }
        }
    }

    private func paintStars(_ canvas: inout PixelCanvas, _ time: Double) {
        let star = Pixel(0xE8ECFF)
        let thinning = scene.sky == .partlyCloudy ? 300 : 150
        for i in 0..<(width * height / thinning) {
            let x = Int(scatter(i * 4 + 1) * Double(width))
            let y = Int(scatter(i * 4 + 2) * Double(height) * 0.75)
            let twinkle = sin(time * (0.5 + 1.5 * scatter(i * 4 + 3)) + scatter(i * 4 + 4) * 2 * .pi)
            if twinkle < -0.6 { continue }   // winks out for a moment
            let big = i % 9 == 0
            canvas.blend(x, y, star, big ? 1 : 0.5 + 0.3 * twinkle)
            if big && twinkle > 0.3 {
                for (dx, dy) in [(-1, 0), (1, 0), (0, -1), (0, 1)] { canvas.blend(x + dx, y + dy, star, 0.35) }
            }
        }
    }

    /// A disc in three tones with a stippled glow, and by day eight rays, the
    /// long ones and the short ones swapping places. At twilight it is low and
    /// orange and has none.
    private func paintSun(_ canvas: inout PixelCanvas, _ time: Double) {
        let low = scene.phase == .twilight
        let core = Pixel(low ? 0xFFD9A0 : 0xFFF6C2), body = Pixel(low ? 0xFF9A4A : 0xFFD94A)
        // the glow is the sky's own colour lifted, since yellow stippled over blue only goes grey
        let rim = Pixel(low ? 0xF2673A : 0xFFB52E), glow = Pixel(low ? 0xFFC08A : 0xBFE1FF)
        let r = 7, reach = 15
        for dy in -reach...reach {
            for dx in -reach...reach {
                let x = bodyX + dx, y = bodyY + dy
                let d2 = dx * dx + dy * dy
                if d2 <= r * r + r {
                    // the highlight sits up and to the left
                    let lit = (dx + 2) * (dx + 2) + (dy + 2) * (dy + 2)
                    canvas[x, y] = lit <= 10 ? core : d2 <= (r - 1) * (r - 1) ? body : rim
                } else {
                    let fade = 1 - (Double(d2).squareRoot() - Double(r)) / Double(reach - r)
                    if fade > threshold(x, y) { canvas.blend(x, y, glow, 0.3) }
                }
            }
        }
        guard !low else { return }
        let beat = Int(time / 0.8) % 2
        let ray = Pixel(0xFFE27A)
        for k in 0..<8 {
            let angle = Double(k) * .pi / 4
            for step in (r + 3)..<(r + (k % 2 == beat ? 7 : 5)) {
                canvas[bodyX + Int((cos(angle) * Double(step)).rounded()), bodyY + Int((sin(angle) * Double(step)).rounded())] = ray
            }
        }
    }

    /// A crescent: a disc with a second one, up and to the right, bitten out of it.
    private func paintMoon(_ canvas: inout PixelCanvas) {
        let body = Pixel(0xF2EFD8), shade = Pixel(0xCFCBB0), glow = Pixel(0xAEB9E8)
        let r = 6, reach = 14
        for dy in -reach...reach {
            for dx in -reach...reach {
                let x = bodyX + dx, y = bodyY + dy
                let d2 = dx * dx + dy * dy
                let bite = (dx - 4) * (dx - 4) + (dy + 3) * (dy + 3)
                if d2 <= r * r + r {
                    if bite > 30 { canvas[x, y] = bite < 46 ? shade : body }
                } else {
                    let fade = 1 - (Double(d2).squareRoot() - Double(r)) / Double(reach - r)
                    if fade * 0.7 > threshold(x, y) { canvas.blend(x, y, glow, 0.22) }
                }
            }
        }
    }

    private func paintClouds(_ canvas: inout PixelCanvas, _ palette: SkyPalette, _ time: Double) {
        let count: Int
        switch scene.sky {
        case .clear: count = 0
        case .mostlyClear: count = 2
        case .partlyCloudy, .fog: count = 5
        case .drizzle, .rain, .snow: count = 11
        case .overcast, .heavyRain, .thunderstorm: count = 14
        }
        // the rows the clouds ride in, counted down from the first they may use: two
        // in the strip of open sky under the date, the rest behind the boxes
        let lanes = [1, 12, 27, 42, 58, 76]
        let sizes = count > 5 ? [2, 1, 2, 2, 1, 0] : [1, 0, 2, 1, 0]
        let push = min(4, 0.6 + scene.wind / 15)
        for i in 0..<count {
            let sprite = CloudSprite.all[sizes[i % sizes.count]]
            let top = cloudTop + lanes[i % lanes.count] + Int(scatter(i * 5 + 1) * 3)
            let speed = (0.5 + 0.9 * scatter(i * 5 + 2)) * push
            // off the right edge, round again from the left
            let span = Double(width + sprite.width + 12)
            let left = Int((scatter(i * 5 + 3) * span + time * speed).truncatingRemainder(dividingBy: span)) - sprite.width
            for row in 0..<sprite.height {
                for col in 0..<sprite.width {
                    let tone = sprite.tones[row * sprite.width + col]
                    if tone > 0 { canvas[left + col, top + row] = palette.cloud[Int(tone) - 1] }
                }
            }
        }
    }

    /// Two ridges along the bottom, and a few pines on the nearer one.
    private func paintHills(_ canvas: inout PixelCanvas, _ palette: SkyPalette) {
        let tall = Double(height)
        func far(_ x: Int) -> Int { max(0, Int(0.075 * tall + 3.5 * sin(Double(x) * 0.07 + 1.3) + 2 * sin(Double(x) * 0.19 + 0.4))) }
        func near(_ x: Int) -> Int { max(0, Int(0.045 * tall + 2.5 * sin(Double(x) * 0.11 + 4) + 1.5 * sin(Double(x) * 0.27))) }
        for x in 0..<width {
            for y in (height - far(x))..<height { canvas[x, y] = palette.land[0] }
            for y in (height - near(x))..<height { canvas[x, y] = palette.land[1] }
        }
        for i in 0..<(width / 12) {
            let x = Int(scatter(i * 3 + 700) * Double(width))
            let foot = height - near(x)
            for row in 0..<6 {
                for dx in -(row / 2)...(row / 2) { canvas[x + dx, foot - 6 + row] = palette.land[2] }
            }
        }
    }

    /// Streaks leaning with the wind: few, short and slow for drizzle; many,
    /// long and fast for a downpour.
    private func paintRain(_ canvas: inout PixelCanvas, _ time: Double) {
        let drop = Pixel(scene.phase == .night ? 0x9DB4D2 : 0xCFE0F2)
        let (thinning, length, fall): (Int, Int, Double) = switch scene.sky {
        case .drizzle: (420, 2, 55)
        case .rain: (200, 3, 95)
        default: (110, 4, 120)
        }
        let lean = min(0.7, 0.12 + scene.wind / 70)
        let drift = Double(height) * lean
        let run = Double(height + 2 * length)
        for i in 0..<(width * height / thinning) {
            let speed = fall * (0.8 + 0.5 * scatter(i * 3 + 1))
            let y = (scatter(i * 3 + 2) * run + time * speed).truncatingRemainder(dividingBy: run) - Double(length)
            // starting far enough left that the lean still reaches the left edge at the bottom
            let x = scatter(i * 3 + 3) * (Double(width) + drift) - drift + y * lean
            for k in 0..<length {
                canvas.blend(Int((x - Double(k) * lean).rounded(.down)), Int(y.rounded(.down)) - k, drop, 0.7 - 0.15 * Double(k))
            }
        }
    }

    /// Flakes swaying on their way down, the near ones bigger and quicker.
    private func paintSnow(_ canvas: inout PixelCanvas, _ time: Double) {
        let flake = Pixel(0xFFFFFF)
        let run = Double(height + 4)
        for i in 0..<(width * height / 240) {
            let near = i % 4 == 0
            let speed = (near ? 15 : 8) * (0.8 + 0.4 * scatter(i * 4 + 1))
            let y = Int((scatter(i * 4 + 2) * run + time * speed).truncatingRemainder(dividingBy: run)) - 2
            let sway = sin(time * (0.4 + 0.6 * scatter(i * 4 + 3)) + Double(i)) * (near ? 3 : 1.5)
            let across = scatter(i * 4 + 4) * Double(width) + sway + time * scene.wind / 12
            let x = Int(across.truncatingRemainder(dividingBy: Double(width)))
            canvas.blend(x, y, flake, near ? 1 : 0.7)
            if near {
                canvas.blend(x + 1, y, flake, 1)
                canvas.blend(x, y + 1, flake, 1)
                canvas.blend(x + 1, y + 1, flake, 1)
            }
        }
    }

    /// Long banks of mist, thickest along the middle and thinner at the
    /// edges, drifting below the date.
    private func paintFog(_ canvas: inout PixelCanvas, _ time: Double) {
        let mist = Pixel(scene.phase == .night ? 0x5A6677 : 0xE3E9EE)
        for i in 0..<(height / 12) {
            let wide = 34 + Int(scatter(i * 5 + 1) * 44)
            let deep = 5 + Int(scatter(i * 5 + 2) * 4)
            let top = cloudTop + Int(scatter(i * 5 + 3) * Double(height - cloudTop))
            let span = Double(width + wide)
            let left = Int((scatter(i * 5 + 4) * span + time * (0.5 + scatter(i * 5 + 5))).truncatingRemainder(dividingBy: span)) - wide
            for row in 0..<deep {
                // each row is shorter the further it is from the middle one
                let off = abs(Double(row) - Double(deep - 1) / 2) / (Double(deep) / 2)
                let inset = Int(off * off * Double(wide) * 0.3)
                for col in inset..<(wide - inset) {
                    let edge = row == 0 || row == deep - 1 || col < inset + 2 || col >= wide - inset - 2
                    canvas.blend(left + col, top + row, mist, edge ? 0.16 : 0.32)
                }
            }
        }
    }

    /// A bolt every seven seconds or so: two quick flickers of the same
    /// zigzag, and the whole sky lifting a little with the first.
    private func paintLightning(_ canvas: inout PixelCanvas, _ time: Double) {
        let gap = 7.0
        let strike = Int(time / gap)
        let since = time - Double(strike) * gap - scatter(strike * 7 + 1) * (gap - 1)
        guard (0..<0.12).contains(since) || (0.2..<0.32).contains(since) else { return }
        let bolt = Pixel(0xFFF7C2)
        var x = 12 + Int(scatter(strike * 7 + 2) * Double(max(1, width - 24)))
        var y = cloudTop + 10
        let foot = y + 45 + Int(scatter(strike * 7 + 3) * 45)
        var side = scatter(strike * 7 + 4) > 0.5 ? 1 : -1
        var leg = 0
        while y < foot {
            canvas[x, y] = bolt
            canvas[x + 1, y] = bolt
            y += 1
            leg += 1
            x += side * (leg % 2)   // down two for every one across
            if leg >= 6 + Int(scatter(strike * 31 + y) * 5) {
                side = -side
                leg = 0
            }
        }
        if since < 0.08 {
            let white = Pixel(0xFFFFFF)
            for row in 0..<height {
                for col in 0..<width { canvas.blend(col, row, white, 0.14) }
            }
        }
    }
}

// MARK: - The view

struct PixelSky: View {
    let scene: SkyScene
    /// The strip of open sky under the date, in points from the top left of
    /// the screen: the sun or moon goes at its right-hand end, and the clouds
    /// start at its top.
    let window: CGRect

    @Environment(\.displayScale) private var displayScale
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        GeometryReader { proxy in
            // one pixel of the scene is a whole number of the screen's own
            let pixel = (4.5 * displayScale).rounded() / displayScale
            let strip = window.isEmpty ? CGRect(x: 0, y: 150, width: proxy.size.width, height: 112) : window
            let painter = SkyPainter(scene: scene,
                                     width: max(8, Int((proxy.size.width / pixel).rounded(.up))),
                                     height: max(8, Int((proxy.size.height / pixel).rounded(.up))),
                                     bodyX: Int((strip.maxX - 64) / pixel), bodyY: Int((strip.midY - 6) / pixel),
                                     cloudTop: Int((strip.minY / pixel).rounded(.up)), still: reduceMotion)
            // with Reduce Motion on, one frame is painted and left
            TimelineView(.animation(minimumInterval: 1.0 / 15, paused: reduceMotion || scenePhase != .active)) { context in
                if let image = painter.paint(at: context.date.timeIntervalSinceReferenceDate).image {
                    Image(decorative: image, scale: 1)
                        .interpolation(.none)
                        .resizable()
                        .frame(width: CGFloat(painter.width) * pixel, height: CGFloat(painter.height) * pixel)
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height, alignment: .topLeading)
            .clipped()
        }
        .ignoresSafeArea()
        .accessibilityHidden(true)
    }
}

#Preview("Thunderstorm at night") {
    PixelSky(scene: SkyScene(sky: .thunderstorm, phase: .night, wind: 40), window: .zero)
}

#Preview("Partly cloudy day") {
    PixelSky(scene: SkyScene(sky: .partlyCloudy, phase: .day, wind: 9), window: .zero)
}
