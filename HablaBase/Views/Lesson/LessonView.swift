import SwiftUI

struct LessonView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var session: LessonSession
    @State private var finished = false
    @State private var showIntro: Bool
    @State private var explanation: FrameCard?

    /// Every lesson wears the colour of its level; a review wears the learner's current one.
    private var tone: Tone {
        Journey.tone(forStep: session.lesson.id) ?? Journey.currentTone(store: store)
    }

    init(lesson: Lesson) {
        _session = StateObject(wrappedValue: LessonSession(lesson: lesson))
        _showIntro = State(initialValue: lesson.target != nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if showIntro, let target = session.lesson.target {
                LessonIntroView(lesson: session.lesson, target: target, language: store.language) {
                    withAnimation { showIntro = false }
                }
            } else if finished {
                LessonCompleteView(lesson: session.lesson,
                                   xp: session.completionXP,
                                   correct: session.correct,
                                   answered: session.answered,
                                   testPassed: session.isTest ? session.passedTest : nil,
                                   sentences: session.saidSentences,
                                   language: store.language) { dismiss() }
            } else if let item = session.current {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HStack {
                            Text(item.beat.title(store.language).uppercased())
                                .font(.caption.weight(.bold))
                                .foregroundStyle(.secondary)
                            Spacer()
                            if let card = session.currentExplanation {
                                Button { explanation = card } label: {
                                    Label("See explanation", systemImage: "book.fill")
                                        .font(.caption.weight(.semibold))
                                }
                                .buttonStyle(.bordered)
                            }
                        }
                        itemView(item)
                            .id("\(item.id)-\(session.index)")
                    }
                    .padding(20)
                }
                .disabled(session.feedback != nil)
                if let feedback = session.feedback {
                    FeedbackBar(feedback: feedback, language: store.language) {
                        withAnimation(.easeOut(duration: 0.2)) { next() }
                    }
                    .transition(.move(edge: .bottom))
                }
            }
        }
        .animation(.easeOut(duration: 0.25), value: session.feedback != nil)
        .levelTone(tone)
        .environment(\.glossary, store.glossary(including: session.lesson))
        .environment(\.learnerLanguage, store.language)
        .sheet(item: $explanation) { card in
            NavigationStack {
                ScrollView {
                    FrameCardView(card: card, language: store.language, onContinue: {}, showsButton: false)
                        .padding(20)
                }
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Back to the exercise") { explanation = nil }
                    }
                }
            }
            .environment(\.glossary, store.glossary(including: session.lesson))
            .environment(\.learnerLanguage, store.language)
            .presentationDetents([.medium, .large])
        }
    }

    private var header: some View {
        HStack(spacing: 14) {
            Button { dismiss() } label: {
                Image(systemName: "xmark").font(.headline)
            }
            .tint(.secondary)
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Close lesson")
            ProgressView(value: finished ? 1 : session.progress)
            EnergyView(energy: store.state.energy)
        }
        .padding()
    }

    @ViewBuilder
    private func itemView(_ item: LessonItem) -> some View {
        let submit: (GradeOutcome) -> Void = { outcome in
            session.submit(outcome, store: store)
            if session.isFinished { finish() }
        }
        let hint = { session.useHint() }
        switch item.kind {
        case .slides(let set):
            VocabSlidesView(set: set, language: store.language) { submit(.correct) }
        case .match(let set):
            VocabMatchView(set: set, language: store.language, onSubmit: submit)
        case .frame(let card):
            FrameCardView(card: card, language: store.language) { submit(.correct) }
        case .legoSnap(let snap):
            LegoSnapView(snap: snap, language: store.language, onSubmit: submit, onHint: hint)
        case .gapFill(let gap):
            GapFillView(gap: gap, language: store.language, onSubmit: submit, onHint: hint)
        case .choice(let choice):
            ChoiceView(choice: choice, language: store.language, onSubmit: submit, onHint: hint)
        case .builder(let builder):
            SentenceBuilderView(builder: builder, language: store.language, onSubmit: submit, onHint: hint)
        case .freeWrite(let write):
            FreeWriteView(write: write, language: store.language, onSubmit: submit, onHint: hint)
        }
    }

    private func next() {
        session.advance()
        if session.isFinished { finish() }
    }

    private func finish() {
        guard !finished else { return }
        switch session.lesson.mode {
        case .lesson:
            store.completeLesson(session.lesson.id, xp: session.completionXP)
        case .unitTest(let unitId):
            // Passing skips the unit: everything up to its end counts as done.
            if session.passedTest { store.completeUnit(unitId) }
            store.addXP(session.completionXP)
        case .review:
            store.addXP(session.completionXP)
        }
        finished = true
    }
}

/// The bottom sheet that rises green (correct) or orange (with a one-line why).
struct FeedbackBar: View {
    let feedback: LessonSession.Feedback
    let language: NativeLanguage
    let onContinue: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label(title, systemImage: feedback.outcome.isCorrect ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .font(.headline)
                .foregroundStyle(color)
            if let note {
                Text(note).font(.subheadline)
            }
            if let model = feedback.model {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        GlossedText(text: model.es, font: .body.weight(.semibold))
                        SpeakButton(text: model.es)
                    }
                    Text(model.gloss.text(language)).font(.footnote).foregroundStyle(.secondary)
                }
            }
            Button("Continue", action: onContinue)
                .buttonStyle(PrimaryButtonStyle(color: feedback.outcome.isCorrect ? Palette.successFill : Palette.warningFill))
                .padding(.top, 4)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(color.opacity(0.12))
    }

    private var color: Color { feedback.outcome.isCorrect ? Palette.success : Palette.warning }

    private var title: String {
        switch feedback.outcome {
        case .correct: return "¡Perfecto!"
        case .accent: return "¡Casi perfecto!"
        case .wrong: return language.localized("Not quite")
        }
    }

    private var note: String? {
        switch feedback.outcome {
        case .correct: return nil
        case .accent(let expected): return language.localized("Watch the accents: \(expected)")
        case .wrong(let hint): return hint
        }
    }
}

struct LessonCompleteView: View {
    let lesson: Lesson
    let xp: Int
    let correct: Int
    let answered: Int
    /// nil for a lesson; for a unit test, whether it was passed.
    let testPassed: Bool?
    /// Sentences said right in this lesson: "Now you can say…".
    let sentences: [Example]
    let language: NativeLanguage
    let onDone: () -> Void

    @Environment(\.accessibilityReduceMotion) var reduceMotion
    @State var appeared = false

    @Environment(\.tone) var tone

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ZStack {
                Circle()
                    .fill(tone.soft)
                    .frame(width: 120, height: 120)
                Image(systemName: testPassed == false ? "arrow.counterclockwise" : "checkmark")
                    .font(.system(size: 46, weight: .semibold))
                    .foregroundStyle(tone.main)
            }
            .scaleEffect(appeared ? 1 : 0.7)
            .opacity(appeared ? 1 : 0)
            .accessibilityHidden(true)
            .onAppear {
                withAnimation(reduceMotion ? nil : .spring(response: 0.45, dampingFraction: 0.7)) { appeared = true }
            }
            Text(headline)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            if testPassed == nil && !sentences.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Now you can say:").font(.headline)
                    ForEach(sentences.suffix(4), id: \.self) { sentence in
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(sentence.es).font(.body.weight(.semibold))
                                Text(sentence.gloss.text(language)).font(.footnote).foregroundStyle(.secondary)
                            }
                            Spacer(minLength: 0)
                            SpeakButton(text: sentence.es)
                        }
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))
            }
            HStack(spacing: 16) {
                stat("+\(xp)", "XP")
                if testPassed != nil {
                    stat("\(correct)/\(answered)", "Correct")
                } else {
                    stat("\(answered == 0 ? 100 : correct * 100 / answered)%", "Accuracy")
                }
            }
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(PrimaryButtonStyle(color: tone.fill))
        }
        .padding(24)
    }

    private var headline: String {
        switch testPassed {
        case .none: return "¡Lección completada!"
        case .some(true): return "¡Unidad superada!"
        case .some(false): return "¡Casi!"
        }
    }

    private var detail: String {
        switch testPassed {
        case .none: return lesson.mode.isReview ? language.localized("Your hearts are back.") : lesson.title
        case .some(true): return language.localized("You can jump to the next unit.")
        case .some(false): return language.localized("You need \(Lesson.testPassMark) of \(Lesson.testQuestions). The lessons will get you there.")
        }
    }

    private func stat(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(width: 110)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.card))
        .accessibilityElement(children: .combine)
    }
}
