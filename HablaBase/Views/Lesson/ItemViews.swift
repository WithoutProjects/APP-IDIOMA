import SwiftUI

// MARK: - Vocabulary

/// New words, one per slide: the Spanish word, its translation, and nothing else.
struct VocabSlidesView: View {
    let set: VocabSet
    let language: NativeLanguage
    let onContinue: () -> Void
    @State var page = 0

    var body: some View {
        VStack(spacing: 20) {
            Text("New words")
                .font(.title2.weight(.semibold))
                .frame(maxWidth: .infinity, alignment: .leading)

            TabView(selection: $page) {
                ForEach(Array(set.words.enumerated()), id: \.offset) { index, word in
                    VStack(spacing: 14) {
                        Text(word.es)
                            .font(.system(.largeTitle, design: .rounded).weight(.bold))
                            .multilineTextAlignment(.center)
                            .minimumScaleFactor(0.6)
                            .foregroundStyle(word.kind.color)
                        Text(word.gloss.text(language))
                            .font(.title2)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(RoundedRectangle(cornerRadius: 24).fill(Palette.card))
                    .padding(.horizontal, 4)
                    .accessibilityElement(children: .combine)
                    .tag(index)
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            .frame(height: 280)

            Button(page < set.words.count - 1 ? language.localized("Next") : language.localized("Practise these words")) {
                if page < set.words.count - 1 {
                    withAnimation { page += 1 }
                } else {
                    onContinue()
                }
            }
            .buttonStyle(PrimaryButtonStyle())
        }
    }
}

/// Match each new word with its translation. Mixing two up sends the set back to Fix.
struct VocabMatchView: View {
    let set: VocabSet
    let language: NativeLanguage
    let onSubmit: (GradeOutcome) -> Void
    @State var words: [VocabWord] = []
    @State var translations: [VocabWord] = []
    @State var selected: VocabWord?
    @State var matched: Set<String> = []
    @State var wrong: VocabWord?
    @State var confused: [VocabWord] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Match each word with its translation.")
                .font(.title2.weight(.semibold))
            HStack(alignment: .top, spacing: 12) {
                VStack(spacing: 10) {
                    ForEach(words, id: \.self) { word in
                        card(word.es, done: matched.contains(word.es), highlighted: selected == word, warning: false) {
                            selected = word
                        }
                    }
                }
                VStack(spacing: 10) {
                    ForEach(translations, id: \.self) { word in
                        card(word.gloss.text(language), done: matched.contains(word.es), highlighted: false, warning: wrong == word) {
                            pick(word)
                        }
                        .disabled(selected == nil)
                    }
                }
            }
        }
        .onAppear {
            if words.isEmpty {
                words = set.words.shuffled()
                translations = set.words.shuffled()
            }
        }
    }

    private func card(_ text: String, done: Bool, highlighted: Bool, warning: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(text)
                .font(.body.weight(.semibold))
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity, minHeight: 52)
                .padding(.horizontal, 6)
                .background(RoundedRectangle(cornerRadius: 12).fill(warning ? Palette.warning.opacity(0.25) : highlighted ? Brick.stem.color.opacity(0.18) : Palette.card))
                .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(highlighted ? Brick.stem.color : .clear, lineWidth: 2))
        }
        .buttonStyle(.plain)
        .opacity(done ? 0.25 : 1)
        .disabled(done)
        .accessibilityAddTraits(highlighted ? .isSelected : [])
    }

    private func pick(_ translation: VocabWord) {
        guard let word = selected else { return }
        if word == translation {
            withAnimation(.spring(response: 0.3)) { matched.insert(word.es) }
            selected = nil
            if matched.count == set.words.count { finish() }
        } else {
            if !confused.contains(word) { confused.append(word) }
            withAnimation(.easeInOut(duration: 0.2)) { wrong = translation }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation { wrong = nil }
            }
        }
    }

    private func finish() {
        if confused.isEmpty {
            onSubmit(.correct)
        } else {
            let pairs = confused.map { "\($0.es) = \($0.gloss.text(language))" }.joined(separator: " · ")
            onSubmit(.wrong(hint: pairs))
        }
    }
}

// MARK: - Frame

/// An explanation: habl- + -o = hablo, one rule, a few examples.
struct FrameCardView: View {
    let card: FrameCard
    let language: NativeLanguage
    let onContinue: () -> Void
    @State var snapped = false
    /// False when the card is reopened from an exercise ("See explanation").
    var showsButton = true

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            FlowLayout(spacing: 10) {
                ForEach(Array(card.bricks.enumerated()), id: \.offset) { index, brick in
                    if index > 0 {
                        Text(verbatim: "+").font(.title2.bold())
                    }
                    BrickView(text: brick.text, kind: brick.kind)
                }
                if let result = card.result {
                    Text(verbatim: "=").font(.title2.bold())
                    ColoredForm(form: result, font: .title.bold())
                        .opacity(snapped ? 1 : 0)
                        .scaleEffect(snapped ? 1 : 0.6)
                }
            }
            .frame(maxWidth: .infinity)
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.6).delay(0.4)) { snapped = true }
            }

            Text(card.rule.text(language))
                .font(.title3.weight(.semibold))

            VStack(alignment: .leading, spacing: 12) {
                ForEach(card.examples, id: \.self) { example in
                    HStack(alignment: .top) {
                        VStack(alignment: .leading, spacing: 2) {
                            GlossedText(text: example.es, font: .body.weight(.medium))
                            Text(example.gloss.text(language)).font(.footnote).foregroundStyle(.secondary)
                        }
                        Spacer(minLength: 0)
                        SpeakButton(text: example.es)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))

            if showsButton {
                Button("Got it", action: onContinue)
                    .buttonStyle(PrimaryButtonStyle())
            }
        }
    }
}

// MARK: - Lego Snap

/// Tap a blue stem and an orange ending to snap them together for the person shown.
struct LegoSnapView: View {
    let snap: LegoSnap
    let language: NativeLanguage
    let onSubmit: (GradeOutcome) -> Void
    var onHint: () -> Void = {}
    @State var stem: String?
    @State var ending: String?
    @State var hintLevel = 0

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Image(systemName: "person.fill")
                    .accessibilityHidden(true)
                Text(snap.person.label).font(.headline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Palette.card))

            Text("Build: \u{201C}\(snap.prompt.text(language))\u{201D}")
                .font(.title2.weight(.semibold))

            HStack(spacing: 10) {
                BrickView(text: stem.map { $0 + "-" } ?? "?", kind: .stem, isGhost: stem == nil)
                Text(verbatim: "+").font(.title2.bold())
                BrickView(text: ending.map { "-" + $0 } ?? "?", kind: .ending, isGhost: ending == nil)
                if let stem, let ending {
                    Text(verbatim: "=").font(.title2.bold())
                    ColoredForm(form: VerbForm(stem: stem, ending: ending), font: .title2.bold())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))
            .animation(.spring(response: 0.3), value: stem)
            .animation(.spring(response: 0.3), value: ending)

            tray("Stems", items: snap.stems, kind: .stem, selected: stem) { stem = $0 }
            tray("Endings", items: snap.endings, kind: .ending, selected: ending) { ending = $0 }

            if hintLevel > 0 {
                HintBox {
                    BrickView(text: snap.answer.stem + "-", kind: .stem)
                    if hintLevel > 1 {
                        Text(verbatim: "+").font(.title3.bold())
                        BrickView(text: "-" + snap.answer.ending, kind: .ending)
                    }
                }
            }
            HintButton(level: $hintLevel, onUse: onHint)

            Button("Check") { check() }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(stem == nil || ending == nil)
                .opacity(stem == nil || ending == nil ? 0.4 : 1)
        }
    }

    private func tray(_ title: LocalizedStringKey, items: [String], kind: Brick, selected: String?, pick: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.bold)).foregroundStyle(.secondary)
            FlowLayout(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Button { pick(item) } label: {
                        BrickView(text: kind == .stem ? item + "-" : "-" + item, kind: kind, isGhost: selected != item)
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected == item ? .isSelected : [])
                }
            }
        }
    }

    private func check() {
        guard let stem, let ending else { return }
        if stem == snap.answer.stem && ending == snap.answer.ending {
            onSubmit(.correct)
        } else if stem != snap.answer.stem, let other = Unit1.verbs.first(where: { $0.stem == stem }) {
            let meaning = other.meaning.text(language), goal = snap.prompt.text(language)
            onSubmit(.wrong(hint: Gloss(en: "\(stem)- means \u{201C}\(meaning)\u{201D}. Find the stem for \u{201C}\(goal)\u{201D}.",
                                        it: "\(stem)- significa \u{201C}\(meaning)\u{201D}. Trova la radice per \u{201C}\(goal)\u{201D}.",
                                        uk: "\(stem)- означає \u{201C}\(meaning)\u{201D}. Знайди основу для \u{201C}\(goal)\u{201D}.",
                                        de: "\(stem)- bedeutet \u{201E}\(meaning)\u{201C}. Finde den Stamm für \u{201E}\(goal)\u{201C}.").text(language)))
        } else {
            onSubmit(.wrong(hint: Gloss(en: "With \(snap.person.label), the ending is -\(snap.answer.ending).",
                                        it: "Con \(snap.person.label), la desinenza è -\(snap.answer.ending).",
                                        uk: "Для \(snap.person.label) закінчення -\(snap.answer.ending).",
                                        de: "Bei \(snap.person.label) lautet die Endung -\(snap.answer.ending).").text(language)))
        }
    }
}

// MARK: - Context Gap

/// Type or say the missing verb; who is speaking and the context decide the form.
struct GapFillView: View {
    let gap: GapFill
    let language: NativeLanguage
    let onSubmit: (GradeOutcome) -> Void
    var onHint: () -> Void = {}
    @State var text = ""
    @FocusState var focused: Bool
    @State var hintLevel = 0
    @AppStorage("answerByVoice") private var byVoice = false

    private static let blank = "\u{0}"

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Complete the sentence.")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                FlowLayout(spacing: 5) {
                    ForEach(Array(sentenceWords.enumerated()), id: \.offset) { _, word in
                        if word == Self.blank {
                            Text(verbatim: "_____").foregroundStyle(Brick.ending.color).font(.title3.weight(.medium))
                        } else {
                            GlossedWord(word: word, font: .title3.weight(.medium))
                        }
                    }
                }
                Text(gap.gloss.text(language))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))

            AnswerModePicker(byVoice: $byVoice)
                .onChange(of: byVoice) { _, voice in
                    text = ""
                    focused = !voice
                }

            if byVoice {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Say the missing word (\(gap.lemma)).")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    VoiceAnswerView(text: $text)
                }
            } else {
                HStack {
                    TextField(gap.lemma, text: $text)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        .focused($focused)
                        .submitLabel(.done)
                        .onSubmit(check)
                        .font(.title3)
                    Text(gap.lemma)
                        .font(.caption.weight(.semibold))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(Brick.stem.color.opacity(0.15)))
                }
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.secondary.opacity(0.4)))
            }

            if hintLevel > 0, let form = answerForm {
                HintBox {
                    BrickView(text: form.stem + "-", kind: .stem)
                    if hintLevel > 1, let first = form.ending.first {
                        Text(verbatim: "+").font(.title3.bold())
                        BrickView(text: "-\(first)…", kind: .ending)
                    }
                }
            }
            if answerForm != nil {
                HintButton(level: $hintLevel, onUse: onHint)
            }

            Button("Check", action: check)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isEmpty)
                .opacity(isEmpty ? 0.4 : 1)
        }
        .onAppear { focused = !byVoice }
    }

    private var sentenceWords: [String] {
        gap.before.split(separator: " ").map(String.init) + [Self.blank] + gap.after.split(separator: " ").map(String.init)
    }

    /// The answer split into stem and ending, for hints.
    private var answerForm: VerbForm? {
        let stem = String(gap.lemma.dropLast(2))
        let answer = gap.accepted[0]
        guard answer.hasPrefix(stem), answer.count > stem.count else { return nil }
        return VerbForm(stem: stem, ending: String(answer.dropFirst(stem.count)))
    }

    private var isEmpty: Bool { text.trimmingCharacters(in: .whitespaces).isEmpty }

    private func check() {
        guard !isEmpty else { return }
        focused = false
        let hint = gap.hint.text(language)
        onSubmit(byVoice ? Grader.compareSpokenPhrase(text, accepted: gap.accepted, hint: hint)
                         : Grader.compare(text, accepted: gap.accepted, hint: hint))
    }
}

// MARK: - Choice

/// Pick the word that completes the sentence. Hints grey out wrong options, one per step.
struct ChoiceView: View {
    let choice: Choice
    let language: NativeLanguage
    let onSubmit: (GradeOutcome) -> Void
    var onHint: () -> Void = {}
    @State var selected: String?
    @State var hintLevel = 0
    @State var options: [String] = []

    private static let blank = "\u{0}"

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text("Choose the right word.")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                FlowLayout(spacing: 5) {
                    ForEach(Array(sentenceWords.enumerated()), id: \.offset) { _, word in
                        if word == Self.blank {
                            Text(verbatim: selected ?? "_____")
                                .foregroundStyle(Brick.ending.color)
                                .font(.title3.weight(.semibold))
                        } else {
                            GlossedWord(word: word, font: .title3.weight(.medium))
                        }
                    }
                }
                Text(choice.gloss.text(language))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))

            VStack(spacing: 10) {
                ForEach(options, id: \.self) { option in
                    let ruledOut = ruledOutOptions.contains(option)
                    Button { selected = option } label: {
                        Text(option)
                            .font(.title3.weight(.semibold))
                            .frame(maxWidth: .infinity, minHeight: 52)
                            .background(RoundedRectangle(cornerRadius: 14).fill(selected == option ? Brick.ending.color.opacity(0.2) : Palette.card))
                            .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(selected == option ? Brick.ending.color : .clear, lineWidth: 2))
                    }
                    .buttonStyle(.plain)
                    .opacity(ruledOut ? 0.3 : 1)
                    .disabled(ruledOut)
                    .accessibilityAddTraits(selected == option ? .isSelected : [])
                }
            }

            if options.count > 2 {
                HintButton(level: $hintLevel, onUse: onHint)
            }

            Button("Check") {
                guard let selected else { return }
                onSubmit(selected == choice.answer ? .correct : .wrong(hint: choice.hint.text(language)))
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(selected == nil)
            .opacity(selected == nil ? 0.4 : 1)
        }
        .onAppear {
            if options.isEmpty { options = choice.options.shuffled() }
        }
        .onChange(of: hintLevel) { _, _ in
            if let selected, ruledOutOptions.contains(selected) { self.selected = nil }
        }
    }

    private var sentenceWords: [String] {
        choice.before.split(separator: " ").map(String.init) + [Self.blank] + choice.after.split(separator: " ").map(String.init)
    }

    /// Each hint step rules out one wrong option, always leaving at least two.
    private var ruledOutOptions: [String] {
        let wrong = choice.options.filter { $0 != choice.answer }
        return Array(wrong.prefix(min(hintLevel, choice.options.count - 2)))
    }
}

// MARK: - Sentence Builder

/// The Builder Bar: tap chunk tiles into place to say what the prompt asks for, or say it out loud.
struct SentenceBuilderView: View {
    let builder: SentenceBuilder
    let language: NativeLanguage
    let onSubmit: (GradeOutcome) -> Void
    var onHint: () -> Void = {}
    /// Indices into builder.tiles, in the order the learner placed them.
    @State var placed: [Int] = []
    @State var hintLevel = 0
    @State var spoken = ""
    @AppStorage("answerByVoice") private var byVoice = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(builder.intention.text(language))
                .font(.title2.weight(.semibold))

            AnswerModePicker(byVoice: $byVoice)
                .onChange(of: byVoice) { _, _ in spoken = "" }

            if byVoice {
                VoiceAnswerView(text: $spoken)
            } else {
                tiles
            }

            if hintLevel > 0, let ordered = builder.orderedTiles {
                HintBox {
                    Text("Start with:")
                    Text(verbatim: ordered.prefix(hintLevel).joined(separator: " ") + " …").fontWeight(.semibold)
                }
            }
            if builder.orderedTiles != nil {
                HintButton(level: $hintLevel, onUse: onHint)
            }

            Button("Check") {
                let hint = builder.hint.text(language)
                if byVoice {
                    onSubmit(Grader.compareSpokenSentence(spoken, accepted: builder.accepted, hint: hint))
                } else {
                    let sentence = placed.map { builder.tiles[$0] }.joined(separator: " ")
                    onSubmit(Grader.compare(sentence, accepted: builder.accepted, hint: hint))
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isEmpty)
            .opacity(isEmpty ? 0.4 : 1)
        }
    }

    private var isEmpty: Bool { byVoice ? spoken.isEmpty : placed.isEmpty }

    private var tiles: some View {
        VStack(alignment: .leading, spacing: 24) {
            FlowLayout(spacing: 8) {
                ForEach(placed, id: \.self) { index in
                    Button { placed.removeAll { $0 == index } } label: { tile(builder.tiles[index], ghost: false) }
                        .buttonStyle(.plain)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 64, alignment: .topLeading)
            .padding(12)
            .background(RoundedRectangle(cornerRadius: 16).strokeBorder(Color.secondary.opacity(0.4), style: StrokeStyle(lineWidth: 1.5, dash: [6])))

            FlowLayout(spacing: 8) {
                ForEach(builder.tiles.indices, id: \.self) { index in
                    let used = placed.contains(index)
                    Button { if !used { placed.append(index) } } label: { tile(builder.tiles[index], ghost: used) }
                        .buttonStyle(.plain)
                        .disabled(used)
                }
            }
        }
    }

    private func tile(_ text: String, ghost: Bool) -> some View {
        Text(text)
            .font(.body.weight(.medium))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .foregroundStyle(ghost ? Color.clear : Color.primary)
            .background(RoundedRectangle(cornerRadius: 10).fill(ghost ? Palette.card : Color(.systemBackground)))
            .overlay(RoundedRectangle(cornerRadius: 10).strokeBorder(Color.secondary.opacity(ghost ? 0.15 : 0.35)))
    }
}

// MARK: - Free write

/// Translate a sentence from the learner's language into Spanish, typed or out loud.
struct FreeWriteView: View {
    let write: FreeWrite
    let language: NativeLanguage
    let onSubmit: (GradeOutcome) -> Void
    var onHint: () -> Void = {}
    @State var text = ""
    @FocusState var focused: Bool
    @State var hintLevel = 0
    @AppStorage("answerByVoice") private var byVoice = false

    var body: some View {
        let prompt = TranslationPrompt(write.instruction.text(language))
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 8) {
                if let sentence = prompt.sentence {
                    Text("Translate into Spanish")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.secondary)
                    if !prompt.context.isEmpty {
                        Text(prompt.context)
                            .font(.subheadline)
                    }
                    Text(sentence)
                        .font(.title2.weight(.semibold))
                } else {
                    Text(prompt.context)
                        .font(.title2.weight(.semibold))
                }
            }

            AnswerModePicker(byVoice: $byVoice)
                .onChange(of: byVoice) { _, voice in
                    text = ""
                    focused = !voice
                }

            if byVoice {
                VoiceAnswerView(text: $text)
            } else {
                TextField("Escribe aquí…", text: $text, axis: .vertical)
                    .lineLimit(3...6)
                    .textInputAutocapitalization(.sentences)
                    .autocorrectionDisabled()
                    .focused($focused)
                    .padding()
                    .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))
            }

            if hintLevel > 0 {
                HintBox {
                    Text(verbatim: hintLevel == 1 ? firstHint : write.model.es)
                }
            }
            HintButton(level: $hintLevel, onUse: onHint)

            Button("Check") {
                focused = false
                onSubmit(grade())
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(isEmpty)
            .opacity(isEmpty ? 0.4 : 1)
        }
        .onAppear { focused = !byVoice }
    }

    private var isEmpty: Bool { text.trimmingCharacters(in: .whitespaces).isEmpty }

    /// First hint: the required chunks, or the start of the answer.
    private var firstHint: String {
        if !write.requiredChunks.isEmpty {
            return write.requiredChunks.filter { $0 != "y" }.joined(separator: " · ")
        }
        let words = write.model.es.split(separator: " ")
        return words.prefix(max(1, words.count / 2)).joined(separator: " ") + " …"
    }

    private func grade() -> GradeOutcome {
        if !write.accepted.isEmpty {
            let hint = Gloss(en: "Compare with the right answer below.", it: "Confronta con la risposta giusta qui sotto.", uk: "Порівняй із правильною відповіддю нижче.", de: "Vergleiche mit der richtigen Antwort unten.").text(language)
            return byVoice ? Grader.compareSpokenSentence(text, accepted: write.accepted, hint: hint)
                           : Grader.compare(text, accepted: write.accepted, hint: hint)
        }
        if let missing = Grader.missingChunk(in: text, required: write.requiredChunks) {
            let hint = missing == "y"
                ? Gloss(en: "Join the parts with y.", it: "Unisci le parti con y.", uk: "З'єднай частини за допомогою y.", de: "Verbinde die Teile mit y.")
                : Gloss(en: "Missing: \u{201C}\(missing)\u{201D}", it: "Manca: \u{201C}\(missing)\u{201D}", uk: "Бракує: \u{201C}\(missing)\u{201D}", de: "Es fehlt: \u{201E}\(missing)\u{201C}")
            return .wrong(hint: hint.text(language))
        }
        return .correct
    }
}

/// "Context. Write in Spanish: «sentence»" split into the context and the sentence to translate,
/// so the sentence can stand out whether the learner types or speaks.
struct TranslationPrompt {
    let context: String
    let sentence: String?

    private static let markers = ["Write in Spanish:", "Scrivi in spagnolo:", "Напиши іспанською:", "Schreib auf Spanisch:"]

    init(_ instruction: String) {
        guard let open = instruction.range(of: "«", options: .backwards),
              let close = instruction.range(of: "»", options: .backwards), open.upperBound <= close.lowerBound else {
            context = instruction
            sentence = nil
            return
        }
        var before = String(instruction[..<open.lowerBound])
        for marker in Self.markers {
            before = before.replacingOccurrences(of: marker, with: "")
        }
        context = before.trimmingCharacters(in: .whitespaces)
        sentence = String(instruction[open.upperBound..<close.lowerBound]).trimmingCharacters(in: .whitespaces)
    }
}

// MARK: - Layout

/// Wraps tiles onto as many lines as they need.
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = arrange(width: proposal.width ?? .infinity, subviews: subviews)
        let height = rows.map(\.height).reduce(0, +) + spacing * CGFloat(max(rows.count - 1, 0))
        let width = rows.map(\.width).max() ?? 0
        return CGSize(width: proposal.width ?? width, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var y = bounds.minY
        for row in arrange(width: bounds.width, subviews: subviews) {
            var x = bounds.minX
            for index in row.indices {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + spacing
            }
            y += row.height + spacing
        }
    }

    private struct Row {
        var indices: [Int] = []
        var width: CGFloat = 0
        var height: CGFloat = 0
    }

    private func arrange(width: CGFloat, subviews: Subviews) -> [Row] {
        var rows: [Row] = []
        var row = Row()
        for index in subviews.indices {
            let size = subviews[index].sizeThatFits(.unspecified)
            let needed = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            if needed > width, !row.indices.isEmpty {
                rows.append(row)
                row = Row()
            }
            row.width = row.indices.isEmpty ? size.width : row.width + spacing + size.width
            row.height = max(row.height, size.height)
            row.indices.append(index)
        }
        if !row.indices.isEmpty { rows.append(row) }
        return rows
    }
}
