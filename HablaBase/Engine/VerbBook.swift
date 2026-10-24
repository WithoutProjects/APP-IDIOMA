import Foundation

/// The tenses the Lab games drill, in the order the path teaches them.
enum VerbTense: String, CaseIterable, Codable, Identifiable {
    case presente, perfecto, indefinido, imperfecto, futuro, condicional, subjuntivo, subjuntivoImperfecto

    var id: String { rawValue }

    /// The tense's name in the learner's language.
    var name: Gloss {
        switch self {
        case .presente: return Gloss(en: "present", it: "presente", uk: "теперішній час", de: "Präsens", fr: "présent", pt: "presente", zh: "现在时")
        case .perfecto: return Gloss(en: "present perfect", it: "passato prossimo", uk: "перфект", de: "Perfekt", fr: "passé composé", pt: "pretérito perfeito composto", zh: "现在完成时")
        case .indefinido: return Gloss(en: "simple past", it: "passato remoto", uk: "минулий доконаний", de: "einfache Vergangenheit", fr: "passé simple", pt: "pretérito perfeito", zh: "简单过去时")
        case .imperfecto: return Gloss(en: "imperfect (used to)", it: "imperfetto", uk: "минулий недоконаний", de: "Imperfekt", fr: "imparfait", pt: "pretérito imperfeito", zh: "过去未完成时")
        case .futuro: return Gloss(en: "future", it: "futuro", uk: "майбутній час", de: "Futur", fr: "futur", pt: "futuro", zh: "将来时")
        case .condicional: return Gloss(en: "conditional", it: "condizionale", uk: "умовний спосіб", de: "Konditional", fr: "conditionnel", pt: "condicional", zh: "条件式")
        case .subjuntivo: return Gloss(en: "present subjunctive", it: "congiuntivo presente", uk: "субʼюнктив теперішнього часу", de: "Subjunktiv Präsens", fr: "subjonctif présent", pt: "presente do subjuntivo", zh: "虚拟式现在时")
        case .subjuntivoImperfecto: return Gloss(en: "past subjunctive", it: "congiuntivo imperfetto", uk: "субʼюнктив минулого часу", de: "Subjunktiv Imperfekt", fr: "subjonctif imparfait", pt: "imperfeito do subjuntivo", zh: "虚拟式过去时")
        }
    }

    /// The tense shown with hablar, so the label is clear in any language: "hablé".
    var model: String {
        switch self {
        case .presente: return "hablo"
        case .perfecto: return "he hablado"
        case .indefinido: return "hablé"
        case .imperfecto: return "hablaba"
        case .futuro: return "hablaré"
        case .condicional: return "hablaría"
        case .subjuntivo: return "hable"
        case .subjuntivoImperfecto: return "hablara"
        }
    }

    /// The lesson that teaches the regular forms. Present forms come with each verb's own lesson.
    var regularGate: String {
        switch self {
        case .presente: return "u1l1"
        case .perfecto: return "u14l1"
        case .indefinido: return "u15l2"
        case .imperfecto: return "u21l1"
        case .futuro: return "u29l1"
        case .condicional: return "u34l1"
        case .subjuntivo: return "u31l4"
        case .subjuntivoImperfecto: return "u37l1"
        }
    }

    /// The lesson that teaches the irregular forms (tuve, hecho, tendré…).
    var irregularGate: String {
        switch self {
        case .presente: return "u1l1"
        case .perfecto: return "u14l4"
        case .indefinido: return "u16l5"
        case .imperfecto: return "u21l2"
        case .futuro: return "u29l2"
        case .condicional: return "u34l2"
        case .subjuntivo: return "u31l5"
        case .subjuntivoImperfecto: return "u37l2"
        }
    }
}

/// One verb's full tables, from Content/verb-tables.json (built by tools/build_verb_tables.py).
struct VerbEntry: Decodable, Identifiable, Hashable {
    let lemma: String
    /// Six forms per tense, in Person order: yo, tú, él, nosotros, vosotros, ellos.
    let forms: [VerbTense: [VerbForm]]
    /// Tenses where the verb does not follow the regular pattern.
    let irregular: Set<VerbTense>

    var id: String { lemma }

    private enum CodingKeys: String, CodingKey {
        case lemma, forms, irregular
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        lemma = try container.decode(String.self, forKey: .lemma)
        let raw = try container.decode([String: [String]].self, forKey: .forms)
        var forms: [VerbTense: [VerbForm]] = [:]
        for (name, list) in raw {
            guard let tense = VerbTense(rawValue: name), list.count == Person.allCases.count else { continue }
            forms[tense] = list.map { Self.parse($0) }
        }
        self.forms = forms
        let irregular = try container.decode([String].self, forKey: .irregular)
        self.irregular = Set(irregular.compactMap { VerbTense(rawValue: $0) })
    }

    /// "habl|o" -> stem "habl", ending "o". A form without a bar is all stem: "soy".
    static func parse(_ text: String) -> VerbForm {
        let parts = text.split(separator: "|", maxSplits: 1, omittingEmptySubsequences: false)
        return VerbForm(stem: String(parts[0]), ending: parts.count > 1 ? String(parts[1]) : "")
    }

    /// Two entries are the same verb when they share the infinitive.
    static func == (lhs: VerbEntry, rhs: VerbEntry) -> Bool { lhs.lemma == rhs.lemma }

    func hash(into hasher: inout Hasher) { hasher.combine(lemma) }

    func form(_ tense: VerbTense, _ person: Person) -> VerbForm? {
        guard let list = forms[tense], let index = Person.allCases.firstIndex(of: person) else { return nil }
        return list[index]
    }

    /// The SRS key, the same as the lessons use: "hablar.presente.yo".
    func key(_ tense: VerbTense, _ person: Person) -> FormKey {
        "\(lemma).\(tense.rawValue).\(person.rawValue)"
    }
}

/// Every verb the Lab games know.
final class VerbBook {
    static let shared = VerbBook()

    let verbs: [VerbEntry]
    private let byLemma: [String: VerbEntry]

    private struct File: Decodable {
        let verbs: [VerbEntry]
    }

    init(bundle: Bundle = .main) {
        var loaded: [VerbEntry] = []
        if let url = bundle.url(forResource: "verb-tables", withExtension: "json") {
            do {
                loaded = try JSONDecoder().decode(File.self, from: Data(contentsOf: url)).verbs
            } catch {
                assertionFailure("verb-tables.json does not match the format: \(error)")
            }
        } else {
            assertionFailure("verb-tables.json is missing from the app bundle")
        }
        verbs = loaded
        byLemma = Dictionary(loaded.map { ($0.lemma, $0) }, uniquingKeysWith: { first, _ in first })
    }

    func verb(_ lemma: String) -> VerbEntry? { byLemma[lemma] }
}

/// What the Lab may ask this learner: the verbs of finished lessons, in the persons and
/// tenses the path has taught so far. Nothing is asked before it is explained.
struct VerbDeck {
    struct Card: Hashable {
        let verb: VerbEntry
        let tense: VerbTense
        let person: Person

        var form: VerbForm { verb.form(tense, person) ?? VerbForm(stem: verb.lemma, ending: "") }
        var key: FormKey { verb.key(tense, person) }
    }

    let verbs: [VerbEntry]
    /// Each verb's meaning, as its vocabulary slide gave it.
    let meanings: [String: Gloss]
    let persons: [Person]
    private let completed: Set<String>

    /// `words` are the words of the finished lessons; their verbs (kind stem) make the deck.
    init(completed: Set<String>, words: [VocabWord], book: VerbBook = .shared) {
        var meanings: [String: Gloss] = [:]
        for word in words where word.kind == .stem && meanings[word.es] == nil {
            meanings[word.es] = word.gloss
        }
        self.meanings = meanings
        self.completed = completed
        verbs = book.verbs.filter { meanings[$0.lemma] != nil }
        persons = Self.persons(completed: completed)
    }

    /// yo, tú and él/ella in Lesson 1; nosotros, ellos and vosotros in the first lessons of Unit 2.
    static func persons(completed: Set<String>) -> [Person] {
        Person.allCases.filter { person in
            switch person {
            case .yo, .tu, .el: return completed.contains("u1l1")
            case .nosotros: return completed.contains("u2l1")
            case .ellos: return completed.contains("u2l2")
            case .vosotros: return completed.contains("u2l3")
            }
        }
    }

    /// A tense is open for a verb once the path has taught its regular, or for this verb its irregular, forms.
    func isOpen(_ verb: VerbEntry, _ tense: VerbTense) -> Bool {
        if tense == .presente { return true }
        return completed.contains(verb.irregular.contains(tense) ? tense.irregularGate : tense.regularGate)
    }

    var cards: [Card] {
        verbs.flatMap { verb in
            VerbTense.allCases.filter { isOpen(verb, $0) }.flatMap { tense in
                persons.map { Card(verb: verb, tense: tense, person: $0) }
            }
        }
    }
}
