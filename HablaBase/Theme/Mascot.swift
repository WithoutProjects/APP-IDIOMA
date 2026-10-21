import SwiftUI

/// The friendly shapes with eyes that live on the path, the cards and the celebrations.
/// They are decoration only: they never speak and have no names.
enum MascotShape: CaseIterable {
    case blob, pentagon, circle, triangle, squircle, cloud, flower

    static func forUnit(_ number: Int) -> MascotShape {
        allCases[(max(number, 1) - 1) % allCases.count]
    }
}

enum MascotMood {
    case happy, excited, sleepy, curious
}

struct Mascot: View {
    var shape: MascotShape = .blob
    var color: Color
    var mood: MascotMood = .happy
    var size: CGFloat = 80

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State var blink = false

    var body: some View {
        ZStack {
            MascotBody(shape: shape)
                .fill(color)
            MascotBody(shape: shape)
                .fill(LinearGradient(colors: [.white.opacity(0.22), .clear], startPoint: .topLeading, endPoint: .center))
            face
                .offset(y: size * faceDrop)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
        .task(id: mood) { await blinkLoop() }
    }

    private var faceDrop: CGFloat {
        switch shape {
        case .triangle: return 0.16
        case .pentagon: return 0.05
        default: return 0.02
        }
    }

    private var face: some View {
        VStack(spacing: size * 0.06) {
            HStack(spacing: size * (shape == .triangle ? 0.12 : 0.17)) {
                eye
                eye
            }
            .scaleEffect(x: 1, y: blink ? 0.1 : 1)
            mouth
        }
    }

    @ViewBuilder
    private var eye: some View {
        let d = size * (mood == .excited ? 0.19 : 0.16)
        switch mood {
        case .sleepy:
            SmileArc()
                .stroke(Color.black, style: StrokeStyle(lineWidth: size * 0.035, lineCap: .round))
                .frame(width: d, height: d * 0.45)
        case .curious:
            ZStack(alignment: .topTrailing) {
                Circle().fill(.white)
                Circle().fill(.black)
                    .frame(width: d * 0.62, height: d * 0.62)
                    .padding(d * 0.1)
            }
            .frame(width: d * 1.3, height: d * 1.3)
        case .happy, .excited:
            ZStack {
                Circle().fill(.black)
                Circle().fill(.white)
                    .frame(width: d * 0.32, height: d * 0.32)
                    .offset(x: d * 0.18, y: -d * 0.16)
            }
            .frame(width: d, height: d)
        }
    }

    @ViewBuilder
    private var mouth: some View {
        let w = size * 0.2
        switch mood {
        case .happy:
            SmileArc()
                .stroke(Color.black, style: StrokeStyle(lineWidth: size * 0.04, lineCap: .round))
                .frame(width: w, height: w * 0.45)
        case .excited:
            ZStack(alignment: .bottom) {
                OpenMouth().fill(.black)
                Ellipse()
                    .fill(Color(red: 1, green: 0.45, blue: 0.52))
                    .frame(width: w * 0.7, height: w * 0.4)
                    .offset(y: w * 0.12)
            }
            .frame(width: w * 1.15, height: w * 0.62)
            .clipShape(OpenMouth())
        case .sleepy:
            Capsule().fill(.black)
                .frame(width: w * 0.45, height: size * 0.035)
        case .curious:
            Circle().fill(.black)
                .frame(width: w * 0.36, height: w * 0.36)
        }
    }

    private func blinkLoop() async {
        guard !reduceMotion, mood != .sleepy else { return }
        while !Task.isCancelled {
            try? await Task.sleep(for: .seconds(Double.random(in: 2.5...5.5)))
            if Task.isCancelled { return }
            withAnimation(.easeInOut(duration: 0.08)) { blink = true }
            try? await Task.sleep(for: .milliseconds(140))
            withAnimation(.easeInOut(duration: 0.1)) { blink = false }
        }
    }
}

/// The body of a mascot: rounded polygons and soft wobbly outlines.
struct MascotBody: Shape {
    let shape: MascotShape

    func path(in rect: CGRect) -> Path {
        switch shape {
        case .circle:
            return Path(ellipseIn: rect)
        case .squircle:
            let inset = rect.width * 0.04
            return Path(roundedRect: rect.insetBy(dx: inset, dy: inset), cornerRadius: rect.width * 0.3, style: .continuous)
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
        var path = Path()
        let last = points[sides - 1]
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

/// A smile or a closed eye: a curve that dips in the middle.
struct SmileArc: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.maxX, y: rect.minY),
                          control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 2))
        return path
    }
}

/// A big open laugh: flat on top, round below.
struct OpenMouth: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))
        path.addQuadCurve(to: CGPoint(x: rect.minX, y: rect.minY),
                          control: CGPoint(x: rect.midX, y: rect.minY + rect.height * 2))
        path.closeSubpath()
        return path
    }
}

/// A happy crowd of mascots for the welcome screen.
struct MascotParade: View {
    private struct Member {
        let shape: MascotShape
        let color: FunColor
        let mood: MascotMood
        let size: CGFloat
        let x: CGFloat
        let y: CGFloat
        let tilt: Double
    }

    private let members: [Member] = [
        Member(shape: .flower, color: .bubblegum, mood: .happy, size: 88, x: -105, y: -105, tilt: -8),
        Member(shape: .circle, color: .tangerine, mood: .excited, size: 92, x: 5, y: -115, tilt: 6),
        Member(shape: .squircle, color: .sunshine, mood: .curious, size: 82, x: 110, y: -95, tilt: 10),
        Member(shape: .blob, color: .sky, mood: .happy, size: 96, x: -110, y: 0, tilt: 4),
        Member(shape: .triangle, color: .teal, mood: .happy, size: 94, x: -5, y: -10, tilt: -4),
        Member(shape: .pentagon, color: .grape, mood: .sleepy, size: 88, x: 105, y: 10, tilt: -10),
        Member(shape: .cloud, color: .leaf, mood: .excited, size: 90, x: -55, y: 100, tilt: 3),
        Member(shape: .circle, color: .bubblegum, mood: .curious, size: 76, x: 60, y: 105, tilt: -6),
    ]

    var body: some View {
        ZStack {
            ForEach(members.indices, id: \.self) { index in
                let member = members[index]
                Mascot(shape: member.shape, color: member.color.main, mood: member.mood, size: member.size)
                    .rotationEffect(.degrees(member.tilt))
                    .offset(x: member.x, y: member.y)
            }
        }
        .frame(width: 320, height: 320)
        .accessibilityHidden(true)
    }
}

/// Colourful paper bits that fly out once, for a finished lesson.
struct ConfettiBurst: View {
    private struct Piece {
        let angle: Double
        let distance: Double
        let color: Color
        let size: CGFloat
        let spin: Double
    }

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State private var go = false
    @State private var pieces: [Piece] = (0..<22).map { index in
        Piece(angle: Double(index) / 22 * 2 * Double.pi + Double.random(in: -0.15...0.15),
              distance: Double.random(in: 90...170),
              color: FunColor.cycle[index % FunColor.cycle.count].main,
              size: CGFloat.random(in: 8...14),
              spin: Double.random(in: 180...540))
    }

    var body: some View {
        ZStack {
            ForEach(pieces.indices, id: \.self) { index in
                let piece = pieces[index]
                RoundedRectangle(cornerRadius: 2)
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size * 0.6)
                    .rotationEffect(.degrees(go ? piece.spin : 0))
                    .offset(x: go ? CGFloat(cos(piece.angle) * piece.distance) : 0,
                            y: go ? CGFloat(sin(piece.angle) * piece.distance) : 0)
                    .opacity(go ? 0 : 1)
            }
        }
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .opacity(reduceMotion ? 0 : 1)
        .onAppear {
            guard !reduceMotion else { return }
            withAnimation(.easeOut(duration: 1.3)) { go = true }
        }
    }
}

/// The reward chest halfway through every unit.
struct ChestView: View {
    enum Status {
        case locked, ready, open
    }

    let status: Status
    var size: CGFloat = 76

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State var wiggle = false

    var body: some View {
        let wood = status == .locked ? FunColor.locked : FunColor.cocoa
        let gold = status == .locked ? FunColor.locked : FunColor.sunshine
        let base = RoundedRectangle(cornerRadius: size * 0.1, style: .continuous)
        let lidShape = UnevenRoundedRectangle(topLeadingRadius: size * 0.2, bottomLeadingRadius: size * 0.04,
                                              bottomTrailingRadius: size * 0.04, topTrailingRadius: size * 0.2,
                                              style: .continuous)
        ZStack {
            if status == .open {
                Image(systemName: "sparkles")
                    .font(.system(size: size * 0.34, weight: .bold))
                    .foregroundStyle(FunColor.sunshine.main)
                    .offset(x: size * 0.22, y: -size * 0.42)
            }
            base.fill(wood.deep)
                .frame(width: size, height: size * 0.48)
                .offset(y: size * 0.22 + 5)
            base.fill(wood.main)
                .frame(width: size, height: size * 0.48)
                .offset(y: size * 0.22)
            lidShape.fill(wood.main)
                .overlay(lidShape.fill(Color.black.opacity(0.08)))
                .overlay(Rectangle().fill(gold.main).frame(width: size * 0.14))
                .frame(width: size * 1.04, height: size * 0.32)
                .rotationEffect(.degrees(status == .open ? -16 : 0), anchor: .bottomLeading)
                .offset(y: status == .open ? -size * 0.14 : -size * 0.08)
            RoundedRectangle(cornerRadius: size * 0.05)
                .fill(gold.main)
                .overlay(Circle().fill(gold.deep).frame(width: size * 0.07))
                .frame(width: size * 0.2, height: size * 0.24)
                .offset(y: size * 0.12)
        }
        .frame(width: size, height: size)
        .rotationEffect(.degrees(status == .ready ? (wiggle ? 5 : -5) : 0), anchor: .bottom)
        .onAppear { startWiggle() }
        .onChange(of: status) { startWiggle() }
    }

    private func startWiggle() {
        guard status == .ready, !reduceMotion else {
            wiggle = false
            return
        }
        withAnimation(.easeInOut(duration: 0.5).repeatForever(autoreverses: true)) { wiggle = true }
    }
}
