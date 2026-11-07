import SwiftUI

/// Écran de fin de test : le score, puis une explication par erreur.
struct TestResultView: View {
    let score: Int
    let mistakes: [TestMistake]
    let carrots: Int
    let onRestart: () -> Void

    @Environment(\.appTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let emoji = theme.resultEmoji(mistakes: mistakes.count) {
                    Text(emoji)
                        .font(.system(size: 72))
                        .accessibilityHidden(true)
                }
                Text("\(score)/\(Quiz.testLength)")
                    .font(.system(size: 80, weight: .bold, design: .rounded).monospacedDigit())
                Text(theme.resultMessage(mistakes: mistakes.count))
                    .font(.title3)
                    .multilineTextAlignment(.center)
                if let reward = theme.reward(score: score, carrots: carrots) {
                    Text(reward)
                        .font(.headline)
                        .foregroundStyle(theme.titleColor)
                        .multilineTextAlignment(.center)
                }
                Button {
                    onRestart()
                } label: {
                    Text(theme.restart)
                        .font(.title3.bold())
                        .padding(.horizontal, 20)
                        .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)

                if !mistakes.isEmpty {
                    Text(theme.mistakesTitle)
                        .font(.system(.title2, design: theme.titleDesign).bold())
                        .foregroundStyle(theme.titleColor)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.top, 12)
                    ForEach(mistakes) { MistakeRow(mistake: $0) }
                }
            }
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
    }
}

struct MistakeRow: View {
    let mistake: TestMistake

    @Environment(\.appTheme) private var theme

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("\(theme.questionLabel) \(mistake.number) · \(prompt)")
                .font(.headline)
            HStack(alignment: .top, spacing: 12) {
                card("Ta réponse", time: mistake.chosen, color: .red)
                card("Bonne réponse", time: mistake.answer, color: .green)
            }
            Text(mistake.answer.explanation)
                .font(.body.weight(.semibold))
            Text(mistake.answer.reason(forChoosing: mistake.chosen))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 16))
    }

    private var prompt: String {
        switch mistake.direction {
        case .readClock: return "Lire l'horloge"
        case .findClock: return "Trouver l'horloge"
        }
    }

    private func card(_ title: String, time: ClockTime, color: Color) -> some View {
        VStack(spacing: 8) {
            Text(title)
                .font(.subheadline.bold())
            ClockFace(time: time)
                .frame(height: 150)
            Text(time.phrase)
                .font(.title3.weight(.medium))
                .multilineTextAlignment(.center)
            Text(time.digital)
                .foregroundStyle(.secondary)
        }
        .padding(12)
        .frame(maxWidth: .infinity)
        .background(color.opacity(0.2), in: RoundedRectangle(cornerRadius: 12))
        .accessibilityElement(children: .combine)
    }
}
