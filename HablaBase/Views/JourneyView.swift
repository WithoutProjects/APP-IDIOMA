import SwiftUI

/// The whole journey on one road: every level, and each unit as a stop along a winding line.
/// The line fills with the level's tone as units are finished; a unit opens its own page of steps.
struct JourneyView: View {
    @EnvironmentObject private var store: AppStore

    private let curriculum = Curriculum.shared

    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(curriculum.levels) { level in
                LevelHeader(level: level, language: store.language)
                LevelRoad(level: level)
            }
        }
    }
}

/// How far the learner is in a unit.
enum UnitProgress {
    case done, current, locked
}

/// One level's units on a winding road, alternating left and right.
struct LevelRoad: View {
    @EnvironmentObject var store: AppStore
    let level: CurriculumLevel

    private static let rowHeight: CGFloat = 128
    private static let nodeInset: CGFloat = 60

    var body: some View {
        let tone = Tone.forLevel(level.number)
        let progress = level.units.map { Journey.progress(of: $0, store: store) }
        VStack(spacing: 0) {
            ForEach(Array(level.units.enumerated()), id: \.element.id) { index, unit in
                NavigationLink {
                    UnitDetailView(unit: unit, level: level)
                } label: {
                    UnitStop(unit: unit, progress: progress[index], tone: tone,
                             onLeft: index.isMultiple(of: 2),
                             done: Journey.nodes(in: unit).filter { store.isCompleted($0.id) }.count,
                             total: Journey.nodes(in: unit).count,
                             language: store.language)
                        .padding(.horizontal, Self.nodeInset - 32)
                        .frame(height: Self.rowHeight)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .id(unit.id)
            }
        }
        .background {
            Canvas { context, size in
                let count = progress.count
                guard count > 1 else { return }
                for index in 0..<(count - 1) {
                    let from = point(index, in: size)
                    let to = point(index + 1, in: size)
                    var path = Path()
                    path.move(to: from)
                    path.addCurve(to: to,
                                  control1: CGPoint(x: from.x, y: from.y + Self.rowHeight * 0.6),
                                  control2: CGPoint(x: to.x, y: to.y - Self.rowHeight * 0.6))
                    let reached = progress[index] == .done
                    context.stroke(path, with: .color(reached ? tone.main : Color(.systemGray5)),
                                   style: StrokeStyle(lineWidth: 10, lineCap: .round))
                }
            }
            .accessibilityHidden(true)
        }
    }

    private func point(_ index: Int, in size: CGSize) -> CGPoint {
        let x = index.isMultiple(of: 2) ? Self.nodeInset : size.width - Self.nodeInset
        return CGPoint(x: x, y: Self.rowHeight * (CGFloat(index) + 0.5))
    }
}

/// A unit on the road: a ringed circle and, beside it, its number, title and progress.
struct UnitStop: View {
    let unit: CurriculumUnit
    let progress: UnitProgress
    let tone: Tone
    let onLeft: Bool
    let done: Int
    let total: Int
    let language: NativeLanguage

    var body: some View {
        HStack(spacing: 16) {
            if onLeft {
                node
                label(alignment: .leading)
                Spacer(minLength: 0)
            } else {
                Spacer(minLength: 0)
                label(alignment: .trailing)
                node
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityValue(Text("\(done) of \(total) steps done"))
    }

    private var node: some View {
        ZStack {
            if progress == .current {
                Circle()
                    .fill(tone.soft)
                    .frame(width: 84, height: 84)
            }
            Circle()
                .fill(Color(.systemBackground))
            Circle()
                .strokeBorder(progress == .locked ? Color(.systemGray5) : tone.main, lineWidth: 6)
            if progress == .done {
                Image(systemName: "checkmark")
                    .font(.title3.weight(.bold))
                    .foregroundStyle(tone.main)
            } else {
                Text(verbatim: "\(unit.number)")
                    .font(.title3.weight(.semibold))
                    .monospacedDigit()
                    .foregroundStyle(progress == .locked ? Color.secondary : tone.main)
            }
        }
        .frame(width: 64, height: 64)
        .accessibilityHidden(true)
    }

    private func label(alignment: HorizontalAlignment) -> some View {
        VStack(alignment: alignment, spacing: 3) {
            Eyebrow(text: "\(Journey.unitWord.text(language)) \(unit.number)",
                    color: progress == .locked ? .secondary : tone.main)
            Text(unit.title)
                .font(.headline)
                .foregroundStyle(progress == .locked ? Color.secondary : Color.primary)
                .lineLimit(2)
            Text(verbatim: "\(done)/\(total)")
                .font(.caption)
                .monospacedDigit()
                .foregroundStyle(.secondary)
        }
        .multilineTextAlignment(alignment == .leading ? .leading : .trailing)
        .frame(maxWidth: 190, alignment: alignment == .leading ? .leading : .trailing)
    }
}

/// "LEVEL 2 · MOTOR · A2" and what the learner will be able to do.
struct LevelHeader: View {
    let level: CurriculumLevel
    let language: NativeLanguage

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Capsule()
                .fill(Tone.forLevel(level.number).main)
                .frame(width: 28, height: 4)
            Text("Level \(level.number) · \(level.name) · \(level.cefr)")
                .font(.title3.weight(.semibold))
            Text(level.canDo.text(language))
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 20)
        .padding(.top, 32)
        .padding(.bottom, 8)
        .accessibilityElement(children: .combine)
        .accessibilityAddTraits(.isHeader)
    }
}

/// The path's lookups and texts, shared by the road and the unit pages.
@MainActor
enum Journey {
    static let nodesByUnit: [String: [PathNode]] = Dictionary(
        grouping: Curriculum.sharedPath.filter { $0.unitId != nil },
        by: { $0.unitId ?? "" }
    )

    /// Where each step sits on the whole path.
    static let position: [String: Int] = Dictionary(
        uniqueKeysWithValues: Curriculum.sharedPath.enumerated().map { ($0.element.id, $0.offset) }
    )

    /// The unit's lessons, then its boss, then its test.
    static func nodes(in unit: CurriculumUnit) -> [PathNode] {
        nodesByUnit[unit.id] ?? []
    }

    static func progress(of unit: CurriculumUnit, store: AppStore) -> UnitProgress {
        let nodes = nodes(in: unit)
        if nodes.allSatisfy({ store.isCompleted($0.id) }) { return .done }
        if let next = store.nextNode, nodes.contains(where: { $0.id == next.id }) { return .current }
        return .locked
    }

    /// A later unit, not started yet, whose test exists: passing it skips everything before.
    static func canSkip(to unit: CurriculumUnit, store: AppStore) -> Bool {
        guard let first = nodes(in: unit).first,
              let next = store.nextNode,
              let unitStart = position[first.id],
              let current = position[next.id],
              unitStart > current,
              !store.isCompleted(unit.test.id),
              let test = nodes(in: unit).first(where: { $0.id == unit.test.id }) else { return false }
        return isBuilt(test, store: store)
    }

    // Building a lesson to find out whether it exists is costly, so the answer is kept.
    private static var built: [String: Bool] = [:]

    static func isBuilt(_ node: PathNode, store: AppStore) -> Bool {
        if let known = built[node.id] { return known }
        guard store.profile != nil else { return false }
        let exists = store.playableLesson(node.id) != nil
        built[node.id] = exists
        return exists
    }

    static let unitWord = Gloss(en: "Unit", it: "Unità", uk: "Розділ", de: "Einheit", fr: "Unité", pt: "Unidade", zh: "单元")
    static let skipTitle = Gloss(en: "Already know this?", it: "Lo sai già?", uk: "Уже це знаєш?", de: "Kannst du das schon?", fr: "Tu sais déjà tout ça ?", pt: "Já sabe isto?", zh: "已经会了吗？")
    static let skipDetail = Gloss(en: "Pass the 10-question test of this unit to skip everything before it.", it: "Supera il test di 10 domande di questa unità per saltare tutto ciò che viene prima.", uk: "Склади тест із 10 запитань цього розділу, щоб пропустити все, що перед ним.", de: "Bestehe den Test mit 10 Fragen dieser Einheit, um alles davor zu überspringen.", fr: "Réussis le test de 10 questions de cette unité pour sauter tout ce qui la précède.", pt: "Passe no teste de 10 perguntas desta unidade para pular tudo o que vem antes.", zh: "通过本单元的10道题测试，即可跳过之前的所有内容。")
    static let takeTest = Gloss(en: "Take the test", it: "Fai il test", uk: "Пройти тест", de: "Test machen", fr: "Passer le test", pt: "Fazer o teste", zh: "参加测试")
    static let anytime = Gloss(en: "You can take it at any time.", it: "Puoi farlo quando vuoi.", uk: "Його можна пройти будь-коли.", de: "Du kannst ihn jederzeit machen.", fr: "Tu peux le passer quand tu veux.", pt: "Você pode fazer a qualquer momento.", zh: "随时都可以参加。")
}
