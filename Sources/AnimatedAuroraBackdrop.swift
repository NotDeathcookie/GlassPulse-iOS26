import SwiftUI

struct AnimatedAuroraBackdrop: View {
    var accent: Color
    @State private var animate = false

    var body: some View {
        TimelineView(.animation(minimumInterval: 1.0 / 30.0)) { timeline in
            let time = timeline.date.timeIntervalSinceReferenceDate
            let shift = Float(sin(time * 0.45) * 0.14)
            let shiftAlt = Float(cos(time * 0.35) * 0.14)

            MeshGradient(
                width: 3,
                height: 3,
                points: [
                    [0.0, 0.0], [0.5, 0.0], [1.0, 0.0],
                    [0.0, 0.5], [0.5 + shift, 0.5 + shiftAlt], [1.0, 0.5],
                    [0.0, 1.0], [0.5, 1.0], [1.0, 1.0]
                ],
                colors: [
                    Color(red: 0.05, green: 0.08, blue: 0.18),
                    accent.opacity(0.65),
                    Color(red: 0.08, green: 0.16, blue: 0.34),
                    Color(red: 0.07, green: 0.22, blue: 0.38),
                    accent.opacity(0.85),
                    Color(red: 0.12, green: 0.10, blue: 0.28),
                    Color(red: 0.03, green: 0.06, blue: 0.14),
                    Color(red: 0.06, green: 0.28, blue: 0.42),
                    Color(red: 0.05, green: 0.09, blue: 0.20)
                ]
            )
            .ignoresSafeArea()
        }
    }
}
