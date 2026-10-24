import SwiftUI
import UIKit

/// One visual language across the app: blue stems, orange endings, green time markers, purple rails.
enum Brick: Hashable {
    case stem, ending, time, rail
    /// A neutral chunk (a place, a name) in sentence-level explanations.
    case chunk

    /// Text colour: deep on light backgrounds, lighter in dark mode, so both stay readable.
    var color: Color {
        switch self {
        case .stem: return .adaptive(light: (0.14, 0.40, 0.84), dark: (0.34, 0.55, 0.91))
        case .ending: return .adaptive(light: (0.63, 0.34, 0.09), dark: (0.96, 0.52, 0.13))
        case .time: return .adaptive(light: (0.12, 0.48, 0.29), dark: (0.16, 0.66, 0.40))
        case .rail: return .adaptive(light: (0.52, 0.30, 0.81), dark: (0.64, 0.46, 0.88))
        case .chunk: return .adaptive(light: (0.40, 0.42, 0.47), dark: (0.53, 0.55, 0.59))
        }
    }

    /// Solid brick colour under white text, deep enough in both modes.
    var fill: Color {
        switch self {
        case .stem: return Color(red: 0.14, green: 0.40, blue: 0.84)
        case .ending: return Color(red: 0.63, green: 0.34, blue: 0.09)
        case .time: return Color(red: 0.12, green: 0.48, blue: 0.29)
        case .rail: return Color(red: 0.52, green: 0.30, blue: 0.81)
        case .chunk: return Color(red: 0.40, green: 0.42, blue: 0.47)
        }
    }
}

enum Palette {
    /// Text and strokes; the fills below sit under white text.
    static let success = Color.adaptive(light: (0.24, 0.46, 0.35), dark: (0.36, 0.66, 0.50))
    static let warning = Color.adaptive(light: (0.60, 0.36, 0.19), dark: (0.84, 0.50, 0.27))
    static let successFill = Color(red: 0.24, green: 0.46, blue: 0.35)
    static let warningFill = Color(red: 0.60, green: 0.36, blue: 0.19)
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
                    .fill(isGhost ? kind.color.opacity(0.12) : kind.fill)
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
    /// Nil uses the level tone's fill.
    var color: Color?
    var textColor: Color = .white

    func makeBody(configuration: Configuration) -> some View {
        PrimaryButtonBody(configuration: configuration, color: color, textColor: textColor)
    }
}

private struct PrimaryButtonBody: View {
    let configuration: ButtonStyleConfiguration
    let color: Color?
    let textColor: Color
    @Environment(\.tone) private var tone

    var body: some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(textColor)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            // The tone's deep fill keeps white text readable in light and dark mode.
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(color ?? tone.fill))
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

extension Color {
    /// One colour per appearance: a deep shade that reads on light backgrounds (contrast of at least
    /// 4.5:1 on white) and a lighter one that reads on dark backgrounds.
    static func adaptive(light: (Double, Double, Double), dark: (Double, Double, Double)) -> Color {
        Color(UIColor { traits in
            let c = traits.userInterfaceStyle == .dark ? dark : light
            return UIColor(red: c.0, green: c.1, blue: c.2, alpha: 1)
        })
    }
}
