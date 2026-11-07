import SwiftUI

/// Rappel permanent : grande aiguille à droite du cadran, past ; à gauche, to.
struct PastToDiagram: View {
    var dialSize: CGFloat = 76

    private let toColor = Color.orange
    private let pastColor = Color.blue

    var body: some View {
        HStack(spacing: 10) {
            label("TO", detail: "avant", color: toColor)
            dial
                .frame(width: dialSize, height: dialSize)
            label("PAST", detail: "après", color: pastColor)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Schéma : à gauche du cadran to, à droite du cadran past")
    }

    private var dial: some View {
        Canvas { context, size in
            let radius = min(size.width, size.height) * 0.47
            let center = CGPoint(x: size.width / 2, y: size.height / 2)

            context.fill(half(center, radius, from: 90, to: 270), with: .color(toColor.opacity(0.35)))
            context.fill(half(center, radius, from: -90, to: 90), with: .color(pastColor.opacity(0.35)))

            var divider = Path()
            divider.move(to: CGPoint(x: center.x, y: center.y - radius))
            divider.addLine(to: CGPoint(x: center.x, y: center.y + radius))
            context.stroke(divider, with: .color(.primary), lineWidth: 1.5)

            let dialRect = CGRect(
                x: center.x - radius, y: center.y - radius,
                width: radius * 2, height: radius * 2
            )
            context.stroke(Path(ellipseIn: dialRect), with: .color(.primary), lineWidth: 2)

            let font = Font.system(size: 12, weight: .bold, design: .rounded)
            for (number, y) in [(12, center.y - radius * 0.72), (6, center.y + radius * 0.72)] {
                var background = Path()
                background.addEllipse(in: CGRect(x: center.x - 9, y: y - 8, width: 18, height: 16))
                context.fill(background, with: .color(Color(.systemGroupedBackground)))
                context.draw(Text("\(number)").font(font), at: CGPoint(x: center.x, y: y))
            }
        }
    }

    private func half(_ center: CGPoint, _ radius: Double, from start: Double, to end: Double) -> Path {
        var path = Path()
        path.move(to: center)
        path.addArc(
            center: center, radius: radius,
            startAngle: .degrees(start), endAngle: .degrees(end), clockwise: false
        )
        path.closeSubpath()
        return path
    }

    private func label(_ title: String, detail: String, color: Color) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.title2.weight(.heavy))
                .foregroundStyle(color)
            Text(detail)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .frame(minWidth: dialSize < 76 ? 52 : 64)
        .fixedSize()
    }
}
