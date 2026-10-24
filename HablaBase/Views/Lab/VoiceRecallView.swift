import SwiftUI

/// "Dilo en español": see a word you've learned in your language, say it in Spanish.
/// Two tries per word, then the answer with its sound.
struct VoiceRecallView: View {
    private enum Result {
        case right, wrong
    }

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tone) private var tone
    @StateObject private var listener = SpeechListener()
    @State private var started = false
    @State private var cards: [VoiceRecall.Card] = []
    @State private var index = 0
    @State private var tries = 0
    @State private var result: Result?
    @State private var score = 0
    @State private var missed: [VoiceRecall.Card] = []
    @State private var finished = false
    @State private var newRecord = false

    var body: some View {
        VStack(spacing: 20) {
            if !started {
                intro
            } else if finished {
                results
            } else if index < cards.count {
                playing(cards[index])
            }
        }
        .padding(20)
        .navigationTitle("Dilo en español")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: listener.transcript) { _, heard in
            // Accept as soon as the right word is heard, without waiting for the end.
            guard result == nil, index < cards.count, VoiceRecall.matches(heard, card: cards[index]) else { return }
            listener.stop()
            settle(right: true)
        }
        .onChange(of: listener.isFinal) { _, done in
            guard done, result == nil, index < cards.count, !listener.transcript.isEmpty else { return }
            if VoiceRecall.matches(listener.transcript, card: cards[index]) {
                settle(right: true)
            } else {
                tries += 1
                if tries >= 2 { settle(right: false) }
            }
        }
        .onDisappear { listener.reset() }
    }

    private var language: NativeLanguage { store.language }

    // MARK: Start

    private var intro: some View {
        VStack(spacing: 20) {
            Spacer()
            ToneTile(size: 88, filled: true) {
                Image(systemName: "mic.fill").font(.system(size: 40, weight: .semibold))
            }
            Text(Self.rules.text(language))
                .font(.title3)
                .multilineTextAlignment(.center)
            if store.best(in: LabGame.voiceId) > 0 {
                Text(SprintGameView.bestLabel.text(language) + " \(store.best(in: LabGame.voiceId))/\(VoiceRecall.rounds)")
                    .font(.headline)
                    .foregroundStyle(tone.main)
            }
            Spacer()
            Button(SprintGameView.start.text(language)) { begin() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    // MARK: Playing

    private func playing(_ card: VoiceRecall.Card) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(index), total: Double(cards.count))
            Text(verbatim: "\(index + 1)/\(cards.count)")
                .font(.subheadline.weight(.semibold))
                .monospacedDigit()
                .foregroundStyle(.secondary)
            VStack(spacing: 8) {
                Text(Self.sayIt.text(language))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text(verbatim: card.prompt)
                    .font(.system(.largeTitle, design: .rounded).weight(.bold))
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 28)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
            .accessibilityElement(children: .combine)

            if let result {
                outcome(card, right: result == .right)
            } else {
                if !listener.transcript.isEmpty {
                    Text(verbatim: "«\(listener.transcript)»")
                        .font(.title3)
                        .foregroundStyle(listener.isFinal ? Palette.warning : Color.secondary)
                }
                if tries == 1, listener.status != .listening {
                    Text(Self.tryAgain.text(language))
                        .foregroundStyle(.secondary)
                }
                Spacer()
                MicButton(listener: listener)
                SpeechStatusNote(listener: listener)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
                Button(Self.showAnswer.text(language)) {
                    listener.reset()
                    settle(right: false)
                }
                .foregroundStyle(.secondary)
            }
        }
    }

    private func outcome(_ card: VoiceRecall.Card, right: Bool) -> some View {
        VStack(spacing: 16) {
            Label(right ? Self.rightLabel.text(language) : Self.answerLabel.text(language),
                  systemImage: right ? "checkmark.circle.fill" : "lightbulb.fill")
                .font(.headline)
                .foregroundStyle(right ? Palette.success : Palette.warning)
            ForEach(card.answers, id: \.self) { answer in
                HStack {
                    Text(verbatim: answer)
                        .font(.title2.weight(.semibold))
                    SpeakButton(text: answer)
                }
            }
            Spacer()
            Button(Self.next.text(language)) { advance() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    // MARK: Game flow

    private func begin() {
        let all = VoiceRecall.cards(from: store.learnedWords, language: language)
        cards = VoiceRecall.round(from: all)
        index = 0
        tries = 0
        result = nil
        score = 0
        missed = []
        newRecord = false
        listener.reset()
        finished = cards.isEmpty
        started = true
    }

    private func settle(right: Bool) {
        guard result == nil, index < cards.count else { return }
        result = right ? .right : .wrong
        if right {
            score += 1
        } else {
            missed.append(cards[index])
        }
    }

    private func advance() {
        listener.reset()
        result = nil
        tries = 0
        index += 1
        if index >= cards.count { finish() }
    }

    private func finish() {
        guard !finished else { return }
        newRecord = store.recordScore(score, in: LabGame.voiceId)
        store.addXP(VoiceRecall.xp(score: score))
        finished = true
    }

    // MARK: Results

    private var results: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: newRecord ? "trophy.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(tone.main)
                    .accessibilityHidden(true)
                if cards.isEmpty {
                    Text(SprintGameView.nothingYet.text(language))
                        .multilineTextAlignment(.center)
                } else {
                    Text(verbatim: "\(score)/\(cards.count)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                    Text(newRecord ? SprintGameView.recordLabel.text(language)
                         : SprintGameView.bestLabel.text(language) + " \(store.best(in: LabGame.voiceId))/\(VoiceRecall.rounds)")
                        .font(.headline)
                        .foregroundStyle(newRecord ? tone.main : Color.secondary)
                    Text(verbatim: "+\(VoiceRecall.xp(score: score)) XP")
                        .foregroundStyle(.secondary)
                }
                if !missed.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(text: SprintGameView.reviewLabel.text(language))
                        ForEach(missed) { card in
                            HStack {
                                Text(verbatim: card.prompt)
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(verbatim: card.answers.joined(separator: " / "))
                                    .font(.headline)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
                }
                if !cards.isEmpty {
                    Button(SprintGameView.again.text(language)) { begin() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                Button(SprintGameView.back.text(language)) { dismiss() }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Texts

    static let rules = Gloss(en: "A word you have learned appears in your language. Say it in Spanish. If there are several right answers, any of them counts.",
                             it: "Appare una parola che hai imparato, nella tua lingua. Dilla in spagnolo. Se ci sono più risposte giuste, vale qualsiasi.",
                             uk: "З'являється слово, яке ти вже вивчив, твоєю мовою. Скажи його іспанською. Якщо правильних відповідей кілька, підходить будь-яка.",
                             de: "Ein Wort, das du gelernt hast, erscheint in deiner Sprache. Sag es auf Spanisch. Gibt es mehrere richtige Antworten, zählt jede.",
                             fr: "Un mot que tu as appris apparaît dans ta langue. Dis-le en espagnol. S'il y a plusieurs bonnes réponses, n'importe laquelle compte.",
                             pt: "Aparece uma palavra que você já aprendeu, na sua língua. Diga em espanhol. Se houver várias respostas certas, qualquer uma vale.",
                             zh: "屏幕上会用你的语言显示一个学过的词。用西班牙语说出来。如果有几个正确答案，说哪个都算。")
    static let sayIt = Gloss(en: "Say it in Spanish", it: "Dillo in spagnolo", uk: "Скажи іспанською", de: "Sag es auf Spanisch", fr: "Dis-le en espagnol", pt: "Diga em espanhol", zh: "用西班牙语说")
    static let tryAgain = Gloss(en: "Not quite. Try once more.", it: "Non proprio. Riprova.", uk: "Не зовсім. Спробуй ще раз.", de: "Nicht ganz. Versuch es noch einmal.", fr: "Pas tout à fait. Essaie encore une fois.", pt: "Quase. Tente mais uma vez.", zh: "不太对。再试一次。")
    static let showAnswer = Gloss(en: "I don't remember", it: "Non me lo ricordo", uk: "Не пам'ятаю", de: "Weiß ich nicht mehr", fr: "Je ne m'en souviens pas", pt: "Não lembro", zh: "我想不起来")
    static let rightLabel = Gloss(en: "Right!", it: "Giusto!", uk: "Правильно!", de: "Richtig!", fr: "Juste !", pt: "Certo!", zh: "正确！")
    static let answerLabel = Gloss(en: "In Spanish:", it: "In spagnolo:", uk: "Іспанською:", de: "Auf Spanisch:", fr: "En espagnol :", pt: "Em espanhol:", zh: "西班牙语：")
    static let next = Gloss(en: "Next", it: "Avanti", uk: "Далі", de: "Weiter", fr: "Suivant", pt: "Próxima", zh: "下一个")
}
