import SwiftUI

/// Speaking practice: hear a sentence from your finished lessons, say it aloud, and see
/// which words came through.
struct TalkView: View {
    @EnvironmentObject private var store: AppStore
    @StateObject private var listener = SpeechListener()
    @State private var index = 0
    @State private var rewarded: Set<String> = []

    enum Mode: Hashable {
        case answer, repeatAfter
    }

    @State private var mode = Mode.answer
    @State private var questionIndex = 0
    @State private var showAnswer = false
    @State private var corrected: Set<String> = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("Mode", selection: $mode) {
                    Text("Answer questions").tag(Mode.answer)
                    Text("Repeat").tag(Mode.repeatAfter)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 20)
                .padding(.top, 8)

                switch mode {
                case .answer:
                    let questions = store.speakingQuestions
                    if questions.isEmpty {
                        empty
                    } else {
                        answerPractice(questions[questionIndex % questions.count], count: questions.count)
                    }
                case .repeatAfter:
                    let sentences = store.speakingSentences
                    if sentences.isEmpty {
                        empty
                    } else {
                        practice(sentences[index % sentences.count], count: sentences.count)
                    }
                }
            }
            .navigationTitle("Speak")
            .onChange(of: mode) { _, _ in listener.reset() }
        }
        .onDisappear { listener.stop() }
    }

    private var empty: some View {
        ContentUnavailableView("Nothing to say yet", systemImage: "mic",
                               description: Text("Finish your first lesson and its sentences will be here to practise out loud."))
    }

    // MARK: Answer questions

    /// The app asks aloud; you answer from memory (or read the answer), and it checks and corrects you.
    private func answerPractice(_ question: SpokenQuestion, count: Int) -> some View {
        let hasTry = !listener.transcript.isEmpty && listener.status != .listening
        let check = SpeakingScore.check(said: listener.transcript, answers: question.answers)
        let passed = hasTry && check.passed

        return ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("Listen to the question and answer out loud.")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                HStack(alignment: .top) {
                    Text(question.question)
                        .font(.title.weight(.semibold))
                        .foregroundStyle(Brick.stem.color)
                    Spacer(minLength: 0)
                    SpeakButton(text: question.question)
                }
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 20).fill(Palette.card))

                if showAnswer || hasTry {
                    answerCard(question, check: check, hasTry: hasTry)
                } else {
                    Button {
                        withAnimation { showAnswer = true }
                    } label: {
                        Label("Show the answer to read it", systemImage: "eye")
                            .font(.subheadline.weight(.semibold))
                    }
                    .buttonStyle(.bordered)
                    Text("Or answer from memory.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if !listener.transcript.isEmpty {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("I heard:").font(.caption.weight(.bold)).foregroundStyle(.secondary)
                        Text(listener.transcript)
                    }
                }

                if hasTry {
                    if passed {
                        Label("Correct!", systemImage: "checkmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(Palette.success)
                    } else {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Not quite. Listen to the right answer and try again.", systemImage: "arrow.counterclockwise.circle.fill")
                                .font(.headline)
                                .foregroundStyle(Palette.warning)
                            ForEach(Array(check.fixes.enumerated()), id: \.offset) { _, fix in
                                HStack(spacing: 8) {
                                    Text(verbatim: fix.said).strikethrough().foregroundStyle(.secondary)
                                    Image(systemName: "arrow.right").accessibilityHidden(true)
                                    Text(verbatim: fix.correct).fontWeight(.semibold).foregroundStyle(Palette.success)
                                }
                            }
                        }
                    }
                }

                statusNote

                micButton
                    .frame(maxWidth: .infinity)

                Button("Next question") {
                    listener.reset()
                    showAnswer = false
                    questionIndex = (questionIndex + 1) % count
                }
                .buttonStyle(PrimaryButtonStyle(color: passed ? Palette.success : .accentColor))
            }
            .padding(20)
        }
        .task(id: questionIndex) { Speaker.say(question.question) }
        .onChange(of: hasTry) { _, tried in
            guard tried else { return }
            if passed {
                if rewarded.insert(question.question + question.answers[0]).inserted { store.addXP(2) }
            } else if corrected.insert(listener.transcript).inserted {
                // Say the right answer once, so the learner hears the correction.
                Speaker.say(check.answer)
            }
        }
    }

    private func answerCard(_ question: SpokenQuestion, check: SpeakingScore.Check, hasTry: Bool) -> some View {
        let words = hasTry ? check.words : question.answers[0].split(separator: " ").map { SpeakingScore.Word(text: String($0), heard: true) }
        return VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                FlowLayout(spacing: 6) {
                    ForEach(Array(words.enumerated()), id: \.offset) { _, word in
                        Text(word.text)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(!hasTry ? Color.primary : word.heard ? Palette.success : Palette.warning)
                    }
                }
                SpeakButton(text: hasTry ? check.answer : question.answers[0])
            }
            Text(question.gloss.text(store.language))
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.secondary.opacity(0.3)))
    }

    // MARK: Repeat after me

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
                    listener.reset()
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
