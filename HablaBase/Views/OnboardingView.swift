import SwiftUI

/// Minute 0 to 3: goal, daily time and four facts that become the learner's personal sentence bank.
struct OnboardingView: View {
    @EnvironmentObject private var store: AppStore
    @State private var draft = Profile(name: "", city: "", workplace: .oficina,
                                       nativeLanguage: .deviceDefault, goal: .travel, dailyMinutes: 10)

    @State private var showsForm = false

    var body: some View {
        if showsForm {
            form
        } else {
            WelcomeView(language: draft.nativeLanguage) {
                withAnimation(.easeInOut) { showsForm = true }
            }
        }
    }

    private var form: some View {
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

/// The first screen: the name, one line, a quiet composition of shapes and one button.
struct WelcomeView: View {
    let language: NativeLanguage
    let onStart: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 12) {
                Text(verbatim: "HablaBase")
                    .font(.system(size: 44, weight: .bold))
                Text(Self.tagline.text(language))
                    .font(.title3.weight(.medium))
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 28)
            .padding(.top, 48)
            Spacer(minLength: 12)
            ShapeComposition()
            Spacer(minLength: 12)
            Button(Self.letsGo.text(language), action: onStart)
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
        }
    }

    static let tagline = Gloss(en: "Spanish step by step, one small win a day.", it: "Lo spagnolo passo dopo passo, una piccola vittoria al giorno.", uk: "Іспанська крок за кроком, щодня маленька перемога.", de: "Spanisch Schritt für Schritt, jeden Tag ein kleiner Erfolg.", fr: "L'espagnol pas à pas, une petite victoire par jour.", pt: "Espanhol passo a passo, uma pequena vitória por dia.", zh: "一步一步学西班牙语，每天一个小进步。")
    static let letsGo = Gloss(en: "Let's go", it: "Iniziamo", uk: "Почнімо", de: "Los geht's", fr: "C'est parti", pt: "Vamos lá", zh: "开始吧")
}

/// Shared by onboarding and the Profile tab.
struct ProfileForm: View {
    @Binding var profile: Profile
    /// Shown above the form on the Profile tab.
    var header: AnyView?
    /// On the Profile tab: the reset button, in its own card at the end of the form.
    var onReset: (() -> Void)?

    var body: some View {
        Form {
            if let header {
                Section {
                    header
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 4, trailing: 0))
            }
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

            VoiceSettingsSection()

            if header != nil {
                AboutSection()
            }

            if let onReset {
                Section {
                    Button("Reset progress", role: .destructive, action: onReset)
                        .frame(maxWidth: .infinity)
                }
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
                ProfileForm(profile: Binding(get: { profile }, set: { store.updateProfile($0) }),
                            header: AnyView(
                                ScreenHeader(eyebrow: Journey.currentLevel(store: store).map { Journey.caption($0, language: store.language) },
                                             title: "Profile",
                                             subtitle: profile.name)
                            ),
                            onReset: { confirmReset = true })
                    .confirmationDialog("Delete all progress and start again?", isPresented: $confirmReset, titleVisibility: .visible) {
                        Button("Reset", role: .destructive) { store.reset() }
                    }
                    .toolbar(.hidden, for: .navigationBar)
            }
        }
    }
}

/// How the Spanish voice sounds: speed, a test button, and how to get a more natural voice.
struct VoiceSettingsSection: View {
    @AppStorage(SpeechSpeed.storageKey) private var speed: SpeechSpeed = .normal

    var body: some View {
        Section {
            Picker("Speed", selection: $speed) {
                Text("Normal").tag(SpeechSpeed.normal)
                Text("Slow").tag(SpeechSpeed.slow)
            }
            .pickerStyle(.segmented)
            Button {
                Speaker.say("Hola, ¿qué tal? Vivo en Madrid y trabajo en una oficina.")
            } label: {
                Label("Listen", systemImage: "speaker.wave.2.fill")
            }
        } header: {
            Text("Spanish voice")
        } footer: {
            if Speaker.hasOnlyStandardVoice {
                Text("For a more natural voice, download a Spanish (Spain) voice marked Enhanced or Premium in Settings > Accessibility > Spoken Content > Voices > Spanish. The app uses it automatically.")
            } else {
                Text("Tap the speaker twice to hear a sentence slowly.")
            }
        }
    }
}
