import AVFoundation
import Foundation
import Observation
import os

enum SoundscapeMode: String, CaseIterable, Identifiable {
    case off = "Off"
    case brownNoise = "Brown Noise"
    case rain = "Soft Rain"
    case binaural = "40Hz Focus"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .off: return "speaker.slash.fill"
        case .brownNoise: return "waveform"
        case .rain: return "cloud.rain.fill"
        case .binaural: return "brain.head.profile"
        }
    }
}

final class AudioSynthState: @unchecked Sendable {
    struct Parameters: Sendable {
        var mode: SoundscapeMode = .off
        var volume: Float = 0.45
        var brownLast: Float = 0.0
        var rainFilter: Float = 0.0
        var dropEnvelope: Float = 0.0
        var phaseLeft: Double = 0.0
        var phaseRight: Double = 0.0
        var rngState: UInt64 = 0x123456789ABCDEF
    }

    private let lock = OSAllocatedUnfairLock(initialState: Parameters())

    func setMode(_ mode: SoundscapeMode) {
        lock.withLock { $0.mode = mode }
    }

    func setVolume(_ volume: Float) {
        lock.withLock { $0.volume = max(0, min(1, volume)) }
    }

    func render(frameCount: Int, sampleRate: Double, leftBuffer: UnsafeMutablePointer<Float>, rightBuffer: UnsafeMutablePointer<Float>) {
        var state = lock.withLock { $0 }

        guard state.mode != .off, state.volume > 0.001 else {
            for i in 0..<frameCount {
                leftBuffer[i] = 0
                rightBuffer[i] = 0
            }
            return
        }

        let vol = state.volume
        for i in 0..<frameCount {
            state.rngState ^= state.rngState << 13
            state.rngState ^= state.rngState >> 7
            state.rngState ^= state.rngState << 17
            let white = Float(Int64(bitPattern: state.rngState)) / Float(Int64.max)

            switch state.mode {
            case .off:
                leftBuffer[i] = 0
                rightBuffer[i] = 0

            case .brownNoise:
                state.brownLast = (state.brownLast + (0.025 * white)) / 1.025
                let sample = max(-1.0, min(1.0, state.brownLast * 3.2)) * vol
                leftBuffer[i] = sample
                rightBuffer[i] = sample * 0.96

            case .rain:
                state.rainFilter = state.rainFilter * 0.88 + white * 0.12
                if (state.rngState & 0x3FFF) == 1 {
                    state.dropEnvelope = 0.35
                }
                state.dropEnvelope *= 0.996
                let bed = state.rainFilter * 1.9
                let drop = white * state.dropEnvelope
                leftBuffer[i] = max(-1.0, min(1.0, (bed + drop * 0.8))) * vol
                rightBuffer[i] = max(-1.0, min(1.0, (bed * 0.95 + drop * 1.1))) * vol

            case .binaural:
                let incL = 200.0 / sampleRate
                let incR = 240.0 / sampleRate
                state.phaseLeft += incL
                if state.phaseLeft >= 1.0 { state.phaseLeft -= 1.0 }
                state.phaseRight += incR
                if state.phaseRight >= 1.0 { state.phaseRight -= 1.0 }

                state.brownLast = (state.brownLast + (0.015 * white)) / 1.015
                let bed = state.brownLast * 0.75
                let toneL = Float(sin(state.phaseLeft * 2.0 * .pi)) * 0.24
                let toneR = Float(sin(state.phaseRight * 2.0 * .pi)) * 0.24
                leftBuffer[i] = max(-1.0, min(1.0, toneL + bed)) * vol
                rightBuffer[i] = max(-1.0, min(1.0, toneR + bed)) * vol
            }
        }

        let updatedBrown = state.brownLast
        let updatedRain = state.rainFilter
        let updatedDrop = state.dropEnvelope
        let updatedPhaseL = state.phaseLeft
        let updatedPhaseR = state.phaseRight
        let updatedRng = state.rngState

        lock.withLock { current in
            current.brownLast = updatedBrown
            current.rainFilter = updatedRain
            current.dropEnvelope = updatedDrop
            current.phaseLeft = updatedPhaseL
            current.phaseRight = updatedPhaseR
            current.rngState = updatedRng
        }
    }
}

@MainActor
@Observable
final class AmbientSoundEngine {
    var selectedMode: SoundscapeMode = .off {
        didSet {
            synthState.setMode(selectedMode)
            if selectedMode == .off {
                stopEngineIfIdle()
            } else {
                startEngineIfNeeded()
            }
        }
    }

    var volume: Double = 0.45 {
        didSet {
            synthState.setVolume(Float(volume))
        }
    }

    private let engine = AVAudioEngine()
    private let synthState = AudioSynthState()
    private var sourceNode: AVAudioSourceNode?
    private var isConfigured = false

    func startEngineIfNeeded() {
        configureSession()
        if !isConfigured {
            setupNode()
        }
        if !engine.isRunning {
            try? engine.start()
        }
    }

    func stopEngineIfIdle() {
        if engine.isRunning {
            engine.pause()
        }
    }

    private func configureSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .default, options: [.mixWithOthers])
        try? session.setActive(true)
    }

    private func setupNode() {
        let format = engine.outputNode.inputFormat(forBus: 0)
        let sampleRate = format.sampleRate > 0 ? format.sampleRate : 44_100.0
        let state = synthState

        let node = AVAudioSourceNode { _, _, frameCount, audioBufferList -> OSStatus in
            let ablPointer = UnsafeMutableAudioBufferListPointer(audioBufferList)
            let count = Int(frameCount)
            guard let leftPtr = ablPointer[0].mData?.assumingMemoryBound(to: Float.self) else {
                return noErr
            }
            let rightPtr: UnsafeMutablePointer<Float>
            if ablPointer.count > 1, let rPtr = ablPointer[1].mData?.assumingMemoryBound(to: Float.self) {
                rightPtr = rPtr
            } else {
                rightPtr = leftPtr
            }
            state.render(frameCount: count, sampleRate: sampleRate, leftBuffer: leftPtr, rightBuffer: rightPtr)
            return noErr
        }

        sourceNode = node
        engine.attach(node)
        engine.connect(node, to: engine.mainMixerNode, format: format)
        isConfigured = true
    }
}
