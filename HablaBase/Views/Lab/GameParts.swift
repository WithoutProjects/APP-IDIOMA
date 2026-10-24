import SwiftUI

/// The first screen of a Lab game: its icon, how it works, the record and Start.
struct GameIntro: View {
    let icon: String
    let rules: String
    /// "Your record: 7", nil before the first game.
    let record: String?
    let onStart: () -> Void
    @Environment(\.tone) private var tone
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(spacing: 20) {
            Spacer()
            ToneTile(size: 88, filled: true) {
                Image(systemName: icon).font(.system(size: 40, weight: .semibold))
            }
            Text(rules)
                .font(.title3)
                .multilineTextAlignment(.center)
            if let record {
                Text(record)
                    .font(.headline)
                    .foregroundStyle(tone.main)
            }
            Spacer()
            Button(SprintGameView.start.text(store.language), action: onStart)
                .buttonStyle(PrimaryButtonStyle())
        }
    }
}

/// The last screen of a Lab game: the score, the record, XP, what to review and two buttons.
struct GameResults: View {
    struct Review: Identifiable {
        let id = UUID()
        let prompt: String
        let answer: String
        /// Spanish to read aloud, if any.
        var spoken: String?
    }

    let score: String
    let newRecord: Bool
    let record: String
    let xp: Int
    var review: [Review] = []
    /// Shown instead of the score when there was nothing to play yet.
    var emptyMessage: String?
    let onAgain: () -> Void
    @Environment(\.tone) private var tone
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var store: AppStore

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                Image(systemName: newRecord ? "trophy.circle.fill" : "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(tone.main)
                    .accessibilityHidden(true)
                if let emptyMessage {
                    Text(emptyMessage)
                        .multilineTextAlignment(.center)
                } else {
                    Text(verbatim: score)
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                    Text(newRecord ? SprintGameView.recordLabel.text(store.language) : record)
                        .font(.headline)
                        .foregroundStyle(newRecord ? tone.main : Color.secondary)
                    Text(verbatim: "+\(xp) XP")
                        .foregroundStyle(.secondary)
                }
                if !review.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Eyebrow(text: SprintGameView.reviewLabel.text(store.language))
                        ForEach(review) { row in
                            HStack(alignment: .firstTextBaseline) {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(verbatim: row.answer)
                                        .font(.headline)
                                    Text(verbatim: row.prompt)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer(minLength: 8)
                                if let spoken = row.spoken {
                                    SpeakButton(text: spoken)
                                }
                            }
                            .accessibilityElement(children: .combine)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(18)
                    .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
                }
                if emptyMessage == nil {
                    Button(SprintGameView.again.text(store.language), action: onAgain)
                        .buttonStyle(PrimaryButtonStyle())
                }
                Button(SprintGameView.back.text(store.language)) { dismiss() }
            }
            .frame(maxWidth: .infinity)
        }
    }
}

/// The bar under an answer: right or not, the model answer with its sound, and Next.
struct GameFeedback: View {
    let right: Bool
    let message: String
    /// The Spanish to show and read aloud.
    var spanish: String?
    let onNext: () -> Void
    @EnvironmentObject private var store: AppStore

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Label(message, systemImage: right ? "checkmark.circle.fill" : "xmark.circle.fill")
                .font(.headline)
                .foregroundStyle(right ? Palette.success : Palette.warning)
            if let spanish {
                HStack(alignment: .firstTextBaseline) {
                    Text(verbatim: spanish)
                    Spacer(minLength: 8)
                    SpeakButton(text: spanish)
                }
            }
            Button(ErrorHuntView.next.text(store.language), action: onNext)
                .buttonStyle(PrimaryButtonStyle())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// Texts shared by the Lab games.
enum GameTexts {
    static let right = Gloss(en: "Right!", it: "Giusto!", uk: "Правильно!", de: "Richtig!", fr: "Juste !", pt: "Certo!", zh: "正确！")
    static let accent = Gloss(en: "Right! Watch the accents:", it: "Giusto! Attento agli accenti:", uk: "Правильно! Зверни увагу на наголоси:", de: "Richtig! Achte auf die Akzente:", fr: "Juste ! Attention aux accents :", pt: "Certo! Atenção aos acentos:", zh: "正确！注意重音符号：")
    static let wrong = Gloss(en: "Not quite. The answer:", it: "Non proprio. La risposta:", uk: "Не зовсім. Відповідь:", de: "Nicht ganz. Die Antwort:", fr: "Pas tout à fait. La réponse :", pt: "Quase. A resposta:", zh: "不太对。答案是：")
    static let check = Gloss(en: "Check", it: "Controlla", uk: "Перевірити", de: "Prüfen", fr: "Vérifier", pt: "Verificar", zh: "检查")
    static let writeHere = Gloss(en: "Write in Spanish", it: "Scrivi in spagnolo", uk: "Пиши іспанською", de: "Schreib auf Spanisch", fr: "Écris en espagnol", pt: "Escreva em espanhol", zh: "用西班牙语写")

    static func record(_ value: Int, of total: Int? = nil, language: NativeLanguage) -> String? {
        guard value > 0 else { return nil }
        return SprintGameView.bestLabel.text(language) + " \(value)" + (total.map { "/\($0)" } ?? "")
    }
}
