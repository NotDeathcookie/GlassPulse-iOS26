import SwiftUI

struct AnimatedAuroraBackdrop: View {
    var accent: Color
    var pitch: Double = 0.0
    var roll: Double = 0.0

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let ambientX = Float(sin(time * 0.42) * 0.11)
            let ambientY = Float(cos(time * 0.34) * 0.11)
            let gyroX = Float(roll * 0.32)
            let gyroY = Float(pitch * 0.32)

            let cx = max(0.18, min(0.82, 0.5 + ambientX + gyroX))
            let cy = max(0.18, min(0.82, 0.5 + ambientY + gyroY))

            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5 + gyroX * 0.25, 0.0], [1.0, 0.0],
                    [0.0, 0.5 + gyroY * 0.25], [cx, cy], [1.0, 0.5 - gyroY * 0.25],
                    [0.0, 1.0], [0.5 - gyroX * 0.25, 1.0], [1.0, 1.0]
                ],
                colors: [
                    Color(red: 0.04, green: 0.07, blue: 0.16),
                    accent.opacity(0.68),
                    Color(red: 0.07, green: 0.15, blue: 0.32),
                    Color(red: 0.06, green: 0.20, blue: 0.36),
                    accent.opacity(0.88),
                    Color(red: 0.11, green: 0.09, blue: 0.27),
                    Color(red: 0.03, green: 0.05, blue: 0.13),
                    Color(red: 0.05, green: 0.26, blue: 0.40),
                    Color(red: 0.04, green: 0.08, blue: 0.18)
                ]
            )
            .ignoresSafeArea()
        }
    }
}
