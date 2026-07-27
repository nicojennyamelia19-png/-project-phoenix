import SwiftUI

@main
struct ProjectPhoenixV3App: App {
    @StateObject private var health = HealthKitService()
    @StateObject private var workoutKit = WorkoutKitService()
    @StateObject private var voiceCoach = VoiceCoach()
    @StateObject private var friends = CloudFriendService()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(health)
                .environmentObject(workoutKit)
                .environmentObject(voiceCoach)
                .environmentObject(friends)
                .preferredColorScheme(.dark)
        }
    }
}
