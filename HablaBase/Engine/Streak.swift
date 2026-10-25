import Foundation

/// Days in a row with some study: a finished lesson, test or review, or a Lab game with points.
/// Missing a day only starts the count again; nothing is ever locked or lost.
enum Streak {
    /// How many study days are kept, for the week row and to rebuild older streaks.
    static let keptDays = 60

    /// The calendar day of a date as "2026-10-25", in the phone's time zone.
    static func dayKey(_ date: Date, calendar: Calendar = .current) -> String {
        let parts = calendar.dateComponents([.year, .month, .day], from: date)
        return String(format: "%04d-%02d-%02d", parts.year ?? 0, parts.month ?? 0, parts.day ?? 0)
    }

    static func date(fromKey key: String, calendar: Calendar = .current) -> Date? {
        let parts = key.split(separator: "-").compactMap { Int($0) }
        guard parts.count == 3 else { return nil }
        return calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2]))
    }

    static func key(daysBefore days: Int, _ date: Date, calendar: Calendar = .current) -> String {
        dayKey(calendar.date(byAdding: .day, value: -days, to: date) ?? date, calendar: calendar)
    }

    /// The streak as it stands today: the saved count while the last study day is today or
    /// yesterday, zero once a whole day has gone by without study.
    static func current(_ state: SavedState, today: Date = .now, calendar: Calendar = .current) -> Int {
        guard let last = state.lastPracticeDay else { return 0 }
        if last == dayKey(today, calendar: calendar) || last == key(daysBefore: 1, today, calendar: calendar) {
            return state.streak
        }
        return 0
    }

    static func studiedToday(_ state: SavedState, today: Date = .now, calendar: Calendar = .current) -> Bool {
        state.lastPracticeDay == dayKey(today, calendar: calendar)
    }

    /// Counts today as a study day. Studying twice in one day changes nothing.
    static func record(_ state: inout SavedState, today: Date = .now, calendar: Calendar = .current) {
        let todayKey = dayKey(today, calendar: calendar)
        guard state.lastPracticeDay != todayKey else { return }
        if state.lastPracticeDay == key(daysBefore: 1, today, calendar: calendar) {
            state.streak += 1
        } else {
            state.streak = 1
        }
        state.lastPracticeDay = todayKey
        state.bestStreak = max(state.bestStreak, state.streak)
        state.practiceDays.insert(todayKey)
        if state.practiceDays.count > keptDays {
            // Day keys sort like dates, so the oldest ones go first.
            state.practiceDays = Set(state.practiceDays.sorted().suffix(keptDays))
        }
    }

    /// The last seven days, oldest first, ending today.
    static func week(_ state: SavedState, today: Date = .now, calendar: Calendar = .current) -> [StudyDay] {
        (0..<7).reversed().map { offset in
            let date = calendar.date(byAdding: .day, value: -offset, to: today) ?? today
            let key = dayKey(date, calendar: calendar)
            return StudyDay(date: date, key: key, studied: state.practiceDays.contains(key), isToday: offset == 0)
        }
    }

    /// The days of a streak saved before study days were kept, so the week row shows it too.
    static func rebuiltDays(streak: Int, lastDay: String?, calendar: Calendar = .current) -> Set<String> {
        guard let lastDay, streak > 0, let last = date(fromKey: lastDay, calendar: calendar) else { return [] }
        return Set((0..<min(streak, keptDays)).map { key(daysBefore: $0, last, calendar: calendar) })
    }
}

struct StudyDay: Hashable, Identifiable {
    let date: Date
    let key: String
    let studied: Bool
    let isToday: Bool

    var id: String { key }
}
