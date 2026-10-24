import XCTest
@testable import HablaBase

/// Checks for the App Store build: a learner can walk the whole built path without a dead end.
final class ReleaseTests: XCTestCase {
    private let profile = Profile(name: "Ana", city: "Milán", workplace: .hospital,
                                  nativeLanguage: .english, goal: .travel, dailyMinutes: 10)

    func testThePathHasNoDeadEndBeforeTheLastBuiltLesson() {
        let path = Curriculum.sharedPath
        guard let last = path.lastIndex(where: { $0.kind == .lesson && LessonContent.lesson(id: $0.id, profile: profile) != nil }) else {
            return XCTFail("No lesson is built")
        }
        for node in path[...last] {
            XCTAssertNotNil(LessonContent.lesson(id: node.id, profile: profile), "\(node.id) stops learners on the path")
        }
    }

    func testTheLevelExamAsksTenQuestionsFromTheLevel() {
        let exam = LessonContent.lesson(id: "level1check", profile: profile)
        XCTAssertEqual(exam?.questionCount, Lesson.testQuestions)
        if case .checkpoint(let levelId)? = exam?.mode {
            XCTAssertEqual(levelId, "level1")
        } else {
            XCTFail("level1check is a level exam")
        }
    }

    func testEveryLevelHasItsExam() {
        for level in Curriculum.shared.levels {
            XCTAssertEqual(LessonContent.lesson(id: level.checkpoint.id, profile: profile)?.questionCount,
                           Lesson.testQuestions, level.checkpoint.id)
        }
    }
}
