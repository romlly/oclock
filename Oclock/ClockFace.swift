import SwiftUI

/// Cadran analogique. L'aiguille des heures avance avec les minutes,
/// comme sur une vraie horloge : à 3:45 elle est presque sur le 4.
struct ClockFace: View {
    let time: ClockTime

    var body: some View {
        Canvas { context, size in
            let side = min(size.width, size.height)
            let radius = side * 0.49
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            let dial = Path(ellipseIn: CGRect(
                x: center.x - radius, y: center.y - radius,
                width: radius * 2, height: radius * 2
            ))
            context.fill(dial, with: .color(Color(.secondarySystemGroupedBackground)))
            context.stroke(dial, with: .color(.primary), lineWidth: side * 0.012)

            for tick in 0..<60 {
                let isHour = tick % 5 == 0
                let angle = Double(tick) * 6
                var path = Path()
                path.move(to: point(center, radius * (isHour ? 0.9 : 0.94), angle))
                path.addLine(to: point(center, radius * 0.98, angle))
                context.stroke(
                    path,
                    with: .color(isHour ? .primary : .secondary),
                    style: StrokeStyle(lineWidth: side * (isHour ? 0.012 : 0.005), lineCap: .round)
                )
            }

            for number in 1...12 {
                let label = Text("\(number)")
                    .font(.system(size: side * 0.075, weight: .semibold, design: .rounded))
                context.draw(label, at: point(center, radius * 0.76, Double(number) * 30))
            }

            let minuteAngle = Double(time.minute) * 6
            let hourAngle = (Double(time.hour % 12) + Double(time.minute) / 60) * 30
            drawHand(in: context, center, length: radius * 0.45, angle: hourAngle, width: side * 0.03, color: .primary)
            // Bleu fixe : `.accentColor` suivrait le thème dans les fenêtres présentées.
            drawHand(in: context, center, length: radius * 0.6, angle: minuteAngle, width: side * 0.016, color: .blue)

            let dot = side * 0.025
            context.fill(
                Path(ellipseIn: CGRect(x: center.x - dot, y: center.y - dot, width: dot * 2, height: dot * 2)),
                with: .color(.primary)
            )
        }
        .aspectRatio(1, contentMode: .fit)
    }

    private func drawHand(
        in context: GraphicsContext, _ center: CGPoint,
        length: Double, angle: Double, width: Double, color: Color
    ) {
        var path = Path()
        path.move(to: center)
        path.addLine(to: point(center, length, angle))
        context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: width, lineCap: .round))
    }

    /// Angle en degrés, 0 à midi, dans le sens des aiguilles.
    private func point(_ center: CGPoint, _ distance: Double, _ angle: Double) -> CGPoint {
        let radians = angle * .pi / 180
        return CGPoint(
            x: center.x + distance * sin(radians),
            y: center.y - distance * cos(radians)
        )
    }
}
