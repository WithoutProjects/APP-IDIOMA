import SwiftUI

/// "Apuntes y teoría": the explanations and vocabulary of the current unit, and of every
/// earlier one, to look things up at any time. Only units the learner has reached.
struct NotesView: View {
    @EnvironmentObject private var store: AppStore

    var body: some View {
        NavigationStack {
            let notes = store.notes
            List {
                if let current = notes.first {
                    Section("Current unit") {
                        row(current)
                    }
                }
                if notes.count > 1 {
                    Section("Earlier units") {
                        ForEach(notes.dropFirst()) { row($0) }
                    }
                }
            }
            .overlay {
                if notes.isEmpty {
                    ContentUnavailableView("No notes yet", systemImage: "book.closed",
                                           description: Text("Start your first lesson and its explanations and words will be saved here."))
                }
            }
            .navigationTitle("Notes")
        }
    }

    private func row(_ notes: UnitNotes) -> some View {
        NavigationLink {
            UnitNotesView(notes: notes)
        } label: {
            VStack(alignment: .leading, spacing: 2) {
                Text("Unit \(notes.unit.number) · \(notes.unit.title)").font(.headline)
                Text(notes.unit.gloss.text(store.language)).font(.subheadline).foregroundStyle(.secondary)
                Text("\(notes.lessons.count) lessons · \(notes.lessons.flatMap(\.vocabulary).count) words")
                    .font(.caption)
                    .foregroundStyle(Brick.stem.color)
            }
            .padding(.vertical, 4)
        }
    }
}

/// One unit's notes, lesson by lesson: the words first, then the explanations, as in the lesson.
struct UnitNotesView: View {
    @EnvironmentObject var store: AppStore
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
                Text("Vocabulary").textCase(.uppercase).font(.caption.weight(.bold)).foregroundStyle(.secondary)
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
                .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))
            }

            let explanations = lesson.items.compactMap { item -> FrameCard? in
                if case .frame(let card) = item.kind { return card }
                return nil
            }
            if !explanations.isEmpty {
                Text("Explanations").textCase(.uppercase).font(.caption.weight(.bold)).foregroundStyle(.secondary)
                ForEach(explanations) { card in
                    FrameCardView(card: card, language: store.language, onContinue: {}, showsButton: false)
                        .padding(16)
                        .background(RoundedRectangle(cornerRadius: 20).strokeBorder(Color.secondary.opacity(0.2)))
                }
            }
        }
    }
}
