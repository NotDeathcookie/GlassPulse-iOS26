import SwiftData
import SwiftUI
import UIKit

@MainActor
struct PulseFocusView: View {
    @Bindable var focusEngine: FocusEngine
    @Bindable var soundEngine: AmbientSoundEngine
    var motionManager: MotionManager

    @Query(sort: \FocusSessionRecord.completedAt, order: .reverse)
    private var sessions: [FocusSessionRecord]

    @State private var showPresets = false
    @State private var showCustomSheet = false
    @State private var newPresetMinutes: Int = 45
    @Namespace private var glassNamespace

    private var activeTint: Color {
        focusEngine.currentPhase == .focus
            ? focusEngine.selectedCategory.color
            : focusEngine.currentPhase.accentColor
    }

    private var todayMinutes: Int {
        let startOfDay = Calendar.current.startOfDay(for: .now)
        return sessions
            .filter { $0.completedAt >= startOfDay }
            .reduce(0) { $0 + ($1.durationSeconds / 60) }
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedAuroraBackdrop(
                    accent: activeTint,
                    pitch: motionManager.pitch,
                    roll: motionManager.roll
                )

                ScrollView(showsIndicators: false) {
                    VStack(spacing: 20) {
                        // Top Status & Pomodoro Round Pill
                        HStack(spacing: 10) {
                            Label(focusEngine.currentPhase.rawValue, systemImage: focusEngine.currentPhase == .focus ? "flame.fill" : "cup.and.saucer.fill")
                                .font(.subheadline.weight(.semibold))
                                .foregroundStyle(activeTint)

                            Spacer()

                            Toggle(isOn: $focusEngine.pomodoroAutoCycle) {
                                Text("Auto-Cycle")
                                    .font(.caption.weight(.semibold))
                            }
                            .toggleStyle(.button)
                            .buttonStyle(.glass)
                            .tint(activeTint)

                            Text("\(todayMinutes)m Today")
                                .font(.caption.monospacedDigit().weight(.bold))
                                .padding(.horizontal, 10)
                                .padding(.vertical, 6)
                                .background(.white.opacity(0.12), in: .capsule)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .glassEffect(.regular, in: .capsule)

                        // Category Selector Pills
                        HStack(spacing: 8) {
                            ForEach(SessionCategory.allCases) { category in
                                Button {
                                    UISelectionFeedbackGenerator().selectionChanged()
                                    withAnimation(.snappy) {
                                        focusEngine.selectedCategory = category
                                    }
                                } label: {
                                    Label(category.rawValue, systemImage: category.icon)
                                        .font(.caption.weight(.semibold))
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 8)
                                }
                                .glassEffect(
                                    focusEngine.selectedCategory == category
                                        ? .regular.tint(category.color).interactive()
                                        : .regular.interactive(),
                                    in: .capsule
                                )
                            }
                        }

                        // Central Liquid Glass Dial
                        ZStack {
                            Circle()
                                .stroke(.white.opacity(0.14), lineWidth: 12)
                                .frame(width: 244, height: 244)

                            Circle()
                                .trim(from: 0, to: focusEngine.progress)
                                .stroke(
                                    AngularGradient(
                                        colors: [activeTint, .mint, .blue, activeTint],
                                        center: .center
                                    ),
                                    style: StrokeStyle(lineWidth: 12, lineCap: .round)
                                )
                                .rotationEffect(.degrees(-90))
                                .frame(width: 244, height: 244)
                                .animation(.smooth(duration: 0.4), value: focusEngine.progress)

                            VStack(spacing: 6) {
                                Text(focusEngine.isRunning ? focusEngine.selectedCategory.rawValue.uppercased() : "ROUND \((focusEngine.completedRoundsInCycle % 4) + 1)/4")
                                    .font(.caption2.weight(.bold))
                                    .tracking(1.8)
                                    .foregroundStyle(.secondary)

                                Text(focusEngine.formattedTime)
                                    .font(.system(size: 52, weight: .bold, design: .rounded))
                                    .monospacedDigit()
                                    .contentTransition(.numericText())

                                Text(focusEngine.currentPhase.rawValue)
                                    .font(.footnote.weight(.medium))
                                    .foregroundStyle(activeTint)
                            }
                            .frame(width: 206, height: 206)
                            .glassEffect(.regular.interactive(), in: .circle)
                        }
                        .padding(.vertical, 4)

                        // Morphing Liquid Glass Preset Bar
                        GlassEffectContainer(spacing: 12) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 10) {
                                    Button {
                                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                                        withAnimation(.bouncy) {
                                            showPresets.toggle()
                                        }
                                    } label: {
                                        Label(showPresets ? "Hide" : "Presets", systemImage: "timer")
                                            .font(.subheadline.weight(.semibold))
                                            .padding(.horizontal, 14)
                                            .padding(.vertical, 10)
                                    }
                                    .glassEffect(.regular.interactive(), in: .capsule)
                                    .glassEffectID("toggle", in: glassNamespace)

                                    if showPresets {
                                        ForEach(focusEngine.customPresetsMinutes, id: \.self) { mins in
                                            Button {
                                                UISelectionFeedbackGenerator().selectionChanged()
                                                withAnimation(.smooth) {
                                                    focusEngine.selectDurationMinutes(mins)
                                                }
                                            } label: {
                                                Text("\(mins)m")
                                                    .font(.subheadline.weight(.bold))
                                                    .padding(.horizontal, 13)
                                                    .padding(.vertical, 10)
                                            }
                                            .glassEffect(
                                                focusEngine.totalSeconds == mins * 60
                                                    ? .regular.tint(activeTint).interactive()
                                                    : .regular.interactive(),
                                                in: .capsule
                                            )
                                            .glassEffectID("preset_\(mins)", in: glassNamespace)
                                        }

                                        Button {
                                            showCustomSheet = true
                                        } label: {
                                            Image(systemName: "plus")
                                                .font(.subheadline.weight(.bold))
                                                .padding(11)
                                        }
                                        .glassEffect(.regular.interactive(), in: .circle)
                                        .glassEffectID("add_preset", in: glassNamespace)
                                    }
                                }
                                .padding(.horizontal, 4)
                            }
                        }

                        // Procedural Ambient Soundscape Bar
                        VStack(spacing: 10) {
                            HStack {
                                Label("Ambient Soundscape", systemImage: soundEngine.selectedMode.icon)
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Spacer()
                                Text(soundEngine.selectedMode.rawValue)
                                    .font(.caption.weight(.bold))
                                    .foregroundStyle(activeTint)
                            }

                            HStack(spacing: 8) {
                                ForEach(SoundscapeMode.allCases) { mode in
                                    Button {
                                        UISelectionFeedbackGenerator().selectionChanged()
                                        withAnimation(.snappy) {
                                            soundEngine.selectedMode = mode
                                        }
                                    } label: {
                                        VStack(spacing: 4) {
                                            Image(systemName: mode.icon)
                                                .font(.subheadline)
                                            Text(mode == .brownNoise ? "Brown" : (mode == .binaural ? "40Hz" : mode.rawValue))
                                                .font(.caption2.weight(.semibold))
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(.vertical, 8)
                                    }
                                    .glassEffect(
                                        soundEngine.selectedMode == mode
                                            ? .regular.tint(activeTint).interactive()
                                            : .regular.interactive(),
                                        in: .rect(cornerRadius: 14)
                                    )
                                }
                            }

                            if soundEngine.selectedMode != .off {
                                HStack(spacing: 10) {
                                    Image(systemName: "speaker.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Slider(value: $soundEngine.volume, in: 0.05...1.0)
                                        .tint(activeTint)
                                    Image(systemName: "speaker.wave.3.fill")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                        .padding(16)
                        .glassEffect(.regular, in: .rect(cornerRadius: 22))

                        // Primary Liquid Glass Action Controls
                        HStack(spacing: 12) {
                            Button {
                                withAnimation(.snappy) {
                                    focusEngine.toggleRun()
                                }
                            } label: {
                                Label(focusEngine.isRunning ? "Pause" : "Start Focus", systemImage: focusEngine.isRunning ? "pause.fill" : "play.fill")
                                    .font(.headline)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 14)
                            }
                            .buttonStyle(.glassProminent)
                            .tint(activeTint)

                            Button {
                                withAnimation(.snappy) {
                                    focusEngine.reset()
                                }
                            } label: {
                                Image(systemName: "arrow.counterclockwise")
                                    .font(.headline)
                                    .padding(14)
                            }
                            .buttonStyle(.glass)
                            .accessibilityLabel("Reset Timer")

                            Button {
                                withAnimation(.snappy) {
                                    focusEngine.skipPhase()
                                }
                            } label: {
                                Image(systemName: "forward.end.fill")
                                    .font(.headline)
                                    .padding(14)
                            }
                            .buttonStyle(.glass)
                            .accessibilityLabel("Skip Phase")
                        }
                        .padding(.bottom, 12)
                    }
                    .padding(.horizontal, 18)
                    .padding(.top, 8)
                }
            }
            .navigationTitle("GlassPulse")
            .navigationBarTitleDisplayMode(.inline)
            .sheet(isPresented: $showCustomSheet) {
                NavigationStack {
                    Form {
                        Section("New Custom Duration") {
                            Stepper("\(newPresetMinutes) minutes", value: $newPresetMinutes, in: 1...180, step: 5)
                            Button("Save & Select Preset") {
                                focusEngine.addCustomPreset(minutes: newPresetMinutes)
                                showCustomSheet = false
                            }
                        }

                        Section("Saved Presets (Swipe to Delete)") {
                            ForEach(focusEngine.customPresetsMinutes, id: \.self) { mins in
                                Text("\(mins) minutes")
                            }
                            .onDelete { indexSet in
                                for idx in indexSet {
                                    let val = focusEngine.customPresetsMinutes[idx]
                                    focusEngine.removeCustomPreset(minutes: val)
                                }
                            }
                        }
                    }
                    .navigationTitle("Manage Presets")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showCustomSheet = false }
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
}
