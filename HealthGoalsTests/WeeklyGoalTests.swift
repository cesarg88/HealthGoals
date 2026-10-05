import Foundation
@testable import HealthGoals
import SwiftUI
import Testing

struct WeeklyGoalTests {
    @Test func fivePercentAndMetricRounding() {
        #expect(GoalEngine.propose(from: RecentBaseline(metric: .steps, weeklyAverage: 38500))?.value == 40400)
        #expect(GoalEngine.propose(from: RecentBaseline(metric: .activeEnergy, weeklyAverage: 3900))?.value == 4100)
        #expect(GoalEngine.propose(from: RecentBaseline(metric: .steps, weeklyAverage: 1000))?.value == 1100)
        #expect(GoalEngine.propose(from: RecentBaseline(metric: .activeEnergy, weeklyAverage: 100))?.value == 110)
    }

    @Test func roundedGoalFallsBackAboveCandidate() {
        #expect(GoalEngine.propose(from: RecentBaseline(metric: .steps, weeklyAverage: 100))?.value == 106)
        #expect(GoalEngine.propose(from: RecentBaseline(metric: .activeEnergy, weeklyAverage: 1))?.value == 2)
    }

    @Test(arguments: [0.0, -1, Double.nan, .infinity, Double.greatestFiniteMagnitude, Double(Int.max)])
    func unusableBaselineCannotProduceGoal(_ value: Double) {
        #expect(GoalEngine.propose(from: RecentBaseline(metric: .steps, weeklyAverage: value)) == nil)
    }

    @Test(arguments: [(2026, 10, 5, 7), (2026, 10, 9, 3), (2026, 10, 11, 1), (2027, 1, 1, 3)])
    func mondayAndInclusiveDays(_ parts: (Int, Int, Int, Int)) throws {
        let calendar = try calendar()
        let now = try date(calendar, year: parts.0, month: parts.1, day: parts.2)
        let week = try ActiveWeek(now: now, calendar: calendar)
        #expect(calendar.component(.weekday, from: week.interval.start) == 2)
        #expect(calendar.component(.hour, from: week.interval.start) == 0)
        #expect(calendar.component(.weekday, from: week.interval.end) == 2)
        #expect(calendar.dateComponents([.day], from: week.interval.start, to: week.interval.end).day == 7)
        #expect(week.queryEnd == now)
        #expect(week.daysRemaining == parts.3)
    }

    @Test func dstAndYearBoundariesAreCalendarBased() throws {
        let calendar = try calendar()
        let spring = try ActiveWeek(now: date(calendar, year: 2026, month: 3, day: 29), calendar: calendar)
        let autumn = try ActiveWeek(now: date(calendar, year: 2026, month: 10, day: 25), calendar: calendar)
        #expect(calendar.dateComponents([.hour], from: spring.interval.start, to: spring.interval.end).hour == 167)
        #expect(calendar.dateComponents([.hour], from: autumn.interval.start, to: autumn.interval.end).hour == 169)
        let year = try ActiveWeek(now: date(calendar, year: 2027, month: 1, day: 1), calendar: calendar)
        #expect(calendar.component(.year, from: year.interval.start) == 2026)
        #expect(calendar.component(.year, from: year.interval.end) == 2027)
    }

    @Test func homeRemainingUsesLocaleAndPluralAndKeepsPrecision() throws {
        let path = try #require(Bundle.main.path(forResource: "es", ofType: "lproj"))
        let bundle = try #require(Bundle(path: path))
        let single = 1.0
        let several = 249.75.rounded()
        #expect(String(
            localized: "home.stepsRemaining \(single)",
            bundle: bundle,
            locale: Locale(identifier: "es_ES")
        ) == "**1**\npaso esta semana")
        #expect(String(
            localized: "home.stepsRemaining \(several)",
            bundle: bundle,
            locale: Locale(identifier: "es_ES")
        ) == "**250**\npasos esta semana")
    }

    @Test func gapAndCompletedPreserveActualProgress() throws {
        let calendar = try calendar()
        let now = try date(calendar, year: 2026, month: 10, day: 9)
        let week = try ActiveWeek(now: now, calendar: calendar)
        let goal = try #require(WeeklyGoal(metric: .steps, value: 1000))
        let normal = WeeklyProgress(goal: goal, value: 750.25, week: week, queriedAt: now)
        #expect(normal.gap == 249.75)
        #expect(!normal.isCompleted)
        let completed = WeeklyProgress(goal: goal, value: 1200, week: week, queriedAt: now)
        #expect(completed.gap == 0)
        #expect(completed.isCompleted)
        #expect(completed.value == 1200)
    }
}

private extension WeeklyGoalTests {
    enum Constants { static let queryHour = 15 }
    func calendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Madrid"))
        calendar.firstWeekday = 1
        return calendar
    }

    func date(_ calendar: Calendar, year: Int, month: Int, day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: Constants.queryHour)))
    }
}

@Suite @MainActor
struct WeeklyGoalModelTests {
    @Test(arguments: [ActivityIntention.walking, .activity])
    func draftAcceptanceRestorationAndOnlyActiveMetric(_ intention: ActivityIntention) async throws {
        let (model, health, defaults, clock) = try setup(intention: intention)
        #expect(model.draftGoal == nil)
        #expect(!model.adjustDraft(to: "1000"))
        await model.loadBaseline()
        let proposed = try #require(model.draftGoal)
        #expect(proposed.metric == intention.metric)
        for invalid in ["", "0", "-1", "1.5", "words", "9999999999999999999999999999999"] {
            #expect(!model.adjustDraft(to: invalid))
            #expect(model.draftGoal == proposed)
        }
        #expect(model.adjustDraft(to: " 1200 "))
        #expect(model.activeGoal == nil)
        #expect(defaults.dictionary(forKey: "onboarding.progress")?["goalValue"] == nil)
        model.acceptGoal()
        #expect(model.stage == .completed)
        #expect(model.activeGoal?.value == 1200)
        await model.loadProgress()
        #expect(health.metrics == [intention.metric])
        guard case let .available(progress) = model.progressState
        else { Issue.record("Expected available progress"); return }
        #expect(progress.gap == 450)
        let persisted = try #require(defaults.dictionary(forKey: "onboarding.progress"))
        #expect(Set(persisted.keys) == ["selectedMetrics", "stage", "goals", "hasCompletedOnboarding"])
        let restored = modelInstance(health: health, defaults: defaults, clock: clock)
        #expect(restored.stage == .completed)
        #expect(restored.activeGoal == model.activeGoal)
        #expect(restored.progressState == .loading)
        #expect(restored.draftGoal == nil)
        await restored.loadProgress()
        #expect(health.authorizationRequests == 0)
        #expect(health.metrics == [intention.metric, intention.metric])
        defaults.removePersistentDomain(forName: clock.suiteName)
    }

    @Test func insufficientAndErrorCanRetryAndExplicitZeroIsAvailable() async throws {
        let (model, health, defaults, clock) = try setup()
        await model.loadBaseline()
        model.acceptGoal()
        health.quantity = nil
        await model.loadProgress()
        #expect(model.progressState == .insufficient)
        health.shouldFail = true
        await model.loadProgress()
        #expect(model.progressState == .failed)
        #expect(model.activeGoal != nil)
        health.shouldFail = false
        health.quantity = 0
        await model.loadProgress()
        guard case let .available(progress) = model.progressState
        else { Issue.record("Explicit zero is available"); return }
        #expect(progress.value == 0)
        #expect(progress.gap == Double(progress.goal.value))
        defaults.removePersistentDomain(forName: clock.suiteName)
    }

    @Test func noGoalWithoutUsablePositiveBaseline() async throws {
        let (model, health, defaults, clock) = try setup()
        health.totals = [nil, 1, 2, 3]
        await model.loadBaseline()
        #expect(model.draftGoal == nil)
        model.acceptGoal()
        #expect(model.stage == .startingPoint)
        health.totals = [0, 0, 0, 0]
        await model.loadBaseline(retry: true)
        #expect(model.draftGoal == nil)
        model.acceptGoal()
        #expect(model.activeGoal == nil)
        defaults.removePersistentDomain(forName: clock.suiteName)
    }

    @Test func queriesAreExclusiveAndNewWeekKeepsGoal() async throws {
        let (model, health, defaults, clock) = try setup()
        await model.loadBaseline()
        model.acceptGoal()
        let goal = model.activeGoal
        health.suspend = true
        let first = Task { await model.loadProgress() }
        while health.continuation == nil {
            await Task.yield()
        }
        #expect(model.progressState == .loading)
        let second = Task { await model.loadProgress() }
        await Task.yield()
        health.continuation?.resume()
        health.suspend = false
        await first.value
        await second.value
        #expect(health.weeks.count == 1)
        let previousStart = try #require(health.weeks.first?.interval.start)
        clock.now = try #require(clock.calendar.date(byAdding: .day, value: 7, to: clock.now))
        await model.loadProgress()
        #expect(model.activeGoal == goal)
        #expect(health.weeks.count == 2)
        #expect(health.weeks.last?.interval.start != previousStart)
        #expect(health.weeks.last?.queryEnd == clock.now)
        defaults.removePersistentDomain(forName: clock.suiteName)
    }

    @Test func inFlightWeekChangeDiscardsPriorInterval() async throws {
        let (model, health, defaults, clock) = try setup()
        await model.loadBaseline()
        model.acceptGoal()
        health.suspend = true
        let query = Task { await model.loadProgress() }
        while health.continuation == nil {
            await Task.yield()
        }
        clock.now = try #require(clock.calendar.date(byAdding: .day, value: 7, to: clock.now))
        health.suspend = false
        health.continuation?.resume()
        await query.value
        #expect(health.weeks.count == 2)
        guard case let .available(progress) = model.progressState else { Issue.record("Expected current week"); return }
        #expect(progress.week.interval == health.weeks.last?.interval)
        defaults.removePersistentDomain(forName: clock.suiteName)
    }

    @Test func proposalRendersLocalizedContent() async throws {
        let (model, _, defaults, clock) = try setup()
        await model.loadBaseline()
        try snapshot(model, name: "proposal-es-light", locale: "es_ES", scheme: .light)
        try snapshot(model, name: "proposal-en-dark", locale: "en_US", scheme: .dark)
        defaults.removePersistentDomain(forName: clock.suiteName)
    }

    @Test func corruptCompletedGoalFallsBackSafely() throws {
        let (_, health, defaults, clock) = try setup()
        defaults.set(
            ["intention": "walking", "stage": "completed", "goalMetric": "steps", "goalValue": -1],
            forKey: "onboarding.progress"
        )
        let restored = modelInstance(health: health, defaults: defaults, clock: clock)
        #expect(restored.stage == .startingPoint)
        #expect(restored.activeGoal == nil)
        defaults.removePersistentDomain(forName: clock.suiteName)
    }
}

private extension WeeklyGoalModelTests {
    enum Constants {
        static let snapshotPadding: CGFloat = 24
        static let snapshotWidth: CGFloat = 393
        static let snapshotHeight: CGFloat = 852
        static let expandedSnapshotHeight: CGFloat = 1400
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

    func setup(intention: ActivityIntention = .walking) throws
        -> (OnboardingModel, GoalHealth, UserDefaults, GoalClock)
    {
        let suiteName = "HealthGoalsWeeklyGoalTests.\(UUID().uuidString)"
        let defaults = try #require(UserDefaults(suiteName: suiteName))
        defaults.set(["intention": intention.rawValue, "stage": "startingPoint"], forKey: "onboarding.progress")
        let health = GoalHealth()
        let clock = try GoalClock(suiteName: suiteName)
        return (modelInstance(health: health, defaults: defaults, clock: clock), health, defaults, clock)
    }

    func modelInstance(health: GoalHealth, defaults: UserDefaults, clock: GoalClock) -> OnboardingModel {
        OnboardingModel(
            healthAuthorization: health,
            healthReading: health,
            progressReading: health,
            defaults: defaults,
            now: { clock.now },
            calendar: { clock.calendar }
        )
    }
}

@MainActor
private final class GoalClock {
    var now: Date
    let calendar: Calendar
    let suiteName: String

    init(suiteName: String) throws {
        self.suiteName = suiteName
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Madrid"))
        self.calendar = calendar
        now = try #require(calendar.date(from: Constants.fridayAfternoon))
    }
}

@MainActor
private final class GoalHealth: HealthAuthorizing, HealthReading, HealthProgressReading {
    let isAvailable = true
    var authorizationRequests = 0
    var totals: [Double?] = Array(repeating: Constants.weeklyTotal, count: Constants.blockCount)
    var quantity: Double? = 750
    var shouldFail = false
    var metrics: [ActivityMetric] = []
    var weeks: [ActiveWeek] = []
    var suspend = false
    var continuation: CheckedContinuation<Void, Never>?

    func needsAuthorizationRequest(for _: Set<ActivityMetric>) async throws -> Bool {
        false
    }

    func requestReadAuthorization(for _: Set<ActivityMetric>) async throws {
        authorizationRequests += 1
    }

    func weeklyTotals(for _: ActivityMetric, in _: BaselineWindow) async throws -> [Double?] {
        totals
    }

    func progress(for metric: ActivityMetric, in week: ActiveWeek) async throws -> Double? {
        metrics.append(metric)
        weeks.append(week)
        if suspend { await withCheckedContinuation { continuation = $0 } }
        if shouldFail { throw Failure.technical }
        return quantity
    }
}

private extension GoalClock {
    enum Constants { static let year = 2026
        static let month = 10
        static let friday = 9
        static let afternoon = 15
        static let fridayAfternoon = DateComponents(year: year, month: month, day: friday, hour: afternoon)
    }
}

private extension GoalHealth {
    enum Constants {
        static let weeklyTotal = 1000.0
        static let blockCount = 4
    }

    enum Failure: Error { case technical }
}
