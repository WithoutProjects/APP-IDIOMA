import SwiftUI

/// "Caza de errores": read sentences from your lessons and tap the verb that is wrong,
/// or say the sentence is fine. Three misses end the run.
struct ErrorHuntView: View {
    private enum Answer: Equatable {
        case word(Int)
        case allGood
    }

    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @Environment(\.tone) private var tone
    @State private var started = false
    @State private var rounds: [ErrorHunt.Round] = []
    @State private var index = 0
    @State private var answer: Answer?
    @State private var score = 0
    @State private var lives = ErrorHunt.lives
    @State private var finished = false
    @State private var newRecord = false

    var body: some View {
        VStack(spacing: 20) {
            if !started {
                intro
            } else if finished {
                results
            } else if index < rounds.count {
                playing(rounds[index])
            }
        }
        .padding(20)
        .navigationTitle("Caza de errores")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var language: NativeLanguage { store.language }

    // MARK: Start

    private var intro: some View {
        VStack(spacing: 20) {
            Spacer()
            ToneTile(size: 88, filled: true) {
                Image(systemName: "magnifyingglass").font(.system(size: 40, weight: .semibold))
            }
            Text(Self.rules.text(language))
                .font(.title3)
                .multilineTextAlignment(.center)
            if store.best(in: LabGame.huntId) > 0 {
                Text(SprintGameView.bestLabel.text(language) + " \(store.best(in: LabGame.huntId))")
                    .font(.headline)
                    .foregroundStyle(tone.main)
            }
            Spacer()
            Button(SprintGameView.start.text(language)) { begin() }
                .buttonStyle(PrimaryButtonStyle())
        }
    }

    // MARK: Playing

    private func playing(_ round: ErrorHunt.Round) -> some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                HStack(spacing: 6) {
                    ForEach(0..<ErrorHunt.lives, id: \.self) { life in
                        Circle()
                            .fill(life < lives ? tone.main : tone.soft)
                            .frame(width: 12, height: 12)
                    }
                }
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Self.livesLabel.text(language) + " \(lives)")
                Spacer()
                Label { Text(verbatim: "\(score)") } icon: { Image(systemName: "checkmark.circle.fill") }
                    .font(.headline)
                    .monospacedDigit()
                    .foregroundStyle(tone.main)
                    .accessibilityLabel(SprintGameView.scoreLabel.text(language) + " \(score)")
            }
            Text(Self.question.text(language))
                .font(.headline)
            FlowLayout(spacing: 8) {
                ForEach(Array(round.words.enumerated()), id: \.offset) { position, word in
                    wordButton(word, at: position, in: round)
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
            Text(round.gloss.text(language))
                .foregroundStyle(.secondary)
            Spacer()
            if let answer {
                feedback(round, answer: answer)
            } else {
                Button(Self.allGood.text(language)) { choose(.allGood, in: round) }
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
    }

    private func wordButton(_ word: String, at position: Int, in round: ErrorHunt.Round) -> some View {
        let isWrongVerb = round.wrongRange?.contains(position) == true
        let tapped = answer == .word(position)
        let reveal = answer != nil && isWrongVerb
        let color: Color = reveal ? (tapped ? Palette.success : Palette.warning) : tapped ? Palette.warning : .primary
        return Button {
            choose(.word(position), in: round)
        } label: {
            Text(verbatim: word)
                .font(.title3)
                .foregroundStyle(color)
                .padding(.horizontal, 8)
                .padding(.vertical, 6)
                .background(RoundedRectangle(cornerRadius: 10).fill(reveal || tapped ? color.opacity(0.15) : Color.clear))
        }
        .buttonStyle(.plain)
        .disabled(answer != nil)
    }

    private func feedback(_ round: ErrorHunt.Round, answer: Answer) -> some View {
        let right = isRight(answer, in: round)
        let corrected = correctedSentence(round)
        return VStack(alignment: .leading, spacing: 12) {
            Label(message(round, answer: answer), systemImage: right ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline)
                .foregroundStyle(right ? Palette.success : Palette.warning)
            if !round.isCorrect {
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: corrected)
                    Spacer(minLength: 8)
                    SpeakButton(text: corrected)
                }
            }
            Button(Self.next.text(language)) { advance() }
                .buttonStyle(PrimaryButtonStyle())
        }
        .accessibilityElement(children: .contain)
    }

    // MARK: Game flow

    private func begin() {
        let deck = VerbDeck(completed: store.state.completedLessons, words: store.learnedWords)
        rounds = ErrorHunt.rounds(from: store.huntSentences, deck: deck)
        index = 0
        answer = nil
        score = 0
        lives = ErrorHunt.lives
        newRecord = false
        finished = rounds.isEmpty
        started = true
    }

    private func isRight(_ answer: Answer, in round: ErrorHunt.Round) -> Bool {
        switch answer {
        case .allGood: return round.isCorrect
        case .word(let position): return round.wrongRange?.contains(position) == true
        }
    }

    private func choose(_ choice: Answer, in round: ErrorHunt.Round) {
        guard answer == nil else { return }
        answer = choice
        let right = isRight(choice, in: round)
        if !round.isCorrect {
            store.recordForms([round.key], correct: right)
        }
        if right {
            score += 1
        } else {
            lives -= 1
        }
    }

    private func advance() {
        answer = nil
        index += 1
        if lives == 0 || index >= rounds.count { finish() }
    }

    private func finish() {
        guard !finished else { return }
        newRecord = store.recordScore(score, in: LabGame.huntId)
        store.addXP(ErrorHunt.xp(score: score))
        finished = true
    }

    /// The sentence as it should be, with the verb put right.
    private func correctedSentence(_ round: ErrorHunt.Round) -> String {
        guard let range = round.wrongRange, let wrong = round.wrongForm else { return round.words.joined(separator: " ") }
        var words = round.words
        let shown = words[range].joined(separator: " ")
        words.replaceSubrange(range, with: [shown.replacingOccurrences(of: wrong, with: round.rightForm)])
        return words.joined(separator: " ")
    }

    private func message(_ round: ErrorHunt.Round, answer: Answer) -> String {
        let right = isRight(answer, in: round)
        if round.isCorrect {
            return (right ? Self.rightAllGood : Self.wasFine).text(language)
        }
        let template = right ? Self.spotted : Self.missed
        return template.text(language)
            .replacingOccurrences(of: "{wrong}", with: round.wrongForm ?? "")
            .replacingOccurrences(of: "{right}", with: round.rightForm)
            .replacingOccurrences(of: "{subject}", with: round.subject)
    }

    // MARK: Results

    private var results: some View {
        VStack(spacing: 18) {
            Spacer()
            Image(systemName: newRecord ? "trophy.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(tone.main)
                .accessibilityHidden(true)
            if rounds.isEmpty {
                Text(Self.nothingYet.text(language))
                    .multilineTextAlignment(.center)
            } else {
                Text(verbatim: "\(score)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .accessibilityLabel(SprintGameView.scoreLabel.text(language) + " \(score)")
                Text(newRecord ? SprintGameView.recordLabel.text(language)
                     : SprintGameView.bestLabel.text(language) + " \(store.best(in: LabGame.huntId))")
                    .font(.headline)
                    .foregroundStyle(newRecord ? tone.main : Color.secondary)
                if lives > 0 {
                    Text(Self.readAll.text(language))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                Text(verbatim: "+\(ErrorHunt.xp(score: score)) XP")
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if !rounds.isEmpty {
                Button(SprintGameView.again.text(language)) { begin() }
                    .buttonStyle(PrimaryButtonStyle())
            }
            Button(SprintGameView.back.text(language)) { dismiss() }
        }
    }

    // MARK: Texts

    static let rules = Gloss(en: "Sentences from your lessons. Some have a verb in the wrong person: tap it. If the sentence is right, say so. Three misses and the hunt is over.",
                             it: "Frasi delle tue lezioni. In alcune c'è un verbo nella persona sbagliata: toccalo. Se la frase è giusta, dillo. Tre errori e la caccia finisce.",
                             uk: "Речення з твоїх уроків. У деяких дієслово стоїть у неправильній особі: торкнися його. Якщо речення правильне, так і скажи. Три помилки — і полювання закінчено.",
                             de: "Sätze aus deinen Lektionen. In manchen steht ein Verb in der falschen Person: Tippe es an. Wenn der Satz stimmt, sag es. Nach drei Fehlern ist die Jagd vorbei.",
                             fr: "Des phrases de tes leçons. Dans certaines, un verbe est à la mauvaise personne : touche-le. Si la phrase est juste, dis-le. Trois erreurs et la chasse est finie.",
                             pt: "Frases das suas lições. Em algumas, um verbo está na pessoa errada: toque nele. Se a frase estiver certa, diga isso. Com três erros, a caça acaba.",
                             zh: "来自你课程的句子。有些句子里有一个动词的人称错了：点它。如果句子是对的，就选“没有错误”。错三次游戏结束。")
    static let question = Gloss(en: "Is there a wrong verb? Tap it.", it: "C'è un verbo sbagliato? Toccalo.", uk: "Є неправильне дієслово? Торкнися його.", de: "Steckt ein falsches Verb drin? Tippe es an.", fr: "Y a-t-il un verbe faux ? Touche-le.", pt: "Tem um verbo errado? Toque nele.", zh: "有错误的动词吗？点它。")
    static let allGood = Gloss(en: "No mistakes", it: "Nessun errore", uk: "Помилок немає", de: "Kein Fehler", fr: "Aucune erreur", pt: "Nenhum erro", zh: "没有错误")
    static let next = Gloss(en: "Next", it: "Avanti", uk: "Далі", de: "Weiter", fr: "Suivant", pt: "Próxima", zh: "下一个")
    static let livesLabel = Gloss(en: "Misses left:", it: "Errori rimasti:", uk: "Залишилось спроб:", de: "Verbleibende Fehler:", fr: "Erreurs restantes :", pt: "Erros restantes:", zh: "剩余机会：")
    static let spotted = Gloss(en: "Well spotted: with {subject} it's «{right}», not «{wrong}».",
                               it: "Visto bene: con {subject} si dice «{right}», non «{wrong}».",
                               uk: "Добре помічено: з {subject} буде «{right}», а не «{wrong}».",
                               de: "Gut erkannt: Mit {subject} heißt es «{right}», nicht «{wrong}».",
                               fr: "Bien vu : avec {subject}, c'est «{right}», pas «{wrong}».",
                               pt: "Boa: com {subject} é «{right}», não «{wrong}».",
                               zh: "找得好：跟 {subject} 搭配的是「{right}」，不是「{wrong}」。")
    static let missed = Gloss(en: "The wrong verb was «{wrong}»: with {subject} it's «{right}».",
                              it: "Il verbo sbagliato era «{wrong}»: con {subject} si dice «{right}».",
                              uk: "Неправильне дієслово — «{wrong}»: з {subject} буде «{right}».",
                              de: "Das falsche Verb war «{wrong}»: Mit {subject} heißt es «{right}».",
                              fr: "Le verbe faux était «{wrong}» : avec {subject}, c'est «{right}».",
                              pt: "O verbo errado era «{wrong}»: com {subject} é «{right}».",
                              zh: "错误的动词是「{wrong}」：跟 {subject} 搭配的是「{right}」。")
    static let rightAllGood = Gloss(en: "Right, this sentence has no mistakes.", it: "Giusto, questa frase non ha errori.", uk: "Так, у цьому реченні немає помилок.", de: "Richtig, dieser Satz ist fehlerfrei.", fr: "Exact, cette phrase n'a pas d'erreur.", pt: "Isso, esta frase não tem erros.", zh: "对，这个句子没有错误。")
    static let wasFine = Gloss(en: "This sentence was right.", it: "Questa frase era giusta.", uk: "Це речення було правильним.", de: "Dieser Satz war richtig.", fr: "Cette phrase était juste.", pt: "Esta frase estava certa.", zh: "这个句子是对的。")
    static let readAll = Gloss(en: "You've read every sentence you know. Finish more lessons for new ones.",
                               it: "Hai letto tutte le frasi che conosci. Finisci altre lezioni per averne di nuove.",
                               uk: "Ти прочитав усі речення, які знаєш. Заверши більше уроків, щоб отримати нові.",
                               de: "Du hast alle Sätze gelesen, die du kennst. Schließ weitere Lektionen ab, um neue zu bekommen.",
                               fr: "Tu as lu toutes les phrases que tu connais. Termine d'autres leçons pour en avoir de nouvelles.",
                               pt: "Você leu todas as frases que conhece. Termine mais lições para ter novas.",
                               zh: "你已经读完了所有学过的句子。完成更多课程来解锁新句子。")
    static let nothingYet = Gloss(en: "Finish a few more lessons: this game uses sentences you have already learned.",
                                  it: "Finisci qualche altra lezione: questo gioco usa frasi che hai già imparato.",
                                  uk: "Заверши ще кілька уроків: ця гра використовує речення, які ти вже вивчив.",
                                  de: "Schließ noch ein paar Lektionen ab: Dieses Spiel nutzt Sätze, die du schon gelernt hast.",
                                  fr: "Termine encore quelques leçons : ce jeu utilise des phrases que tu as déjà apprises.",
                                  pt: "Termine mais algumas lições: este jogo usa frases que você já aprendeu.",
                                  zh: "再完成几节课吧：这个游戏使用你已经学过的句子。")
}
