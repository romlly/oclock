import SwiftUI

struct SettingsView: View {
    @AppStorage(AppTheme.storageKey) private var horseTheme = false

    @Environment(\.appTheme) private var theme
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("🐴 Thème chevaux", isOn: $horseTheme)
                } footer: {
                    Text("Chevaux au galop, carottes à gagner et Galops à passer. L'horloge ne change pas.")
                }
            }
            .scrollContentBackground(.hidden)
            .background(theme.background)
            .navigationTitle("Réglages")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Fermer") { dismiss() }
                }
            }
        }
    }
}
