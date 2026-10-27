import Foundation
import SwiftUI

/// Everything the app remembers about the learner, saved on the phone after every change.
struct SavedState: Codable, Equatable {
    static let maxEnergy = 5

    var profile: Profile?
    var xp = 0
    /// Days in a row with study, as of `lastPracticeDay`; `Streak.current` says if it still holds.
    var streak = 0
    var lastPracticeDay: String?
    var bestStreak = 0
    /// The recent days with study, as day keys ("2026-10-25"), for the week row.
    var practiceDays: Set<String> = []
    /// The daily reminder the learner turned on in Profile; nil when it is off.
    var reminder: StudyReminder?
    var energy = SavedState.maxEnergy
    /// The day energy was last refilled; it fills up again every new day.
    var energyDay: String?
    /// Every finished path step: lessons, bosses, unit tests and checkpoints.
    var completedLessons: Set<String> = []
    /// Mastery 0...5 per verb x tense x person cell (the verb SRS).
    var mastery: [FormKey: Int] = [:]
    var sentencesBuilt = 0
    /// The best score in each Lab game, by game id.
    var gameBests: [String: Int] = [:]
    /// The learner's favourites folder from "Palabras al azar", newest first.
    var favoriteWords: [FeedWord] = []

    init() {}

    /// Every field is optional on disk, so progress saved by an older version still loads
    /// after an update adds new fields.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        profile = try c.decodeIfPresent(Profile.self, forKey: .profile)
        xp = try c.decodeIfPresent(Int.self, forKey: .xp) ?? 0
        streak = try c.decodeIfPresent(Int.self, forKey: .streak) ?? 0
        lastPracticeDay = try c.decodeIfPresent(String.self, forKey: .lastPracticeDay)
        bestStreak = try c.decodeIfPresent(Int.self, forKey: .bestStreak) ?? streak
        practiceDays = try c.decodeIfPresent(Set<String>.self, forKey: .practiceDays)
            ?? Streak.rebuiltDays(streak: streak, lastDay: lastPracticeDay)
        reminder = try c.decodeIfPresent(StudyReminder.self, forKey: .reminder)
        energy = try c.decodeIfPresent(Int.self, forKey: .energy) ?? SavedState.maxEnergy
        energyDay = try c.decodeIfPresent(String.self, forKey: .energyDay)
        completedLessons = try c.decodeIfPresent(Set<String>.self, forKey: .completedLessons) ?? []
        mastery = try c.decodeIfPresent([FormKey: Int].self, forKey: .mastery) ?? [:]
        sentencesBuilt = try c.decodeIfPresent(Int.self, forKey: .sentencesBuilt) ?? 0
        gameBests = try c.decodeIfPresent([String: Int].self, forKey: .gameBests) ?? [:]
        favoriteWords = try c.decodeIfPresent([FeedWord].self, forKey: .favoriteWords) ?? []
    }
}

@MainActor
final class AppStore: ObservableObject {
    private let storage: ProgressStorage
    private let reminders: ReminderScheduling

    @Published private(set) var state: SavedState {
        didSet { storage.save(state) }
    }

    init(storage: ProgressStorage = FileProgressStorage(), reminders: ReminderScheduling = NotificationReminders()) {
        self.storage = storage
        self.reminders = reminders
        state = storage.load() ?? SavedState()
        refillEnergyIfNewDay()
        if state.reminder != nil { planReminders() }
    }

    var profile: Profile? { state.profile }
    var language: NativeLanguage { state.profile?.nativeLanguage ?? .english }

    func completeOnboarding(_ profile: Profile) {
        state.profile = profile
    }

    func updateProfile(_ profile: Profile) {
        let languageOrTimeChanged = profile.nativeLanguage != state.profile?.nativeLanguage
            || profile.dailyMinutes != state.profile?.dailyMinutes
        state.profile = profile
        // The reminders speak the learner's language and mention their daily minutes.
        if languageOrTimeChanged && state.reminder != nil { planReminders() }
    }

    func reset() {
        state = SavedState()
        planReminders()
    }

    // MARK: Streak and reminder

    /// Days in a row with study, counting today or yesterday; zero after a day without study.
    var currentStreak: Int { Streak.current(state) }

    var studiedToday: Bool { Streak.studiedToday(state) }

    /// The last seven days for the week row, oldest first.
    var studyWeek: [StudyDay] { Streak.week(state) }

    /// Counts today as a study day and moves today's reminder out of the way.
    func recordStudyDay(today: Date = .now) {
        let wasStudied = state.lastPracticeDay == Streak.dayKey(today)
        Streak.record(&state, today: today)
        if !wasStudied && state.reminder != nil { planReminders(now: today) }
    }

    /// Turns the daily reminder on at this time, or off with nil. Ask for permission first.
    func setReminder(_ reminder: StudyReminder?) {
        state.reminder = reminder
        planReminders()
    }

    /// Plans the next two weeks of reminders again: call it when the app comes back, since the
    /// day, the streak or the language may have changed.
    func planReminders(now: Date = .now) {
        guard let reminder = state.reminder, let profile = state.profile else {
            reminders.replace(with: [])
            return
        }
        let studied = Streak.studiedToday(state, today: now)
        let dates = reminder.fireDates(from: now, studiedToday: studied)
        let messages = StudyReminder.messages(count: dates.count, streak: Streak.current(state, today: now),
                                              minutes: profile.dailyMinutes, language: profile.nativeLanguage)
        reminders.replace(with: zip(dates, messages).map { PlannedReminder(date: $0, message: $1) })
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

    /// Finished lessons and bosses, in path order.
    private var finishedLessons: [Lesson] {
        guard let profile else { return [] }
        return Curriculum.sharedPath
            .filter { ($0.kind == .lesson || $0.kind == .boss) && isCompleted($0.id) }
            .compactMap { LessonContent.lesson(id: $0.id, profile: profile) }
    }

    /// The words of every finished lesson: the Lab games only use the verbs among them.
    var learnedWords: [VocabWord] {
        finishedLessons.flatMap(\.vocabulary)
    }

    /// Every Spanish sentence of the finished lessons with its translation and every accepted way
    /// to say it, for the sentence games of the Lab.
    var practiceSentences: [PracticeSentence] {
        finishedLessons.flatMap(\.practiceSentences)
    }

    /// The sentences of the finished lessons, for "Caza de errores".
    var huntSentences: [Example] {
        practiceSentences.map(\.example)
    }

    // MARK: Lab games

    func best(in game: String) -> Int {
        state.gameBests[game] ?? 0
    }

    /// Keeps the score if it beats the record. True when it is a new record.
    @discardableResult
    func recordScore(_ score: Int, in game: String) -> Bool {
        // A Lab game with points is study too: it counts for the streak.
        if score > 0 { recordStudyDay() }
        guard score > best(in: game) else { return false }
        state.gameBests[game] = score
        return true
    }

    /// For races, where less is better: keeps the time in seconds if it beats the record.
    /// A finished race is study too. True when it is a new record.
    @discardableResult
    func recordTime(_ seconds: Int, in game: String) -> Bool {
        guard seconds > 0 else { return false }
        recordStudyDay()
        let record = best(in: game)
        guard record == 0 || seconds < record else { return false }
        state.gameBests[game] = seconds
        return true
    }

    // MARK: Favourite words

    var favoriteWords: [FeedWord] { state.favoriteWords }

    func isFavorite(_ word: FeedWord) -> Bool {
        state.favoriteWords.contains { $0.id == word.id }
    }

    /// Saves the word at the top of the favourites folder, or takes it out if it is already there.
    func toggleFavorite(_ word: FeedWord) {
        if isFavorite(word) {
            state.favoriteWords.removeAll { $0.id == word.id }
        } else {
            state.favoriteWords.insert(word, at: 0)
        }
    }

    func removeFavorites(at offsets: IndexSet) {
        state.favoriteWords.remove(atOffsets: offsets)
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
        recordStudyDay()
    }

    /// A passed unit test skips the unit: every step up to the end of that unit counts as done.
    func completeUnit(_ unitId: String) {
        let path = Curriculum.sharedPath
        guard let last = path.lastIndex(where: { $0.unitId == unitId }) else { return }
        for node in path[...last] {
            state.completedLessons.insert(node.id)
        }
        recordStudyDay()
    }

    func mastery(of key: FormKey) -> Int {
        state.mastery[key] ?? 0
    }

    private static func dayKey(_ date: Date) -> String {
        Streak.dayKey(date)
    }
}

/// One unit's notes: the explanations and words of the lessons reached so far.
struct UnitNotes: Identifiable {
    let unit: CurriculumUnit
    let lessons: [Lesson]

    var id: String { unit.id }
}
