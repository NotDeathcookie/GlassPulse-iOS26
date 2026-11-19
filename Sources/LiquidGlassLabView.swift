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
    @State private var selectedTint: GlassTintOption = .cyan
    @State private var useClearGlass = false
    @State private var interactiveTouch = true
    @State private var morphSpacing: CGFloat = 18
    @State private var mergedCluster = false
    @Namespace private var labNamespace

    private var activeGlass: Glass {
        let base: Glass = useClearGlass ? .clear : .regular
        let tinted = base.tint(selectedTint.color)
        return interactiveTouch ? tinted.interactive() : tinted
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AnimatedAuroraBackdrop(accent: selectedTint.color)

                ScrollView {
                    VStack(spacing: 22) {
                        // Live Interactive Preview Card
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "drop.halffull")
                                    .font(.title2)
                                    .foregroundStyle(selectedTint.color)
                                Text("Interactive Liquid Glass")
                                    .font(.headline)
                                Spacer()
                                Text(useClearGlass ? "CLEAR" : "REGULAR")
                                    .font(.caption2.weight(.bold))
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.white.opacity(0.14), in: .capsule)
                            }

                            Text("Touch and drag across this card or toggle morph spacing below to see iOS 26 refraction, specular highlights, and shape merging in real time.")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .padding(20)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .glassEffect(activeGlass, in: .rect(cornerRadius: 24))

                        // Morphing Orb Cluster inside GlassEffectContainer
                        VStack(spacing: 12) {
                            Text("GlassEffectContainer Morph Cluster")
                                .font(.caption.weight(.semibold))
                                .foregroundStyle(.secondary)

                            GlassEffectContainer(spacing: morphSpacing) {
                                HStack(spacing: mergedCluster ? 6 : 24) {
                                    ForEach(["waveform", "sparkles", "cpu", "bolt.fill"], id: \.self) { symbol in
                                        Image(systemName: symbol)
                                            .font(.title2.weight(.semibold))
                                            .frame(width: 60, height: 60)
                                            .glassEffect(activeGlass, in: .circle)
                                            .glassEffectID(symbol, in: labNamespace)
                                    }
                                }
                                .padding(.vertical, 8)
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

                        // Controls Panel
                        VStack(alignment: .leading, spacing: 16) {
                            Text("Material Controls")
                                .font(.headline)

                            Picker("Tint", selection: $selectedTint) {
                                ForEach(GlassTintOption.allCases) { option in
                                    Text(option.rawValue).tag(option)
                                }
                            }
                            .pickerStyle(.segmented)

                            Toggle("Clear Glass Variant (.clear)", isOn: $useClearGlass)
                            Toggle("Touch Refraction (.interactive)", isOn: $interactiveTouch)

                            VStack(alignment: .leading, spacing: 6) {
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
                    .padding(20)
                }
            }
            .navigationTitle("Liquid Lab")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
