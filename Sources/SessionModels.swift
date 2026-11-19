import Foundation
import SwiftData
import SwiftUI
import UniformTypeIdentifiers

@Model
final class FocusSessionRecord {
    var id: UUID
    var category: String
    var phase: String
    var durationSeconds: Int
    var completedAt: Date

    init(
        id: UUID = UUID(),
        category: String,
        phase: String = "Focus",
        durationSeconds: Int,
        completedAt: Date = .now
    ) {
        self.id = id
        self.category = category
        self.phase = phase
        self.durationSeconds = durationSeconds
        self.completedAt = completedAt
    }
}

enum SessionCategory: String, CaseIterable, Identifiable, Codable {
    case code = "Code"
    case study = "Study"
    case workout = "Workout"
    case design = "Design"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .code: return "chevron.left.forwardslash.chevron.right"
        case .study: return "book.fill"
        case .workout: return "figure.run"
        case .design: return "paintbrush.pointed.fill"
        }
    }

    var color: Color {
        switch self {
        case .code: return .cyan
        case .study: return .indigo
        case .workout: return .orange
        case .design: return .pink
        }
    }
}

enum PomodoroPhase: String, CaseIterable, Identifiable {
    case focus = "Focus"
    case shortBreak = "Short Break"
    case longBreak = "Long Break"

    var id: String { rawValue }

    var accentColor: Color {
        switch self {
        case .focus: return .cyan
        case .shortBreak: return .mint
        case .longBreak: return .orange
        }
    }

    var defaultSeconds: Int {
        switch self {
        case .focus: return 25 * 60
        case .shortBreak: return 5 * 60
        case .longBreak: return 15 * 60
        }
    }
}

struct SessionBackupDTO: Codable {
    let id: UUID
    let category: String
    let phase: String
    let durationSeconds: Int
    let completedAt: Date
}

struct GlassPulseBackupPayload: Codable {
    let exportedAt: Date
    let appVersion: String
    let customPresetMinutes: [Int]
    let sessions: [SessionBackupDTO]
}

struct GlassPulseBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.json] }

    var payload: GlassPulseBackupPayload

    init(payload: GlassPulseBackupPayload) {
        self.payload = payload
    }

    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents else {
            throw CocoaError(.fileReadCorruptFile)
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        self.payload = try decoder.decode(GlassPulseBackupPayload.self, from: data)
    }

    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(payload)
        return FileWrapper(regularFileWithContents: data)
    }
}
