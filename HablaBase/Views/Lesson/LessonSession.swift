import Foundation

/// Runs one lesson or unit test: the item queue, grading, the Fix replay of mistakes and XP.
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

    init(lesson: Lesson) {
        self.lesson = lesson
        self.queue = lesson.items
    }

    var current: LessonItem? { index < queue.count ? queue[index] : nil }
    var isFinished: Bool { index >= queue.count }
    var progress: Double { Double(index) / Double(max(queue.count, 1)) }
    var hadMistakes: Bool { correct < answered }

    var isTest: Bool {
        if case .unitTest = lesson.mode { return true }
        return false
    }

    var passedTest: Bool { correct >= Lesson.testPassMark }

    private var questionsQueued: Int { queue.filter { $0.kind.isQuestion }.count }

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
            xpEarned += 3
            switch item.kind {
            case .builder, .freeWrite: store.recordSentenceBuilt()
            default: break
            }
            if isReplay { store.restoreEnergy() }
        } else if !isTest {
            if item.heartsAtRisk { store.spendEnergy() }
            // Fix: a mistake comes back once at the end, as long as the block stays within 15 questions.
            if !isReplay && questionsQueued < Lesson.maxQuestions {
                queue.append(LessonItem(id: item.id + "-fix", beat: .fix, kind: item.kind,
                                        heartsAtRisk: item.heartsAtRisk, formKeys: item.formKeys))
            }
        }
        feedback = Feedback(outcome: outcome, model: Self.model(for: item.kind))
    }

    func advance() {
        feedback = nil
        index += 1
    }

    /// Lesson finished: 10 XP, +5 for a clean run. A passed test is worth a boss win.
    var completionXP: Int {
        if isTest { return passedTest ? 50 : xpEarned }
        return xpEarned + 10 + (hadMistakes ? 0 : 5)
    }

    private static func model(for kind: ItemKind) -> Example? {
        switch kind {
        case .frame: return nil
        case .legoSnap(let snap): return Example(es: snap.answer.text, gloss: snap.prompt)
        case .gapFill(let gap): return Example(es: gap.sentence, gloss: gap.gloss)
        case .builder(let builder): return builder.model
        case .freeWrite(let write): return write.model
        }
    }
}
