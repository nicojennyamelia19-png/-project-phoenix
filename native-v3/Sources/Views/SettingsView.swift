import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var health: HealthKitService
    @EnvironmentObject private var voiceCoach: VoiceCoach
    @AppStorage("phoenix.nickname") private var nickname = "Nicolas"
    @AppStorage("phoenix.startWeight") private var startWeight = 120.0
    @AppStorage("phoenix.goalWeight") private var goalWeight = 108.0

    var body: some View {
        Form {
            Section("Profil") {
                TextField("Prénom ou pseudo", text: $nickname)
                HStack {
                    Text("Poids de départ")
                    Spacer()
                    TextField("kg", value: $startWeight, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
                HStack {
                    Text("Objectif")
                    Spacer()
                    TextField("kg", value: $goalWeight, format: .number)
                        .multilineTextAlignment(.trailing)
                        .keyboardType(.decimalPad)
                }
            }

            Section("Apple Santé et Apple Watch") {
                LabeledContent("État", value: health.isAuthorized ? "Connecté" : "Non connecté")
                Button(health.isAuthorized ? "Relire les données" : "Connecter Apple Santé") {
                    Task {
                        if health.isAuthorized {
                            await health.refreshAll()
                        } else {
                            await health.requestAuthorization()
                        }
                    }
                }
                Text("Les séances provenant de l’Apple Watch, de l’app Exercice ou d’Adidas Running peuvent être lues seulement si l’app source les écrit dans Apple Santé et si tu autorises Project Phoenix à les consulter.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Coach vocal") {
                Toggle("Annonces vocales sur l’iPhone", isOn: $voiceCoach.isEnabled)
                Text("Pour les séances envoyées dans l’app Exercice, l’Apple Watch gère les étapes, vibrations et alertes du workout structuré.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Confidentialité") {
                Label("Les données Apple Santé restent sur tes appareils et dans Apple Santé.", systemImage: "lock.shield.fill")
                Label("Le mode Équipe partage seulement le pseudo, les séances, la série et le volume hebdomadaire.", systemImage: "person.3.sequence.fill")
                Label("Aucune fréquence cardiaque, poids, sommeil ou parcours GPS n’est envoyé aux amis.", systemImage: "eye.slash.fill")
            }

            Section("Version") {
                LabeledContent("Application", value: "Project Phoenix V3 Native")
                LabeledContent("Compatibilité", value: "iOS 17+ / Apple Watch")
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.black)
        .navigationTitle("Réglages")
    }
}
