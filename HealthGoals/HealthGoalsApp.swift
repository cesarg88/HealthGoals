import SwiftUI

@main
struct HealthGoalsApp: App {
    @State private var onboarding = OnboardingModel(
        healthAuthorization: HealthAuthorization(), defaults: .standard
    )

    var body: some Scene {
        WindowGroup {
            OnboardingView(model: onboarding)
        }
    }
}
