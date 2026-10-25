import SwiftUI

/// "¿Qué significa?": hear and see a Spanish word you've learned, pick what it means.
struct MeaningQuizView: View {
    @EnvironmentObject private var store: AppStore
    @State private var started = false
    @State private var questions: [MeaningQuiz.Question] = []
    @State private var index = 0
    @State private var picked: String?
    @State private var score = 0
    @State private var missed: [MeaningQuiz.Card] = []
    @State private var finished = false
    @State private var newRecord = false

    var body: some View {
        VStack(spacing: 20) {
            if !started {
                GameIntro(icon: "questionmark.bubble", rules: Self.rules.text(language),
                          record: GameTexts.record(store.best(in: LabGame.meaningId), of: MeaningQuiz.rounds, language: language),
                          onStart: begin)
            } else if finished {
                GameResults(score: "\(score)/\(questions.count)", newRecord: newRecord,
                            record: GameTexts.record(store.best(in: LabGame.meaningId), of: MeaningQuiz.rounds, language: language) ?? "",
                            xp: MeaningQuiz.xp(score: score),
                            review: missed.map { GameResults.Review(prompt: $0.meaning, answer: $0.spanish, spoken: $0.spoken) },
                            emptyMessage: questions.isEmpty ? SprintGameView.nothingYet.text(language) : nil,
                            onAgain: begin)
            } else if index < questions.count {
                playing(questions[index])
            }
        }
        .padding(20)
        .navigationTitle("¿Qué significa?")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var language: NativeLanguage { store.language }

    private func playing(_ question: MeaningQuiz.Question) -> some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(questions.count))
            HStack(spacing: 8) {
                Text(verbatim: question.card.spanish)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.center)
                SpeakButton(text: question.card.spoken)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 26)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
            Text(Self.question.text(language))
                .font(.headline)
                .foregroundStyle(.secondary)
            ForEach(question.options, id: \.self) { meaning in
                GameOption(title: meaning, isAnswer: meaning == question.card.meaning,
                           isPicked: picked == meaning, revealed: picked != nil) {
                    pick(meaning, question: question)
                }
            }
            Spacer()
            if picked != nil {
                Button(ErrorHuntView.next.text(language), action: advance)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
        .onAppear { Speaker.say(question.card.spoken) }
        .id(question.id)
    }

    private func begin() {
        let cards = MeaningQuiz.cards(from: store.learnedWords, language: language)
        questions = MeaningQuiz.questions(from: cards)
        index = 0
        picked = nil
        score = 0
        missed = []
        newRecord = false
        finished = questions.isEmpty
        started = true
    }

    private func pick(_ meaning: String, question: MeaningQuiz.Question) {
        guard picked == nil else { return }
        picked = meaning
        if meaning == question.card.meaning { score += 1 } else { missed.append(question.card) }
    }

    private func advance() {
        picked = nil
        index += 1
        if index >= questions.count {
            newRecord = store.recordScore(score, in: LabGame.meaningId)
            store.addXP(MeaningQuiz.xp(score: score))
            finished = true
        }
    }

    static let rules = Gloss(en: "A Spanish word you've learned appears and you hear it. Pick what it means.",
                             it: "Appare una parola spagnola che hai imparato e la senti. Scegli che cosa significa.",
                             uk: "З'являється іспанське слово, яке ти вивчив, і ти його чуєш. Обери, що воно означає.",
                             de: "Ein spanisches Wort, das du gelernt hast, erscheint, und du hörst es. Wähle, was es bedeutet.",
                             fr: "Un mot espagnol que tu as appris apparaît et tu l'entends. Choisis ce qu'il veut dire.",
                             pt: "Aparece uma palavra em espanhol que você aprendeu, e você a ouve. Escolha o que ela significa.",
                             zh: "屏幕上会出现一个学过的西班牙语词，并读给你听。选出它的意思。")
    static let question = Gloss(en: "What does it mean?", it: "Che cosa significa?", uk: "Що це означає?", de: "Was bedeutet das?", fr: "Qu'est-ce que ça veut dire ?", pt: "O que significa?", zh: "这是什么意思？")
}
