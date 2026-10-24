import Foundation

/// Runs one lesson, unit test or review: the item queue, grading, hints, the Fix replay of
/// mistakes, the quick review when someone gets stuck, and XP.
@MainActor
final class LessonSession: ObservableObject {
    struct Feedback {
        let outcome: GradeOutcome
        let model: Example?
    }

    let lesson: Lesson
    @Published private(set) var queue: [LessonItem]
    @Published private(set) var index = 0
    @Published private(set) var feedback: Feedback?

    private(set) var xpEarned = 0
    private(set) var answered = 0
    private(set) var correct = 0
    /// Sentences said right in this lesson, for "Now you can say…".
    private(set) var saidSentences: [Example] = []

    /// Queue positions where a hint was used: a right answer there earns less XP.
    private var hinted: Set<Int> = []
    /// The explanation behind the last miss, to spot two misses in a row on the same point.
    private var lastMissPoint: Int?
    private var reviewedPoints: Set<Int> = []

    init(lesson: Lesson) {
        self.lesson = lesson
        self.queue = lesson.items
    }

    var current: LessonItem? { index < queue.count ? queue[index] : nil }
    var isFinished: Bool { index >= queue.count }
    var progress: Double { Double(index) / Double(max(queue.count, 1)) }
    var hadMistakes: Bool { correct < answered }

    var isTest: Bool {
        switch lesson.mode {
        case .unitTest, .checkpoint: return true
        case .lesson, .review: return false
        }
    }

    var isReview: Bool {
        if case .review = lesson.mode { return true }
        return false
    }

    var passedTest: Bool { correct >= Lesson.testPassMark }

    private var questionsQueued: Int { queue.filter { $0.kind.isQuestion }.count }

    /// The explanation behind the current exercise, for the "See explanation" button.
    var currentExplanation: FrameCard? {
        guard !isTest, let item = current, item.kind.isQuestion else { return nil }
        return lesson.explanation(for: item)
    }

    /// Hints never cost energy; they only lower the XP for that answer.
    func useHint() {
        hinted.insert(index)
    }

    /// Grades the current item and shows feedback. Explanations skip feedback.
    func submit(_ outcome: GradeOutcome, store: AppStore) {
        guard let item = current else { return }
        guard item.kind.isQuestion else {
            advance()
            return
        }

        answered += 1
        let isReplay = item.id.hasSuffix("-fix")
        store.recordForms(item.formKeys, correct: outcome.isCorrect)

        if outcome.isCorrect {
            correct += 1
            xpEarned += hinted.contains(index) ? 1 : 3
            lastMissPoint = nil
            switch item.kind {
            case .builder, .freeWrite: store.recordSentenceBuilt()
            default: break
            }
            if let sentence = Self.sentence(for: item.kind), !saidSentences.contains(where: { $0.es == sentence.es }) {
                saidSentences.append(sentence)
            }
            if isReplay || isReview { store.restoreEnergy() }
        } else if !isTest {
            if item.heartsAtRisk && !isReview { store.spendEnergy() }
            // Fix: a mistake comes back once at the end, as long as the block stays within 15 questions.
            if !isReplay && questionsQueued < Lesson.maxQuestions {
                queue.append(LessonItem(id: item.id + "-fix", beat: .fix, kind: item.kind,
                                        heartsAtRisk: item.heartsAtRisk, formKeys: item.formKeys))
            }
            insertReviewIfStuck(after: item)
        }
        feedback = Feedback(outcome: outcome, model: Self.model(for: item.kind))
    }

    /// Two misses in a row on the same point: the rule in one line with one worked example,
    /// then an easier twin question. Once per point, and free.
    private func insertReviewIfStuck(after item: LessonItem) {
        guard let point = lesson.explanationIndex(for: item) else { return }
        defer { lastMissPoint = point }
        guard lastMissPoint == point, !reviewedPoints.contains(point),
              case .frame(let card) = lesson.items[point].kind else { return }
        reviewedPoints.insert(point)

        let short = FrameCard(bricks: card.bricks, result: card.result, rule: card.rule,
                              examples: Array(card.examples.prefix(1)))
        var review = [LessonItem(id: "review-\(point)", beat: .review, kind: .frame(short),
                                 heartsAtRisk: false, formKeys: [])]
        if questionsQueued < Lesson.maxQuestions, let key = item.formKeys.first,
           let twin = Unit1.easyTwin(of: key, id: "\(item.id)-twin") {
            review.append(twin)
        }
        queue.insert(contentsOf: review, at: index + 1)
    }

    func advance() {
        feedback = nil
        index += 1
    }

    /// Lesson finished: 10 XP, +5 for a clean run. A passed test is worth a boss win.
    var completionXP: Int {
        if isTest { return passedTest ? 50 : xpEarned }
        if isReview { return xpEarned }
        return xpEarned + 10 + (hadMistakes ? 0 : 5)
    }

    /// Whole sentences only: a snapped verb form on its own is not something you "can say".
    private static func sentence(for kind: ItemKind) -> Example? {
        switch kind {
        case .gapFill, .choice, .builder, .freeWrite: return model(for: kind)
        default: return nil
        }
    }

    private static func model(for kind: ItemKind) -> Example? {
        switch kind {
        case .slides, .match, .frame: return nil
        case .legoSnap(let snap): return Example(es: snap.answer.text, gloss: snap.prompt)
        case .gapFill(let gap): return Example(es: gap.sentence, gloss: gap.gloss)
        case .choice(let choice): return Example(es: choice.sentence, gloss: choice.gloss)
        case .builder(let builder): return builder.model
        case .freeWrite(let write): return write.model
        }
    }
}
