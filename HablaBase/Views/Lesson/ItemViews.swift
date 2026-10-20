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
                            .font(.system(size: 40, weight: .bold, design: .rounded))
                            .foregroundStyle(word.kind.color)
                        Text(word.gloss.text(language))
                            .font(.title2)
                            .foregroundStyle(.secondary)
                    }
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

            Button(page < set.words.count - 1 ? "Next" : "Practise these words") {
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

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            FlowLayout(spacing: 10) {
                ForEach(Array(card.bricks.enumerated()), id: \.offset) { index, brick in
                    if index > 0 {
                        Text("+").font(.title2.bold())
                    }
                    BrickView(text: brick.text, kind: brick.kind)
                }
                if let result = card.result {
                    Text("=").font(.title2.bold())
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
                    VStack(alignment: .leading, spacing: 2) {
                        Text(example.es).font(.body.weight(.medium))
                        Text(example.gloss.text(language)).font(.footnote).foregroundStyle(.secondary)
                    }
                }
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))

            Button("Got it", action: onContinue)
                .buttonStyle(PrimaryButtonStyle())
        }
    }
}

// MARK: - Lego Snap

/// Tap a blue stem and an orange ending to snap them together for the person shown.
struct LegoSnapView: View {
    let snap: LegoSnap
    let language: NativeLanguage
    let onSubmit: (GradeOutcome) -> Void
    @State var stem: String?
    @State var ending: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack {
                Image(systemName: "person.fill")
                Text(snap.person.label).font(.headline)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Capsule().fill(Palette.card))

            Text("Build: \u{201C}\(snap.prompt.text(language))\u{201D}")
                .font(.title2.weight(.semibold))

            HStack(spacing: 10) {
                BrickView(text: stem.map { $0 + "-" } ?? "?", kind: .stem, isGhost: stem == nil)
                Text("+").font(.title2.bold())
                BrickView(text: ending.map { "-" + $0 } ?? "?", kind: .ending, isGhost: ending == nil)
                if let stem, let ending {
                    Text("=").font(.title2.bold())
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

            Button("Check") { check() }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(stem == nil || ending == nil)
                .opacity(stem == nil || ending == nil ? 0.4 : 1)
        }
    }

    private func tray(_ title: String, items: [String], kind: Brick, selected: String?, pick: @escaping (String) -> Void) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.caption.weight(.bold)).foregroundStyle(.secondary)
            HStack(spacing: 8) {
                ForEach(items, id: \.self) { item in
                    Button { pick(item) } label: {
                        BrickView(text: kind == .stem ? item + "-" : "-" + item, kind: kind, isGhost: selected != item)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }

    private func check() {
        guard let stem, let ending else { return }
        if stem == snap.answer.stem && ending == snap.answer.ending {
            onSubmit(.correct)
        } else if stem != snap.answer.stem, let other = Unit1.verbs.first(where: { $0.stem == stem }) {
            onSubmit(.wrong(hint: "\(stem)- means \u{201C}\(other.meaning.text(language))\u{201D}. Find the stem for \u{201C}\(snap.prompt.text(language))\u{201D}."))
        } else {
            onSubmit(.wrong(hint: "With \(snap.person.label), the ending is -\(snap.answer.ending)."))
        }
    }
}

// MARK: - Context Gap

/// Type the missing verb; who is speaking and the context decide the form.
struct GapFillView: View {
    let gap: GapFill
    let language: NativeLanguage
    let onSubmit: (GradeOutcome) -> Void
    @State var text = ""
    @FocusState var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(language == .english ? "Complete the sentence." : "Completa la frase.")
                .font(.title2.weight(.semibold))

            VStack(alignment: .leading, spacing: 8) {
                (Text(gap.before) + Text("_____").foregroundColor(Brick.ending.color) + Text(gap.after))
                    .font(.title3.weight(.medium))
                Text(gap.gloss.text(language))
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))

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

            Button("Check", action: check)
                .buttonStyle(PrimaryButtonStyle())
                .disabled(isEmpty)
                .opacity(isEmpty ? 0.4 : 1)
        }
        .onAppear { focused = true }
    }

    private var isEmpty: Bool { text.trimmingCharacters(in: .whitespaces).isEmpty }

    private func check() {
        guard !isEmpty else { return }
        focused = false
        onSubmit(Grader.compare(text, accepted: gap.accepted, hint: gap.hint.text(language)))
    }
}

// MARK: - Sentence Builder

/// The Builder Bar: tap chunk tiles into place to say what the prompt asks for.
struct SentenceBuilderView: View {
    let builder: SentenceBuilder
    let language: NativeLanguage
    let onSubmit: (GradeOutcome) -> Void
    /// Indices into builder.tiles, in the order the learner placed them.
    @State var placed: [Int] = []

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(builder.intention.text(language))
                .font(.title2.weight(.semibold))

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

            Button("Check") {
                let sentence = placed.map { builder.tiles[$0] }.joined(separator: " ")
                onSubmit(Grader.compare(sentence, accepted: builder.accepted, hint: builder.hint.text(language)))
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(placed.isEmpty)
            .opacity(placed.isEmpty ? 0.4 : 1)
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

/// The output step: write the whole thing in one go.
struct FreeWriteView: View {
    let write: FreeWrite
    let language: NativeLanguage
    let onSubmit: (GradeOutcome) -> Void
    @State var text = ""
    @FocusState var focused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(write.instruction.text(language))
                .font(.title2.weight(.semibold))

            TextField("Escribe aquí…", text: $text, axis: .vertical)
                .lineLimit(3...6)
                .textInputAutocapitalization(.sentences)
                .autocorrectionDisabled()
                .focused($focused)
                .padding()
                .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))

            Button("Check") {
                focused = false
                if let missing = Grader.missingChunk(in: text, required: write.requiredChunks) {
                    let hint = missing == "y" ? "Join the parts with y." : "Missing: \u{201C}\(missing)\u{201D}"
                    onSubmit(.wrong(hint: hint))
                } else {
                    onSubmit(.correct)
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty)
            .opacity(text.trimmingCharacters(in: .whitespaces).isEmpty ? 0.4 : 1)
        }
        .onAppear { focused = true }
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
