import SwiftUI

struct OnboardingView: View {
    let model: OnboardingModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                switch model.stage {
                case .intention: intentionContent
                case .connectHealth: healthContent
                case .startingPoint: startingPointContent
                }
            }
            .frame(maxWidth: 560, alignment: .leading)
            .padding(24)
            .frame(maxWidth: .infinity, alignment: .top)
        }
    }

    private var intentionContent: some View {
        Group {
            heading("intention.title", identifier: "onboarding.intention.title")
            Text("intention.promise")
            Text("intention.question").font(.title2.bold())
            ForEach(ActivityIntention.allCases) { intention in
                intentionButton(intention)
            }
            Button("common.continue", action: model.continueToHealth)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .disabled(!model.canContinue)
                .accessibilityIdentifier("onboarding.continue")
        }
    }

    private func intentionButton(_ intention: ActivityIntention) -> some View {
        let selected = model.intention == intention
        return Button {
            model.select(intention)
        } label: {
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(LocalizedStringKey(intention == .walking ? "intention.walking" : "intention.activity"))
                        .font(.headline)
                    Text(LocalizedStringKey(intention == .walking ? "metric.steps" : "metric.activity"))
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
                Image(systemName: selected ? "checkmark.circle.fill" : "circle")
                    .accessibilityHidden(true)
            }
            .padding(16)
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .background(Color(uiColor: .secondarySystemBackground), in: RoundedRectangle(cornerRadius: 10))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityIdentifier("onboarding.intention.\(intention.rawValue)")
    }

    private var healthContent: some View {
        Group {
            heading("health.title", identifier: "onboarding.health.title")
            Text("health.explanation")
            Text("health.privacy")
            if model.requestState == .unavailable {
                Text("health.unavailable").accessibilityIdentifier("onboarding.health.error")
            } else if model.requestState == .failed {
                Text("health.error").accessibilityIdentifier("onboarding.health.error")
            }
            if model.requestState == .requesting {
                ProgressView("health.requesting")
            }
            Button(LocalizedStringKey(model.requestState == .failed || model.requestState == .unavailable
                   ? "common.retry" : "health.connect")) {
                Task { await model.connectHealth() }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(model.requestState == .requesting)
            .accessibilityIdentifier("onboarding.health.connect")
            Button("common.back", action: model.backToIntention)
                .buttonStyle(.bordered)
                .controlSize(.large)
                .disabled(model.requestState == .requesting)
                .accessibilityIdentifier("onboarding.back")
        }
    }

    private var startingPointContent: some View {
        Group {
            heading("startingPoint.title", identifier: "onboarding.startingPoint.title")
            // La siguiente Issue añadirá consultas y baseline; esta entrega no lee Salud.
            Text("startingPoint.pending")
            Text("startingPoint.requestCompleted").foregroundStyle(.secondary)
        }
    }

    private func heading(_ key: LocalizedStringKey, identifier: String) -> some View {
        Text(key)
            .font(.largeTitle.bold())
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier(identifier)
    }
}
