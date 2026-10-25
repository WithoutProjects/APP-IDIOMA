import Foundation

/// A Spanish saying (refrán), split where the game cuts it. Every Spanish word on screen comes
/// with its literal translation, and the meaning is given after each answer, so nothing is
/// shown without being explained.
struct Saying: Decodable, Identifiable, Hashable {
    let id: String
    /// "Más vale tarde"
    let start: String
    /// "que nunca"
    let end: String
    /// The lesson that teaches the grammar it uses (imperative, subjunctive…).
    let unlockedBy: String
    let startLiteral: Gloss
    let endLiteral: Gloss
    /// What it means, in plain words.
    let meaning: Gloss

    /// "Más vale tarde que nunca."
    var spanish: String { "\(start) \(end)." }

    /// The literal translation of the whole saying.
    func literal(_ language: NativeLanguage) -> String {
        let separator = language == .chinese ? "" : " "
        return startLiteral.text(language) + separator + endLiteral.text(language)
    }
}

/// Every saying, from Content/sayings.json.
final class SayingBook {
    static let shared = SayingBook()

    let sayings: [Saying]

    private struct File: Decodable {
        let sayings: [Saying]
    }

    init(bundle: Bundle = .main) {
        var loaded: [Saying] = []
        if let url = bundle.url(forResource: "sayings", withExtension: "json") {
            do {
                loaded = try JSONDecoder().decode(File.self, from: Data(contentsOf: url)).sayings
            } catch {
                assertionFailure("sayings.json does not match the format: \(error)")
            }
        } else {
            assertionFailure("sayings.json is missing from the app bundle")
        }
        sayings = loaded
    }

    /// The sayings whose grammar the learner has reached.
    func open(completed: Set<String>) -> [Saying] {
        sayings.filter { completed.contains($0.unlockedBy) }
    }
}

/// "Termina el refrán": the start of a saying; pick its end from three.
enum SayingsGame {
    static let rounds = 8
    static let optionCount = 3

    struct Question: Identifiable, Hashable {
        let id = UUID()
        let saying: Saying
        /// The right end and up to two ends of other open sayings, shuffled.
        let options: [Saying]
    }

    static func questions(from open: [Saying], count: Int = rounds) -> [Question] {
        guard open.count >= optionCount else { return [] }
        return open.shuffled().prefix(count).map { saying in
            let wrong = open.filter { $0 != saying }.shuffled().prefix(optionCount - 1)
            return Question(saying: saying, options: ([saying] + wrong).shuffled())
        }
    }

    static func xp(score: Int) -> Int { 2 + score }
}
