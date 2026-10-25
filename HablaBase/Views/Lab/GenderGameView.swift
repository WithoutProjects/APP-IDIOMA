import SwiftUI

/// "¿El o la?": a noun you've learned without its article. Tap el or la. A right answer
/// moves on by itself; a wrong one stops to show the article and, for the words that break
/// the pattern, why.
struct GenderGameView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.tone) private var tone
    @State private var started = false
    @State private var cards: [GenderGame.Card] = []
    @State private var index = 0
    @State private var picked: String?
    @State private var score = 0
    @State private var missed: [GenderGame.Card] = []
    @State private var finished = false
    @State private var newRecord = false

    var body: some View {
        VStack(spacing: 20) {
            if !started {
                GameIntro(icon: "textformat", rules: Self.rules.text(language),
                          record: GameTexts.record(store.best(in: LabGame.genderId), of: GenderGame.rounds, language: language),
                          onStart: begin)
            } else if finished {
                GameResults(score: "\(score)/\(cards.count)", newRecord: newRecord,
                            record: GameTexts.record(store.best(in: LabGame.genderId), of: GenderGame.rounds, language: language) ?? "",
                            xp: GenderGame.xp(score: score),
                            review: missed.map { GameResults.Review(prompt: $0.meaning, answer: $0.spanish, spoken: $0.spanish) },
                            emptyMessage: cards.isEmpty ? Self.nothingYet.text(language) : nil,
                            onAgain: begin)
            } else if index < cards.count {
                playing(cards[index])
            }
        }
        .padding(20)
        .navigationTitle("¿El o la?")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var language: NativeLanguage { store.language }

    private func playing(_ card: GenderGame.Card) -> some View {
        VStack(spacing: 20) {
            ProgressView(value: Double(index), total: Double(cards.count))
            VStack(spacing: 8) {
                HStack(spacing: 10) {
                    Text(verbatim: picked == nil ? "___" : card.article)
                        .foregroundStyle(picked == nil ? Color.secondary : tone.main)
                    Text(verbatim: card.noun)
                }
                .font(.system(.largeTitle, design: .rounded).weight(.bold))
                Text(verbatim: card.meaning)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 30)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
            .accessibilityElement(children: .combine)
            HStack(spacing: 14) {
                articleButton("el", card: card)
                articleButton("la", card: card)
            }
            Spacer()
            if let picked, picked != card.article {
                GameFeedback(right: false, message: wrongMessage(card), spanish: card.spanish, onNext: advance)
            }
        }
    }

    private func articleButton(_ article: String, card: GenderGame.Card) -> some View {
        let revealed = picked != nil
        let isAnswer = article == card.article
        let showRight = revealed && isAnswer
        let showWrong = revealed && picked == article && !isAnswer
        return Button {
            pick(article, card: card)
        } label: {
            Text(verbatim: article)
                .font(.system(.title, design: .rounded).weight(.bold))
                .frame(maxWidth: .infinity, minHeight: 96)
                .foregroundStyle(showRight ? Palette.success : showWrong ? Palette.warning : tone.main)
                .background(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(showRight ? Palette.success.opacity(0.15) : showWrong ? Palette.warning.opacity(0.15) : tone.soft))
                .overlay(RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .strokeBorder(showRight ? Palette.success : showWrong ? Palette.warning : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .disabled(revealed)
    }

    private func wrongMessage(_ card: GenderGame.Card) -> String {
        let base = GameTexts.wrong.text(language) + " " + card.spanish
        guard let tip = GenderGame.tip(for: card) else { return base }
        let text: Gloss
        switch tip {
        case .stressedA: text = Self.stressedATip
        case .masculineInA: text = Self.masculineInATip
        case .feminineInO: text = Self.feminineInOTip
        }
        return base + ". " + text.text(language)
    }

    private func begin() {
        cards = GenderGame.round(from: GenderGame.cards(from: store.learnedWords, language: language))
        index = 0
        picked = nil
        score = 0
        missed = []
        newRecord = false
        finished = cards.isEmpty
        started = true
    }

    private func pick(_ article: String, card: GenderGame.Card) {
        guard picked == nil else { return }
        picked = article
        Speaker.say(card.spanish)
        if article == card.article {
            score += 1
            let current = index
            Task { @MainActor in
                try? await Task.sleep(nanoseconds: 700_000_000)
                if index == current, picked != nil { advance() }
            }
        } else {
            missed.append(card)
        }
    }

    private func advance() {
        picked = nil
        index += 1
        if index >= cards.count {
            newRecord = store.recordScore(score, in: LabGame.genderId)
            store.addXP(GenderGame.xp(score: score))
            finished = true
        }
    }

    static let rules = Gloss(en: "A word you've learned appears without its article. Is it el or la? Go as fast as you can.",
                             it: "Appare una parola che hai imparato senza articolo. È el o la? Vai più veloce che puoi.",
                             uk: "З'являється вивчене слово без артикля. Це el чи la? Відповідай якомога швидше.",
                             de: "Ein gelerntes Wort erscheint ohne Artikel. Ist es el oder la? So schnell du kannst.",
                             fr: "Un mot que tu as appris apparaît sans article. C'est el ou la ? Va le plus vite possible.",
                             pt: "Aparece uma palavra que você aprendeu, sem o artigo. É el ou la? Vá o mais rápido que puder.",
                             zh: "屏幕上出现一个学过的名词，但没有冠词。是 el 还是 la？尽量快点回答。")
    static let nothingYet = Gloss(en: "This game opens with the words of your lessons. Finish one more lesson with new words.",
                                  it: "Questo gioco usa le parole delle tue lezioni. Finisci un'altra lezione con parole nuove.",
                                  uk: "Ця гра використовує слова з твоїх уроків. Пройди ще один урок з новими словами.",
                                  de: "Dieses Spiel nutzt die Wörter deiner Lektionen. Schließ noch eine Lektion mit neuen Wörtern ab.",
                                  fr: "Ce jeu utilise les mots de tes leçons. Termine encore une leçon avec de nouveaux mots.",
                                  pt: "Este jogo usa as palavras das suas lições. Termine mais uma lição com palavras novas.",
                                  zh: "这个游戏使用你课程里的词。再完成一节有新词的课吧。")
    static let stressedATip = Gloss(en: "It's a feminine word, but it takes el because it starts with a stressed a: el agua.",
                                    it: "È una parola femminile, ma vuole el perché comincia con una a tonica: el agua.",
                                    uk: "Це слово жіночого роду, але з артиклем el, бо починається з наголошеного a: el agua.",
                                    de: "Das Wort ist weiblich, bekommt aber el, weil es mit betontem a beginnt: el agua.",
                                    fr: "C'est un mot féminin, mais il prend el parce qu'il commence par un a accentué : el agua.",
                                    pt: "É uma palavra feminina, mas leva el porque começa com a tônico: el agua.",
                                    zh: "这是阴性词，但因为以重读的 a 开头，所以用 el：el agua。")
    static let masculineInATip = Gloss(en: "Most words ending in -a are feminine, but this one is masculine.",
                                       it: "Quasi tutte le parole in -a sono femminili, ma questa è maschile.",
                                       uk: "Більшість слів на -a жіночого роду, але це слово чоловічого.",
                                       de: "Die meisten Wörter auf -a sind weiblich, dieses ist männlich.",
                                       fr: "La plupart des mots en -a sont féminins, mais celui-ci est masculin.",
                                       pt: "A maioria das palavras terminadas em -a é feminina, mas esta é masculina.",
                                       zh: "大多数以 -a 结尾的词是阴性，但这个词是阳性。")
    static let feminineInOTip = Gloss(en: "Most words ending in -o are masculine, but this one is feminine.",
                                      it: "Quasi tutte le parole in -o sono maschili, ma questa è femminile.",
                                      uk: "Більшість слів на -o чоловічого роду, але це слово жіночого.",
                                      de: "Die meisten Wörter auf -o sind männlich, dieses ist weiblich.",
                                      fr: "La plupart des mots en -o sont masculins, mais celui-ci est féminin.",
                                      pt: "A maioria das palavras terminadas em -o é masculina, mas esta é feminina.",
                                      zh: "大多数以 -o 结尾的词是阳性，但这个词是阴性。")
}
