import Foundation

/// The result of checking one answer. Every format goes through the same pipeline:
/// normalise, grade, explain.
enum GradeOutcome: Equatable {
    case correct
    /// Right words, missing or wrong accents. Counts as correct, with a note.
    case accent(expected: String)
    case wrong(hint: String)

    var isCorrect: Bool {
        if case .wrong = self { return false }
        return true
    }
}

enum Grader {
    /// Lowercase, drop punctuation (including ¿ and ¡) and collapse spaces.
    static func normalize(_ text: String) -> String {
        let punctuation = CharacterSet(charactersIn: "¿?¡!.,;:\"'()")
        let cleaned = text.lowercased().unicodeScalars.map { punctuation.contains($0) ? " " : String($0) }.joined()
        return cleaned.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    /// Removes accents but keeps ñ, which is a different letter, not an accented n.
    static func stripAccents(_ text: String) -> String {
        let protected = text.replacingOccurrences(of: "ñ", with: "\u{0}")
        let folded = protected.folding(options: .diacriticInsensitive, locale: Locale(identifier: "es"))
        return folded.replacingOccurrences(of: "\u{0}", with: "ñ")
    }

    /// Compares a typed or built answer with every accepted answer.
    static func compare(_ answer: String, accepted: [String], hint: String) -> GradeOutcome {
        let given = normalize(answer)
        for target in accepted {
            let expected = normalize(target)
            if given == expected { return .correct }
            if stripAccents(given) == stripAccents(expected) { return .accent(expected: target) }
        }
        return .wrong(hint: hint)
    }

    /// Checks that a free answer contains every required chunk as whole words, in any order.
    /// Returns the first missing chunk so the feedback can name it.
    static func missingChunk(in answer: String, required: [String]) -> String? {
        let given = " " + stripAccents(normalize(answer)) + " "
        return required.first { !given.contains(" " + stripAccents(normalize($0)) + " ") }
    }

    // MARK: Spoken answers

    /// A spoken answer has no punctuation, capitals or accents to judge, and the recogniser
    /// writes numbers as digits.
    static func spokenWords(_ text: String) -> [String] {
        stripAccents(normalize(text)).split(separator: " ").map { numberWords[String($0)] ?? String($0) }
    }

    /// A spoken word or phrase for a gap: right when the answer is heard, alone or inside
    /// the whole sentence.
    static func compareSpokenPhrase(_ said: String, accepted: [String], hint: String) -> GradeOutcome {
        let heard = " " + spokenWords(said).joined(separator: " ") + " "
        let found = accepted.contains { heard.contains(" " + spokenWords($0).joined(separator: " ") + " ") }
        return found ? .correct : .wrong(hint: hint)
    }

    /// A spoken sentence: every word must come in the right order and nothing else may be said,
    /// except tiny linking words (y, a, en, de), which recognisers often drop.
    static func compareSpokenSentence(_ said: String, accepted: [String], hint: String) -> GradeOutcome {
        let heard = spokenWords(said).filter { !droppable.contains($0) }
        guard !heard.isEmpty else { return .wrong(hint: hint) }
        for target in accepted where spokenWords(target).filter({ !droppable.contains($0) }) == heard {
            return .correct
        }
        return .wrong(hint: hint)
    }

    private static let droppable: Set<String> = ["y", "e", "o", "u", "a", "en", "de", "al"]

    private static let numberWords: [String: String] = {
        let words = ["cero", "uno", "dos", "tres", "cuatro", "cinco", "seis", "siete", "ocho", "nueve", "diez",
                     "once", "doce", "trece", "catorce", "quince", "dieciseis", "diecisiete", "dieciocho",
                     "diecinueve", "veinte", "veintiuno", "veintidos", "veintitres", "veinticuatro",
                     "veinticinco", "veintiseis", "veintisiete", "veintiocho", "veintinueve", "treinta"]
        return Dictionary(uniqueKeysWithValues: words.enumerated().map { (String($0.offset), $0.element) })
    }()
}
