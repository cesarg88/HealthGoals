import Foundation
import Observation

enum ActivityIntention: String, CaseIterable, Identifiable {
    case walking
    case activity

    var id: Self {
        self
    }

    var metric: ActivityMetric {
        self == .walking ? .steps : .activeEnergy
    }
}

enum ActivityMetric: Equatable { case steps, activeEnergy }
enum OnboardingStage: String { case intention, connectHealth, startingPoint }
enum AuthorizationRequestState: Equatable { case idle, requesting, unavailable, failed }

@MainActor
@Observable
final class OnboardingModel {
    private(set) var intention: ActivityIntention?
    private(set) var stage: OnboardingStage = .intention
    private(set) var requestState: AuthorizationRequestState = .idle
    private(set) var baselineState: BaselineState = .loading
    private let healthAuthorization: any HealthAuthorizing
    private let healthReading: any HealthReading
    private let now: () -> Date
    private let calendar: () -> Calendar
    private var baselineTask: Task<Void, Never>?
    private var hasLoadedBaseline = false
    private let defaults: UserDefaults
    private static let progressKey = "onboarding.progress"

    var canContinue: Bool {
        intention != nil
    }

    init(
        healthAuthorization: any HealthAuthorizing,
        healthReading: any HealthReading,
        defaults: UserDefaults,
        now: @escaping () -> Date = Date.init,
        calendar: @escaping () -> Calendar = { .current }
    ) {
        self.healthReading = healthReading
        self.now = now
        self.calendar = calendar
        self.healthAuthorization = healthAuthorization
        self.defaults = defaults
        let progress = defaults.dictionary(forKey: Self.progressKey)
        intention = (progress?["intention"] as? String).flatMap(ActivityIntention.init(rawValue:))
        // A saved stage never skips S01 without a valid intention.
        if intention != nil, let rawStage = progress?["stage"] as? String,
           let savedStage = OnboardingStage(rawValue: rawStage)
        {
            stage = savedStage
        }
    }

    func select(_ intention: ActivityIntention) {
        guard stage == .intention else { return }
        self.intention = intention
        saveProgress()
    }

    func continueToHealth() {
        guard stage == .intention, canContinue else { return }
        stage = .connectHealth
        requestState = .idle
        saveProgress()
    }

    func backToIntention() {
        guard stage == .connectHealth, requestState != .requesting else { return }
        stage = .intention
        requestState = .idle
        saveProgress()
    }

    func connectHealth() async {
        guard stage == .connectHealth, requestState != .requesting else { return }
        guard healthAuthorization.isAvailable else {
            requestState = .unavailable
            return
        }
        requestState = .requesting
        do {
            try await healthAuthorization.requestReadAuthorization()
            // Only the request finished. Read access and available data remain unknown.
            stage = .startingPoint
            requestState = .idle
            saveProgress()
        } catch {
            requestState = .failed
        }
    }

    func loadBaseline(retry: Bool = false) async {
        guard stage == .startingPoint, let intention else { return }
        if let baselineTask {
            await baselineTask.value
            return
        }
        guard retry || !hasLoadedBaseline, !Task.isCancelled else { return }
        baselineState = .loading
        // The model owns this finite query; disappearing SwiftUI tasks must not strand S03 in loading.
        let task = Task { await fetchBaseline(for: intention.metric) }
        baselineTask = task
        await task.value
        baselineTask = nil
    }
}

private extension OnboardingModel {
    func fetchBaseline(for metric: ActivityMetric) async {
        do {
            let window = try BaselineWindow(now: now(), calendar: calendar())
            let totals = try await healthReading.weeklyTotals(for: metric, in: window)
            if let baseline = BaselineCalculator.calculate(metric: metric, weeklyTotals: totals) {
                baselineState = .available(baseline)
            } else {
                baselineState = .insufficient
            }
        } catch {
            baselineState = .failed
        }
        hasLoadedBaseline = true
    }

    func saveProgress() {
        guard let intention else { return }
        // Persist S02 before requesting authorization; never persist an in-flight operation.
        defaults.set(["intention": intention.rawValue, "stage": stage.rawValue], forKey: Self.progressKey)
    }
}
