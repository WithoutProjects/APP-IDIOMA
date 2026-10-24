import XCTest
@testable import HablaBase

/// The verb tables and the Lab games built on them and on the learner's own sentences.
@MainActor
final class LabGamesTests: XCTestCase {
    private let profile = Profile(name: "Ana", city: "Milán", workplace: .hospital,
                                  nativeLanguage: .english, goal: .travel, dailyMinutes: 10)
    private let book = VerbBook.shared

    private func words(_ lemmas: [String]) -> [VocabWord] {
        lemmas.map { VocabWord(es: $0, gloss: Gloss(en: $0, it: $0, uk: $0), kind: .stem) }
    }

    private func forms(_ lemma: String, _ tense: VerbTense) -> [String] {
        Person.allCases.compactMap { book.verb(lemma)?.form(tense, $0)?.text }
    }

    // MARK: Verb tables

    func testEveryVerbHasSixFormsInEveryTense() {
        XCTAssertGreaterThan(book.verbs.count, 140)
        for verb in book.verbs {
            XCTAssertEqual(Set(verb.forms.keys), Set(VerbTense.allCases), verb.lemma)
        }
    }

    func testHardFormsAreRight() {
        XCTAssertEqual(forms("ser", .presente), ["soy", "eres", "es", "somos", "sois", "son"])
        XCTAssertEqual(forms("tener", .indefinido), ["tuve", "tuviste", "tuvo", "tuvimos", "tuvisteis", "tuvieron"])
        XCTAssertEqual(forms("hacer", .perfecto), ["he hecho", "has hecho", "ha hecho", "hemos hecho", "habéis hecho", "han hecho"])
        XCTAssertEqual(forms("levantarse", .presente), ["me levanto", "te levantas", "se levanta", "nos levantamos", "os levantáis", "se levantan"])
        XCTAssertEqual(forms("poder", .condicional).first, "podría")
        XCTAssertEqual(forms("ir", .subjuntivoImperfecto).first, "fuera")
    }

    func testFormsSplitIntoStemAndEnding() {
        let tuve = book.verb("tener")?.form(.indefinido, .yo)
        XCTAssertEqual(tuve?.stem, "tuv")
        XCTAssertEqual(tuve?.ending, "e")
        XCTAssertEqual(book.verb("ser")?.form(.presente, .yo)?.stem, "soy")
        XCTAssertEqual(book.verb("ser")?.form(.presente, .yo)?.ending, "")
    }

    func testPresentFormsMatchTheLessonsConjugator() {
        for verb in Unit1.verbs {
            for person in Person.allCases {
                XCTAssertEqual(book.verb(verb.lemma)?.form(.presente, person)?.text,
                               Conjugator.conjugate(verb, .presente, person).text, verb.lemma)
            }
        }
    }

    func testEveryVerbIsTaughtInALesson() {
        let taught = Set(Curriculum.sharedPath.compactMap { LessonContent.lesson(id: $0.id, profile: profile) }
            .flatMap(\.vocabulary).filter { $0.kind == .stem }.map(\.es))
        for verb in book.verbs {
            XCTAssertTrue(taught.contains(verb.lemma), "\(verb.lemma) is never on a vocabulary slide")
        }
    }

    // MARK: What the learner can be asked

    func testTheDeckFollowsThePath() {
        let early = VerbDeck(completed: ["u1l1"], words: words(["hablar", "tener"]))
        XCTAssertEqual(early.persons, [.yo, .tu, .el])
        XCTAssertEqual(Set(early.cards.map(\.tense)), [.presente])
        XCTAssertEqual(early.cards.count, 2 * 3)

        let pastRegular: Set<String> = ["u1l1", "u2l1", "u2l2", "u2l3", "u15l2"]
        let deck = VerbDeck(completed: pastRegular, words: words(["hablar", "tener"]))
        XCTAssertEqual(deck.persons, Person.allCases)
        XCTAssertTrue(deck.isOpen(book.verb("hablar")!, .indefinido))
        XCTAssertFalse(deck.isOpen(book.verb("tener")!, .indefinido), "tuve waits for the irregular past lesson")
        XCTAssertTrue(VerbDeck(completed: pastRegular.union(["u16l5"]), words: []).isOpen(book.verb("tener")!, .indefinido))
    }

    func testOnlyVerbsFromFinishedLessonsAreAsked() {
        let deck = VerbDeck(completed: ["u1l1"], words: words(["hablar"]) + [VocabWord(es: "café", gloss: Gloss(en: "", it: "", uk: ""), kind: .chunk)])
        XCTAssertEqual(deck.verbs.map(\.lemma), ["hablar"])
    }

    // MARK: Contrarreloj

    func testSprintOptionsAreRealDistinctFormsWithTheAnswer() {
        let deck = VerbDeck(completed: ["u1l1", "u2l1", "u2l2", "u2l3", "u15l2", "u16l5"], words: words(["tener", "hablar", "comer"]))
        for _ in 0..<50 {
            guard let question = SprintGame.question(deck: deck) else { return XCTFail("No question") }
            let texts = question.options.map(\.text)
            XCTAssertTrue(texts.contains(question.answer.text))
            XCTAssertEqual(Set(texts).count, texts.count)
            XCTAssertTrue((2...4).contains(texts.count))
            let real = Set(VerbTense.allCases.flatMap { tense in Person.allCases.compactMap { question.card.verb.form(tense, $0)?.text } })
            XCTAssertTrue(Set(texts).isSubset(of: real))
        }
    }

    func testSprintNeverRepeatsTheSameCardTwiceInARow() {
        let deck = VerbDeck(completed: ["u1l1"], words: words(["hablar", "comer"]))
        var previous = SprintGame.question(deck: deck)?.card
        for _ in 0..<30 {
            let next = SprintGame.question(deck: deck, after: previous)?.card
            XCTAssertNotEqual(next, previous)
            previous = next
        }
    }

    func testSprintWithoutVerbsHasNoQuestion() {
        XCTAssertNil(SprintGame.question(deck: VerbDeck(completed: [], words: [])))
    }

    // MARK: Caza de errores

    private var huntDeck: VerbDeck {
        VerbDeck(completed: ["u1l1", "u2l1", "u2l2", "u2l3", "u14l1", "u14l4"], words: words(["hablar", "comer", "ser", "levantarse"]))
    }

    private func example(_ es: String) -> Example {
        Example(es: es, gloss: Gloss(en: es, it: es, uk: es))
    }

    func testFindsTheVerbAfterTheSubject() {
        let candidate = ErrorHunt.candidate(in: example("Nosotros hablamos español."), deck: huntDeck)
        XCTAssertEqual(candidate?.span, 1..<2)
        XCTAssertEqual(candidate?.person, .nosotros)
        XCTAssertEqual(ErrorHunt.candidate(in: example("Yo no me levanto pronto."), deck: huntDeck)?.span, 2..<4)
    }

    func testSkipsSentencesWhereThePronounIsNotTheSubject() {
        XCTAssertNil(ErrorHunt.candidate(in: example("Mi amiga y yo somos de Madrid."), deck: huntDeck))
        XCTAssertNil(ErrorHunt.candidate(in: example("Con ella hablo español."), deck: huntDeck))
        XCTAssertNil(ErrorHunt.candidate(in: example("Hablamos español."), deck: huntDeck))
    }

    func testAChangedVerbIsAlwaysReallyWrong() {
        let candidate = ErrorHunt.candidate(in: example("Yo hablo español."), deck: huntDeck)!
        let yoForms = Set(VerbTense.allCases.compactMap { candidate.verb.form($0, .yo)?.text })
        for _ in 0..<30 {
            let round = ErrorHunt.round(from: candidate, deck: huntDeck, withMistake: true)
            let wrong = try! XCTUnwrap(round.wrongForm)
            XCTAssertFalse(yoForms.contains(wrong))
            XCTAssertEqual(round.words[round.wrongRange!].joined(separator: " "), wrong)
            XCTAssertEqual(round.rightForm, "hablo")
        }
    }

    func testPunctuationStaysAroundTheChangedVerb() {
        let candidate = ErrorHunt.candidate(in: example("¿Tú has comido?"), deck: huntDeck)!
        let round = ErrorHunt.round(from: candidate, deck: huntDeck, withMistake: true)
        XCTAssertEqual(round.words.first, "¿Tú")
        XCTAssertTrue(round.words.last?.hasSuffix("?") == true)
        XCTAssertNotEqual(round.words.joined(separator: " "), "¿Tú has comido?")
    }

    func testARightSentenceIsShownAsItIs() {
        let candidate = ErrorHunt.candidate(in: example("Ellos son de Roma."), deck: huntDeck)!
        let round = ErrorHunt.round(from: candidate, deck: huntDeck, withMistake: false)
        XCTAssertTrue(round.isCorrect)
        XCTAssertEqual(round.words.joined(separator: " "), "Ellos son de Roma.")
    }

    func testFinishedLessonsGiveSentencesToHunt() {
        let store = AppStore(storage: InMemoryProgressStorage())
        store.completeOnboarding(profile)
        store.completeUnit("u2")
        let deck = VerbDeck(completed: store.state.completedLessons, words: store.learnedWords)
        XCTAssertGreaterThanOrEqual(ErrorHunt.rounds(from: store.huntSentences, deck: deck).count, 10)
    }

    // MARK: Dilo en español

    private func word(_ es: String, _ en: String) -> VocabWord {
        VocabWord(es: es, gloss: Gloss(en: en, it: en, uk: en), kind: .chunk)
    }

    func testEveryRightSpanishWordCounts() {
        let cards = VoiceRecall.cards(from: [word("ellos", "they"), word("ellas", "they (all women)"), word("él / ella", "he / she")],
                                      language: .english)
        let they = cards.first { $0.prompt == "they" }
        XCTAssertEqual(they?.answers, ["ellos", "ellas"])
        XCTAssertTrue(VoiceRecall.matches("Ellas", card: they!))
        XCTAssertTrue(VoiceRecall.matches("ellos", card: they!))
        XCTAssertFalse(VoiceRecall.matches("nosotros", card: they!))
        XCTAssertEqual(cards.first { $0.prompt == "he / she" }?.answers, ["él", "ella"])
    }

    func testAccentsAndArticlesAreForgiven() {
        let card = VoiceRecall.cards(from: [word("el café", "coffee"), word("tú", "you")], language: .english)
        XCTAssertTrue(VoiceRecall.matches("cafe", card: card[0]))
        XCTAssertTrue(VoiceRecall.matches("el café", card: card[0]))
        XCTAssertTrue(VoiceRecall.matches("tu", card: card[1]))
        XCTAssertFalse(VoiceRecall.matches("cafetería", card: card[0]))
    }

    func testWordsSpeltTheSameAreLeftOut() {
        XCTAssertTrue(VoiceRecall.cards(from: [word("pizza", "pizza")], language: .english).isEmpty)
    }

    func testARoundUsesOnlyLearnedWords() {
        let store = AppStore(storage: InMemoryProgressStorage())
        store.completeOnboarding(profile)
        store.completeLesson("u1l1", xp: 0)
        let cards = VoiceRecall.cards(from: store.learnedWords, language: .english)
        XCTAssertFalse(cards.isEmpty)
        let taught = Set(store.learnedWords.flatMap { VoiceRecall.variants(of: $0.es) })
        for card in VoiceRecall.round(from: cards) {
            XCTAssertTrue(card.answers.allSatisfy(taught.contains), card.prompt)
        }
        XCTAssertLessThanOrEqual(VoiceRecall.round(from: cards).count, VoiceRecall.rounds)
    }

    // MARK: Parejas de palabras

    func testEveryWordPairHasOnlyOnePartner() {
        let words = [word("ellos", "they"), word("ellas", "they (all women)"), word("no", "no"), word("no", "not"),
                     word("sí", "yes"), word("agua", "water"), word("té", "tea"), word("hola", "hello")]
        let cards = VoiceRecall.cards(from: words, language: .english)
        for _ in 0..<20 {
            for round in WordMatch.rounds(from: cards) {
                let spanish = round.flatMap { $0.answers.map(VoiceRecall.simplified) }
                XCTAssertEqual(Set(spanish).count, spanish.count)
                XCTAssertLessThanOrEqual(round.count, WordMatch.perRound)
            }
        }
        XCTAssertEqual(WordMatch.spanish(cards[0]), "ellos / ellas")
    }

    func testWordMatchUsesOnlyLearnedWords() {
        let store = AppStore(storage: InMemoryProgressStorage())
        store.completeOnboarding(profile)
        XCTAssertTrue(WordMatch.rounds(from: VoiceRecall.cards(from: store.learnedWords, language: .english)).isEmpty)
        store.completeLesson("u1l1", xp: 0)
        XCTAssertFalse(WordMatch.rounds(from: VoiceRecall.cards(from: store.learnedWords, language: .english)).isEmpty)
    }

    // MARK: Ordena la frase and Dictado

    private func sentence(_ es: String, accepted: [String] = []) -> PracticeSentence {
        PracticeSentence(example: example(es), accepted: accepted)
    }

    func testThePoolKeepsShortSingleSentencesOnce() {
        let pool = SentenceGames.pool([sentence("Soy Ana."), sentence("soy ana"), sentence("Hola."),
                                       sentence("Soy Ana. Soy de Roma."), sentence("Dice: «hola»."),
                                       sentence("¿Eres de Roma?")], words: 2...9)
        XCTAssertEqual(Set(pool.map(\.example.es)), ["Soy Ana.", "¿Eres de Roma?"])
    }

    func testTilesAreTheSentenceWordsInAnotherOrder() {
        let item = sentence("¿Eres de Roma?")
        for _ in 0..<20 {
            let tiles = SentenceGames.tiles(for: item)
            XCTAssertEqual(tiles.sorted(), ["Eres", "Roma", "de"].sorted())
            XCTAssertNotEqual(tiles, ["Eres", "de", "Roma"])
            XCTAssertEqual(SentenceGames.grade(["Eres", "de", "Roma"].joined(separator: " "), item), .correct)
        }
    }

    func testDictationForgivesAccentsAndAcceptsEveryVariant() {
        let item = sentence("Tú eres de Roma.", accepted: ["Eres de Roma."])
        XCTAssertEqual(SentenceGames.grade("tu eres de roma", item), .accent(expected: "Tú eres de Roma."))
        XCTAssertEqual(SentenceGames.grade("Eres de Roma", item), .correct)
        XCTAssertFalse(SentenceGames.grade("Soy de Roma", item).isCorrect)
    }

    func testFinishedLessonsGiveSentencesToOrder() {
        let store = AppStore(storage: InMemoryProgressStorage())
        store.completeOnboarding(profile)
        XCTAssertTrue(SentenceGames.pool(store.practiceSentences, words: 3...9).isEmpty)
        store.completeUnit("u2")
        let pool = SentenceGames.pool(store.practiceSentences, words: 3...9)
        XCTAssertGreaterThanOrEqual(pool.count, SentenceGames.rounds)
        XCTAssertLessThanOrEqual(SentenceGames.round(from: pool).count, SentenceGames.rounds)
    }

    // MARK: ¿Qué tiempo es? and Máquina del tiempo

    private var tenseDeck: VerbDeck {
        VerbDeck(completed: ["u1l1", "u2l1", "u2l2", "u2l3", "u14l1", "u14l4", "u15l2", "u16l5"],
                 words: words(["hablar", "comer", "tener", "ser"]))
    }

    func testEveryTenseQuestionHasOneRightTense() {
        let deck = tenseDeck
        let questions = TenseQuiz.questions(deck: deck)
        XCTAssertEqual(questions.count, TenseQuiz.rounds)
        for question in questions {
            XCTAssertTrue(question.options.contains(question.card.tense))
            XCTAssertEqual(Set(question.options).count, question.options.count)
            XCTAssertTrue(question.options.allSatisfy { deck.isOpen(question.card.verb, $0) })
            let matching = question.options.filter { tense in
                Person.allCases.contains { question.card.verb.form(tense, $0)?.text == question.card.form.text }
            }
            XCTAssertEqual(matching, [question.card.tense], question.card.form.text)
        }
    }

    func testOnlyThePresentGivesNoTenseQuestion() {
        XCTAssertTrue(TenseQuiz.questions(deck: VerbDeck(completed: ["u1l1"], words: words(["hablar"]))).isEmpty)
    }

    func testTheTimeMachineAlwaysChangesTheForm() {
        let deck = tenseDeck
        let questions = TimeMachine.questions(deck: deck)
        XCTAssertFalse(questions.isEmpty)
        XCTAssertLessThanOrEqual(questions.count, TimeMachine.rounds)
        for question in questions {
            XCTAssertNotEqual(question.to, question.from.tense)
            XCTAssertTrue(deck.isOpen(question.from.verb, question.to))
            XCTAssertNotEqual(question.answer.text, question.from.form.text)
            XCTAssertEqual(question.answer.text, question.from.verb.form(question.to, question.from.person)?.text)
        }
    }

    func testEveryLabGameHasAScreenAndAKind() {
        let ids = LabGame.built.map(\.id)
        XCTAssertEqual(Set(ids).count, ids.count)
        XCTAssertEqual(LabGame.built.count, 9)
        for kind in LabGame.Kind.allCases {
            XCTAssertFalse(LabGame.built.filter { $0.kind == kind }.isEmpty)
        }
        let path = Set(Curriculum.sharedPath.map(\.id))
        for game in LabGame.built {
            XCTAssertTrue(path.contains(game.unlockedBy), game.id)
        }
    }

    func testBestScoresAreKept() {
        let store = AppStore(storage: InMemoryProgressStorage())
        XCTAssertTrue(store.recordScore(12, in: LabGame.sprintId))
        XCTAssertFalse(store.recordScore(8, in: LabGame.sprintId))
        XCTAssertEqual(store.best(in: LabGame.sprintId), 12)
        XCTAssertEqual(store.best(in: LabGame.huntId), 0)
    }
}
