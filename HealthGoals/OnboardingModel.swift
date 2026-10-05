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

enum ActivityMetric: String, CaseIterable, Identifiable {
    case steps, activeEnergy
    var id: Self {
        self
    }
}

enum OnboardingStage: String { case intention, connectHealth, startingPoint, completed }
enum AuthorizationRequestState: Equatable { case idle, requesting, unavailable, failed }

@MainActor
@Observable
final class OnboardingModel {
    private(set) var selectedMetrics: Set<ActivityMetric> = []
    private(set) var stage: OnboardingStage = .intention
    private(set) var requestState: AuthorizationRequestState = .idle
    private(set) var baselineStates: [ActivityMetric: BaselineState] = [:]
    private(set) var draftGoals: [ActivityMetric: WeeklyGoal] = [:]
    private(set) var activeGoals: [WeeklyGoal] = []
    private(set) var progressStates: [ActivityMetric: WeeklyProgressState] = [:]
    private(set) var hasCompletedOnboarding = false
    private(set) var activeWeek: ActiveWeek?
    private let progressReading: (any HealthProgressReading)?
    private let patternReading: (any HealthPatternReading)?
    private var progressTasks: [ActivityMetric: Task<Void, Never>] = [:]
    private var progressTokens: [ActivityMetric: UUID] = [:]
    private var patterns: [ActivityMetric: HistoricalPattern] = [:]
    private var patternWindows: [ActivityMetric: PatternWindow] = [:]
    private var authorizationTask: Task<Void, Error>?
    private var preparedMetrics: Set<ActivityMetric> = []
    private let healthAuthorization: any HealthAuthorizing
    private let healthReading: any HealthReading
    private let now: () -> Date
    private let calendar: () -> Calendar
    private var baselineTasks: [ActivityMetric: Task<Void, Never>] = [:]
    private var baselineTokens: [ActivityMetric: UUID] = [:]
    private var loadedBaselines: Set<ActivityMetric> = []
    private let defaults: UserDefaults
    private static let progressKey = "onboarding.progress"

    var canContinue: Bool {
        !selectedMetrics.isEmpty
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
        if let records = progress?["selectedMetrics"] as? [String] {
            selectedMetrics = Set(records.compactMap(ActivityMetric.init(rawValue:)))
        } else if let legacy = (progress?["intention"] as? String).flatMap(ActivityIntention.init(rawValue:)) {
            selectedMetrics = [legacy.metric]
        }
        restore(progress)
        if progress?["selectedMetrics"] == nil, !selectedMetrics.isEmpty { saveProgress() }
    }

    var baselineState: BaselineState {
        proposalMetrics.first.map { baselineState(for: $0) } ?? .loading
    }

    var draftGoal: WeeklyGoal? {
        proposalMetrics.first.flatMap { draftGoals[$0] }
    }

    var activeGoal: WeeklyGoal? {
        activeGoals.first
    }

    var progressState: WeeklyProgressState {
        activeGoal.map { progressState(for: $0.metric) } ?? .loading
    }

    var proposalMetrics: [ActivityMetric] {
        ActivityMetric.allCases.filter { selectedMetrics.contains($0) }
    }

    var canAcceptGoals: Bool {
        stage == .startingPoint && !proposalMetrics.isEmpty && proposalMetrics.allSatisfy {
            if case .available = baselineState(for: $0) { return draftGoals[$0] != nil }
            return false
        }
    }

    func baselineState(for metric: ActivityMetric) -> BaselineState {
        baselineStates[metric] ?? .loading
    }

    func progressState(for metric: ActivityMetric) -> WeeklyProgressState {
        progressStates[metric] ?? .loading
    }

    func select(_ intention: ActivityIntention) {
        guard stage == .intention else { return }
        if !selectedMetrics.insert(intention.metric).inserted { selectedMetrics.remove(intention.metric) }
        saveProgress()
    }

    func continueToHealth() {
        guard stage == .intention, canContinue else { return }
        stage = hasCompletedOnboarding ? .startingPoint : .connectHealth
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
            try await healthAuthorization.requestReadAuthorization(for: selectedMetrics)
            preparedMetrics.formUnion(selectedMetrics)
            // Only the request finished. Read access and available data remain unknown.
            stage = .startingPoint
            requestState = .idle
            saveProgress()
        } catch {
            requestState = .failed
        }
    }

    func addMetric(_ metric: ActivityMetric) {
        guard stage == .startingPoint, !selectedMetrics.contains(metric) else { return }
        selectedMetrics.insert(metric)
        saveProgress()
    }

    func removeMetric(_ metric: ActivityMetric) {
        guard stage == .startingPoint else { return }
        selectedMetrics.remove(metric)
        preparedMetrics.remove(metric)
        baselineTokens[metric] = nil
        baselineTasks[metric] = nil
        baselineStates[metric] = nil
        draftGoals[metric] = nil
        loadedBaselines.remove(metric)
        saveProgress()
    }

    @discardableResult
    func adjustDraft(to text: String, metric: ActivityMetric? = nil) -> Bool {
        guard stage == .startingPoint, let metric = metric ?? proposalMetrics.first,
              draftGoals[metric] != nil, let goal = parsedGoal(text, metric: metric)
        else { return false }
        draftGoals[metric] = goal
        return true
    }

    func acceptGoal() {
        guard canAcceptGoals else { return }
        activeGoals = proposalMetrics.compactMap { draftGoals[$0] }
        stage = .completed
        hasCompletedOnboarding = true
        saveProgress()
    }

    @discardableResult
    func editGoal(metric: ActivityMetric, to text: String) -> Bool {
        guard stage == .completed, let index = activeGoals.firstIndex(where: { $0.metric == metric }),
              let goal = parsedGoal(text, metric: metric)
        else { return false }
        activeGoals[index] = goal
        if case let .available(progress) = progressState(for: metric) {
            publishProgress(goal: goal, value: progress.value, week: progress.week, queriedAt: progress.queriedAt)
        }
        saveProgress()
        return true
    }

    func deleteGoal(metric: ActivityMetric) {
        guard stage == .completed else { return }
        activeGoals.removeAll { $0.metric == metric }
        progressTokens[metric] = nil
        progressTasks[metric] = nil
        progressStates[metric] = nil
        patterns[metric] = nil
        patternWindows[metric] = nil
        saveProgress()
    }

    func chooseGoal() {
        guard stage == .completed, activeGoals.isEmpty else { return }
        stage = .intention
        selectedMetrics = []
        baselineStates = [:]
        draftGoals = [:]
        loadedBaselines = []
        baselineTokens = [:]
        baselineTasks = [:]
        saveProgress()
    }

    func cancelChoosingGoal() {
        guard hasCompletedOnboarding, stage != .completed else { return }
        baselineTokens = [:]
        baselineTasks = [:]
        stage = .completed
        saveProgress()
    }

    func loadProgress() async {
        guard stage == .completed, !Task.isCancelled else { return }
        // Independent finite tasks let a slow/erroring metric coexist with the other card.
        for goal in activeGoals {
            startProgress(for: goal.metric)
        }
        let tasks = Array(progressTasks.values)
        for task in tasks {
            await task.value
        }
    }

    func loadProgress(for metric: ActivityMetric) async {
        guard stage == .completed, activeGoals.contains(where: { $0.metric == metric }),
              !Task.isCancelled else { return }
        startProgress(for: metric)
        await progressTasks[metric]?.value
    }

    func isRefreshing(_ metric: ActivityMetric) -> Bool {
        progressTasks[metric] != nil
    }

    func loadBaseline(retry: Bool = false) async {
        for metric in proposalMetrics {
            await loadBaseline(for: metric, retry: retry)
        }
    }

    func loadBaseline(for metric: ActivityMetric, retry: Bool = false) async {
        guard stage == .startingPoint, proposalMetrics.contains(metric), !Task.isCancelled else { return }
        if let task = baselineTasks[metric] { await task.value; return }
        guard retry || !loadedBaselines.contains(metric) else { return }
        baselineStates[metric] = .loading
        draftGoals[metric] = nil
        let token = UUID()
        baselineTokens[metric] = token
        let task = Task { await fetchBaseline(for: metric, token: token) }
        baselineTasks[metric] = task
        await task.value
        if baselineTokens[metric] == token { baselineTasks[metric] = nil }
    }
}

private extension OnboardingModel {
    func fetchBaseline(for metric: ActivityMetric, token: UUID) async {
        do {
            try await prepareAuthorization(for: metric, token: token)
            guard isCurrentBaseline(metric, token: token) else { return }
            let window = try BaselineWindow(now: now(), calendar: calendar())
            let totals = try await healthReading.weeklyTotals(for: metric, in: window)
            guard isCurrentBaseline(metric, token: token) else { return }
            if let baseline = BaselineCalculator.calculate(metric: metric, weeklyTotals: totals) {
                baselineStates[metric] = .available(baseline)
                draftGoals[metric] = GoalEngine.propose(from: baseline)
            } else {
                baselineStates[metric] = .insufficient
            }
        } catch {
            guard isCurrentBaseline(metric, token: token) else { return }
            baselineStates[metric] = .failed
        }
        loadedBaselines.insert(metric)
    }

    func isCurrentBaseline(_ metric: ActivityMetric, token: UUID) -> Bool {
        stage == .startingPoint && baselineTokens[metric] == token && selectedMetrics.contains(metric)
    }

    func prepareAuthorization(for metric: ActivityMetric, token: UUID) async throws {
        // Serialize native requests across independently loading cards, including removed/readded metrics.
        while let task = authorizationTask {
            try? await task.value
            guard isCurrentBaseline(metric, token: token) else { return }
        }
        guard !preparedMetrics.contains(metric), isCurrentBaseline(metric, token: token) else { return }
        let task = Task {
            defer { authorizationTask = nil }
            guard healthAuthorization.isAvailable else { throw AuthorizationFailure.unavailable }
            let needsRequest = try await healthAuthorization.needsAuthorizationRequest(for: [metric])
            guard isCurrentBaseline(metric, token: token) else { return }
            if needsRequest {
                try await healthAuthorization.requestReadAuthorization(for: [metric])
            }
            // Request presentation/completion conveys nothing about read access or data availability.
            if isCurrentBaseline(metric, token: token) { preparedMetrics.insert(metric) }
        }
        authorizationTask = task
        try await task.value
    }

    enum AuthorizationFailure: Error { case unavailable }

    func startProgress(for metric: ActivityMetric) {
        guard progressTasks[metric] == nil else { return }
        let currentWeek = try? ActiveWeek(now: now(), calendar: calendar())
        // Keep a valid current-week observation during refresh so active editing preserves it immediately.
        if case let .available(progress) = progressState(for: metric),
           progress.week.interval == currentWeek?.interval, progress.week.timeZone == currentWeek?.timeZone
        {
            // The card still identifies the original query time while the new query is in flight.
        } else {
            progressStates[metric] = .loading
            patterns[metric] = nil
            patternWindows[metric] = nil
        }
        let token = UUID()
        progressTokens[metric] = token
        progressTasks[metric] = Task {
            await fetchProgress(for: metric, token: token)
            if progressTokens[metric] == token { progressTasks[metric] = nil }
        }
    }

    func fetchProgress(for metric: ActivityMetric, token: UUID) async {
        do {
            guard let progressReading else { throw ProgressFailure.readerUnavailable }
            while progressTokens[metric] == token {
                let queryCalendar = calendar()
                let queriedAt = now()
                let week = try ActiveWeek(now: queriedAt, calendar: queryCalendar)
                let window = try PatternWindow(now: queriedAt, calendar: queryCalendar)
                activeWeek = week
                let value = try await progressReading.progress(for: metric, in: week)
                guard progressTokens[metric] == token else { return }
                if try !isCurrent(week: week, window: window) { continue }
                guard let value, value.isFinite, value >= 0 else {
                    progressStates[metric] = .insufficient
                    return
                }
                guard let goal = activeGoals.first(where: { $0.metric == metric }) else { return }
                let finishedAt = now()
                // Use the current goal after every await; editing must not restore an older value.
                publishProgress(goal: goal, value: value, week: week, queriedAt: finishedAt)
                let pattern = await fetchPattern(for: metric, in: window)
                guard progressTokens[metric] == token else { return }
                if try !isCurrent(week: week, window: window) {
                    progressStates[metric] = .loading
                    continue
                }
                patterns[metric] = pattern
                patternWindows[metric] = window
                guard let currentGoal = activeGoals.first(where: { $0.metric == metric }) else { return }
                publishProgress(goal: currentGoal, value: value, week: week, queriedAt: finishedAt)
                activeWeek = try ActiveWeek(now: now(), calendar: calendar())
                return
            }
        } catch {
            guard progressTokens[metric] == token else { return }
            progressStates[metric] = .failed
        }
    }

    func publishProgress(goal: WeeklyGoal, value: Double, week: ActiveWeek, queriedAt: Date) {
        let progress = WeeklyProgress(goal: goal, value: value, week: week, queriedAt: queriedAt)
        let window = patternWindows[goal.metric]
        let currentCalendar = calendar()
        let today = currentCalendar.startOfDay(for: now())
        let pattern = window?.today == today && window?.calendar == currentCalendar ? patterns[goal.metric] : nil
        let pace = PaceCalculator.state(for: progress, pattern: pattern, day: today, calendar: currentCalendar)
        progressStates[goal.metric] = .available(WeeklyProgress(
            goal: goal, value: value, week: week, queriedAt: queriedAt, pace: pace
        ))
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

    func parsedGoal(_ text: String, metric: ActivityMetric) -> WeeklyGoal? {
        guard let value = Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) else { return nil }
        return WeeklyGoal(metric: metric, value: value)
    }

    func restore(_ progress: [String: Any]?) {
        guard let progress, let rawStage = progress["stage"] as? String,
              let savedStage = OnboardingStage(rawValue: rawStage)
        else { return }
        hasCompletedOnboarding = progress["hasCompletedOnboarding"] as? Bool ?? false
        if let records = progress["goals"] as? [[String: Any]] {
            for record in records {
                guard let rawMetric = record["metric"] as? String, let metric = ActivityMetric(rawValue: rawMetric),
                      let value = record["value"] as? Int, let goal = WeeklyGoal(metric: metric, value: value),
                      !activeGoals.contains(where: { $0.metric == metric })
                else { continue }
                activeGoals.append(goal)
            }
            activeGoals = ActivityMetric.allCases.compactMap { metric in activeGoals.first { $0.metric == metric } }
            if savedStage == .completed {
                stage = .completed
                hasCompletedOnboarding = true
                return
            }
        } else if savedStage == .completed,
                  let rawMetric = progress["goalMetric"] as? String,
                  let metric = ActivityMetric(rawValue: rawMetric), selectedMetrics.contains(metric),
                  let value = progress["goalValue"] as? Int, let goal = WeeklyGoal(metric: metric, value: value)
        {
            activeGoals = [goal]
            stage = .completed
            hasCompletedOnboarding = true
            saveProgress()
            return
        }
        guard !selectedMetrics.isEmpty || hasCompletedOnboarding else { return }
        stage = savedStage == .completed ? .startingPoint : savedStage
        if selectedMetrics.isEmpty { stage = .intention }
    }

    func saveProgress() {
        var progress: [String: Any] = ["stage": stage.rawValue]
        progress["selectedMetrics"] = proposalMetrics.map(\.rawValue)
        if hasCompletedOnboarding {
            progress["hasCompletedOnboarding"] = true
            progress["goals"] = activeGoals.map { ["metric": $0.metric.rawValue, "value": $0.value] }
        }
        defaults.set(progress, forKey: Self.progressKey)
    }
}
