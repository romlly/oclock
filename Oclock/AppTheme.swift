import SwiftUI

/// Couleurs, décor et vocabulaire de l'app. Le cadran n'en dépend jamais :
/// `ClockFace` reste identique pour que l'heure soit toujours aussi lisible.
struct AppTheme {
    static let storageKey = "horseTheme"

    let accent: Color
    let background: Color
    let band: Color?
    let bandLine: Color
    let titleColor: Color
    let correctColor: Color
    let wrongColor: Color
    let titleDesign: Font.Design
    let logo: String?
    let herd: String?
    let colorScheme: ColorScheme?
    let isFun: Bool

    let testTitle: String
    let questionLabel: String
    let scoreLabel: String
    let streakLabel: String
    let correctLines: [String]
    let wrongLines: [String]
    let mistakesTitle: String
    let restart: String
    let historyTitle: String
    let emptyHistory: String
    let resultPerfect: String
    let resultGood: String
    let resultFair: String
    let resultLow: String

    func title(for mode: QuizMode) -> String {
        mode == .test ? testTitle : mode.rawValue
    }

    /// `seed` change à chaque réponse, pour varier les réactions.
    func reaction(correct: Bool, seed: Int) -> String {
        let lines = correct ? correctLines : wrongLines
        return lines[seed % lines.count]
    }

    func resultMessage(mistakes: Int) -> String {
        switch mistakes {
        case 0: return resultPerfect
        case 1...3: return resultGood
        case 4...6: return resultFair
        default: return resultLow
        }
    }

    func resultEmoji(mistakes: Int) -> String? {
        guard isFun else { return nil }
        switch mistakes {
        case 0: return "🏆"
        case 1...3: return "🏇"
        case 4...6: return "🐎"
        default: return "🐴"
        }
    }

    func reward(score: Int, carrots: Int) -> String? {
        guard isFun else { return nil }
        let galop = TestHistory.galop(carrots: carrots)
        guard let missing = TestHistory.carrotsToNextGalop(carrots: carrots) else {
            return "+\(score) 🥕 · Galop \(galop), le plus haut niveau !"
        }
        return "+\(score) 🥕 · Galop \(galop) · encore \(missing) 🥕 pour le Galop \(galop + 1)"
    }

    static let standard = AppTheme(
        accent: .accentColor,
        background: Color(.systemGroupedBackground),
        band: nil,
        bandLine: .clear,
        titleColor: .primary,
        correctColor: .green,
        wrongColor: .red,
        titleDesign: .default,
        logo: nil,
        herd: nil,
        colorScheme: nil,
        isFun: false,
        testTitle: "Test",
        questionLabel: "Question",
        scoreLabel: "Score",
        streakLabel: "Série",
        correctLines: ["Bravo !"],
        wrongLines: ["Pas tout à fait"],
        mistakesTitle: "À revoir",
        restart: "Recommencer",
        historyTitle: "Historique",
        emptyHistory: "Aucun test",
        resultPerfect: "Sans faute, bravo !",
        resultGood: "Bien joué !",
        resultFair: "C'est en bonne voie, regarde les explications.",
        resultLow: "Regarde les explications, puis retente ta chance."
    )

    /// Le test devient un parcours d'obstacles, et chaque bonne réponse rapporte une carotte.
    static let horses = AppTheme(
        accent: Color(red: 0.478, green: 0.243, blue: 0.102),
        background: Color(red: 0.969, green: 0.941, blue: 0.890),
        band: Color(red: 0.894, green: 0.812, blue: 0.659),
        bandLine: Color(red: 0.722, green: 0.525, blue: 0.043),
        titleColor: Color(red: 0.122, green: 0.302, blue: 0.227),
        correctColor: Color(red: 0.122, green: 0.420, blue: 0.227),
        wrongColor: Color(red: 0.702, green: 0.149, blue: 0.118),
        titleDesign: .serif,
        logo: "🐴",
        herd: "🐎 🏇 🐎",
        colorScheme: .light,
        isFun: true,
        testTitle: "🏇 Parcours",
        questionLabel: "Obstacle",
        scoreLabel: "🥕",
        streakLabel: "🔥",
        correctLines: [
            "Bien sauté !", "Hiiii ! Au galop !", "Une carotte pour toi !",
            "Pur-sang de l'anglais !", "Ton cheval est fier de toi !",
        ],
        wrongLines: [
            "Barre tombée !", "Refus d'obstacle !", "Oups, ton cheval fait la tête.",
            "Pas de carotte cette fois.",
        ],
        mistakesTitle: "Barres tombées",
        restart: "Reprendre le parcours",
        historyTitle: "Mes parcours 🏇",
        emptyHistory: "Aucun parcours",
        resultPerfect: "Sans-faute ! Tu remportes le concours !",
        resultGood: "Beau parcours, ton cheval est content !",
        resultFair: "Pas mal ! Regarde les barres tombées.",
        resultLow: "Regarde les explications et remonte en selle."
    )
}

extension EnvironmentValues {
    @Entry var appTheme = AppTheme.standard
}

/// Fond de page. Le décor reste dans le bandeau du haut et la marge du bas :
/// rien ne passe derrière l'horloge, les réponses ou le schéma.
struct ThemeBackground: View {
    let bandHeight: CGFloat

    @Environment(\.appTheme) private var theme

    var body: some View {
        ZStack(alignment: .top) {
            theme.background
            if theme.isFun {
                fence
                    .frame(maxHeight: .infinity, alignment: .bottom)
            }
            if let band = theme.band {
                band
                    .frame(height: bandHeight)
                    .overlay(alignment: .bottom) {
                        theme.bandLine.frame(height: 3)
                    }
            }
        }
        .ignoresSafeArea()
    }

    private var fence: some View {
        Canvas { context, size in
            let wood = GraphicsContext.Shading.color(theme.accent.opacity(0.35))
            for railY in [8.0, 20.0] {
                let rail = CGRect(x: 0, y: railY, width: size.width, height: 5)
                context.fill(Path(roundedRect: rail, cornerRadius: 2), with: wood)
            }
            var postX = 24.0
            while postX < size.width {
                let post = CGRect(x: postX, y: 0, width: 8, height: size.height)
                context.fill(Path(roundedRect: post, cornerRadius: 2), with: wood)
                postX += 96
            }
            let ground = CGRect(x: 0, y: size.height - 6, width: size.width, height: 6)
            context.fill(Path(ground), with: .color(theme.titleColor.opacity(0.75)))
        }
        .frame(height: 36)
        .accessibilityHidden(true)
    }
}
