import SwiftUI

@main
struct HablaBaseApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
        }
    }
}

struct RootView: View {
    @EnvironmentObject private var store: AppStore
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        if store.profile == nil {
            OnboardingView()
        } else {
            TabView {
                DashboardView()
                    .tabItem { Label("Path", systemImage: "map") }
                LabView()
                    .tabItem { Label("Lab", systemImage: "square.stack.3d.up") }
                NotesView()
                    .tabItem { Label("Notes", systemImage: "book.closed") }
                TalkView()
                    .tabItem { Label("Speak", systemImage: "mic.fill") }
                ProfileView()
                    .tabItem { Label("Profile", systemImage: "person.crop.circle") }
            }
            .environment(\.locale, store.language.locale)
            .levelTone(Journey.currentTone(store: store))
            .onChange(of: scenePhase) { _, phase in
                // A new day may have started: refill the hearts and plan the reminders again.
                guard phase == .active else { return }
                store.refillEnergyIfNewDay()
                if store.state.reminder != nil { store.planReminders() }
            }
        }
    }
}
