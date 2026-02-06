import SwiftData
import SwiftUI

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            MainView()
                .modelContainer(for: SlipBox.self)
        }
    }
}
