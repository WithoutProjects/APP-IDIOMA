import SwiftUI

/// "¿Qué tiempo es?": see a verb form, pick its tense.
struct TenseQuizView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.tone) private var tone
    @State private var started = false
    @State private var deck: VerbDeck?
    @State private var questions: [TenseQuiz.Question] = []
    @State private var index = 0
    @State private var picked: VerbTense?
    @State private var score = 0
    @State private var missed: [VerbDeck.Card] = []
    @State private var finished = false
    @State private var newRecord = false

    var body: some View {
        VStack(spacing: 20) {
            if !started {
                GameIntro(icon: "clock.arrow.circlepath", rules: Self.rules.text(language),
                          record: GameTexts.record(store.best(in: LabGame.tensesId), of: TenseQuiz.rounds, language: language),
                          onStart: begin)
            } else if finished {
                GameResults(score: "\(score)/\(questions.count)", newRecord: newRecord,
                            record: GameTexts.record(store.best(in: LabGame.tensesId), of: TenseQuiz.rounds, language: language) ?? "",
                            xp: SentenceGames.xp(score: score),
                            review: missed.map { GameResults.Review(prompt: "\($0.tense.name.text(language)) · \($0.person.label)", answer: $0.form.text) },
                            emptyMessage: questions.isEmpty ? SprintGameView.nothingYet.text(language) : nil,
                            onAgain: begin)
            } else if index < questions.count {
                playing(questions[index])
            }
        }
        .padding(20)
        .navigationTitle("¿Qué tiempo es?")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var language: NativeLanguage { store.language }

    private func playing(_ question: TenseQuiz.Question) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(index), total: Double(questions.count))
            VStack(spacing: 8) {
                ColoredForm(form: question.card.form, font: .system(.largeTitle, design: .rounded).weight(.bold))
                Text(verbatim: question.card.verb.lemma + (deck?.meanings[question.card.verb.lemma].map { " · " + $0.text(language) } ?? ""))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 26)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
            .accessibilityElement(children: .combine)
            ForEach(question.options) { tense in
                option(tense, question: question)
            }
            Spacer()
            if picked != nil {
                Button(ErrorHuntView.next.text(language), action: advance)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private func option(_ tense: VerbTense, question: TenseQuiz.Question) -> some View {
        let isAnswer = tense == question.card.tense
        let showRight = picked != nil && isAnswer
        let showWrong = picked == tense && !isAnswer
        let border: Color = showRight ? Palette.success : showWrong ? Palette.warning : .clear
        return Button {
            pick(tense, question: question)
        } label: {
            HStack {
                Text(tense.name.text(language))
                    .font(.headline)
                Spacer()
                Text(verbatim: tense.model)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal, 18)
            .frame(maxWidth: .infinity, minHeight: 54)
            .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(showRight ? Palette.success.opacity(0.15) : showWrong ? Palette.warning.opacity(0.15) : Palette.card))
            .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(border, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(picked != nil)
    }

    private func begin() {
        let built = VerbDeck(completed: store.state.completedLessons, words: store.learnedWords)
        deck = built
        questions = TenseQuiz.questions(deck: built)
        index = 0
        picked = nil
        score = 0
        missed = []
        newRecord = false
        finished = questions.isEmpty
        started = true
    }

    private func pick(_ tense: VerbTense, question: TenseQuiz.Question) {
        guard picked == nil else { return }
        picked = tense
        let right = tense == question.card.tense
        store.recordForms([question.card.key], correct: right)
        if right { score += 1 } else { missed.append(question.card) }
    }

    private func advance() {
        picked = nil
        index += 1
        if index >= questions.count {
            newRecord = store.recordScore(score, in: LabGame.tensesId)
            store.addXP(SentenceGames.xp(score: score))
            finished = true
        }
    }

    static let rules = Gloss(en: "A verb form appears. Which tense is it? Each tense shows hablar as a model.",
                             it: "Appare una forma verbale. Che tempo è? Ogni tempo mostra hablar come modello.",
                             uk: "З'являється форма дієслова. Який це час? Біля кожного часу є зразок із hablar.",
                             de: "Eine Verbform erscheint. Welche Zeitform ist es? Jede Zeitform zeigt hablar als Muster.",
                             fr: "Une forme verbale apparaît. Quel temps est-ce ? Chaque temps montre hablar comme modèle.",
                             pt: "Aparece uma forma verbal. Qual é o tempo? Cada tempo mostra hablar como modelo.",
                             zh: "屏幕上出现一个动词形式。它是什么时态？每个时态旁边都有 hablar 的例子。")
}
