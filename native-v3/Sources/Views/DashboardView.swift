import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var health: HealthKitService
    @EnvironmentObject private var workoutKit: WorkoutKitService
    @EnvironmentObject private var voiceCoach: VoiceCoach

    private let plan = DailyPlan.plan()

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                header
                healthMetrics
                todayPlan
                automaticMatch
                connectionStatus
            }
            .padding()
        }
        .background(
            LinearGradient(colors: [.black, Color(red: 0.09, green: 0.12, blue: 0.18)], startPoint: .top, endPoint: .bottom)
                .ignoresSafeArea()
        )
        .navigationTitle("Project Phoenix")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    Task { await health.refreshAll() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .disabled(!health.isAuthorized)
            }
        }
    }

    private var header: some View {
        PhoenixCard {
            HStack(spacing: 16) {
                ZStack {
                    Circle().fill(
                        LinearGradient(colors: [.phoenixOrange, .phoenixGold], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
                    Image(systemName: "flame.fill")
                        .font(.system(size: 34, weight: .black))
                        .foregroundStyle(.white)
                }
                .frame(width: 74, height: 74)

                VStack(alignment: .leading, spacing: 5) {
                    Text("MISSION DU JOUR")
                        .font(.caption.bold())
                        .tracking(1.4)
                        .foregroundStyle(.phoenixGold)
                    Text(plan.title)
                        .font(.title2.bold())
                    Text("Objectif : \(plan.targetMinutes) minutes")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var healthMetrics: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
            MetricTile(title: "Pas aujourd’hui", value: health.stepsToday.formatted(.number.precision(.fractionLength(0))), icon: "shoeprints.fill")
            MetricTile(title: "Calories actives", value: "\(Int(health.activeEnergyToday)) kcal", icon: "flame")
            MetricTile(title: "Sommeil", value: String(format: "%.1f h", health.sleepHours), icon: "moon.zzz.fill")
            MetricTile(title: "FC repos", value: health.restingHeartRate > 0 ? "\(Int(health.restingHeartRate)) bpm" : "—", icon: "heart.fill")
            MetricTile(title: "VO₂ max", value: health.vo2Max > 0 ? String(format: "%.1f", health.vo2Max) : "—", icon: "lungs.fill")
            MetricTile(title: "Séances importées", value: "\(health.workouts.count)", icon: "applewatch")
        }
    }

    private var todayPlan: some View {
        PhoenixCard {
            VStack(alignment: .leading, spacing: 14) {
                Label("Séance structurée", systemImage: "applewatch.radiowaves.left.and.right")
                    .font(.headline)
                Text(planDescription)
                    .foregroundStyle(.secondary)

                Button {
                    Task { await workoutKit.openTodayOnWatch() }
                } label: {
                    Label(workoutKit.isWorking ? "Envoi…" : "Ouvrir sur l’Apple Watch", systemImage: "applewatch")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.phoenixOrange)
                .disabled(workoutKit.isWorking)

                HStack {
                    Button {
                        Task { await workoutKit.scheduleToday() }
                    } label: {
                        Label("Programmer à 18 h", systemImage: "calendar.badge.clock")
                    }
                    .buttonStyle(.bordered)

                    Button {
                        voiceCoach.announcePlan(plan)
                    } label: {
                        Label("Annonce", systemImage: "speaker.wave.2.fill")
                    }
                    .buttonStyle(.bordered)
                }

                Text(workoutKit.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    @ViewBuilder
    private var automaticMatch: some View {
        PhoenixCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Détection automatique", systemImage: "checkmark.seal.fill")
                    .font(.headline)
                    .foregroundStyle(health.todayMatchedWorkout == nil ? .secondary : .green)

                if let workout = health.todayMatchedWorkout {
                    Text("Séance du jour reconnue")
                        .font(.title3.bold())
                    Text("\(workout.activityName) • \(workout.durationText) • \(workout.distanceKm, specifier: "%.2f") km • \(workout.paceText)")
                    Text("Source : \(workout.sourceName)\(workout.isFromAdidas ? " · Adidas Running détecté" : "")")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("Après une séance enregistrée sur l’Apple Watch ou écrite dans Apple Santé par Adidas Running, elle apparaîtra ici si elle correspond au programme du jour.")
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    private var connectionStatus: some View {
        PhoenixCard {
            VStack(alignment: .leading, spacing: 10) {
                Label("Apple Santé", systemImage: health.isAuthorized ? "heart.circle.fill" : "heart.slash")
                    .font(.headline)
                    .foregroundStyle(health.isAuthorized ? .green : .phoenixOrange)
                Text(health.statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if !health.isAuthorized {
                    Button("Connecter Apple Santé") {
                        Task { await health.requestAuthorization() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.phoenixOrange)
                }
            }
        }
    }

    private var planDescription: String {
        if let repetitions = plan.repetitions,
           let effort = plan.effortSeconds,
           let recovery = plan.recoverySeconds {
            return "Échauffement \(plan.warmupMinutes) min, puis \(repetitions) × \(effort) s d’effort / \(recovery) s de récupération, et \(plan.cooldownMinutes) min de retour au calme."
        }
        return "Séance de \(plan.targetMinutes) minutes à intensité contrôlée. La montre enregistre le GPS, la fréquence cardiaque, la distance, l’allure et les calories."
    }
}
