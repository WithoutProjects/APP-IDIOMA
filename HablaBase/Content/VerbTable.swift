import Foundation

/// Every verb the course teaches, from verbs.json (built by tools/gen_verbs.py): the lesson that
/// introduces it and its meaning. The forms in every tense come from VerbBook (verb-tables.json).
struct TableVerb: Decodable, Identifiable {
    let lemma: String
    /// The lesson that introduces it; the verb joins the tables once that lesson is done.
    let lesson: String
    let meaning: Gloss
    /// Six present forms as [stem, ending], in Person order. Irregular forms have an empty ending.
    let present: [[String]]
    /// Persons the verb is used in, when not all six (llover: él; gustar: él, ellos).
    let persons: [Person]?

    var id: String { lemma }

    func form(_ person: Person) -> VerbForm {
        let pair = present[Person.allCases.firstIndex(of: person) ?? 0]
        return VerbForm(stem: pair[0], ending: pair.count > 1 ? pair[1] : "")
    }

    func uses(_ person: Person) -> Bool {
        persons?.contains(person) ?? true
    }

    /// Same key as Conjugator.key, so practice in lessons shades the tables.
    func key(_ person: Person) -> FormKey {
        "\(lemma).\(Tense.presente.rawValue).\(person.rawValue)"
    }
}

enum VerbTable {
    /// All verbs in the order the course introduces them.
    static let all: [TableVerb] = {
        guard let url = Bundle.main.url(forResource: "verbs", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let verbs = try? JSONDecoder().decode([TableVerb].self, from: data) else { return [] }
        return verbs
    }()

    private static let byLemma = Dictionary(all.map { ($0.lemma, $0) }, uniquingKeysWith: { first, _ in first })

    /// The meaning the verb's vocabulary slide gives it.
    static func meaning(_ lemma: String) -> Gloss? { byLemma[lemma]?.meaning }

    /// A verb is learned once the lesson that introduces it is done.
    static func isLearned(_ lemma: String, completed: Set<String>) -> Bool {
        byLemma[lemma].map { completed.contains($0.lesson) } ?? false
    }
}
