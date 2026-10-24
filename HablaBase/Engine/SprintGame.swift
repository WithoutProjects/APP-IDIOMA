import Foundation

/// "Contrarreloj": 60 seconds to pick as many right forms as you can. Every 5 right answers
/// in a row add 3 seconds; a wrong answer shows the right form before the next question.
enum SprintGame {
    static let seconds = 60
    static let bonusEvery = 5
    static let bonusSeconds = 3
    /// How often a question comes from the forms the learner keeps missing.
    static let weakShare = 0.4

    struct Question: Identifiable, Hashable {
        let id = UUID()
        let card: VerbDeck.Card
        /// The right form and up to three wrong ones, shuffled. All of them are real forms.
        let options: [VerbForm]

        var answer: VerbForm { card.form }
    }

    /// The next question, never the same card twice in a row. Nil when the deck is empty.
    static func question(deck: VerbDeck, weak: Set<FormKey> = [], after previous: VerbDeck.Card? = nil) -> Question? {
        let cards = deck.cards.filter { $0 != previous }
        guard !cards.isEmpty else { return nil }
        let weakCards = cards.filter { weak.contains($0.key) }
        let card: VerbDeck.Card
        if !weakCards.isEmpty, Double.random(in: 0..<1) < weakShare {
            card = weakCards.randomElement()!
        } else {
            card = cards.randomElement()!
        }
        return Question(card: card, options: options(for: card, deck: deck))
    }

    /// Wrong options come from the same verb: other persons in the same tense first (the
    /// mistake learners make most), then the same person in other tenses they know.
    static func options(for card: VerbDeck.Card, deck: VerbDeck) -> [VerbForm] {
        let answer = card.form
        var seen: Set<String> = [answer.text]
        var wrong: [VerbForm] = []
        func add(_ candidates: [VerbForm], upTo limit: Int) {
            for form in candidates.shuffled() where wrong.count < limit && seen.insert(form.text).inserted {
                wrong.append(form)
            }
        }
        let otherPersons = deck.persons.filter { $0 != card.person }.compactMap { card.verb.form(card.tense, $0) }
        let otherTenses = VerbTense.allCases.filter { $0 != card.tense && deck.isOpen(card.verb, $0) }
            .compactMap { card.verb.form($0, card.person) }
        add(otherPersons, upTo: 2)
        add(otherTenses, upTo: 3)
        add(otherPersons, upTo: 3)
        return ([answer] + wrong).shuffled()
    }

    /// XP for a run: a little for trying, more for every right answer, at most 20.
    static func xp(score: Int) -> Int { min(20, 2 + score / 2) }
}
