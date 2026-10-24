import SwiftUI

/// "Repasar tablas": every verb the learner has met, each with a heat-rack that fills as forms are
/// mastered, and a Lego bench to play with endings. A verb joins the tables when its lesson is done.
struct TablesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var benchLemma = "hablar"
    @State private var benchPerson: Person = .yo
    @State private var search = ""
    @Environment(\.tone) private var tone

    private static let countText = Gloss(en: "verbs learned", it: "verbi imparati", uk: "вивчених дієслів", de: "gelernte Verben", fr: "verbes appris", pt: "verbos aprendidos", zh: "个已学动词")
    private static let emptyText = Gloss(en: "Finish your first lesson and its verbs will appear here.", it: "Completa la prima lezione e i suoi verbi appariranno qui.", uk: "Заверши перший урок, і його дієслова з'являться тут.", de: "Schließ deine erste Lektion ab, dann erscheinen ihre Verben hier.", fr: "Termine ta première leçon et ses verbes apparaîtront ici.", pt: "Termine a primeira lição e os verbos dela vão aparecer aqui.", zh: "完成第一课后，它的动词会出现在这里。")
    private static let searchText = Gloss(en: "Find a verb", it: "Cerca un verbo", uk: "Знайти дієслово", de: "Verb suchen", fr: "Chercher un verbe", pt: "Buscar um verbo", zh: "查找动词")
    private static let irregularText = Gloss(en: "This form is irregular: learn it whole.", it: "Questa forma è irregolare: imparala intera.", uk: "Ця форма неправильна: запам'ятай її цілком.", de: "Diese Form ist unregelmäßig: lern sie als Ganzes.", fr: "Cette forme est irrégulière : apprends-la en entier.", pt: "Esta forma é irregular: aprenda ela inteira.", zh: "这个形式是不规则的：整体记住。")

    private var completed: Set<String> { store.state.completedLessons }
    private var verbs: [TableVerb] { VerbTable.unlocked(completed: completed) }

    var body: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 28) {
                    bench.id("bench")
                    rack
                }
                .padding(20)
            }
            // Tapping a verb in the rack puts it on the bench.
            .onChange(of: benchLemma) { _, _ in
                withAnimation { proxy.scrollTo("bench", anchor: .top) }
            }
        }
        .onAppear {
            if !benchVerbs.contains(where: { $0.lemma == benchLemma }), let first = benchVerbs.first {
                benchLemma = first.lemma
            }
        }
        .navigationTitle("Repasar tablas")
        .searchable(text: $search, prompt: Text(verbatim: Self.searchText.text(store.language)))
    }

    // MARK: Heat-rack

    private var shown: [TableVerb] {
        let query = search.trimmingCharacters(in: .whitespaces).folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
        guard !query.isEmpty else { return verbs }
        return verbs.filter { verb in
            [verb.lemma, verb.meaning.text(store.language)].contains {
                $0.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil).contains(query)
            }
        }
    }

    private var rack: some View {
        let unlocked = VerbTable.unlockedPersons(completed: completed)
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Present tense").textCase(.uppercase).font(.caption.weight(.bold)).foregroundStyle(.secondary)
                Spacer()
                Text(verbatim: "\(verbs.count) \(Self.countText.text(store.language))")
                    .font(.caption).foregroundStyle(.secondary)
            }
            if verbs.isEmpty {
                Text(verbatim: Self.emptyText.text(store.language))
                    .font(.callout).foregroundStyle(.secondary)
            }
            LazyVStack(spacing: 10) {
                ForEach(shown) { verb in
                    card(verb, unlocked: unlocked)
                }
            }
        }
    }

    private func card(_ verb: TableVerb, unlocked: [Person]) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: verb.lemma).font(.headline)
                Text(verbatim: verb.meaning.text(store.language))
                    .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
            }
            Grid(horizontalSpacing: 6, verticalSpacing: 6) {
                ForEach([[Person.yo, .nosotros], [.tu, .vosotros], [.el, .ellos]], id: \.self) { row in
                    GridRow {
                        ForEach(row) { person in
                            cell(verb, person, locked: !unlocked.contains(person))
                        }
                    }
                }
            }
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 14).fill(Palette.card))
        .contentShape(Rectangle())
        .onTapGesture { benchLemma = verb.lemma }
    }

    private func cell(_ verb: TableVerb, _ person: Person, locked: Bool) -> some View {
        let used = verb.uses(person)
        let mastery = store.mastery(of: verb.key(person))
        return HStack(spacing: 6) {
            Text(person.label).font(.caption2).foregroundStyle(.secondary)
            Spacer(minLength: 0)
            if locked {
                Image(systemName: "lock.fill").font(.caption2).foregroundStyle(.tertiary)
            } else if !used {
                Text(verbatim: "—").font(.callout).foregroundStyle(.tertiary)
            } else {
                ColoredForm(form: verb.form(person), font: .callout.weight(.semibold))
                    .lineLimit(1).minimumScaleFactor(0.7)
            }
        }
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity, minHeight: 34)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(tone.main.opacity(locked || !used ? 0.04 : 0.08 + 0.17 * Double(mastery)))
        )
    }

    // MARK: Lego bench

    private var benchVerbs: [TableVerb] {
        verbs.isEmpty ? Array(VerbTable.all.prefix(6)) : verbs
    }

    private var bench: some View {
        let options = benchVerbs
        let verb = options.first { $0.lemma == benchLemma } ?? options.first
        let persons = Person.allCases.filter { verb?.uses($0) ?? true }
        let person = persons.contains(benchPerson) ? benchPerson : (persons.first ?? .yo)
        let form = verb?.form(person) ?? VerbForm(stem: "", ending: "")
        return VStack(alignment: .leading, spacing: 14) {
            Text("Lego bench").textCase(.uppercase).font(.caption.weight(.bold)).foregroundStyle(.secondary)
            Picker("Verb", selection: $benchLemma) {
                ForEach(options) { verb in
                    Text(verbatim: "\(verb.lemma) · \(verb.meaning.text(store.language))").tag(verb.lemma)
                }
            }
            .pickerStyle(.menu)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    ForEach(persons) { candidate in
                        Button(candidate.label) { benchPerson = candidate }
                            .accessibilityAddTraits(candidate == person ? .isSelected : [])
                            .buttonStyle(.bordered)
                            .tint(candidate == person ? tone.main : .secondary)
                    }
                }
            }
            HStack(spacing: 10) {
                if form.ending.isEmpty {
                    BrickView(text: form.stem, kind: .stem)
                } else {
                    BrickView(text: form.stem + "-", kind: .stem)
                    Text(verbatim: "+").font(.title2.bold())
                    BrickView(text: "-" + form.ending, kind: .ending)
                    Text(verbatim: "=").font(.title2.bold())
                    ColoredForm(form: form, font: .title2.bold())
                }
            }
            .lineLimit(1)
            .minimumScaleFactor(0.6)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))
            .animation(.spring(response: 0.3), value: form)
            if form.ending.isEmpty {
                Text(verbatim: Self.irregularText.text(store.language))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            } else {
                Text("ER and IR share almost every ending, so there are really 2 families to learn, not 3.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}
