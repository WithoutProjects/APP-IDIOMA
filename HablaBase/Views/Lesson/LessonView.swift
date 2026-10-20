import SwiftUI

struct LessonView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var session: LessonSession
    @State private var finished = false

    init(lesson: Lesson) {
        _session = StateObject(wrappedValue: LessonSession(lesson: lesson))
    }

    var body: some View {
        VStack(spacing: 0) {
            header
            if finished {
                LessonCompleteView(lesson: session.lesson,
                                   xp: session.completionXP,
                                   correct: session.correct,
                                   answered: session.answered,
                                   testPassed: session.isTest ? session.passedTest : nil) { dismiss() }
            } else if let item = session.current {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(item.beat.title.uppercased())
                            .font(.caption.weight(.bold))
                            .foregroundStyle(.secondary)
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
                .tint(Palette.success)
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
        switch item.kind {
        case .slides(let set):
            VocabSlidesView(set: set, language: store.language) { submit(.correct) }
        case .match(let set):
            VocabMatchView(set: set, language: store.language, onSubmit: submit)
        case .frame(let card):
            FrameCardView(card: card, language: store.language) { submit(.correct) }
        case .legoSnap(let snap):
            LegoSnapView(snap: snap, language: store.language, onSubmit: submit)
        case .gapFill(let gap):
            GapFillView(gap: gap, language: store.language, onSubmit: submit)
        case .builder(let builder):
            SentenceBuilderView(builder: builder, language: store.language, onSubmit: submit)
        case .freeWrite(let write):
            FreeWriteView(write: write, language: store.language, onSubmit: submit)
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
                    Text(model.es).font(.body.weight(.semibold))
                    Text(model.gloss.text(language)).font(.footnote).foregroundStyle(.secondary)
                }
            }
            Button("Continue", action: onContinue)
                .buttonStyle(PrimaryButtonStyle(color: color))
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
        case .wrong: return String(localized: "Not quite")
        }
    }

    private var note: String? {
        switch feedback.outcome {
        case .correct: return nil
        case .accent(let expected): return String(localized: "Watch the accents: \(expected)")
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
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: testPassed == false ? "arrow.counterclockwise.circle.fill" : "trophy.fill")
                .font(.system(size: 64))
                .accessibilityHidden(true)
                .foregroundStyle(testPassed == false ? Brick.stem.color : .yellow)
            Text(headline)
                .font(.title.bold())
                .multilineTextAlignment(.center)
            Text(detail)
                .font(.title3)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
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
                .buttonStyle(PrimaryButtonStyle())
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
        case .none: return lesson.title
        case .some(true): return String(localized: "You can jump to the next unit.")
        case .some(false): return String(localized: "You need \(Lesson.testPassMark) of \(Lesson.testQuestions). The lessons will get you there.")
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
