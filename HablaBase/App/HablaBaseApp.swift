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
        }
    }
}
