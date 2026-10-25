import Foundation

/// Picks a round from a list in learning order: half from the newest items, the rest from
/// anywhere, so recent words come back more often.
enum LabRound {
    static func pick<T: Hashable>(from items: [T], count: Int) -> [T] {
        let recent = Array(items.suffix(30)).shuffled()
        var picked = Array(recent.prefix(count / 2))
        for item in items.shuffled() where picked.count < count && !picked.contains(item) {
            picked.append(item)
        }
        return picked.shuffled()
    }
}

/// "¿Qué significa?": a Spanish word the learner has met is shown and read aloud; they pick
/// its meaning in their own language from four.
enum MeaningQuiz {
    static let rounds = 10
    static let optionCount = 4

    struct Card: Identifiable, Hashable {
        /// As shown: "él / ella".
        let spanish: String
        /// The meaning in the learner's language, without notes in brackets: "he / she".
        let meaning: String
        let kind: Brick

        var id: String { spanish }
        /// What the voice reads: the first way to say it.
        var spoken: String { VoiceRecall.variants(of: spanish).first ?? spanish }
    }

    struct Question: Identifiable, Hashable {
        let id = UUID()
        let card: Card
        /// The right meaning and up to three others, shuffled. No two mean the same.
        let options: [String]
    }

    /// One card per Spanish word, in the order the path taught them.
    static func cards(from words: [VocabWord], language: NativeLanguage) -> [Card] {
        var seen: Set<String> = []
        var cards: [Card] = []
        for word in words {
            let meaning = VoiceRecall.shownMeaning(word.gloss.text(language))
            let variants = VoiceRecall.variants(of: word.es).filter { $0.split(separator: " ").count <= VoiceRecall.maxWords }
            guard !Grader.normalize(meaning).isEmpty, !variants.isEmpty else { continue }
            // A word spelt the same in both languages ("pizza") is no test.
            if variants.contains(where: { VoiceRecall.simplified($0) == VoiceRecall.simplified(meaning) }) { continue }
            let spanish = variants.joined(separator: " / ")
            guard seen.insert(VoiceRecall.simplified(spanish)).inserted else { continue }
            cards.append(Card(spanish: spanish, meaning: meaning, kind: word.kind))
        }
        return cards
    }

    static func questions(from cards: [Card], count: Int = rounds) -> [Question] {
        guard cards.count >= 2 else { return [] }
        return LabRound.pick(from: cards, count: count).compactMap { card in
            let options = self.options(for: card, among: cards)
            return options.count >= 2 ? Question(card: card, options: options) : nil
        }
    }

    /// Wrong meanings come from words of the same kind first (a verb with verbs), so the
    /// answer can't be guessed from its shape.
    static func options(for card: Card, among cards: [Card]) -> [String] {
        var used: Set<String> = [Grader.normalize(card.meaning)]
        var wrong: [String] = []
        let others = cards.filter { $0 != card }.shuffled()
        let sameKind = others.filter { $0.kind == card.kind }
        for other in sameKind + others where wrong.count < optionCount - 1 {
            if used.insert(Grader.normalize(other.meaning)).inserted {
                wrong.append(other.meaning)
            }
        }
        return ([card.meaning] + wrong).shuffled()
    }

    static func xp(score: Int) -> Int { 2 + score }
}

/// "¿El o la?": a noun without its article; tap el or la. Fast rounds with a tip for the
/// words that break the -o / -a pattern.
enum GenderGame {
    static let rounds = 15

    struct Card: Identifiable, Hashable {
        let article: String
        let noun: String
        let meaning: String

        var id: String { noun }
        var spanish: String { "\(article) \(noun)" }
    }

    enum Tip: Equatable {
        /// el agua: a feminine word that takes el because it starts with a stressed a.
        case stressedA
        /// el día, el problema.
        case masculineInA
        /// la mano, la foto.
        case feminineInO
    }

    /// Feminine words that take el in the singular, because they start with a stressed a.
    static let stressedA: Set<String> = ["agua", "alma", "aula", "área", "arma", "hambre", "águila", "hacha", "ala", "ave", "arpa", "hada", "asma"]

    /// Single nouns from the vocabulary slides with el or la ("la casa"). A noun the slides give
    /// with both articles ("el capital", "la capital") is left out: either answer would be right.
    static func cards(from words: [VocabWord], language: NativeLanguage) -> [Card] {
        var cards: [Card] = []
        var articles: [String: Set<String>] = [:]
        for word in words {
            let parts = word.es.split(separator: " ").map(String.init)
            guard parts.count == 2, parts[0] == "el" || parts[0] == "la",
                  parts[1].allSatisfy({ $0.isLetter }) else { continue }
            articles[parts[1], default: []].insert(parts[0])
            let meaning = VoiceRecall.shownMeaning(word.gloss.text(language))
            if !cards.contains(where: { $0.noun == parts[1] }) {
                cards.append(Card(article: parts[0], noun: parts[1], meaning: meaning))
            }
        }
        return cards.filter { articles[$0.noun]?.count == 1 }
    }

    static func round(from cards: [Card], count: Int = rounds) -> [Card] {
        LabRound.pick(from: cards, count: count)
    }

    static func tip(for card: Card) -> Tip? {
        if card.article == "el", stressedA.contains(card.noun) { return .stressedA }
        if card.article == "el", card.noun.hasSuffix("a") { return .masculineInA }
        if card.article == "la", card.noun.hasSuffix("o") { return .feminineInO }
        return nil
    }

    static func xp(score: Int) -> Int { min(20, 2 + score) }
}

/// "Contrarios": a word appears; pick its opposite from four words the learner knows.
enum Opposites {
    static let rounds = 10
    static let optionCount = 4

    /// Opposites as the vocabulary slides write them. A pair is asked once both words are learned.
    static let pairs: [(String, String)] = [
        ("grande", "pequeño"), ("alto", "bajo"), ("caro", "barato"), ("bueno", "malo"),
        ("abrir", "cerrar"), ("cerca de", "lejos de"), ("siempre", "nunca"), ("antes de", "después de"),
        ("rápido", "lento"), ("fácil", "difícil"), ("temprano", "tarde"), ("contento", "triste"),
        ("empezar", "terminar"), ("entrar", "salir"), ("ir", "venir"), ("comprar", "vender"),
        ("subir", "bajar"), ("ganar", "perder"), ("mejor", "peor"), ("la verdad", "la mentira"),
        ("aburrido", "divertido"), ("abierto", "cerrado"), ("dulce", "salado"),
        ("a la izquierda", "a la derecha"), ("alguien", "nadie"), ("primero", "último"),
    ]

    struct Question: Identifiable, Hashable {
        let id = UUID()
        let word: VocabWord
        let answer: VocabWord
        /// The answer and up to three other learned words, shuffled.
        let options: [VocabWord]
    }

    /// The pairs whose two words are both on the learner's vocabulary slides.
    static func openPairs(words: [VocabWord]) -> [(VocabWord, VocabWord)] {
        var learned: [String: VocabWord] = [:]
        for word in words where learned[word.es] == nil {
            learned[word.es] = word
        }
        return pairs.compactMap { pair in
            guard let a = learned[pair.0], let b = learned[pair.1] else { return nil }
            return (a, b)
        }
    }

    static func questions(words: [VocabWord], count: Int = rounds) -> [Question] {
        let open = openPairs(words: words)
        guard open.count >= 2 else { return [] }
        let pool = open.flatMap { [$0.0, $0.1] }
        return open.shuffled().prefix(count).map { pair in
            let (word, answer) = Bool.random() ? (pair.0, pair.1) : (pair.1, pair.0)
            let others = pool.filter { $0 != word && $0 != answer }.shuffled()
            let sameKind = others.filter { $0.kind == answer.kind }
            var wrong: [VocabWord] = []
            for other in sameKind + others where wrong.count < optionCount - 1 && !wrong.contains(other) {
                wrong.append(other)
            }
            return Question(word: word, answer: answer, options: ([answer] + wrong).shuffled())
        }
    }

    static func xp(score: Int) -> Int { 2 + score }
}
