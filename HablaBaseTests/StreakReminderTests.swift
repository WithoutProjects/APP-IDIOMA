import XCTest
@testable import HablaBase

final class StreakTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return calendar
    }

    private func day(_ d: Int, hour: Int = 12, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: d, hour: hour, minute: minute))!
    }

    func testDaysInARowCount() {
        var state = SavedState()
        Streak.record(&state, today: day(20), calendar: calendar)
        Streak.record(&state, today: day(21), calendar: calendar)
        Streak.record(&state, today: day(21, hour: 22), calendar: calendar)
        Streak.record(&state, today: day(22), calendar: calendar)
        XCTAssertEqual(state.streak, 3, "studying twice in a day counts once")
        XCTAssertEqual(Streak.current(state, today: day(22), calendar: calendar), 3)
        XCTAssertEqual(state.bestStreak, 3)
    }

    func testTheStreakHoldsUntilAWholeDayIsMissed() {
        var state = SavedState()
        Streak.record(&state, today: day(20), calendar: calendar)
        Streak.record(&state, today: day(21), calendar: calendar)
        XCTAssertEqual(Streak.current(state, today: day(22, hour: 23), calendar: calendar), 2, "today is not over yet")
        XCTAssertEqual(Streak.current(state, today: day(23), calendar: calendar), 0)
    }

    func testAMissedDayStartsAgainAndKeepsTheBest() {
        var state = SavedState()
        for d in 10...14 { Streak.record(&state, today: day(d), calendar: calendar) }
        Streak.record(&state, today: day(20), calendar: calendar)
        XCTAssertEqual(state.streak, 1)
        XCTAssertEqual(state.bestStreak, 5)
    }

    func testTheWeekShowsTheLastSevenDays() {
        var state = SavedState()
        Streak.record(&state, today: day(20), calendar: calendar)
        Streak.record(&state, today: day(22), calendar: calendar)
        let week = Streak.week(state, today: day(22), calendar: calendar)
        XCTAssertEqual(week.map(\.key), (16...22).map { "2026-10-\($0)" })
        XCTAssertEqual(week.map(\.studied), [false, false, false, false, true, false, true])
        XCTAssertEqual(week.last?.isToday, true)
    }

    func testOnlyRecentDaysAreKept() {
        var state = SavedState()
        let start = day(1)
        for offset in 0..<(Streak.keptDays + 10) {
            Streak.record(&state, today: calendar.date(byAdding: .day, value: offset, to: start)!, calendar: calendar)
        }
        XCTAssertEqual(state.practiceDays.count, Streak.keptDays)
        XCTAssertFalse(state.practiceDays.contains("2026-10-01"))
    }

    func testAStreakSavedByAnOlderVersionShowsInTheWeek() throws {
        let old = #"{"streak": 3, "lastPracticeDay": "2026-10-22"}"#
        let state = try JSONDecoder().decode(SavedState.self, from: Data(old.utf8))
        XCTAssertEqual(state.bestStreak, 3)
        XCTAssertEqual(state.practiceDays, ["2026-10-20", "2026-10-21", "2026-10-22"])
        XCTAssertNil(state.reminder)
    }

    func testStreakAndReminderSurviveSaving() throws {
        var state = SavedState()
        Streak.record(&state, today: day(20), calendar: calendar)
        state.reminder = StudyReminder(hour: 8, minute: 30)
        let loaded = try JSONDecoder().decode(SavedState.self, from: JSONEncoder().encode(state))
        XCTAssertEqual(loaded, state)
    }
}

final class StudyReminderTests: XCTestCase {
    private var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Madrid")!
        return calendar
    }

    private func day(_ d: Int, hour: Int = 12, minute: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: 10, day: d, hour: hour, minute: minute))!
    }

    func testTodayIsIncludedWhenTheTimeHasNotPassed() {
        let reminder = StudyReminder(hour: 19, minute: 0)
        let dates = reminder.fireDates(from: day(20, hour: 9), studiedToday: false, calendar: calendar)
        XCTAssertEqual(dates.count, StudyReminder.plannedDays)
        XCTAssertEqual(dates.first, day(20, hour: 19))
        XCTAssertEqual(dates[1], day(21, hour: 19))
    }

    func testNoReminderOnADayAlreadyStudied() {
        let reminder = StudyReminder(hour: 19, minute: 0)
        let dates = reminder.fireDates(from: day(20, hour: 9), studiedToday: true, calendar: calendar)
        XCTAssertEqual(dates.first, day(21, hour: 19))
        XCTAssertEqual(dates.count, StudyReminder.plannedDays)
    }

    func testAPassedTimeStartsTomorrow() {
        let reminder = StudyReminder(hour: 8, minute: 15)
        let dates = reminder.fireDates(from: day(20, hour: 9), studiedToday: false, calendar: calendar)
        XCTAssertEqual(dates.first, day(21, hour: 8, minute: 15))
    }

    func testTheTimeIsKeptAcrossTheClockChange() {
        // Spain moves the clocks back on 25 October 2026.
        let reminder = StudyReminder(hour: 19, minute: 0)
        let dates = reminder.fireDates(from: day(24, hour: 9), studiedToday: false, calendar: calendar)
        for date in dates.prefix(3) {
            XCTAssertEqual(calendar.component(.hour, from: date), 19)
        }
    }

    func testOnlyTheFirstReminderMentionsTheStreak() {
        let messages = StudyReminder.messages(count: 3, streak: 4, minutes: 10, language: .english)
        XCTAssertTrue(messages[0].body.hasPrefix("4 days in a row"))
        XCTAssertFalse(messages[1].body.contains("4"))
        XCTAssertTrue(messages[2].body.contains("10 minutes"))
        XCTAssertEqual(messages[0].title, "Hablo")
    }

    func testRemindersSpeakTheLearnersLanguage() {
        let messages = StudyReminder.messages(count: 1, streak: 0, minutes: 5, language: .italian)
        XCTAssertEqual(messages[0].body, "I tuoi 5 minuti di spagnolo di oggi, quando ti va.")
    }

    func testEveryReminderTextHasAllLanguagesAndNoLeftoverPlaceholders() {
        for language in NativeLanguage.allCases {
            for streak in [0, 1, 6] {
                for message in StudyReminder.messages(count: 2, streak: streak, minutes: 10, language: language) {
                    XCTAssertFalse(message.body.contains("{"), "\(language) \(message.body)")
                    XCTAssertFalse(message.body.isEmpty)
                }
            }
        }
        for gloss in [StudyReminder.fewMinutes, StudyReminder.nextLesson, StudyReminder.keepGoing, StudyReminder.keepGoingOne,
                      StreakCard.title, StreakCard.best, StreakCard.doneToday, StreakCard.keepGoing, StreakCard.start,
                      ReminderSection.header, ReminderSection.toggle, ReminderSection.time,
                      ReminderSection.explanation, ReminderSection.denied, ReminderSection.openSettings] {
            XCTAssertNotNil(gloss.de, gloss.en)
            XCTAssertNotNil(gloss.fr, gloss.en)
            XCTAssertNotNil(gloss.pt, gloss.en)
            XCTAssertNotNil(gloss.zh, gloss.en)
        }
    }

    func testTheTimePickerRoundTrips() {
        let reminder = StudyReminder(hour: 7, minute: 45)
        XCTAssertEqual(ReminderSection.reminder(at: ReminderSection.date(for: reminder)), reminder)
    }
}

@MainActor
final class StoreReminderTests: XCTestCase {
    private let profile = Profile(name: "Ana", city: "Milán", workplace: .hospital,
                                  nativeLanguage: .english, goal: .travel, dailyMinutes: 10)

    func testTurningTheReminderOnPlansTwoWeeks() {
        let reminders = InMemoryReminders()
        let store = AppStore(storage: InMemoryProgressStorage(), reminders: reminders)
        store.completeOnboarding(profile)
        store.setReminder(StudyReminder(hour: 23, minute: 59))
        XCTAssertEqual(reminders.planned.count, StudyReminder.plannedDays)
        store.setReminder(nil)
        XCTAssertTrue(reminders.planned.isEmpty)
    }

    func testStudyingMovesTodaysReminderToTomorrow() {
        let reminders = InMemoryReminders()
        let store = AppStore(storage: InMemoryProgressStorage(), reminders: reminders)
        store.completeOnboarding(profile)
        store.setReminder(StudyReminder(hour: 23, minute: 59))
        store.completeLesson("u1l1", xp: 10)
        let tomorrow = Calendar.current.startOfDay(for: Calendar.current.date(byAdding: .day, value: 1, to: .now)!)
        XCTAssertGreaterThanOrEqual(reminders.planned.first!.date, tomorrow)
        XCTAssertEqual(store.currentStreak, 1)
        XCTAssertTrue(store.studiedToday)
    }

    func testALabGameWithPointsCountsAsStudy() {
        let store = AppStore(storage: InMemoryProgressStorage(), reminders: InMemoryReminders())
        store.recordScore(0, in: LabGame.sprintId)
        XCTAssertEqual(store.currentStreak, 0)
        store.recordScore(3, in: LabGame.sprintId)
        XCTAssertEqual(store.currentStreak, 1)
    }

    func testResetTurnsTheReminderOff() {
        let reminders = InMemoryReminders()
        let store = AppStore(storage: InMemoryProgressStorage(), reminders: reminders)
        store.completeOnboarding(profile)
        store.setReminder(.standard)
        store.reset()
        XCTAssertNil(store.state.reminder)
        XCTAssertTrue(reminders.planned.isEmpty)
    }

    func testChangingLanguageRewritesTheReminders() {
        let reminders = InMemoryReminders()
        let store = AppStore(storage: InMemoryProgressStorage(), reminders: reminders)
        store.completeOnboarding(profile)
        store.setReminder(StudyReminder(hour: 23, minute: 59))
        var italian = profile
        italian.nativeLanguage = .italian
        store.updateProfile(italian)
        XCTAssertTrue(reminders.planned.last!.message.body.contains("spagnolo"))
    }
}
