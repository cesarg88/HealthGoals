import Foundation
import Observation

enum ActivityIntention: String, CaseIterable, Identifiable {
    case walking
    case activity

    var id: Self { self }
    var metric: ActivityMetric { self == .walking ? .steps : .activeEnergy }
}

enum ActivityMetric { case steps, activeEnergy }
enum OnboardingStage: String { case intention, connectHealth, startingPoint }
enum AuthorizationRequestState: Equatable { case idle, requesting, unavailable, failed }

@MainActor
@Observable
final class OnboardingModel {
    private(set) var intention: ActivityIntention?
    private(set) var stage: OnboardingStage = .intention
    private(set) var requestState: AuthorizationRequestState = .idle
    private let healthAuthorization: any HealthAuthorizing
    private let defaults: UserDefaults
    private static let progressKey = "onboarding.progress"

    var canContinue: Bool { intention != nil }

    init(healthAuthorization: any HealthAuthorizing, defaults: UserDefaults) {
        self.healthAuthorization = healthAuthorization
        self.defaults = defaults
        let progress = defaults.dictionary(forKey: Self.progressKey)
        intention = (progress?["intention"] as? String).flatMap(ActivityIntention.init(rawValue:))
        // Sin intención válida, una etapa guardada nunca permite saltar S01.
        if intention != nil, let rawStage = progress?["stage"] as? String,
           let savedStage = OnboardingStage(rawValue: rawStage) {
            stage = savedStage
        }
    }

    func select(_ intention: ActivityIntention) {
        guard stage == .intention else { return }
        self.intention = intention
        saveProgress()
    }

    func continueToHealth() {
        guard stage == .intention, canContinue else { return }
        stage = .connectHealth
        requestState = .idle
        saveProgress()
    }

    func backToIntention() {
        guard stage == .connectHealth, requestState != .requesting else { return }
        stage = .intention
        requestState = .idle
        saveProgress()
    }

    func connectHealth() async {
        guard stage == .connectHealth, requestState != .requesting else { return }
        guard healthAuthorization.isAvailable else {
            requestState = .unavailable
            return
        }
        requestState = .requesting
        do {
            try await healthAuthorization.requestReadAuthorization()
            // Solo finalizó la solicitud. No conocemos permisos de lectura ni datos.
            stage = .startingPoint
            requestState = .idle
            saveProgress()
        } catch {
            requestState = .failed
        }
    }

    private func saveProgress() {
        guard let intention else { return }
        // S02 se guarda antes de pedir autorización; nunca se persiste una operación en curso.
        defaults.set(["intention": intention.rawValue, "stage": stage.rawValue], forKey: Self.progressKey)
    }
}
