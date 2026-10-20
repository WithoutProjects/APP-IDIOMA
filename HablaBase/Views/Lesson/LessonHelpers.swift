import AVFoundation
import SwiftUI

// MARK: - Environment

private struct GlossaryKey: EnvironmentKey {
    static let defaultValue = Glossary(words: [])
}

private struct LearnerLanguageKey: EnvironmentKey {
    static let defaultValue = NativeLanguage.english
}

extension EnvironmentValues {
    /// Words the learner has already met, for tap-to-translate.
    var glossary: Glossary {
        get { self[GlossaryKey.self] }
        set { self[GlossaryKey.self] = newValue }
    }

    var learnerLanguage: NativeLanguage {
        get { self[LearnerLanguageKey.self] }
        set { self[LearnerLanguageKey.self] = newValue }
    }
}

// MARK: - Tap a word to translate it

/// A Spanish sentence whose known words can be tapped for their translation.
/// Words not introduced yet are plain text, so nothing reveals vocabulary early.
struct GlossedText: View {
    let text: String
    var font: Font = .body

    var body: some View {
        FlowLayout(spacing: 5) {
            ForEach(Array(text.split(separator: " ").enumerated()), id: \.offset) { _, word in
                GlossedWord(word: String(word), font: font)
            }
        }
        .accessibilityElement(children: .combine)
    }
}

struct GlossedWord: View {
    @Environment(\.glossary) var glossary
    @Environment(\.learnerLanguage) var language
    let word: String
    var font: Font = .body
    @State var showing = false

    var body: some View {
        if let entry = glossary.lookup(word) {
            Button { showing = true } label: {
                Text(word)
                    .underline(pattern: .dot, color: .secondary)
                    .font(font)
                    .foregroundStyle(Color.primary)
            }
            .buttonStyle(.plain)
            .accessibilityHint(Text(entry.gloss.text(language)))
            .popover(isPresented: $showing) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(entry.es).font(.headline)
                    Text(entry.gloss.text(language)).foregroundStyle(.secondary)
                }
                .padding()
                .presentationCompactAdaptation(.popover)
            }
        } else {
            Text(word).font(font)
        }
    }
}

// MARK: - Audio

/// Reads Spanish aloud with the system voice. Works offline; nothing leaves the phone.
@MainActor
enum Speaker {
    private static let synthesizer = AVSpeechSynthesizer()

    static func say(_ text: String) {
        synthesizer.stopSpeaking(at: .immediate)
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "es-ES")
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        synthesizer.speak(utterance)
    }
}

struct SpeakButton: View {
    let text: String

    var body: some View {
        Button { Speaker.say(text) } label: {
            Image(systemName: "speaker.wave.2.fill")
                .frame(minWidth: 44, minHeight: 44)
        }
        .accessibilityLabel("Listen")
    }
}

// MARK: - Hints

/// Two-step hint: the first tap gives a nudge, the second a bigger one. Hints never cost
/// energy; a right answer after a hint earns a little less XP.
struct HintButton: View {
    @Binding var level: Int
    let onUse: () -> Void

    var body: some View {
        if level < 2 {
            Button {
                if level == 0 { onUse() }
                withAnimation { level += 1 }
            } label: {
                Label(level == 0 ? LocalizedStringKey("Hint") : LocalizedStringKey("Another hint"), systemImage: "lightbulb")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .tint(Brick.ending.color)
        }
    }
}

/// The box a hint appears in.
struct HintBox<Content: View>: View {
    @ViewBuilder let content: Content

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            Image(systemName: "lightbulb.fill")
                .foregroundStyle(.yellow)
                .accessibilityHidden(true)
            content
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14).fill(Color.yellow.opacity(0.12)))
        .transition(.opacity)
    }
}

extension FrameCard: Identifiable {
    var id: Self { self }
}

// MARK: - Intro

/// "Today you'll learn to say…": the sentence the lesson builds up to, heard before starting.
struct LessonIntroView: View {
    let lesson: Lesson
    let target: Example
    let language: NativeLanguage
    let onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Spacer()
            Text(lesson.title)
                .font(.largeTitle.bold())
            Text("Today you'll learn to say:")
                .font(.headline)
                .foregroundStyle(.secondary)
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(target.es)
                        .font(.title2.weight(.semibold))
                        .foregroundStyle(Brick.stem.color)
                    Text(target.gloss.text(language))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                SpeakButton(text: target.es)
            }
            .padding(20)
            .background(RoundedRectangle(cornerRadius: 20).fill(Palette.card))
            Text(lesson.goal.text(language))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Button("Start", action: onStart)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
    }
}
