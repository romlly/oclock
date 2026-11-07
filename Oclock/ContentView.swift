import SwiftUI

struct ContentView: View {
    @State private var quiz = Quiz()
    @State private var showsHistory = false
    @State private var showsSettings = false
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.appTheme) private var theme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var isCompact: Bool { sizeClass == .compact }
    private var pagePadding: CGFloat { isCompact ? 16 : 24 }

    var body: some View {
        GeometryReader { geometry in
            let isWide = geometry.size.width > geometry.size.height

            ZStack {
                ThemeBackground(
                    bandHeight: geometry.safeAreaInsets.top + pagePadding + Self.titleRowHeight + 4
                )
                VStack(spacing: isCompact ? 10 : 20) {
                    header
                    Group {
                        if quiz.isTestFinished {
                            TestResultView(
                                score: quiz.testScore,
                                mistakes: quiz.mistakes,
                                carrots: quiz.history.carrots
                            ) {
                                quiz.restart()
                            }
                        } else {
                            switch quiz.direction {
                            case .readClock: readClock(isWide: isWide)
                            case .findClock: findClock(isWide: isWide)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    if isCompact {
                        compactFooter
                    } else {
                        HStack(spacing: 24) {
                            PastToDiagram()
                            if !quiz.isTestFinished {
                                feedback
                            }
                        }
                    }
                }
                .padding(pagePadding)

                if theme.isFun {
                    HorseLane(
                        isTest: quiz.mode == .test,
                        position: quiz.testIndex,
                        isFinished: quiz.isTestFinished,
                        fallen: Set(quiz.mistakes.map(\.number)),
                        runs: quiz.total,
                        lastCorrect: quiz.isCorrect
                    )
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .ignoresSafeArea(edges: .bottom)
                }
                if theme.isFun && !reduceMotion && quiz.isTestFinished && quiz.mistakes.count <= 3 {
                    EmojiRain()
                }
            }
        }
        .sheet(isPresented: $showsHistory) {
            HistoryView(records: quiz.history.records)
        }
        .sheet(isPresented: $showsSettings) {
            SettingsView()
        }
    }

    private static let titleRowHeight: CGFloat = 44

    private var header: some View {
        let pickersLayout = isCompact
            ? AnyLayout(VStackLayout(spacing: 8))
            : AnyLayout(HStackLayout(spacing: 16))

        return VStack(spacing: isCompact ? 8 : 12) {
            HStack(spacing: isCompact ? 4 : 8) {
                if let logo = theme.logo {
                    Text(logo)
                        .font(isCompact ? .title : .largeTitle)
                        .accessibilityHidden(true)
                }
                Text("O'Clock")
                    .font(.system(isCompact ? .title : .largeTitle, design: theme.titleDesign).bold())
                    .foregroundStyle(theme.titleColor)
                if let herd = theme.herd, !isCompact {
                    Text(herd)
                        .font(.title)
                        .padding(.leading, 12)
                        .accessibilityHidden(true)
                }
                Spacer()
                if quiz.mode == .test {
                    if !quiz.isTestFinished {
                        Text("\(theme.questionLabel) \(quiz.testIndex + 1)/\(Quiz.testLength)")
                            .font(.title3.monospacedDigit())
                            .lineLimit(1)
                            .minimumScaleFactor(0.8)
                    }
                } else {
                    Text("\(theme.scoreLabel) \(quiz.score)/\(quiz.total)")
                        .font(.title3.monospacedDigit())
                    if quiz.streak >= 2 {
                        Text("\(theme.streakLabel) \(quiz.streak)")
                            .font(.title3.monospacedDigit().bold())
                            .foregroundStyle(.orange)
                    }
                }
                Button {
                    showsHistory = true
                } label: {
                    Image(systemName: "clock.arrow.circlepath")
                        .font(.title2)
                        .frame(width: isCompact ? 36 : 44, height: Self.titleRowHeight)
                }
                .accessibilityLabel(theme.historyTitle)
                Button {
                    showsSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .font(.title2)
                        .frame(width: isCompact ? 36 : 44, height: Self.titleRowHeight)
                }
                .accessibilityLabel("Réglages")
            }
            pickersLayout {
                Picker("Exercice", selection: $quiz.mode) {
                    ForEach(QuizMode.allCases) { Text(theme.title(for: $0)).tag($0) }
                }
                Picker("Niveau", selection: $quiz.level) {
                    ForEach(QuizLevel.allCases) { Text($0.rawValue).tag($0) }
                }
            }
            .pickerStyle(.segmented)
        }
    }

    // MARK: - Horloge affichée, on choisit la phrase

    @ViewBuilder
    private func readClock(isWide: Bool) -> some View {
        let layout = isWide
            ? AnyLayout(HStackLayout(spacing: 32))
            : AnyLayout(VStackLayout(spacing: isCompact ? 12 : 24))

        layout {
            ClockFace(time: quiz.answer)
                .accessibilityLabel("Horloge")
            VStack(spacing: isCompact ? 8 : 14) {
                ForEach(quiz.choices, id: \.self) { choice in
                    Button {
                        quiz.choose(choice)
                    } label: {
                        Text(choice.phrase)
                            .font(isCompact ? .title3.weight(.medium) : .title2.weight(.medium))
                            .frame(maxWidth: .infinity, minHeight: isCompact ? 48 : 64)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(tint(for: choice), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(selectionBorder(for: choice))
                    .accessibilityAddTraits(choice == quiz.pending ? .isSelected : [])
                }
            }
            .frame(maxWidth: 520)
        }
    }

    // MARK: - Phrase affichée, on choisit l'horloge

    private func findClock(isWide: Bool) -> some View {
        VStack(spacing: 20) {
            HStack(spacing: 12) {
                Text(quiz.answer.phrase)
                    .font(.system(isCompact ? .title2 : .largeTitle, design: .rounded).weight(.semibold))
                    .multilineTextAlignment(.center)
                speakButton
            }
            LazyVGrid(
                columns: Array(repeating: GridItem(.flexible(), spacing: 16), count: isWide ? 4 : 2),
                spacing: 16
            ) {
                ForEach(Array(quiz.choices.enumerated()), id: \.element) { index, choice in
                    Button {
                        quiz.choose(choice)
                    } label: {
                        ClockFace(time: choice)
                            .padding(12)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .background(tint(for: choice), in: RoundedRectangle(cornerRadius: 16))
                    .overlay(selectionBorder(for: choice))
                    .accessibilityLabel("Horloge \(index + 1)")
                    .accessibilityAddTraits(choice == quiz.pending ? .isSelected : [])
                }
            }
            Spacer(minLength: 0)
        }
    }

    private var speakButton: some View {
        Button {
            quiz.speak(quiz.answer.phrase)
        } label: {
            Image(systemName: "speaker.wave.2.fill")
                .font(.title2)
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel("Écouter")
    }

    // MARK: - Retour après la réponse

    private var feedback: some View {
        HStack(spacing: 16) {
            feedbackText
            feedbackButtons
        }
        .frame(minHeight: 88)
    }

    /// Sur iPhone, la zone de texte a une hauteur fixe : l'horloge garde
    /// la même taille avant et après la réponse.
    private var compactFooter: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                PastToDiagram(dialSize: 52)
                if !quiz.isTestFinished {
                    Spacer(minLength: 0)
                    feedbackButtons
                }
            }
            if !quiz.isTestFinished {
                feedbackText
                    .frame(height: 68, alignment: .top)
            }
        }
    }

    private var feedbackText: some View {
        VStack(alignment: .leading, spacing: isCompact ? 2 : 4) {
            if quiz.isAnswered {
                Text(theme.reaction(correct: quiz.isCorrect, seed: quiz.total))
                    .font(isCompact ? .headline : .title3.bold())
                    .foregroundStyle(quiz.isCorrect ? theme.correctColor : theme.wrongColor)
                Text("\(quiz.answer.digital) = \(quiz.answer.phrase)")
                    .font(isCompact ? .body : .title3)
                Text(quiz.answer.explanation)
                    .font(isCompact ? .subheadline : .body)
                    .foregroundStyle(.secondary)
            } else if quiz.mode != .test {
                Text("Past : les minutes après l'heure. To : les minutes avant l'heure suivante.")
                    .font(isCompact ? .subheadline : .body)
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(isCompact && quiz.isAnswered ? 1 : nil)
        .minimumScaleFactor(0.7)
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private var feedbackButtons: some View {
        if quiz.isAnswered {
            if quiz.mode == .readClock {
                speakButton
            }
            Button {
                quiz.next()
            } label: {
                Text("Suivant")
                    .font(.title3.bold())
                    .padding(.horizontal, isCompact ? 12 : 20)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
        } else {
            Button {
                quiz.validate()
            } label: {
                Text("Valider")
                    .font(.title3.bold())
                    .padding(.horizontal, isCompact ? 12 : 20)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .disabled(quiz.pending == nil)
        }
    }

    private func selectionBorder(for choice: ClockTime) -> some View {
        RoundedRectangle(cornerRadius: 16)
            .stroke(theme.accent, lineWidth: 4)
            .opacity(choice == quiz.pending ? 1 : 0)
    }

    private func tint(for choice: ClockTime) -> Color {
        if choice == quiz.pending { return theme.accent.opacity(0.2) }
        guard quiz.isAnswered else { return Color(.secondarySystemGroupedBackground) }
        if choice == quiz.answer { return .green.opacity(0.35) }
        if choice == quiz.selected { return .red.opacity(0.35) }
        return Color(.secondarySystemGroupedBackground)
    }
}

#Preview {
    ContentView()
}
