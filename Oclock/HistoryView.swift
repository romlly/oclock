import SwiftUI

struct HistoryView: View {
    let records: [TestRecord]

    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Group {
                if records.isEmpty {
                    ContentUnavailableView(
                        theme.emptyHistory,
                        systemImage: "clock.arrow.circlepath",
                        description: Text("Les tests terminés s'afficheront ici.")
                    )
                } else {
                    List(records) { record in
                        NavigationLink {
                            TestRecordView(record: record)
                        } label: {
                            HistoryRow(record: record)
                        }
                    }
                    .scrollContentBackground(.hidden)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(theme.background)
            .navigationTitle(theme.historyTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}

private struct HistoryRow: View {
    let record: TestRecord

    @Environment(\.appTheme) private var theme

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(record.formattedDate)
                    .font(.headline)
                Text(record.level.rawValue)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if let emoji = theme.resultEmoji(mistakes: record.mistakes.count) {
                Text(emoji)
                    .font(.title2)
                    .accessibilityHidden(true)
            }
            Text("\(record.score)/\(Quiz.testLength)")
                .font(.title2.bold().monospacedDigit())
        }
        .padding(.vertical, 4)
    }
}

/// Le détail d'un test passé : son score et l'explication de chaque erreur.
private struct TestRecordView: View {
    let record: TestRecord

    @Environment(\.appTheme) private var theme

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("\(record.score)/\(Quiz.testLength)")
                    .font(.system(size: 64, weight: .bold, design: .rounded).monospacedDigit())
                Text(record.level.rawValue)
                    .foregroundStyle(.secondary)
                if record.mistakes.isEmpty {
                    Text(theme.resultPerfect)
                        .font(.title3)
                }
                ForEach(record.mistakes) { MistakeRow(mistake: $0) }
            }
            .padding(24)
            .frame(maxWidth: 760)
            .frame(maxWidth: .infinity)
        }
        .background(theme.background)
        .navigationTitle(record.formattedDate)
    }
}

private extension TestRecord {
    var formattedDate: String {
        date.formatted(
            Date.FormatStyle(date: .long, time: .shortened).locale(Locale(identifier: "fr_FR"))
        )
    }
}
