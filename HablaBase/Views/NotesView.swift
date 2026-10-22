import SwiftUI

/// "Apuntes y teoría": the explanations and vocabulary of the current unit, and of every
/// earlier one, to look things up at any time. Only units the learner has reached.
struct NotesView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            let notes = store.notes
            ScrollView {
                VStack(alignment: .leading, spacing: 14) {
                    ScreenHeader(eyebrow: Journey.currentLevel(store: store).map { Journey.caption($0, language: store.language) },
                                 title: "Notes",
                                 subtitle: Self.intro.text(store.language))
                        .padding(.bottom, 8)
                    if let current = notes.first {
                        Eyebrow(text: store.language.localized("Current unit"))
                        row(current)
                    }
                    if notes.count > 1 {
                        Eyebrow(text: store.language.localized("Earlier units"))
                            .padding(.top, 12)
                        ForEach(notes.dropFirst()) { row($0) }
                    }
                    if notes.isEmpty {
                        ContentUnavailableView("No notes yet", systemImage: "book.closed",
                                               description: Text("Start your first lesson and its explanations and words will be saved here."))
                            .padding(.top, 40)
                    }
                }
                .padding(20)
            }
            .toolbar(.hidden, for: .navigationBar)
        }
    }

    static let intro = Gloss(en: "Every explanation and word you have met, unit by unit.", it: "Tutte le spiegazioni e le parole che hai incontrato, unità per unità.", uk: "Усі пояснення і слова, які ти вже бачив, розділ за розділом.", de: "Alle Erklärungen und Wörter, die du kennengelernt hast, Einheit für Einheit.", fr: "Toutes les explications et tous les mots rencontrés, unité par unité.", pt: "Todas as explicações e palavras que você já viu, unidade por unidade.", zh: "你学过的所有讲解和单词，按单元整理。")

    private func row(_ notes: UnitNotes) -> some View {
        let tone = Journey.level(of: notes.unit).map { Tone.forLevel($0.number) } ?? .sage
        return NavigationLink {
            UnitNotesView(notes: notes)
                .levelTone(tone)
        } label: {
            HStack(spacing: 16) {
                ToneTile(size: 52) {
                    Text(verbatim: "\(notes.unit.number)").monospacedDigit()
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(notes.unit.title).font(.headline)
                    Text(notes.unit.gloss.text(store.language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text("\(notes.lessons.count) lessons · \(notes.lessons.flatMap(\.vocabulary).count) words")
                        .font(.caption)
                        .foregroundStyle(tone.main)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Palette.card))
            .contentShape(Rectangle())
            .environment(\.tone, tone)
        }
        .buttonStyle(.plain)
    }
}

/// One unit's notes, lesson by lesson: the words first, then the explanations, as in the lesson.
struct UnitNotesView: View {
    @EnvironmentObject var store: AppStore
    @Environment(\.tone) var tone
    let notes: UnitNotes

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 32) {
                ForEach(notes.lessons) { lesson in
                    lessonNotes(lesson)
                }
            }
            .padding(20)
        }
        .navigationTitle("Unit \(notes.unit.number) · \(notes.unit.title)")
        .navigationBarTitleDisplayMode(.inline)
        .environment(\.glossary, store.glossary())
        .environment(\.learnerLanguage, store.language)
    }

    private func lessonNotes(_ lesson: Lesson) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(lesson.title).font(.title2.bold())
                Text(lesson.titleGloss.text(store.language)).foregroundStyle(.secondary)
            }

            if !lesson.vocabulary.isEmpty {
                Eyebrow(text: store.language.localized("Vocabulary"), color: tone.main)
                VStack(spacing: 0) {
                    ForEach(lesson.vocabulary, id: \.self) { word in
                        HStack {
                            Text(word.es).font(.body.weight(.semibold)).foregroundStyle(word.kind.color)
                            Spacer()
                            Text(word.gloss.text(store.language)).foregroundStyle(.secondary)
                            SpeakButton(text: word.es)
                        }
                        .padding(.horizontal, 14)
                        Divider().padding(.leading, 14)
                    }
                }
                .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Palette.card))
            }

            let explanations = lesson.items.compactMap { item -> FrameCard? in
                if case .frame(let card) = item.kind { return card }
                return nil
            }
            if !explanations.isEmpty {
                Eyebrow(text: store.language.localized("Explanations"), color: tone.main)
                ForEach(explanations) { card in
                    FrameCardView(card: card, language: store.language, onContinue: {}, showsButton: false)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color(.systemGray5)))
                }
            }
        }
    }
}
