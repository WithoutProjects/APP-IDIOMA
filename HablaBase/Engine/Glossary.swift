import Foundation

/// The learner's personal dictionary: only words already introduced on vocabulary slides,
/// plus the yo, tú and él/ella forms of the verbs among them. Tapping one of these words in
/// a Spanish sentence shows its translation.
struct Glossary {
    struct Entry: Equatable {
        /// The word or phrase as it was introduced, e.g. "me llamo".
        let es: String
        let gloss: Gloss
    }

    private(set) var entries: [String: Entry] = [:]

    init(words: [VocabWord], verbs: [Verb] = Unit1.verbs) {
        for word in words {
            let entry = Entry(es: word.es, gloss: word.gloss)
            let tokens = Self.tokens(in: word.es)
            // A one-word entry wins over a word that only appears inside a phrase.
            for token in tokens where tokens.count == 1 || entries[token] == nil {
                entries[token] = entry
            }
            if let verb = verbs.first(where: { $0.lemma == word.es }) {
                for person in [Person.yo, .tu, .el] {
                    let form = Conjugator.conjugate(verb, .presente, person).text
                    entries[form] = Entry(es: form, gloss: verb.gloss(person))
                }
            }
        }
    }

    func lookup(_ word: String) -> Entry? {
        Self.tokens(in: word).first.flatMap { entries[$0] }
    }

    /// Lowercased words without punctuation: "¿Hablas español?" -> ["hablas", "español"].
    static func tokens(in text: String) -> [String] {
        Grader.normalize(text).split(separator: " ").map(String.init)
    }
}
