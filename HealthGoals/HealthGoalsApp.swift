import SwiftUI

@main
struct HealthGoalsApp: App {
    var body: some Scene {
        WindowGroup {
            Text(verbatim: "HealthGoals")
                .font(.title)
                .padding()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .accessibilityIdentifier("bootstrap.title")
        }
    }
}
