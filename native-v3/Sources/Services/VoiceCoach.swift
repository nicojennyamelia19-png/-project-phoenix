import AVFoundation
import Foundation
import Combine

@MainActor
final class VoiceCoach: ObservableObject {
    private let synthesizer = AVSpeechSynthesizer()
    @Published var isEnabled = true

    func speak(_ text: String) {
        guard isEnabled else { return }
        let utterance = AVSpeechUtterance(string: text)
        utterance.voice = AVSpeechSynthesisVoice(language: "fr-FR")
        utterance.rate = 0.47
        utterance.volume = 1
        synthesizer.stopSpeaking(at: .immediate)
        synthesizer.speak(utterance)
    }

    func announcePlan(_ plan: DailyPlan) {
        if let repetitions = plan.repetitions,
           let effort = plan.effortSeconds,
           let recovery = plan.recoverySeconds {
            speak("Séance \(plan.title). Échauffement de \(plan.warmupMinutes) minutes, puis \(repetitions) répétitions de \(effort) secondes d'effort et \(recovery) secondes de récupération.")
        } else {
            speak("Séance \(plan.title), durée prévue \(plan.targetMinutes) minutes. Pars tranquillement et garde une allure contrôlée.")
        }
    }
}
