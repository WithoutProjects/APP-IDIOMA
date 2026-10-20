import Foundation

/// The learner's own language. Every Spanish example carries a gloss in each.
enum NativeLanguage: String, Codable, CaseIterable, Identifiable {
    case english, italian, ukrainian, german

    var id: String { rawValue }

    var label: String {
        switch self {
        case .english: return "English"
        case .italian: return "Italiano"
        case .ukrainian: return "Українська"
        case .german: return "Deutsch"
        }
    }

    /// The key of this language in lesson files and Gloss: en, it, uk…
    var code: String {
        switch self {
        case .english: return "en"
        case .italian: return "it"
        case .ukrainian: return "uk"
        case .german: return "de"
        }
    }

    /// The app localization: Brazilian Portuguese and Simplified Chinese.
    var localization: String {
        switch self {
        default: return code
        }
    }

    /// The whole interface speaks the learner's language, whatever the device language is.
    var locale: Locale { Locale(identifier: localization) }

    /// A UI string in this language, for code that builds strings rather than Text views.
    func localized(_ key: String.LocalizationValue) -> String {
        if let path = Bundle.main.path(forResource: localization, ofType: "lproj"), let bundle = Bundle(path: path) {
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
        case .german: return .german
        default: return .english
        }
    }

    /// How the learner names their own language in Spanish ("Hablo italiano").
    var spanishName: String {
        switch self {
        case .english: return "inglés"
        case .italian: return "italiano"
        case .ukrainian: return "ucraniano"
        case .german: return "alemán"
        }
    }

    /// This language's name on its own, as the meaning of "inglés" on a vocabulary slide.
    var languageNameGloss: Gloss {
        switch self {
        case .english: return Gloss(en: "English", it: "inglese", uk: "англійська", de: "Englisch")
        case .italian: return Gloss(en: "Italian", it: "italiano", uk: "італійська", de: "Italienisch")
        case .ukrainian: return Gloss(en: "Ukrainian", it: "ucraino", uk: "українська", de: "Ukrainisch")
        case .german: return Gloss(en: "German", it: "tedesco", uk: "німецька", de: "Deutsch")
        }
    }

    /// This language's name as it fits in "I speak …" in each learner language
    /// (Ukrainian: "Я розмовляю англійською").
    var spokenName: Gloss {
        switch self {
        case .english: return Gloss(en: "English", it: "inglese", uk: "англійською", de: "Englisch")
        case .italian: return Gloss(en: "Italian", it: "italiano", uk: "італійською", de: "Italienisch")
        case .ukrainian: return Gloss(en: "Ukrainian", it: "ucraino", uk: "українською", de: "Ukrainisch")
        case .german: return Gloss(en: "German", it: "tedesco", uk: "німецькою", de: "Deutsch")
        }
    }
}

/// A translation of a Spanish line into the learner's language. English, Italian and Ukrainian
/// were the first three; German, French, Portuguese and Chinese came later, so in code they
/// are optional arguments. Lesson files must have all of them (tools/validate_content.py).
struct Gloss: Hashable, Codable {
    let en: String
    let it: String
    let uk: String
    let de: String?
    let fr: String?
    let pt: String?
    let zh: String?

    init(en: String, it: String, uk: String, de: String? = nil, fr: String? = nil, pt: String? = nil, zh: String? = nil) {
        self.en = en
        self.it = it
        self.uk = uk
        self.de = de
        self.fr = fr
        self.pt = pt
        self.zh = zh
    }

    /// Progress saved before a language existed has no text for it: it falls back to English.
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        en = try container.decode(String.self, forKey: .en)
        it = try container.decode(String.self, forKey: .it)
        uk = try container.decodeIfPresent(String.self, forKey: .uk) ?? en
        de = try container.decodeIfPresent(String.self, forKey: .de)
        fr = try container.decodeIfPresent(String.self, forKey: .fr)
        pt = try container.decodeIfPresent(String.self, forKey: .pt)
        zh = try container.decodeIfPresent(String.self, forKey: .zh)
    }

    func text(_ language: NativeLanguage) -> String {
        switch language {
        case .english: return en
        case .italian: return it
        case .ukrainian: return uk
        case .german: return de ?? en
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
        case .yo: return Gloss(en: "I", it: "io", uk: "я", de: "ich")
        case .tu: return Gloss(en: "you", it: "tu", uk: "ти", de: "du")
        case .el: return Gloss(en: "he / she", it: "lui / lei", uk: "він / вона", de: "er / sie")
        case .nosotros: return Gloss(en: "we", it: "noi", uk: "ми", de: "wir")
        case .vosotros: return Gloss(en: "you all", it: "voi", uk: "ви", de: "ihr")
        case .ellos: return Gloss(en: "they", it: "loro", uk: "вони", de: "sie")
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
