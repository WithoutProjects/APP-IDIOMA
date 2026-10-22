import SwiftUI

/// One unit's page: what it teaches, then its steps on a dotted line, each one a tile to tap.
struct UnitDetailView: View {
    @EnvironmentObject private var store: AppStore
    let unit: CurriculumUnit
    let level: CurriculumLevel
    @State private var activeLesson: Lesson?

    var body: some View {
        let tone = Tone.forLevel(level.number)
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                header(tone)
                if Journey.canSkip(to: unit, store: store) {
                    skipCard(tone)
                }
                steps(tone)
            }
            .padding(20)
        }
        .navigationBarTitleDisplayMode(.inline)
        .levelTone(tone)
        .fullScreenCover(item: $activeLesson) { lesson in
            LessonView(lesson: lesson)
                .environmentObject(store)
                .environment(\.locale, store.language.locale)
        }
    }

    private func header(_ tone: Tone) -> some View {
        let nodes = Journey.nodes(in: unit)
        let done = nodes.filter { store.isCompleted($0.id) }.count
        return VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "\(Journey.unitWord.text(store.language)) \(unit.number) · \(level.cefr)", color: tone.main)
            Text(unit.title)
                .font(.largeTitle.bold())
            Text(unit.gloss.text(store.language))
                .foregroundStyle(.secondary)
            if !unit.grammar.isEmpty {
                Text(unit.grammar.joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(Brick.time.color)
            }
            if !unit.connectors.isEmpty {
                Text(unit.connectors.joined(separator: " · "))
                    .font(.footnote)
                    .foregroundStyle(Brick.rail.color)
            }
            ProgressView(value: nodes.isEmpty ? 0 : Double(done) / Double(nodes.count))
                .tint(tone.main)
                .padding(.top, 4)
                .accessibilityValue(Text("\(done) of \(nodes.count) steps done"))
        }
    }

    private func skipCard(_ tone: Tone) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(Journey.skipTitle.text(store.language))
                .font(.headline)
            Text(Journey.skipDetail.text(store.language))
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Button(Journey.takeTest.text(store.language)) { start(unit.test.id) }
                .buttonStyle(PrimaryButtonStyle(color: tone.main))
                .padding(.top, 4)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(tone.soft))
    }

    private func steps(_ tone: Tone) -> some View {
        VStack(alignment: .leading, spacing: 24) {
            ForEach(Journey.nodes(in: unit)) { node in
                StepRow(node: node, status: status(of: node), tone: tone,
                        focus: unit.lessons.first { $0.id == node.id }?.focus,
                        language: store.language) {
                    start(node.id)
                }
            }
        }
        .background(alignment: .leading) {
            VerticalLine()
                .stroke(Color(.systemGray3), style: StrokeStyle(lineWidth: 2, lineCap: .round, dash: [0.5, 7]))
                .frame(width: 2)
                .padding(.leading, StepRow.tileSize / 2 - 1)
                .padding(.vertical, StepRow.tileSize / 2)
                .accessibilityHidden(true)
        }
    }

    private func status(of node: PathNode) -> StepStatus {
        if store.isCompleted(node.id) { return .done }
        let built = Journey.isBuilt(node, store: store)
        if store.nextNode?.id == node.id { return built ? .current : .comingSoon }
        // The unit test can be taken at any time.
        if node.kind == .test, built { return .open }
        return .locked
    }

    private func start(_ id: String) {
        activeLesson = store.playableLesson(id)
    }
}

enum StepStatus {
    case done, current, open, locked
    /// The next step, but not in this version of the app yet.
    case comingSoon

    var canStart: Bool { self == .done || self == .current || self == .open }
}

/// A step: a rounded tile with its state, and its title beside it.
struct StepRow: View {
    static let tileSize: CGFloat = 64

    let node: PathNode
    let status: StepStatus
    let tone: Tone
    let focus: String?
    let language: NativeLanguage
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 18) {
                tile
                VStack(alignment: .leading, spacing: 3) {
                    Text(node.title)
                        .font(status == .current ? Font.title3.weight(.semibold) : Font.headline)
                        .foregroundStyle(status == .locked ? Color.secondary : Color.primary)
                    Text(node.gloss.text(language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    if let note {
                        Text(note)
                            .font(.caption.weight(.medium))
                            .foregroundStyle(status == .locked ? Color.secondary : tone.main)
                    }
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .disabled(!status.canStart)
        .accessibilityElement(children: .combine)
        .accessibilityValue(statusText)
    }

    private var note: String? {
        switch status {
        case .open: return Journey.anytime.text(language)
        case .comingSoon: return language.localized("You're up to date")
        default: return focus
        }
    }

    private var tile: some View {
        let shape = RoundedRectangle(cornerRadius: 18, style: .continuous)
        return ZStack {
            switch status {
            case .done:
                shape.fill(tone.main)
            case .current:
                shape.fill(tone.main)
                    .shadow(color: tone.main.opacity(0.35), radius: 12, y: 6)
            case .open:
                shape.fill(tone.soft)
            case .locked, .comingSoon:
                shape.fill(Color(.systemGray6))
            }
            Image(systemName: icon)
                .font(.title3.weight(.semibold))
                .foregroundStyle(iconColor)
        }
        .frame(width: Self.tileSize, height: Self.tileSize)
        .accessibilityHidden(true)
    }

    private var icon: String {
        switch status {
        case .done: return "checkmark"
        case .locked, .comingSoon: return "lock.fill"
        case .current, .open:
            switch node.kind {
            case .lesson: return "play.fill"
            case .boss: return "flag.fill"
            case .test: return "checklist"
            case .checkpoint: return "rosette"
            }
        }
    }

    private var iconColor: Color {
        switch status {
        case .done, .current: return .white
        case .open: return tone.main
        case .locked, .comingSoon: return Color(.systemGray2)
        }
    }

    private var statusText: String {
        switch status {
        case .done: return language.localized("Done")
        case .current: return language.localized("Next")
        case .open: return language.localized("Unit test")
        case .locked, .comingSoon: return language.localized("Locked")
        }
    }
}
