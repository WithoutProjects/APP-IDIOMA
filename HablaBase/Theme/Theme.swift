import SwiftUI

/// One visual language across the app: blue stems, orange endings, green time markers, purple rails.
enum Brick: Hashable {
    case stem, ending, time, rail
    /// A neutral chunk (a place, a name) in sentence-level explanations.
    case chunk

    var color: Color {
        switch self {
        case .stem: return Color(red: 0.15, green: 0.42, blue: 0.88)
        case .ending: return Color(red: 0.96, green: 0.52, blue: 0.13)
        case .time: return Color(red: 0.16, green: 0.66, blue: 0.40)
        case .rail: return Color(red: 0.55, green: 0.32, blue: 0.85)
        case .chunk: return Color(red: 0.45, green: 0.47, blue: 0.52)
        }
    }
}

enum Palette {
    static let success = Color(red: 0.16, green: 0.66, blue: 0.40)
    static let warning = Color(red: 0.96, green: 0.52, blue: 0.13)
    static let card = Color(.secondarySystemBackground)
}

/// A single Lego brick: stem, ending, time marker or rail.
struct BrickView: View {
    let text: String
    let kind: Brick
    var isGhost = false

    var body: some View {
        Text(text)
            .font(.system(.title3, design: .rounded).weight(.semibold))
            .foregroundStyle(isGhost ? kind.color : .white)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .frame(minWidth: 52)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isGhost ? kind.color.opacity(0.12) : kind.color)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .strokeBorder(kind.color, style: StrokeStyle(lineWidth: 2, dash: isGhost ? [5] : []))
            )
    }
}

/// A form written in two colours: blue stem, orange ending.
struct ColoredForm: View {
    let form: VerbForm
    var font: Font = .body

    var body: some View {
        (Text(form.stem).foregroundColor(Brick.stem.color) + Text(form.ending).foregroundColor(Brick.ending.color))
            .font(font)
    }
}

/// The single large primary action at thumb height: a chunky button with a 3D edge that presses down.
struct PrimaryButtonStyle: ButtonStyle {
    var color: Color = .accentColor
    var textColor: Color = .white

    private static let depth: CGFloat = 4

    func makeBody(configuration: Configuration) -> some View {
        let shape = RoundedRectangle(cornerRadius: 16, style: .continuous)
        let pressed = configuration.isPressed
        return configuration.label
            .font(.system(.headline, design: .rounded).weight(.bold))
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(shape.fill(color))
            .offset(y: pressed ? Self.depth : 0)
            .background(
                shape.fill(color)
                    .overlay(shape.fill(Color.black.opacity(0.22)))
                    .offset(y: Self.depth)
            )
            .padding(.bottom, Self.depth)
            .animation(.easeOut(duration: 0.08), value: pressed)
    }
}

struct EnergyView: View {
    let energy: Int

    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<SavedState.maxEnergy, id: \.self) { index in
                Image(systemName: index < energy ? "heart.fill" : "heart")
                    .foregroundStyle(index < energy ? Color.red : Color.secondary)
            }
        }
        .font(.caption)
        .accessibilityLabel("Hearts: \(energy) of \(SavedState.maxEnergy)")
    }
}
