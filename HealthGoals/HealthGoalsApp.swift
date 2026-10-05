import SwiftUI

@main
struct HealthGoalsApp: App {
    @State private var onboarding = makeOnboarding()

    var body: some Scene {
        WindowGroup {
            OnboardingView(model: onboarding)
        }
    }
}

private extension HealthGoalsApp {
    static func makeOnboarding() -> OnboardingModel {
        let health = HealthAuthorization()
        return OnboardingModel(
            healthAuthorization: health,
            healthReading: health,
            progressReading: health,
            patternReading: health,
            defaults: .standard
        )
    }
}
