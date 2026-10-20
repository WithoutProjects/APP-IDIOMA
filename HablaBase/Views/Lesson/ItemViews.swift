import SwiftUI

// MARK: - Frame

/// A rule shown as a picture: habl- + -o = hablo, one rule, a few examples.
struct FrameCardView: View {
    let card: FrameCard
    let language: NativeLanguage
    let onContinue: () -> Void
    @State private var snapped = false

    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 10) {
                BrickView(text: card.stem + "-", kind: .stem)
                Text("+").font(.title2.bold())
                BrickView(text: "-" + card.ending, kind: .ending)
                Text("=").font(.title2.bold())
                ColoredForm(form: VerbForm(stem: card.stem, ending: card.ending), font: .title.bold())
                    .opacity(snapped ? 1 : 0)
                    .scaleEffect(snapped ? 1 : 0.6)
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
    @State private var stem: String?
    @State private var ending: String?

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

// MARK: - Sentence Builder

/// The Builder Bar: tap chunk tiles into place to say what the prompt asks for.
struct SentenceBuilderView: View {
    let builder: SentenceBuilder
    let language: NativeLanguage
    let onSubmit: (GradeOutcome) -> Void
    /// Indices into builder.tiles, in the order the learner placed them.
    @State private var placed: [Int] = []

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
    @State private var text = ""
    @FocusState private var focused: Bool

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
