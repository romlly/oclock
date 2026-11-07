import SwiftUI

/// La piste de la marge du bas. En entraînement, le cheval part au galop sur une
/// bonne réponse et refuse l'obstacle sur une mauvaise. En parcours, il saute un
/// obstacle à chaque question, sans rien dévoiler avant l'écran final.
struct HorseLane: View {
    let isTest: Bool
    let position: Int
    let isFinished: Bool
    let fallen: Set<Int>
    let runs: Int
    let lastCorrect: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private let horseSize: CGFloat = 44
    private let margin: CGFloat = 12

    var body: some View {
        GeometryReader { geometry in
            let track = geometry.size.width - horseSize - margin * 2

            ZStack(alignment: .bottomLeading) {
                if isTest {
                    obstacles(track: track)
                    courseHorse(track: track)
                } else {
                    trainingHorse(track: track)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
        }
        .frame(height: 50)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }

    private var horse: some View {
        Text("🐎")
            .font(.system(size: horseSize))
            .fixedSize()
    }

    private func courseHorse(track: CGFloat) -> some View {
        horse
            .scaleEffect(x: -1, y: 1)
            .offset(x: margin + track * Double(position) / Double(Quiz.testLength), y: -4)
            .animation(reduceMotion ? nil : .easeInOut(duration: 0.5), value: position)
            .keyframeAnimator(initialValue: 0.0, trigger: reduceMotion ? 0 : position) { content, hop in
                content.offset(y: hop)
            } keyframes: { _ in
                KeyframeTrack {
                    CubicKeyframe(-30, duration: 0.25)
                    CubicKeyframe(0, duration: 0.25)
                }
            }
    }

    private func trainingHorse(track: CGFloat) -> some View {
        let correct = lastCorrect

        return horse
            .keyframeAnimator(
                initialValue: RunPose(),
                trigger: reduceMotion ? 0 : runs
            ) { content, pose in
                content
                    .scaleEffect(x: pose.facing, y: 1)
                    .offset(x: margin + track * pose.progress, y: pose.hop - 4)
            } keyframes: { _ in
                KeyframeTrack(\.progress) {
                    LinearKeyframe(correct ? 1.2 : 0.35, duration: correct ? 1.3 : 0.5)
                    CubicKeyframe(correct ? 1.2 : 0.35, duration: 0.3)
                    LinearKeyframe(correct ? 1.2 : 0, duration: 0.5)
                    // Sorti à droite, il revient par la gauche : la piste ne reste jamais vide.
                    LinearKeyframe(correct ? -0.2 : 0, duration: 0.01)
                    LinearKeyframe(0, duration: 0.5)
                }
                KeyframeTrack(\.facing) {
                    LinearKeyframe(-1, duration: 0.8)
                    LinearKeyframe(correct ? -1 : 1, duration: 0.02)
                    LinearKeyframe(correct ? -1 : 1, duration: 0.48)
                    LinearKeyframe(-1, duration: 0.02)
                }
                KeyframeTrack(\.hop) {
                    CubicKeyframe(-12, duration: 0.1)
                    CubicKeyframe(0, duration: 0.1)
                    CubicKeyframe(-12, duration: 0.1)
                    CubicKeyframe(0, duration: 0.1)
                    CubicKeyframe(-12, duration: 0.1)
                    CubicKeyframe(0, duration: 0.1)
                    CubicKeyframe(-12, duration: 0.1)
                    CubicKeyframe(0, duration: 0.1)
                    CubicKeyframe(-12, duration: 0.1)
                    CubicKeyframe(0, duration: 0.1)
                    CubicKeyframe(-12, duration: 0.1)
                    CubicKeyframe(0, duration: 0.1)
                }
            }
    }

    private func obstacles(track: CGFloat) -> some View {
        Canvas { context, size in
            for number in 1...Quiz.testLength {
                let x = margin + horseSize / 2 + track * (Double(number) - 0.5) / Double(Quiz.testLength)
                let ground = size.height - 6
                let fell = isFinished && fallen.contains(number)

                for postX in [x - 9, x + 7] {
                    let post = CGRect(x: postX, y: ground - 24, width: 3, height: 24)
                    context.fill(Path(post), with: .color(.white))
                    context.stroke(Path(post), with: .color(.black.opacity(0.35)), lineWidth: 0.5)
                }

                let bar = CGRect(x: x - 13, y: fell ? ground - 4 : ground - 20, width: 26, height: 4)
                let color: Color = !isFinished ? .red : (fell ? .red : .green)
                context.fill(Path(roundedRect: bar, cornerRadius: 1), with: .color(color))
            }
        }
    }
}

private struct RunPose {
    var progress = 0.0
    var hop = 0.0
    var facing = -1.0
}

/// La fête de fin de parcours : quelques secondes, puis tout est sorti de l'écran.
struct EmojiRain: View {
    private struct Drop: Identifiable {
        let id: Int
        let emoji: String
        let x: Double
        let delay: Double
        let duration: Double
        let size: CGFloat
    }

    @State private var isFalling = false
    @State private var drops: [Drop] = (0..<36).map { index in
        Drop(
            id: index,
            emoji: ["🐴", "🐎", "🥕", "🏆", "🍎", "🎉"].randomElement()!,
            x: .random(in: 0.03...0.97),
            delay: .random(in: 0...1.0),
            duration: .random(in: 1.6...2.6),
            size: .random(in: 28...48)
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ForEach(drops) { drop in
                Text(drop.emoji)
                    .font(.system(size: drop.size))
                    .position(
                        x: geometry.size.width * drop.x,
                        y: isFalling ? geometry.size.height + 80 : -80
                    )
                    .animation(.easeIn(duration: drop.duration).delay(drop.delay), value: isFalling)
            }
        }
        .ignoresSafeArea()
        .allowsHitTesting(false)
        .accessibilityHidden(true)
        .onAppear { isFalling = true }
    }
}
