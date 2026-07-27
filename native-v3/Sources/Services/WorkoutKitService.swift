import Foundation
import Combine
import HealthKit
import WorkoutKit

@MainActor
final class WorkoutKitService: ObservableObject {
    @Published var statusMessage = "Prêt à synchroniser la séance avec l’Apple Watch."
    @Published var isWorking = false

    func openTodayOnWatch() async {
        isWorking = true
        defer { isWorking = false }

        guard WorkoutScheduler.isSupported else {
            statusMessage = "La synchronisation des séances n’est pas prise en charge sur cet appareil."
            return
        }

        let scheduler = WorkoutScheduler.shared
        let authorization = await scheduler.requestAuthorization()
        guard authorization == .authorized else {
            statusMessage = "Autorise Project Phoenix à programmer les entraînements dans les réglages."
            return
        }

        let workoutPlan = makeWorkoutPlan(from: DailyPlan.plan())
        let date = Calendar.current.date(byAdding: .minute, value: 2, to: .now) ?? .now
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        await scheduler.schedule(workoutPlan, at: components)
        statusMessage = "Séance envoyée. Ouvre l’app Exercice sur l’Apple Watch : elle apparaît dans les séances programmées."
    }

    func scheduleToday() async {
        isWorking = true
        defer { isWorking = false }

        guard WorkoutScheduler.isSupported else {
            statusMessage = "Les séances planifiées ne sont pas disponibles sur cet appareil."
            return
        }

        let scheduler = WorkoutScheduler.shared
        let authorization = await scheduler.requestAuthorization()
        guard authorization == .authorized else {
            statusMessage = "Autorise Project Phoenix à programmer les entraînements dans les réglages."
            return
        }

        let phoenixPlan = DailyPlan.plan()
        let workoutPlan = makeWorkoutPlan(from: phoenixPlan)
        var components = Calendar.current.dateComponents([.year, .month, .day], from: .now)
        components.hour = 18
        components.minute = 0
        await scheduler.schedule(workoutPlan, at: components)
        statusMessage = "Séance programmée aujourd’hui à 18 h dans l’app Exercice."
    }

    private func makeWorkoutPlan(from plan: DailyPlan) -> WorkoutPlan {
        let runningKinds: Set<DailyPlan.Kind> = [.easyRun, .fartlek, .intervals, .longRun]

        if runningKinds.contains(plan.kind),
           let effort = plan.effortSeconds,
           let recovery = plan.recoverySeconds,
           let repetitions = plan.repetitions {
            let warmup = WorkoutStep(goal: .time(Double(plan.warmupMinutes * 60), .seconds))
            let workStep = IntervalStep(.work, goal: .time(Double(effort), .seconds))
            let recoveryStep = IntervalStep(.recovery, goal: .time(Double(recovery), .seconds))
            let block = IntervalBlock(steps: [workStep, recoveryStep], iterations: repetitions)
            let cooldown = WorkoutStep(goal: .time(Double(plan.cooldownMinutes * 60), .seconds))
            let workout = CustomWorkout(
                activity: .running,
                location: .outdoor,
                displayName: plan.title,
                warmup: warmup,
                blocks: [block],
                cooldown: cooldown
            )
            return WorkoutPlan(.custom(workout), id: plan.id)
        }

        let activity: HKWorkoutActivityType
        switch plan.kind {
        case .strength: activity = .functionalStrengthTraining
        case .recovery: activity = .walking
        default: activity = .running
        }

        let location: HKWorkoutSessionLocationType = activity == .functionalStrengthTraining ? .indoor : .outdoor
        let workout = SingleGoalWorkout(
            activity: activity,
            location: location,
            goal: .time(Double(plan.targetMinutes * 60), .seconds)
        )
        return WorkoutPlan(.goal(workout), id: plan.id)
    }
}
