import SwiftUI

/// Answers "what do I do now?" with one button, and shows fluency growing, not only XP.
struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @State private var activeLesson: Lesson?

    private let curriculum = Curriculum.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statsRow
                    continueCard
                    fluencyCard
                    currentUnit
                }
                .padding(20)
            }
            .navigationTitle("¡Hola, \(store.profile?.name ?? "")!")
        }
        .fullScreenCover(item: $activeLesson) { lesson in
            LessonView(lesson: lesson)
                .environmentObject(store)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            Label("\(store.state.streak)", systemImage: "flame.fill")
                .foregroundStyle(.orange)
            Label("\(store.state.xp) XP", systemImage: "star.fill")
                .foregroundStyle(.yellow)
            Spacer()
            EnergyView(energy: store.state.energy)
        }
        .font(.headline)
    }

    @ViewBuilder
    private var continueCard: some View {
        if let node = store.nextNode, let level = curriculum.level(id: node.levelId) {
            let lesson = store.profile.flatMap { Unit1.lesson(id: node.id, profile: $0) }
            let unit = node.unitId.flatMap { curriculum.unit(id: $0) }
            VStack(alignment: .leading, spacing: 12) {
                Text("NIVEL \(level.number) · \(level.name.uppercased()) · \(level.cefr)")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
                if let unit {
                    Text("Unidad \(unit.number) · \(unit.title)")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.white.opacity(0.9))
                }
                Text(node.title)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text(node.gloss.text(store.language))
                    .foregroundStyle(.white.opacity(0.9))
                Button(lesson == nil ? "Coming soon" : "Continue") {
                    activeLesson = lesson
                }
                .buttonStyle(PrimaryButtonStyle(color: .white, textColor: Brick.stem.color))
                .opacity(lesson == nil ? 0.5 : 1)
                .disabled(lesson == nil)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Brick.stem.color.gradient))
        } else {
            Text("¡Maestría! You have finished the whole path.")
                .font(.title2.bold())
        }
    }

    private var fluencyCard: some View {
        let mastered = store.state.mastery.values.filter { $0 >= 3 }.count
        return HStack {
            metric("\(store.state.sentencesBuilt)", "sentences built")
            Divider()
            metric("\(mastered)", "forms mastered")
            Divider()
            metric("\(store.state.completedLessons.count)", "steps done")
        }
        .padding()
        .background(RoundedRectangle(cornerRadius: 16).fill(Palette.card))
    }

    private func metric(_ value: String, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }

    @ViewBuilder
    private var currentUnit: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let unitId = store.nextNode?.unitId, let unit = curriculum.unit(id: unitId) {
                Text("Unidad \(unit.number) · \(unit.title)")
                    .font(.headline)
                ForEach(unit.lessons) { lesson in
                    PathNodeRow(id: lesson.id, title: lesson.title, subtitle: lesson.gloss.text(store.language), kind: .lesson)
                }
                PathNodeRow(id: unit.boss.id, title: unit.boss.title, subtitle: unit.boss.gloss.text(store.language), kind: .boss)
            }
            NavigationLink {
                PathMapView()
            } label: {
                Label("See the full path: 8 levels, A0 to C2", systemImage: "map")
                    .font(.subheadline.weight(.semibold))
            }
            .padding(.top, 4)
        }
    }
}

/// One step on the path with its state: done, current or locked.
struct PathNodeRow: View {
    // Not private: a private wrapped property would make the memberwise init private.
    @EnvironmentObject var store: AppStore
    let id: String
    let title: String
    let subtitle: String
    let kind: PathNode.Kind
    var detail: String?

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 32)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.body.weight(.semibold))
                Text(subtitle).font(.footnote).foregroundStyle(.secondary)
                if let detail {
                    Text(detail).font(.caption).foregroundStyle(Brick.stem.color)
                }
            }
            Spacer()
        }
        .padding(.vertical, 4)
    }

    private var isCurrent: Bool { store.nextNode?.id == id }

    private var icon: String {
        if store.isCompleted(id) { return "checkmark.seal.fill" }
        switch kind {
        case .lesson: return isCurrent ? "play.circle.fill" : "lock.circle"
        case .boss: return "flag.checkered"
        case .checkpoint: return "rosette"
        }
    }

    private var color: Color {
        if store.isCompleted(id) { return Palette.success }
        if isCurrent { return Brick.stem.color }
        return kind == .lesson ? .secondary : Brick.rail.color.opacity(0.6)
    }
}
