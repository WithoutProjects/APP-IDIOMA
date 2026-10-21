import Foundation
import SwiftUI

/// Everything the app remembers about the learner, saved on the phone after every change.
struct SavedState: Codable, Equatable {
    static let maxEnergy = 5

    var profile: Profile?
    var xp = 0
    var streak = 0
    var lastPracticeDay: String?
    var energy = SavedState.maxEnergy
    /// The day energy was last refilled; it fills up again every new day.
    var energyDay: String?
    /// Every finished path step: lessons, bosses, unit tests and checkpoints.
    var completedLessons: Set<String> = []
    /// Mastery 0...5 per verb x tense x person cell (the verb SRS).
    var mastery: [FormKey: Int] = [:]
    var sentencesBuilt = 0
    /// Reward chests on the path that the learner has already opened.
    var openedChests: Set<String> = []

    init() {}

    /// Every field is optional on disk, so progress saved by an older version still loads
    /// after an update adds new fields.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        profile = try c.decodeIfPresent(Profile.self, forKey: .profile)
        xp = try c.decodeIfPresent(Int.self, forKey: .xp) ?? 0
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        lastPracticeDay = try c.decodeIfPresent(String.self, forKey: .lastPracticeDay)
        energy = try c.decodeIfPresent(Int.self, forKey: .energy) ?? SavedState.maxEnergy
        energyDay = try c.decodeIfPresent(String.self, forKey: .energyDay)
        completedLessons = try c.decodeIfPresent(Set<String>.self, forKey: .completedLessons) ?? []
        mastery = try c.decodeIfPresent([FormKey: Int].self, forKey: .mastery) ?? [:]
        sentencesBuilt = try c.decodeIfPresent(Int.self, forKey: .sentencesBuilt) ?? 0
        openedChests = try c.decodeIfPresent(Set<String>.self, forKey: .openedChests) ?? []
    }
}

@MainActor
final class AppStore: ObservableObject {
    private let storage: ProgressStorage

    @Published private(set) var state: SavedState {
        didSet { storage.save(state) }
    }

    init(storage: ProgressStorage = FileProgressStorage()) {
        self.storage = storage
        state = storage.load() ?? SavedState()
        refillEnergyIfNewDay()
    }

    var profile: Profile? { state.profile }
    var language: NativeLanguage { state.profile?.nativeLanguage ?? .english }

    func completeOnboarding(_ profile: Profile) {
        state.profile = profile
    }

    func updateProfile(_ profile: Profile) {
        state.profile = profile
    }

    func reset() {
        state = SavedState()
    }

    // MARK: Path

    func isCompleted(_ lessonId: String) -> Bool {
        state.completedLessons.contains(lessonId)
    }

    /// The first node on the path that is not finished yet.
    var nextNode: PathNode? {
        Curriculum.sharedPath.first { !isCompleted($0.id) }
    }

    /// The exercises for a path step, if they exist in the app yet.
    func playableLesson(_ id: String) -> Lesson? {
        profile.flatMap { LessonContent.lesson(id: id, profile: $0) }
    }

    /// Words met in finished lessons plus the ones this lesson introduces, for tap-to-translate.
    func glossary(including lesson: Lesson? = nil) -> Glossary {
        var words: [VocabWord] = (lesson?.vocabulary ?? []) + (lesson?.taughtForms ?? [])
        if let profile {
            for node in Curriculum.sharedPath where isCompleted(node.id) && node.kind == .lesson {
                if let done = LessonContent.lesson(id: node.id, profile: profile) {
                    words += done.vocabulary + done.taughtForms
                }
            }
        }
        return Glossary(words: words)
    }

    /// Notes for every unit the learner has reached, current unit first: the lessons they
    /// have finished or are on now, with their explanations and vocabulary.
    var notes: [UnitNotes] {
        guard let profile else { return [] }
        let current = nextNode?.id
        var result: [UnitNotes] = []
        for level in Curriculum.shared.levels {
            for unit in level.units {
                let lessons = unit.lessons
                    .filter { isCompleted($0.id) || $0.id == current }
                    .compactMap { LessonContent.lesson(id: $0.id, profile: profile) }
                if !lessons.isEmpty { result.append(UnitNotes(unit: unit, lessons: lessons)) }
            }
        }
        return result.reversed()
    }

    /// Sentences to say aloud: only from finished lessons, so every word has been introduced.
    var speakingSentences: [Example] {
        guard let profile else { return [] }
        var sentences: [Example] = []
        for node in Curriculum.sharedPath where isCompleted(node.id) {
            guard let lesson = LessonContent.lesson(id: node.id, profile: profile), case .lesson = lesson.mode else { continue }
            if let target = lesson.target { sentences.append(target) }
            for item in lesson.items {
                switch item.kind {
                case .frame(let card): sentences += card.examples
                case .builder(let builder): sentences.append(builder.model)
                case .freeWrite(let write): sentences.append(write.model)
                default: break
                }
            }
        }
        var seen: Set<String> = []
        return sentences.filter { seen.insert($0.es).inserted }
    }

    // MARK: Practice events

    func addXP(_ amount: Int) {
        state.xp += amount
    }

    func recordForms(_ keys: [FormKey], correct: Bool) {
        for key in keys {
            let current = state.mastery[key] ?? 0
            state.mastery[key] = correct ? min(5, current + 1) : max(0, current - 1)
        }
    }

    func recordSentenceBuilt() {
        state.sentencesBuilt += 1
    }

    /// Energy never blocks a lesson. It shows how a session is going and fills up every day.
    func spendEnergy() {
        refillEnergyIfNewDay()
        state.energy = max(0, state.energy - 1)
    }

    func refillEnergyIfNewDay(today: Date = .now) {
        let todayKey = Self.dayKey(today)
        guard state.energyDay != todayKey else { return }
        state.energy = SavedState.maxEnergy
        state.energyDay = todayKey
    }

    /// Forms the learner has missed and not yet mastered, weakest first.
    var weakForms: [FormKey] {
        state.mastery.filter { $0.value < 3 }.sorted { $0.value < $1.value }.map(\.key)
    }

    /// Fixing a mistake earns a bolt back: errors are the path back, not a punishment.
    func restoreEnergy() {
        state.energy = min(SavedState.maxEnergy, state.energy + 1)
    }

    func completeLesson(_ lessonId: String, xp: Int) {
        state.completedLessons.insert(lessonId)
        state.xp += xp
        touchStreak()
    }

    /// A passed unit test skips the unit: every step up to the end of that unit counts as done.
    func completeUnit(_ unitId: String) {
        let path = Curriculum.sharedPath
        guard let last = path.lastIndex(where: { $0.unitId == unitId }) else { return }
        for node in path[...last] {
            state.completedLessons.insert(node.id)
        }
        touchStreak()
    }

    // MARK: Chests

    static let chestXP = 20

    func isChestOpen(_ chestId: String) -> Bool {
        state.openedChests.contains(chestId)
    }

    /// A chest halfway through a unit gives bonus XP once.
    func openChest(_ chestId: String) {
        guard !isChestOpen(chestId) else { return }
        state.openedChests.insert(chestId)
        state.xp += Self.chestXP
    }

    func mastery(of key: FormKey) -> Int {
        state.mastery[key] ?? 0
    }

    /// A streak day needs the daily minimum (one lesson for now).
    private func touchStreak(today: Date = .now) {
        let calendar = Calendar.current
        let todayKey = Self.dayKey(today)
        guard state.lastPracticeDay != todayKey else { return }
        if let last = state.lastPracticeDay,
           let yesterday = calendar.date(byAdding: .day, value: -1, to: today),
           last == Self.dayKey(yesterday) {
            state.streak += 1
        } else {
            state.streak = 1
        }
        state.lastPracticeDay = todayKey
    }

    private static func dayKey(_ date: Date) -> String {
        let parts = Calendar.current.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }
}

/// One unit's notes: the explanations and words of the lessons reached so far.
struct UnitNotes: Identifiable {
    let unit: CurriculumUnit
    let lessons: [Lesson]

    var id: String { unit.id }
}
