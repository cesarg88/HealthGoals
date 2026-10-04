import Foundation
@testable import HealthGoals
import HealthKit
import SwiftUI
import Testing

struct BaselineTests {
    @Test func stepsMeanUsesExactlyFourWeeklyTotals() {
        #expect(BaselineCalculator.calculate(metric: .steps, weeklyTotals: [37000, 41000, 36000, 40000]) ==
            RecentBaseline(metric: .steps, weeklyAverage: 38500))
    }

    @Test func energyMeanPreservesPrecision() {
        #expect(BaselineCalculator.calculate(metric: .activeEnergy, weeklyTotals: [100.25, 200.5, 300.75, 400.5]) ==
            RecentBaseline(metric: .activeEnergy, weeklyAverage: 250.5))
    }

    @Test(arguments: [[nil, 1, 2, 3], [1, nil, 2, 3], [1, 2, nil, 3], [1, 2, 3, nil], [], [1, 2, 3]])
    func missingBlockIsUnknown(_ totals: [Double?]) {
        #expect(BaselineCalculator.calculate(metric: .steps, weeklyTotals: totals) == nil)
    }

    @Test func explicitZeroIsUsableWithoutInferringDailyCoverage() {
        #expect(BaselineCalculator.calculate(metric: .steps, weeklyTotals: [0, 0, 0, 0])?.weeklyAverage == 0)
        #expect(BaselineCalculator.calculate(metric: .steps, weeklyTotals: [0, 4, 8, 12])?.weeklyAverage == 6)
    }

    @Test(arguments: [Double.nan, .infinity, -.infinity, -1])
    func invalidQuantityCannotBecomeBaseline(_ value: Double) {
        #expect(BaselineCalculator.calculate(metric: .activeEnergy, weeklyTotals: [1, 2, 3, value]) == nil)
    }

    @Test func normalizesOnlyTheChosenMetricAndPreservesNil() {
        #expect(ActivityMetric.steps.quantityType == HKQuantityType(.stepCount))
        #expect(ActivityMetric.activeEnergy.quantityType == HKQuantityType(.activeEnergyBurned))
        #expect(ActivityMetric.steps.value(from: HKQuantity(unit: .count(), doubleValue: 0)) == 0)
        #expect(ActivityMetric.steps.value(from: nil) == nil)
        #expect(ActivityMetric.activeEnergy.value(from: nil) == nil)
        #expect(ActivityMetric.activeEnergy.value(from: HKQuantity(unit: .kilocalorie(), doubleValue: 12.75)) == 12.75)
        #expect(ActivityMetric.activeEnergy.value(from: HKQuantity(unit: .joule(), doubleValue: 4184)) == 1)
    }

    @Test(arguments: [(2027, 1, 10), (2026, 3, 31), (2026, 10, 27), (2026, 5, 2)])
    func calendarWindowHasFourConsecutiveBlocks(_ components: (Int, Int, Int)) throws {
        let calendar = try localCalendar()
        let now = try #require(calendar.date(from: DateComponents(
            year: components.0,
            month: components.1,
            day: components.2,
            hour: 15
        )))
        let window = try BaselineWindow(now: now, calendar: calendar)
        #expect(window.intervals.count == 4)
        let start = try #require(window.intervals.first?.start)
        let end = try #require(window.intervals.last?.end)
        #expect(calendar.dateComponents([.day], from: start, to: end).day == 28)
        #expect(end == calendar.startOfDay(for: now))
        #expect(end < now)
        for (index, interval) in window.intervals.enumerated() {
            #expect(calendar.dateComponents([.day], from: interval.start, to: interval.end).day == 7)
            #expect(calendar.component(.hour, from: interval.start) == 0)
            #expect(calendar.component(.hour, from: interval.end) == 0)
            if index > 0 { #expect(interval.start == window.intervals[index - 1].end) }
        }
    }

    @Test func daylightSavingChangesHoursWithoutChangingCalendarDays() throws {
        let calendar = try localCalendar()
        let spring = try #require(calendar.date(from: DateComponents(year: 2026, month: 3, day: 31)))
        let autumn = try #require(calendar.date(from: DateComponents(year: 2026, month: 10, day: 27)))
        let springBlock = try #require(BaselineWindow(now: spring, calendar: calendar).intervals.last)
        let autumnBlock = try #require(BaselineWindow(now: autumn, calendar: calendar).intervals.last)
        #expect(calendar.dateComponents([.hour], from: springBlock.start, to: springBlock.end).hour == 167)
        #expect(calendar.dateComponents([.hour], from: autumnBlock.start, to: autumnBlock.end).hour == 169)
    }

    @Test func localizedIntegerPresentationPreservesTheUnderlyingValue() {
        let value = 38500.25
        #expect(value
            .formatted(.number.locale(Locale(identifier: "es_ES")).precision(.fractionLength(0))
                .grouping(.automatic)) ==
            "38.500")
        #expect(value
            .formatted(.number.locale(Locale(identifier: "en_US")).precision(.fractionLength(0))
                .grouping(.automatic)) ==
            "38,500")
        #expect(value == 38500.25)
    }

    @Test func localizedStepPhraseUsesNativePluralRules() throws {
        let single = 1.0
        let several = 2.0
        let weeklyAverage = 38500.25
        let roundedSingle = 1.25.rounded()
        let spanishPath = try #require(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let englishPath = try #require(Bundle.main.path(forResource: "en", ofType: "lproj"))
        let spanish = try #require(Bundle(path: spanishPath))
        let english = try #require(Bundle(path: englishPath))
        #expect(String(
            localized: "baseline.steps \(weeklyAverage)",
            bundle: spanish,
            locale: Locale(identifier: "es_ES")
        ) == "**38.500**\npasos / semana")
        #expect(String(
            localized: "baseline.steps \(weeklyAverage)",
            bundle: english,
            locale: Locale(identifier: "en_US")
        ) == "**38,500**\nsteps / week")
        #expect(String(localized: "baseline.steps \(single)", bundle: spanish, locale: Locale(identifier: "es_ES")) ==
            "**1**\npaso / semana")
        #expect(String(localized: "baseline.steps \(several)", bundle: spanish, locale: Locale(identifier: "es_ES")) ==
            "**2**\npasos / semana")
        #expect(String(
            localized: "baseline.steps \(roundedSingle)",
            bundle: spanish,
            locale: Locale(identifier: "es_ES")
        ) == "**1**\npaso / semana")
        #expect(String(localized: "baseline.steps \(single)", bundle: english, locale: Locale(identifier: "en_US")) ==
            "**1**\nstep / week")
        #expect(String(localized: "baseline.steps \(several)", bundle: english, locale: Locale(identifier: "en_US")) ==
            "**2**\nsteps / week")
    }
}

private extension BaselineTests {
    func localCalendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Madrid"))
        return calendar
    }
}

@Suite @MainActor
struct BaselineModelTests {
    @Test func noQueryBeforeStartingPoint() async throws {
        let (model, reader, _) = try setup()
        await model.loadBaseline()
        #expect(reader.metrics.isEmpty)
        model.select(.walking)
        model.continueToHealth()
        await model.loadBaseline()
        #expect(reader.metrics.isEmpty)
    }

    @Test(arguments: [ActivityIntention.walking, .activity])
    func completedRequestQueriesOnlyPrimaryMetric(_ intention: ActivityIntention) async throws {
        let (model, reader, _) = try setup()
        model.select(intention)
        model.continueToHealth()
        await model.connectHealth()
        #expect(model.baselineState == .loading)
        await model.loadBaseline()
        #expect(reader.metrics == [intention.metric])
        #expect(model.baselineState == .available(RecentBaseline(metric: intention.metric, weeklyAverage: 38500)))
        #expect(model.intention == intention)
        #expect(model.stage == .startingPoint)
        #expect(reader.windows.first?.intervals.last?.end == Date(timeIntervalSince1970: 0))
    }

    @Test func missingQuantityIsNeutralAndCanRetry() async throws {
        let (model, reader, _) = try setup(restored: true)
        reader.totals = [1, nil, 3, 4]
        await model.loadBaseline()
        #expect(model.baselineState == .insufficient)
        reader.totals = [0, 0, 0, 0]
        await model.loadBaseline(retry: true)
        #expect(model.baselineState == .available(RecentBaseline(metric: .steps, weeklyAverage: 0)))
        #expect(reader.metrics.count == 2)
    }

    @Test func technicalFailureIsRecoverableWithoutChangingProgress() async throws {
        let (model, reader, _) = try setup(restored: true)
        reader.shouldFail = true
        await model.loadBaseline()
        #expect(model.baselineState == .failed)
        #expect(model.intention == .walking)
        #expect(model.stage == .startingPoint)
        reader.shouldFail = false
        await model.loadBaseline(retry: true)
        #expect(model.baselineState == .available(RecentBaseline(metric: .steps, weeklyAverage: 38500)))
    }

    @Test func repeatedAppearanceDoesNotRepeatQueryWithoutExplicitRetry() async throws {
        let (model, reader, _) = try setup(restored: true)
        await model.loadBaseline()
        await model.loadBaseline()
        #expect(reader.metrics.count == 1)
        await model.loadBaseline(retry: true)
        #expect(reader.metrics.count == 2)
    }

    @Test func simultaneousRequestsShareOneFiniteQueryDespiteViewCancellation() async throws {
        let (model, reader, _) = try setup(restored: true)
        reader.suspendRequest = true
        let task = Task { await model.loadBaseline() }
        while reader.continuation == nil {
            await Task.yield()
        }
        #expect(model.baselineState == .loading)
        task.cancel()
        let appearance = Task { await model.loadBaseline() }
        let retry = Task { await model.loadBaseline(retry: true) }
        await Task.yield()
        #expect(reader.metrics.count == 1)
        reader.continuation?.resume()
        await task.value
        await appearance.value
        await retry.value
        #expect(model.baselineState == .available(RecentBaseline(metric: .steps, weeklyAverage: 38500)))
        #expect(reader.metrics.count == 1)
    }

    @Test func restorationQueriesAgainWithoutAuthorizationOrHealthPersistence() async throws {
        let (model, reader, defaults) = try setup(restored: true)
        let before = defaults.dictionary(forKey: "onboarding.progress") as? [String: String]
        await model.loadBaseline()
        #expect(defaults.dictionary(forKey: "onboarding.progress") as? [String: String] == before)
        #expect(before == ["intention": "walking", "stage": "startingPoint"])
        let authorization = BaselineAuthorization()
        let restored = OnboardingModel(healthAuthorization: authorization, healthReading: reader, defaults: defaults)
        #expect(restored.baselineState == .loading)
        await restored.loadBaseline()
        #expect(authorization.requests == 0)
        #expect(reader.metrics.count == 2)
        #expect(restored.intention == .walking)
        #expect(restored.stage == .startingPoint)
    }

    @Test func baselinePresentationHasLocalizedAdaptiveSnapshots() async throws {
        let (available, _, _) = try setup(restored: true)
        await available.loadBaseline()
        try snapshot(available, name: "steps-es-light", locale: "es_ES", scheme: .light)
        try snapshot(available, name: "steps-en-dark", locale: "en_US", scheme: .dark)
        let (energy, energyReader, _) = try setup(restored: true, intention: .activity)
        energyReader.totals = [100, 200, 300, 400]
        await energy.loadBaseline()
        try snapshot(energy, name: "energy-en-dark", locale: "en_US", scheme: .dark)
        let (insufficient, insufficientReader, _) = try setup(restored: true)
        insufficientReader.totals = [1, nil, 3, 4]
        await insufficient.loadBaseline()
        #expect(insufficient.baselineState == .insufficient)
        try snapshot(
            insufficient,
            name: "insufficient-es-accessibility",
            locale: "es_ES",
            scheme: .light,
            textSize: .accessibility3
        )
        let (failed, failedReader, _) = try setup(restored: true)
        failedReader.shouldFail = true
        await failed.loadBaseline()
        #expect(failed.baselineState == .failed)
        try snapshot(failed, name: "error-en-dark", locale: "en_US", scheme: .dark)
    }
}

private extension BaselineModelTests {
    enum Constants {
        static let snapshotWidth: CGFloat = 393
        static let snapshotHeight: CGFloat = 852
        static let expandedSnapshotHeight: CGFloat = 1200
        static let snapshotPadding: CGFloat = 24
    }

    func snapshot(
        _ model: OnboardingModel,
        name: String,
        locale: String,
        scheme: ColorScheme,
        textSize: DynamicTypeSize = .large
    ) throws {
        let renderer = ImageRenderer(content: BaselineView(model: model)
            .padding(Constants.snapshotPadding)
            .frame(
                width: Constants.snapshotWidth,
                height: textSize.isAccessibilitySize ? Constants.expandedSnapshotHeight : Constants.snapshotHeight,
                alignment: .topLeading
            )
            .background(Color("BaselineBackground"))
            .environment(\.locale, Locale(identifier: locale))
            .environment(\.colorScheme, scheme)
            .environment(\.dynamicTypeSize, textSize))
        let image = try #require(renderer.uiImage)
        try Attachment.record(#require(image.pngData()), named: "\(name).png")
    }

    func setup(
        restored: Bool = false,
        intention: ActivityIntention = .walking
    ) throws -> (OnboardingModel, FakeHealthReader, UserDefaults) {
        let defaults = try #require(UserDefaults(suiteName: "HealthGoalsBaselineTests.\(UUID().uuidString)"))
        if restored { defaults.set(
            ["intention": intention.rawValue, "stage": "startingPoint"],
            forKey: "onboarding.progress"
        ) }
        let reader = FakeHealthReader()
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(secondsFromGMT: 0))
        let model = OnboardingModel(
            healthAuthorization: BaselineAuthorization(),
            healthReading: reader,
            defaults: defaults,
            now: { Date(timeIntervalSince1970: 0) },
            calendar: { calendar }
        )
        return (model, reader, defaults)
    }
}

@MainActor
final class FakeHealthReader: HealthReading {
    var totals = Constants.weeklyTotals
    var shouldFail = false
    var suspendRequest = false
    var continuation: CheckedContinuation<Void, Never>?
    var metrics: [ActivityMetric] = []
    var windows: [BaselineWindow] = []
    enum Failure: Error { case technical }

    func weeklyTotals(for metric: ActivityMetric, in window: BaselineWindow) async throws -> [Double?] {
        metrics.append(metric)
        windows.append(window)
        if suspendRequest { await withCheckedContinuation { continuation = $0 } }
        if shouldFail { throw Failure.technical }
        return totals
    }
}

@MainActor
private final class BaselineAuthorization: HealthAuthorizing {
    let isAvailable = true
    var requests = 0

    func requestReadAuthorization() async throws {
        requests += 1
    }
}

private extension FakeHealthReader {
    enum Constants {
        static let firstWeekTotal = 37000.0
        static let secondWeekTotal = 41000.0
        static let thirdWeekTotal = 36000.0
        static let fourthWeekTotal = 40000.0
        static let weeklyTotals: [Double?] = [firstWeekTotal, secondWeekTotal, thirdWeekTotal, fourthWeekTotal]
    }
}
