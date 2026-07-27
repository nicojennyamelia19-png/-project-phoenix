import SwiftUI

struct RootView: View {
    var body: some View {
        TabView {
            NavigationStack { DashboardView() }
                .tabItem { Label("Accueil", systemImage: "flame.fill") }

            NavigationStack { WorkoutHistoryView() }
                .tabItem { Label("Séances", systemImage: "figure.run") }

            NavigationStack { NutritionView() }
                .tabItem { Label("Nutrition", systemImage: "fork.knife") }

            NavigationStack { FriendsView() }
                .tabItem { Label("Équipe", systemImage: "person.3.fill") }

            NavigationStack { SettingsView() }
                .tabItem { Label("Réglages", systemImage: "gearshape.fill") }
        }
        .tint(Color.phoenixOrange)
    }
}

extension Color {
    static let phoenixOrange = Color(red: 1.0, green: 0.32, blue: 0.18)
    static let phoenixGold = Color(red: 1.0, green: 0.68, blue: 0.20)
    static let phoenixPanel = Color(red: 0.08, green: 0.10, blue: 0.14)
}

struct PhoenixCard<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        content
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color.phoenixPanel)
                    .overlay(
                        RoundedRectangle(cornerRadius: 22, style: .continuous)
                            .stroke(Color.white.opacity(0.07), lineWidth: 1)
                    )
            )
    }
}

struct MetricTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.primary)
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.05), in: RoundedRectangle(cornerRadius: 16))
    }
}
