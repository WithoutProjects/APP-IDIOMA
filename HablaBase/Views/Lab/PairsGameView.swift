import SwiftUI

/// "Parejas": tap a verb form, then the person it belongs to. Five quick rounds.
struct PairsGameView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.dismiss) private var dismiss
    @State private var rounds: [[PairsGame.Card]] = []
    @State private var round = 0
    @State private var persons: [Person] = []
    @State private var selected: PairsGame.Card?
    @State private var matched: Set<FormKey> = []
    @State private var missed: Set<FormKey> = []
    @State private var wrongPerson: Person?
    @State private var mistakes = 0
    @State private var startedAt = Date()
    @State private var finished = false

    var body: some View {
        VStack(spacing: 24) {
            if finished {
                results
            } else if round < rounds.count {
                ProgressView(value: Double(round), total: Double(rounds.count))
                    .tint(Brick.ending.color)
                Text("Match each verb to its person.")
                    .font(.headline)
                HStack(alignment: .top, spacing: 16) {
                    VStack(spacing: 12) {
                        ForEach(rounds[round]) { card in
                            formCard(card)
                        }
                    }
                    VStack(spacing: 12) {
                        ForEach(persons) { person in
                            personCard(person)
                        }
                    }
                }
                Spacer()
            }
        }
        .padding(20)
        .navigationTitle("Parejas")
        .onAppear(perform: start)
    }

    // MARK: Cards

    private func formCard(_ card: PairsGame.Card) -> some View {
        let done = matched.contains(card.key)
        let isSelected = selected == card
        return Button {
            if !done { selected = card }
        } label: {
            ColoredForm(form: card.form, font: .title3.bold())
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(RoundedRectangle(cornerRadius: 14).fill(isSelected ? Brick.ending.color.opacity(0.2) : Palette.card))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(isSelected ? Brick.ending.color : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .opacity(done ? 0.2 : 1)
        .disabled(done)
        .accessibilityLabel(card.form.text)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }

    private func personCard(_ person: Person) -> some View {
        let done = rounds[round].contains { $0.person == person && matched.contains($0.key) }
        let isWrong = wrongPerson == person
        return Button {
            pick(person)
        } label: {
            Text(person.label)
                .font(.title3.weight(.semibold))
                .frame(maxWidth: .infinity, minHeight: 56)
                .background(RoundedRectangle(cornerRadius: 14).fill(isWrong ? Palette.warning.opacity(0.25) : Palette.card))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(isWrong ? Palette.warning : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .opacity(done ? 0.2 : 1)
        .disabled(done || selected == nil)
    }

    // MARK: Game flow

    private func start() {
        guard rounds.isEmpty else { return }
        let unlocked = Unit1.unlockedPersons(completed: store.state.completedLessons)
        rounds = PairsGame.makeRounds(verbs: Unit1.coreVerbs, persons: unlocked)
        startedAt = Date()
        beginRound()
    }

    private func beginRound() {
        guard round < rounds.count else {
            finish()
            return
        }
        persons = rounds[round].map(\.person).shuffled()
        selected = nil
    }

    private func pick(_ person: Person) {
        guard let card = selected else { return }
        if card.person == person {
            withAnimation(.spring(response: 0.3)) { matched.insert(card.key) }
            store.recordForms([card.key], correct: !missed.contains(card.key))
            selected = nil
            if rounds[round].allSatisfy({ matched.contains($0.key) }) {
                round += 1
                beginRound()
            }
        } else {
            mistakes += 1
            missed.insert(card.key)
            withAnimation(.easeInOut(duration: 0.2)) { wrongPerson = person }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { wrongPerson = nil }
            }
        }
    }

    private func finish() {
        guard !finished else { return }
        store.addXP(xp)
        finished = true
    }

    private var xp: Int { max(2, 10 - mistakes) }

    // MARK: Results

    private var results: some View {
        let seconds = Int(Date().timeIntervalSince(startedAt))
        return VStack(spacing: 20) {
            Spacer()
            Image(systemName: mistakes == 0 ? "star.circle.fill" : "checkmark.circle.fill")
                .font(.system(size: 64))
                .foregroundStyle(mistakes == 0 ? .yellow : Palette.success)
                .accessibilityHidden(true)
            Text(mistakes == 0 ? "¡Perfecto!" : "¡Bien hecho!")
                .font(.title.bold())
            Text("Pairs: \(matched.count) · Mistakes: \(mistakes) · \(seconds) s · +\(xp) XP")
                .foregroundStyle(.secondary)
            Spacer()
            Button("Play again") {
                rounds = []
                round = 0
                matched = []
                missed = []
                mistakes = 0
                finished = false
                start()
            }
            .buttonStyle(PrimaryButtonStyle(color: Brick.ending.color))
            Button("Back to the Lab") { dismiss() }
        }
    }
}
