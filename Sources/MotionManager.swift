import CoreMotion
import Foundation
import Observation

@MainActor
@Observable
final class MotionManager {
    var pitch: Double = 0.0
    var roll: Double = 0.0
    var isEnabled: Bool = true {
        didSet {
            if isEnabled {
                start()
            } else {
                stop()
            }
        }
    }
    var isAvailable: Bool = false

    private let manager = CMMotionManager()
    private let queue: OperationQueue = {
        let q = OperationQueue()
        q.name = "com.github.glasspulse.motion"
        q.maxConcurrentOperationCount = 1
        return q
    }()

    init() {
        isAvailable = manager.isDeviceMotionAvailable
        if isEnabled {
            start()
        }
    }

    func start() {
        guard manager.isDeviceMotionAvailable else {
            isAvailable = false
            return
        }
        isAvailable = true
        guard !manager.isDeviceMotionActive else { return }
        manager.deviceMotionUpdateInterval = 1.0 / 30.0
        manager.startDeviceMotionUpdates(to: queue) { [weak self] motion, _ in
            guard let motion else { return }
            let clampedPitch = max(-0.6, min(0.6, motion.attitude.pitch - 0.5))
            let clampedRoll = max(-0.6, min(0.6, motion.attitude.roll))
            Task { @MainActor [weak self] in
                guard let self, self.isEnabled else { return }
                self.pitch = self.pitch * 0.8 + clampedPitch * 0.2
                self.roll = self.roll * 0.8 + clampedRoll * 0.2
            }
        }
    }

    func stop() {
        if manager.isDeviceMotionActive {
            manager.stopDeviceMotionUpdates()
        }
        pitch = 0.0
        roll = 0.0
    }
}
