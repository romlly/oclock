import Foundation
import Observation
import OSLog

struct TestRecord: Identifiable, Codable {
    var id = UUID()
    let date: Date
    let level: QuizLevel
    let score: Int
    let mistakes: [TestMistake]
}

/// Les tests terminés, du plus récent au plus ancien, gardés dans un fichier JSON.
@MainActor
@Observable
final class TestHistory {
    private(set) var records: [TestRecord] = []

    private let fileURL: URL
    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "oclock", category: "history")

    /// Une carotte par bonne réponse, tous tests confondus.
    var carrots: Int { records.reduce(0) { $0 + $1.score } }

    nonisolated static let carrotsPerGalop = 25
    nonisolated static let maxGalop = 7

    /// Les niveaux des cavaliers, du Galop 1 au Galop 7.
    nonisolated static func galop(carrots: Int) -> Int {
        min(maxGalop, 1 + carrots / carrotsPerGalop)
    }

    nonisolated static func carrotsToNextGalop(carrots: Int) -> Int? {
        galop(carrots: carrots) == maxGalop ? nil : carrotsPerGalop - carrots % carrotsPerGalop
    }

    init(fileURL: URL = .documentsDirectory.appending(path: "test-history.json")) {
        self.fileURL = fileURL
        load()
    }

    func add(_ record: TestRecord) {
        records.insert(record, at: 0)
        save()
    }

    private func load() {
        guard let data = try? Data(contentsOf: fileURL) else { return }
        do {
            records = try JSONDecoder().decode([TestRecord].self, from: data)
        } catch {
            // Mis de côté plutôt qu'écrasé par la prochaine sauvegarde.
            logger.error("Historique illisible : \(error)")
            let backup = fileURL.appendingPathExtension("illisible")
            try? FileManager.default.removeItem(at: backup)
            try? FileManager.default.moveItem(at: fileURL, to: backup)
        }
    }

    private func save() {
        do {
            let data = try JSONEncoder().encode(records)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            logger.error("Historique non enregistré : \(error)")
        }
    }
}
