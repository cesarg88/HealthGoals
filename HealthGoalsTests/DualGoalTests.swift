import Foundation
@testable import HealthGoals
import Testing

@Suite @MainActor
struct DualGoalTests {
    @Test(arguments: [ActivityIntention.walking, .activity])
    func secondMetricRequiresExplicitActionAndUsesIndependentEngine(_ intention: ActivityIntention) async throws {
        let (model, reader, defaults, clock) = try setup()
        defer { defaults.removePersistentDomain(forName: clock.suite) }
        model.select(intention)
        model.continueToHealth()
        await model.connectHealth()
        await model.loadBaseline()
        #expect(reader.baselineMetrics == [intention.metric])
        let primary = try #require(model.draftGoals[intention.metric])
        #expect(model.proposalMetrics == [intention.metric])
        model.addMetric(intention.metric == .steps ? .activeEnergy : .steps)
        model.addMetric(intention.metric == .steps ? .activeEnergy : .steps)
        let secondary: ActivityMetric = intention.metric == .steps ? .activeEnergy : .steps
        #expect(secondary != intention.metric)
        #expect(reader.baselineMetrics == [intention.metric])
        #expect(!model.canAcceptGoals)
        await model.loadBaseline(for: secondary)
        #expect(reader.baselineMetrics == [intention.metric, secondary])
        #expect(model.draftGoals[intention.metric] == primary)
        let average = try #require(reader.baselines[secondary]?.first.flatMap { $0 })
        #expect(model.draftGoals[secondary] == GoalEngine.propose(from: RecentBaseline(
            metric: secondary,
            weeklyAverage: average
        )))
        #expect(model.adjustDraft(to: "250", metric: secondary))
        #expect(model.draftGoals[intention.metric] == primary)
        model.acceptGoal()
        #expect(model.stage == .completed)
        #expect(model.activeGoals.count == 2)
        #expect(Set(model.activeGoals.map(\.metric)).count == 2)
        model.acceptGoal()
        model.addMetric(intention.metric == .steps ? .activeEnergy : .steps)
        #expect(model.activeGoals.count == 2)
    }

    @Test func unavailableSecondProposalLeavesPrimaryIntactAndCanBeRemoved() async throws {
        let (model, reader, defaults, clock) = try setup()
        defer { defaults.removePersistentDomain(forName: clock.suite) }
        await beginProposal(model)
        let draft = model.draftGoal
        reader.baselines[.activeEnergy] = [nil, nil, nil, nil]
        model.addMetric(.activeEnergy)
        await model.loadBaseline(for: .activeEnergy)
        #expect(model.baselineState(for: .activeEnergy) == .insufficient)
        #expect(model.draftGoal == draft)
        model.acceptGoal()
        #expect(model.stage == .startingPoint)
        model.removeMetric(.activeEnergy)
        #expect(model.canAcceptGoals)
        model.acceptGoal()
        #expect(model.activeGoals == [draft].compactMap { $0 })
    }

    @Test func dualHomeHasIndependentStatesAndFailureDoesNotEraseOtherMetric() async throws {
        let (model, reader, defaults, clock) = try setup(active: true)
        defer { defaults.removePersistentDomain(forName: clock.suite) }
        reader.quantities[.steps] = 900
        reader.quantities[.activeEnergy] = 100
        await model.loadProgress()
        #expect(try progress(model, .steps).pace == .ahead)
        #expect(try progress(model, .activeEnergy).pace == .belowPace)
        let steps = try progress(model, .steps)
        reader.failedProgress = .activeEnergy
        await model.loadProgress()
        #expect(model.progressState(for: .activeEnergy) == .failed)
        #expect(try progress(model, .steps) == steps)
        reader.failedProgress = nil
        reader.quantities[.activeEnergy] = nil
        await model.loadProgress()
        #expect(model.progressState(for: .activeEnergy) == .insufficient)
        #expect(try progress(model, .steps) == steps)
    }

    @Test func activeEditingPreservesActivityRecalculatesImmediatelyAndPersists() async throws {
        let (model, reader, defaults, clock) = try setup(active: true)
        defer { defaults.removePersistentDomain(forName: clock.suite) }
        await model.loadProgress()
        let other = try progress(model, .activeEnergy)
        let original = try progress(model, .steps)
        #expect(original.pace == .ahead)
        for input in ["", "0", "-1", "1.5", "text"] {
            #expect(!model.editGoal(metric: .steps, to: input))
            #expect(try progress(model, .steps) == original)
        }
        #expect(model.editGoal(metric: .steps, to: "500"))
        #expect(try progress(model, .steps).value == original.value)
        #expect(try progress(model, .steps).gap == 0)
        #expect(try progress(model, .steps).pace == .completed)
        #expect(try progress(model, .steps).queriedAt == original.queriedAt)
        #expect(try progress(model, .activeEnergy) == other)
        #expect(model.editGoal(metric: .steps, to: "2000"))
        #expect(try progress(model, .steps).gap == 1400)
        #expect(try progress(model, .steps).pace == .belowPace)
        let restored = instance(reader, defaults, clock)
        #expect(restored.stage == .completed)
        #expect(restored.activeGoals == model.activeGoals)
        #expect(restored.progressState(for: .steps) == .loading)
        await restored.loadProgress()
        #expect(try progress(restored, .steps).goal.value == 2000)
        #expect(reader.authorizationRequests == 0)
        let saved = try #require(defaults.dictionary(forKey: "onboarding.progress"))
        #expect(Set(saved.keys) == ["selectedMetrics", "stage", "goals", "hasCompletedOnboarding"])
        let records = try #require(saved["goals"] as? [[String: Any]])
        #expect(records.allSatisfy { Set($0.keys) == ["metric", "value"] })
    }

    @Test func editingWhilePatternIsInFlightNeverRestoresOlderGoal() async throws {
        let (model, reader, defaults, clock) = try setup(active: true)
        defer { defaults.removePersistentDomain(forName: clock.suite) }
        reader.suspendedPattern = .steps
        let task = Task { await model.loadProgress() }
        while reader.patternContinuation == nil {
            await Task.yield()
        }
        #expect(model.editGoal(metric: .steps, to: "500"))
        #expect(try progress(model, .steps).pace == .completed)
        reader.patternContinuation?.resume()
        await task.value
        #expect(try progress(model, .steps).goal.value == 500)
        #expect(try progress(model, .steps).value == 600)
        #expect(try progress(model, .steps).gap == 0)
        #expect(try progress(model, .steps).pace == .completed)
    }

    @Test func editingDuringRefreshConservesObservedProgressBeforeAndAfterResponse() async throws {
        let (model, reader, defaults, clock) = try setup(active: true)
        defer { defaults.removePersistentDomain(forName: clock.suite) }
        await model.loadProgress()
        let observed = try progress(model, .steps)
        reader.suspendedProgress = .steps
        let task = Task { await model.loadProgress(for: .steps) }
        while reader.progressContinuation == nil {
            await Task.yield()
        }
        #expect(model.isRefreshing(.steps))
        #expect(model.editGoal(metric: .steps, to: "500"))
        #expect(try progress(model, .steps).value == observed.value)
        #expect(try progress(model, .steps).gap == 0)
        #expect(try progress(model, .steps).pace == .completed)
        reader.progressContinuation?.resume()
        await task.value
        #expect(try progress(model, .steps).goal.value == 500)
        #expect(try progress(model, .steps).value == observed.value)
    }

    @Test func retryingOneMetricDoesNotRequeryOrInvalidateOtherCard() async throws {
        let (model, reader, defaults, clock) = try setup(active: true)
        defer { defaults.removePersistentDomain(forName: clock.suite) }
        reader.failedProgress = .activeEnergy
        await model.loadProgress()
        let steps = try progress(model, .steps)
        let calls = reader.progressMetrics.count(where: { $0 == .steps })
        reader.failedProgress = nil
        await model.loadProgress(for: .activeEnergy)
        #expect(try progress(model, .steps) == steps)
        #expect(reader.progressMetrics.count(where: { $0 == .steps }) == calls)
        #expect(try progress(model, .activeEnergy).value == 600)
    }

    @Test func removedSecondaryDiscardsLateBaselineWithoutLosingPrimaryDraft() async throws {
        let (model, reader, defaults, clock) = try setup()
        defer { defaults.removePersistentDomain(forName: clock.suite) }
        await beginProposal(model)
        let primary = model.draftGoal
        model.addMetric(.activeEnergy)
        reader.suspendedBaseline = .activeEnergy
        let task = Task { await model.loadBaseline(for: .activeEnergy) }
        while reader.baselineContinuation == nil {
            await Task.yield()
        }
        model.removeMetric(.activeEnergy)
        reader.baselineContinuation?.resume()
        await task.value
        #expect(model.draftGoal == primary)
        #expect(model.draftGoals[.activeEnergy] == nil)
        #expect(model.baselineStates[.activeEnergy] == nil)
        #expect(model.canAcceptGoals)
    }

    @Test func deletionDuringQueryDiscardsLateResponseAndPreservesOtherGoal() async throws {
        let (model, reader, defaults, clock) = try setup(active: true)
        defer { defaults.removePersistentDomain(forName: clock.suite) }
        reader.suspendedPattern = .steps
        let task = Task { await model.loadProgress() }
        while reader.patternContinuation == nil {
            await Task.yield()
        }
        model.deleteGoal(metric: .steps)
        reader.patternContinuation?.resume()
        await task.value
        #expect(model.activeGoals.map(\.metric) == [.activeEnergy])
        #expect(model.progressStates[.steps] == nil)
        #expect(try progress(model, .activeEnergy).value == 600)
        #expect(instance(reader, defaults, clock).activeGoals == model.activeGoals)
    }

    @Test func deletingLastGoalRestoresEmptyHomeAndRechoosesWithoutWelcomeOrAuthorization() async throws {
        let (model, reader, defaults, clock) = try setup(active: true)
        defer { defaults.removePersistentDomain(forName: clock.suite) }
        model.deleteGoal(metric: .steps)
        model.deleteGoal(metric: .activeEnergy)
        #expect(model.stage == .completed)
        #expect(model.activeGoals.isEmpty)
        let restored = instance(reader, defaults, clock)
        #expect(restored.stage == .completed)
        #expect(restored.activeGoals.isEmpty)
        restored.chooseGoal()
        #expect(restored.hasCompletedOnboarding)
        #expect(restored.selectedMetrics.isEmpty)
        #expect(!restored.canContinue)
        restored.select(.activity)
        restored.continueToHealth()
        #expect(restored.stage == .startingPoint)
        await restored.loadBaseline()
        restored.acceptGoal()
        #expect(restored.activeGoals.map(\.metric) == [.activeEnergy])
        #expect(reader.authorizationRequests == 0)
        #expect(instance(reader, defaults, clock).stage == .completed)
    }

    @Test func cancellingReselectionAndRelaunchPreserveCompletedContext() throws {
        let (model, reader, defaults, clock) = try setup(active: true)
        defer { defaults.removePersistentDomain(forName: clock.suite) }
        model.deleteGoal(metric: .steps)
        model.deleteGoal(metric: .activeEnergy)
        model.chooseGoal()
        var restored = instance(reader, defaults, clock)
        #expect(restored.stage == .intention)
        #expect(restored.hasCompletedOnboarding)
        restored.select(.walking)
        restored.continueToHealth()
        restored = instance(reader, defaults, clock)
        #expect(restored.stage == .startingPoint)
        #expect(restored.hasCompletedOnboarding)
        restored.cancelChoosingGoal()
        #expect(restored.stage == .completed)
        #expect(restored.activeGoals.isEmpty)
        #expect(reader.authorizationRequests == 0)
    }

    @Test(arguments: [ActivityIntention.walking, .activity])
    func legacySingleGoalMigratesWithoutLosingDefinition(_ intention: ActivityIntention) throws {
        let (_, reader, defaults, clock) = try setup()
        defer { defaults.removePersistentDomain(forName: clock.suite) }
        defaults.set([
            "intention": intention.rawValue,
            "stage": "completed",
            "goalMetric": intention.metric.rawValue,
            "goalValue": Constants.goal,
        ], forKey: "onboarding.progress")
        let model = instance(reader, defaults, clock)
        #expect(model.stage == .completed)
        #expect(model.activeGoals == [WeeklyGoal(metric: intention.metric, value: Constants.goal)].compactMap { $0 })
        #expect(defaults.dictionary(forKey: "onboarding.progress")?["goalMetric"] == nil)
        #expect(instance(reader, defaults, clock).activeGoals == model.activeGoals)
    }

    @Test func restoredCollectionRejectsInvalidAndDuplicateMetrics() throws {
        let (_, reader, defaults, clock) = try setup()
        defer { defaults.removePersistentDomain(forName: clock.suite) }
        defaults.set(["stage": "completed", "goals": [
            ["metric": "steps", "value": 1000], ["metric": "steps", "value": 2000],
            ["metric": "activeEnergy", "value": -1], ["metric": "activeEnergy", "value": 500],
            ["metric": "distance", "value": 1000],
        ]], forKey: "onboarding.progress")
        let model = instance(reader, defaults, clock)
        #expect(model.activeGoals.count == 2)
        #expect(model.activeGoals.first?.value == 1000)
        #expect(model.activeGoals.last?.value == 500)
    }

    @Test func newVisibleCopyIsLocalized() throws {
        for language in ["en", "es"] {
            let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try #require(Bundle(path: path))
            for key in [
                "goal.addActivity",
                "goal.addSteps",
                "goal.removeSecondary",
                "goal.acceptBoth",
                "goal.save",
                "goal.currentWeekEffect",
                "goal.delete",
                "goal.deleteStepsTitle",
                "goal.deleteActivityTitle",
                "goal.deleteExplanation",
                "baseline.stepsAccessHelp",
                "baseline.activityAccessHelp",
                "home.empty",
                "home.chooseGoal",
            ] {
                #expect(bundle.localizedString(forKey: key, value: nil, table: nil) != key)
            }
        }
    }
}

private extension DualGoalTests {
    enum Constants { static let goal = 1000 }
    enum Failure: Error { case unavailable }

    func progress(_ model: OnboardingModel, _ metric: ActivityMetric) throws -> WeeklyProgress {
        guard case let .available(progress) = model.progressState(for: metric) else { throw Failure.unavailable }
        return progress
    }

    func setup(active: Bool = false) throws -> (OnboardingModel, DualHealth, UserDefaults, DualClock) {
        let clock = try DualClock()
        let defaults = try #require(UserDefaults(suiteName: clock.suite))
        if active {
            defaults.set(
                [
                    "intention": "walking",
                    "stage": "completed",
                    "hasCompletedOnboarding": true,
                    "goals": [
                        ["metric": "steps", "value": Constants.goal],
                        ["metric": "activeEnergy", "value": Constants.goal],
                    ],
                ],
                forKey: "onboarding.progress"
            )
        }
        let reader = DualHealth()
        return (instance(reader, defaults, clock), reader, defaults, clock)
    }

    func instance(_ reader: DualHealth, _ defaults: UserDefaults, _ clock: DualClock) -> OnboardingModel {
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

    func beginProposal(_ model: OnboardingModel) async {
        model.select(.walking)
        model.continueToHealth()
        await model.connectHealth()
        await model.loadBaseline()
    }
}

@MainActor private final class DualClock {
    let suite = "HealthGoalsDualTests.\(UUID().uuidString)"
    let now: Date
    let calendar: Calendar

    init() throws {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "Europe/Madrid"))
        self.calendar = calendar
        now = try #require(calendar.date(from: Constants.friday))
    }
}

private extension DualClock {
    enum Constants { static let year = 2026
        static let month = 10
        static let day = 9
        static let hour = 15
        static let friday = DateComponents(year: year, month: month, day: day, hour: hour)
    }
}

@MainActor private final class DualHealth: HealthAuthorizing, HealthReading, HealthProgressReading,
    HealthPatternReading
{
    let isAvailable = true
    var authorizationRequests = 0
    var baselineMetrics: [ActivityMetric] = []
    var baselines: [ActivityMetric: [Double?]] = [
        .steps: Array(repeating: Constants.steps, count: Constants.weeks),
        .activeEnergy: Array(repeating: Constants.energy, count: Constants.weeks),
    ]
    var quantities: [ActivityMetric: Double] = [.steps: Constants.quantity, .activeEnergy: Constants.quantity]
    var progressMetrics: [ActivityMetric] = []
    var suspendedProgress: ActivityMetric?
    var progressContinuation: CheckedContinuation<Void, Never>?
    var suspendedBaseline: ActivityMetric?
    var baselineContinuation: CheckedContinuation<Void, Never>?
    var failedProgress: ActivityMetric?
    var suspendedPattern: ActivityMetric?
    var patternContinuation: CheckedContinuation<Void, Never>?

    func needsAuthorizationRequest(for _: Set<ActivityMetric>) async throws -> Bool {
        false
    }

    func requestReadAuthorization(for _: Set<ActivityMetric>) async throws {
        authorizationRequests += 1
    }

    func weeklyTotals(for metric: ActivityMetric, in _: BaselineWindow) async throws -> [Double?] {
        baselineMetrics.append(metric)
        if suspendedBaseline == metric { await withCheckedContinuation { baselineContinuation = $0 } }
        return baselines[metric] ?? []
    }

    func progress(for metric: ActivityMetric, in _: ActiveWeek) async throws -> Double? {
        progressMetrics.append(metric)
        if suspendedProgress == metric { await withCheckedContinuation { progressContinuation = $0 } }
        if failedProgress == metric { throw Failure.technical }
        return quantities[metric]
    }

    func dailyTotals(for metric: ActivityMetric, in window: PatternWindow) async throws -> [Double?] {
        if suspendedPattern == metric { await withCheckedContinuation { patternContinuation = $0 } }
        return window.intervals
            .map {
                PatternCalculator.mondayIndex(for: $0.start, calendar: window.calendar) == Constants.sunday ? Constants
                    .sundayWeight : 1
            }
    }
}

private extension DualHealth {
    enum Constants {
        static let steps = 1000.0
        static let energy = 100.0
        static let weeks = 4
        static let quantity = 600.0
        static let sunday = 6
        static let sundayWeight = 2.0
    }

    enum Failure: Error { case technical }
}
