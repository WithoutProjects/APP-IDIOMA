import SwiftUI

/// Home: the counters on top, a greeting that shows fluency growing, and the winding path.
struct DashboardView: View {
    @EnvironmentObject private var store: AppStore
    @State private var activeLesson: Lesson?

    var body: some View {
        NavigationStack {
            JourneyView(start: { activeLesson = $0 }) {
                heroCard
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
            }
            .safeAreaInset(edge: .top, spacing: 0) {
                VStack(spacing: 10) {
                    statsBar
                    if store.state.energy == 0 {
                        rechargeCard
                    }
                    statusCard
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color(.systemBackground))
                .overlay(alignment: .bottom) { Divider() }
            }
            .toolbar(.hidden, for: .navigationBar)
            .onAppear { store.refillEnergyIfNewDay() }
        }
        .fullScreenCover(item: $activeLesson) { lesson in
            LessonView(lesson: lesson)
                .environmentObject(store)
                .environment(\.locale, store.language.locale)
                .fontDesign(.rounded)
        }
    }

    private var statsBar: some View {
        HStack(spacing: 10) {
            StatPill(icon: "flame.fill", value: "\(store.state.streak)", color: .tangerine)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("Streak: \(store.state.streak) days"))
            StatPill(icon: "star.fill", value: "\(store.state.xp)", color: .sunshine)
                .accessibilityElement(children: .ignore)
                .accessibilityLabel(Text("\(store.state.xp) XP"))
            Spacer()
            EnergyView(energy: store.state.energy)
                .font(.headline)
        }
    }

    /// "¡Hola!" and the three numbers that show real Spanish growing, with a mascot peeking in.
    private var heroCard: some View {
        let mastered = store.state.mastery.values.filter { $0 >= 3 }.count
        let shape = RoundedRectangle(cornerRadius: 28, style: .continuous)
        return ZStack(alignment: .topLeading) {
            shape.fill(FunColor.grape.main)
            Mascot(shape: .blob, color: FunColor.sunshine.main, mood: .excited, size: 130)
                .rotationEffect(.degrees(-10))
                .offset(x: 28, y: 34)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            VStack(alignment: .leading, spacing: 10) {
                Text(verbatim: "¡Hola, \(store.profile?.name ?? "")!")
                    .font(.system(.title, design: .rounded).weight(.heavy))
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                metric(store.state.sentencesBuilt, "sentences built", icon: "text.bubble.fill")
                metric(mastered, "forms mastered", icon: "bolt.fill")
                metric(store.state.completedLessons.count, "steps done", icon: "checkmark.circle.fill")
            }
            .foregroundStyle(.white)
            .padding(20)
            .padding(.trailing, 96)
        }
        .clipShape(shape)
        .frame(minHeight: 170)
    }

    private func metric(_ value: Int, _ label: LocalizedStringKey, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundStyle(FunColor.sunshine.main)
                .accessibilityHidden(true)
            Text(verbatim: "\(value)").font(.system(.headline, design: .rounded).weight(.heavy))
            Text(label).font(.subheadline.weight(.medium)).opacity(0.9)
        }
        .accessibilityElement(children: .combine)
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
            .padding(14)
            .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(Color.red.opacity(0.1)))
        }
        .buttonStyle(.plain)
    }

    /// Shown when the next step is not in this version of the app yet, or the path is finished.
    @ViewBuilder
    private var statusCard: some View {
        if let node = store.nextNode {
            if !Journey.isBuilt(node, store: store) {
                HStack(alignment: .top, spacing: 12) {
                    Mascot(shape: .squircle, color: FunColor.leaf.main, mood: .happy, size: 46)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("You're up to date")
                            .font(.headline)
                            .foregroundStyle(Palette.success)
                        Text("You have done every lesson in this version. New lessons arrive with app updates; meanwhile, keep your verbs fresh in the Lab.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(FunColor.leaf.soft))
            }
        } else {
            Text("You have finished the whole path. ¡Enhorabuena!")
                .font(.system(.title3, design: .rounded).weight(.heavy))
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
