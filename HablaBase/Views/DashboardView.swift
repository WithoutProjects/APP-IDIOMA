import SwiftUI

/// Answers "what do I do now?" with one button, and shows fluency growing, not only XP.
struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @State private var activeLesson: Lesson?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    statsRow
                    continueCard
                    fluencyCard
                    pathList
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
        let language = store.language
        if let node = store.nextNode {
            let lesson = store.profile.flatMap { Unit1.lesson(id: node.id, profile: $0) }
            VStack(alignment: .leading, spacing: 12) {
                Text(node.isBoss ? "BOSS" : "UNIT 1 · LEVEL 1 ARRANQUE")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(.white.opacity(0.8))
                Text(node.title)
                    .font(.title.bold())
                    .foregroundStyle(.white)
                Text(node.gloss.text(language))
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
            Text("Unit 1 complete. ¡Enhorabuena!")
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
            metric("\(store.state.completedLessons.count)", "lessons")
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

    private var pathList: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Unit 1 · El presente")
                .font(.headline)
            ForEach(Unit1.path) { node in
                HStack(spacing: 14) {
                    Image(systemName: icon(for: node))
                        .font(.title2)
                        .foregroundStyle(color(for: node))
                        .frame(width: 32)
                    VStack(alignment: .leading) {
                        Text(node.title).font(.body.weight(.semibold))
                        Text(node.gloss.text(store.language)).font(.footnote).foregroundStyle(.secondary)
                    }
                    Spacer()
                }
                .padding(.vertical, 6)
            }
        }
    }

    private func icon(for node: PathNode) -> String {
        if store.isCompleted(node.id) { return "checkmark.seal.fill" }
        if node.id == store.nextNode?.id { return node.isBoss ? "flag.checkered" : "play.circle.fill" }
        return node.isBoss ? "flag.checkered" : "lock.circle"
    }

    private func color(for node: PathNode) -> Color {
        if store.isCompleted(node.id) { return Palette.success }
        if node.id == store.nextNode?.id { return Brick.stem.color }
        return .secondary
    }
}
