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

enum ActivityMetric: String { case steps, activeEnergy }
enum OnboardingStage: String { case intention, connectHealth, startingPoint, completed }
enum AuthorizationRequestState: Equatable { case idle, requesting, unavailable, failed }

@MainActor
@Observable
final class OnboardingModel {
    private(set) var intention: ActivityIntention?
    private(set) var stage: OnboardingStage = .intention
    private(set) var requestState: AuthorizationRequestState = .idle
    private(set) var baselineState: BaselineState = .loading
    private(set) var draftGoal: WeeklyGoal?
    private(set) var activeGoal: WeeklyGoal?
    private(set) var progressState: WeeklyProgressState = .loading
    private(set) var activeWeek: ActiveWeek?
    private let progressReading: (any HealthProgressReading)?
    private let patternReading: (any HealthPatternReading)?
    private var progressTask: Task<Void, Never>?
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
        progressReading: (any HealthProgressReading)? = nil,
        patternReading: (any HealthPatternReading)? = nil,
        defaults: UserDefaults,
        now: @escaping () -> Date = Date.init,
        calendar: @escaping () -> Calendar = { .current }
    ) {
        self.progressReading = progressReading
        self.patternReading = patternReading
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
            if savedStage == .completed {
                if let rawMetric = progress?["goalMetric"] as? String,
                   let metric = ActivityMetric(rawValue: rawMetric), metric == intention?.metric,
                   let value = progress?["goalValue"] as? Int,
                   let goal = WeeklyGoal(metric: metric, value: value)
                {
                    activeGoal = goal
                    stage = .completed
                } else {
                    stage = .startingPoint
                }
            } else {
                stage = savedStage
            }
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

    @discardableResult
    func adjustDraft(to text: String) -> Bool {
        guard stage == .startingPoint, let draftGoal,
              let value = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)),
              let adjusted = WeeklyGoal(metric: draftGoal.metric, value: value)
        else { return false }
        self.draftGoal = adjusted
        return true
    }

    func acceptGoal() {
        guard stage == .startingPoint, case .available = baselineState, let draftGoal else { return }
        activeGoal = draftGoal
        stage = .completed
        saveProgress()
    }

    func loadProgress() async {
        guard stage == .completed, let activeGoal, !Task.isCancelled else { return }
        if let progressTask {
            await progressTask.value
            return
        }
        progressState = .loading
        let task = Task { await fetchProgress(for: activeGoal) }
        progressTask = task
        await task.value
        progressTask = nil
    }

    func loadBaseline(retry: Bool = false) async {
        guard stage == .startingPoint, let intention else { return }
        if let baselineTask {
            await baselineTask.value
            return
        }
        guard retry || !hasLoadedBaseline, !Task.isCancelled else { return }
        baselineState = .loading
        draftGoal = nil
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
                draftGoal = GoalEngine.propose(from: baseline)
            } else {
                baselineState = .insufficient
            }
        } catch {
            baselineState = .failed
        }
        hasLoadedBaseline = true
    }

    func fetchProgress(for goal: WeeklyGoal) async {
        do {
            guard let progressReading else { throw ProgressFailure.readerUnavailable }
            while true {
                let queryCalendar = calendar()
                let queriedAt = now()
                let week = try ActiveWeek(now: queriedAt, calendar: queryCalendar)
                let window = try PatternWindow(now: queriedAt, calendar: queryCalendar)
                activeWeek = week
                let value = try await progressReading.progress(for: goal.metric, in: week)
                if try !isCurrent(week: week, window: window) { continue }
                guard let value, value.isFinite, value >= 0 else {
                    progressState = .insufficient
                    return
                }
                let progress = WeeklyProgress(
                    goal: goal, value: value, week: week, queriedAt: now(),
                    pace: value >= Double(goal.value) ? .completed : .unknown
                )
                // Progress/gap is useful independently of historical pattern availability or errors.
                progressState = .available(progress)
                let pattern = await fetchPattern(for: goal.metric, in: window)
                if try !isCurrent(week: week, window: window) {
                    progressState = .loading
                    continue
                }
                let pace = PaceCalculator.state(
                    for: progress,
                    pattern: pattern,
                    day: window.today,
                    calendar: queryCalendar
                )
                progressState = .available(WeeklyProgress(
                    goal: goal, value: value, week: week, queriedAt: progress.queriedAt, pace: pace
                ))
                activeWeek = try ActiveWeek(now: now(), calendar: calendar())
                return
            }
        } catch {
            progressState = .failed
        }
    }

    func fetchPattern(for metric: ActivityMetric, in window: PatternWindow) async -> HistoricalPattern? {
        guard let patternReading else { return nil }
        do {
            let totals = try await patternReading.dailyTotals(for: metric, in: window)
            return PatternCalculator.calculate(metric: metric, dailyTotals: totals, in: window)
        } catch {
            return nil
        }
    }

    func isCurrent(week: ActiveWeek, window: PatternWindow) throws -> Bool {
        let currentCalendar = calendar()
        let currentDate = now()
        let currentWeek = try ActiveWeek(now: currentDate, calendar: currentCalendar)
        return week.interval == currentWeek.interval && window.calendar == currentCalendar
            && window.today == currentCalendar.startOfDay(for: currentDate)
    }

    enum ProgressFailure: Error { case readerUnavailable }

    func saveProgress() {
        guard let intention else { return }
        // Persist S02 before requesting authorization; never persist an in-flight operation.
        var progress: [String: Any] = ["intention": intention.rawValue, "stage": stage.rawValue]
        if let activeGoal {
            progress["goalMetric"] = activeGoal.metric.rawValue
            progress["goalValue"] = activeGoal.value
        }
        defaults.set(progress, forKey: Self.progressKey)
    }
}
