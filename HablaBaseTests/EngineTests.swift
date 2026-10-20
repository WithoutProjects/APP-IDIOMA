import XCTest
@testable import HablaBase

final class ConjugatorTests: XCTestCase {
    func testPresentAcrossFamilies() {
        let expected: [String: [String]] = [
            "hablar": ["hablo", "hablas", "habla", "hablamos", "habláis", "hablan"],
            "comer": ["como", "comes", "come", "comemos", "coméis", "comen"],
            "vivir": ["vivo", "vives", "vive", "vivimos", "vivís", "viven"],
        ]
        for (lemma, forms) in expected {
            let verb = Unit1.verb(lemma)
            XCTAssertEqual(Person.allCases.map { Conjugator.conjugate(verb, .presente, $0).text }, forms, lemma)
        }
    }

    func testFormSplitsIntoBricks() {
        let form = Conjugator.conjugate(Unit1.verb("trabajar"), .presente, .yo)
        XCTAssertEqual(form.stem, "trabaj")
        XCTAssertEqual(form.ending, "o")
    }

    func testEveryUnit1VerbHasAFamily() {
        XCTAssertEqual(Unit1.verbs.filter { $0.family == .ar }.count, 6)
        XCTAssertEqual(Unit1.verbs.filter { $0.family == .er }.count, 4)
        XCTAssertEqual(Unit1.verbs.filter { $0.family == .ir }.count, 2)
    }
}

final class GraderTests: XCTestCase {
    func testIgnoresCaseAndPunctuation() {
        XCTAssertEqual(Grader.compare("trabajo en casa", accepted: ["Trabajo en casa."], hint: ""), .correct)
        XCTAssertEqual(Grader.compare("¿Hablas inglés?", accepted: ["hablas inglés"], hint: ""), .correct)
    }

    func testMissingAccentIsAlmostCorrect() {
        XCTAssertEqual(Grader.compare("Vivo en Milan", accepted: ["Vivo en Milán."], hint: ""), .accent(expected: "Vivo en Milán."))
    }

    func testEnyeIsNotAnAccent() {
        XCTAssertEqual(Grader.stripAccents("año está"), "año esta")
    }

    func testWrongAnswerCarriesHint() {
        XCTAssertEqual(Grader.compare("Vivo en casa", accepted: ["Trabajo en casa"], hint: "trabaj- + -o"), .wrong(hint: "trabaj- + -o"))
    }

    func testMissingChunkMatchesWholeWords() {
        let required = ["me llamo Ana", "vivo en Milán", "trabajo en un hospital", "y"]
        XCTAssertNil(Grader.missingChunk(in: "Me llamo Ana, vivo en Milan y trabajo en un hospital.", required: required))
        XCTAssertEqual(Grader.missingChunk(in: "Me llamo Ana, vivo en Milán, trabajo en un hospital.", required: required), "y")
        XCTAssertEqual(Grader.missingChunk(in: "Me llamo Ana y vivo en Milán.", required: required), "trabajo en un hospital")
    }
}

final class Lesson1Tests: XCTestCase {
    private let profile = Profile(name: "Ana", city: "Milán", workplace: .hospital,
                                  nativeLanguage: .italian, goal: .travel, dailyMinutes: 10)

    func testRunsFrameForgeFireFix() {
        let lesson = Unit1.lesson1(profile: profile)
        XCTAssertEqual(lesson.items.first?.beat, .frame)
        XCTAssertEqual(lesson.items.filter { $0.beat == .forge }.count, 6)
        XCTAssertEqual(lesson.items.filter { $0.beat == .fire }.count, 5)
        XCTAssertEqual(lesson.items.last?.beat, .fix)
    }

    func testBuilderTilesCanMakeTheAcceptedSentence() {
        for item in Unit1.lesson1(profile: profile).items {
            guard case .builder(let builder) = item.kind else { continue }
            var tiles = builder.tiles
            for word in builder.accepted[0].dropLast().split(separator: " ").map(String.init) {
                guard let index = tiles.firstIndex(of: word) else {
                    return XCTFail("\(item.id): no tile for \(word)")
                }
                tiles.remove(at: index)
            }
        }
    }

    func testSnapTrayAlwaysHoldsTheAnswer() {
        for item in Unit1.lesson1(profile: profile).items {
            guard case .legoSnap(let snap) = item.kind else { continue }
            XCTAssertTrue(snap.stems.contains(snap.answer.stem), item.id)
            XCTAssertEqual(Set(snap.stems).count, snap.stems.count, item.id)
        }
    }

    func testModelAnswerPassesTheOutputCheck() {
        for item in Unit1.lesson1(profile: profile).items {
            guard case .freeWrite(let write) = item.kind else { continue }
            XCTAssertNil(Grader.missingChunk(in: write.model.es, required: write.requiredChunks))
        }
    }
}

final class CurriculumTests: XCTestCase {
    private let curriculum = Curriculum.shared

    func testGoesFromZeroToExpert() {
        XCTAssertEqual(curriculum.levels.count, 8)
        XCTAssertEqual(curriculum.levels.first?.cefr, "A0–A1")
        XCTAssertEqual(curriculum.levels.last?.cefr, "C2")
        XCTAssertEqual(curriculum.levels.map(\.number), Array(1...8))
    }

    func testEveryStepHasAUniqueId() {
        let ids = Curriculum.sharedPath.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
    }

    func testEveryUnitHasLessonsAndABoss() {
        for unit in curriculum.levels.flatMap(\.units) {
            XCTAssertGreaterThanOrEqual(unit.lessons.count, 5, unit.id)
            XCTAssertEqual(unit.boss.id, "\(unit.id)boss")
            XCTAssertFalse(unit.grammar.isEmpty, unit.id)
        }
    }

    func testEveryLevelEndsWithItsCheckpoint() {
        for level in curriculum.levels {
            let last = Curriculum.sharedPath.last { $0.levelId == level.id }
            XCTAssertEqual(last?.kind, .checkpoint, level.id)
        }
    }

    func testUnit1MatchesTheBuiltLessons() {
        let unit1 = curriculum.levels[0].units[0]
        XCTAssertEqual(unit1.lessons.map(\.id), ["u1l1", "u1l2", "u1l3", "u1l4", "u1l5", "u1l6"])
        let profile = Profile(name: "Ana", city: "Milán", workplace: .hospital, nativeLanguage: .english, goal: .travel, dailyMinutes: 10)
        XCTAssertNotNil(Unit1.lesson(id: Curriculum.sharedPath[0].id, profile: profile))
    }
}
