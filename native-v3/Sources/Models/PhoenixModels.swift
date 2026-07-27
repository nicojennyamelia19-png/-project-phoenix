import Foundation
import HealthKit
import CoreLocation

struct DailyPlan: Identifiable, Hashable {
    let id: UUID
    let title: String
    let kind: Kind
    let targetMinutes: Int
    let warmupMinutes: Int
    let effortSeconds: Int?
    let recoverySeconds: Int?
    let repetitions: Int?
    let cooldownMinutes: Int

    enum Kind: String, Hashable {
        case easyRun = "Endurance"
        case fartlek = "Fartlek"
        case intervals = "Fractionné"
        case longRun = "Sortie longue"
        case strength = "Renforcement"
        case recovery = "Récupération"
    }

    static func plan(for date: Date = .now) -> DailyPlan {
        let weekday = Calendar.current.component(.weekday, from: date)
        switch weekday {
        case 2:
            return DailyPlan(id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!, title: "Endurance douce 35 min", kind: .easyRun, targetMinutes: 35, warmupMinutes: 5, effortSeconds: nil, recoverySeconds: nil, repetitions: nil, cooldownMinutes: 5)
        case 3:
            return DailyPlan(id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!, title: "Street workout", kind: .strength, targetMinutes: 35, warmupMinutes: 5, effortSeconds: nil, recoverySeconds: nil, repetitions: nil, cooldownMinutes: 5)
        case 4:
            return DailyPlan(id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!, title: "Fartlek 8 × 1 min / 2 min", kind: .fartlek, targetMinutes: 44, warmupMinutes: 12, effortSeconds: 60, recoverySeconds: 120, repetitions: 8, cooldownMinutes: 8)
        case 5:
            return DailyPlan(id: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!, title: "Récupération active", kind: .recovery, targetMinutes: 45, warmupMinutes: 0, effortSeconds: nil, recoverySeconds: nil, repetitions: nil, cooldownMinutes: 0)
        case 6:
            return DailyPlan(id: UUID(uuidString: "10000000-0000-0000-0000-000000000005")!, title: "10 × 30 s / 90 s", kind: .intervals, targetMinutes: 50, warmupMinutes: 15, effortSeconds: 30, recoverySeconds: 90, repetitions: 10, cooldownMinutes: 10)
        case 7:
            return DailyPlan(id: UUID(uuidString: "10000000-0000-0000-0000-000000000006")!, title: "Circuit commando", kind: .strength, targetMinutes: 40, warmupMinutes: 5, effortSeconds: nil, recoverySeconds: nil, repetitions: nil, cooldownMinutes: 5)
        default:
            return DailyPlan(id: UUID(uuidString: "10000000-0000-0000-0000-000000000007")!, title: "Sortie longue 55 min", kind: .longRun, targetMinutes: 55, warmupMinutes: 5, effortSeconds: nil, recoverySeconds: nil, repetitions: nil, cooldownMinutes: 5)
        }
    }
}

struct RoutePoint: Identifiable, Hashable {
    let id = UUID()
    let latitude: Double
    let longitude: Double
    let altitude: Double
    let timestamp: Date

    var coordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

struct WorkoutSummary: Identifiable {
    let id: UUID
    let healthKitUUID: UUID
    let activityName: String
    let startDate: Date
    let duration: TimeInterval
    let distanceKm: Double
    let activeKilocalories: Double
    let averageHeartRate: Double?
    let sourceName: String
    let isFromAdidas: Bool

    var paceSecondsPerKm: Double? {
        guard distanceKm > 0 else { return nil }
        return duration / distanceKm
    }

    var durationText: String {
        let total = Int(duration)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    var paceText: String {
        guard let paceSecondsPerKm else { return "—" }
        let seconds = Int(paceSecondsPerKm)
        return String(format: "%d:%02d/km", seconds / 60, seconds % 60)
    }
}

struct FriendSnapshot: Identifiable, Codable, Hashable {
    var id: String { inviteCode }
    let inviteCode: String
    let nickname: String
    let completedWorkouts: Int
    let currentStreak: Int
    let weeklyMinutes: Int
    let lastWorkoutDate: Date?
    let updatedAt: Date
}

struct PhoenixRecipe: Identifiable, Hashable {
    let id = UUID()
    let name: String
    let category: String
    let minutes: Int
    let calories: Int
    let protein: Int
    let ingredients: [String]
    let instructions: [String]

    static let library: [PhoenixRecipe] = [
        PhoenixRecipe(name: "Bol poulet créole léger", category: "Déjeuner", minutes: 25, calories: 560, protein: 48, ingredients: ["180 g de poulet", "120 g de riz cuit", "tomates", "concombre", "oignon", "citron", "épices"], instructions: ["Griller le poulet sans excès d'huile.", "Composer le bol avec la moitié en légumes.", "Ajouter le riz et assaisonner au citron."]),
        PhoenixRecipe(name: "Omelette récupération", category: "Dîner", minutes: 12, calories: 430, protein: 35, ingredients: ["3 œufs", "150 g de légumes", "30 g de fromage", "1 tranche de pain complet"], instructions: ["Faire revenir les légumes.", "Ajouter les œufs battus.", "Servir avec le pain complet."]),
        PhoenixRecipe(name: "Yaourt banane protéiné", category: "Collation", minutes: 3, calories: 310, protein: 24, ingredients: ["250 g de skyr", "1 banane", "20 g d'avoine", "cannelle"], instructions: ["Mélanger tous les ingrédients.", "Garder au frais jusqu'à la collation."]),
        PhoenixRecipe(name: "Cari poisson assiette Phoenix", category: "Déjeuner", minutes: 30, calories: 520, protein: 42, ingredients: ["180 g de poisson", "tomate", "oignon", "épices", "100 g de riz cuit", "légumes verts"], instructions: ["Préparer un cari peu huilé.", "Remplir la moitié de l'assiette de légumes.", "Ajouter un quart de poisson et un quart de riz."])
    ]
}
