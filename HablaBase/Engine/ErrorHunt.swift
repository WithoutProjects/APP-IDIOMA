import Foundation

/// "Caza de errores": sentences from the learner's own lessons. In some of them one verb has
/// the wrong person ("Nosotros habla…"); the learner taps it, or says the sentence is fine.
/// Only sentences with a subject pronoun right before the verb are used, so a changed verb
/// is always really wrong and never just another correct sentence.
enum ErrorHunt {
    static let lives = 3
    /// The share of sentences with a mistake in them.
    static let wrongShare = 0.6

    struct Round: Identifiable {
        let id = UUID()
        /// The sentence as shown, word by word, punctuation attached.
        let words: [String]
        let gloss: Gloss
        /// Where the wrong verb sits in `words`. Nil when the sentence is right.
        let wrongRange: Range<Int>?
        /// The verb as the sentence needs it, and as it was changed.
        let rightForm: String
        let wrongForm: String?
        /// The pronoun that decides the person, as written: "nosotros", "usted".
        let subject: String
        let key: FormKey

        var isCorrect: Bool { wrongRange == nil }
    }

    /// A sentence with a subject pronoun followed by a verb form the learner knows.
    struct Candidate {
        let sentence: Example
        let words: [String]
        let span: Range<Int>
        let subject: String
        let person: Person
        let verb: VerbEntry
        let tense: VerbTense
    }

    static let subjects: [String: Person] = [
        "yo": .yo, "tú": .tu, "él": .el, "ella": .el, "usted": .el,
        "nosotros": .nosotros, "nosotras": .nosotros, "vosotros": .vosotros, "vosotras": .vosotros,
        "ellos": .ellos, "ellas": .ellos, "ustedes": .ellos,
    ]

    /// After these the pronoun is not the subject: "con ella", "para ellos".
    static let prepositions: Set<String> = ["a", "con", "de", "en", "para", "por", "sin", "entre", "hacia", "según", "contra", "como"]

    /// Lowercased word without punctuation: "¿Tú" -> "tú", "comido?" -> "comido".
    static func clean(_ word: String) -> String {
        Grader.normalize(word).trimmingCharacters(in: CharacterSet(charactersIn: "«»“”‘’-–—…"))
    }

    /// Finds the subject and its verb in a sentence. Tries "me he levantado" before "he" alone.
    static func candidate(in sentence: Example, deck: VerbDeck) -> Candidate? {
        let words = sentence.es.split(separator: " ").map(String.init)
        let cleaned = words.map(clean)
        for index in cleaned.indices {
            guard let person = subjects[cleaned[index]] else { continue }
            if index > 0, prepositions.contains(cleaned[index - 1]) { continue }
            var start = index + 1
            if start < cleaned.count, cleaned[start] == "no" { start += 1 }
            for length in [3, 2, 1] where start + length <= cleaned.count {
                let phrase = cleaned[start..<start + length].joined(separator: " ")
                for verb in deck.verbs {
                    for tense in VerbTense.allCases where verb.form(tense, person)?.text == phrase {
                        return Candidate(sentence: sentence, words: words, span: start..<start + length,
                                         subject: cleaned[index], person: person, verb: verb, tense: tense)
                    }
                }
            }
        }
        return nil
    }

    /// A wrong person for the verb: unlocked, spelt differently, and not a form this subject
    /// could take in any tense ("yo hablaba" can't become "él hablaba").
    static func wrongForm(for candidate: Candidate, deck: VerbDeck) -> String? {
        let fitting = Set(VerbTense.allCases.compactMap { candidate.verb.form($0, candidate.person)?.text })
        let options = deck.persons.filter { $0 != candidate.person }
            .compactMap { candidate.verb.form(candidate.tense, $0)?.text }
            .filter { !fitting.contains($0) }
        return options.randomElement()
    }

    /// One round from a candidate, with or without a mistake.
    static func round(from candidate: Candidate, deck: VerbDeck, withMistake: Bool) -> Round {
        let right = candidate.verb.form(candidate.tense, candidate.person)?.text ?? ""
        let key = candidate.verb.key(candidate.tense, candidate.person)
        guard withMistake, let wrong = wrongForm(for: candidate, deck: deck) else {
            return Round(words: candidate.words, gloss: candidate.sentence.gloss, wrongRange: nil,
                         rightForm: right, wrongForm: nil, subject: candidate.subject, key: key)
        }
        // Keep the punctuation around the verb: "¿Tú has comido?" -> "¿Tú ha comido?".
        let original = Array(candidate.words[candidate.span])
        var replacement = wrong.split(separator: " ").map(String.init)
        if let first = original.first, let prefix = first.firstIndex(where: { $0.isLetter }) {
            replacement[0] = String(first[..<prefix]) + replacement[0]
        }
        if let last = original.last, let end = last.lastIndex(where: { $0.isLetter }) {
            replacement[replacement.count - 1] += String(last[last.index(after: end)...])
        }
        var words = candidate.words
        words.replaceSubrange(candidate.span, with: replacement)
        let range = candidate.span.lowerBound..<candidate.span.lowerBound + replacement.count
        return Round(words: words, gloss: candidate.sentence.gloss, wrongRange: range,
                     rightForm: right, wrongForm: wrong, subject: candidate.subject, key: key)
    }

    /// Every usable sentence, each once, shuffled; about 6 in 10 get a mistake.
    static func rounds(from sentences: [Example], deck: VerbDeck) -> [Round] {
        var seen: Set<String> = []
        return sentences
            .filter { seen.insert($0.es).inserted }
            .compactMap { candidate(in: $0, deck: deck) }
            .shuffled()
            .map { round(from: $0, deck: deck, withMistake: Double.random(in: 0..<1) < wrongShare) }
    }

    static func xp(score: Int) -> Int { min(20, 2 + score) }
}
