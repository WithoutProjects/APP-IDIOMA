import Foundation
import SwiftUI

/// Everything the app remembers about the learner. Saved to UserDefaults as JSON;
/// moves to SQLite with a sync queue once there is a backend.
struct SavedState: Codable, Equatable {
    static let maxEnergy = 5

    var profile: Profile?
    var xp = 0
    var streak = 0
    var lastPracticeDay: String?
    var energy = SavedState.maxEnergy
    var completedLessons: Set<String> = []
    /// Mastery 0...5 per verb x tense x person cell.
    var mastery: [FormKey: Int] = [:]
    var sentencesBuilt = 0
}

@MainActor
final class AppStore: ObservableObject {
    private static let storageKey = "hablabase.state.v1"

    @Published private(set) var state: SavedState {
        didSet { save() }
    }

    init() {
        if let data = UserDefaults.standard.data(forKey: Self.storageKey),
           let saved = try? JSONDecoder().decode(SavedState.self, from: data) {
            state = saved
        } else {
            state = SavedState()
        }
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
        Unit1.path.first { !isCompleted($0.id) }
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

    func spendEnergy() {
        state.energy = max(0, state.energy - 1)
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

    private func save() {
        if let data = try? JSONEncoder().encode(state) {
            UserDefaults.standard.set(data, forKey: Self.storageKey)
        }
    }
}
