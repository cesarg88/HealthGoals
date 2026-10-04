import Foundation
import Observation

enum ActivityIntention: String, CaseIterable, Identifiable {
    case walking
    case activity

    var id: Self {
        self
    }

    var metric: ActivityMetric {
        self == .walking ? .steps : .activeEnergy
    }
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

    var canContinue: Bool {
        intention != nil
    }

    init(healthAuthorization: any HealthAuthorizing, defaults: UserDefaults) {
        self.healthAuthorization = healthAuthorization
        self.defaults = defaults
        let progress = defaults.dictionary(forKey: Self.progressKey)
        intention = (progress?["intention"] as? String).flatMap(ActivityIntention.init(rawValue:))
        // A saved stage never skips S01 without a valid intention.
        if intention != nil, let rawStage = progress?["stage"] as? String,
           let savedStage = OnboardingStage(rawValue: rawStage)
        {
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
            // Only the request finished. Read access and available data remain unknown.
            stage = .startingPoint
            requestState = .idle
            saveProgress()
        } catch {
            requestState = .failed
        }
    }
}

private extension OnboardingModel {
    func saveProgress() {
        guard let intention else { return }
        // Persist S02 before requesting authorization; never persist an in-flight operation.
        defaults.set(["intention": intention.rawValue, "stage": stage.rawValue], forKey: Self.progressKey)
    }
}
