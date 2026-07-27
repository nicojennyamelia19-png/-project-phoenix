import SwiftUI
import MapKit

struct WorkoutHistoryView: View {
    @EnvironmentObject private var health: HealthKitService

    var body: some View {
        Group {
            if !health.isAuthorized {
                ContentUnavailableView {
                    Label("Apple Santé non connecté", systemImage: "heart.slash")
                } description: {
                    Text("Connecte Apple Santé depuis l’accueil pour importer les séances de l’Apple Watch et celles écrites par Adidas Running.")
                }
            } else if health.workouts.isEmpty {
                ContentUnavailableView("Aucune séance", systemImage: "figure.run", description: Text("Les entraînements autorisés apparaîtront ici."))
            } else {
                List(health.workouts) { workout in
                    NavigationLink {
                        WorkoutDetailView(workout: workout)
                    } label: {
                        WorkoutRow(workout: workout)
                    }
                    .listRowBackground(Color.phoenixPanel)
                }
                .scrollContentBackground(.hidden)
                .background(Color.black)
                .refreshable { await health.refreshAll() }
            }
        }
        .navigationTitle("Historique")
    }
}

private struct WorkoutRow: View {
    let workout: WorkoutSummary

    var body: some View {
        HStack(spacing: 13) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(workout.isFromAdidas ? Color.blue.opacity(0.25) : Color.phoenixOrange.opacity(0.22))
                Image(systemName: workout.activityName == "Course" ? "figure.run" : "figure.mixed.cardio")
                    .foregroundStyle(workout.isFromAdidas ? .blue : .phoenixOrange)
            }
            .frame(width: 48, height: 48)

            VStack(alignment: .leading, spacing: 4) {
                Text(workout.activityName).font(.headline)
                Text(workout.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(workout.sourceName)
                    .font(.caption2)
                    .foregroundStyle(workout.isFromAdidas ? .blue : .secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 3) {
                Text(workout.durationText).font(.headline.monospacedDigit())
                Text("\(workout.distanceKm, specifier: "%.2f") km")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 5)
    }
}

struct WorkoutDetailView: View {
    @EnvironmentObject private var health: HealthKitService
    let workout: WorkoutSummary
    @State private var mapPosition: MapCameraPosition = .automatic

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PhoenixCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(workout.activityName)
                            .font(.largeTitle.bold())
                        Text(workout.startDate.formatted(date: .long, time: .shortened))
                            .foregroundStyle(.secondary)
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            MetricTile(title: "Durée", value: workout.durationText, icon: "clock.fill")
                            MetricTile(title: "Distance", value: String(format: "%.2f km", workout.distanceKm), icon: "point.topleft.down.to.point.bottomright.curvepath")
                            MetricTile(title: "Allure", value: workout.paceText, icon: "speedometer")
                            MetricTile(title: "Calories", value: "\(Int(workout.activeKilocalories)) kcal", icon: "flame.fill")
                            MetricTile(title: "FC moyenne", value: workout.averageHeartRate.map { "\(Int($0)) bpm" } ?? "—", icon: "heart.fill")
                            MetricTile(title: "Source", value: workout.isFromAdidas ? "Adidas" : workout.sourceName, icon: "square.and.arrow.down")
                        }
                    }
                }

                PhoenixCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Parcours GPS", systemImage: "map.fill")
                            .font(.headline)
                        if health.routePoints.count > 1 {
                            Map(position: $mapPosition) {
                                MapPolyline(coordinates: health.routePoints.map(\.coordinate))
                                    .stroke(.phoenixOrange, lineWidth: 5)
                                if let first = health.routePoints.first {
                                    Marker("Départ", systemImage: "flag.fill", coordinate: first.coordinate)
                                        .tint(.green)
                                }
                                if let last = health.routePoints.last {
                                    Marker("Arrivée", systemImage: "flag.checkered", coordinate: last.coordinate)
                                        .tint(.phoenixOrange)
                                }
                            }
                            .mapStyle(.standard(elevation: .realistic))
                            .frame(height: 330)
                            .clipShape(RoundedRectangle(cornerRadius: 18))
                        } else {
                            ContentUnavailableView("Parcours indisponible", systemImage: "map", description: Text("Le GPS n’a pas été partagé dans Apple Santé pour cette séance, ou le parcours est encore en cours de synchronisation."))
                                .frame(minHeight: 230)
                        }
                    }
                }
            }
            .padding()
        }
        .background(Color.black)
        .navigationTitle("Analyse")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await health.loadRoute(for: workout)
        }
    }
}
