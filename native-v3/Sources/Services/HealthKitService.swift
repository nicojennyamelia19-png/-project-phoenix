import Foundation
import HealthKit
import CoreLocation

@MainActor
final class HealthKitService: ObservableObject {
    @Published private(set) var isAuthorized = false
    @Published private(set) var workouts: [WorkoutSummary] = []
    @Published private(set) var routePoints: [RoutePoint] = []
    @Published private(set) var stepsToday: Double = 0
    @Published private(set) var activeEnergyToday: Double = 0
    @Published private(set) var sleepHours: Double = 0
    @Published private(set) var restingHeartRate: Double = 0
    @Published private(set) var vo2Max: Double = 0
    @Published var statusMessage = "Apple Santé n’est pas encore connecté."

    private let store = HKHealthStore()
    private var healthWorkouts: [UUID: HKWorkout] = [:]
    private var observerQuery: HKObserverQuery?

    private var stepType: HKQuantityType { HKObjectType.quantityType(forIdentifier: .stepCount)! }
    private var energyType: HKQuantityType { HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)! }
    private var distanceType: HKQuantityType { HKObjectType.quantityType(forIdentifier: .distanceWalkingRunning)! }
    private var heartRateType: HKQuantityType { HKObjectType.quantityType(forIdentifier: .heartRate)! }
    private var restingHeartRateType: HKQuantityType { HKObjectType.quantityType(forIdentifier: .restingHeartRate)! }
    private var vo2MaxType: HKQuantityType { HKObjectType.quantityType(forIdentifier: .vo2Max)! }
    private var bodyMassType: HKQuantityType { HKObjectType.quantityType(forIdentifier: .bodyMass)! }
    private var sleepType: HKCategoryType { HKObjectType.categoryType(forIdentifier: .sleepAnalysis)! }

    func requestAuthorization() async {
        guard HKHealthStore.isHealthDataAvailable() else {
            statusMessage = "Apple Santé n’est pas disponible sur cet appareil."
            return
        }

        let readTypes: Set<HKObjectType> = [
            HKObjectType.workoutType(),
            HKSeriesType.workoutRoute(),
            stepType,
            energyType,
            distanceType,
            heartRateType,
            restingHeartRateType,
            vo2MaxType,
            bodyMassType,
            sleepType
        ]

        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            statusMessage = "Apple Santé connecté. Les séances de l’Apple Watch et des apps autorisées peuvent être importées."
            enableWorkoutUpdates()
            await refreshAll()
        } catch {
            statusMessage = "Connexion Apple Santé impossible : \(error.localizedDescription)"
        }
    }

    func refreshAll() async {
        guard isAuthorized else { return }
        do {
            async let workoutsResult = queryWorkouts()
            async let stepsResult = quantitySum(type: stepType, unit: .count(), start: Calendar.current.startOfDay(for: .now))
            async let energyResult = quantitySum(type: energyType, unit: .kilocalorie(), start: Calendar.current.startOfDay(for: .now))
            async let sleepResult = querySleepHours()
            async let restingResult = latestQuantity(type: restingHeartRateType, unit: HKUnit.count().unitDivided(by: .minute()))
            async let vo2Result = latestQuantity(type: vo2MaxType, unit: HKUnit(from: "ml/kg*min"))

            let (newWorkouts, steps, energy, sleep, resting, vo2) = try await (workoutsResult, stepsResult, energyResult, sleepResult, restingResult, vo2Result)
            workouts = newWorkouts
            stepsToday = steps
            activeEnergyToday = energy
            sleepHours = sleep
            restingHeartRate = resting
            vo2Max = vo2
        } catch {
            statusMessage = "Certaines données n’ont pas pu être lues : \(error.localizedDescription)"
        }
    }

    var todayMatchedWorkout: WorkoutSummary? {
        let plan = DailyPlan.plan()
        return workouts.first { workout in
            guard Calendar.current.isDateInToday(workout.startDate) else { return false }
            let minutes = workout.duration / 60
            let durationFits = abs(minutes - Double(plan.targetMinutes)) <= max(15, Double(plan.targetMinutes) * 0.45)
            let runningPlan = [.easyRun, .fartlek, .intervals, .longRun].contains(plan.kind)
            return durationFits && (!runningPlan || workout.activityName == "Course")
        }
    }

    func loadRoute(for summary: WorkoutSummary) async {
        routePoints = []
        guard let workout = healthWorkouts[summary.healthKitUUID] else { return }
        do {
            routePoints = try await queryRoute(for: workout)
        } catch {
            statusMessage = "Le parcours GPS n’est pas disponible : \(error.localizedDescription)"
        }
    }

    private func enableWorkoutUpdates() {
        let workoutType = HKObjectType.workoutType()
        store.enableBackgroundDelivery(for: workoutType, frequency: .immediate) { _, _ in }

        if let observerQuery {
            store.stop(observerQuery)
        }

        let query = HKObserverQuery(sampleType: workoutType, predicate: nil) { [weak self] _, completion, _ in
            Task { @MainActor in
                await self?.refreshAll()
                completion()
            }
        }
        observerQuery = query
        store.execute(query)
    }

    private func queryWorkouts() async throws -> [WorkoutSummary] {
        let distanceType = self.distanceType
        let energyType = self.energyType
        let heartRateType = self.heartRateType

        return try await withCheckedThrowingContinuation { continuation in
            let start = Calendar.current.date(byAdding: .month, value: -6, to: .now)!
            let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictEndDate)
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
            let query = HKSampleQuery(sampleType: HKObjectType.workoutType(), predicate: predicate, limit: 250, sortDescriptors: [sort]) { [weak self] _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }
                let hkWorkouts = (samples as? [HKWorkout]) ?? []
                var summaries: [WorkoutSummary] = []
                var lookup: [UUID: HKWorkout] = [:]

                for workout in hkWorkouts {
                    lookup[workout.uuid] = workout
                    let distance = workout.statistics(for: distanceType)?.sumQuantity()?.doubleValue(for: .meterUnit(with: .kilo)) ?? 0
                    let calories = workout.statistics(for: energyType)?.sumQuantity()?.doubleValue(for: .kilocalorie()) ?? 0
                    let averageHR = workout.statistics(for: heartRateType)?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: .minute()))
                    let source = workout.sourceRevision.source.name
                    let normalized = source.folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
                    summaries.append(WorkoutSummary(
                        id: workout.uuid,
                        healthKitUUID: workout.uuid,
                        activityName: Self.activityName(workout.workoutActivityType),
                        startDate: workout.startDate,
                        duration: workout.duration,
                        distanceKm: distance,
                        activeKilocalories: calories,
                        averageHeartRate: averageHR,
                        sourceName: source,
                        isFromAdidas: normalized.contains("adidas") || normalized.contains("runtastic")
                    ))
                }

                Task { @MainActor in self?.healthWorkouts = lookup }
                continuation.resume(returning: summaries)
            }
            store.execute(query)
        }
    }

    private func quantitySum(type: HKQuantityType, unit: HKUnit, start: Date) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForSamples(withStart: start, end: .now, options: .strictStartDate)
            let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, result, error in
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: result?.sumQuantity()?.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }

    private func latestQuantity(type: HKQuantityType, unit: HKUnit) async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                let sample = samples?.first as? HKQuantitySample
                continuation.resume(returning: sample?.quantity.doubleValue(for: unit) ?? 0)
            }
            store.execute(query)
        }
    }

    private func querySleepHours() async throws -> Double {
        try await withCheckedThrowingContinuation { continuation in
            let start = Calendar.current.date(byAdding: .hour, value: -30, to: .now)!
            let predicate = HKQuery.predicateForSamples(withStart: start, end: .now)
            let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                let seconds = (samples as? [HKCategorySample] ?? []).reduce(0.0) { total, sample in
                    let isAwake = sample.value == HKCategoryValueSleepAnalysis.awake.rawValue
                    let isInBed = sample.value == HKCategoryValueSleepAnalysis.inBed.rawValue
                    return total + ((!isAwake && !isInBed) ? sample.endDate.timeIntervalSince(sample.startDate) : 0)
                }
                continuation.resume(returning: seconds / 3600)
            }
            store.execute(query)
        }
    }

    private func queryRoute(for workout: HKWorkout) async throws -> [RoutePoint] {
        let routeSamples: [HKWorkoutRoute] = try await withCheckedThrowingContinuation { continuation in
            let predicate = HKQuery.predicateForObjects(from: workout)
            let query = HKSampleQuery(sampleType: HKSeriesType.workoutRoute(), predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
                if let error { continuation.resume(throwing: error); return }
                continuation.resume(returning: (samples as? [HKWorkoutRoute]) ?? [])
            }
            store.execute(query)
        }

        guard let route = routeSamples.first else { return [] }
        return try await withCheckedThrowingContinuation { continuation in
            var all: [RoutePoint] = []
            var finished = false
            let query = HKWorkoutRouteQuery(route: route) { _, locations, done, error in
                guard !finished else { return }
                if let error {
                    finished = true
                    continuation.resume(throwing: error)
                    return
                }
                for location in locations ?? [] {
                    all.append(RoutePoint(latitude: location.coordinate.latitude, longitude: location.coordinate.longitude, altitude: location.altitude, timestamp: location.timestamp))
                }
                if done {
                    finished = true
                    continuation.resume(returning: all)
                }
            }
            store.execute(query)
        }
    }

    private static func activityName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Course"
        case .walking: return "Marche"
        case .traditionalStrengthTraining, .functionalStrengthTraining: return "Renforcement"
        case .cycling: return "Vélo"
        case .hiking: return "Randonnée"
        case .highIntensityIntervalTraining: return "Fractionné"
        default: return "Entraînement"
        }
    }
}
