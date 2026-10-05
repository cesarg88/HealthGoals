import Foundation
@testable import HealthGoals
import HealthKit
import Testing

@Suite @MainActor
struct MetricSelectionTests {
    @Test(arguments: [Set<ActivityMetric>(), [.steps], [.activeEnergy], [.steps, .activeEnergy]])
    func initialSelectionRequestsOnlyExplicitMetrics(_ metrics: Set<ActivityMetric>) async throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        for intention in ActivityIntention.allCases where metrics.contains(intention.metric) {
            fixture.model.select(intention)
        }
        #expect(fixture.model.canContinue == !metrics.isEmpty)
        fixture.model.continueToHealth()
        await fixture.model.connectHealth()
        #expect(fixture.health.requests == (metrics.isEmpty ? [] : [metrics]))
        if !metrics.isEmpty {
            await fixture.model.loadBaseline()
            #expect(Set(fixture.health.queries) == metrics)
            #expect(Set(fixture.model.draftGoals.keys) == metrics)
            #expect(fixture.health.statusChecks.isEmpty)
        }
        #expect(ActivityMetric.steps.quantityType == HKQuantityType(.stepCount))
        #expect(ActivityMetric.activeEnergy.quantityType == HKQuantityType(.activeEnergyBurned))
    }

    @Test func togglingBothBackAndRestorationPreserveStableSelection() throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        fixture.model.select(.activity)
        fixture.model.select(.walking)
        #expect(fixture.model.proposalMetrics == [.steps, .activeEnergy])
        fixture.model.continueToHealth()
        fixture.model.backToIntention()
        let restored = fixture.restore()
        #expect(restored.stage == .intention)
        #expect(restored.selectedMetrics == [.steps, .activeEnergy])
        restored.select(.walking)
        #expect(restored.selectedMetrics == [.activeEnergy])
        restored.select(.walking)
        #expect(restored.proposalMetrics == [.steps, .activeEnergy])
        restored.select(.activity)
        restored.select(.walking)
        #expect(restored.selectedMetrics.isEmpty)
        #expect(!restored.canContinue)
    }

    @Test(
        arguments: [ActivityIntention.walking, .activity],
        [OnboardingStage.intention, .connectHealth, .startingPoint]
    )
    func legacySelectionMigratesWithoutStoringHealth(_ intention: ActivityIntention, stage: OnboardingStage) throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        fixture.defaults.set(["intention": intention.rawValue, "stage": stage.rawValue], forKey: "onboarding.progress")
        let restored = fixture.restore()
        #expect(restored.stage == stage)
        #expect(restored.selectedMetrics == [intention.metric])
        let saved = try #require(fixture.defaults.dictionary(forKey: "onboarding.progress"))
        #expect(Set(saved.keys) == ["selectedMetrics", "stage"])
        #expect(fixture.health.requests.isEmpty)
        #expect(fixture.health.queries.isEmpty)
    }

    @Test func existingAcceptedDefinitionsStayIntactWithoutAutomaticAuthorization() async throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        let records = [["metric": "activeEnergy", "value": 200], ["metric": "steps", "value": 1000]] as [[String: Any]]
        fixture.defaults.set([
            "intention": "activity", "stage": "completed", "hasCompletedOnboarding": true, "goals": records,
        ], forKey: "onboarding.progress")
        let restored = fixture.restore()
        #expect(restored.activeGoals == [
            WeeklyGoal(metric: .steps, value: 1000),
            WeeklyGoal(metric: .activeEnergy, value: 200),
        ].compactMap { $0 })
        #expect(restored.stage == .completed)
        await restored.loadBaseline()
        #expect(fixture.health.requests.isEmpty)
        #expect(fixture.health.statusChecks.isEmpty)
        #expect(fixture.restore().activeGoals == restored.activeGoals)
    }

    @Test func duplicateAndUnknownSelectionRecordsCannotAddMetrics() throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        fixture.defaults.set(
            ["stage": "connectHealth", "selectedMetrics": ["steps", "steps", "distance", "activeEnergy"]],
            forKey: "onboarding.progress"
        )
        #expect(fixture.restore().proposalMetrics == [.steps, .activeEnergy])
    }

    @Test(arguments: [true, false])
    func addingMetricChecksPresentationBeforeReading(_ needsRequest: Bool) async throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        await fixture.beginWalking()
        let walkingDraft = fixture.model.draftGoals[.steps]
        fixture.health.events = []
        fixture.health.needsRequest[.activeEnergy] = needsRequest
        fixture.model.addMetric(.activeEnergy)
        fixture.model.addMetric(.activeEnergy)
        await fixture.model.loadBaseline(for: .activeEnergy)
        #expect(fixture.health.events == (needsRequest ? [
            "status.activeEnergy",
            "request.activeEnergy",
            "query.activeEnergy",
        ] :
            ["status.activeEnergy", "query.activeEnergy"]))
        #expect(fixture.model.draftGoals[.steps] == walkingDraft)
        #expect(fixture.model.selectedMetrics == [.steps, .activeEnergy])
        #expect(fixture.model.canAcceptGoals)
        fixture.model.acceptGoal()
        #expect(fixture.model.activeGoals.map(\.metric) == [.steps, .activeEnergy])
    }

    @Test func completedRequestWithNoDataDoesNotDiagnoseReadPermission() async throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        await fixture.beginWalking()
        fixture.health.needsRequest[.activeEnergy] = true
        fixture.health.totals[.activeEnergy] = [nil, nil, nil, nil]
        let walkingDraft = fixture.model.draftGoals[.steps]
        fixture.model.addMetric(.activeEnergy)
        await fixture.model.loadBaseline(for: .activeEnergy)
        #expect(fixture.model.baselineState(for: .activeEnergy) == .insufficient)
        #expect(fixture.model.selectedMetrics.contains(.activeEnergy))
        #expect(!fixture.model.canAcceptGoals)
        fixture.model.acceptGoal()
        #expect(fixture.model.stage == .startingPoint)
        await fixture.model.loadBaseline(for: .activeEnergy, retry: true)
        #expect(fixture.health.requests.count == 2)
        #expect(fixture.model.draftGoals[.steps] == walkingDraft)
        fixture.model.removeMetric(.activeEnergy)
        #expect(fixture.model.canAcceptGoals)
        fixture.model.acceptGoal()
        #expect(fixture.model.activeGoals == [walkingDraft].compactMap { $0 })
    }

    @Test func bothInsufficientCannotAcceptAndRemovingEitherIsExplicit() async throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        fixture.health.totals = [:]
        fixture.model.select(.activity)
        fixture.model.select(.walking)
        fixture.model.continueToHealth()
        await fixture.model.connectHealth()
        await fixture.model.loadBaseline()
        #expect(fixture.model.proposalMetrics == [.steps, .activeEnergy])
        #expect(!fixture.model.canAcceptGoals)
        fixture.model.removeMetric(.steps)
        #expect(fixture.model.proposalMetrics == [.activeEnergy])
        #expect(!fixture.model.canAcceptGoals)
        fixture.model.removeMetric(.activeEnergy)
        #expect(fixture.model.proposalMetrics.isEmpty)
        #expect(!fixture.model.canAcceptGoals)
        fixture.model.addMetric(.steps)
        #expect(fixture.model.proposalMetrics == [.steps])
    }

    @Test(arguments: [SelectionFailure.status, .request, .unavailable])
    func justInTimeTechnicalFailureCanRetryWithoutLosingOtherDraft(_ failure: SelectionFailure) async throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        await fixture.beginWalking()
        let walking = fixture.model.draftGoals[.steps]
        fixture.health.needsRequest[.activeEnergy] = true
        fixture.health.failure = failure
        fixture.model.addMetric(.activeEnergy)
        await fixture.model.loadBaseline(for: .activeEnergy)
        #expect(fixture.model.baselineState(for: .activeEnergy) == .failed)
        #expect(fixture.health.queries == [.steps])
        #expect(fixture.model.draftGoals[.steps] == walking)
        fixture.health.failure = nil
        await fixture.model.loadBaseline(for: .activeEnergy, retry: true)
        #expect(fixture.model.canAcceptGoals)
        #expect(fixture.model.draftGoals[.steps] == walking)
    }

    @Test func restoredDualProposalRequeriesWithoutPersistedHealthOrRequestResult() async throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        fixture.model.select(.walking)
        fixture.model.select(.activity)
        fixture.model.continueToHealth()
        await fixture.model.connectHealth()
        let restored = fixture.restore()
        #expect(restored.proposalMetrics == [.steps, .activeEnergy])
        await restored.loadBaseline()
        #expect(restored.canAcceptGoals)
        #expect(fixture.health.requests.count == 1)
        #expect(fixture.health.statusChecks == [[.steps], [.activeEnergy]])
        let saved = try #require(fixture.defaults.dictionary(forKey: "onboarding.progress"))
        #expect(Set(saved.keys) == ["selectedMetrics", "stage"])
        #expect(saved["selectedMetrics"] as? [String] == ["steps", "activeEnergy"])
    }

    @Test func emptyHomeReselectionUsesJustInTimeBeforeQueries() async throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        fixture.defaults.set(["stage": "completed", "goals": []], forKey: "onboarding.progress")
        let model = fixture.restore()
        fixture.health.needsRequest[.activeEnergy] = true
        model.chooseGoal()
        model.select(.activity)
        model.continueToHealth()
        #expect(model.stage == .startingPoint)
        await model.loadBaseline()
        #expect(fixture.health.events == ["status.activeEnergy", "request.activeEnergy", "query.activeEnergy"])
        model.acceptGoal()
        #expect(model.activeGoals.map(\.metric) == [.activeEnergy])
    }

    @Test func removedMetricDuringStatusCheckCannotPresentRequestOrPublishLateData() async throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        await fixture.beginWalking()
        fixture.health.needsRequest[.activeEnergy] = true
        fixture.health.suspendedStatus = .activeEnergy
        fixture.model.addMetric(.activeEnergy)
        let task = Task { await fixture.model.loadBaseline(for: .activeEnergy) }
        while fixture.health.statusContinuation == nil {
            await Task.yield()
        }
        fixture.model.removeMetric(.activeEnergy)
        fixture.health.statusContinuation?.resume()
        await task.value
        #expect(fixture.health.requests == [[.steps]])
        #expect(fixture.health.queries == [.steps])
        #expect(fixture.model.baselineStates[.activeEnergy] == nil)
        #expect(fixture.model.canAcceptGoals)
    }

    @Test func concurrentCardsAndCancelledViewShareSerializedNativeRequests() async throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        fixture.defaults.set(
            ["stage": "startingPoint", "selectedMetrics": ["steps", "activeEnergy"]],
            forKey: "onboarding.progress"
        )
        let model = fixture.restore()
        fixture.health.needsRequest = [.steps: true, .activeEnergy: true]
        fixture.health.suspendedRequest = .steps
        let first = Task { await model.loadBaseline(for: .steps) }
        while fixture.health.requestContinuation == nil {
            await Task.yield()
        }
        let duplicate = Task { await model.loadBaseline(for: .steps) }
        let second = Task { await model.loadBaseline(for: .activeEnergy) }
        first.cancel()
        await Task.yield()
        #expect(fixture.health.requests == [[.steps]])
        fixture.health.requestContinuation?.resume()
        await first.value
        await duplicate.value
        await second.value
        #expect(fixture.health.requests == [[.steps], [.activeEnergy]])
        #expect(fixture.health.maximumConcurrentRequests == 1)
        #expect(Set(fixture.health.queries) == [.steps, .activeEnergy])
        #expect(model.canAcceptGoals)
    }

    @Test func removalAndReadditionDuringNativeRequestKeepsNewestSelection() async throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        await fixture.beginWalking()
        fixture.health.needsRequest[.activeEnergy] = true
        fixture.health.suspendedRequest = .activeEnergy
        fixture.model.addMetric(.activeEnergy)
        let first = Task { await fixture.model.loadBaseline(for: .activeEnergy) }
        while fixture.health.requestContinuation == nil {
            await Task.yield()
        }
        fixture.model.removeMetric(.activeEnergy)
        fixture.model.addMetric(.activeEnergy)
        let second = Task { await fixture.model.loadBaseline(for: .activeEnergy) }
        fixture.health.suspendedRequest = nil
        fixture.health.needsRequest[.activeEnergy] = false
        fixture.health.requestContinuation?.resume()
        await first.value
        await second.value
        #expect(fixture.health.requests == [[.steps], [.activeEnergy]])
        #expect(fixture.health.queries == [.steps, .activeEnergy])
        #expect(fixture.model.canAcceptGoals)
    }

    @Test func cancellingEmptyHomeReselectionDiscardsPendingRequestResponse() async throws {
        let fixture = try SelectionFixture()
        defer { fixture.clear() }
        fixture.defaults.set(["stage": "completed", "goals": []], forKey: "onboarding.progress")
        let model = fixture.restore()
        fixture.health.needsRequest[.activeEnergy] = true
        fixture.health.suspendedRequest = .activeEnergy
        model.chooseGoal()
        model.select(.activity)
        model.continueToHealth()
        let task = Task { await model.loadBaseline() }
        while fixture.health.requestContinuation == nil {
            await Task.yield()
        }
        model.cancelChoosingGoal()
        fixture.health.requestContinuation?.resume()
        await task.value
        #expect(model.stage == .completed)
        #expect(model.activeGoals.isEmpty)
        #expect(model.draftGoals.isEmpty)
        #expect(model.baselineStates == [.activeEnergy: .loading])
        #expect(fixture.health.queries.isEmpty)
    }

    @Test func newCopyIsLocalizedInBothLanguages() throws {
        for language in ["en", "es"] {
            let path = try #require(Bundle.main.path(forResource: language, ofType: "lproj"))
            let bundle = try #require(Bundle(path: path))
            for key in [
                "health.stepsExplanation",
                "health.activityExplanation",
                "goal.removeSteps",
                "goal.removeActivity",
            ] {
                #expect(bundle.localizedString(forKey: key, value: nil, table: nil) != key)
            }
        }
    }
}

@MainActor private struct SelectionFixture {
    let suite = "HealthGoalsSelectionTests.\(UUID().uuidString)"
    let defaults: UserDefaults
    let health = SelectionHealth()
    let model: OnboardingModel

    init() throws {
        defaults = try #require(UserDefaults(suiteName: suite))
        model = OnboardingModel(healthAuthorization: health, healthReading: health, defaults: defaults)
    }

    func restore() -> OnboardingModel {
        OnboardingModel(healthAuthorization: health, healthReading: health, defaults: defaults)
    }

    func clear() {
        defaults.removePersistentDomain(forName: suite)
    }

    func beginWalking() async {
        model.select(.walking)
        model.continueToHealth()
        await model.connectHealth()
        await model.loadBaseline()
    }
}

enum SelectionFailure: Error { case status, request, unavailable }

@MainActor private final class SelectionHealth: HealthAuthorizing, HealthReading {
    var isAvailable: Bool {
        failure != .unavailable
    }

    var failure: SelectionFailure?
    var needsRequest: [ActivityMetric: Bool] = [:]
    var requests: [Set<ActivityMetric>] = []
    var statusChecks: [Set<ActivityMetric>] = []
    var queries: [ActivityMetric] = []
    var events: [String] = []
    var totals: [ActivityMetric: [Double?]] = [
        .steps: Array(repeating: Constants.steps, count: Constants.blocks),
        .activeEnergy: Array(repeating: Constants.energy, count: Constants.blocks),
    ]
    var suspendedStatus: ActivityMetric?
    var statusContinuation: CheckedContinuation<Void, Never>?
    var suspendedRequest: ActivityMetric?
    var requestContinuation: CheckedContinuation<Void, Never>?
    var concurrentRequests = 0
    var maximumConcurrentRequests = 0

    func needsAuthorizationRequest(for metrics: Set<ActivityMetric>) async throws -> Bool {
        statusChecks.append(metrics)
        for metric in ActivityMetric.allCases
            where metrics.contains(metric)
        {
            events.append("status.\(metric.rawValue)")
        }
        if metrics.contains(suspendedStatus ?? .steps), suspendedStatus != nil {
            await withCheckedContinuation { statusContinuation = $0 }
        }
        if failure == .status { throw SelectionFailure.status }
        return metrics.contains { needsRequest[$0] == true }
    }

    func requestReadAuthorization(for metrics: Set<ActivityMetric>) async throws {
        requests.append(metrics)
        for metric in ActivityMetric.allCases
            where metrics.contains(metric)
        {
            events.append("request.\(metric.rawValue)")
        }
        concurrentRequests += 1
        maximumConcurrentRequests = max(maximumConcurrentRequests, concurrentRequests)
        defer { concurrentRequests -= 1 }
        if let suspendedRequest, metrics.contains(suspendedRequest) {
            await withCheckedContinuation { requestContinuation = $0 }
        }
        if failure == .request { throw SelectionFailure.request }
    }

    func weeklyTotals(for metric: ActivityMetric, in _: BaselineWindow) async throws -> [Double?] {
        queries.append(metric)
        events.append("query.\(metric.rawValue)")
        return totals[metric] ?? []
    }
}

private extension SelectionHealth {
    enum Constants {
        static let steps = 1000.0
        static let energy = 100.0
        static let blocks = 4
    }
}
