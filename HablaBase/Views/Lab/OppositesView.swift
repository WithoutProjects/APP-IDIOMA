import SwiftUI

/// "Contrarios": a word you've learned; pick its opposite among four words you know.
struct OppositesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var started = false
    @State private var questions: [Opposites.Question] = []
    @State private var index = 0
    @State private var picked: VocabWord?
    @State private var score = 0
    @State private var missed: [Opposites.Question] = []
    @State private var finished = false
    @State private var newRecord = false

    var body: some View {
        VStack(spacing: 20) {
            if !started {
                GameIntro(icon: "arrow.left.arrow.right", rules: Self.rules.text(language),
                          record: GameTexts.record(store.best(in: LabGame.oppositesId), of: Opposites.rounds, language: language),
                          onStart: begin)
            } else if finished {
                GameResults(score: "\(score)/\(questions.count)", newRecord: newRecord,
                            record: GameTexts.record(store.best(in: LabGame.oppositesId), of: Opposites.rounds, language: language) ?? "",
                            xp: Opposites.xp(score: score),
                            review: missed.map { GameResults.Review(prompt: meaning($0.word) + " ↔ " + meaning($0.answer),
                                                                    answer: "\($0.word.es) ↔ \($0.answer.es)", spoken: $0.answer.es) },
                            emptyMessage: questions.isEmpty ? Self.nothingYet.text(language) : nil,
                            onAgain: begin)
            } else if index < questions.count {
                playing(questions[index])
            }
        }
        .padding(20)
        .navigationTitle("Contrarios")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var language: NativeLanguage { store.language }

    private func meaning(_ word: VocabWord) -> String {
        VoiceRecall.shownMeaning(word.gloss.text(language))
    }

    private func playing(_ question: Opposites.Question) -> some View {
        VStack(spacing: 16) {
            ProgressView(value: Double(index), total: Double(questions.count))
            VStack(spacing: 8) {
                HStack(spacing: 8) {
                    Text(verbatim: question.word.es)
                        .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    SpeakButton(text: question.word.es)
                }
                Text(verbatim: meaning(question.word))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
            Text(Self.question.text(language))
                .font(.headline)
                .foregroundStyle(.secondary)
            ForEach(question.options, id: \.self) { option in
                GameOption(title: option.es, detail: picked == nil ? nil : meaning(option),
                           isAnswer: option == question.answer, isPicked: picked == option, revealed: picked != nil) {
                    pick(option, question: question)
                }
            }
            Spacer()
            if picked != nil {
                Button(ErrorHuntView.next.text(language), action: advance)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private func begin() {
        questions = Opposites.questions(words: store.learnedWords)
        index = 0
        picked = nil
        score = 0
        missed = []
        newRecord = false
        finished = questions.isEmpty
        started = true
    }

    private func pick(_ option: VocabWord, question: Opposites.Question) {
        guard picked == nil else { return }
        picked = option
        Speaker.say(question.answer.es)
        if option == question.answer { score += 1 } else { missed.append(question) }
    }

    private func advance() {
        picked = nil
        index += 1
        if index >= questions.count {
            newRecord = store.recordScore(score, in: LabGame.oppositesId)
            store.addXP(Opposites.xp(score: score))
            finished = true
        }
    }

    static let rules = Gloss(en: "A word you've learned appears. Pick its opposite. After each answer you see what every option means.",
                             it: "Appare una parola che hai imparato. Scegli il suo contrario. Dopo ogni risposta vedi che cosa significa ogni opzione.",
                             uk: "З'являється вивчене слово. Обери його протилежність. Після кожної відповіді побачиш значення всіх варіантів.",
                             de: "Ein gelerntes Wort erscheint. Wähle sein Gegenteil. Nach jeder Antwort siehst du, was jede Option bedeutet.",
                             fr: "Un mot que tu as appris apparaît. Choisis son contraire. Après chaque réponse, tu vois le sens de chaque option.",
                             pt: "Aparece uma palavra que você aprendeu. Escolha o contrário dela. Depois de cada resposta, você vê o que cada opção significa.",
                             zh: "屏幕上出现一个学过的词。选出它的反义词。每次回答后，你会看到每个选项的意思。")
    static let question = Gloss(en: "What's the opposite?", it: "Qual è il contrario?", uk: "Яка протилежність?", de: "Was ist das Gegenteil?", fr: "Quel est le contraire ?", pt: "Qual é o contrário?", zh: "反义词是什么？")
    static let nothingYet = Gloss(en: "Learn a few more pairs of opposites in your lessons, like alto and bajo, to play.",
                                  it: "Impara qualche altra coppia di contrari nelle lezioni, come alto e bajo, per giocare.",
                                  uk: "Вивчи на уроках ще кілька пар протилежностей, як-от alto і bajo, щоб грати.",
                                  de: "Lerne in deinen Lektionen noch ein paar Gegensatzpaare wie alto und bajo, um zu spielen.",
                                  fr: "Apprends encore quelques paires de contraires dans tes leçons, comme alto et bajo, pour jouer.",
                                  pt: "Aprenda mais alguns pares de opostos nas lições, como alto e bajo, para jogar.",
                                  zh: "在课程中再学几组反义词，比如 alto 和 bajo，就可以玩了。")
}
