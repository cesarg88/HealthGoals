import SwiftUI

struct OnboardingView: View {
    let model: OnboardingModel

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
                switch model.stage {
                    case .intention: intentionContent
                    case .connectHealth: healthContent
                    case .startingPoint: BaselineView(model: model)
                }
            }
            .frame(maxWidth: Constants.maximumContentWidth, alignment: .leading)
            .padding(Constants.contentPadding)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .background(model.stage == .startingPoint ? Color("BaselineBackground") : Color(uiColor: .systemBackground))
    }
}

private extension OnboardingView {
    enum Constants {
        static let sectionSpacing: CGFloat = 20
        static let maximumContentWidth: CGFloat = 560
        static let contentPadding: CGFloat = 24
        static let optionSpacing: CGFloat = 16
        static let labelSpacing: CGFloat = 4
        static let minimumTouchHeight: CGFloat = 44
        static let optionCornerRadius: CGFloat = 10
    }

    var intentionContent: some View {
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

    func intentionButton(_ intention: ActivityIntention) -> some View {
        let selected = model.intention == intention
        return Button {
            model.select(intention)
        } label: {
            HStack(spacing: Constants.optionSpacing) {
                VStack(alignment: .leading, spacing: Constants.labelSpacing) {
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
            .padding(Constants.optionSpacing)
            .frame(maxWidth: .infinity, minHeight: Constants.minimumTouchHeight, alignment: .leading)
            .background(
                Color(uiColor: .secondarySystemBackground),
                in: RoundedRectangle(cornerRadius: Constants.optionCornerRadius)
            )
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(selected ? [.isSelected] : [])
        .accessibilityIdentifier("onboarding.intention.\(intention.rawValue)")
    }

    var healthContent: some View {
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
                    ? "common.retry" : "health.connect"))
            {
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

    func heading(_ key: LocalizedStringKey, identifier: String) -> some View {
        Text(key)
            .font(.largeTitle.bold())
            .accessibilityAddTraits(.isHeader)
            .accessibilityIdentifier(identifier)
    }
}
