import SwiftData
import SwiftUI

enum AppTab: String, Hashable {
    case pulse
    case lab
    case stats
    case runtime
}

@MainActor
struct ContentView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var selectedTab: AppTab = .pulse
    @State private var focusEngine = FocusEngine()
    @State private var soundEngine = AmbientSoundEngine()
    @State private var motionManager = MotionManager()
    @State private var showMiniPlayerSheet = false
    @Namespace private var zoomNamespace

    var body: some View {
        TabView(selection: $selectedTab) {
            Tab("Pulse", systemImage: "circle.hexagongrid.fill", value: AppTab.pulse) {
                PulseFocusView(
                    focusEngine: focusEngine,
                    soundEngine: soundEngine,
                    motionManager: motionManager
                )
            }

            Tab("Liquid Lab", systemImage: "drop.fill", value: AppTab.lab) {
                LiquidGlassLabView(motionManager: motionManager)
            }

            Tab("Stats", systemImage: "chart.bar.xaxis", value: AppTab.stats) {
                StatsView(motionManager: motionManager)
            }

            Tab("Runtime", systemImage: "cpu.fill", value: AppTab.runtime) {
                RuntimeInspectorView(
                    focusEngine: focusEngine,
                    motionManager: motionManager
                )
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .tabViewBottomAccessory {
            if selectedTab != .pulse && (focusEngine.hasActiveSession || soundEngine.selectedMode != .off) {
                miniAccessoryBar
                    .matchedTransitionSource(id: "miniTimer", in: zoomNamespace)
            }
        }
        .sheet(isPresented: $showMiniPlayerSheet) {
            QuickFocusSheet(focusEngine: focusEngine, soundEngine: soundEngine)
                .navigationTransition(.zoom(sourceID: "miniTimer", in: zoomNamespace))
                .presentationDetents([.medium])
        }
        .onAppear {
            focusEngine.modelContext = modelContext
        }
        .onOpenURL { url in
            handleDeepLink(url)
        }
    }

    private var miniAccessoryBar: some View {
        HStack(spacing: 12) {
            Button {
                showMiniPlayerSheet = true
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: focusEngine.selectedCategory.icon)
                        .foregroundStyle(focusEngine.selectedCategory.color)
                    Text(focusEngine.formattedTime)
                        .font(.subheadline.monospacedDigit().weight(.bold))
                    Text("· \(focusEngine.selectedCategory.rawValue)")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)

            Spacer()

            Button {
                withAnimation(.snappy) {
                    focusEngine.toggleRun()
                }
            } label: {
                Image(systemName: focusEngine.isRunning ? "pause.fill" : "play.fill")
                    .font(.subheadline.weight(.bold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.glass)

            Button {
                withAnimation(.snappy) {
                    selectedTab = .pulse
                }
            } label: {
                Image(systemName: "arrow.up.left.and.arrow.down.right")
                    .font(.caption.weight(.bold))
                    .frame(width: 30, height: 30)
            }
            .buttonStyle(.glass)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme?.lowercased() == "glasspulse" else { return }
        let host = url.host?.lowercased() ?? ""
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false)
        let queryItems = components?.queryItems ?? []

        func param(_ name: String) -> String? {
            queryItems.first(where: { $0.name.lowercased() == name.lowercased() })?.value
        }

        switch host {
        case "start":
            if let minsStr = param("minutes"), let mins = Int(minsStr) {
                focusEngine.selectDurationMinutes(mins, autoStart: true)
            } else {
                focusEngine.isRunning = true
            }
            if let catStr = param("category"),
               let matchedCat = SessionCategory.allCases.first(where: { $0.rawValue.caseInsensitiveCompare(catStr) == .orderedSame }) {
                focusEngine.selectedCategory = matchedCat
            }
            if let soundStr = param("sound") {
                switch soundStr.lowercased() {
                case "brown", "brownnoise": soundEngine.selectedMode = .brownNoise
                case "rain", "softrain": soundEngine.selectedMode = .rain
                case "binaural", "40hz": soundEngine.selectedMode = .binaural
                case "off": soundEngine.selectedMode = .off
                default: break
                }
            }
            selectedTab = .pulse

        case "pause":
            focusEngine.isRunning = false

        case "reset":
            focusEngine.reset()

        case "tab":
            if let tabName = param("name")?.lowercased() {
                switch tabName {
                case "pulse": selectedTab = .pulse
                case "lab", "liquid": selectedTab = .lab
                case "stats", "charts": selectedTab = .stats
                case "runtime", "settings": selectedTab = .runtime
                default: break
                }
            }

        default:
            break
        }
    }
}

@MainActor
struct QuickFocusSheet: View {
    @Bindable var focusEngine: FocusEngine
    @Bindable var soundEngine: AmbientSoundEngine
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text(focusEngine.currentPhase.rawValue.uppercased())
                    .font(.caption.weight(.bold))
                    .tracking(2)
                    .foregroundStyle(.secondary)

                Text(focusEngine.formattedTime)
                    .font(.system(size: 58, weight: .bold, design: .rounded))
                    .monospacedDigit()

                Picker("Soundscape", selection: $soundEngine.selectedMode) {
                    ForEach(SoundscapeMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)

                HStack(spacing: 16) {
                    Button {
                        focusEngine.toggleRun()
                    } label: {
                        Label(focusEngine.isRunning ? "Pause" : "Resume", systemImage: focusEngine.isRunning ? "pause.fill" : "play.fill")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                    }
                    .buttonStyle(.glassProminent)
                    .tint(focusEngine.selectedCategory.color)

                    Button {
                        focusEngine.reset()
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.headline)
                            .padding(12)
                    }
                    .buttonStyle(.glass)
                }
            }
            .padding(24)
            .navigationTitle(focusEngine.selectedCategory.rawValue)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: FocusSessionRecord.self, inMemory: true)
}
