import SwiftUI

/// Minute 0 to 3: goal, daily time and four facts that become the learner's personal sentence bank.
struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var draft = Profile(name: "", city: "", workplace: .oficina,
                                       nativeLanguage: .deviceDefault, goal: .travel, dailyMinutes: 10)

    var body: some View {
        NavigationStack {
            ProfileForm(profile: $draft)
                .safeAreaInset(edge: .bottom) {
                    Button("Start") { store.completeOnboarding(cleaned) }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!isValid)
                        .opacity(isValid ? 1 : 0.4)
                        .padding()
                        .background(.bar)
                }
                .navigationTitle("HablaBase")
        }
        // The form switches language as soon as the learner picks theirs.
        .environment(\.locale, draft.nativeLanguage.locale)
    }

    private var cleaned: Profile {
        var profile = draft
        profile.name = profile.name.trimmingCharacters(in: .whitespaces)
        profile.city = profile.city.trimmingCharacters(in: .whitespaces)
        return profile
    }

    private var isValid: Bool {
        !cleaned.name.isEmpty && !cleaned.city.isEmpty
    }
}

/// Shared by onboarding and the Profile tab.
struct ProfileForm: View {
    @Binding var profile: Profile

    var body: some View {
        Form {
            Section {
                Picker("My language", selection: $profile.nativeLanguage) {
                    ForEach(NativeLanguage.allCases) { Text($0.label).tag($0) }
                }
                Picker("Goal", selection: $profile.goal) {
                    ForEach(LearningGoal.allCases) { Text($0.gloss.text(profile.nativeLanguage)).tag($0) }
                }
                Picker("Daily time", selection: $profile.dailyMinutes) {
                    ForEach([5, 10, 20], id: \.self) { Text("\($0) min").tag($0) }
                }
                .pickerStyle(.segmented)
            } header: {
                Text("You")
            }

            Section {
                TextField("Name", text: $profile.name)
                    .textContentType(.givenName)
                TextField("City", text: $profile.city)
                    .textContentType(.addressCity)
                Picker("I work", selection: $profile.workplace) {
                    ForEach(Workplace.allCases) { Text($0.gloss.text(profile.nativeLanguage)).tag($0) }
                }
            } header: {
                Text("Your sentence bank")
            } footer: {
                Text("Your first Spanish sentences will be about you: your name, your city and your work.")
            }
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject private var store: AppStore
    @State private var confirmReset = false

    var body: some View {
        NavigationStack {
            if let profile = store.profile {
                ProfileForm(profile: Binding(get: { profile }, set: { store.updateProfile($0) }))
                    .safeAreaInset(edge: .bottom) {
                        Button("Reset progress", role: .destructive) { confirmReset = true }
                            .padding()
                    }
                    .confirmationDialog("Delete all progress and start again?", isPresented: $confirmReset, titleVisibility: .visible) {
                        Button("Reset", role: .destructive) { store.reset() }
                    }
                    .navigationTitle("Profile")
            }
        }
    }
}
