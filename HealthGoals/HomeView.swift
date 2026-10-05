import SwiftUI

struct HomeView: View {
    let model: OnboardingModel
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.locale) private var locale
    @State private var isPaceExplanationExpanded = false
    @ScaledMetric(relativeTo: .largeTitle) private var remainingSize = Constants.remainingSize

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            Text("HealthGoals").font(.headline).foregroundStyle(Color("GoalAccent"))
            Text("home.title").font(.largeTitle.bold()).accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("home.title")
            if let week = model.activeWeek {
                Text("home.days \(week.daysRemaining)").foregroundStyle(Color("BaselineSecondary"))
            }
            if let goal = model.activeGoal {
                VStack(alignment: .leading, spacing: Constants.cardSpacing) {
                    Text(LocalizedStringKey(goal.metric == .steps ? "metric.steps" : "metric.activity"))
                        .font(.title3.weight(.semibold))
                    switch model.progressState {
                        case .loading:
                            ProgressView("home.loading").accessibilityIdentifier("home.loading")
                        case let .available(progress):
                            availableContent(progress)
                        case .insufficient:
                            Text("home.insufficient").accessibilityIdentifier("home.insufficient")
                            retryButton
                        case .failed:
                            Text("home.error").accessibilityIdentifier("home.error")
                            retryButton
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Constants.cardPadding)
                .background(Color("BaselineSurface"), in: RoundedRectangle(cornerRadius: Constants.cardRadius))
            }
            DisclosureGroup(isExpanded: $isPaceExplanationExpanded) {
                Text("pace.explanation")
                    .font(.subheadline).foregroundStyle(Color("BaselineSecondary"))
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("pace.explanation")
            } label: {
                Text("pace.explanationTitle").font(.subheadline)
                    .frame(minHeight: Constants.minimumTouchHeight, alignment: .leading)
            }
            .accessibilityIdentifier("pace.explanationToggle")
            Button("home.refresh") { Task { await model.loadProgress() } }
                .buttonStyle(.bordered).controlSize(.large)
                .disabled(model.progressState == .loading)
                .accessibilityIdentifier("home.refresh")
        }
        .foregroundStyle(Color("BaselineText"))
        .tint(Color("GoalAccent"))
        .task { await model.loadProgress() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { Task { await model.loadProgress() } }
        }
    }
}

private extension HomeView {
    enum Constants {
        static let sectionSpacing: CGFloat = 16
        static let cardSpacing: CGFloat = 4
        static let cardPadding: CGFloat = 16
        static let cardRadius: CGFloat = 24
        static let remainingSize: CGFloat = 42
        static let minimumTouchHeight: CGFloat = 44
    }

    var retryButton: some View {
        Button { Task { await model.loadProgress() } } label: {
            Text("common.retry").foregroundStyle(Color("GoalOnAccent"))
        }
        .buttonStyle(.borderedProminent).controlSize(.large)
        .accessibilityIdentifier("home.retry")
    }

    func formattedRemaining(_ progress: WeeklyProgress) -> AttributedString {
        let language = locale.language.languageCode?.identifier
        let bundle = language.flatMap { Bundle.main.path(forResource: $0, ofType: "lproj") }
            .flatMap(Bundle.init(path:)) ?? .main
        let rounded = progress.gap.rounded()
        let localized = progress.goal.metric == .steps
            ? String(localized: "home.stepsRemaining \(rounded)", bundle: bundle, locale: locale)
            : String(localized: "home.energyRemaining \(rounded)", bundle: bundle, locale: locale)
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        var value = (try? AttributedString(markdown: localized, options: options)) ?? AttributedString(localized)
        for run in value.runs where run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
            value[run.range].font = .system(size: remainingSize, weight: .semibold)
        }
        return value
    }

    @ViewBuilder
    func availableContent(_ progress: WeeklyProgress) -> some View {
        Text(progress.isCompleted ? "home.completed" : "home.remaining")
            .font(.subheadline).foregroundStyle(Color("BaselineSecondary"))
        Text(formattedRemaining(progress))
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("home.gap")
        let paceKey = "pace.\(progress.pace.rawValue)"
        Text(LocalizedStringKey(paceKey))
            .font(.subheadline).fixedSize(horizontal: false, vertical: true)
            .accessibilityIdentifier("pace.state")
        if progress.goal.metric == .steps {
            Text("home.stepsProgress \(progress.value) \(progress.goal.value)")
                .font(.subheadline).foregroundStyle(Color("BaselineSecondary"))
                .accessibilityIdentifier("home.progress")
        } else {
            Text("home.energyProgress \(progress.value) \(progress.goal.value)")
                .font(.subheadline).foregroundStyle(Color("BaselineSecondary"))
                .accessibilityIdentifier("home.progress")
        }
        ProgressView(value: min(progress.value / Double(progress.goal.value), 1))
            .accessibilityHidden(true)
        Text("home.queriedAt \(progress.queriedAt.formatted(.dateTime.hour().minute().locale(locale)))")
            .font(.footnote).foregroundStyle(Color("BaselineSecondary"))
    }
}
