import SwiftUI

/// "Termina el refrán": the start of a Spanish saying with its literal translation; pick
/// the end. Then the whole saying is read aloud with what it means.
struct SayingsView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.tone) private var tone
    @State private var started = false
    @State private var questions: [SayingsGame.Question] = []
    @State private var index = 0
    @State private var picked: Saying?
    @State private var score = 0
    @State private var missed: [Saying] = []
    @State private var finished = false
    @State private var newRecord = false

    var body: some View {
        VStack(spacing: 20) {
            if !started {
                GameIntro(icon: "quote.bubble", rules: Self.rules.text(language),
                          record: GameTexts.record(store.best(in: LabGame.sayingsId), of: SayingsGame.rounds, language: language),
                          onStart: begin)
            } else if finished {
                GameResults(score: "\(score)/\(questions.count)", newRecord: newRecord,
                            record: GameTexts.record(store.best(in: LabGame.sayingsId), of: SayingsGame.rounds, language: language) ?? "",
                            xp: SayingsGame.xp(score: score),
                            review: missed.map { GameResults.Review(prompt: $0.meaning.text(language), answer: $0.spanish, spoken: $0.spanish) },
                            emptyMessage: questions.isEmpty ? Self.nothingYet.text(language) : nil,
                            onAgain: begin)
            } else if index < questions.count {
                playing(questions[index])
            }
        }
        .padding(20)
        .navigationTitle("Termina el refrán")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var language: NativeLanguage { store.language }

    private func playing(_ question: SayingsGame.Question) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ProgressView(value: Double(index), total: Double(questions.count))
                VStack(alignment: .leading, spacing: 8) {
                    Text(verbatim: picked == nil ? question.saying.start + " …" : question.saying.spanish)
                        .font(.system(.title2, design: .rounded).weight(.bold))
                    Text(verbatim: picked == nil ? question.saying.startLiteral.text(language) + " …" : question.saying.literal(language))
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(20)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
                .accessibilityElement(children: .combine)
                ForEach(question.options) { option in
                    GameOption(title: option.end, detail: option.endLiteral.text(language),
                               isAnswer: option == question.saying, isPicked: picked == option, revealed: picked != nil) {
                        pick(option, question: question)
                    }
                }
                if let picked {
                    VStack(alignment: .leading, spacing: 12) {
                        Label(picked == question.saying ? GameTexts.right.text(language) : Self.wrong.text(language),
                              systemImage: picked == question.saying ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .font(.headline)
                            .foregroundStyle(picked == question.saying ? Palette.success : Palette.warning)
                        HStack(alignment: .firstTextBaseline) {
                            Eyebrow(text: Self.meansLabel.text(language))
                            Spacer(minLength: 8)
                            SpeakButton(text: question.saying.spanish)
                        }
                        Text(verbatim: question.saying.meaning.text(language))
                        Button(ErrorHuntView.next.text(language), action: advance)
                            .buttonStyle(PrimaryButtonStyle())
                    }
                    .padding(.top, 4)
                }
            }
        }
    }

    private func begin() {
        questions = SayingsGame.questions(from: SayingBook.shared.open(completed: store.state.completedLessons))
        index = 0
        picked = nil
        score = 0
        missed = []
        newRecord = false
        finished = questions.isEmpty
        started = true
    }

    private func pick(_ option: Saying, question: SayingsGame.Question) {
        guard picked == nil else { return }
        picked = option
        Speaker.say(question.saying.spanish)
        if option == question.saying { score += 1 } else { missed.append(question.saying) }
    }

    private func advance() {
        picked = nil
        index += 1
        if index >= questions.count {
            newRecord = store.recordScore(score, in: LabGame.sayingsId)
            store.addXP(SayingsGame.xp(score: score))
            finished = true
        }
    }

    static let rules = Gloss(en: "Spanish sayings, with a word-for-word translation. Read the start and pick the end. Then you'll see what it really means.",
                             it: "Proverbi spagnoli, con la traduzione parola per parola. Leggi l'inizio e scegli la fine. Poi vedrai che cosa significa davvero.",
                             uk: "Іспанські прислів'я з дослівним перекладом. Прочитай початок і обери кінець. Потім побачиш, що воно насправді означає.",
                             de: "Spanische Sprichwörter mit Wort-für-Wort-Übersetzung. Lies den Anfang und wähle das Ende. Danach siehst du, was es wirklich bedeutet.",
                             fr: "Des proverbes espagnols, avec une traduction mot à mot. Lis le début et choisis la fin. Ensuite, tu verras ce qu'il veut vraiment dire.",
                             pt: "Ditados espanhóis, com tradução palavra por palavra. Leia o começo e escolha o final. Depois você vê o que ele quer dizer de verdade.",
                             zh: "西班牙俗语，附逐字翻译。读前半句，选出后半句。然后你会看到它真正的意思。")
    static let wrong = Gloss(en: "Not this one: the whole saying is above.", it: "Non è questa: il proverbio intero è qui sopra.", uk: "Не цей: усе прислів'я вгорі.", de: "Nicht dieses: Das ganze Sprichwort steht oben.", fr: "Pas celle-ci : le proverbe entier est au-dessus.", pt: "Não é esse: o ditado inteiro está acima.", zh: "不是这个：完整的俗语在上方。")
    static let meansLabel = Gloss(en: "What it means", it: "Che cosa significa", uk: "Що це означає", de: "Was es bedeutet", fr: "Ce que ça veut dire", pt: "O que significa", zh: "意思是")
    static let nothingYet = Gloss(en: "Sayings come later in the course. Keep going along the path to unlock them.",
                                  it: "I proverbi arrivano più avanti nel corso. Continua il percorso per sbloccarli.",
                                  uk: "Прислів'я з'являться пізніше в курсі. Просувайся шляхом, щоб їх відкрити.",
                                  de: "Sprichwörter kommen später im Kurs. Geh weiter auf deinem Weg, um sie freizuschalten.",
                                  fr: "Les proverbes arrivent plus tard dans le cours. Continue ton chemin pour les débloquer.",
                                  pt: "Os ditados chegam mais adiante no curso. Siga o caminho para desbloqueá-los.",
                                  zh: "俗语在课程后面才会出现。继续沿着学习路线前进来解锁吧。")
}
