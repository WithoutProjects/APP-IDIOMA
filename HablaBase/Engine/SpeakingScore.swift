import Foundation

/// Compares what the speech recogniser heard with the sentence the learner tried to say.
/// Accents, capitals and punctuation don't count: you can't hear them.
enum SpeakingScore {
    struct Word: Hashable {
        let text: String
        let heard: Bool
    }

    /// At least this share of the words must be heard to pass.
    static let passMark = 0.8

    /// The target's words, each marked heard or not.
    static func words(said: String, target: String) -> [Word] {
        let heard = Set(Glossary.tokens(in: said).map(Grader.stripAccents))
        return target.split(separator: " ").map { word in
            let key = Glossary.tokens(in: String(word)).first.map(Grader.stripAccents) ?? ""
            return Word(text: String(word), heard: key.isEmpty || heard.contains(key))
        }
    }

    static func passed(_ words: [Word]) -> Bool {
        guard !words.isEmpty else { return false }
        return Double(words.filter(\.heard).count) / Double(words.count) >= passMark
    }
}
