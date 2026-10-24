import SwiftUI

/// Speaking practice: hear a sentence from your finished lessons, say it aloud, and see
/// which words came through.
struct TalkView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var listener = SpeechListener()
    @State private var index = 0
    @State private var rewarded: Set<String> = []

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ScreenHeader(eyebrow: Journey.currentLevel(store: store).map { Journey.caption($0, language: store.language) },
                                 title: "Speak",
                                 subtitle: store.language.localized("Listen, then say it out loud."))
                    let sentences = store.speakingSentences
                    if sentences.isEmpty {
                        empty
                            .padding(.top, 40)
                    } else {
                        practice(sentences[index % sentences.count], count: sentences.count)
                    }
                }
                .padding(20)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
        .onDisappear { listener.stop() }
    }

    private var empty: some View {
        ContentUnavailableView("Nothing to say yet", systemImage: "mic",
                               description: Text("Finish your first lesson and its sentences will be here to practise out loud."))
    }

    // MARK: Repeat after me

    private func practice(_ sentence: Example, count: Int) -> some View {
        let words = SpeakingScore.words(said: listener.transcript, target: sentence.es)
        let hasTry = listener.isFinal && !listener.transcript.isEmpty
        let passed = hasTry && SpeakingScore.passed(words)

        return VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    FlowLayout(spacing: 6) {
                        ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                            Text(word.text)
                                .font(.title2.weight(.semibold))
                                .foregroundStyle(!hasTry ? Color.primary : word.heard ? Palette.success : Palette.warning)
                        }
                    }
                    SpeakButton(text: sentence.es)
                }
                Text(sentence.gloss.text(store.language))
                    .foregroundStyle(.secondary)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Palette.card))

            if !listener.transcript.isEmpty {
                VStack(alignment: .leading, spacing: 4) {
                    Text("I heard:").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                    Text(listener.transcript).font(.body)
                }
            }

            if hasTry {
                Label(passed ? LocalizedStringKey("Great, that was clear!") : LocalizedStringKey("Almost. Listen again and try the orange words."),
                      systemImage: passed ? "checkmark.circle.fill" : "arrow.counterclockwise.circle.fill")
                    .font(.headline)
                    .foregroundStyle(passed ? Palette.success : Palette.warning)
                if !listener.unclearWords.isEmpty {
                    unclearWords
                }
            }

            SpeechStatusNote(listener: listener)

            MicButton(listener: listener)
                .frame(maxWidth: .infinity)

            Button("Next sentence") {
                listener.reset()
                index = (index + 1) % count
            }
            .buttonStyle(PrimaryButtonStyle(color: passed ? Palette.successFill : nil))
        }
        .onChange(of: passed) { _, isPassed in
            // A few XP the first time each sentence comes out right.
            if isPassed, rewarded.insert(sentence.es).inserted { store.addXP(2) }
        }
    }

    /// Words the speech recogniser was unsure of: listen to them and say them more clearly.
    private var unclearWords: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Say these words more clearly:", systemImage: "waveform")
                .font(.subheadline.weight(.semibold))
            FlowLayout(spacing: 8) {
                ForEach(Array(listener.unclearWords.enumerated()), id: \.offset) { _, word in
                    HStack(spacing: 4) {
                        Text(verbatim: word).fontWeight(.semibold)
                        SpeakButton(text: word)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Palette.card))
                }
            }
        }
    }
}
