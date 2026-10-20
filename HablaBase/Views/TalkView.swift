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
            let sentences = store.speakingSentences
            Group {
                if sentences.isEmpty {
                    ContentUnavailableView("Nothing to say yet", systemImage: "mic",
                                           description: Text("Finish your first lesson and its sentences will be here to practise out loud."))
                } else {
                    practice(sentences[index % sentences.count], count: sentences.count)
                }
            }
            .navigationTitle("Speak")
        }
        .onDisappear { listener.stop() }
    }

    private func practice(_ sentence: Example, count: Int) -> some View {
        let words = SpeakingScore.words(said: listener.transcript, target: sentence.es)
        let hasTry = !listener.transcript.isEmpty && listener.status != .listening
        let passed = hasTry && SpeakingScore.passed(words)

        return ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Text("Listen, then say it out loud.")
                    .font(.headline)
                    .foregroundStyle(.secondary)

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
                .background(RoundedRectangle(cornerRadius: 20).fill(Palette.card))

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
                }

                statusNote

                micButton
                    .frame(maxWidth: .infinity)

                Button("Next sentence") {
                    listener.stop()
                    index = (index + 1) % count
                }
                .buttonStyle(PrimaryButtonStyle(color: passed ? Palette.success : .accentColor))
            }
            .padding(20)
        }
        .onChange(of: passed) { _, isPassed in
            // A few XP the first time each sentence comes out right.
            if isPassed, rewarded.insert(sentence.es).inserted { store.addXP(2) }
        }
    }

    private var micButton: some View {
        let listening = listener.status == .listening
        return Button {
            if listening {
                listener.stop()
            } else {
                Task { await listener.start() }
            }
        } label: {
            Image(systemName: listening ? "stop.fill" : "mic.fill")
                .font(.largeTitle)
                .foregroundStyle(.white)
                .frame(width: 88, height: 88)
                .background(Circle().fill(listening ? Palette.warning : Brick.stem.color))
        }
        .accessibilityLabel(listening ? LocalizedStringKey("Stop") : LocalizedStringKey("Speak"))
    }

    @ViewBuilder
    private var statusNote: some View {
        switch listener.status {
        case .listening:
            Text("Listening… tap stop when you finish.").foregroundStyle(.secondary)
        case .denied:
            VStack(alignment: .leading, spacing: 8) {
                Text("To practise speaking, allow the microphone and speech recognition in Settings.")
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    Link("Open Settings", destination: url)
                }
            }
        case .unavailable:
            Text("Speech recognition isn't available right now. Check your connection or try again later.")
                .foregroundStyle(.secondary)
        case .idle:
            EmptyView()
        }
    }
}
