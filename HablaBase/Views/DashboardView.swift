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
                    if store.state.energy == 0 {
                        rechargeCard
                    }
                    continueCard
                    fluencyCard
                    currentUnit
                }
                .padding(20)
            }
            .onAppear { store.refillEnergyIfNewDay() }
            .navigationTitle("¡Hola, \(store.profile?.name ?? "")!")
        }
        .fullScreenCover(item: $activeLesson) { lesson in
            LessonView(lesson: lesson)
                .environmentObject(store)
                .environment(\.locale, store.language.locale)
        }
    }

    private var statsRow: some View {
        HStack(spacing: 16) {
            Label("\(store.state.streak)", systemImage: "flame.fill")
                .foregroundStyle(.orange)
                .accessibilityLabel("Streak: \(store.state.streak) days")
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
            let unit = node.unitId.flatMap { curriculum.unit(id: $0) }
            if let lesson = store.playableLesson(node.id) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Level \(level.number) · \(level.name) · \(level.cefr)")
                        .textCase(.uppercase)
                        .font(.caption.weight(.bold))
                        .foregroundStyle(.white.opacity(0.8))
                    if let unit {
                        Text("Unit \(unit.number) · \(unit.title)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(.white.opacity(0.9))
                    }
                    Text(node.title)
                        .font(.title.bold())
                        .foregroundStyle(.white)
                    Text(node.gloss.text(store.language))
                        .foregroundStyle(.white.opacity(0.9))
                    Button("Continue") { activeLesson = lesson }
                        .buttonStyle(PrimaryButtonStyle(color: .white, textColor: Brick.stem.color))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Brick.stem.color.gradient))
            } else {
                caughtUpCard
            }
        } else {
            Text("You have finished the whole path. ¡Enhorabuena!")
                .font(.title2.bold())
        }
    }

    /// Energy never blocks a lesson; at zero, it invites a short review of the mistakes.
    private var rechargeCard: some View {
        Button {
            activeLesson = Unit1.reviewLesson(weakForms: store.weakForms, completed: store.state.completedLessons)
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "heart.fill")
                    .font(.title)
                    .foregroundStyle(.red)
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Win your hearts back").font(.headline)
                    Text("Review your mistakes: every right answer gives you a heart.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: "chevron.right").foregroundStyle(.secondary).accessibilityHidden(true)
            }
            .padding(16)
            .background(RoundedRectangle(cornerRadius: 18).fill(Color.red.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }

    /// Shown when the next step is not in this version of the app yet.
    private var caughtUpCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("You're up to date", systemImage: "checkmark.seal.fill")
                .font(.title2.bold())
                .foregroundStyle(Palette.success)
            Text("You have done every lesson in this version. New lessons arrive with app updates; meanwhile, keep your verbs fresh in the Lab.")
                .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Palette.card))
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

    private func metric(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(value).font(.title2.bold())
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }

    @ViewBuilder
    private var currentUnit: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let unitId = store.nextNode?.unitId, let unit = curriculum.unit(id: unitId) {
                Text("Unit \(unit.number) · \(unit.title)")
                    .font(.headline)
                ForEach(unit.lessons) { lesson in
                    PathNodeRow(id: lesson.id, title: lesson.title, subtitle: lesson.gloss.text(store.language), kind: .lesson)
                }
                PathNodeRow(id: unit.boss.id, title: unit.boss.title, subtitle: unit.boss.gloss.text(store.language), kind: .boss)
                PathNodeRow(id: unit.test.id, title: unit.test.title, subtitle: unit.test.gloss.text(store.language), kind: .test)
                SkipUnitButton(unit: unit) { activeLesson = $0 }
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
                .accessibilityHidden(true)
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
        .accessibilityElement(children: .combine)
        .accessibilityValue(status)
    }

    private var status: String {
        if store.isCompleted(id) { return store.language.localized("Done") }
        if isCurrent { return store.language.localized("Next") }
        return store.language.localized("Locked")
    }

    private var isCurrent: Bool { store.nextNode?.id == id }

    private var icon: String {
        if store.isCompleted(id) { return "checkmark.seal.fill" }
        switch kind {
        case .lesson: return isCurrent ? "play.circle.fill" : "lock.circle"
        case .boss: return "flag.checkered"
        case .test: return "checklist"
        case .checkpoint: return "rosette"
        }
    }

    private var color: Color {
        if store.isCompleted(id) { return Palette.success }
        if isCurrent { return Brick.stem.color }
        return kind == .lesson ? .secondary : Brick.rail.color.opacity(0.6)
    }
}

/// "Already know this?": take the unit's 10-question test and skip ahead if you pass.
/// Hidden when the unit is done or its test is not in this version yet.
struct SkipUnitButton: View {
    @EnvironmentObject var store: AppStore
    let unit: CurriculumUnit
    let start: (Lesson) -> Void

    var body: some View {
        if !store.isCompleted(unit.test.id), let test = store.playableLesson(unit.test.id) {
            Button {
                start(test)
            } label: {
                Label("Already know this? Take the test (10 questions)", systemImage: "forward.fill")
                    .font(.subheadline.weight(.semibold))
            }
            .buttonStyle(.bordered)
            .tint(Brick.rail.color)
        }
    }
}
