import SwiftUI

/// The bright colours of the path, the mascots and the cards.
/// Each one has a main tone, a deeper tone for the 3D edge, a soft tint and the ink that reads on it.
struct FunColor: Hashable {
    let main: Color
    let deep: Color
    let soft: Color
    let ink: Color

    init(main: Color, deep: Color, soft: Color, ink: Color = .white) {
        self.main = main
        self.deep = deep
        self.soft = soft
        self.ink = ink
    }

    private static func rgb(_ r: Double, _ g: Double, _ b: Double,
                            deep: (Double, Double, Double), ink: Color = .white) -> FunColor {
        let main = Color(red: r, green: g, blue: b)
        return FunColor(main: main,
                        deep: Color(red: deep.0, green: deep.1, blue: deep.2),
                        soft: main.opacity(0.16),
                        ink: ink)
    }

    static let sky = rgb(0.18, 0.55, 0.96, deep: (0.10, 0.40, 0.78))
    static let leaf = rgb(0.20, 0.70, 0.40, deep: (0.12, 0.52, 0.28))
    static let tangerine = rgb(0.96, 0.42, 0.16, deep: (0.76, 0.28, 0.08))
    static let grape = rgb(0.49, 0.36, 0.90, deep: (0.35, 0.24, 0.72))
    static let bubblegum = rgb(0.93, 0.36, 0.64, deep: (0.74, 0.22, 0.48))
    static let teal = rgb(0.10, 0.68, 0.66, deep: (0.05, 0.50, 0.48))
    static let sunshine = rgb(1.00, 0.78, 0.16, deep: (0.86, 0.60, 0.04),
                              ink: Color(red: 0.32, green: 0.21, blue: 0.02))
    static let cocoa = rgb(0.66, 0.48, 0.32, deep: (0.50, 0.34, 0.20))

    /// Steps not reached yet: quiet grey in light and dark mode.
    static let locked = FunColor(main: Color(.systemGray5), deep: Color(.systemGray3),
                                 soft: Color(.systemGray6), ink: Color(.systemGray))

    static let cycle: [FunColor] = [sky, leaf, tangerine, grape, bubblegum, teal, sunshine, cocoa]

    /// Every unit has its own colour, so the path changes as the learner moves on.
    static func forUnit(_ number: Int) -> FunColor {
        cycle[(max(number, 1) - 1) % cycle.count]
    }
}

/// Round path steps shrink a little under the finger.
struct SquishButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.93 : 1)
            .animation(.easeOut(duration: 0.1), value: configuration.isPressed)
    }
}

/// A small coloured counter: streak, XP.
struct StatPill: View {
    let icon: String
    let value: String
    let color: FunColor

    var body: some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .foregroundStyle(color.main)
                .accessibilityHidden(true)
            Text(verbatim: value)
                .foregroundStyle(.primary)
        }
        .font(.system(.headline, design: .rounded).weight(.heavy))
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(color.soft))
    }
}
