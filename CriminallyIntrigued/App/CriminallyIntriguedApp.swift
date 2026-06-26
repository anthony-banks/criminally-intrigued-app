import SwiftUI
import SwiftData

@main
struct CriminallyIntriguedApp: App {
    @State private var environment = AppEnvironment()
    @AppStorage("appTheme") private var themeRaw = AppTheme.system.rawValue

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(environment)
                .tint(Palette.accentOlive)
                .preferredColorScheme(AppTheme(rawValue: themeRaw)?.colorScheme)
        }
        .modelContainer(environment.modelContainer)
    }
}
