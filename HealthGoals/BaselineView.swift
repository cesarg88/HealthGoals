import SwiftUI

struct BaselineView: View {
    let model: OnboardingModel
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            Text("startingPoint.title")
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)
                .accessibilityIdentifier("onboarding.startingPoint.title")
            switch model.baselineState {
                case .loading:
                    ProgressView("baseline.loading")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .accessibilityIdentifier("baseline.loading")
                case let .available(baseline):
                    activityCard(baseline)
                case .insufficient:
                    recoveryContent("baseline.insufficient", identifier: "baseline.insufficient")
                case .failed:
                    recoveryContent("baseline.error", identifier: "baseline.error")
            }
            Text("baseline.windowExplanation")
                .font(.footnote)
                .foregroundStyle(Color("BaselineSecondary"))
        }
        .foregroundStyle(Color("BaselineText"))
        .task { await model.loadBaseline() }
    }
}

private extension BaselineView {
    enum Constants {
        static let sectionSpacing: CGFloat = 12
        static let cardSpacing: CGFloat = 4
        static let cardPadding: CGFloat = 16
        static let cardCornerRadius: CGFloat = 24
        static let minimumTouchHeight: CGFloat = 54
    }

    func activityCard(_ baseline: RecentBaseline) -> some View {
        VStack(alignment: .leading, spacing: Constants.cardSpacing) {
            Text("baseline.recentActivity").font(.headline)
            Text("baseline.averageExplanation")
                .font(.subheadline)
                .foregroundStyle(Color("BaselineSecondary"))
            Text(formattedValue(baseline))
                .fixedSize(horizontal: false, vertical: true)
                .font(.subheadline)
                .foregroundStyle(Color("BaselineSecondary"))
                .accessibilityIdentifier("baseline.value")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(Constants.cardPadding)
        .background(Color("BaselineSurface"), in: RoundedRectangle(cornerRadius: Constants.cardCornerRadius))
        .accessibilityIdentifier("baseline.available")
    }

    func formattedValue(_ baseline: RecentBaseline) -> AttributedString {
        // Catalog plural rules and locale format the complete value/unit phrase; Markdown marks only the number.
        let options = AttributedString.MarkdownParsingOptions(interpretedSyntax: .inlineOnlyPreservingWhitespace)
        let rounded = baseline.weeklyAverage.rounded()
        let language = locale.language.languageCode?.identifier
        let bundle = language.flatMap { Bundle.main.path(forResource: $0, ofType: "lproj") }
            .flatMap(Bundle.init(path:)) ?? .main
        let localized = baseline.metric == .steps
            ? String(localized: "baseline.steps \(rounded)", bundle: bundle, locale: locale)
            : String(localized: "baseline.energy \(rounded)", bundle: bundle, locale: locale)
        var value = (try? AttributedString(markdown: localized, options: options)) ?? AttributedString(localized)
        for run in value.runs where run.inlinePresentationIntent?.contains(.stronglyEmphasized) == true {
            value[run.range].font = .title.weight(.semibold)
            value[run.range].foregroundColor = Color("BaselineText")
        }
        return value
    }

    func recoveryContent(_ key: LocalizedStringKey, identifier: String) -> some View {
        VStack(alignment: .leading, spacing: Constants.sectionSpacing) {
            Text(key).accessibilityIdentifier(identifier)
            Button("common.retry") {
                Task { await model.loadBaseline(retry: true) }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .frame(minHeight: Constants.minimumTouchHeight)
            .accessibilityIdentifier("baseline.retry")
        }
    }
}
