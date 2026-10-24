import SwiftUI

/// "Ordena la frase": a sentence from your lessons with its words mixed up. Tap them in order.
struct SentenceOrderView: View {
    private struct Tile: Identifiable, Hashable {
        let id: Int
        let text: String
    }

    @EnvironmentObject private var store: AppStore
    @Environment(\.tone) private var tone
    @State private var started = false
    @State private var sentences: [PracticeSentence] = []
    @State private var index = 0
    @State private var tray: [Tile] = []
    @State private var placed: [Tile] = []
    @State private var outcome: GradeOutcome?
    @State private var score = 0
    @State private var missed: [PracticeSentence] = []
    @State private var finished = false
    @State private var newRecord = false

    var body: some View {
        VStack(spacing: 20) {
            if !started {
                GameIntro(icon: "list.number", rules: Self.rules.text(language),
                          record: GameTexts.record(store.best(in: LabGame.orderId), of: SentenceGames.rounds, language: language),
                          onStart: begin)
            } else if finished {
                GameResults(score: "\(score)/\(sentences.count)", newRecord: newRecord,
                            record: GameTexts.record(store.best(in: LabGame.orderId), of: SentenceGames.rounds, language: language) ?? "",
                            xp: SentenceGames.xp(score: score),
                            review: missed.map { GameResults.Review(prompt: $0.example.gloss.text(language), answer: $0.example.es, spoken: $0.example.es) },
                            emptyMessage: sentences.isEmpty ? Self.nothingYet.text(language) : nil,
                            onAgain: begin)
            } else if index < sentences.count {
                playing(sentences[index])
            }
        }
        .padding(20)
        .navigationTitle("Ordena la frase")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var language: NativeLanguage { store.language }

    // MARK: Playing

    private func playing(_ sentence: PracticeSentence) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            ProgressView(value: Double(index), total: Double(sentences.count))
            Text(sentence.example.gloss.text(language))
                .font(.title3.weight(.semibold))
            // The sentence being built: tap a word to send it back.
            FlowLayout(spacing: 8) {
                ForEach(placed) { tile in
                    tileButton(tile, filled: true) {
                        guard outcome == nil else { return }
                        placed.removeAll { $0 == tile }
                        tray.append(tile)
                    }
                }
            }
            .frame(maxWidth: .infinity, minHeight: 60, alignment: .topLeading)
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).strokeBorder(tone.main.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [5])))
            FlowLayout(spacing: 8) {
                ForEach(tray) { tile in
                    tileButton(tile, filled: false) {
                        guard outcome == nil else { return }
                        tray.removeAll { $0 == tile }
                        placed.append(tile)
                    }
                }
            }
            Spacer()
            if let outcome {
                GameFeedback(right: outcome.isCorrect, message: message(outcome), spanish: sentence.example.es, onNext: advance)
            } else {
                Button(GameTexts.check.text(language)) { check(sentence) }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!tray.isEmpty)
                    .opacity(tray.isEmpty ? 1 : 0.5)
            }
        }
    }

    private func tileButton(_ tile: Tile, filled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(verbatim: tile.text)
                .font(.title3)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(filled ? tone.soft : Palette.card))
        }
        .buttonStyle(.plain)
    }

    private func message(_ outcome: GradeOutcome) -> String {
        switch outcome {
        case .correct: return GameTexts.right.text(language)
        case .accent: return GameTexts.right.text(language)
        case .wrong: return GameTexts.wrong.text(language)
        }
    }

    // MARK: Game flow

    private func begin() {
        sentences = SentenceGames.round(from: SentenceGames.pool(store.practiceSentences, words: 3...9))
        index = 0
        score = 0
        missed = []
        newRecord = false
        finished = sentences.isEmpty
        started = true
        if !finished { setUp() }
    }

    private func setUp() {
        tray = SentenceGames.tiles(for: sentences[index]).enumerated().map { Tile(id: $0.offset, text: $0.element) }
        placed = []
        outcome = nil
    }

    private func check(_ sentence: PracticeSentence) {
        let result = SentenceGames.grade(placed.map(\.text).joined(separator: " "), sentence)
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
            newRecord = store.recordScore(score, in: LabGame.orderId)
            store.addXP(SentenceGames.xp(score: score))
            finished = true
        }
    }

    static let rules = Gloss(en: "Sentences from your lessons, with the words mixed up. Tap them in the right order.",
                             it: "Frasi delle tue lezioni con le parole in disordine. Toccale nell'ordine giusto.",
                             uk: "Речення з твоїх уроків, слова переплутані. Торкайся їх у правильному порядку.",
                             de: "Sätze aus deinen Lektionen mit durcheinandergewürfelten Wörtern. Tippe sie in der richtigen Reihenfolge an.",
                             fr: "Des phrases de tes leçons aux mots mélangés. Touche-les dans le bon ordre.",
                             pt: "Frases das suas lições com as palavras embaralhadas. Toque nelas na ordem certa.",
                             zh: "来自你课程的句子，词序被打乱了。按正确的顺序点击单词。")
    static let nothingYet = Gloss(en: "Finish a couple more lessons: this game uses sentences you have already learned.",
                                  it: "Finisci ancora un paio di lezioni: questo gioco usa frasi che hai già imparato.",
                                  uk: "Заверши ще кілька уроків: ця гра використовує речення, які ти вже вивчив.",
                                  de: "Schließ noch ein paar Lektionen ab: Dieses Spiel nutzt Sätze, die du schon gelernt hast.",
                                  fr: "Termine encore quelques leçons : ce jeu utilise des phrases que tu as déjà apprises.",
                                  pt: "Termine mais algumas lições: este jogo usa frases que você já aprendeu.",
                                  zh: "再完成几节课吧：这个游戏使用你已经学过的句子。")
}
