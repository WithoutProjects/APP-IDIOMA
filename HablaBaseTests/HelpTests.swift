import XCTest
@testable import HablaBase

/// Help that keeps learners from getting lost: explanations on demand, hints, tap-to-translate,
/// the quick review when stuck, and hearts that never block.
@MainActor
final class HelpTests: XCTestCase {
    private let profile = Profile(name: "Ana", city: "Milán", workplace: .hospital,
                                  nativeLanguage: .italian, goal: .travel, dailyMinutes: 10)

    func testEveryExerciseInALessonCanReopenItsExplanation() {
        for lesson in [Unit1.lesson1(), Unit1.lesson2(profile: profile)] {
            for item in lesson.items where item.kind.isQuestion && item.beat != .words {
                XCTAssertNotNil(lesson.explanation(for: item), item.id)
            }
        }
    }

    func testMixExercisesPointToTheirPersonsExplanation() {
        let lesson = Unit1.lesson1()
        let mix = lesson.items.first { $0.id == "u1l1-mix-1" }!  // vivir, tú
        let frame = lesson.explanationIndex(for: mix)!
        XCTAssertEqual(lesson.items[frame].id, "u1l1-tu")
    }

    func testBuilderHintsFollowTheModelAnswer() {
        let lessons = [Unit1.lesson1(), Unit1.lesson2(profile: profile), Unit1.unitTest()]
        for case .builder(let builder) in lessons.flatMap(\.items).map(\.kind) {
            let ordered = builder.orderedTiles
            XCTAssertNotNil(ordered, builder.accepted[0])
            XCTAssertEqual(Grader.compare(ordered!.joined(separator: " "), accepted: builder.accepted, hint: ""), .correct)
        }
    }

    func testGlossaryOnlyKnowsIntroducedWordsAndTheirForms() {
        let glossary = Glossary(words: Unit1.lesson1().vocabulary)
        XCTAssertEqual(glossary.lookup("¿Hablas")?.gloss, Gloss(en: "you speak", it: "parli"))
        XCTAssertEqual(glossary.lookup("café.")?.es, "café")
        XCTAssertNil(glossary.lookup("en"), "en is introduced in Lesson 2")
        XCTAssertNotNil(Glossary(words: Unit1.lesson2(profile: profile).vocabulary).lookup("llamo"))
    }

    func testTwoMissesInARowOnTheSamePointBringAQuickReview() {
        let all = Unit1.lesson1().items
        let start = all.firstIndex { $0.id == "u1l1-yo" }!
        let lesson = Lesson(id: "t", title: "", titleGloss: Gloss(en: "", it: ""), goal: Gloss(en: "", it: ""),
                            mode: .lesson, items: Array(all[start...]))
        let store = AppStore(storage: InMemoryProgressStorage())
        let session = LessonSession(lesson: lesson)

        session.submit(.correct, store: store)               // the explanation
        session.submit(.wrong(hint: ""), store: store)        // yo, first miss
        session.advance()
        session.submit(.wrong(hint: ""), store: store)        // yo, second miss
        XCTAssertEqual(session.queue[session.index + 1].beat, .review)
        let twin = session.queue[session.index + 2]
        XCTAssertEqual(twin.id, "u1l1-yo-2-twin")
        XCTAssertFalse(twin.heartsAtRisk)
        if case .legoSnap(let snap) = twin.kind {
            XCTAssertEqual(snap.stems.count, 1)
            XCTAssertTrue(snap.endings.contains(snap.answer.ending))
        } else {
            XCTFail("The twin is a Lego Snap")
        }
    }

    func testHintsLowerXPButCostNoHearts() {
        let lesson = Unit1.lesson1()
        let store = AppStore(storage: InMemoryProgressStorage())
        let session = LessonSession(lesson: lesson)
        while !(session.current?.kind.isQuestion ?? true) || session.current?.beat == .words {
            session.submit(.correct, store: store)
            if session.feedback != nil { session.advance() }
        }
        let hearts = store.state.energy
        session.useHint()
        session.submit(.correct, store: store)
        XCTAssertEqual(session.xpEarned, 1 + 3 * 3, "three matching sets, then one hinted answer")
        XCTAssertEqual(store.state.energy, hearts)
    }

    func testHeartsRefillEveryDay() {
        let store = AppStore(storage: InMemoryProgressStorage())
        for _ in 0..<SavedState.maxEnergy { store.spendEnergy() }
        XCTAssertEqual(store.state.energy, 0)
        store.refillEnergyIfNewDay(today: .now.addingTimeInterval(86_400))
        XCTAssertEqual(store.state.energy, SavedState.maxEnergy)
    }

    func testReviewPractisesTheMissedForms() {
        let missed = Conjugator.key(Unit1.verb("vivir"), .presente, .tu)
        let review = Unit1.reviewLesson(weakForms: [missed], completed: ["u1l1"])
        XCTAssertTrue(review.mode.isReview)
        XCTAssertEqual(review.items.first?.formKeys, [missed])
        XCTAssertLessThanOrEqual(review.questionCount, Lesson.maxQuestions)
    }
}

@MainActor
final class NotesAndSpeakingTests: XCTestCase {
    private let profile = Profile(name: "Ana", city: "Milán", workplace: .hospital,
                                  nativeLanguage: .english, goal: .travel, dailyMinutes: 10)

    func testSpeakingIgnoresAccentsAndPunctuation() {
        let words = SpeakingScore.words(said: "tu hablas espanol", target: "¿Tú hablas español?")
        XCTAssertTrue(words.allSatisfy(\.heard))
        XCTAssertTrue(SpeakingScore.passed(words))
    }

    func testSpeakingMarksMissingWords() {
        let words = SpeakingScore.words(said: "yo hablo", target: "Yo hablo español.")
        XCTAssertEqual(words.map(\.heard), [true, true, false])
        XCTAssertFalse(SpeakingScore.passed(words))
    }

    func testNotesShowReachedUnitsOnly() {
        let store = AppStore(storage: InMemoryProgressStorage())
        store.completeOnboarding(profile)
        XCTAssertEqual(store.notes.map(\.unit.id), ["u1"])
        XCTAssertEqual(store.notes.first?.lessons.map(\.id), ["u1l1"])
        XCTAssertTrue(store.speakingSentences.isEmpty, "nothing to say before the first lesson is done")
        store.completeLesson("u1l1", xp: 10)
        XCTAssertFalse(store.speakingSentences.isEmpty)
    }
}

final class SpokenAnswerTests: XCTestCase {
    func testSpokenSentenceIgnoresAccentsPunctuationAndDigits() {
        let accepted = ["Nos vemos a las siete."]
        XCTAssertTrue(Grader.compareSpokenSentence("nos vemos a las 7", accepted: accepted, hint: "").isCorrect)
        XCTAssertTrue(Grader.compareSpokenSentence("Nos vemos las siete", accepted: accepted, hint: "").isCorrect,
                      "a dropped short word is forgiven")
    }

    func testSpokenSentenceNeedsTheRightFormAndOrder() {
        let accepted = ["Yo como en casa."]
        XCTAssertFalse(Grader.compareSpokenSentence("yo comes en casa", accepted: accepted, hint: "").isCorrect)
        XCTAssertFalse(Grader.compareSpokenSentence("casa como yo", accepted: accepted, hint: "").isCorrect)
        XCTAssertFalse(Grader.compareSpokenSentence("como", accepted: ["No, no como."], hint: "").isCorrect,
                       "no is never forgiven")
    }

    func testSpokenGapAcceptsTheWordAloneOrInTheSentence() {
        XCTAssertTrue(Grader.compareSpokenPhrase("como", accepted: ["como"], hint: "").isCorrect)
        XCTAssertTrue(Grader.compareSpokenPhrase("no no como mucho", accepted: ["como"], hint: "").isCorrect)
        XCTAssertFalse(Grader.compareSpokenPhrase("comes", accepted: ["como"], hint: "").isCorrect)
    }

    func testTranslationPromptSplitsContextAndSentence() {
        let prompt = TranslationPrompt("A friend asks «¿Qué tal?». Write in Spanish: «Today I'm tired.»")
        XCTAssertEqual(prompt.context, "A friend asks «¿Qué tal?».")
        XCTAssertEqual(prompt.sentence, "Today I'm tired.")
        XCTAssertNil(TranslationPrompt("Say hello.").sentence)
    }
}
