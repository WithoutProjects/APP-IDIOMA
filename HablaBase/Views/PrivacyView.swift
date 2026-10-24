import SwiftUI

/// The privacy policy, in the learner's language. The App Store asks for it inside the app too.
struct PrivacyView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                ForEach(Self.paragraphs, id: \.en) { paragraph in
                    Text(paragraph.text(store.language))
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .navigationTitle(Self.title.text(store.language))
    }

    static let title = Gloss(en: "Privacy", it: "Privacy", uk: "Конфіденційність", de: "Datenschutz", fr: "Confidentialité", pt: "Privacidade", zh: "隐私")

    static let paragraphs: [Gloss] = [
        Gloss(en: "HablaBase has no accounts, no ads and no tracking. We do not collect any data about you.",
              it: "HablaBase non ha account, pubblicità né tracciamento. Non raccogliamo nessun dato su di te.",
              uk: "У HablaBase немає облікових записів, реклами чи відстеження. Ми не збираємо жодних даних про тебе.",
              de: "HablaBase hat keine Konten, keine Werbung und kein Tracking. Wir erheben keine Daten über dich.",
              fr: "HablaBase n'a ni compte, ni publicité, ni pistage. Nous ne collectons aucune donnée sur toi.",
              pt: "O HablaBase não tem contas, anúncios nem rastreamento. Não coletamos nenhum dado sobre você.",
              zh: "HablaBase 没有账号、没有广告、没有追踪。我们不收集任何关于你的数据。"),
        Gloss(en: "Your name, city, answers and progress are saved only on this iPhone and in its backup. They are never sent to us or to anyone else.",
              it: "Il tuo nome, la città, le risposte e i progressi sono salvati solo su questo iPhone e nel suo backup. Non vengono mai inviati a noi né a nessun altro.",
              uk: "Твоє ім'я, місто, відповіді та прогрес зберігаються лише на цьому iPhone і в його резервній копії. Вони ніколи не надсилаються ні нам, ні комусь іншому.",
              de: "Dein Name, deine Stadt, deine Antworten und dein Fortschritt werden nur auf diesem iPhone und in seinem Backup gespeichert. Sie werden nie an uns oder andere gesendet.",
              fr: "Ton prénom, ta ville, tes réponses et ta progression sont enregistrés uniquement sur cet iPhone et dans sa sauvegarde. Ils ne sont jamais envoyés ni à nous ni à personne d'autre.",
              pt: "Seu nome, cidade, respostas e progresso ficam salvos só neste iPhone e no backup dele. Eles nunca são enviados para nós nem para mais ninguém.",
              zh: "你的名字、城市、答案和学习进度只保存在这部 iPhone 及其备份中，绝不会发送给我们或任何其他人。"),
        Gloss(en: "When you answer by voice, your iPhone turns what you say into text. On iPhones that support it this happens on the phone; otherwise Apple's speech recognition processes the audio under Apple's privacy policy. HablaBase keeps no recordings.",
              it: "Quando rispondi a voce, il tuo iPhone trasforma ciò che dici in testo. Sugli iPhone che lo permettono avviene sul telefono; altrimenti l'audio viene elaborato dal riconoscimento vocale di Apple secondo la privacy policy di Apple. HablaBase non conserva registrazioni.",
              uk: "Коли ти відповідаєш голосом, iPhone перетворює сказане на текст. На iPhone, які це підтримують, це відбувається на самому телефоні; інакше аудіо обробляє розпізнавання мовлення Apple згідно з політикою конфіденційності Apple. HablaBase не зберігає записів.",
              de: "Wenn du per Sprache antwortest, wandelt dein iPhone das Gesagte in Text um. Auf iPhones, die das unterstützen, passiert das auf dem Gerät; sonst verarbeitet die Spracherkennung von Apple den Ton gemäß Apples Datenschutzrichtlinie. HablaBase speichert keine Aufnahmen.",
              fr: "Quand tu réponds à voix haute, ton iPhone transforme ce que tu dis en texte. Sur les iPhone compatibles, cela se fait sur l'appareil ; sinon, la reconnaissance vocale d'Apple traite l'audio selon la politique de confidentialité d'Apple. HablaBase ne garde aucun enregistrement.",
              pt: "Quando você responde por voz, o iPhone transforma o que você diz em texto. Nos iPhones compatíveis isso acontece no próprio aparelho; caso contrário, o reconhecimento de fala da Apple processa o áudio conforme a política de privacidade da Apple. O HablaBase não guarda gravações.",
              zh: "当你用语音回答时，iPhone 会把你说的话转成文字。在支持的 iPhone 上，这一过程在手机上完成；否则由 Apple 的语音识别按照 Apple 的隐私政策处理音频。HablaBase 不保存任何录音。"),
        Gloss(en: "The Spanish you hear is read by your iPhone's own voices, without the internet.",
              it: "Lo spagnolo che ascolti è letto dalle voci del tuo iPhone, senza internet.",
              uk: "Іспанську, яку ти чуєш, читають голоси самого iPhone, без інтернету.",
              de: "Das Spanisch, das du hörst, liest die Stimme deines iPhones vor, ohne Internet.",
              fr: "L'espagnol que tu entends est lu par les voix de ton iPhone, sans internet.",
              pt: "O espanhol que você ouve é lido pelas vozes do próprio iPhone, sem internet.",
              zh: "你听到的西班牙语由 iPhone 自带的语音朗读，无需联网。"),
        Gloss(en: "To delete everything, tap Reset progress in Profile, or delete the app.",
              it: "Per cancellare tutto, tocca Azzera i progressi nel Profilo, oppure elimina l'app.",
              uk: "Щоб усе видалити, натисни «Скинути прогрес» у Профілі або видали застосунок.",
              de: "Um alles zu löschen, tippe im Profil auf „Fortschritt zurücksetzen“ oder lösche die App.",
              fr: "Pour tout effacer, touche Réinitialiser la progression dans Profil, ou supprime l'app.",
              pt: "Para apagar tudo, toque em Redefinir progresso no Perfil ou apague o app.",
              zh: "如需删除所有数据，请在“个人资料”中点“重置进度”，或删除本应用。"),
    ]
}

/// The bottom of the Profile tab: the privacy policy and the app version.
struct AboutSection: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        Section {
            NavigationLink {
                PrivacyView()
            } label: {
                Label(PrivacyView.title.text(store.language), systemImage: "hand.raised.fill")
            }
        } footer: {
            Text(verbatim: "HablaBase \(Self.version)")
        }
    }

    static var version: String {
        Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? ""
    }
}
