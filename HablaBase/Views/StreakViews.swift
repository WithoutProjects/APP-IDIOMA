import SwiftUI
import UIKit
import UserNotifications

/// Days in a row, shown quietly: the count, the last seven days as dots and one plain line.
/// Missing a day only starts the count again; there is nothing to lose or to buy back.
struct StreakCard: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.tone) private var tone

    var body: some View {
        let language = store.language
        let streak = store.currentStreak
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .lastTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Eyebrow(text: Self.title.text(language), color: tone.main)
                    Text(verbatim: "\(streak)")
                        .font(.system(size: 34, weight: .semibold))
                        .monospacedDigit()
                }
                Spacer()
                if store.state.bestStreak > 1 {
                    Text(verbatim: "\(Self.best.text(language)) \(store.state.bestStreak)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(Text(verbatim: "\(Self.title.text(language)): \(streak). \(Self.best.text(language)) \(store.state.bestStreak)"))

            HStack(spacing: 0) {
                ForEach(store.studyWeek) { day in
                    VStack(spacing: 6) {
                        Text(verbatim: Self.letter(day.date, language: language))
                            .font(.caption2.weight(day.isToday ? .semibold : .regular))
                            .foregroundStyle(day.isToday ? Color.primary : Color.secondary)
                        Circle()
                            .fill(day.studied ? tone.main : Color.clear)
                            .overlay(Circle().strokeBorder(day.studied ? Color.clear : (day.isToday ? tone.main : Color(.systemGray4)),
                                                           lineWidth: 1.5))
                            .frame(width: 14, height: 14)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .accessibilityHidden(true)

            Text(status.text(language))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Palette.card))
    }

    private var status: Gloss {
        if store.studiedToday { return Self.doneToday }
        return store.currentStreak > 0 ? Self.keepGoing : Self.start
    }

    /// The one-letter weekday, in the learner's language.
    static func letter(_ date: Date, language: NativeLanguage) -> String {
        let formatter = DateFormatter()
        formatter.locale = language.locale
        formatter.setLocalizedDateFormatFromTemplate("EEEEE")
        return formatter.string(from: date)
    }

    static let title = Gloss(en: "Days in a row", it: "Giorni di fila", uk: "Днів поспіль", de: "Tage in Folge",
                             fr: "Jours d'affilée", pt: "Dias seguidos", zh: "连续学习天数")
    static let best = Gloss(en: "Best:", it: "Record:", uk: "Рекорд:", de: "Bestwert:", fr: "Record :", pt: "Recorde:", zh: "最长：")
    static let doneToday = Gloss(
        en: "Today counts. See you tomorrow.",
        it: "Oggi conta. A domani.",
        uk: "Сьогоднішній день зараховано. До завтра.",
        de: "Heute zählt. Bis morgen.",
        fr: "Aujourd'hui compte. À demain.",
        pt: "Hoje já conta. Até amanhã.",
        zh: "今天已计入。明天见。")
    static let keepGoing = Gloss(
        en: "A lesson or a Lab game today keeps it going.",
        it: "Una lezione o un gioco del Lab oggi e continui così.",
        uk: "Урок або гра в Лабораторії сьогодні, і серія триває.",
        de: "Eine Lektion oder ein Lab-Spiel heute, und es geht weiter.",
        fr: "Une leçon ou un jeu du Lab aujourd'hui, et ça continue.",
        pt: "Uma lição ou um jogo do Lab hoje e você continua.",
        zh: "今天完成一节课或一个实验室游戏，就能继续保持。")
    static let start = Gloss(
        en: "Finish a lesson or a Lab game and today counts as day one.",
        it: "Finisci una lezione o un gioco del Lab e oggi è il primo giorno.",
        uk: "Заверши урок або гру в Лабораторії, і сьогодні стане першим днем.",
        de: "Schließ eine Lektion oder ein Lab-Spiel ab, und heute ist Tag eins.",
        fr: "Termine une leçon ou un jeu du Lab et aujourd'hui sera le premier jour.",
        pt: "Termine uma lição ou um jogo do Lab e hoje conta como o primeiro dia.",
        zh: "完成一节课或一个实验室游戏，今天就算第一天。")
}

/// The daily reminder in Profile: off until the learner turns it on, at the time they choose.
/// The system asks for permission only when they turn it on, after the footer says what it does.
struct ReminderSection: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.scenePhase) private var scenePhase
    @State private var permission: UNAuthorizationStatus = .notDetermined
    @State private var asking = false

    var body: some View {
        let language = store.language
        Section {
            Toggle(isOn: Binding(get: { store.state.reminder != nil },
                                 set: { $0 ? turnOn() : store.setReminder(nil) })) {
                Text(Self.toggle.text(language))
            }
            .disabled(asking)

            if let reminder = store.state.reminder {
                DatePicker(selection: Binding(get: { Self.date(for: reminder) },
                                              set: { store.setReminder(Self.reminder(at: $0)) }),
                           displayedComponents: .hourAndMinute) {
                    Text(Self.time.text(language))
                }
            }

            if permission == .denied {
                Button(Self.openSettings.text(language)) {
                    if let url = URL(string: UIApplication.openNotificationSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
            }
        } header: {
            Text(Self.header.text(language))
        } footer: {
            Text((permission == .denied ? Self.denied : Self.explanation).text(language))
        }
        .task { permission = await NotificationReminders.permission() }
        .onChange(of: scenePhase) { _, phase in
            // The learner may have changed the permission in Settings.
            guard phase == .active else { return }
            Task { permission = await NotificationReminders.permission() }
        }
    }

    private func turnOn() {
        asking = true
        Task {
            let granted = await NotificationReminders.requestPermission()
            permission = await NotificationReminders.permission()
            if granted { store.setReminder(.standard) }
            asking = false
        }
    }

    static func date(for reminder: StudyReminder, calendar: Calendar = .current) -> Date {
        calendar.date(bySettingHour: reminder.hour, minute: reminder.minute, second: 0, of: .now) ?? .now
    }

    static func reminder(at date: Date, calendar: Calendar = .current) -> StudyReminder {
        let parts = calendar.dateComponents([.hour, .minute], from: date)
        return StudyReminder(hour: parts.hour ?? StudyReminder.standard.hour, minute: parts.minute ?? 0)
    }

    static let header = Gloss(en: "Reminder", it: "Promemoria", uk: "Нагадування", de: "Erinnerung",
                              fr: "Rappel", pt: "Lembrete", zh: "提醒")
    static let toggle = Gloss(en: "Daily study reminder", it: "Promemoria per studiare", uk: "Щоденне нагадування",
                              de: "Tägliche Lernerinnerung", fr: "Rappel quotidien", pt: "Lembrete diário", zh: "每日学习提醒")
    static let time = Gloss(en: "Time", it: "Ora", uk: "Час", de: "Uhrzeit", fr: "Heure", pt: "Horário", zh: "时间")
    static let explanation = Gloss(
        en: "One quiet notification a day at your time, and none on days you have already studied. Your iPhone shows it; nothing is sent anywhere.",
        it: "Una notifica discreta al giorno all'ora che scegli, e nessuna nei giorni in cui hai già studiato. La mostra il tuo iPhone; non viene inviato nulla.",
        uk: "Одне тихе сповіщення на день у вибраний час і жодного в дні, коли заняття вже було. Його показує сам iPhone; нічого нікуди не надсилається.",
        de: "Eine ruhige Mitteilung pro Tag zu deiner Uhrzeit und keine an Tagen, an denen du schon gelernt hast. Dein iPhone zeigt sie an; nichts wird irgendwohin gesendet.",
        fr: "Une notification discrète par jour à l'heure choisie, et aucune les jours où tu as déjà étudié. C'est ton iPhone qui l'affiche ; rien n'est envoyé nulle part.",
        pt: "Uma notificação discreta por dia no horário que você escolher, e nenhuma nos dias em que você já estudou. O próprio iPhone a mostra; nada é enviado.",
        zh: "每天在你选择的时间发送一条安静的通知，已经学习过的日子不会提醒。通知由 iPhone 本身显示，不会发送任何数据。")
    static let denied = Gloss(
        en: "Notifications are turned off for Hablo. To get the reminder, allow them in Settings.",
        it: "Le notifiche di Hablo sono disattivate. Per ricevere il promemoria, attivale nelle Impostazioni.",
        uk: "Сповіщення для Hablo вимкнено. Щоб отримувати нагадування, дозволь їх у Параметрах.",
        de: "Mitteilungen für Hablo sind ausgeschaltet. Erlaube sie in den Einstellungen, um die Erinnerung zu bekommen.",
        fr: "Les notifications de Hablo sont désactivées. Pour recevoir le rappel, autorise-les dans Réglages.",
        pt: "As notificações do Hablo estão desativadas. Para receber o lembrete, permita-as nos Ajustes.",
        zh: "Hablo 的通知已关闭。如需接收提醒，请在“设置”中允许通知。")
    static let openSettings = Gloss(en: "Open Settings", it: "Apri Impostazioni", uk: "Відкрити Параметри",
                                    de: "Einstellungen öffnen", fr: "Ouvrir Réglages", pt: "Abrir Ajustes", zh: "打开设置")
}
