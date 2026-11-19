import Combine
import SwiftUI
import UIKit

enum FocusPreset: Int, CaseIterable, Identifiable {
    case quick = 60
    case sprint = 300
    case deep = 900
    case pomodoro = 1500

    var id: Int { rawValue }

    var label: String {
        switch self {
        case .quick: return "1m"
        case .sprint: return "5m"
        case .deep: return "15m"
        case .pomodoro: return "25m"
        }
    }
}

@MainActor
struct PulseFocusView: View {
    @AppStorage("completedSessions") private var completedSessions = 0
    @State private var selectedPreset: FocusPreset = .sprint
    @State private var remainingSeconds: Int = FocusPreset.sprint.rawValue
    @State private var isRunning = false
    @State private var showPresets = false
    @Namespace private var glassNamespace

    private let ticker = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var progress: Double {
        let total = Double(selectedPreset.rawValue)
        guard total > 0 else { return 0 }
        return max(0, min(1, 1.0 - (Double(remainingSeconds) / total)))
    }

    private var formattedTime: String {
        let mins = remainingSeconds / 60
        let secs = remainingSeconds % 60
        return String(format: "%02d:%02d", mins, secs)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedAuroraBackdrop(accent: .cyan)

                VStack(spacing: 28) {
                    // Header pill
                    HStack {
                        Label("iOS 26 Liquid Glass", systemImage: "sparkles")
                            .font(.subheadline.weight(.semibold))
                        Spacer()
                        Text("\(completedSessions) Done")
                            .font(.subheadline.monospacedDigit().weight(.bold))
                            .foregroundStyle(.cyan)
                    }
                    .padding(.horizontal, 18)
                    .padding(.vertical, 12)
                    .glassEffect(.regular, in: .capsule)

                    Spacer()

                    // Central Liquid Glass Dial
                    ZStack {
                        Circle()
                            .stroke(.white.opacity(0.15), lineWidth: 12)
                            .frame(width: 250, height: 250)

                        Circle()
                            .trim(from: 0, to: progress)
                            .stroke(
                                AngularGradient(
                                    colors: [.cyan, .mint, .blue, .cyan],
                                    center: .center
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 250, height: 250)
                            .animation(.smooth(duration: 0.45), value: progress)

                        VStack(spacing: 8) {
                            Text(isRunning ? "FOCUSING" : "READY")
                                .font(.caption.weight(.bold))
                                .tracking(2)
                                .foregroundStyle(.secondary)

                            Text(formattedTime)
                                .font(.system(size: 54, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .contentTransition(.numericText())

                            Text("\(selectedPreset.label) Session")
                                .font(.footnote.weight(.medium))
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: 212, height: 212)
                        .glassEffect(.regular.interactive(), in: .circle)
                    }

                    // Morphing Liquid Glass Preset Bar
                    GlassEffectContainer(spacing: 14) {
                        HStack(spacing: 12) {
                            Button {
                                triggerHaptic(.light)
                                withAnimation(.bouncy) {
                                    showPresets.toggle()
                                }
                            } label: {
                                Label(showPresets ? "Hide" : "Duration", systemImage: "timer")
                                    .font(.subheadline.weight(.semibold))
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 12)
                            }
                            .glassEffect(.regular.interactive(), in: .capsule)
                            .glassEffectID("toggle", in: glassNamespace)

                            if showPresets {
                                ForEach(FocusPreset.allCases) { preset in
                                    Button {
                                        triggerHaptic(.selection)
                                        withAnimation(.smooth) {
                                            selectedPreset = preset
                                            isRunning = false
                                            remainingSeconds = preset.rawValue
                                        }
                                    } label: {
                                        Text(preset.label)
                                            .font(.subheadline.weight(.bold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 12)
                                    }
                                    .glassEffect(
                                        selectedPreset == preset
                                            ? .regular.tint(.cyan).interactive()
                                            : .regular.interactive(),
                                        in: .capsule
                                    )
                                    .glassEffectID("preset_\(preset.rawValue)", in: glassNamespace)
                                }
                            }
                        }
                    }

                    Spacer()

                    // Primary Liquid Glass Action Controls
                    HStack(spacing: 16) {
                        Button {
                            triggerHaptic(.medium)
                            withAnimation(.snappy) {
                                isRunning.toggle()
                            }
                        } label: {
                            Label(isRunning ? "Pause" : "Start Focus", systemImage: isRunning ? "pause.fill" : "play.fill")
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 14)
                        }
                        .buttonStyle(.glassProminent)
                        .tint(.cyan)

                        Button {
                            triggerHaptic(.light)
                            withAnimation(.snappy) {
                                isRunning = false
                                remainingSeconds = selectedPreset.rawValue
                            }
                        } label: {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.headline)
                                .padding(14)
                        }
                        .buttonStyle(.glass)
                        .accessibilityLabel("Reset Timer")
                    }
                    .padding(.bottom, 12)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
            }
            .navigationTitle("GlassPulse")
            .navigationBarTitleDisplayMode(.inline)
            .onReceive(ticker) { _ in
                guard isRunning else { return }
                if remainingSeconds > 0 {
                    withAnimation(.linear(duration: 0.25)) {
                        remainingSeconds -= 1
                    }
                } else {
                    isRunning = false
                    completedSessions += 1
                    remainingSeconds = selectedPreset.rawValue
                    triggerHaptic(.success)
                }
            }
        }
    }

    private enum HapticKind {
        case light, medium, selection, success
    }

    private func triggerHaptic(_ kind: HapticKind) {
        switch kind {
        case .light:
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        case .medium:
            UIImpactFeedbackGenerator(style: .medium).impactOccurred()
        case .selection:
            UISelectionFeedbackGenerator().selectionChanged()
        case .success:
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        }
    }
}
