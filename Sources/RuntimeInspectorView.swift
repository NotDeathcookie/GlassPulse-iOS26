import SwiftUI
import UIKit

@MainActor
struct RuntimeInspectorView: View {
    @AppStorage("containerScratchpad") private var scratchpad = "Running inside LiveContainer on iOS 26!"

    private var thermalLabel: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: return "Nominal"
        case .fair: return "Fair"
        case .serious: return "Serious"
        case .critical: return "Critical"
        @unknown default: return "Unknown"
        }
    }

    private var ramGB: String {
        let bytes = Double(ProcessInfo.processInfo.physicalMemory)
        return String(format: "%.1f GB", bytes / 1_073_741_824.0)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedAuroraBackdrop(accent: .indigo)

                ScrollView {
                    VStack(spacing: 18) {
                        // Environment Card
                        VStack(alignment: .leading, spacing: 14) {
                            Label("Runtime & Container Info", systemImage: "shippingbox.fill")
                                .font(.headline)

                            Divider().overlay(.white.opacity(0.2))

                            infoRow(title: "System", value: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
                            infoRow(title: "Device", value: UIDevice.current.model)
                            infoRow(title: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "N/A")
                            infoRow(title: "CPU Cores", value: "\(ProcessInfo.processInfo.processorCount)")
                            infoRow(title: "Physical RAM", value: ramGB)
                            infoRow(title: "Thermal State", value: thermalLabel)
                        }
                        .padding(20)
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))

                        // Persistent Container Scratchpad
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Label("Container Storage Test", systemImage: "internaldrive.fill")
                                    .font(.headline)
                                Spacer()
                                Text("UserDefaults")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            Text("Verify that LiveContainer persists data across app relaunches:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            TextField("Type a note...", text: $scratchpad, axis: .vertical)
                                .lineLimit(3...6)
                                .padding(12)
                                .background(.white.opacity(0.08), in: .rect(cornerRadius: 14))
                        }
                        .padding(20)
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))
                    }
                    .padding(20)
                }
            }
            .navigationTitle("Runtime")
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func infoRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.subheadline.weight(.semibold))
                .multilineTextAlignment(.trailing)
                .textSelection(.enabled)
        }
    }
}
