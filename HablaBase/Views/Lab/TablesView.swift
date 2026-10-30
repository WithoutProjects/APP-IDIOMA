import SwiftUI

/// "Repasar tablas": one folder per tense, like the notes, each with its formula, the three model
/// verbs and the irregulars worth learning. A search box shows any verb in every tense.
struct TablesView: View {
    @EnvironmentObject private var store: AppStore
    @State private var search = ""

    private var completed: Set<String> { store.state.completedLessons }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 14) {
                if query.isEmpty {
                    folders
                } else {
                    results
                }
            }
            .padding(20)
        }
        .navigationTitle("Repasar tablas")
        .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always),
                    prompt: Text(verbatim: Self.searchText.text(store.language)))
        .autocorrectionDisabled()
        .textInputAutocapitalization(.never)
    }

    // MARK: Folders

    private var folders: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(verbatim: Self.intro.text(store.language))
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
            ForEach(TableTense.Group.allCases) { group in
                Eyebrow(text: group.name.text(store.language))
                    .padding(.top, 10)
                ForEach(group.tenses) { tense in
                    folderRow(tense)
                }
            }
        }
    }

    private func folderRow(_ tense: TableTense) -> some View {
        let tone = Journey.tone(forStep: tense.gate) ?? .sage
        let taught = tense.isTaught(completed: completed)
        return NavigationLink {
            TenseFolderView(tense: tense)
                .levelTone(tone)
        } label: {
            HStack(spacing: 16) {
                ToneTile(size: 52, filled: false) {
                    if taught {
                        Image(systemName: "folder.fill")
                    } else {
                        Image(systemName: "lock.fill").font(.subheadline)
                    }
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(verbatim: tense.spanishName).font(.headline)
                    Text(verbatim: tense.name.text(store.language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(verbatim: taught ? Self.sample(tense) : Self.unitText(tense, language: store.language))
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

    /// "hablé · comí · viví": the tense at a glance.
    private static func sample(_ tense: TableTense) -> String {
        TableTense.models.compactMap { lemma in
            VerbBook.shared.verb(lemma).flatMap { tense.forms($0)?.first?.text }
        }
        .joined(separator: " · ")
    }

    // MARK: Search

    private var query: String { Self.fold(search.trimmingCharacters(in: .whitespacesAndNewlines)) }

    private var results: some View {
        let found = Self.find(query, completed: completed, language: store.language)
        return VStack(alignment: .leading, spacing: 10) {
            if found.isEmpty {
                ContentUnavailableView {
                    Label { Text(verbatim: Self.noResultText.text(store.language)) } icon: { Image(systemName: "magnifyingglass") }
                } description: {
                    Text(verbatim: Self.noResultHint.text(store.language))
                }
                .padding(.top, 40)
            }
            ForEach(found) { verb in
                NavigationLink {
                    VerbDetailView(verb: verb)
                        .levelTone(Journey.currentTone(store: store))
                } label: {
                    resultRow(verb)
                }
                .buttonStyle(.plain)
            }
        }
    }

    private func resultRow(_ verb: VerbEntry) -> some View {
        let learned = VerbTable.isLearned(verb.lemma, completed: completed)
        return HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(verbatim: verb.lemma).font(.headline)
                if let meaning = VerbTable.meaning(verb.lemma) {
                    Text(verbatim: meaning.text(store.language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
            Spacer(minLength: 0)
            Text(verbatim: (learned ? Self.learnedText : Self.upcomingText).text(store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
            Image(systemName: "chevron.right")
                .foregroundStyle(.tertiary)
                .accessibilityHidden(true)
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.card))
        .contentShape(Rectangle())
    }

    static func fold(_ text: String) -> String {
        text.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: nil)
    }

    /// The infinitive, its meaning or any of its forms: "pongo" finds poner. Infinitives that start
    /// with the search come first, then the verbs the learner already knows.
    static func find(_ query: String, completed: Set<String>, language: NativeLanguage) -> [VerbEntry] {
        guard !query.isEmpty else { return [] }
        let matches = VerbBook.shared.verbs.filter { verb in
            if fold(verb.lemma).contains(query) { return true }
            if let meaning = VerbTable.meaning(verb.lemma), fold(meaning.text(language)).contains(query) { return true }
            guard query.count >= 3 else { return false }
            return TableTense.allCases.contains { tense in
                tense.forms(verb)?.contains { form in
                    let text = fold(form.text)
                    return text == query || text.split(separator: " ").last.map(String.init) == query
                } ?? false
            }
        }
        func rank(_ verb: VerbEntry) -> Int {
            (fold(verb.lemma).hasPrefix(query) ? 0 : 2) + (VerbTable.isLearned(verb.lemma, completed: completed) ? 0 : 1)
        }
        return matches.sorted { (rank($0), $0.lemma) < (rank($1), $1.lemma) }
    }

    static func unitText(_ tense: TableTense, language: NativeLanguage) -> String {
        guard let unit = tense.unit else { return "" }
        return unitLabel(unit.number).text(language)
    }

    static func unitLabel(_ number: Int) -> Gloss {
        Gloss(en: "Unit \(number)", it: "Unità \(number)", uk: "Розділ \(number)", de: "Einheit \(number)", fr: "Unité \(number)", pt: "Unidade \(number)", zh: "第\(number)单元")
    }

    static let intro = Gloss(en: "One folder per tense: how it is built, the model verbs and the irregulars to learn. Search any verb to see it in every tense.",
                             it: "Una cartella per ogni tempo: come si forma, i verbi modello e gli irregolari da imparare. Cerca un verbo per vederlo in tutti i tempi.",
                             uk: "Окрема тека для кожного часу: як він утворюється, зразкові дієслова й неправильні, які варто вивчити. Знайди будь-яке дієслово, щоб побачити його в усіх часах.",
                             de: "Ein Ordner pro Zeitform: wie sie gebildet wird, die Musterverben und die unregelmäßigen zum Lernen. Such ein Verb, um es in allen Zeiten zu sehen.",
                             fr: "Un dossier par temps : comment il se forme, les verbes modèles et les irréguliers à retenir. Cherche un verbe pour le voir à tous les temps.",
                             pt: "Uma pasta para cada tempo: como se forma, os verbos modelo e os irregulares para aprender. Busque um verbo para vê-lo em todos os tempos.",
                             zh: "每个时态一个文件夹：构成方法、示范动词和需要记住的不规则动词。搜索任意动词，查看它在所有时态中的变位。")
    static let searchText = Gloss(en: "Find a verb: tener, pongo…", it: "Cerca un verbo: tener, pongo…", uk: "Знайти дієслово: tener, pongo…", de: "Verb suchen: tener, pongo…", fr: "Chercher un verbe : tener, pongo…", pt: "Buscar um verbo: tener, pongo…", zh: "查找动词：tener、pongo…")
    static let learnedText = Gloss(en: "You know it", it: "Lo conosci", uk: "Ти його знаєш", de: "Kennst du", fr: "Tu le connais", pt: "Você já sabe", zh: "已学过")
    static let upcomingText = Gloss(en: "Coming up", it: "In arrivo", uk: "Попереду", de: "Kommt bald", fr: "Bientôt", pt: "Em breve", zh: "即将学到")
    static let noResultText = Gloss(en: "No verb found", it: "Nessun verbo trovato", uk: "Дієслово не знайдено", de: "Kein Verb gefunden", fr: "Aucun verbe trouvé", pt: "Nenhum verbo encontrado", zh: "没有找到动词")
    static let noResultHint = Gloss(en: "Try the infinitive (tener) or a form you saw (tengo).", it: "Prova con l'infinito (tener) o con una forma che hai visto (tengo).", uk: "Спробуй інфінітив (tener) або форму, яку ти бачив (tengo).", de: "Versuch es mit dem Infinitiv (tener) oder einer Form, die du gesehen hast (tengo).", fr: "Essaie l'infinitif (tener) ou une forme que tu as vue (tengo).", pt: "Tente o infinitivo (tener) ou uma forma que você viu (tengo).", zh: "试试不定式（tener）或你见过的变位形式（tengo）。")
}

// MARK: - One tense

/// A tense folder: the formula, the three model verbs side by side and the key irregulars.
struct TenseFolderView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.tone) private var tone
    let tense: TableTense

    private var book: VerbBook { .shared }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(verbatim: tense.spanishName).font(.title2.bold())
                    Text(verbatim: tense.name.text(store.language)).foregroundStyle(.secondary)
                }
                if !tense.isTaught(completed: store.state.completedLessons), let unit = tense.unit {
                    Label {
                        Text(verbatim: Self.aheadText(unit.number).text(store.language))
                    } icon: {
                        Image(systemName: "lock.fill")
                    }
                    .font(.footnote)
                    .foregroundStyle(tone.main)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(tone.soft))
                }
                section(Self.formulaTitle) {
                    Text(verbatim: tense.formula.text(store.language))
                        .font(.callout)
                        .fixedSize(horizontal: false, vertical: true)
                }
                section(Self.modelsTitle) {
                    if tense.isCompound { compoundModels } else { simpleModels }
                }
                section(tense.isCompound ? Self.participlesTitle : Self.irregularsTitle) {
                    if tense.isCompound { participles } else { irregulars }
                }
            }
            .padding(20)
        }
        .navigationTitle(tense.spanishName)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func section<Content: View>(_ title: Gloss, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: title.text(store.language), color: tone.main)
            content()
        }
    }

    private var models: [VerbEntry] { TableTense.models.compactMap { book.verb($0) } }

    /// hablar, comer and vivir in three columns: the endings line up, so the pattern shows.
    private var simpleModels: some View {
        let verbs = models
        return Grid(alignment: .leading, horizontalSpacing: 10, verticalSpacing: 8) {
            GridRow {
                Color.clear.frame(width: 1, height: 1)
                ForEach(verbs) { verb in
                    Text(verbatim: verb.lemma).font(.caption.weight(.bold)).foregroundStyle(.secondary)
                }
            }
            ForEach(Person.allCases) { person in
                GridRow {
                    Text(verbatim: person.label).font(.caption).foregroundStyle(.secondary)
                    ForEach(verbs) { verb in
                        if let form = verb.form(tense.base, person) {
                            ColoredForm(form: form, font: .callout.weight(.semibold))
                                .lineLimit(1).minimumScaleFactor(0.6)
                        }
                    }
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.card))
    }

    /// haber once, then the three participles: había + hablado / comido / vivido.
    private var compoundModels: some View {
        let haber = Person.allCases.map { person -> String in
            if let auxiliary = tense.auxiliary { return auxiliary[Person.allCases.firstIndex(of: person) ?? 0] }
            return models.first?.form(.perfecto, person)?.stem.split(separator: " ").first.map(String.init) ?? ""
        }
        return VStack(alignment: .leading, spacing: 12) {
            Grid(alignment: .leading, horizontalSpacing: 14, verticalSpacing: 8) {
                ForEach(Array(Person.allCases.enumerated()), id: \.element) { index, person in
                    GridRow {
                        Text(verbatim: person.label).font(.caption).foregroundStyle(.secondary)
                        Text(verbatim: haber[index]).font(.callout.weight(.semibold)).foregroundStyle(Brick.rail.color)
                    }
                }
            }
            Divider()
            HStack(spacing: 14) {
                Text(verbatim: "+").font(.headline).foregroundStyle(.secondary)
                ForEach(models) { verb in
                    if let participle = TableTense.participle(verb) {
                        ColoredForm(form: participle, font: .callout.weight(.semibold))
                    }
                }
            }
            if let example = models.first.flatMap({ tense.forms($0)?.first }) {
                Text(verbatim: "yo \(example.text)")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.card))
    }

    /// Verbs with the same forms share one card: "ser · ir" in the simple past.
    private var irregularGroups: [[VerbEntry]] {
        var groups: [[VerbEntry]] = []
        for lemma in tense.keyIrregulars {
            guard let verb = book.verb(lemma), tense.isIrregular(verb) else { continue }
            let forms = tense.forms(verb)
            if let index = groups.firstIndex(where: { tense.forms($0[0]) == forms }) {
                groups[index].append(verb)
            } else {
                groups.append([verb])
            }
        }
        return groups
    }

    private var irregulars: some View {
        VStack(spacing: 10) {
            ForEach(irregularGroups, id: \.first) { group in
                if let verb = group.first {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text(verbatim: group.map(\.lemma).joined(separator: " · ")).font(.headline)
                            Text(verbatim: group.compactMap { VerbTable.meaning($0.lemma)?.text(store.language) }.joined(separator: " · "))
                                .font(.subheadline).foregroundStyle(.secondary).lineLimit(1)
                        }
                        ConjugationGrid(forms: tense.forms(verb) ?? [])
                    }
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.card))
                }
            }
        }
    }

    /// hecho, dicho, visto…: the only part of a compound tense that can be irregular.
    private var participles: some View {
        let verbs = tense.keyIrregulars.compactMap { book.verb($0) }.filter { tense.isIrregular($0) }
        return VStack(spacing: 0) {
            ForEach(verbs) { verb in
                HStack {
                    Text(verbatim: verb.lemma).font(.body.weight(.semibold))
                    Spacer()
                    if let participle = TableTense.participle(verb) {
                        ColoredForm(form: participle, font: .body.weight(.semibold))
                    }
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                if verb != verbs.last { Divider().padding(.leading, 14) }
            }
        }
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(Palette.card))
    }

    static func aheadText(_ unit: Int) -> Gloss {
        Gloss(en: "You'll learn this tense in Unit \(unit). You can already take a look.",
              it: "Imparerai questo tempo nell'unità \(unit). Puoi già darci un'occhiata.",
              uk: "Цей час ти вивчиш у розділі \(unit). Але вже можеш зазирнути.",
              de: "Diese Zeitform lernst du in Einheit \(unit). Du kannst schon einen Blick hineinwerfen.",
              fr: "Tu apprendras ce temps dans l'unité \(unit). Tu peux déjà y jeter un œil.",
              pt: "Você vai aprender este tempo na unidade \(unit). Já pode dar uma olhada.",
              zh: "你会在第\(unit)单元学习这个时态，现在可以先看看。")
    }

    static let formulaTitle = Gloss(en: "Formula", it: "Formula", uk: "Формула", de: "Formel", fr: "Formule", pt: "Fórmula", zh: "构成规则")
    static let modelsTitle = Gloss(en: "Regular verbs: -ar, -er, -ir", it: "Verbi regolari: -ar, -er, -ir", uk: "Правильні дієслова: -ar, -er, -ir", de: "Regelmäßige Verben: -ar, -er, -ir", fr: "Verbes réguliers : -ar, -er, -ir", pt: "Verbos regulares: -ar, -er, -ir", zh: "规则动词：-ar、-er、-ir")
    static let irregularsTitle = Gloss(en: "Key irregulars", it: "Irregolari principali", uk: "Головні неправильні дієслова", de: "Wichtige unregelmäßige Verben", fr: "Irréguliers essentiels", pt: "Principais irregulares", zh: "常用不规则动词")
    static let participlesTitle = Gloss(en: "Irregular participles", it: "Participi irregolari", uk: "Неправильні дієприкметники", de: "Unregelmäßige Partizipien", fr: "Participes irréguliers", pt: "Particípios irregulares", zh: "不规则过去分词")
}

// MARK: - One verb

/// A verb from the search, in every tense. Tenses the path has not explained yet come last, marked.
struct VerbDetailView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.tone) private var tone
    let verb: VerbEntry

    var body: some View {
        let completed = store.state.completedLessons
        let taught = TableTense.allCases.filter { $0.isTaught(completed: completed) }
        let ahead = TableTense.allCases.filter { !$0.isTaught(completed: completed) }
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                HStack(alignment: .firstTextBaseline) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(verbatim: verb.lemma).font(.largeTitle.bold())
                        if let meaning = VerbTable.meaning(verb.lemma) {
                            Text(verbatim: meaning.text(store.language)).foregroundStyle(.secondary)
                        }
                    }
                    Spacer()
                    SpeakButton(text: verb.lemma)
                }
                ForEach(taught) { tense in
                    tenseCard(tense, locked: false)
                }
                if !ahead.isEmpty {
                    Eyebrow(text: TablesView.upcomingText.text(store.language))
                        .padding(.top, 8)
                    ForEach(ahead) { tense in
                        tenseCard(tense, locked: true)
                    }
                }
            }
            .padding(20)
        }
        .navigationTitle(verb.lemma)
        .navigationBarTitleDisplayMode(.inline)
    }

    private func tenseCard(_ tense: TableTense, locked: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(verbatim: tense.spanishName).font(.headline)
                if tense.isIrregular(verb) {
                    Text(verbatim: Self.irregularTag.text(store.language))
                        .font(.caption2.weight(.semibold))
                        .foregroundStyle(tone.main)
                        .padding(.horizontal, 6).padding(.vertical, 2)
                        .background(Capsule().fill(tone.soft))
                }
                Spacer(minLength: 0)
                if locked {
                    Label {
                        Text(verbatim: TablesView.unitText(tense, language: store.language))
                    } icon: {
                        Image(systemName: "lock.fill")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }
            Text(verbatim: tense.name.text(store.language))
                .font(.caption)
                .foregroundStyle(.secondary)
            ConjugationGrid(forms: tense.forms(verb) ?? [])
                .opacity(locked ? 0.55 : 1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Palette.card))
    }

    static let irregularTag = Gloss(en: "irregular", it: "irregolare", uk: "неправильне", de: "unregelmäßig", fr: "irrégulier", pt: "irregular", zh: "不规则")
}

/// Six forms in two columns, singular on the left and plural on the right, stem blue and ending orange.
/// An irregular form is all stem: learn it whole.
struct ConjugationGrid: View {
    let forms: [VerbForm]

    private static let rows: [[Person]] = [[.yo, .nosotros], [.tu, .vosotros], [.el, .ellos]]

    var body: some View {
        Grid(horizontalSpacing: 6, verticalSpacing: 6) {
            ForEach(Self.rows, id: \.self) { row in
                GridRow {
                    ForEach(row) { person in
                        cell(person)
                    }
                }
            }
        }
    }

    private func cell(_ person: Person) -> some View {
        let index = Person.allCases.firstIndex(of: person) ?? 0
        return VStack(alignment: .leading, spacing: 1) {
            Text(verbatim: person.label).font(.caption2).foregroundStyle(.secondary)
            if forms.indices.contains(index) {
                ColoredForm(form: forms[index], font: .callout.weight(.semibold))
                    .lineLimit(1).minimumScaleFactor(0.6)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .frame(maxWidth: .infinity, alignment: .leading)
        // A plain light cell keeps both colours of the form readable.
        .background(RoundedRectangle(cornerRadius: 8).fill(Color(.systemBackground)))
        .accessibilityElement(children: .combine)
    }
}
