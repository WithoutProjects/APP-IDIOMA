import Foundation

/// Where the learner works. Feeds their personal sentence bank from Lesson 1.
enum Workplace: String, Codable, CaseIterable, Identifiable {
    case hospital, oficina, escuela, casa, tienda

    var id: String { rawValue }

    /// The words after "Trabajo en".
    var spanish: String {
        switch self {
        case .hospital: return "un hospital"
        case .oficina: return "una oficina"
        case .escuela: return "una escuela"
        case .casa: return "casa"
        case .tienda: return "una tienda"
        }
    }

    /// The place on its own, for the vocabulary slides.
    var nounGloss: Gloss {
        switch self {
        case .hospital: return Gloss(en: "a hospital", it: "un ospedale", uk: "лікарня", de: "ein Krankenhaus", fr: "un hôpital", pt: "um hospital", zh: "医院")
        case .oficina: return Gloss(en: "an office", it: "un ufficio", uk: "офіс", de: "ein Büro", fr: "un bureau", pt: "um escritório", zh: "办公室")
        case .escuela: return Gloss(en: "a school", it: "una scuola", uk: "школа", de: "eine Schule", fr: "une école", pt: "uma escola", zh: "学校")
        case .casa: return Gloss(en: "home", it: "casa", uk: "дім", de: "Zuhause", fr: "la maison", pt: "casa", zh: "家")
        case .tienda: return Gloss(en: "a shop", it: "un negozio", uk: "магазин", de: "ein Geschäft", fr: "un magasin", pt: "uma loja", zh: "商店")
        }
    }

    var gloss: Gloss {
        switch self {
        case .hospital: return Gloss(en: "in a hospital", it: "in un ospedale", uk: "в лікарні", de: "in einem Krankenhaus", fr: "dans un hôpital", pt: "em um hospital", zh: "在医院")
        case .oficina: return Gloss(en: "in an office", it: "in un ufficio", uk: "в офісі", de: "in einem Büro", fr: "dans un bureau", pt: "em um escritório", zh: "在办公室")
        case .escuela: return Gloss(en: "at a school", it: "in una scuola", uk: "у школі", de: "an einer Schule", fr: "dans une école", pt: "em uma escola", zh: "在学校")
        case .casa: return Gloss(en: "from home", it: "a casa", uk: "з дому", de: "von zu Hause aus", fr: "de chez moi", pt: "em casa", zh: "在家")
        case .tienda: return Gloss(en: "in a shop", it: "in un negozio", uk: "в магазині", de: "in einem Geschäft", fr: "dans un magasin", pt: "em uma loja", zh: "在商店")
        }
    }
}

enum LearningGoal: String, Codable, CaseIterable, Identifiable {
    case travel, work, family, partner, move

    var id: String { rawValue }

    var gloss: Gloss {
        switch self {
        case .travel: return Gloss(en: "Travel", it: "Viaggiare", uk: "Подорожі", de: "Reisen", fr: "Voyager", pt: "Viajar", zh: "旅行")
        case .work: return Gloss(en: "Work", it: "Lavoro", uk: "Робота", de: "Arbeit", fr: "Travail", pt: "Trabalho", zh: "工作")
        case .family: return Gloss(en: "Family", it: "Famiglia", uk: "Сім'я", de: "Familie", fr: "Famille", pt: "Família", zh: "家人")
        case .partner: return Gloss(en: "Partner", it: "Partner", uk: "Партнер", de: "Partner", fr: "Couple", pt: "Relacionamento", zh: "伴侣")
        case .move: return Gloss(en: "Move abroad", it: "Trasferirmi", uk: "Переїзд за кордон", de: "Auswandern", fr: "Vivre à l'étranger", pt: "Morar fora", zh: "移居国外")
        }
    }
}

/// Collected in onboarding so practice sentences are personally true.
struct Profile: Codable, Equatable {
    var name: String
    var city: String
    var workplace: Workplace
    var nativeLanguage: NativeLanguage
    var goal: LearningGoal
    var dailyMinutes: Int
}
