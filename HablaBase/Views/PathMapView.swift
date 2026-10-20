import SwiftUI

/// The whole journey: every level, unit, lesson, boss and checkpoint from A0 to C2.
struct PathMapView: View {
    @EnvironmentObject private var store: AppStore
    @State private var expanded: Set<String> = []

    private let curriculum = Curriculum.shared

    var body: some View {
        List {
            ForEach(curriculum.levels) { level in
                Section {
                    Text(level.canDo.text(store.language))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    ForEach(level.units) { unit in
                        DisclosureGroup(isExpanded: binding(for: unit.id)) {
                            ForEach(unit.lessons) { lesson in
                                PathNodeRow(id: lesson.id, title: lesson.title,
                                            subtitle: lesson.gloss.text(store.language),
                                            kind: .lesson, detail: lesson.focus)
                            }
                            PathNodeRow(id: unit.boss.id, title: unit.boss.title,
                                        subtitle: unit.boss.gloss.text(store.language), kind: .boss)
                        } label: {
                            unitLabel(unit)
                        }
                    }
                    PathNodeRow(id: level.checkpoint.id, title: level.checkpoint.title,
                                subtitle: level.checkpoint.gloss.text(store.language), kind: .checkpoint)
                } header: {
                    Text("Nivel \(level.number) · \(level.name) · \(level.cefr)")
                }
            }
        }
        .navigationTitle("Recorrido A0–C2")
        .onAppear {
            if let unitId = store.nextNode?.unitId { expanded.insert(unitId) }
        }
    }

    private func unitLabel(_ unit: CurriculumUnit) -> some View {
        let steps = unit.lessons.map(\.id) + [unit.boss.id]
        let done = steps.filter { store.isCompleted($0) }.count
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Unidad \(unit.number) · \(unit.title)").font(.body.weight(.semibold))
                Spacer()
                Text("\(done)/\(steps.count)").font(.caption).foregroundStyle(.secondary)
            }
            Text(unit.grammar.joined(separator: " · "))
                .font(.caption)
                .foregroundStyle(Brick.time.color)
            if !unit.connectors.isEmpty {
                Text(unit.connectors.joined(separator: " · "))
                    .font(.caption)
                    .foregroundStyle(Brick.rail.color)
            }
        }
    }

    private func binding(for unitId: String) -> Binding<Bool> {
        Binding(
            get: { expanded.contains(unitId) },
            set: { isOpen in
                if isOpen { expanded.insert(unitId) } else { expanded.remove(unitId) }
            }
        )
    }
}
