import SwiftUI

/// "Máquina del tiempo": a form in one tense; write the same person in another tense.
struct TimeMachineView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.tone) private var tone
    @State private var started = false
    @State private var questions: [TimeMachine.Question] = []
    @State private var index = 0
    @State private var text = ""
    @State private var outcome: GradeOutcome?
    @State private var score = 0
    @State private var missed: [TimeMachine.Question] = []
    @State private var finished = false
    @State private var newRecord = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 20) {
            if !started {
                GameIntro(icon: "dial.medium", rules: Self.rules.text(language),
                          record: GameTexts.record(store.best(in: LabGame.timeMachineId), of: TimeMachine.rounds, language: language),
                          onStart: begin)
            } else if finished {
                GameResults(score: "\(score)/\(questions.count)", newRecord: newRecord,
                            record: GameTexts.record(store.best(in: LabGame.timeMachineId), of: TimeMachine.rounds, language: language) ?? "",
                            xp: SentenceGames.xp(score: score),
                            review: missed.map { GameResults.Review(prompt: "\($0.from.person.label) · \($0.to.name.text(language))", answer: $0.answer.text) },
                            emptyMessage: questions.isEmpty ? SprintGameView.nothingYet.text(language) : nil,
                            onAgain: begin)
            } else if index < questions.count {
                playing(questions[index])
            }
        }
        .padding(20)
        .navigationTitle("Máquina del tiempo")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var language: NativeLanguage { store.language }

    private func playing(_ question: TimeMachine.Question) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            ProgressView(value: Double(index), total: Double(questions.count))
            VStack(spacing: 14) {
                tenseChip(question.from.tense, filled: false)
                HStack(spacing: 8) {
                    Text(verbatim: question.from.person.label)
                        .foregroundStyle(.secondary)
                    ColoredForm(form: question.from.form, font: .system(.title, design: .rounded).weight(.bold))
                }
                Image(systemName: "arrow.down")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(tone.main)
                    .accessibilityHidden(true)
                tenseChip(question.to, filled: true)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 22)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
            .accessibilityElement(children: .combine)
            HStack {
                Text(verbatim: question.from.person.label)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                TextField(GameTexts.writeHere.text(language), text: $text)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .focused($focused)
                    .submitLabel(.done)
                    .onSubmit { if outcome == nil { check(question) } }
                    .font(.title3)
                    .disabled(outcome != nil)
            }
            .padding()
            .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))
            Spacer()
            if let outcome {
                GameFeedback(right: outcome.isCorrect, message: message(outcome),
                             spanish: "\(question.from.person.label.components(separatedBy: " / ")[0]) \(question.answer.text)",
                             onNext: advance)
            } else {
                Button(GameTexts.check.text(language)) { check(question) }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(Grader.normalize(text).isEmpty)
            }
        }
        .onAppear { focused = true }
    }

    private func tenseChip(_ tense: VerbTense, filled: Bool) -> some View {
        Text(verbatim: "\(tense.name.text(language)) · \(tense.model)")
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(filled ? Color.white : Color.primary)
            .padding(.horizontal, 14)
            .padding(.vertical, 7)
            .background(Capsule().fill(filled ? tone.fill : tone.soft))
    }

    private func message(_ outcome: GradeOutcome) -> String {
        switch outcome {
        case .correct: return GameTexts.right.text(language)
        case .accent: return GameTexts.accent.text(language)
        case .wrong: return GameTexts.wrong.text(language)
        }
    }

    private func begin() {
        let deck = VerbDeck(completed: store.state.completedLessons, words: store.learnedWords)
        questions = TimeMachine.questions(deck: deck, weak: Set(store.weakForms))
        index = 0
        text = ""
        outcome = nil
        score = 0
        missed = []
        newRecord = false
        finished = questions.isEmpty
        started = true
    }

    private func check(_ question: TimeMachine.Question) {
        focused = false
        let result = Grader.compare(text, accepted: [question.answer.text], hint: "")
        outcome = result
        store.recordForms([TimeMachine.key(question)], correct: result.isCorrect)
        if result.isCorrect { score += 1 } else { missed.append(question) }
    }

    private func advance() {
        text = ""
        outcome = nil
        index += 1
        if index >= questions.count {
            newRecord = store.recordScore(score, in: LabGame.timeMachineId)
            store.addXP(SentenceGames.xp(score: score))
            finished = true
        } else {
            focused = true
        }
    }

    static let rules = Gloss(en: "A verb in one tense. Write the same person in the tense shown below it.",
                             it: "Un verbo in un tempo. Scrivi la stessa persona nel tempo indicato sotto.",
                             uk: "Дієслово в одному часі. Напиши ту саму особу в часі, вказаному нижче.",
                             de: "Ein Verb in einer Zeitform. Schreib dieselbe Person in der Zeitform darunter.",
                             fr: "Un verbe à un temps. Écris la même personne au temps indiqué en dessous.",
                             pt: "Um verbo em um tempo. Escreva a mesma pessoa no tempo indicado embaixo.",
                             zh: "给出一个时态的动词。用下面标出的时态写出同一人称的形式。")
}
