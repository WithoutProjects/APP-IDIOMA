import Foundation

/// Where an item sits in a lesson. New words come first, then explanations (Frame) alternate
/// with short practice runs, a mixed block closes the lesson, and unit tests have no explanations.
enum Beat: String {
    case words, frame, forge, fire, mix, fix, test
    /// A quick review after two misses in a row on the same point.
    case review

    /// The small label above each item, in the learner's language.
    func title(_ language: NativeLanguage) -> String {
        switch self {
        case .words: return language.localized("New words")
        case .frame: return language.localized("How it works")
        case .forge, .fire: return language.localized("Practice")
        case .mix: return language.localized("Mix")
        case .fix: return language.localized("Second chance")
        case .test: return language.localized("Unit test")
        case .review: return language.localized("Quick review")
        }
    }
}

/// A new word, introduced on a slide before any exercise uses it.
struct VocabWord: Hashable {
    let es: String
    let gloss: Gloss
    let kind: Brick
}

/// A small set of new words: first shown as slides, then matched with their translations.
struct VocabSet: Hashable {
    let words: [VocabWord]
}

/// One brick on an explanation card.
struct FrameBrick: Hashable {
    let text: String
    let kind: Brick
}

/// An explanation: one rule shown as a picture, never a paragraph.
struct FrameCard: Hashable {
    /// The bricks that snap together, e.g. habl- + -o.
    let bricks: [FrameBrick]
    /// What they make, e.g. hablo. Stem and ending are coloured when given as a form.
    let result: VerbForm?
    let rule: Gloss
    let examples: [Example]
    /// Forms this explanation teaches (e.g. hablamos, comemos), with their meaning. From here on
    /// exercises may use them, and they join the learner's tap-to-translate glossary.
    var teaches: [VocabWord] = []

    /// The usual case: a stem and an ending that make a verb form.
    static func form(_ stem: String, _ ending: String, rule: Gloss, examples: [Example]) -> FrameCard {
        FrameCard(bricks: [FrameBrick(text: stem + "-", kind: .stem), FrameBrick(text: "-" + ending, kind: .ending)],
                  result: VerbForm(stem: stem, ending: ending), rule: rule, examples: examples)
    }
}

/// Forge: tap a blue stem and an orange ending into the snap slot.
struct LegoSnap: Hashable {
    let person: Person
    let prompt: Gloss
    let stems: [String]
    let endings: [String]
    let answer: VerbForm
}

/// Context Gap: type the missing verb; the sentence decides the person.
struct GapFill: Hashable {
    let before: String
    let after: String
    let lemma: String
    let accepted: [String]
    let gloss: Gloss
    let hint: Gloss

    var sentence: String { before + accepted[0] + after }
}

/// Pick the word that completes the sentence: for irregular forms, ser or estar, articles…
struct Choice: Hashable {
    let before: String
    let after: String
    let options: [String]
    let answer: String
    let gloss: Gloss
    let hint: Gloss

    var sentence: String { before + answer + after }
}

/// Build a sentence from chunk tiles; the prompt is an intention, not a translation.
struct SentenceBuilder: Hashable {
    let intention: Gloss
    let tiles: [String]
    let accepted: [String]
    let model: Example
    let hint: Gloss

    /// The tiles in the order of the model answer, for hints. Nil if the tiles can't spell it.
    var orderedTiles: [String]? {
        var remaining = Grader.normalize(accepted[0])
        var unused = Array(tiles.indices)
        var ordered: [String] = []
        while !remaining.isEmpty {
            let fits = unused.filter { index in
                let tile = Grader.normalize(tiles[index])
                return !tile.isEmpty && remaining.hasPrefix(tile)
                    && (remaining.count == tile.count || remaining.dropFirst(tile.count).first == " ")
            }
            guard let best = fits.max(by: { tiles[$0].count < tiles[$1].count }) else { return nil }
            ordered.append(tiles[best])
            unused.removeAll { $0 == best }
            remaining = String(remaining.dropFirst(Grader.normalize(tiles[best]).count))
                .trimmingCharacters(in: .whitespaces)
        }
        return ordered
    }
}

/// Write it all in one go. Any order is fine as long as every chunk is there.
/// Write a whole sentence. With `accepted`, the instruction gives the exact meaning to translate
/// and the answer must match one accepted sentence (accents forgiven). Without it (Lesson 2's
/// personal output), any order is fine as long as every required chunk is there.
struct FreeWrite: Hashable {
    let instruction: Gloss
    let requiredChunks: [String]
    let model: Example
    var accepted: [String] = []
}

enum ItemKind: Hashable {
    case slides(VocabSet)
    case match(VocabSet)
    case frame(FrameCard)
    case legoSnap(LegoSnap)
    case gapFill(GapFill)
    case choice(Choice)
    case builder(SentenceBuilder)
    case freeWrite(FreeWrite)

    /// Slides and explanations are read, not answered; everything else is a question.
    var isQuestion: Bool {
        switch self {
        case .slides, .frame: return false
        default: return true
        }
    }
}

struct LessonItem: Identifiable, Hashable {
    let id: String
    let beat: Beat
    let kind: ItemKind
    /// Only production errors on these formats cost an Energy bolt.
    let heartsAtRisk: Bool
    let formKeys: [FormKey]
}

struct Lesson: Identifiable {
    enum Mode {
        case lesson
        /// A unit test: no explanations, no energy cost, pass to skip the unit.
        case unitTest(unitId: String)
        /// The exam at the end of a level: 10 questions from all its units, 8 right to move on.
        case checkpoint(levelId: String)
        /// Practise missed forms: every right answer wins back a bolt of energy.
        case review

        var isReview: Bool {
            if case .review = self { return true }
            return false
        }
    }

    /// A block never asks more than this, mistakes replayed in Fix included, so lessons stay short.
    static let maxQuestions = 15
    /// Unit tests ask 10 questions and need 8 right.
    static let testQuestions = 10
    static let testPassMark = 8

    let id: String
    let title: String
    let titleGloss: Gloss
    let goal: Gloss
    let mode: Mode
    let items: [LessonItem]
    /// "Today you'll learn to say…": the sentence the lesson builds up to.
    var target: Example? = nil

    var questionCount: Int { items.filter { $0.kind.isQuestion }.count }

    /// The explanation that teaches what an item practises: the last one before it, or for a
    /// Mix item, the one whose first exercise practises the same person. Replays and twins
    /// ("-fix", "-twin") point back to their original item.
    func explanationIndex(for item: LessonItem) -> Int? {
        let baseId = item.id.components(separatedBy: "-fix")[0].components(separatedBy: "-twin")[0]
        let frames = items.indices.filter { if case .frame = items[$0].kind { return true } else { return false } }
        guard !frames.isEmpty else { return nil }
        guard let index = items.firstIndex(where: { $0.id == baseId }) else {
            // A twin made from scratch: match by person.
            return frames.first { practisedPerson(after: $0) == Self.person(of: item.formKeys.first) }
        }
        if items[index].beat == .mix, let person = Self.person(of: items[index].formKeys.first),
           let frame = frames.first(where: { practisedPerson(after: $0) == person }) {
            return frame
        }
        return frames.last { $0 < index }
    }

    func explanation(for item: LessonItem) -> FrameCard? {
        guard let index = explanationIndex(for: item), case .frame(let card) = items[index].kind else { return nil }
        return card
    }

    private func practisedPerson(after frame: Int) -> String? {
        items[(frame + 1)...].first { $0.kind.isQuestion }.flatMap { Self.person(of: $0.formKeys.first) }
    }

    /// "hablar.presente.yo" -> "yo"
    static func person(of key: FormKey?) -> String? {
        guard let parts = key?.split(separator: "."), parts.count == 3 else { return nil }
        return String(parts[2])
    }

    /// Forms taught inside explanations (e.g. hablamos), for the glossary and the notes.
    var taughtForms: [VocabWord] {
        items.flatMap { item -> [VocabWord] in
            if case .frame(let card) = item.kind { return card.teaches }
            return []
        }
    }

    /// The words this lesson introduces on its slides.
    var vocabulary: [VocabWord] {
        items.flatMap { item -> [VocabWord] in
            if case .slides(let set) = item.kind { return set.words }
            return []
        }
    }
}
