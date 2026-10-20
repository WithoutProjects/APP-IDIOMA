import Foundation

/// A question the app asks aloud in Speak, with the answers it accepts.
struct SpokenQuestion: Hashable {
    let question: String
    /// Accepted answers; the first is the one shown and read back.
    let answers: [String]
    /// The translation of the whole exchange.
    let gloss: Gloss

    /// Question-and-answer exercises ("¿Comes mucho? No, no ___ mucho.") become spoken questions.
    static func from(_ kind: ItemKind) -> SpokenQuestion? {
        switch kind {
        case .gapFill(let gap):
            return split(before: gap.before, answers: gap.accepted, after: gap.after, gloss: gap.gloss)
        case .choice(let choice):
            return split(before: choice.before, answers: [choice.answer], after: choice.after, gloss: choice.gloss)
        default:
            return nil
        }
    }

    /// Only when the question is complete before the gap, so the answer is the learner's to say.
    private static func split(before: String, answers: [String], after: String, gloss: Gloss) -> SpokenQuestion? {
        guard before.hasPrefix("¿"), let end = before.firstIndex(of: "?") else { return nil }
        let question = String(before[...end])
        let rest = String(before[before.index(after: end)...])
        let full = answers.map { (rest + $0 + after).trimmingCharacters(in: .whitespaces) }
        guard let first = full.first, !first.isEmpty, !first.hasPrefix("¿") else { return nil }
        return SpokenQuestion(question: question, answers: full, gloss: gloss)
    }

    /// Questions about the learner, open once the lesson that teaches the answer is done.
    static func personal(profile: Profile, completed: Set<String>) -> [SpokenQuestion] {
        let fill = Placeholders(profile: profile)
        let all: [(String, String, [String], Gloss)] = [
            ("u1l3", "¿Cómo te llamas?", ["Me llamo {name}."],
             Gloss(en: "What's your name? My name is {name}.", it: "Come ti chiami? Mi chiamo {name}.")),
            ("u1l3", "¿Dónde vives?", ["Vivo en {city}.", "Yo vivo en {city}."],
             Gloss(en: "Where do you live? I live in {city}.", it: "Dove vivi? Vivo a {city}.")),
            ("u1l3", "¿Dónde trabajas?", ["Trabajo en {work}.", "Yo trabajo en {work}."],
             Gloss(en: "Where do you work? I work {workEn}.", it: "Dove lavori? Lavoro {workIt}.")),
            ("u1l3", "¿Hablas español?", ["Sí, hablo un poco de español.", "Sí, un poco.", "Hablo un poco de español."],
             Gloss(en: "Do you speak Spanish? Yes, I speak a little Spanish.", it: "Parli spagnolo? Sì, parlo un po' di spagnolo.")),
            ("u1l3", "¿Bebes café?", ["Sí, bebo café.", "No, no bebo café."],
             Gloss(en: "Do you drink coffee? Yes, I drink coffee. / No, I don't.", it: "Bevi caffè? Sì, bevo caffè. / No, non bevo caffè.")),
        ]
        return all.filter { completed.contains($0.0) }.map { entry in
            SpokenQuestion(question: entry.1, answers: entry.2.map { fill($0) },
                           gloss: Gloss(en: fill(entry.3.en), it: fill(entry.3.it)))
        }
    }
}

extension SpeakingScore {
    struct Check {
        let passed: Bool
        /// The closest accepted answer, word by word: heard or not.
        let words: [Word]
        /// Words said in the wrong form: (what was heard, what it should be).
        let fixes: [(said: String, correct: String)]
        let answer: String
    }

    /// An answer passes when every word of 3 or more letters of one accepted answer was heard.
    /// Short words (y, a, en) are forgiven: speech recognition often drops them.
    static func check(said: String, answers: [String]) -> Check {
        let scored = answers.map { answer -> (String, [Word]) in (answer, words(said: said, target: answer)) }
        let best = scored.max { lhs, rhs in
            lhs.1.filter(\.heard).count * rhs.1.count < rhs.1.filter(\.heard).count * lhs.1.count
        } ?? ("", [])
        let passed = !best.1.isEmpty && best.1.allSatisfy { $0.heard || key($0.text).count < 3 }

        let heard = Glossary.tokens(in: said)
        let fixes: [(said: String, correct: String)] = best.1.filter { !$0.heard }.compactMap { word in
            let target = key(word.text)
            guard target.count >= 3,
                  let close = heard.first(where: { Grader.stripAccents($0).prefix(3) == target.prefix(3) && Grader.stripAccents($0) != target })
            else { return nil }
            return (close, Glossary.tokens(in: word.text).first ?? word.text)
        }
        return Check(passed: passed, words: best.1, fixes: fixes, answer: best.0)
    }

    private static func key(_ word: String) -> String {
        Glossary.tokens(in: word).first.map(Grader.stripAccents) ?? ""
    }
}
