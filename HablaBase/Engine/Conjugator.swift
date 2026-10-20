import Foundation

/// The learner's own language. Every Spanish example carries a gloss in each.
enum NativeLanguage: String, Codable, CaseIterable, Identifiable {
    case english, italian, ukrainian

    var id: String { rawValue }

    var label: String {
        switch self {
        case .english: return "English"
        case .italian: return "Italiano"
        case .ukrainian: return "Українська"
        }
    }

    /// The localization code: en, it or uk.
    var code: String {
        switch self {
        case .english: return "en"
        case .italian: return "it"
        case .ukrainian: return "uk"
        }
    }

    /// The whole interface speaks the learner's language, whatever the device language is.
    var locale: Locale { Locale(identifier: code) }

    /// A UI string in this language, for code that builds strings rather than Text views.
    func localized(_ key: String.LocalizationValue) -> String {
        if let path = Bundle.main.path(forResource: code, ofType: "lproj"), let bundle = Bundle(path: path) {
            return String(localized: key, bundle: bundle)
        }
        // No compiled table for the source language: a missing table returns the English text.
        return String(localized: key, table: "SourceLanguage")
    }

    /// The device language when the app speaks it, English otherwise.
    static var deviceDefault: NativeLanguage {
        switch Locale.current.language.languageCode {
        case .italian: return .italian
        case .ukrainian: return .ukrainian
        default: return .english
        }
    }

    /// How the learner names their own language in Spanish ("Hablo italiano").
    var spanishName: String {
        switch self {
        case .english: return "inglés"
        case .italian: return "italiano"
        case .ukrainian: return "ucraniano"
        }
    }

    /// This language's name on its own, as the meaning of "inglés" on a vocabulary slide.
    var languageNameGloss: Gloss {
        switch self {
        case .english: return Gloss(en: "English", it: "inglese", uk: "англійська")
        case .italian: return Gloss(en: "Italian", it: "italiano", uk: "італійська")
        case .ukrainian: return Gloss(en: "Ukrainian", it: "ucraino", uk: "українська")
        }
    }

    /// This language's name as it fits in "I speak …" in each learner language
    /// (Ukrainian: "Я розмовляю англійською").
    var spokenName: Gloss {
        switch self {
        case .english: return Gloss(en: "English", it: "inglese", uk: "англійською")
        case .italian: return Gloss(en: "Italian", it: "italiano", uk: "італійською")
        case .ukrainian: return Gloss(en: "Ukrainian", it: "ucraino", uk: "українською")
        }
    }
}

/// A translation of a Spanish line into the learner's language.
struct Gloss: Hashable, Codable {
    let en: String
    let it: String
    let uk: String

    init(en: String, it: String, uk: String) {
        self.en = en
        self.it = it
        self.uk = uk
    }

    /// Progress saved before Ukrainian existed has no uk: it falls back to English.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        en = try container.decode(String.self, forKey: .en)
        it = try container.decode(String.self, forKey: .it)
        uk = try container.decodeIfPresent(String.self, forKey: .uk) ?? en
    }

    func text(_ language: NativeLanguage) -> String {
        switch language {
        case .english: return en
        case .italian: return it
        case .ukrainian: return uk
        }
    }
}

/// A Spanish sentence with its translations.
struct Example: Hashable {
    let es: String
    let gloss: Gloss
}

enum Family: String, Codable {
    case ar, er, ir
}

enum Person: String, CaseIterable, Codable, Identifiable {
    case yo, tu, el, nosotros, vosotros, ellos

    var id: String { rawValue }

    var label: String {
        switch self {
        case .yo: return "yo"
        case .tu: return "tú"
        case .el: return "él / ella"
        case .nosotros: return "nosotros"
        case .vosotros: return "vosotros"
        case .ellos: return "ellos"
        }
    }

    var gloss: Gloss {
        switch self {
        case .yo: return Gloss(en: "I", it: "io", uk: "я")
        case .tu: return Gloss(en: "you", it: "tu", uk: "ти")
        case .el: return Gloss(en: "he / she", it: "lui / lei", uk: "він / вона")
        case .nosotros: return Gloss(en: "we", it: "noi", uk: "ми")
        case .vosotros: return Gloss(en: "you all", it: "voi", uk: "ви")
        case .ellos: return Gloss(en: "they", it: "loro", uk: "вони")
        }
    }
}

/// Only the present is unlocked in Level 1; past tenses arrive in Levels 3 and 4.
enum Tense: String, Codable {
    case presente
}

struct Verb: Identifiable, Hashable {
    let lemma: String
    /// Infinitive meaning, e.g. "to speak" / "parlare".
    let meaning: Gloss
    /// Meaning for yo, tú and él/ella, e.g. "I speak", "you speak", "she speaks".
    let present: [Gloss]
    /// The chunk the verb is practised with ("No naked words"), e.g. "español".
    let complement: String
    let complementGloss: Gloss

    var id: String { lemma }

    var family: Family {
        switch lemma.suffix(2) {
        case "ar": return .ar
        case "er": return .er
        default: return .ir
        }
    }

    /// The blue brick: the infinitive minus -ar/-er/-ir.
    var stem: String { String(lemma.dropLast(2)) }

    /// Meaning of the yo, tú or él/ella form; other persons fall back to the infinitive.
    func gloss(_ person: Person) -> Gloss {
        switch person {
        case .yo: return present[0]
        case .tu: return present[1]
        case .el: return present[2]
        default: return meaning
        }
    }
}

/// A form split into its Lego bricks, so the UI can colour stem and ending.
struct VerbForm: Hashable {
    let stem: String
    let ending: String

    var text: String { stem + ending }
}

/// Key for one tracked SRS cell: verb x tense x person.
typealias FormKey = String

enum Conjugator {
    /// Orange bricks for the present tense. ER and IR share all but nosotros and vosotros.
    static let presentEndings: [Family: [Person: String]] = [
        .ar: [.yo: "o", .tu: "as", .el: "a", .nosotros: "amos", .vosotros: "áis", .ellos: "an"],
        .er: [.yo: "o", .tu: "es", .el: "e", .nosotros: "emos", .vosotros: "éis", .ellos: "en"],
        .ir: [.yo: "o", .tu: "es", .el: "e", .nosotros: "imos", .vosotros: "ís", .ellos: "en"],
    ]

    /// Regular forms only for now; irregular overrides (tengo, quiero) come with Level 2.
    static func conjugate(_ verb: Verb, _ tense: Tense, _ person: Person) -> VerbForm {
        switch tense {
        case .presente:
            let ending = presentEndings[verb.family]?[person] ?? ""
            return VerbForm(stem: verb.stem, ending: ending)
        }
    }

    static func key(_ verb: Verb, _ tense: Tense, _ person: Person) -> FormKey {
        "\(verb.lemma).\(tense.rawValue).\(person.rawValue)"
    }
}
