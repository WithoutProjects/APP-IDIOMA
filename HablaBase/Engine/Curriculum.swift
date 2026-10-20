import Foundation

/// The whole journey from zero to expert, loaded from Content/curriculum.json.
/// Level > Unit > Lessons + Boss + Test, and a Checkpoint closes every level.
struct Curriculum: Decodable {
    let version: Int
    let levels: [CurriculumLevel]

    static let shared = Curriculum.load()
    /// The path is fixed for the app's lifetime, so it is built once.
    static let sharedPath = shared.path

    static func load(bundle: Bundle = .main) -> Curriculum {
        guard let url = bundle.url(forResource: "curriculum", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let curriculum = try? JSONDecoder().decode(Curriculum.self, from: data) else {
            fatalError("curriculum.json is missing from the app bundle or does not match the model")
        }
        return curriculum
    }

    /// Every step in the order the learner meets it.
    var path: [PathNode] {
        var nodes: [PathNode] = []
        for level in levels {
            for unit in level.units {
                for lesson in unit.lessons {
                    nodes.append(PathNode(id: lesson.id, title: lesson.title, gloss: lesson.gloss,
                                          kind: .lesson, levelId: level.id, unitId: unit.id))
                }
                nodes.append(PathNode(id: unit.boss.id, title: unit.boss.title, gloss: unit.boss.gloss,
                                      kind: .boss, levelId: level.id, unitId: unit.id))
                nodes.append(PathNode(id: unit.test.id, title: unit.test.title, gloss: unit.test.gloss,
                                      kind: .test, levelId: level.id, unitId: unit.id))
            }
            nodes.append(PathNode(id: level.checkpoint.id, title: level.checkpoint.title, gloss: level.checkpoint.gloss,
                                  kind: .checkpoint, levelId: level.id, unitId: nil))
        }
        return nodes
    }

    func level(id: String) -> CurriculumLevel? {
        levels.first { $0.id == id }
    }

    func unit(id: String) -> CurriculumUnit? {
        levels.flatMap(\.units).first { $0.id == id }
    }
}

struct CurriculumLevel: Decodable, Identifiable {
    let id: String
    let number: Int
    /// CEFR band, e.g. "A0–A1".
    let cefr: String
    let name: String
    let gloss: Gloss
    /// The speaking goal the checkpoint tests.
    let canDo: Gloss
    let units: [CurriculumUnit]
    let checkpoint: NodePlan
}

struct CurriculumUnit: Decodable, Identifiable {
    let id: String
    let number: Int
    let title: String
    let gloss: Gloss
    /// Grammar engine unlocked in this unit.
    let grammar: [String]
    /// Connectors and prepositions practised as rails.
    let connectors: [String]
    let lessons: [LessonPlan]
    let boss: NodePlan
    /// 10 questions that close the unit; passing it early skips the unit.
    let test: NodePlan
}

struct LessonPlan: Decodable, Identifiable {
    let id: String
    let title: String
    let gloss: Gloss
    /// The one new thing this lesson teaches.
    let focus: String
}

/// A boss fight, unit test or level checkpoint.
struct NodePlan: Decodable, Identifiable {
    let id: String
    let title: String
    let gloss: Gloss
}

/// One step on the path.
struct PathNode: Identifiable {
    enum Kind {
        case lesson, boss, test, checkpoint
    }

    let id: String
    let title: String
    let gloss: Gloss
    let kind: Kind
    let levelId: String
    let unitId: String?
}
