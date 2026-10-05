import Foundation
@testable import HealthGoals
import HealthKit
import Testing

struct PersonalPacingTests {
    @Test(arguments: [ActivityMetric.steps, .activeEnergy])
    func averagesUseFourObservationsPerWeekday(_ metric: ActivityMetric) throws {
        let calendar = try calendar()
        let window = try PatternWindow(now: date(calendar, year: 2026, month: 10, day: 9), calendar: calendar)
        let totals = window.intervals.enumerated().map { index, interval -> Double? in
            Double(PatternCalculator.mondayIndex(for: interval.start, calendar: calendar) + 1) + Double(index / 7)
        }
        let pattern = try #require(PatternCalculator.calculate(metric: metric, dailyTotals: totals, in: window))
        #expect(pattern.metric == metric)
        #expect(pattern.weekdayAverages == [2.5, 3.5, 4.5, 5.5, 6.5, 7.5, 8.5])
        #expect(pattern.historicalWeek == 38.5)
    }

    @Test(arguments: [(2026, 3, 30, 23), (2026, 10, 26, 25), (2027, 1, 1, 24)])
    func windowExcludesTodayAcrossDSTMonthAndYear(_ parts: (Int, Int, Int, Int)) throws {
        let calendar = try calendar()
        let now = try date(calendar, year: parts.0, month: parts.1, day: parts.2)
        let window = try PatternWindow(now: now, calendar: calendar)
        #expect(window.intervals.count == 28)
        #expect(window.today == calendar.startOfDay(for: now))
        #expect(window.intervals.last?.end == window.today)
        let first = try #require(window.intervals.first)
        #expect(calendar.dateComponents([.day], from: first.start, to: window.today).day == 28)
        for interval in window.intervals {
            #expect(calendar.dateComponents([.day], from: interval.start, to: interval.end).day == 1)
            #expect(calendar.component(.hour, from: interval.start) == 0)
        }
        #expect(window.intervals
            .contains { calendar.dateComponents([.hour], from: $0.start, to: $0.end).hour == parts.3 })
    }

    @Test func dailyFractionsExcludeCurrentDayAndRespectWeekendDistribution() throws {
        let calendar = try calendar()
        let monday = try date(calendar, year: 2026, month: 10, day: 5)
        let window = try PatternWindow(now: monday, calendar: calendar)
        let pattern = try #require(PatternCalculator.calculate(
            metric: .steps, dailyTotals: totals(in: window, weekdays: [1, 1, 1, 1, 1, 5, 10]), in: window
        ))
        let expected = [0.0, 0.05, 0.1, 0.15, 0.2, 0.25, 0.5]
        for (index, fraction) in expected.enumerated() {
            let day = try #require(calendar.date(byAdding: .day, value: index, to: monday))
            #expect(pattern.cumulativeFraction(at: day, calendar: calendar) == fraction)
        }
        let thursday = try #require(calendar.date(byAdding: .day, value: 3, to: monday))
        let progress = try progress(value: 150, day: thursday, calendar: calendar)
        #expect(PaceCalculator.state(for: progress, pattern: pattern, day: thursday, calendar: calendar) == .onTrack)
    }

    @Test func absentInvalidAndZeroHistoryStayDistinct() throws {
        let calendar = try calendar()
        let window = try PatternWindow(now: date(calendar, year: 2026, month: 10, day: 9), calendar: calendar)
        let complete = [Double?](repeating: 1, count: Constants.dayCount)
        for missing in [nil, -1, Double.nan, .infinity] as [Double?] {
            var values = complete
            values[0] = missing
            #expect(PatternCalculator.calculate(metric: .steps, dailyTotals: values, in: window) == nil)
        }
        #expect(PatternCalculator.calculate(metric: .steps, dailyTotals: Array(complete.dropLast()), in: window) == nil)
        #expect(PatternCalculator.calculate(metric: .steps, dailyTotals: complete + [1], in: window) == nil)
        #expect(PatternCalculator.calculate(
            metric: .steps, dailyTotals: Array(repeating: 0, count: Constants.dayCount), in: window
        ) == nil)
        var withExplicitZero = complete
        withExplicitZero[0] = 0
        #expect(PatternCalculator.calculate(metric: .steps, dailyTotals: withExplicitZero, in: window) != nil)
        #expect(PatternCalculator.calculate(
            metric: .steps, dailyTotals: Array(repeating: Double.greatestFiniteMagnitude, count: Constants.dayCount),
            in: window
        ) == nil)
        #expect(ActivityMetric.steps.value(from: nil) == nil)
        #expect(ActivityMetric.steps.value(from: HKQuantity(unit: .count(), doubleValue: 0)) == 0)
        #expect(ActivityMetric.activeEnergy.value(from: HKQuantity(unit: .kilocalorie(), doubleValue: 125.5)) == 125.5)
    }

    @Test(arguments: [
        (449.0, PaceState.belowPace),
        (450, .onTrack),
        (500, .onTrack),
        (550, .onTrack),
        (551, .ahead),
        (1000, .completed),
    ])
    func inclusiveToleranceAndPriority(_ sample: (Double, PaceState)) throws {
        let calendar = try calendar()
        let day = try date(calendar, year: 2026, month: 10, day: 9)
        let window = try PatternWindow(now: day, calendar: calendar)
        let pattern = try #require(PatternCalculator.calculate(
            metric: .steps, dailyTotals: totals(in: window, weekdays: [1, 1, 1, 1, 1, 1, 2]), in: window
        ))
        let goal = try #require(WeeklyGoal(metric: .steps, value: 1000))
        let week = try ActiveWeek(now: day, calendar: calendar)
        let progress = WeeklyProgress(goal: goal, value: sample.0, week: week, queriedAt: day)
        #expect(PaceCalculator.state(for: progress, pattern: pattern, day: day, calendar: calendar) == sample.1)
        #expect(PaceCalculator.state(for: progress, pattern: nil, day: day, calendar: calendar) ==
            (sample.1 == .completed ? .completed : .unknown))
    }

    @Test func mondayStartsAtZeroAndMetricMismatchIsUnknown() throws {
        let calendar = try calendar()
        let day = try date(calendar, year: 2026, month: 10, day: 5)
        let window = try PatternWindow(now: day, calendar: calendar)
        let values = [Double?](repeating: 1, count: Constants.dayCount)
        let pattern = try #require(PatternCalculator.calculate(metric: .steps, dailyTotals: values, in: window))
        #expect(try PaceCalculator.state(
            for: progress(value: 0, day: day, calendar: calendar),
            pattern: pattern,
            day: day,
            calendar: calendar
        ) == .onTrack)
        #expect(try PaceCalculator.state(
            for: progress(value: 50, day: day, calendar: calendar),
            pattern: pattern,
            day: day,
            calendar: calendar
        ) == .onTrack)
        #expect(try PaceCalculator.state(
            for: progress(value: 51, day: day, calendar: calendar),
            pattern: pattern,
            day: day,
            calendar: calendar
        ) == .ahead)
        let otherPattern = try #require(PatternCalculator.calculate(
            metric: .activeEnergy,
            dailyTotals: values,
            in: window
        ))
        #expect(try PaceCalculator.state(
            for: progress(value: 0, day: day, calendar: calendar),
            pattern: otherPattern,
            day: day,
            calendar: calendar
        ) == .unknown)
    }

    @Test func allStateAndExplanationStringsAreLocalized() throws {
        for language in ["en", "es"] {
            let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try #require(Bundle(path: path))
            for key in PaceState.allCases.map({ "pace.\($0.rawValue)" }) + [
                "pace.explanation",
                "pace.explanationTitle",
            ] {
                #expect(bundle.localizedString(forKey: key, value: nil, table: nil) != key)
            }
        }
    }
}

private extension PersonalPacingTests {
    enum Constants { static let dayCount = 28; static let queryHour = 15; static let testGoal = 1000 }

    func calendar() throws -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Madrid"))
        calendar.firstWeekday = 1
        return calendar
    }

    func date(_ calendar: Calendar, year: Int, month: Int, day: Int) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: year, month: month, day: day, hour: Constants.queryHour)))
    }

    func totals(in window: PatternWindow, weekdays: [Double]) -> [Double?] {
        window.intervals.map { weekdays[PatternCalculator.mondayIndex(for: $0.start, calendar: window.calendar)] }
    }

    func progress(value: Double, day: Date, calendar: Calendar) throws -> WeeklyProgress {
        try WeeklyProgress(
            goal: #require(WeeklyGoal(metric: .steps, value: Constants.testGoal)),
            value: value,
            week: ActiveWeek(now: day, calendar: calendar),
            queriedAt: day
        )
    }
}

@Suite @MainActor
struct PersonalPacingModelTests {
    @Test(arguments: [ActivityIntention.walking, .activity])
    func restorationRequeriesOnlyActiveMetricWithoutPersistingHealth(_ intention: ActivityIntention) async throws {
        let (model, reader, defaults, clock) = try setup(intention: intention)
        defer { defaults.removePersistentDomain(forName: clock.suiteName) }
        #expect(model.stage == .completed)
        #expect(model.progressState == .loading)
        await model.loadProgress()
        let initial = try available(model)
        #expect(initial.pace == .onTrack)
        #expect(initial.gap == 400)
        #expect(reader.progressMetrics == [intention.metric])
        #expect(reader.patternMetrics == [intention.metric])
        let restored = instance(reader, defaults: defaults, clock: clock)
        #expect(restored.progressState == .loading)
        await restored.loadProgress()
        #expect(try available(restored) == initial)
        #expect(reader.patternMetrics == [intention.metric, intention.metric])
        #expect(reader.authorizationRequests == 0)
        #expect(try Set(#require(defaults.dictionary(forKey: "onboarding.progress")).keys) ==
            ["intention", "stage", "goalMetric", "goalValue"])
    }

    @Test func patternFailureOrAbsencePreservesGapAndRetries() async throws {
        let (model, reader, defaults, clock) = try setup()
        defer { defaults.removePersistentDomain(forName: clock.suiteName) }
        reader.totals[0] = nil
        await model.loadProgress()
        #expect(try available(model).pace == .unknown)
        #expect(try available(model).gap == 400)
        reader.failPattern = true
        await model.loadProgress()
        #expect(try available(model).pace == .unknown)
        #expect(try available(model).gap == 400)
        reader.failPattern = false
        reader.totals[0] = 1
        await model.loadProgress()
        #expect(try available(model).pace == .onTrack)
        reader.quantity = Double(Constants.acceptedGoal)
        reader.failPattern = true
        await model.loadProgress()
        #expect(try available(model).pace == .completed)
        #expect(try available(model).gap == 0)
    }

    @Test func unavailableCurrentProgressNeverDisplaysHistoricalPace() async throws {
        let (model, reader, defaults, clock) = try setup()
        defer { defaults.removePersistentDomain(forName: clock.suiteName) }
        await model.loadProgress()
        #expect(try available(model).pace == .onTrack)
        let priorQueries = reader.patternMetrics.count
        reader.quantity = nil
        await model.loadProgress()
        #expect(model.progressState == .insufficient)
        #expect(reader.patternMetrics.count == priorQueries)
        reader.failProgress = true
        await model.loadProgress()
        #expect(model.progressState == .failed)
        #expect(reader.patternMetrics.count == priorQueries)
    }

    @Test func concurrentCallsShareBothQueriesAndGapAppearsBeforePattern() async throws {
        let (model, reader, defaults, clock) = try setup()
        defer { defaults.removePersistentDomain(forName: clock.suiteName) }
        reader.suspendPattern = true
        let first = Task { await model.loadProgress() }
        while reader.patternContinuation == nil {
            await Task.yield()
        }
        #expect(try available(model).gap == 400)
        #expect(try available(model).pace == .unknown)
        let second = Task { await model.loadProgress() }
        await Task.yield()
        reader.patternContinuation?.resume()
        await first.value
        await second.value
        #expect(reader.progressMetrics.count == 1)
        #expect(reader.patternMetrics.count == 1)
        #expect(try available(model).pace == .onTrack)
    }

    @Test(arguments: [1, 7])
    func patternFinishingAcrossDayOrWeekRequeriesConsistentContext(_ days: Int) async throws {
        let (model, reader, defaults, clock) = try setup()
        defer { defaults.removePersistentDomain(forName: clock.suiteName) }
        reader.suspendPattern = true
        let task = Task { await model.loadProgress() }
        while reader.patternContinuation == nil {
            await Task.yield()
        }
        clock.now = try #require(clock.calendar.date(byAdding: .day, value: days, to: clock.now))
        reader.suspendPattern = false
        reader.patternContinuation?.resume()
        await task.value
        #expect(reader.patternMetrics.count == 2)
        #expect(reader.progressMetrics.count == 2)
        #expect(reader.windows.last?.today == clock.calendar.startOfDay(for: clock.now))
        #expect(try available(model).week.queryEnd == clock.now)
        #expect(model.activeGoal?.value == 1000)
    }

    @Test func timeZoneChangeDiscardsInFlightPattern() async throws {
        let (model, reader, defaults, clock) = try setup()
        defer { defaults.removePersistentDomain(forName: clock.suiteName) }
        reader.suspendPattern = true
        let task = Task { await model.loadProgress() }
        while reader.patternContinuation == nil {
            await Task.yield()
        }
        clock.calendar.timeZone = try #require(TimeZone(identifier: "America/Los_Angeles"))
        reader.suspendPattern = false
        reader.patternContinuation?.resume()
        await task.value
        #expect(reader.windows.count == 2)
        #expect(reader.windows.last?.calendar.timeZone == clock.calendar.timeZone)
        #expect(try available(model).week.timeZone == clock.calendar.timeZone)
    }
}

private extension PersonalPacingModelTests {
    enum Constants { static let acceptedGoal = 1000 }

    func available(_ model: OnboardingModel) throws -> WeeklyProgress {
        guard case let .available(progress) = model.progressState else { throw Failure.unavailable }
        return progress
    }

    func setup(intention: ActivityIntention = .walking) throws
        -> (OnboardingModel, PacingHealth, UserDefaults, PacingClock)
    {
        let clock = try PacingClock()
        let defaults = try #require(UserDefaults(suiteName: clock.suiteName))
        defaults.set([
            "intention": intention.rawValue,
            "stage": "completed",
            "goalMetric": intention.metric.rawValue,
            "goalValue": Constants.acceptedGoal,
        ], forKey: "onboarding.progress")
        let reader = PacingHealth()
        return (instance(reader, defaults: defaults, clock: clock), reader, defaults, clock)
    }

    func instance(_ reader: PacingHealth, defaults: UserDefaults, clock: PacingClock) -> OnboardingModel {
        OnboardingModel(
            healthAuthorization: reader,
            healthReading: reader,
            progressReading: reader,
            patternReading: reader,
            defaults: defaults,
            now: { clock.now },
            calendar: { clock.calendar }
        )
    }

    enum Failure: Error { case unavailable }
}

@MainActor
private final class PacingClock {
    var now: Date
    var calendar: Calendar
    let suiteName = "HealthGoalsPacingTests.\(UUID().uuidString)"

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Madrid"))
        self.calendar = calendar
        now = try #require(calendar.date(from: Constants.fridayAfternoon))
    }
}

private extension PacingClock {
    enum Constants {
        static let year = 2026
        static let month = 10
        static let friday = 9
        static let afternoon = 15
        static let fridayAfternoon = DateComponents(year: year, month: month, day: friday, hour: afternoon)
    }
}

@MainActor
private final class PacingHealth: HealthAuthorizing, HealthReading, HealthProgressReading, HealthPatternReading {
    let isAvailable = true
    var authorizationRequests = 0
    var quantity: Double? = Constants.weeklyProgress
    var totals: [Double?] = Array(repeating: 1, count: Constants.dayCount)
    var failPattern = false
    var failProgress = false
    var suspendPattern = false
    var patternContinuation: CheckedContinuation<Void, Never>?
    var patternMetrics: [ActivityMetric] = []
    var progressMetrics: [ActivityMetric] = []
    var windows: [PatternWindow] = []

    func requestReadAuthorization() async throws {
        authorizationRequests += 1
    }

    func weeklyTotals(for _: ActivityMetric, in _: BaselineWindow) async throws -> [Double?] {
        []
    }

    func progress(for metric: ActivityMetric, in _: ActiveWeek) async throws -> Double? {
        progressMetrics.append(metric)
        if failProgress { throw Failure.technical }
        return quantity
    }

    func dailyTotals(for metric: ActivityMetric, in window: PatternWindow) async throws -> [Double?] {
        patternMetrics.append(metric)
        windows.append(window)
        if suspendPattern { await withCheckedContinuation { patternContinuation = $0 } }
        if failPattern { throw Failure.technical }
        return totals
    }
}

private extension PacingHealth {
    enum Constants { static let dayCount = 28; static let weeklyProgress = 600.0 }
    enum Failure: Error { case technical }
}
