import SwiftUI

@MainActor
struct ContentView: View {
    var body: some View {
        TabView {
            Tab("Pulse", systemImage: "circle.hexagongrid.fill") {
                PulseFocusView()
            }

            Tab("Liquid Lab", systemImage: "drop.fill") {
                LiquidGlassLabView()
            }

            Tab("Runtime", systemImage: "cpu.fill") {
                RuntimeInspectorView()
            }
        }
    }
}

#Preview {
    ContentView()
}
