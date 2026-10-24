import SwiftUI

/// "Contrarreloj": as many right forms as you can in 60 seconds. Beat your own record.
struct SprintGameView: View {
    private enum Phase {
        case ready, playing, done
    }

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tone) private var tone
    @State private var phase = Phase.ready
    @State private var deck: VerbDeck?
    @State private var question: SprintGame.Question?
    @State private var picked: VerbForm?
    @State private var score = 0
    @State private var inARow = 0
    @State private var endsAt = Date()
    @State private var now = Date()
    @State private var bonusShown = false
    @State private var missed: [VerbDeck.Card] = []
    @State private var newRecord = false
    /// True when the learner has no verbs to play with yet.
    @State private var emptyDeck = false

    var body: some View {
        VStack(spacing: 20) {
            switch phase {
            case .ready: intro
            case .playing: playing
            case .done: results
            }
        }
        .padding(20)
        .navigationTitle("Contrarreloj")
        .navigationBarTitleDisplayMode(.inline)
        .task(id: phase) { await runClock() }
    }

    private var language: NativeLanguage { store.language }
    private var secondsLeft: Int { max(0, Int(endsAt.timeIntervalSince(now).rounded(.up))) }

    // MARK: Start

    private var intro: some View {
        VStack(spacing: 20) {
            Spacer()
            ToneTile(size: 88, filled: true) {
                Image(systemName: "stopwatch").font(.system(size: 40, weight: .semibold))
            }
            Text(Self.rules.text(language))
                .font(.title3)
                .multilineTextAlignment(.center)
            if store.best(in: LabGame.sprintId) > 0 {
                Text(Self.bestLabel.text(language) + " \(store.best(in: LabGame.sprintId))")
                    .font(.headline)
                    .foregroundStyle(tone.main)
            }
            Spacer()
            Button(Self.start.text(language)) { begin() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    // MARK: Playing

    private var playing: some View {
        VStack(spacing: 20) {
            HStack {
                Label { Text(verbatim: "\(secondsLeft) s") } icon: { Image(systemName: "stopwatch") }
                    .monospacedDigit()
                    .foregroundStyle(secondsLeft <= 10 ? Palette.warning : Color.primary)
                    .accessibilityLabel(Self.timeLeft.text(language) + " \(secondsLeft)")
                if bonusShown {
                    Text(verbatim: "+\(SprintGame.bonusSeconds) s")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(Palette.success)
                        .transition(.opacity.combined(with: .move(edge: .bottom)))
                }
                Spacer()
                Label { Text(verbatim: "\(score)") } icon: { Image(systemName: "checkmark.circle.fill") }
                    .monospacedDigit()
                    .foregroundStyle(tone.main)
                    .accessibilityLabel(Self.scoreLabel.text(language) + " \(score)")
            }
            .font(.headline)
            ProgressView(value: Double(min(secondsLeft, SprintGame.seconds)), total: Double(SprintGame.seconds))
                .accessibilityHidden(true)
            if let question {
                prompt(question.card)
                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(question.options, id: \.text) { option in
                        optionButton(option, question: question)
                    }
                }
            }
            Spacer()
        }
    }

    private func prompt(_ card: VerbDeck.Card) -> some View {
        VStack(spacing: 10) {
            HStack(spacing: 8) {
                Text(verbatim: card.person.label)
                    .font(.headline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(tone.soft))
                Text(verbatim: "\(card.tense.name.text(language)) · \(card.tense.model)")
                    .font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(Palette.card))
            }
            Text(verbatim: card.verb.lemma)
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                .foregroundStyle(Brick.stem.color)
            if let meaning = deck?.meanings[card.verb.lemma] {
                Text(meaning.text(language))
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 22)
        .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
        .accessibilityElement(children: .combine)
    }

    private func optionButton(_ option: VerbForm, question: SprintGame.Question) -> some View {
        let isAnswer = option == question.answer
        let showRight = picked != nil && isAnswer
        let showWrong = picked == option && !isAnswer
        let border: Color = showRight ? Palette.success : showWrong ? Palette.warning : .clear
        return Button {
            pick(option)
        } label: {
            ColoredForm(form: option, font: .title3.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, minHeight: 64)
                .padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(showRight ? Palette.success.opacity(0.15) : showWrong ? Palette.warning.opacity(0.15) : Palette.card))
                .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).strokeBorder(border, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(picked != nil)
        .accessibilityLabel(option.text)
    }

    // MARK: Game flow

    private func begin() {
        let built = VerbDeck(completed: store.state.completedLessons, words: store.learnedWords)
        deck = built
        score = 0
        inARow = 0
        missed = []
        newRecord = false
        picked = nil
        now = Date()
        endsAt = now.addingTimeInterval(TimeInterval(SprintGame.seconds))
        question = SprintGame.question(deck: built, weak: Set(store.weakForms))
        emptyDeck = question == nil
        phase = emptyDeck ? .done : .playing
    }

    private func pick(_ option: VerbForm) {
        guard picked == nil, phase == .playing, let question, let deck else { return }
        picked = option
        let right = option == question.answer
        store.recordForms([question.card.key], correct: right)
        if right {
            score += 1
            inARow += 1
            if inARow % SprintGame.bonusEvery == 0 {
                endsAt = endsAt.addingTimeInterval(TimeInterval(SprintGame.bonusSeconds))
                withAnimation { bonusShown = true }
                Task { @MainActor in
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    withAnimation { bonusShown = false }
                }
            }
        } else {
            inARow = 0
            if !missed.contains(question.card) { missed.append(question.card) }
        }
        // A wrong answer stays on screen long enough to read the right form.
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: right ? 250_000_000 : 1_100_000_000)
            guard phase == .playing else { return }
            picked = nil
            self.question = SprintGame.question(deck: deck, weak: Set(store.weakForms), after: question.card)
        }
    }

    /// Ticks the clock while a run is on and ends it at zero.
    @MainActor
    private func runClock() async {
        while phase == .playing {
            try? await Task.sleep(nanoseconds: 100_000_000)
            now = Date()
            if now >= endsAt { finish() }
        }
    }

    private func finish() {
        guard phase == .playing else { return }
        newRecord = store.recordScore(score, in: LabGame.sprintId)
        store.addXP(SprintGame.xp(score: score))
        picked = nil
        phase = .done
    }

    // MARK: Results

    private var results: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: newRecord ? "trophy.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(tone.main)
                    .accessibilityHidden(true)
                if emptyDeck {
                    Text(Self.nothingYet.text(language))
                        .multilineTextAlignment(.center)
                } else {
                    Text(verbatim: "\(score)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .accessibilityLabel(Self.scoreLabel.text(language) + " \(score)")
                    Text(newRecord ? Self.recordLabel.text(language)
                         : Self.bestLabel.text(language) + " \(store.best(in: LabGame.sprintId))")
                        .font(.headline)
                        .foregroundStyle(newRecord ? tone.main : Color.secondary)
                    Text(verbatim: "+\(SprintGame.xp(score: score)) XP")
                        .foregroundStyle(.secondary)
                }
                if !missed.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Eyebrow(text: Self.reviewLabel.text(language))
                        ForEach(missed, id: \.self) { card in
                            HStack {
                                Text(verbatim: "\(card.verb.lemma) · \(card.person.label)")
                                    .foregroundStyle(.secondary)
                                Spacer()
                                ColoredForm(form: card.form, font: .headline)
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
                }
                if !emptyDeck {
                    Button(Self.again.text(language)) { begin() }
                        .buttonStyle(PrimaryButtonStyle())
                }
                Button(Self.back.text(language)) { dismiss() }
            }
            .frame(maxWidth: .infinity)
        }
    }

    // MARK: Texts

    static let rules = Gloss(en: "60 seconds. Pick the right form of each verb. Every 5 right in a row gives you 3 more seconds.",
                             it: "60 secondi. Scegli la forma giusta di ogni verbo. Ogni 5 risposte giuste di fila guadagni 3 secondi.",
                             uk: "60 секунд. Обери правильну форму кожного дієслова. Кожні 5 правильних відповідей поспіль дають 3 секунди.",
                             de: "60 Sekunden. Wähle die richtige Form jedes Verbs. Alle 5 richtigen Antworten in Folge bekommst du 3 Sekunden dazu.",
                             fr: "60 secondes. Choisis la bonne forme de chaque verbe. Toutes les 5 bonnes réponses d'affilée, tu gagnes 3 secondes.",
                             pt: "60 segundos. Escolha a forma certa de cada verbo. A cada 5 acertos seguidos, você ganha 3 segundos.",
                             zh: "60 秒。为每个动词选出正确的形式。每连续答对 5 题，多得 3 秒。")
    static let start = Gloss(en: "Start", it: "Inizia", uk: "Почати", de: "Los geht's", fr: "Commencer", pt: "Começar", zh: "开始")
    static let bestLabel = Gloss(en: "Your record:", it: "Il tuo record:", uk: "Твій рекорд:", de: "Dein Rekord:", fr: "Ton record :", pt: "Seu recorde:", zh: "你的纪录：")
    static let recordLabel = Gloss(en: "New record!", it: "Nuovo record!", uk: "Новий рекорд!", de: "Neuer Rekord!", fr: "Nouveau record !", pt: "Novo recorde!", zh: "新纪录！")
    static let scoreLabel = Gloss(en: "Right answers:", it: "Risposte giuste:", uk: "Правильних відповідей:", de: "Richtige Antworten:", fr: "Bonnes réponses :", pt: "Acertos:", zh: "答对：")
    static let timeLeft = Gloss(en: "Seconds left:", it: "Secondi rimasti:", uk: "Залишилось секунд:", de: "Verbleibende Sekunden:", fr: "Secondes restantes :", pt: "Segundos restantes:", zh: "剩余秒数：")
    static let reviewLabel = Gloss(en: "To review", it: "Da ripassare", uk: "Повторити", de: "Zum Wiederholen", fr: "À revoir", pt: "Para revisar", zh: "需要复习")
    static let again = Gloss(en: "Play again", it: "Gioca ancora", uk: "Грати ще", de: "Nochmal spielen", fr: "Rejouer", pt: "Jogar de novo", zh: "再玩一次")
    static let back = Gloss(en: "Back to the Lab", it: "Torna al Lab", uk: "Назад до Лабораторії", de: "Zurück zum Lab", fr: "Retour au Lab", pt: "Voltar ao Lab", zh: "返回实验室")
    static let nothingYet = Gloss(en: "Finish your first lesson to unlock the verbs for this game.",
                                  it: "Finisci la prima lezione per sbloccare i verbi di questo gioco.",
                                  uk: "Заверши перший урок, щоб відкрити дієслова для цієї гри.",
                                  de: "Schließ deine erste Lektion ab, um die Verben für dieses Spiel freizuschalten.",
                                  fr: "Termine ta première leçon pour débloquer les verbes de ce jeu.",
                                  pt: "Termine sua primeira lição para liberar os verbos deste jogo.",
                                  zh: "完成第一课即可解锁本游戏的动词。")
}
