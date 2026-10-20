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
                                   answered: session.answered) { dismiss() }
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
        case .frame(let card):
            FrameCardView(card: card, language: store.language) { submit(.correct) }
        case .legoSnap(let snap):
            LegoSnapView(snap: snap, language: store.language, onSubmit: submit)
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
        store.completeLesson(session.lesson.id, xp: session.completionXP)
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
        case .wrong: return "Not quite"
        }
    }

    private var note: String? {
        switch feedback.outcome {
        case .correct: return nil
        case .accent(let expected): return "Watch the accents: \(expected)"
        case .wrong(let hint): return hint
        }
    }
}

struct LessonCompleteView: View {
    let lesson: Lesson
    let xp: Int
    let correct: Int
    let answered: Int
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "trophy.fill")
                .font(.system(size: 64))
                .foregroundStyle(.yellow)
            Text("¡Lección completada!")
                .font(.title.bold())
            Text(lesson.title)
                .font(.title3)
                .foregroundStyle(.secondary)
            HStack(spacing: 16) {
                stat("+\(xp)", "XP")
                stat("\(answered == 0 ? 100 : correct * 100 / answered)%", "Accuracy")
            }
            Spacer()
            Button("Done", action: onDone)
                .buttonStyle(PrimaryButtonStyle())
        }
        .padding(24)
    }

    private func stat(_ value: String, _ label: String) -> some View {
        VStack {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(width: 110)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.card))
    }
}
