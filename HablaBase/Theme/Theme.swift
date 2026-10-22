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
    static let success = Color(red: 0.30, green: 0.58, blue: 0.44)
    static let warning = Color(red: 0.84, green: 0.50, blue: 0.27)
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

/// The single large primary action at thumb height: flat, calm and full width.
struct PrimaryButtonStyle: ButtonStyle {
    /// Nil follows the screen's tint, which is the level's tone.
    var color: Color?
    var textColor: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(color.map { AnyShapeStyle($0) } ?? AnyShapeStyle(.tint)))
            .opacity(configuration.isPressed ? 0.8 : 1)
            .scaleEffect(configuration.isPressed ? 0.99 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
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
