import SwiftData
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(for: Slipbox.self)
        }
    }
}

#Preview("MainView – In-Memory Store") {
    MainView()
        .modelContainer(for: Slipbox.self, inMemory: true)
}
