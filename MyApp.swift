import SwiftData
import SwiftUI
import TipKit

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(for: Slipbox.self, isAutosaveEnabled: true)
                .task {
                    try? Tips.configure([
                        .displayFrequency(.immediate),
                        .datastoreLocation(.applicationDefault)
                    ])
                }
        }
    }
}

#Preview("MainView – In-Memory Store") {
    MainView()
        .modelContainer(for: Slipbox.self, inMemory: true)
}
