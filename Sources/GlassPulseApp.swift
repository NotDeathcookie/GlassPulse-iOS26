import SwiftData
import SwiftUI

@main
struct GlassPulseApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(for: FocusSessionRecord.self)
    }
}
