import Foundation

/// The daily study reminder the learner chose in Profile: one quiet notification at their time.
struct StudyReminder: Codable, Equatable {
    var hour: Int
    var minute: Int

    static let standard = StudyReminder(hour: 19, minute: 0)

    /// How many days ahead are planned. They are planned again whenever the learner studies or
    /// opens the app, so a reminder never arrives on a day they have already studied.
    static let plannedDays = 14

    /// The moments the next reminders fire, soonest first: today if the time has not passed and
    /// the learner has not studied yet, then every following day.
    func fireDates(from now: Date, studiedToday: Bool, calendar: Calendar = .current,
                   days: Int = StudyReminder.plannedDays) -> [Date] {
        let startOfToday = calendar.startOfDay(for: now)
        let dates = (0...days).compactMap { offset -> Date? in
            guard let day = calendar.date(byAdding: .day, value: offset, to: startOfToday),
                  let fire = calendar.date(bySettingHour: hour, minute: minute, second: 0, of: day) else { return nil }
            if offset == 0 && (studiedToday || fire <= now) { return nil }
            return fire
        }
        return Array(dates.prefix(days))
    }

    /// The text of each planned reminder. The first one mentions a streak that is still alive;
    /// later ones only fire if the learner skipped days, so they never talk about a lost streak.
    static func messages(count: Int, streak: Int, minutes: Int, language: NativeLanguage) -> [ReminderMessage] {
        (0..<count).map { index in
            let body: Gloss
            if index == 0 && streak > 0 {
                body = streak == 1 ? keepGoingOne : keepGoing
            } else {
                body = index.isMultiple(of: 2) ? fewMinutes : nextLesson
            }
            return ReminderMessage(title: title,
                                   body: body.text(language)
                                       .replacingOccurrences(of: "{n}", with: "\(streak)")
                                       .replacingOccurrences(of: "{min}", with: "\(minutes)"))
        }
    }

    static let title = "Hablo"

    static let fewMinutes = Gloss(
        en: "Your {min} minutes of Spanish for today, whenever suits you.",
        it: "I tuoi {min} minuti di spagnolo di oggi, quando ti va.",
        uk: "Твої {min} хвилин іспанської на сьогодні, коли тобі зручно.",
        de: "Deine {min} Minuten Spanisch für heute, wann es dir passt.",
        fr: "Tes {min} minutes d'espagnol du jour, quand tu veux.",
        pt: "Seus {min} minutos de espanhol de hoje, quando for melhor para você.",
        zh: "今天的 {min} 分钟西班牙语，什么时候方便都可以。")

    static let nextLesson = Gloss(
        en: "Your next Spanish lesson is ready when you are.",
        it: "La tua prossima lezione di spagnolo ti aspetta.",
        uk: "Твій наступний урок іспанської чекає на тебе.",
        de: "Deine nächste Spanischlektion wartet auf dich.",
        fr: "Ta prochaine leçon d'espagnol t'attend.",
        pt: "Sua próxima lição de espanhol está esperando por você.",
        zh: "你的下一节西班牙语课已经准备好了。")

    static let keepGoing = Gloss(
        en: "{n} days in a row. One short lesson today keeps it going.",
        it: "{n} giorni di fila. Una lezione breve oggi e continui così.",
        uk: "{n} дн. поспіль. Один короткий урок сьогодні, і серія триває.",
        de: "{n} Tage in Folge. Eine kurze Lektion heute, und es geht weiter.",
        fr: "{n} jours d'affilée. Une courte leçon aujourd'hui et ça continue.",
        pt: "{n} dias seguidos. Uma lição curta hoje e você continua.",
        zh: "已连续学习 {n} 天。今天上一节短课就能继续保持。")

    static let keepGoingOne = Gloss(
        en: "You studied yesterday. One short lesson today makes it two days in a row.",
        it: "Ieri hai studiato. Una lezione breve oggi e sono due giorni di fila.",
        uk: "Учора був день навчання. Один короткий урок сьогодні, і буде два дні поспіль.",
        de: "Gestern hast du gelernt. Eine kurze Lektion heute, und es sind zwei Tage in Folge.",
        fr: "Tu as étudié hier. Une courte leçon aujourd'hui et ça fait deux jours d'affilée.",
        pt: "Você estudou ontem. Uma lição curta hoje e são dois dias seguidos.",
        zh: "你昨天学习了。今天上一节短课，就连续两天了。")
}

struct ReminderMessage: Equatable {
    let title: String
    let body: String
}

/// One notification to plan: when it fires and what it says.
struct PlannedReminder: Equatable {
    let date: Date
    let message: ReminderMessage
}
