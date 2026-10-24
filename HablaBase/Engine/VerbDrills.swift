import Foundation

/// "¿Qué tiempo es?": a verb form appears; pick its tense.
enum TenseQuiz {
    static let rounds = 10

    struct Question: Identifiable, Hashable {
        let id = UUID()
        let card: VerbDeck.Card
        /// The right tense and up to three others the learner knows, shuffled.
        let options: [VerbTense]
    }

    /// Only forms that belong to one tense alone ("hablé", not "hablamos", which is present and past).
    static func questions(deck: VerbDeck, count: Int = rounds) -> [Question] {
        let cards = deck.cards.filter { card in
            let others = VerbTense.allCases.filter { $0 != card.tense && deck.isOpen(card.verb, $0) }
            let text = card.form.text
            return !others.isEmpty && !others.contains { tense in
                Person.allCases.contains { card.verb.form(tense, $0)?.text == text }
            }
        }
        return Array(cards.shuffled().prefix(count)).map { card in
            let others = VerbTense.allCases.filter { $0 != card.tense && deck.isOpen(card.verb, $0) }.shuffled().prefix(3)
            return Question(card: card, options: ([card.tense] + others).sorted { tenseOrder($0) < tenseOrder($1) })
        }
    }

    /// Options keep the order of the path, so they don't jump around between questions.
    private static func tenseOrder(_ tense: VerbTense) -> Int {
        VerbTense.allCases.firstIndex(of: tense) ?? 0
    }
}

/// "Máquina del tiempo": a form in one tense ("tú hablas"), write it in another ("hablaste").
enum TimeMachine {
    static let rounds = 10

    struct Question: Identifiable, Hashable {
        let id = UUID()
        let from: VerbDeck.Card
        let to: VerbTense

        var answer: VerbForm { from.verb.form(to, from.person) ?? from.form }
    }

    static func questions(deck: VerbDeck, weak: Set<FormKey> = [], count: Int = rounds) -> [Question] {
        var questions: [Question] = []
        let cards = deck.cards.shuffled()
        let weakFirst = cards.filter { weak.contains($0.key) } + cards.filter { !weak.contains($0.key) }
        for card in weakFirst where questions.count < count {
            let targets = VerbTense.allCases.filter { $0 != card.tense && deck.isOpen(card.verb, $0) }
                .filter { card.verb.form($0, card.person)?.text != card.form.text }
            guard let target = targets.randomElement(),
                  !questions.contains(where: { $0.from.verb == card.verb && $0.from.person == card.person }) else { continue }
            questions.append(Question(from: card, to: target))
        }
        return questions.shuffled()
    }

    static func key(_ question: Question) -> FormKey {
        question.from.verb.key(question.to, question.from.person)
    }
}
