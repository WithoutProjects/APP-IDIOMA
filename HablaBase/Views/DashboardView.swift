import SwiftUI

/// Home: a greeting with the counters, one button for "what do I do now?", the days in a row,
/// fluency growing, and the whole road from A0 to C2 below.
struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @State private var activeLesson: Lesson?

    private let curriculum = Curriculum.shared

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if store.state.energy == 0 {
                        rechargeCard
                    }
                    continueCard
                    StreakCard()
                    fluencyCard
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                JourneyView()
                    .padding(.bottom, 32)
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { store.refillEnergyIfNewDay() }
        }
        .fullScreenCover(item: $activeLesson) { lesson in
            LessonView(lesson: lesson)
                .environmentObject(store)
                .environment(\.locale, store.language.locale)
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let level = Journey.currentLevel(store: store) {
                Eyebrow(text: Journey.caption(level, language: store.language), color: Tone.forLevel(level.number).main)
            }
            Text(verbatim: "¡Hola, \(store.profile?.name ?? "")!")
                .font(.largeTitle.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            HStack(spacing: 16) {
                Label {
                    Text("\(store.state.xp) XP")
                } icon: {
                    Image(systemName: "star.fill").foregroundStyle(Tone.ochre.main)
                }
                Spacer()
                EnergyView(energy: store.state.energy)
            }
            .font(.subheadline.weight(.medium))
            .foregroundStyle(.secondary)
        }
    }

    @ViewBuilder
    private var continueCard: some View {
        if let node = store.nextNode, let level = curriculum.level(id: node.levelId) {
            let unit = node.unitId.flatMap { curriculum.unit(id: $0) }
            let tone = Tone.forLevel(level.number)
            if Journey.isBuilt(node, store: store) {
                VStack(alignment: .leading, spacing: 8) {
                    if let unit {
                        Eyebrow(text: "\(Journey.unitWord.text(store.language)) \(unit.number) · \(unit.title)", color: tone.main)
                    }
                    Text(node.title)
                        .font(.title2.bold())
                    Text(node.gloss.text(store.language))
                        .foregroundStyle(.secondary)
                    if let unit {
                        let nodes = Journey.nodes(in: unit)
                        ProgressView(value: Double(nodes.filter { store.isCompleted($0.id) }.count),
                                     total: Double(max(nodes.count, 1)))
                            .tint(tone.main)
                            .padding(.vertical, 6)
                    }
                    Button("Continue") { activeLesson = store.playableLesson(node.id) }
                        .buttonStyle(PrimaryButtonStyle(color: tone.fill))
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 24, style: .continuous).fill(Palette.card))
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
                    .font(.title2)
                    .foregroundStyle(Tone.rose.main)
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
            .background(RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Tone.rose.soft))
        }
        .buttonStyle(.plain)
    }

    /// Shown when the next step is not in this version of the app yet.
    private var caughtUpCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("You're up to date", systemImage: "checkmark.seal.fill")
                .font(.title3.bold())
                .foregroundStyle(Tone.sage.main)
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
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(Color(.systemGray5), lineWidth: 1))
    }

    private func metric(_ value: String, _ label: LocalizedStringKey) -> some View {
        VStack(spacing: 2) {
            Text(verbatim: value).font(.title3.weight(.semibold)).monospacedDigit()
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .accessibilityElement(children: .combine)
    }
}
