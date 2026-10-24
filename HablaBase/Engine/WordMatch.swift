import Foundation

/// "Parejas de palabras": match words you have learned, your language on one side and
/// Spanish on the other. Four rounds of five pairs.
enum WordMatch {
    static let rounds = 4
    static let perRound = 5

    /// The Spanish side of a card: every right way to say it, "ellos / ellas".
    static func spanish(_ card: VoiceRecall.Card) -> String {
        card.answers.joined(separator: " / ")
    }

    /// Rounds of cards from the learner's words, newest words more often. Within a round no two
    /// cards share a Spanish word, so every pair has exactly one partner.
    static func rounds(from cards: [VoiceRecall.Card], count: Int = rounds, size: Int = perRound) -> [[VoiceRecall.Card]] {
        let pool = VoiceRecall.round(from: cards, count: count * size)
        var rounds: [[VoiceRecall.Card]] = []
        var left = pool
        while !left.isEmpty, rounds.count < count {
            var round: [VoiceRecall.Card] = []
            var used: Set<String> = []
            var skipped: [VoiceRecall.Card] = []
            for card in left {
                let words = Set(card.answers.map(VoiceRecall.simplified))
                if round.count < size, used.isDisjoint(with: words) {
                    round.append(card)
                    used.formUnion(words)
                } else {
                    skipped.append(card)
                }
            }
            guard round.count >= 2 else { break }
            rounds.append(round)
            left = skipped
        }
        return rounds
    }

    static func xp(score: Int) -> Int { min(20, 2 + score / 2) }
}
