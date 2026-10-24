import Foundation

/// A sentence from a finished lesson, with its translation and every accepted way to say it.
struct PracticeSentence: Hashable {
    let example: Example
    let accepted: [String]

    /// The sentence itself is always accepted; builder and writing items add their variants.
    init(example: Example, accepted: [String] = []) {
        self.example = example
        var all = [example.es]
        for answer in accepted where !all.contains(where: { Grader.normalize($0) == Grader.normalize(answer) }) {
            all.append(answer)
        }
        self.accepted = all
    }

    var words: [String] { example.es.split(separator: " ").map(String.init) }
}

/// "Ordena la frase" and "Dictado": both use short sentences from the learner's own lessons,
/// so every word has been introduced.
enum SentenceGames {
    static let rounds = 8

    /// Marks that a tile never shows: they would give the order away.
    private static let marks = CharacterSet(charactersIn: "¿?¡!.,;:«»\"“”…")

    /// Short single sentences, each once, shuffled.
    static func pool(_ sentences: [PracticeSentence], words: ClosedRange<Int>) -> [PracticeSentence] {
        var seen: Set<String> = []
        return sentences.filter { sentence in
            let text = sentence.example.es
            guard words.contains(sentence.words.count), !text.contains("\n"), !text.contains("«"),
                  !text.contains("{"), seen.insert(Grader.normalize(text)).inserted else { return false }
            // One sentence only: no full stop or question mark before the end.
            let inner = text.dropLast()
            return !inner.contains(where: { ".?!".contains($0) })
        }.shuffled()
    }

    /// A round: the first `count` sentences of the shuffled pool.
    static func round(from pool: [PracticeSentence], count: Int = rounds) -> [PracticeSentence] {
        Array(pool.prefix(count))
    }

    /// The words of the sentence without punctuation, shuffled into a different order.
    static func tiles(for sentence: PracticeSentence) -> [String] {
        let words = sentence.words
            .map { $0.unicodeScalars.filter { !marks.contains($0) }.map(String.init).joined() }
            .filter { !$0.isEmpty }
        guard Set(words).count > 1 else { return words }
        var shuffled = words.shuffled()
        while shuffled == words { shuffled.shuffle() }
        return shuffled
    }

    /// Accents are forgiven with a note, as in the lessons.
    static func grade(_ answer: String, _ sentence: PracticeSentence) -> GradeOutcome {
        Grader.compare(answer, accepted: sentence.accepted, hint: "")
    }

    static func xp(score: Int) -> Int { 2 + score }
}
