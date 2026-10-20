import Foundation

/// Where an item sits in a lesson. Explanations (Frame) alternate with short practice runs,
/// a mixed block closes the lesson, and unit tests have no explanations at all.
enum Beat: String {
    case frame, forge, fire, mix, fix, test

    var title: String {
        switch self {
        case .frame: return "Frame"
        case .forge: return "Forge"
        case .fire: return "Fire"
        case .mix: return "Mix"
        case .fix: return "Fix"
        case .test: return "Test"
        }
    }
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

/// Build a sentence from chunk tiles; the prompt is an intention, not a translation.
struct SentenceBuilder: Hashable {
    let intention: Gloss
    let tiles: [String]
    let accepted: [String]
    let model: Example
    let hint: Gloss
}

/// Write it all in one go. Any order is fine as long as every chunk is there.
struct FreeWrite: Hashable {
    let instruction: Gloss
    let requiredChunks: [String]
    let model: Example
}

enum ItemKind: Hashable {
    case frame(FrameCard)
    case legoSnap(LegoSnap)
    case gapFill(GapFill)
    case builder(SentenceBuilder)
    case freeWrite(FreeWrite)

    /// Explanations are read, not answered; everything else is a question.
    var isQuestion: Bool {
        if case .frame = self { return false }
        return true
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

    var questionCount: Int { items.filter { $0.kind.isQuestion }.count }
}
