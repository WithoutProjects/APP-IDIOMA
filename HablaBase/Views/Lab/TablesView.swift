import SwiftUI

/// "Repasar tablas": a heat-rack that fills as forms are mastered, and a Lego bench to play with endings.
struct TablesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var benchLemma = "hablar"
    @State private var benchPerson: Person = .yo

    private let rackPersons = Unit1.persons

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                rack
                bench
            }
            .padding(20)
        }
        .navigationTitle("Repasar tablas")
    }

    // MARK: Heat-rack

    private var rack: some View {
        let unlocked = Unit1.unlockedPersons(completed: store.state.completedLessons)
        return VStack(alignment: .leading, spacing: 10) {
            Text("PRESENTE RACK").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                GridRow {
                    Text("")
                    ForEach(rackPersons) { person in
                        Text(person.label).font(.caption.weight(.semibold))
                    }
                }
                ForEach(Unit1.verbs) { verb in
                    GridRow {
                        Text(verb.lemma).font(.caption).foregroundStyle(.secondary)
                            .gridColumnAlignment(.leading)
                        ForEach(rackPersons) { person in
                            cell(verb, person, locked: !unlocked.contains(person))
                        }
                    }
                }
            }
        }
    }

    private func cell(_ verb: Verb, _ person: Person, locked: Bool) -> some View {
        let mastery = store.mastery(of: Conjugator.key(verb, .presente, person))
        return Group {
            if locked {
                Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.tertiary)
            } else {
                ColoredForm(form: Conjugator.conjugate(verb, .presente, person), font: .callout.weight(.semibold))
            }
        }
        .frame(maxWidth: .infinity, minHeight: 34)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Palette.success.opacity(locked ? 0.04 : 0.08 + 0.17 * Double(mastery)))
        )
    }

    // MARK: Lego bench

    private var bench: some View {
        let verb = Unit1.verb(benchLemma)
        let form = Conjugator.conjugate(verb, .presente, benchPerson)
        return VStack(alignment: .leading, spacing: 14) {
            Text("LEGO BENCH").font(.caption.weight(.bold)).foregroundStyle(.secondary)
            Picker("Verb", selection: $benchLemma) {
                ForEach(Unit1.verbs) { verb in
                    Text("\(verb.lemma) · \(verb.meaning.text(store.language))").tag(verb.lemma)
                }
            }
            .pickerStyle(.menu)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(Person.allCases) { person in
                        Button(person.label) { benchPerson = person }
                            .buttonStyle(.bordered)
                            .tint(person == benchPerson ? Brick.ending.color : .secondary)
                    }
                }
            }
            HStack(spacing: 10) {
                BrickView(text: form.stem + "-", kind: .stem)
                Text("+").font(.title2.bold())
                BrickView(text: "-" + form.ending, kind: .ending)
                Text("=").font(.title2.bold())
                ColoredForm(form: form, font: .title2.bold())
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))
            .animation(.spring(response: 0.3), value: form)
            Text("ER and IR share almost every ending, so there are really 2 families to learn, not 3.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }
}
