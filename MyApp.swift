import SwiftData
import SwiftUI

@main
struct MyApp: App {
    @State private var shouldShowOnboarding: Bool = true
    @AppStorage("theme") private var theme: Theme = .light
    
    var body: some Scene {
        WindowGroup {
            if shouldShowOnboarding {
                OnboardingView(show: $shouldShowOnboarding)
                    .preferredColorScheme(theme.colorScheme)
            } else {
                MainView()
                    .modelContainer(for: Slipbox.self, isAutosaveEnabled: true)
            }
        }
    }
}

#Preview("MainView – In-Memory Store") {
    MainView()
        .modelContainer(for: Slipbox.self, inMemory: true)
}
