import Foundation

/// "Dilo en español": a word the learner has already met appears in their own language
/// ("they") and they say it in Spanish ("ellos" or "ellas"). Every Spanish word that shares
/// the meaning counts, so the learner is never marked wrong for a right answer.
enum VoiceRecall {
    static let rounds = 10
    /// Long phrases are hard for speech recognition; the game keeps to short words and chunks.
    static let maxWords = 4

    struct Card: Identifiable, Hashable {
        /// The meaning in the learner's language, as shown: "they".
        let prompt: String
        /// Every Spanish way to say it that the learner has met: ["ellos", "ellas"].
        let answers: [String]

        var id: String { prompt }
    }

    /// One card per meaning. "they" and "they (all women)" are the same card, so both
    /// ellos and ellas are right.
    static func cards(from words: [VocabWord], language: NativeLanguage) -> [Card] {
        var order: [String] = []
        var answers: [String: [String]] = [:]
        var prompts: [String: String] = [:]
        for word in words {
            let prompt = shownMeaning(word.gloss.text(language))
            let key = Grader.normalize(prompt)
            guard !key.isEmpty else { continue }
            let spanish = variants(of: word.es).filter { $0.split(separator: " ").count <= maxWords }
            guard !spanish.isEmpty else { continue }
            // A word that is spelt the same in both languages ("pizza") is no test.
            if spanish.contains(where: { simplified($0) == simplified(prompt) }) { continue }
            if answers[key] == nil {
                order.append(key)
                prompts[key] = prompt
            }
            for answer in spanish where !(answers[key] ?? []).contains(where: { simplified($0) == simplified(answer) }) {
                answers[key, default: []].append(answer)
            }
        }
        return order.compactMap { key in
            guard let prompt = prompts[key], let list = answers[key] else { return nil }
            return Card(prompt: prompt, answers: list)
        }
    }

    /// The meaning without notes in brackets: "they (all women)" -> "they".
    static func shownMeaning(_ text: String) -> String {
        var result = ""
        var depth = 0
        for character in text {
            if character == "(" || character == "（" { depth += 1; continue }
            if character == ")" || character == "）" { depth = max(0, depth - 1); continue }
            if depth == 0 { result.append(character) }
        }
        return result.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ")
    }

    /// "él / ella" -> ["él", "ella"]; "¿y tú?" -> ["¿y tú?"].
    static func variants(of spanish: String) -> [String] {
        spanish.split(separator: "/")
            .map { shownMeaning(String($0)).trimmingCharacters(in: .whitespaces) }
            .filter { !Grader.normalize($0).isEmpty }
    }

    /// What can be heard: no capitals, punctuation or accents.
    static func simplified(_ text: String) -> String {
        Grader.stripAccents(Grader.normalize(text))
    }

    private static let articles = ["el ", "la ", "los ", "las ", "un ", "una ", "unos ", "unas "]

    /// True when what was heard contains one of the answers. "el café" also accepts "café".
    static func matches(_ heard: String, card: Card) -> Bool {
        let said = " " + simplified(heard) + " "
        for answer in card.answers {
            var forms = [simplified(answer)]
            if let article = articles.first(where: { forms[0].hasPrefix($0) }) {
                forms.append(String(forms[0].dropFirst(article.count)))
            }
            if forms.contains(where: { !$0.isEmpty && said.contains(" " + $0 + " ") }) { return true }
        }
        return false
    }

    /// A round of cards, newest words more often: half from the last 30 words met.
    static func round(from cards: [Card], count: Int = rounds) -> [Card] {
        let recent = Array(cards.suffix(30)).shuffled()
        var picked = Array(recent.prefix(count / 2))
        for card in cards.shuffled() where picked.count < count && !picked.contains(card) {
            picked.append(card)
        }
        return picked.shuffled()
    }

    static func xp(score: Int) -> Int { 2 + score }
}
