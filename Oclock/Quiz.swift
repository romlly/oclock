import AVFoundation
import Observation

enum QuizMode: String, CaseIterable, Identifiable {
    case readClock = "Lire l'horloge"
    case findClock = "Trouver l'horloge"
    case test = "Test"

    var id: Self { self }
}

/// Le sens d'une question : de l'horloge vers la phrase, ou l'inverse.
enum QuizDirection: String, Codable {
    case readClock
    case findClock
}

enum QuizLevel: String, CaseIterable, Identifiable, Codable {
    case fiveMinutes = "Par 5 minutes"
    case exactMinute = "À la minute"

    var id: Self { self }

    var minutes: [Int] {
        switch self {
        case .fiveMinutes: return Array(stride(from: 0, to: 60, by: 5))
        case .exactMinute: return Array(0..<60)
        }
    }
}

struct TestMistake: Identifiable, Codable {
    let number: Int
    let direction: QuizDirection
    let answer: ClockTime
    let chosen: ClockTime

    var id: Int { number }
}

@MainActor
@Observable
final class Quiz {
    static let testLength = 10

    var mode = QuizMode.readClock {
        didSet { restart() }
    }
    var level = QuizLevel.fiveMinutes {
        didSet { restart() }
    }

    private(set) var direction = QuizDirection.readClock
    private(set) var answer = ClockTime(hour: 3, minute: 40)
    private(set) var choices: [ClockTime] = []
    private(set) var pending: ClockTime?
    private(set) var selected: ClockTime?
    private(set) var score = 0
    private(set) var total = 0
    private(set) var streak = 0

    private(set) var testIndex = 0
    private(set) var testScore = 0
    private(set) var mistakes: [TestMistake] = []
    private var testDirections: [QuizDirection] = []
    private var askedInTest: Set<ClockTime> = []

    let history: TestHistory
    private let speaker = AVSpeechSynthesizer()

    var isAnswered: Bool { selected != nil }
    var isCorrect: Bool { selected == answer }
    var isTestFinished: Bool { mode == .test && testIndex == Self.testLength }

    init(history: TestHistory? = nil) {
        self.history = history ?? TestHistory()
        restart()
    }

    /// Relance la question, ou un test complet : moitié dans chaque sens, dans le désordre.
    func restart() {
        testIndex = 0
        testScore = 0
        mistakes = []
        askedInTest = []
        testDirections = (0..<Self.testLength)
            .map { $0 < Self.testLength / 2 ? QuizDirection.readClock : .findClock }
            .shuffled()
        next()
    }

    func next() {
        switch mode {
        case .readClock: direction = .readClock
        case .findClock: direction = .findClock
        case .test: direction = testDirections[testIndex]
        }

        var time: ClockTime
        repeat {
            time = ClockTime(hour: Int.random(in: 1...12), minute: level.minutes.randomElement()!)
        } while time == answer || (mode == .test && askedInTest.contains(time))
        if mode == .test {
            askedInTest.insert(time)
        }
        answer = time
        choices = ([time] + time.distractors).shuffled()
        pending = nil
        selected = nil
    }

    /// Un toucher ne fait que sélectionner : seul `validate()` compte la réponse.
    func choose(_ choice: ClockTime) {
        guard !isAnswered, !isTestFinished else { return }
        pending = choice
    }

    func validate() {
        guard let choice = pending else { return }
        pending = nil
        if mode == .test {
            validateInTest(choice)
            return
        }
        selected = choice
        total += 1
        if choice == answer {
            score += 1
            streak += 1
        } else {
            streak = 0
        }
    }

    /// Pas de correction pendant le test : tout arrive sur l'écran final.
    private func validateInTest(_ choice: ClockTime) {
        if choice == answer {
            testScore += 1
        } else {
            mistakes.append(TestMistake(
                number: testIndex + 1, direction: direction, answer: answer, chosen: choice
            ))
        }
        testIndex += 1
        if isTestFinished {
            history.add(TestRecord(date: .now, level: level, score: testScore, mistakes: mistakes))
        } else {
            next()
        }
    }

    func speak(_ text: String) {
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        speaker.stopSpeaking(at: .immediate)
        speaker.speak(utterance)
    }
}
