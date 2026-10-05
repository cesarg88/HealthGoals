import Foundation
@testable import HealthGoals
import Testing

@Suite @MainActor
struct OnboardingTests {
    @Test func initialStateCannotContinue() throws {
        let (model, _, _) = try setup()
        #expect(model.selectedMetrics.isEmpty)
        #expect(model.stage == .intention)
        #expect(!model.canContinue)
        model.continueToHealth()
        #expect(model.stage == .intention)
    }

    @Test func selectionsAreIndependentOfCopyAndEachOther() throws {
        let (model, _, _) = try setup()
        model.select(.walking)
        #expect(model.canContinue)
        #expect(model.selectedMetrics == [.steps])
        model.select(.activity)
        #expect(model.selectedMetrics == [.steps, .activeEnergy])
        model.select(.walking)
        #expect(model.selectedMetrics == [.activeEnergy])
        model.select(.activity)
        #expect(!model.canContinue)
    }

    @Test func continueAndBackPreserveSelection() throws {
        let (model, _, _) = try setup()
        model.select(.walking)
        model.continueToHealth()
        #expect(model.stage == .connectHealth)
        model.backToIntention()
        #expect(model.stage == .intention)
        #expect(model.selectedMetrics == [.steps])
        #expect(model.canContinue)
    }

    @Test func technicalErrorIsRecoverable() async throws {
        let (model, service, _) = try setup()
        model.select(.activity)
        model.continueToHealth()
        service.shouldFail = true
        await model.connectHealth()
        #expect(model.stage == .connectHealth)
        #expect(model.requestState == .failed)
        #expect(model.selectedMetrics == [.activeEnergy])
        service.shouldFail = false
        await model.connectHealth()
        #expect(model.stage == .startingPoint)
        #expect(service.requests == 2)
    }

    @Test func unavailableCanRetryWithoutLosingIntention() async throws {
        let (model, service, _) = try setup()
        model.select(.walking)
        model.continueToHealth()
        service.isAvailable = false
        await model.connectHealth()
        #expect(model.requestState == .unavailable)
        #expect(model.stage == .connectHealth)
        #expect(model.selectedMetrics == [.steps])
        #expect(service.requests == 0)
        service.isAvailable = true
        await model.connectHealth()
        #expect(model.stage == .startingPoint)
    }

    @Test func completedRequestAdvancesWithoutAnyReadPermissionResult() async throws {
        let (model, service, _) = try setup()
        model.select(.activity)
        model.continueToHealth()
        // The service returns neither granted/denied nor data. Both remain unknown.
        await model.connectHealth()
        #expect(model.stage == .startingPoint)
        #expect(model.requestState == .idle)
        #expect(service.requests == 1)
    }

    @Test func connectionCannotSkipIntentionScreen() async throws {
        let (model, service, _) = try setup()
        await model.connectHealth()
        #expect(model.stage == .intention)
        #expect(service.requests == 0)
    }

    @Test func restorationBeforeAndAfterBack() throws {
        let (model, service, defaults) = try setup()
        model.select(.walking)
        #expect(OnboardingModel(healthAuthorization: service, healthReading: FakeHealthReader(), defaults: defaults)
            .selectedMetrics == [.steps])
        model.continueToHealth()
        #expect(OnboardingModel(healthAuthorization: service, healthReading: FakeHealthReader(), defaults: defaults)
            .stage == .connectHealth)
        model.backToIntention()
        let restored = OnboardingModel(
            healthAuthorization: service,
            healthReading: FakeHealthReader(),
            defaults: defaults
        )
        #expect(restored.stage == .intention)
        #expect(restored.selectedMetrics == [.steps])
    }

    @Test func restorationOfCompletedRequestIsOnlyAStage() async throws {
        let (model, service, defaults) = try setup()
        model.select(.activity)
        model.continueToHealth()
        await model.connectHealth()
        let restored = OnboardingModel(
            healthAuthorization: service,
            healthReading: FakeHealthReader(),
            defaults: defaults
        )
        #expect(restored.stage == .startingPoint)
        #expect(restored.selectedMetrics == [.activeEnergy])
        #expect(restored.requestState == .idle)
        #expect(defaults.dictionary(forKey: "onboarding.progress")?.count == 2)
    }

    @Test func malformedProgressCannotSkipIntention() throws {
        let (_, service, defaults) = try setup()
        defaults.set(["stage": "startingPoint", "intention": "unknown"], forKey: "onboarding.progress")
        let restored = OnboardingModel(
            healthAuthorization: service,
            healthReading: FakeHealthReader(),
            defaults: defaults
        )
        #expect(restored.stage == .intention)
        #expect(restored.selectedMetrics.isEmpty)
    }

    @Test func interruptedRequestRestoresS02AndCannotDuplicate() async throws {
        let (model, service, defaults) = try setup()
        model.select(.walking)
        model.continueToHealth()
        service.suspendRequest = true
        let task = Task { await model.connectHealth() }
        while service.continuation == nil {
            await Task.yield()
        }
        #expect(model.requestState == .requesting)
        await model.connectHealth()
        model.backToIntention()
        #expect(service.requests == 1)
        #expect(model.stage == .connectHealth)
        let restored = OnboardingModel(
            healthAuthorization: service,
            healthReading: FakeHealthReader(),
            defaults: defaults
        )
        #expect(restored.stage == .connectHealth)
        #expect(restored.requestState == .idle)
        #expect(restored.selectedMetrics == [.steps])
        service.continuation?.resume()
        await task.value
        #expect(model.stage == .startingPoint)
    }
}

private extension OnboardingTests {
    func setup() throws -> (OnboardingModel, FakeHealthAuthorization, UserDefaults) {
        let defaults = try #require(UserDefaults(suiteName: "HealthGoalsTests.\(UUID().uuidString)"))
        let service = FakeHealthAuthorization()
        return (
            OnboardingModel(healthAuthorization: service, healthReading: FakeHealthReader(), defaults: defaults),
            service,
            defaults
        )
    }
}

@MainActor
private final class FakeHealthAuthorization: HealthAuthorizing {
    var isAvailable = true
    var shouldFail = false
    var requests = 0
    var suspendRequest = false
    var continuation: CheckedContinuation<Void, Never>?
    enum Failure: Error { case technical }

    func needsAuthorizationRequest(for _: Set<ActivityMetric>) async throws -> Bool {
        false
    }

    func requestReadAuthorization(for _: Set<ActivityMetric>) async throws {
        requests += 1
        if suspendRequest {
            await withCheckedContinuation { continuation = $0 }
        }
        if shouldFail { throw Failure.technical }
    }
}
