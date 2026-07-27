import SwiftUI

struct FriendsView: View {
    @EnvironmentObject private var friends: CloudFriendService
    @EnvironmentObject private var health: HealthKitService
    @AppStorage("phoenix.nickname") private var nickname = "Nicolas"
    @State private var friendCode = ""

    var body: some View {
        ScrollView {
            VStack(spacing: 14) {
                PhoenixCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Label("Mon équipe Phoenix", systemImage: "person.3.fill")
                            .font(.title2.bold())
                        Text("Tes amis partagent uniquement leur pseudo, leur volume d’entraînement et leur régularité. Les données médicales et la fréquence cardiaque restent privées.")
                            .foregroundStyle(.secondary)

                        Text("Mon code ami")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(friends.inviteCode)
                            .font(.system(.largeTitle, design: .monospaced, weight: .black))
                            .foregroundStyle(.phoenixGold)
                            .textSelection(.enabled)

                        Button {
                            Task { await publishMySnapshot() }
                        } label: {
                            Label("Actualiser mon profil partagé", systemImage: "icloud.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.phoenixOrange)
                    }
                }

                PhoenixCard {
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ajouter un ami").font(.headline)
                        TextField("Code ami", text: $friendCode)
                            .textInputAutocapitalization(.characters)
                            .autocorrectionDisabled()
                            .textFieldStyle(.roundedBorder)
                        Button("Suivre ce profil") {
                            Task {
                                await friends.follow(code: friendCode)
                                friendCode = ""
                            }
                        }
                        .buttonStyle(.bordered)
                    }
                }

                if friends.friends.isEmpty {
                    ContentUnavailableView("Aucun ami suivi", systemImage: "person.badge.plus", description: Text("Ajoute les codes de tes deux amis lorsqu’ils auront installé Project Phoenix."))
                        .frame(minHeight: 240)
                } else {
                    ForEach(friends.friends) { friend in
                        PhoenixCard {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    ZStack {
                                        Circle().fill(Color.phoenixOrange.opacity(0.25))
                                        Text(String(friend.nickname.prefix(1)).uppercased())
                                            .font(.title.bold())
                                            .foregroundStyle(.phoenixOrange)
                                    }
                                    .frame(width: 52, height: 52)
                                    VStack(alignment: .leading) {
                                        Text(friend.nickname).font(.title3.bold())
                                        Text("Mis à jour \(friend.updatedAt.formatted(.relative(presentation: .named)))")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Button(role: .destructive) {
                                        friends.removeFriend(code: friend.inviteCode)
                                    } label: {
                                        Image(systemName: "person.crop.circle.badge.minus")
                                    }
                                }
                                HStack {
                                    MetricTile(title: "Séances", value: "\(friend.completedWorkouts)", icon: "checkmark.seal.fill")
                                    MetricTile(title: "Série", value: "\(friend.currentStreak) j", icon: "flame.fill")
                                }
                                MetricTile(title: "Cette semaine", value: "\(friend.weeklyMinutes) min", icon: "calendar")
                                if let date = friend.lastWorkoutDate {
                                    Text("Dernière séance : \(date.formatted(date: .abbreviated, time: .shortened))")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }

                Text(friends.statusMessage)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding()
        }
        .background(Color.black)
        .navigationTitle("Équipe")
        .task { await friends.refreshFriends() }
        .refreshable { await friends.refreshFriends() }
    }

    private func publishMySnapshot() async {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: .now)?.start ?? .now
        let weeklyWorkouts = health.workouts.filter { $0.startDate >= weekStart }
        let minutes = Int(weeklyWorkouts.reduce(0) { $0 + $1.duration } / 60)
        let streak = calculateStreak(from: health.workouts.map(\.startDate))
        await friends.publish(
            nickname: nickname,
            completedWorkouts: health.workouts.count,
            currentStreak: streak,
            weeklyMinutes: minutes,
            lastWorkoutDate: health.workouts.first?.startDate
        )
    }

    private func calculateStreak(from dates: [Date]) -> Int {
        let workoutDays = Set(dates.map { Calendar.current.startOfDay(for: $0) })
        var streak = 0
        var day = Calendar.current.startOfDay(for: .now)
        if !workoutDays.contains(day) {
            day = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? day
        }
        while workoutDays.contains(day) {
            streak += 1
            day = Calendar.current.date(byAdding: .day, value: -1, to: day) ?? day
        }
        return streak
    }
}
