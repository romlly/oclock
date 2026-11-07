import SwiftUI

@main
struct OclockApp: App {
    @AppStorage(AppTheme.storageKey) private var horseTheme = false

    private var theme: AppTheme { horseTheme ? .horses : .standard }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.appTheme, theme)
                .tint(theme.accent)
                .preferredColorScheme(theme.colorScheme)
        }
    }
}
