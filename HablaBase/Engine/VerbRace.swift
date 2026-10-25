import Foundation

/// "Carrera de verbos": write whole tables against the clock. Three verbs, every person,
/// typed. The run ends when the last form is in, and the record is the fastest time.
/// Contrarreloj is the opposite game: a fixed minute, picking forms from options.
enum VerbRace {
    static let verbsPerRace = 3
    /// Seconds added for each form shown instead of written.
    static let skipPenalty = 5

    struct Table: Identifiable, Hashable {
        let id = UUID()
        let verb: VerbEntry
        let tense: VerbTense
        let persons: [Person]

        func form(_ person: Person) -> VerbForm {
            verb.form(tense, person) ?? VerbForm(stem: verb.lemma, ending: "")
        }
    }

    /// One table per verb, each in a tense the learner knows for it. Verbs with forms the
    /// learner keeps missing come first.
    static func tables(deck: VerbDeck, weak: Set<FormKey> = [], count: Int = verbsPerRace) -> [Table] {
        guard deck.persons.count >= 3 else { return [] }
        let verbs = deck.verbs.shuffled()
        let weakLemmas = Set(weak.compactMap { $0.split(separator: ".").first.map(String.init) })
        let ordered = verbs.filter { weakLemmas.contains($0.lemma) } + verbs.filter { !weakLemmas.contains($0.lemma) }
        return ordered.prefix(count).map { verb in
            let tenses = VerbTense.allCases.filter { deck.isOpen(verb, $0) }
            return Table(verb: verb, tense: tenses.randomElement() ?? .presente, persons: deck.persons)
        }
    }

    /// True when the typed text is the form, accents aside. The game moves on by itself as soon
    /// as it matches, so the learner never has to press a button between forms.
    static func matches(_ typed: String, _ form: VerbForm) -> Bool {
        let given = Grader.normalize(typed)
        return !given.isEmpty && Grader.stripAccents(given) == Grader.stripAccents(Grader.normalize(form.text))
    }

    /// True when it matches with every accent right.
    static func isExact(_ typed: String, _ form: VerbForm) -> Bool {
        Grader.normalize(typed) == Grader.normalize(form.text)
    }

    /// The time that counts: whole seconds plus the penalty for each form shown.
    static func time(elapsed: TimeInterval, skips: Int) -> Int {
        max(1, Int(elapsed.rounded(.up))) + skips * skipPenalty
    }

    /// "1:05", or "48 s" under a minute.
    static func clock(_ seconds: Int) -> String {
        seconds < 60 ? "\(seconds) s" : String(format: "%d:%02d", seconds / 60, seconds % 60)
    }

    static func xp(written: Int) -> Int { min(20, 4 + written / 2) }
}
