import SwiftData
import SwiftUI
import UIKit
import UniformTypeIdentifiers

@MainActor
struct RuntimeInspectorView: View {
    @Bindable var focusEngine: FocusEngine
    var motionManager: MotionManager

    @Environment(\.modelContext) private var modelContext
    @Environment(\.openURL) private var openURL
    @Query(sort: \FocusSessionRecord.completedAt, order: .reverse)
    private var sessions: [FocusSessionRecord]

    @AppStorage("containerScratchpad") private var scratchpad = "Running inside LiveContainer on iOS 26!"
    @State private var isExporting = false
    @State private var isImporting = false
    @State private var backupStatusMessage: String?

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

    private var backupDocument: GlassPulseBackupDocument {
        let dtos = sessions.map {
            SessionBackupDTO(
                id: $0.id,
                category: $0.category,
                phase: $0.phase,
                durationSeconds: $0.durationSeconds,
                completedAt: $0.completedAt
            )
        }
        let payload = GlassPulseBackupPayload(
            exportedAt: .now,
            appVersion: "2.0.0",
            customPresetMinutes: focusEngine.customPresetsMinutes,
            sessions: dtos
        )
        return GlassPulseBackupDocument(payload: payload)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedAuroraBackdrop(
                    accent: .indigo,
                    pitch: motionManager.pitch,
                    roll: motionManager.roll
                )

                ScrollView {
                    VStack(spacing: 18) {
                        // Environment & Sensor Telemetry Card
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Runtime & Sensor Telemetry", systemImage: "shippingbox.fill")
                                .font(.headline)

                            Divider().overlay(.white.opacity(0.2))

                            infoRow(title: "System", value: "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)")
                            infoRow(title: "Bundle ID", value: Bundle.main.bundleIdentifier ?? "N/A")
                            infoRow(title: "CPU / RAM", value: "\(ProcessInfo.processInfo.processorCount) Cores · \(ramGB)")
                            infoRow(title: "Thermal State", value: thermalLabel)
                            infoRow(
                                title: "Gyroscope Tilt",
                                value: motionManager.isAvailable
                                    ? String(format: "P: %.2f · R: %.2f", motionManager.pitch, motionManager.roll)
                                    : "Unavailable (Simulator)"
                            )
                        }
                        .padding(18)
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))

                        // JSON Data Export & Restore Card
                        VStack(alignment: .leading, spacing: 12) {
                            Label("LiveContainer Data Backup (JSON)", systemImage: "externaldrive.badge.timemachine")
                                .font(.headline)

                            Text("Export your SwiftData focus history & custom presets before updating or reinstalling the .ipa in LiveContainer.")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            HStack(spacing: 10) {
                                Button {
                                    isExporting = true
                                } label: {
                                    Label("Export JSON", systemImage: "square.and.arrow.up")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                }
                                .buttonStyle(.glassProminent)
                                .tint(.indigo)

                                Button {
                                    isImporting = true
                                } label: {
                                    Label("Restore JSON", systemImage: "square.and.arrow.down")
                                        .font(.subheadline.weight(.semibold))
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 10)
                                }
                                .buttonStyle(.glass)
                            }

                            if let backupStatusMessage {
                                Text(backupStatusMessage)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.mint)
                            }
                        }
                        .padding(18)
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))

                        // Custom URL Scheme Deep Links Card
                        VStack(alignment: .leading, spacing: 12) {
                            Label("URL Scheme Automation (glasspulse://)", systemImage: "link")
                                .font(.headline)

                            Text("Trigger actions from iOS Shortcuts or Safari:")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            deepLinkRow(label: "Start 25m Code + Rain", urlString: "glasspulse://start?minutes=25&category=Code&sound=rain")
                            deepLinkRow(label: "Open Liquid Lab Tab", urlString: "glasspulse://tab?name=lab")
                            deepLinkRow(label: "Pause Active Timer", urlString: "glasspulse://pause")
                        }
                        .padding(18)
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))

                        // Persistent Container Scratchpad
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Label("Container Storage Scratchpad", systemImage: "internaldrive.fill")
                                    .font(.headline)
                                Spacer()
                                Text("UserDefaults")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            TextField("Type a note...", text: $scratchpad, axis: .vertical)
                                .lineLimit(2...5)
                                .padding(12)
                                .background(.white.opacity(0.08), in: .rect(cornerRadius: 14))
                        }
                        .padding(18)
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Runtime")
            .navigationBarTitleDisplayMode(.inline)
            .fileExporter(
                isPresented: $isExporting,
                document: backupDocument,
                contentType: .json,
                defaultFilename: "GlassPulse-Backup"
            ) { result in
                switch result {
                case .success(let url):
                    backupStatusMessage = "Exported \(sessions.count) sessions to \(url.lastPathComponent)"
                case .failure(let error):
                    backupStatusMessage = "Export failed: \(error.localizedDescription)"
                }
            }
            .fileImporter(
                isPresented: $isImporting,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImport(result)
            }
        }
    }

    private func deepLinkRow(label: String, urlString: String) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption.weight(.semibold))
                Text(urlString)
                    .font(.caption2.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
            Spacer()
            Button("Test") {
                if let url = URL(string: urlString) {
                    openURL(url)
                }
            }
            .font(.caption.weight(.bold))
            .buttonStyle(.glass)
        }
        .padding(10)
        .background(.white.opacity(0.06), in: .rect(cornerRadius: 12))
    }

    private func handleImport(_ result: Result<[URL], Error>) {
        switch result {
        case .success(let urls):
            guard let url = urls.first else { return }
            let accessed = url.startAccessingSecurityScopedResource()
            defer {
                if accessed { url.stopAccessingSecurityScopedResource() }
            }
            do {
                let data = try Data(contentsOf: url)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let payload = try decoder.decode(GlassPulseBackupPayload.self, from: data)

                let existingIDs = Set(sessions.map(\.id))
                var importedCount = 0
                for item in payload.sessions where !existingIDs.contains(item.id) {
                    modelContext.insert(
                        FocusSessionRecord(
                            id: item.id,
                            category: item.category,
                            phase: item.phase,
                            durationSeconds: item.durationSeconds,
                            completedAt: item.completedAt
                        )
                    )
                    importedCount += 1
                }
                if !payload.customPresetMinutes.isEmpty {
                    focusEngine.customPresetsMinutes = payload.customPresetMinutes
                }
                try? modelContext.save()
                backupStatusMessage = "Restored \(importedCount) new sessions & presets!"
            } catch {
                backupStatusMessage = "Restore error: \(error.localizedDescription)"
            }

        case .failure(let error):
            backupStatusMessage = "Import canceled: \(error.localizedDescription)"
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
