import SwiftUI

/// "Carrera de verbos": write three whole verb tables as fast as you can. Each form moves on
/// by itself as soon as it's right; the clock stops at the last one. Beat your best time.
struct VerbRaceView: View {
    private enum Cell {
        case exact, accent, skipped
    }

    @EnvironmentObject private var store: AppStore
    @Environment(\.tone) private var tone
    @State private var started = false
    @State private var tables: [VerbRace.Table] = []
    @State private var meanings: [String: Gloss] = [:]
    @State private var tableIndex = 0
    @State private var cells: [Cell] = []
    @State private var text = ""
    @State private var skips = 0
    @State private var startedAt = Date()
    @State private var time = 0
    @State private var review: [GameResults.Review] = []
    @State private var written = 0
    @State private var moving = false
    @State private var finished = false
    @State private var newRecord = false
    @FocusState private var focused: Bool

    var body: some View {
        VStack(spacing: 20) {
            if !started {
                GameIntro(icon: "flag.checkered", rules: Self.rules.text(language), record: bestText, onStart: begin)
            } else if finished {
                GameResults(score: VerbRace.clock(time), newRecord: newRecord, record: bestText ?? "",
                            xp: VerbRace.xp(written: written), review: review,
                            emptyMessage: tables.isEmpty ? Self.nothingYet.text(language) : nil,
                            onAgain: begin)
            } else if tableIndex < tables.count {
                playing(tables[tableIndex])
            }
        }
        .padding(20)
        .navigationTitle("Carrera de verbos")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var language: NativeLanguage { store.language }

    private var bestText: String? {
        let best = store.best(in: LabGame.raceId)
        return best > 0 ? Self.bestTime.text(language) + " " + VerbRace.clock(best) : nil
    }

    // MARK: Playing

    private func playing(_ table: VerbRace.Table) -> some View {
        VStack(spacing: 16) {
            HStack {
                TimelineView(.periodic(from: startedAt, by: 1)) { context in
                    let seconds = Int(context.date.timeIntervalSince(startedAt)) + skips * VerbRace.skipPenalty
                    Label { Text(verbatim: VerbRace.clock(seconds)) } icon: { Image(systemName: "stopwatch") }
                        .monospacedDigit()
                        .accessibilityLabel(Self.timeSoFar.text(language) + " \(seconds)")
                }
                Spacer()
                Text(verbatim: "\(tableIndex + 1)/\(tables.count)")
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
            .font(.headline)
            VStack(spacing: 6) {
                Text(verbatim: table.verb.lemma)
                    .font(.system(.title, design: .rounded).weight(.bold))
                if let meaning = meanings[table.verb.lemma] {
                    Text(verbatim: meaning.text(language))
                        .foregroundStyle(.secondary)
                }
                Text(verbatim: "\(table.tense.name.text(language)) · \(table.tense.model)")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 6)
                    .background(Capsule().fill(tone.fill))
            }
            .frame(maxWidth: .infinity)
            VStack(spacing: 4) {
                ForEach(Array(table.persons.enumerated()), id: \.offset) { item in
                    tableRow(table, row: item.offset, person: item.element)
                }
            }
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 22, style: .continuous).fill(Palette.card))
            if cells.count < table.persons.count {
                let person = table.persons[cells.count]
                HStack {
                    Text(verbatim: person.label)
                        .font(.title3)
                        .foregroundStyle(.secondary)
                    TextField(GameTexts.writeHere.text(language), text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused)
                        .submitLabel(.next)
                        .font(.title3)
                        .onChange(of: text) { _, typed in check(typed, table: table) }
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))
                Button(Self.skip.text(language)) { skip(table) }
                    .disabled(moving)
            }
            Spacer(minLength: 0)
        }
        .onAppear { focused = true }
    }

    private func tableRow(_ table: VerbRace.Table, row: Int, person: Person) -> some View {
        let isCurrent = row == cells.count
        return HStack {
            Text(verbatim: person.label)
                .foregroundStyle(.secondary)
                .frame(width: 104, alignment: .leading)
            if row < cells.count {
                switch cells[row] {
                case .exact, .accent:
                    ColoredForm(form: table.form(person), font: .headline)
                    Spacer()
                    Image(systemName: "checkmark")
                        .foregroundStyle(Palette.success)
                        .accessibilityHidden(true)
                case .skipped:
                    Text(verbatim: table.form(person).text)
                        .font(.headline)
                        .foregroundStyle(Palette.warning)
                    Spacer()
                }
            } else {
                Text(verbatim: isCurrent ? "…" : "")
                    .font(.headline)
                    .foregroundStyle(tone.main)
                Spacer()
            }
        }
        .padding(.horizontal, 10)
        .frame(minHeight: 36)
        .background(RoundedRectangle(cornerRadius: 10).fill(isCurrent ? tone.soft : .clear))
        .accessibilityElement(children: .combine)
    }

    // MARK: Game flow

    private func begin() {
        let deck = VerbDeck(completed: store.state.completedLessons, words: store.learnedWords)
        meanings = deck.meanings
        tables = VerbRace.tables(deck: deck, weak: Set(store.weakForms))
        tableIndex = 0
        cells = []
        text = ""
        skips = 0
        written = 0
        review = []
        moving = false
        newRecord = false
        finished = tables.isEmpty
        started = true
        startedAt = Date()
        focused = true
    }

    private func check(_ typed: String, table: VerbRace.Table) {
        guard !moving, cells.count < table.persons.count else { return }
        let person = table.persons[cells.count]
        let form = table.form(person)
        guard VerbRace.matches(typed, form) else { return }
        let exact = VerbRace.isExact(typed, form)
        cells.append(exact ? .exact : .accent)
        written += 1
        if !exact {
            review.append(GameResults.Review(prompt: "\(person.label) · \(table.tense.name.text(language))", answer: form.text))
        }
        store.recordForms([table.verb.key(table.tense, person)], correct: true)
        text = ""
        nextStep(table)
    }

    private func skip(_ table: VerbRace.Table) {
        guard !moving, cells.count < table.persons.count else { return }
        let person = table.persons[cells.count]
        cells.append(.skipped)
        skips += 1
        review.append(GameResults.Review(prompt: "\(person.label) · \(table.tense.name.text(language))", answer: table.form(person).text))
        store.recordForms([table.verb.key(table.tense, person)], correct: false)
        text = ""
        nextStep(table)
    }

    /// After the last form of a table, a short pause to see it whole, then the next table.
    private func nextStep(_ table: VerbRace.Table) {
        guard cells.count == table.persons.count else { return }
        moving = true
        let end = Date()
        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 450_000_000)
            moving = false
            if tableIndex + 1 < tables.count {
                // The pause between tables doesn't count.
                startedAt = startedAt.addingTimeInterval(Date().timeIntervalSince(end))
                tableIndex += 1
                cells = []
                focused = true
            } else {
                finish(at: end)
            }
        }
    }

    private func finish(at end: Date) {
        time = VerbRace.time(elapsed: end.timeIntervalSince(startedAt), skips: skips)
        focused = false
        newRecord = written > 0 && store.recordTime(time, in: LabGame.raceId)
        store.addXP(VerbRace.xp(written: written))
        finished = true
    }

    static let rules = Gloss(en: "Three verbs, every person. Write each form: it moves on by itself when it's right. Showing a form adds \(VerbRace.skipPenalty) seconds. Beat your best time.",
                             it: "Tre verbi, tutte le persone. Scrivi ogni forma: si va avanti da soli quando è giusta. Mostrare una forma aggiunge \(VerbRace.skipPenalty) secondi. Batti il tuo miglior tempo.",
                             uk: "Три дієслова, усі особи. Пиши кожну форму: коли вона правильна, гра йде далі сама. Підказка додає \(VerbRace.skipPenalty) секунд. Побий свій найкращий час.",
                             de: "Drei Verben, alle Personen. Schreib jede Form: Wenn sie stimmt, geht es von selbst weiter. Eine Form anzeigen kostet \(VerbRace.skipPenalty) Sekunden. Schlag deine Bestzeit.",
                             fr: "Trois verbes, toutes les personnes. Écris chaque forme : on passe à la suivante tout seul quand elle est juste. Afficher une forme ajoute \(VerbRace.skipPenalty) secondes. Bats ton meilleur temps.",
                             pt: "Três verbos, todas as pessoas. Escreva cada forma: quando estiver certa, o jogo avança sozinho. Mostrar uma forma soma \(VerbRace.skipPenalty) segundos. Supere seu melhor tempo.",
                             zh: "三个动词，所有人称。写出每个形式：写对了会自动跳到下一个。查看答案会加 \(VerbRace.skipPenalty) 秒。打破你的最好成绩。")
    static let skip = Gloss(en: "Show me (+\(VerbRace.skipPenalty) s)", it: "Mostramela (+\(VerbRace.skipPenalty) s)", uk: "Показати (+\(VerbRace.skipPenalty) с)", de: "Zeigen (+\(VerbRace.skipPenalty) s)", fr: "Montre-moi (+\(VerbRace.skipPenalty) s)", pt: "Mostrar (+\(VerbRace.skipPenalty) s)", zh: "显示答案（+\(VerbRace.skipPenalty) 秒）")
    static let bestTime = Gloss(en: "Your best time:", it: "Il tuo miglior tempo:", uk: "Твій найкращий час:", de: "Deine Bestzeit:", fr: "Ton meilleur temps :", pt: "Seu melhor tempo:", zh: "你的最好成绩：")
    static let timeSoFar = Gloss(en: "Seconds so far:", it: "Secondi finora:", uk: "Секунд минуло:", de: "Bisherige Sekunden:", fr: "Secondes écoulées :", pt: "Segundos até agora:", zh: "已用秒数：")
    static let nothingYet = Gloss(en: "This race needs every person: finish the lesson on vosotros in Unit 2 to play.",
                                  it: "Questa gara ha bisogno di tutte le persone: finisci la lezione su vosotros dell'Unità 2 per giocare.",
                                  uk: "Для цих перегонів потрібні всі особи: пройди урок про vosotros у розділі 2, щоб грати.",
                                  de: "Für dieses Rennen brauchst du alle Personen: Schließ die Lektion zu vosotros in Einheit 2 ab.",
                                  fr: "Cette course a besoin de toutes les personnes : termine la leçon sur vosotros de l'unité 2 pour jouer.",
                                  pt: "Esta corrida precisa de todas as pessoas: termine a lição de vosotros da Unidade 2 para jogar.",
                                  zh: "这个比赛需要所有人称：完成第 2 单元关于 vosotros 的课就可以玩了。")
}
