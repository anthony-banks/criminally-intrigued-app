import SwiftUI

/// Root tab shell: the three categories + Saved + Settings (spec §10).
/// Also drives the one-time first-launch content disclaimer.
struct RootView: View {
    @Environment(AppEnvironment.self) private var environment
    @AppStorage("hasSeenDisclaimer") private var hasSeenDisclaimer = false
    @AppStorage("offlineModeEnabled") private var offlineEnabled = false

    var body: some View {
        TabView {
            ForEach(Category.allCases) { category in
                NavigationStack {
                    CategoryListView(category: category)
                }
                .tabItem {
                    Label(category.title, systemImage: category.symbolName)
                }
            }

            NavigationStack {
                SavedView()
            }
            .tabItem { Label("Saved", systemImage: "bookmark.fill") }

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
        .task {
            await environment.catalog.bootstrap()
            // If offline mode is on, top up any articles still missing a body
            // (e.g. new entries from a background catalog refresh).
            if offlineEnabled {
                environment.offline.start()
            }
        }
        .sheet(isPresented: disclaimerBinding) {
            DisclaimerView { hasSeenDisclaimer = true }
                .interactiveDismissDisabled()
        }
    }

    private var disclaimerBinding: Binding<Bool> {
        Binding(
            get: { !hasSeenDisclaimer },
            set: { showing in if !showing { hasSeenDisclaimer = true } }
        )
    }
}
