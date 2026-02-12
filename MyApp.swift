import SwiftData
import SwiftUI

@main
struct MyApp: App {
    // MARK: - Theme
    @AppStorage("theme") private var theme: Theme = .system
    
    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(for: Slipbox.self)
                .preferredColorScheme(theme.colorScheme)
        }
    }
}

#Preview("MainView – In-Memory Store") {
    MainView()
        .modelContainer(for: Slipbox.self, inMemory: true)
}
