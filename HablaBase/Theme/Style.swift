import SwiftUI

/// The calm colours of the app: one muted tone per level, used for the road, the step tiles and the cards.
struct Tone: Hashable {
    /// Text, strokes and controls: deep on light backgrounds, lighter in dark mode, so text in the
    /// tone always reads (contrast of at least 4.5:1).
    let main: Color
    /// Solid fills under white text (buttons, tiles), deep enough in both modes.
    let fill: Color

    /// A light tint of the tone for backgrounds and rings.
    var soft: Color { main.opacity(0.14) }

    private init(deep: (Double, Double, Double), light: (Double, Double, Double)) {
        main = .adaptive(light: deep, dark: light)
        fill = Color(red: deep.0, green: deep.1, blue: deep.2)
    }

    static let sage = Tone(deep: (0.31, 0.45, 0.37), light: (0.42, 0.60, 0.50))
    static let dustyBlue = Tone(deep: (0.31, 0.43, 0.58), light: (0.41, 0.55, 0.75))
    static let terracotta = Tone(deep: (0.61, 0.36, 0.27), light: (0.80, 0.47, 0.36))
    static let plum = Tone(deep: (0.49, 0.38, 0.55), light: (0.62, 0.51, 0.69))
    static let ochre = Tone(deep: (0.52, 0.40, 0.19), light: (0.80, 0.62, 0.30))
    static let teal = Tone(deep: (0.23, 0.45, 0.47), light: (0.31, 0.59, 0.61))
    static let rose = Tone(deep: (0.58, 0.36, 0.42), light: (0.80, 0.50, 0.58))
    static let slate = Tone(deep: (0.38, 0.42, 0.50), light: (0.51, 0.55, 0.63))

    static let levels: [Tone] = [sage, dustyBlue, terracotta, plum, ochre, teal, rose, slate]

    /// Every level has its own tone, so the road changes colour as the learner moves up.
    static func forLevel(_ number: Int) -> Tone {
        levels[(max(number, 1) - 1) % levels.count]
    }
}

/// Soft geometric shapes for quiet decoration: rounded polygons and gentle wavy outlines.
struct SoftShape: Shape {
    enum Kind {
        case circle, squircle, pentagon, triangle, blob, cloud, flower
    }

    let kind: Kind

    func path(in rect: CGRect) -> Path {
        switch kind {
        case .circle:
            return Path(ellipseIn: rect)
        case .squircle:
            return Path(roundedRect: rect, cornerRadius: rect.width * 0.3, style: .continuous)
        case .pentagon:
            return Self.roundedPolygon(sides: 5, in: rect, corner: rect.width * 0.14)
        case .triangle:
            return Self.roundedPolygon(sides: 3, in: rect, corner: rect.width * 0.16)
        case .blob:
            return Self.wobble(in: rect, lobes: 3, depth: 0.06, turn: 0.3)
        case .cloud:
            return Self.wobble(in: rect, lobes: 5, depth: 0.08, turn: 0)
        case .flower:
            return Self.wobble(in: rect, lobes: 6, depth: 0.11, turn: 0)
        }
    }

    private static func roundedPolygon(sides: Int, in rect: CGRect, corner: CGFloat) -> Path {
        let raw = (0..<sides).map { index -> CGPoint in
            let angle = -Double.pi / 2 + Double(index) * 2 * Double.pi / Double(sides)
            return CGPoint(x: cos(angle), y: sin(angle))
        }
        let points = fit(raw, in: rect)
        let last = points[sides - 1]
        var path = Path()
        path.move(to: CGPoint(x: (points[0].x + last.x) / 2, y: (points[0].y + last.y) / 2))
        for index in 0..<sides {
            path.addArc(tangent1End: points[index], tangent2End: points[(index + 1) % sides], radius: corner)
        }
        path.closeSubpath()
        return path
    }

    private static func wobble(in rect: CGRect, lobes: Int, depth: Double, turn: Double) -> Path {
        let steps = 96
        let raw = (0..<steps).map { index -> CGPoint in
            let angle = Double(index) / Double(steps) * 2 * Double.pi
            let radius = 1 + depth * cos(Double(lobes) * (angle + turn))
            return CGPoint(x: radius * cos(angle), y: radius * sin(angle))
        }
        var path = Path()
        path.addLines(fit(raw, in: rect))
        path.closeSubpath()
        return path
    }

    /// Stretches a unit shape to fill the rectangle.
    private static func fit(_ points: [CGPoint], in rect: CGRect) -> [CGPoint] {
        let xs = points.map(\.x)
        let ys = points.map(\.y)
        let minX = xs.min() ?? 0, maxX = xs.max() ?? 1
        let minY = ys.min() ?? 0, maxY = ys.max() ?? 1
        return points.map { point in
            CGPoint(x: rect.minX + (point.x - minX) / (maxX - minX) * rect.width,
                    y: rect.minY + (point.y - minY) / (maxY - minY) * rect.height)
        }
    }
}

/// A still composition of soft shapes in the level tones, for the welcome screen.
struct ShapeComposition: View {
    private struct Piece {
        let kind: SoftShape.Kind
        let tone: Tone
        let size: CGFloat
        let x: CGFloat
        let y: CGFloat
        let tilt: Double
    }

    private let pieces: [Piece] = [
        Piece(kind: .circle, tone: .terracotta, size: 120, x: -70, y: -70, tilt: 0),
        Piece(kind: .squircle, tone: .sage, size: 110, x: 60, y: -50, tilt: 12),
        Piece(kind: .flower, tone: .ochre, size: 90, x: -95, y: 60, tilt: -8),
        Piece(kind: .pentagon, tone: .dustyBlue, size: 104, x: 20, y: 70, tilt: -6),
        Piece(kind: .triangle, tone: .rose, size: 70, x: 110, y: 50, tilt: 14),
        Piece(kind: .cloud, tone: .plum, size: 64, x: -10, y: -120, tilt: 0),
    ]

    var body: some View {
        ZStack {
            ForEach(pieces.indices, id: \.self) { index in
                let piece = pieces[index]
                SoftShape(kind: piece.kind)
                    .fill(piece.tone.main.opacity(0.85))
                    .frame(width: piece.size, height: piece.size)
                    .rotationEffect(.degrees(piece.tilt))
                    .offset(x: piece.x, y: piece.y)
            }
        }
        .frame(width: 300, height: 300)
        .accessibilityHidden(true)
    }
}

/// A straight vertical line through the middle of its frame, drawn dotted by the caller.
struct VerticalLine: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        return path
    }
}

/// A small caption above titles: "LEVEL 1 · A0–A1", "UNIT 3".
struct Eyebrow: View {
    let text: String
    var color: Color = .secondary

    var body: some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .tracking(0.8)
            .textCase(.uppercase)
            .foregroundStyle(color)
    }
}

private struct ToneKey: EnvironmentKey {
    static let defaultValue = Tone.sage
}

extension EnvironmentValues {
    /// The tone of the level the screen belongs to: the learner's current level, or the lesson's own level.
    var tone: Tone {
        get { self[ToneKey.self] }
        set { self[ToneKey.self] = newValue }
    }
}

extension View {
    /// Colours a screen with a level's tone: buttons, highlights, progress and controls.
    func levelTone(_ tone: Tone) -> some View {
        environment(\.tone, tone).tint(tone.main)
    }
}

/// The top of every main screen: a small level caption, a large title and one line below.
struct ScreenHeader: View {
    var eyebrow: String?
    let title: LocalizedStringKey
    var subtitle: String?
    @Environment(\.tone) var tone

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if let eyebrow {
                Eyebrow(text: eyebrow, color: tone.main)
            }
            Text(title)
                .font(.largeTitle.bold())
            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// A tinted rounded tile with an icon or a number, as on the unit page.
struct ToneTile<Content: View>: View {
    var size: CGFloat = 52
    var filled = false
    @ViewBuilder let content: Content
    @Environment(\.tone) var tone

    var body: some View {
        content
            .font(.headline)
            .foregroundStyle(filled ? Color.white : tone.main)
            .frame(width: size, height: size)
            .background(RoundedRectangle(cornerRadius: size * 0.3, style: .continuous).fill(filled ? tone.fill : tone.soft))
            .accessibilityHidden(true)
    }
}
