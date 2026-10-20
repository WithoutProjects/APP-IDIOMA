import Foundation

/// The four beats every lesson runs, from A0 to B2.
enum Beat: String {
    case frame, forge, fire, fix

    var title: String {
        switch self {
        case .frame: return "Frame"
        case .forge: return "Forge"
        case .fire: return "Fire"
        case .fix: return "Fix"
        }
    }
}

/// Beat 1: one rule shown as a picture, never a paragraph.
struct FrameCard: Hashable {
    let stem: String
    let ending: String
    let rule: Gloss
    let examples: [Example]

    var result: String { stem + ending }
}

/// Forge: drag (here: tap) a blue stem and an orange ending into the snap slot.
struct LegoSnap: Hashable {
    let person: Person
    let prompt: Gloss
    let stems: [String]
    let endings: [String]
    let answer: VerbForm
}

/// Forge to Fire: build a sentence from chunk tiles; the prompt is an intention, not a translation.
struct SentenceBuilder: Hashable {
    let intention: Gloss
    let tiles: [String]
    let accepted: [String]
    let model: Example
    let hint: Gloss
}

/// Fix: write it all in one go. Any order is fine as long as every chunk is there.
struct FreeWrite: Hashable {
    let instruction: Gloss
    let requiredChunks: [String]
    let model: Example
}

enum ItemKind: Hashable {
    case frame(FrameCard)
    case legoSnap(LegoSnap)
    case builder(SentenceBuilder)
    case freeWrite(FreeWrite)

    /// Recognition and info items earn less than production (see the XP economy).
    var isProduction: Bool {
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
    let id: String
    let number: Int
    let title: String
    let titleGloss: Gloss
    let goal: Gloss
    let items: [LessonItem]
}

/// A slot on the Unit path. Lessons without items are shown locked until their content ships.
struct PathNode: Identifiable {
    let id: String
    let title: String
    let gloss: Gloss
    let isBoss: Bool
}
