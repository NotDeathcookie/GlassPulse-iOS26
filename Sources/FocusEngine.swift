import Combine
import Foundation
import Observation
import SwiftData
import SwiftUI
import UIKit

@MainActor
@Observable
final class FocusEngine {
    var selectedCategory: SessionCategory = .code
    var currentPhase: PomodoroPhase = .focus
    var pomodoroAutoCycle: Bool = true
    var completedRoundsInCycle: Int = 0

    var customPresetsMinutes: [Int] = [1, 5, 15, 25] {
        didSet {
            savePresets()
        }
    }

    var totalSeconds: Int = 5 * 60
    var remainingSeconds: Int = 5 * 60
    var isRunning: Bool = false

    weak var modelContext: ModelContext?
    private var timerCancellable: AnyCancellable?
    private let presetsDefaultsKey = "glasspulse.customPresets.v2"

    var progress: Double {
        guard totalSeconds > 0 else { return 0 }
        return max(0, min(1, 1.0 - (Double(remainingSeconds) / Double(totalSeconds))))
    }

    var formattedTime: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var hasActiveSession: Bool {
        isRunning || (remainingSeconds > 0 && remainingSeconds < totalSeconds)
    }

    init() {
        loadPresets()
        timerCancellable = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    func selectDurationMinutes(_ minutes: Int, autoStart: Bool = false) {
        let clamped = max(1, min(180, minutes))
        isRunning = autoStart
        totalSeconds = clamped * 60
        remainingSeconds = clamped * 60
    }

    func addCustomPreset(minutes: Int) {
        let clamped = max(1, min(180, minutes))
        if !customPresetsMinutes.contains(clamped) {
            customPresetsMinutes.append(clamped)
            customPresetsMinutes.sort()
        }
        selectDurationMinutes(clamped)
    }

    func removeCustomPreset(minutes: Int) {
        guard customPresetsMinutes.count > 1 else { return }
        customPresetsMinutes.removeAll { $0 == minutes }
    }

    func toggleRun() {
        isRunning.toggle()
        triggerPhaseHaptic(isRunning ? .start : .pause)
    }

    func reset() {
        isRunning = false
        remainingSeconds = totalSeconds
        triggerPhaseHaptic(.pause)
    }

    func skipPhase() {
        completeCurrentPhase(recordToHistory: false)
    }

    private func tick() {
        guard isRunning else { return }
        if remainingSeconds > 1 {
            remainingSeconds -= 1
        } else {
            remainingSeconds = 0
            completeCurrentPhase(recordToHistory: true)
        }
    }

    private func completeCurrentPhase(recordToHistory: Bool) {
        isRunning = false
        triggerPhaseHaptic(.complete)

        if recordToHistory && currentPhase == .focus {
            let record = FocusSessionRecord(
                category: selectedCategory.rawValue,
                phase: currentPhase.rawValue,
                durationSeconds: totalSeconds,
                completedAt: .now
            )
            modelContext?.insert(record)
            try? modelContext?.save()
        }

        if pomodoroAutoCycle {
            advancePomodoroPhase()
        } else {
            remainingSeconds = totalSeconds
        }
    }

    private func advancePomodoroPhase() {
        switch currentPhase {
        case .focus:
            completedRoundsInCycle += 1
            if completedRoundsInCycle % 4 == 0 {
                currentPhase = .longBreak
            } else {
                currentPhase = .shortBreak
            }
            totalSeconds = currentPhase.defaultSeconds
            remainingSeconds = totalSeconds
            isRunning = true

        case .shortBreak, .longBreak:
            currentPhase = .focus
            totalSeconds = currentPhase.defaultSeconds
            remainingSeconds = totalSeconds
            isRunning = false
        }
    }

    private func savePresets() {
        if let data = try? JSONEncoder().encode(customPresetsMinutes) {
            UserDefaults.standard.set(data, forKey: presetsDefaultsKey)
        }
    }

    private func loadPresets() {
        if let data = UserDefaults.standard.data(forKey: presetsDefaultsKey),
           let decoded = try? JSONDecoder().decode([Int].self, from: data),
           !decoded.isEmpty {
            customPresetsMinutes = decoded
        }
    }

    enum PhaseHaptic {
        case start, pause, complete
    }

    func triggerPhaseHaptic(_ kind: PhaseHaptic) {
        switch kind {
        case .start:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .pause:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .complete:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(currentPhase == .focus ? .success : .warning)
        }
    }
}
