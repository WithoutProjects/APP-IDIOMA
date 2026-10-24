import SwiftUI

/// "Parejas de palabras": tap a word in your language, then its Spanish partner.
/// A right pair is read aloud in Spanish.
struct WordMatchView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tone) private var tone
    @State private var rounds: [[VoiceRecall.Card]] = []
    @State private var round = 0
    @State private var spanishOrder: [VoiceRecall.Card] = []
    @State private var selected: VoiceRecall.Card?
    @State private var matched: Set<String> = []
    @State private var missed: [VoiceRecall.Card] = []
    @State private var wrongSpanish: String?
    @State private var score = 0
    @State private var startedAt = Date()
    @State private var finished = false
    @State private var newRecord = false

    var body: some View {
        VStack(spacing: 20) {
            if finished {
                results
            } else if round < rounds.count {
                ProgressView(value: Double(round), total: Double(rounds.count))
                Text(Self.rules.text(language))
                    .font(.headline)
                    .multilineTextAlignment(.center)
                HStack(alignment: .top, spacing: 14) {
                    VStack(spacing: 12) {
                        ForEach(rounds[round]) { card in
                            nativeCard(card)
                        }
                    }
                    VStack(spacing: 12) {
                        ForEach(spanishOrder) { card in
                            spanishCard(card)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(20)
        .navigationTitle("Parejas de palabras")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear(perform: start)
    }

    private var language: NativeLanguage { store.language }

    // MARK: Cards

    private func nativeCard(_ card: VoiceRecall.Card) -> some View {
        let done = matched.contains(card.id)
        let isSelected = selected == card
        return Button {
            if !done { selected = card }
        } label: {
            Text(verbatim: card.prompt)
                .font(.headline)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 14).fill(isSelected ? tone.soft : Palette.card))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(isSelected ? tone.main : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .opacity(done ? 0.25 : 1)
        .disabled(done)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func spanishCard(_ card: VoiceRecall.Card) -> some View {
        let done = matched.contains(card.id)
        let text = WordMatch.spanish(card)
        let isWrong = wrongSpanish == card.id
        return Button {
            pick(card)
        } label: {
            Text(verbatim: text)
                .font(.headline)
                .foregroundStyle(isWrong ? Palette.warning : tone.main)
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 56)
                .padding(.horizontal, 8)
                .background(RoundedRectangle(cornerRadius: 14).fill(isWrong ? Palette.warning.opacity(0.15) : Palette.card))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(isWrong ? Palette.warning : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .opacity(done ? 0.25 : 1)
        .disabled(done || selected == nil)
    }

    // MARK: Game flow

    private func start() {
        guard rounds.isEmpty, !finished else { return }
        let cards = VoiceRecall.cards(from: store.learnedWords, language: language)
        rounds = WordMatch.rounds(from: cards)
        round = 0
        score = 0
        matched = []
        missed = []
        newRecord = false
        startedAt = Date()
        if rounds.isEmpty { finished = true } else { beginRound() }
    }

    private func beginRound() {
        spanishOrder = rounds[round].shuffled()
        selected = nil
    }

    private func pick(_ card: VoiceRecall.Card) {
        guard let chosen = selected else { return }
        if chosen == card {
            withAnimation(.spring(response: 0.3)) { matched.insert(card.id) }
            if !missed.contains(card) { score += 1 }
            Speaker.say(card.answers[0])
            selected = nil
            if rounds[round].allSatisfy({ matched.contains($0.id) }) {
                round += 1
                if round < rounds.count { beginRound() } else { finish() }
            }
        } else {
            if !missed.contains(chosen) { missed.append(chosen) }
            withAnimation(.easeInOut(duration: 0.2)) { wrongSpanish = card.id }
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 500_000_000)
                withAnimation { wrongSpanish = nil }
            }
        }
    }

    private func finish() {
        guard !finished else { return }
        newRecord = store.recordScore(score, in: LabGame.wordMatchId)
        store.addXP(WordMatch.xp(score: score))
        finished = true
    }

    private var total: Int { rounds.reduce(0) { $0 + $1.count } }

    // MARK: Results

    private var results: some View {
        let seconds = Int(Date().timeIntervalSince(startedAt))
        return ScrollView {
            VStack(spacing: 18) {
                Image(systemName: newRecord ? "trophy.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(tone.main)
                    .accessibilityHidden(true)
                if rounds.isEmpty {
                    Text(SprintGameView.nothingYet.text(language))
                        .multilineTextAlignment(.center)
                } else {
                    Text(verbatim: "\(score)/\(total)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                    Text(newRecord ? SprintGameView.recordLabel.text(language)
                         : SprintGameView.bestLabel.text(language) + " \(store.best(in: LabGame.wordMatchId))")
                        .font(.headline)
                        .foregroundStyle(newRecord ? tone.main : Color.secondary)
                    Text(verbatim: "\(seconds) s · +\(WordMatch.xp(score: score)) XP")
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
                                Text(verbatim: WordMatch.spanish(card))
                                    .font(.headline)
                                SpeakButton(text: card.answers[0])
                            }
                        }
                    }
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
                }
                if !rounds.isEmpty {
                    Button(SprintGameView.again.text(language)) {
                        rounds = []
                        finished = false
                        start()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                }
                Button(SprintGameView.back.text(language)) { dismiss() }
            }
            .frame(maxWidth: .infinity)
        }
    }

    static let rules = Gloss(en: "Match each word with its Spanish.", it: "Abbina ogni parola al suo spagnolo.", uk: "З'єднай кожне слово з іспанським.", de: "Ordne jedem Wort sein spanisches Wort zu.", fr: "Associe chaque mot à son équivalent espagnol.", pt: "Ligue cada palavra ao seu espanhol.", zh: "把每个词和它的西班牙语配对。")
}
