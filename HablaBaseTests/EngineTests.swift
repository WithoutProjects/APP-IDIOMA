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

final class Unit1Tests: XCTestCase {
    private let profile = Profile(name: "Ana", city: "Milán", workplace: .hospital,
                                  nativeLanguage: .italian, goal: .travel, dailyMinutes: 10)

    private var allBlocks: [Lesson] {
        [Unit1.lesson1(), Unit1.lesson2(profile: profile), Unit1.unitTest()]
    }

    func testLesson1ExplainsEachPersonThenPractisesTwiceThenMixes() {
        let beats = Unit1.lesson1().items.map(\.beat)
        let explanations = beats.indices.filter { beats[$0] == .frame }
        XCTAssertEqual(explanations.count, 3)
        for (index, start) in explanations.enumerated() {
            let end = index + 1 < explanations.count ? explanations[index + 1] : beats.firstIndex(of: .mix)!
            XCTAssertEqual(end - start - 1, 2, "two exercises after explanation \(index + 1)")
        }
        XCTAssertEqual(beats.last, .mix)
    }

    func testBlocksStayWithinFifteenQuestions() {
        for lesson in allBlocks {
            XCTAssertLessThanOrEqual(lesson.questionCount, Lesson.maxQuestions, lesson.id)
        }
    }

    func testUnitTestHasTenQuestionsAndNoExplanations() {
        let test = Unit1.unitTest()
        XCTAssertEqual(test.questionCount, Lesson.testQuestions)
        XCTAssertEqual(test.items.count, Lesson.testQuestions)
    }

    func testBuilderTilesCanMakeTheAcceptedSentence() {
        for lesson in allBlocks {
            for item in lesson.items {
                guard case .builder(let builder) = item.kind else { continue }
                let target = Grader.normalize(builder.accepted[0])
                XCTAssertTrue(canBuild(target, from: builder.tiles.map(Grader.normalize)), item.id)
            }
        }
    }

    /// Whether some of the tiles, in some order, spell the target exactly.
    private func canBuild(_ target: String, from tiles: [String]) -> Bool {
        if target.isEmpty { return true }
        for (index, tile) in tiles.enumerated() where target == tile || target.hasPrefix(tile + " ") {
            var rest = tiles
            rest.remove(at: index)
            let remaining = String(target.dropFirst(tile.count)).trimmingCharacters(in: .whitespaces)
            if canBuild(remaining, from: rest) { return true }
        }
        return false
    }

    /// Carla's rule: an exercise never uses a word the learner has not been shown yet.
    func testEveryWordIsIntroducedBeforeItIsUsed() {
        var known: Set<String> = Set([profile.name, profile.city].flatMap(words))
        for verb in Unit1.coreVerbs {
            for person in Unit1.persons {
                known.insert(Conjugator.conjugate(verb, .presente, person).text)
            }
        }
        for lesson in [Unit1.lesson1(), Unit1.lesson2(profile: profile), Unit1.unitTest()] {
            for item in lesson.items {
                if case .slides(let set) = item.kind {
                    set.words.flatMap { words($0.es) }.forEach { known.insert($0) }
                }
                for word in spanishText(of: item.kind).flatMap(words) {
                    XCTAssertTrue(known.contains(word), "\(item.id) uses \"\(word)\" before it is introduced")
                }
            }
        }
    }

    private func words(_ text: String) -> [String] {
        Grader.normalize(text).split(separator: " ").map(String.init)
    }

    private func spanishText(of kind: ItemKind) -> [String] {
        switch kind {
        case .slides, .match: return []
        case .frame(let card): return card.examples.map(\.es)
        case .legoSnap(let snap): return [snap.answer.text]
        case .gapFill(let gap): return [gap.sentence]
        case .builder(let builder): return builder.accepted + builder.tiles
        case .freeWrite(let write): return [write.model.es]
        }
    }

    func testSnapTrayAlwaysHoldsTheAnswer() {
        for lesson in allBlocks {
            for item in lesson.items {
                guard case .legoSnap(let snap) = item.kind else { continue }
                XCTAssertTrue(snap.stems.contains(snap.answer.stem), item.id)
                XCTAssertTrue(snap.endings.contains(snap.answer.ending), item.id)
                XCTAssertEqual(Set(snap.stems).count, snap.stems.count, item.id)
            }
        }
    }

    func testGapAnswersAreTheConjugatedForm() {
        let gaps = Unit1.lesson1().items.compactMap { item -> GapFill? in
            if case .gapFill(let gap) = item.kind { return gap }
            return nil
        }
        XCTAssertEqual(gaps.first?.sentence, "Yo hablo español.")
        for gap in gaps {
            XCTAssertEqual(Grader.compare(gap.accepted[0], accepted: gap.accepted, hint: ""), .correct)
        }
    }

    func testModelAnswerPassesTheOutputCheck() {
        for item in Unit1.lesson2(profile: profile).items {
            guard case .freeWrite(let write) = item.kind else { continue }
            XCTAssertNil(Grader.missingChunk(in: write.model.es, required: write.requiredChunks))
        }
    }
}

final class PairsGameTests: XCTestCase {
    func testEachRoundUsesDifferentPersons() {
        let rounds = PairsGame.makeRounds(verbs: Unit1.coreVerbs, persons: Unit1.persons)
        XCTAssertEqual(rounds.count, PairsGame.rounds)
        for round in rounds {
            XCTAssertEqual(round.count, 3)
            XCTAssertEqual(Set(round.map(\.person)).count, round.count)
        }
    }

    func testNeedsAtLeastTwoPersons() {
        XCTAssertTrue(PairsGame.makeRounds(verbs: Unit1.verbs, persons: [.yo]).isEmpty)
    }
}

@MainActor
final class ProgressTests: XCTestCase {
    func testProgressSurvivesARestart() {
        let storage = InMemoryProgressStorage()
        let store = AppStore(storage: storage)
        store.completeLesson("u1l1", xp: 20)
        let reopened = AppStore(storage: storage)
        XCTAssertTrue(reopened.isCompleted("u1l1"))
        XCTAssertEqual(reopened.state.xp, 20)
    }

    func testOlderSavesWithMissingFieldsStillLoad() throws {
        let old = #"{"xp": 42, "completedLessons": ["u1l1"]}"#.data(using: .utf8)!
        let state = try JSONDecoder().decode(SavedState.self, from: old)
        XCTAssertEqual(state.xp, 42)
        XCTAssertEqual(state.energy, SavedState.maxEnergy)
        XCTAssertEqual(state.completedLessons, ["u1l1"])
    }

    func testFileStorageRoundTrip() {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString).appendingPathComponent("progress.json")
        var state = SavedState()
        state.xp = 7
        FileProgressStorage(url: url).save(state)
        XCTAssertEqual(FileProgressStorage(url: url).load()?.xp, 7)
    }

    func testPassingAUnitTestSkipsEverythingUpToIt() {
        let store = AppStore(storage: InMemoryProgressStorage())
        store.completeUnit("u2")
        XCTAssertTrue(store.isCompleted("u1l1"))
        XCTAssertTrue(store.isCompleted("u2boss"))
        XCTAssertTrue(store.isCompleted("u2test"))
        XCTAssertFalse(store.isCompleted("u3l1"))
        XCTAssertEqual(store.nextNode?.id, "u3l1")
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

    func testEveryUnitHasLessonsABossAndATest() {
        for unit in curriculum.levels.flatMap(\.units) {
            XCTAssertGreaterThanOrEqual(unit.lessons.count, 5, unit.id)
            XCTAssertEqual(unit.boss.id, "\(unit.id)boss")
            XCTAssertEqual(unit.test.id, "\(unit.id)test")
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
