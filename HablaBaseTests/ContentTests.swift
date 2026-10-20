import XCTest
@testable import HablaBase

/// The lesson files (lessons-u{n}.json). tools/validate_content.py checks the vocabulary rule;
/// these tests check that the app reads every file the way the format describes.
final class ContentTests: XCTestCase {
    private let profile = Profile(name: "Ana", city: "Milán", workplace: .hospital,
                                  nativeLanguage: .english, goal: .travel, dailyMinutes: 10)

    private var builtLessons: [Lesson] {
        Curriculum.sharedPath.filter { $0.kind != .test && $0.kind != .checkpoint }
            .compactMap { LessonContent.lesson(id: $0.id, profile: profile) }
    }

    func testEveryLessonFileLoads() {
        for file in LessonLibrary.shared.files {
            for spec in file.lessons {
                XCTAssertNotNil(Curriculum.sharedPath.first { $0.id == spec.id }, "\(spec.id) is not on the path")
            }
            XCTAssertEqual(file.boss?.id, file.unit + "boss")
        }
    }

    func testLessonsStayWithinFifteenQuestionsAndStartWithWords() {
        for lesson in builtLessons {
            XCTAssertLessThanOrEqual(lesson.questionCount, Lesson.maxQuestions, lesson.id)
            if !lesson.id.hasSuffix("boss") {
                XCTAssertEqual(lesson.items.first?.beat, .words, "\(lesson.id) starts with its new words")
            }
        }
    }

    func testEveryExerciseCanBeAnswered() {
        for lesson in builtLessons {
            for item in lesson.items {
                switch item.kind {
                case .legoSnap(let snap):
                    XCTAssertTrue(snap.stems.contains(snap.answer.stem) && snap.endings.contains(snap.answer.ending), item.id)
                case .gapFill(let gap):
                    XCTAssertEqual(Grader.compare(gap.accepted[0], accepted: gap.accepted, hint: ""), .correct, item.id)
                case .choice(let choice):
                    XCTAssertTrue(choice.options.contains(choice.answer), item.id)
                case .builder(let builder):
                    XCTAssertNotNil(builder.orderedTiles, "\(item.id): tiles can't build \(builder.accepted[0])")
                case .freeWrite(let write):
                    XCTAssertNil(Grader.missingChunk(in: write.model.es, required: write.requiredChunks), item.id)
                default:
                    break
                }
            }
        }
    }

    func testPersonalPlaceholdersAreFilledIn() {
        for lesson in builtLessons {
            let texts = lesson.items.compactMap { item -> String? in
                switch item.kind {
                case .builder(let builder): return builder.accepted.joined() + builder.tiles.joined()
                case .freeWrite(let write): return write.model.es + write.requiredChunks.joined()
                case .gapFill(let gap): return gap.sentence
                case .choice(let choice): return choice.sentence
                default: return nil
                }
            }
            XCTAssertFalse(texts.contains { $0.contains("{") }, lesson.id)
        }
    }

    func testFinishedUnitsHaveATenQuestionTest() {
        for unit in Curriculum.shared.levels.flatMap(\.units) {
            guard let test = LessonContent.unitTest(unitId: unit.id, profile: profile) else { continue }
            XCTAssertEqual(test.questionCount, Lesson.testQuestions, unit.id)
            XCTAssertFalse(test.items.contains { if case .frame = $0.kind { return true } else { return false } })
            XCTAssertEqual(Set(test.items.map(\.id)).count, test.items.count)
        }
    }
}
