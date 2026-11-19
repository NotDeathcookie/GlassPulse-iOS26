import SwiftUI

enum GlassTintOption: String, CaseIterable, Identifiable {
    case cyan = "Cyan"
    case indigo = "Indigo"
    case mint = "Mint"
    case orange = "Amber"
    case pink = "Rose"

    var id: String { rawValue }

    var color: Color {
        switch self {
        case .cyan: return .cyan
        case .indigo: return .indigo
        case .mint: return .mint
        case .orange: return .orange
        case .pink: return .pink
        }
    }
}

@MainActor
struct LiquidGlassLabView: View {
    @Bindable var motionManager: MotionManager

    @State private var selectedTint: GlassTintOption = .cyan
    @State private var useClearGlass = false
    @State private var interactiveTouch = true
    @State private var morphSpacing: CGFloat = 18
    @State private var mergedCluster = false

    // Metal Shader Controls
    @State private var rippleOrigin = CGPoint(x: 160, y: 90)
    @State private var rippleAmplitude: Double = 8.0
    @State private var chromaticShift: Double = 2.0
    @State private var shaderStartDate = Date.now

    @Namespace private var labNamespace

    private var activeGlass: Glass {
        let base: Glass = useClearGlass ? .clear : .regular
        let tinted = base.tint(selectedTint.color)
        return interactiveTouch ? tinted.interactive() : tinted
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedAuroraBackdrop(
                    accent: selectedTint.color,
                    pitch: motionManager.pitch,
                    roll: motionManager.roll
                )

                ScrollView {
                    VStack(spacing: 20) {
                        // Metal Shader + Liquid Glass Interactive Canvas
                        TimelineView(.animation(minimumInterval: 1.0 / 60.0)) { timeline in
                            let elapsed = timeline.date.timeIntervalSince(shaderStartDate)

                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "wand.and.sparkles")
                                        .font(.title2)
                                        .foregroundStyle(selectedTint.color)
                                    Text("Metal Ripple & Prism Glass")
                                        .font(.headline)
                                    Spacer()
                                    Text(useClearGlass ? "CLEAR" : "REGULAR")
                                        .font(.caption2.weight(.bold))
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(.white.opacity(0.14), in: .capsule)
                                }

                                Text("Touch or drag anywhere on this card to emit GPU Metal wave distortions and chromatic prism refraction beneath iOS 26 Liquid Glass.")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassEffect(activeGlass, in: .rect(cornerRadius: 24))
                            .layerEffect(
                                ShaderLibrary.chromaticPrism(
                                    .float(chromaticShift),
                                    .float(elapsed)
                                ),
                                maxSampleOffset: CGSize(width: 16, height: 16)
                            )
                            .distortionEffect(
                                ShaderLibrary.liquidRipple(
                                    .float2(rippleOrigin),
                                    .float(elapsed),
                                    .float(rippleAmplitude),
                                    .float(0.055)
                                ),
                                maxSampleOffset: CGSize(width: 24, height: 24)
                            )
                            .gesture(
                                DragGesture(minimumDistance: 0)
                                    .onChanged { value in
                                        rippleOrigin = value.location
                                    }
                            )
                        }

                        // Morphing Orb Cluster inside GlassEffectContainer
                        VStack(spacing: 12) {
                            Text("GlassEffectContainer Morph Cluster")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            GlassEffectContainer(spacing: morphSpacing) {
                                HStack(spacing: mergedCluster ? 6 : 22) {
                                    ForEach(["waveform", "sparkles", "cpu", "bolt.fill"], id: \.self) { symbol in
                                        Image(systemName: symbol)
                                            .font(.title2.weight(.semibold))
                                            .frame(width: 58, height: 58)
                                            .glassEffect(activeGlass, in: .circle)
                                            .glassEffectID(symbol, in: labNamespace)
                                    }
                                }
                                .padding(.vertical, 6)
                            }

                            Button {
                                withAnimation(.bouncy(duration: 0.5)) {
                                    mergedCluster.toggle()
                                }
                            } label: {
                                Label(
                                    mergedCluster ? "Separate Glass Orbs" : "Merge Glass Orbs",
                                    systemImage: mergedCluster ? "arrow.up.left.and.arrow.down.right" : "arrow.down.right.and.arrow.up.left"
                                )
                                .font(.subheadline.weight(.semibold))
                            }
                            .buttonStyle(.glass)
                        }
                        .padding(18)
                        .frame(maxWidth: .infinity)
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))

                        // Shader, Material & CoreMotion Controls
                        VStack(alignment: .leading, spacing: 14) {
                            Text("Shader, Glass & Gyroscope Controls")
                                .font(.headline)

                            Picker("Tint", selection: $selectedTint) {
                                ForEach(GlassTintOption.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)

                            Toggle("Clear Glass Variant (.clear)", isOn: $useClearGlass)
                            Toggle("Touch Refraction (.interactive)", isOn: $interactiveTouch)
                            Toggle("Gyroscope Light Tilt (CoreMotion)", isOn: $motionManager.isEnabled)

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Metal Ripple Amplitude")
                                    Spacer()
                                    Text(String(format: "%.1f pt", rippleAmplitude))
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                Slider(value: $rippleAmplitude, in: 0...22, step: 0.5)
                                    .tint(selectedTint.color)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Chromatic Prism Dispersion")
                                    Spacer()
                                    Text(String(format: "%.1f px", chromaticShift))
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                Slider(value: $chromaticShift, in: 0...10, step: 0.5)
                                    .tint(selectedTint.color)
                            }

                            VStack(alignment: .leading, spacing: 4) {
                                HStack {
                                    Text("Container Blend Spacing")
                                    Spacer()
                                    Text("\(Int(morphSpacing)) pt")
                                        .monospacedDigit()
                                        .foregroundStyle(.secondary)
                                }
                                Slider(value: $morphSpacing, in: 0...48, step: 2)
                                    .tint(selectedTint.color)
                            }
                        }
                        .padding(20)
                        .glassEffect(.regular, in: .rect(cornerRadius: 24))
                    }
                    .padding(18)
                }
            }
            .navigationTitle("Liquid Lab")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
