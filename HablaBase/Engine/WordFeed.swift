import Foundation

/// A word for "Palabras al azar": the Spanish, its meaning, where the path teaches it and a
/// sentence from that unit that uses it. Saved as it is in the learner's favourites folder.
struct FeedWord: Codable, Hashable, Identifiable {
    /// As the vocabulary slide writes it: "la casa", "él / ella".
    let es: String
    let gloss: Gloss
    /// The lesson whose vocabulary slides introduce the word.
    let lessonId: String
    /// A short sentence from the same unit with the word in it, if there is one.
    let example: Example?

    var id: String { WordFeed.key(es) }
    /// What the voice reads: the first way to say it.
    var spoken: String { VoiceRecall.variants(of: es).first ?? es }
}

/// "Palabras al azar": swipe up through Spanish words, one per screen, each with its meaning in
/// the learner's language. The words come from every lesson up to the learner's current level,
/// so the feed shows what they know and what is coming soon, never words from far ahead.
enum WordFeed {
    /// Example sentences stay short so the card reads at a glance.
    static let maxExampleWords = 12

    /// One entry per Spanish word, in path order.
    static func words(upToLevel level: Int, profile: Profile) -> [FeedWord] {
        var seen: Set<String> = []
        var words: [FeedWord] = []
        for curriculumLevel in Curriculum.shared.levels where curriculumLevel.number <= level {
            for unit in curriculumLevel.units {
                let lessons = LessonContent.lessons(ofUnit: unit.id, profile: profile)
                let unitSentences = lessons.flatMap(\.practiceSentences).map(\.example).filter(isShortExample)
                for lesson in lessons {
                    let own = lesson.practiceSentences.map(\.example).filter(isShortExample)
                    for word in lesson.vocabulary {
                        guard !Grader.normalize(word.es).isEmpty, !Grader.normalize(word.gloss.en).isEmpty,
                              seen.insert(key(word.es)).inserted else { continue }
                        let example = example(for: word.es, in: own) ?? example(for: word.es, in: unitSentences)
                        words.append(FeedWord(es: word.es, gloss: word.gloss, lessonId: lesson.id, example: example))
                    }
                }
            }
        }
        return words
    }

    /// The words in a new random order. The first is never the word just shown, so a new round
    /// doesn't repeat it twice in a row.
    static func deck(_ words: [FeedWord], after last: FeedWord? = nil) -> [FeedWord] {
        var deck = words.shuffled()
        if deck.count > 1, let last, deck[0].id == last.id {
            deck.swapAt(0, deck.count - 1)
        }
        return deck
    }

    /// The shortest sentence that uses the word ("la casa" also matches "mi casa"), and is longer
    /// than the word itself.
    static func example(for spanish: String, in sentences: [Example]) -> Example? {
        let forms = VoiceRecall.variants(of: spanish).map(withoutArticle).filter { !$0.isEmpty }
        guard !forms.isEmpty else { return nil }
        let longest = forms.map { $0.split(separator: " ").count }.max() ?? 0
        return sentences
            .filter { sentence in
                let text = VoiceRecall.simplified(sentence.es)
                let padded = " " + text + " "
                return text.split(separator: " ").count > longest
                    && forms.contains { padded.contains(" " + $0 + " ") }
            }
            .min { $0.es.count < $1.es.count }
    }

    /// The same word however it is written: no capitals, punctuation or accents.
    static func key(_ spanish: String) -> String {
        VoiceRecall.simplified(spanish)
    }

    /// One plain sentence: no personal placeholders, quotes or line breaks.
    static func isShortExample(_ example: Example) -> Bool {
        let text = example.es
        let count = text.split(separator: " ").count
        guard (2...maxExampleWords).contains(count), !text.contains("{"), !text.contains("\n"), !text.contains("«") else { return false }
        return !text.dropLast().contains(where: { ".?!".contains($0) })
    }

    private static let articles = ["el ", "la ", "los ", "las ", "un ", "una ", "unos ", "unas "]

    private static func withoutArticle(_ text: String) -> String {
        let simple = VoiceRecall.simplified(text)
        if let article = articles.first(where: { simple.hasPrefix($0) }), simple.count > article.count {
            return String(simple.dropFirst(article.count))
        }
        return simple
    }
}
