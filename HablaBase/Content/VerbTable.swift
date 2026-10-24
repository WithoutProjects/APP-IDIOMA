import Foundation

/// A verb in the Lab's tables: every verb the course teaches, from verbs.json (built by tools/gen_verbs.py).
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

    /// Verbs whose lesson is done, newest first.
    static func unlocked(completed: Set<String>) -> [TableVerb] {
        all.filter { completed.contains($0.lesson) }.reversed()
    }

    /// Unit 1 teaches yo, tú, él; Unit 2 adds nosotros, ellos and vosotros, one lesson each.
    static func unlockedPersons(completed: Set<String>) -> [Person] {
        var persons = Unit1.unlockedPersons(completed: completed)
        if completed.contains("u2l1") { persons.append(.nosotros) }
        if completed.contains("u2l3") { persons.append(.vosotros) }
        if completed.contains("u2l2") { persons.append(.ellos) }
        return persons
    }
}
