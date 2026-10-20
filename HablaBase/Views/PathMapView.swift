import SwiftUI

/// The whole journey: every level, unit, lesson, boss and checkpoint from A0 to C2.
struct PathMapView: View {
    @EnvironmentObject private var store: AppStore
    @State private var expanded: Set<String> = []
    @State private var activeLesson: Lesson?

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
                            PathNodeRow(id: unit.test.id, title: unit.test.title,
                                        subtitle: unit.test.gloss.text(store.language), kind: .test)
                            SkipUnitButton(unit: unit) { activeLesson = $0 }
                        } label: {
                            unitLabel(unit)
                        }
                    }
                    PathNodeRow(id: level.checkpoint.id, title: level.checkpoint.title,
                                subtitle: level.checkpoint.gloss.text(store.language), kind: .checkpoint)
                } header: {
                    Text("Level \(level.number) · \(level.name) · \(level.cefr)")
                }
            }
        }
        .navigationTitle("Full path: A0–C2")
        .fullScreenCover(item: $activeLesson) { lesson in
            LessonView(lesson: lesson)
                .environmentObject(store)
        }
        .onAppear {
            if let unitId = store.nextNode?.unitId { expanded.insert(unitId) }
        }
    }

    private func unitLabel(_ unit: CurriculumUnit) -> some View {
        let steps = unit.lessons.map(\.id) + [unit.boss.id, unit.test.id]
        let done = steps.filter { store.isCompleted($0) }.count
        return VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text("Unit \(unit.number) · \(unit.title)").font(.body.weight(.semibold))
                Spacer()
                Text("\(done)/\(steps.count)").font(.caption).foregroundStyle(.secondary)
                    .accessibilityLabel("\(done) of \(steps.count) steps done")
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
