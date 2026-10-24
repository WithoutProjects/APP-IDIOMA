import SwiftUI

/// "Dictado": hear a sentence from your lessons and write it. Tap the speaker twice to hear it slowly.
struct DictationView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.tone) private var tone
    @State private var started = false
    @State private var sentences: [PracticeSentence] = []
    @State private var index = 0
    @State private var text = ""
    @State private var outcome: GradeOutcome?
    @State private var score = 0
    @State private var missed: [PracticeSentence] = []
    @State private var finished = false
    @State private var newRecord = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 20) {
            if !started {
                GameIntro(icon: "ear", rules: Self.rules.text(language),
                          record: GameTexts.record(store.best(in: LabGame.dictationId), of: SentenceGames.rounds, language: language),
                          onStart: begin)
            } else if finished {
                GameResults(score: "\(score)/\(sentences.count)", newRecord: newRecord,
                            record: GameTexts.record(store.best(in: LabGame.dictationId), of: SentenceGames.rounds, language: language) ?? "",
                            xp: SentenceGames.xp(score: score),
                            review: missed.map { GameResults.Review(prompt: $0.example.gloss.text(language), answer: $0.example.es, spoken: $0.example.es) },
                            emptyMessage: sentences.isEmpty ? SentenceOrderView.nothingYet.text(language) : nil,
                            onAgain: begin)
            } else if index < sentences.count {
                playing(sentences[index])
            }
        }
        .padding(20)
        .navigationTitle("Dictado")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var language: NativeLanguage { store.language }

    private func playing(_ sentence: PracticeSentence) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            ProgressView(value: Double(index), total: Double(sentences.count))
            Button {
                Speaker.say(sentence.example.es)
            } label: {
                Label(Self.listen.text(language), systemImage: "speaker.wave.2.fill")
                    .font(.title3.weight(.semibold))
                    .frame(maxWidth: .infinity, minHeight: 88)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(tone.soft))
            }
            .buttonStyle(.plain)
            .foregroundStyle(tone.main)
            Text(Self.slowHint.text(language))
                .font(.footnote)
                .foregroundStyle(.secondary)
            TextField(GameTexts.writeHere.text(language), text: $text, axis: .vertical)
                .lineLimit(2...4)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .focused($focused)
                .font(.title3)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))
                .disabled(outcome != nil)
            if let outcome {
                Text(sentence.example.gloss.text(language))
                    .foregroundStyle(.secondary)
                Spacer()
                GameFeedback(right: outcome.isCorrect, message: message(outcome), spanish: sentence.example.es, onNext: advance)
            } else {
                Spacer()
                Button(GameTexts.check.text(language)) { check(sentence) }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(Grader.normalize(text).isEmpty)
            }
        }
    }

    private func message(_ outcome: GradeOutcome) -> String {
        switch outcome {
        case .correct: return GameTexts.right.text(language)
        case .accent: return GameTexts.accent.text(language)
        case .wrong: return GameTexts.wrong.text(language)
        }
    }

    private func begin() {
        sentences = SentenceGames.round(from: SentenceGames.pool(store.practiceSentences, words: 2...8))
        index = 0
        score = 0
        missed = []
        newRecord = false
        finished = sentences.isEmpty
        started = true
        if !finished { setUp() }
    }

    private func setUp() {
        text = ""
        outcome = nil
        Speaker.say(sentences[index].example.es)
    }

    private func check(_ sentence: PracticeSentence) {
        focused = false
        let result = SentenceGames.grade(text, sentence)
        outcome = result
        if result.isCorrect {
            score += 1
        } else {
            missed.append(sentence)
        }
    }

    private func advance() {
        index += 1
        if index < sentences.count {
            setUp()
        } else {
            newRecord = store.recordScore(score, in: LabGame.dictationId)
            store.addXP(SentenceGames.xp(score: score))
            finished = true
        }
    }

    static let rules = Gloss(en: "Listen to a sentence from your lessons and write it in Spanish. Accents count as right, with a note.",
                             it: "Ascolta una frase delle tue lezioni e scrivila in spagnolo. Gli accenti sbagliati valgono comunque, con una nota.",
                             uk: "Послухай речення з твоїх уроків і напиши його іспанською. Помилки в наголосах зараховуються, з приміткою.",
                             de: "Hör einen Satz aus deinen Lektionen und schreib ihn auf Spanisch. Fehlende Akzente zählen als richtig, mit einem Hinweis.",
                             fr: "Écoute une phrase de tes leçons et écris-la en espagnol. Les accents oubliés comptent comme justes, avec une remarque.",
                             pt: "Ouça uma frase das suas lições e escreva em espanhol. Erros de acento contam como certos, com um aviso.",
                             zh: "听一句你课程里的句子，用西班牙语写下来。重音符号写错也算对，会有提示。")
    static let listen = Gloss(en: "Listen", it: "Ascolta", uk: "Слухати", de: "Anhören", fr: "Écouter", pt: "Ouvir", zh: "听")
    static let slowHint = Gloss(en: "Tap again to hear it slowly.", it: "Tocca di nuovo per ascoltarla piano.", uk: "Торкнися ще раз, щоб почути повільніше.", de: "Tippe noch einmal, um ihn langsam zu hören.", fr: "Touche encore pour l'entendre lentement.", pt: "Toque de novo para ouvir devagar.", zh: "再点一次可以慢速收听。")
}
