import HealthKit

@MainActor
protocol HealthAuthorizing {
    var isAvailable: Bool { get }
    /// Completes the request without exposing read authorization status.
    func requestReadAuthorization(for metrics: Set<ActivityMetric>) async throws
    /// Whether a request may need presentation; never reveals granted/denied read access.
    func needsAuthorizationRequest(for metrics: Set<ActivityMetric>) async throws -> Bool
}

@MainActor
protocol HealthReading {
    func weeklyTotals(for metric: ActivityMetric, in window: BaselineWindow) async throws -> [Double?]
}

@MainActor
protocol HealthProgressReading {
    func progress(for metric: ActivityMetric, in week: ActiveWeek) async throws -> Double?
}

@MainActor
protocol HealthPatternReading {
    func dailyTotals(for metric: ActivityMetric, in window: PatternWindow) async throws -> [Double?]
}

@MainActor
final class HealthAuthorization: HealthAuthorizing, HealthReading, HealthProgressReading, HealthPatternReading {
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private var store: HKHealthStore?

    func requestReadAuthorization(for metrics: Set<ActivityMetric>) async throws {
        guard isAvailable else { throw HKError(.errorHealthDataUnavailable) }
        let store = try availableStore()
        let readTypes = Set<HKObjectType>(metrics.map(\.quantityType))
        // The async API throws if the request does not finish. It exposes no read permission status.
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }

    func needsAuthorizationRequest(for metrics: Set<ActivityMetric>) async throws -> Bool {
        let store = try availableStore()
        let readTypes = Set<HKObjectType>(metrics.map(\.quantityType))
        switch try await store.statusForAuthorizationRequest(toShare: [], read: readTypes) {
            case .shouldRequest: return true
            case .unnecessary: return false
            case .unknown: throw Failure.requestStatusUnknown
            @unknown default: throw Failure.requestStatusUnknown
        }
    }

    func progress(for metric: ActivityMetric, in week: ActiveWeek) async throws -> Double? {
        let store = try availableStore()
        let predicate = HKQuery.predicateForSamples(withStart: week.interval.start, end: week.queryEnd)
        let query = HKStatisticsQueryDescriptor(
            predicate: .quantitySample(type: metric.quantityType, predicate: predicate),
            options: .cumulativeSum
        )
        let statistics = try await query.result(for: store)
        // Native aggregation preserves source merging; absence remains unknown rather than zero.
        return metric.value(from: statistics?.sumQuantity())
    }

    func weeklyTotals(for metric: ActivityMetric, in window: BaselineWindow) async throws -> [Double?] {
        try await quantities(
            for: metric,
            intervals: window.intervals,
            calendar: window.calendar,
            days: Constants.daysPerBlock
        )
    }

    func dailyTotals(for metric: ActivityMetric, in window: PatternWindow) async throws -> [Double?] {
        try await quantities(for: metric, intervals: window.intervals, calendar: window.calendar, days: 1)
    }
}

private extension HealthAuthorization {
    enum Constants {
        static let daysPerBlock = 7
    }

    enum Failure: Error { case invalidIntervals, requestStatusUnknown }

    func quantities(
        for metric: ActivityMetric,
        intervals: [DateInterval],
        calendar: Calendar,
        days: Int
    ) async throws -> [Double?] {
        let store = try availableStore()
        guard let first = intervals.first, let last = intervals.last else { throw Failure.invalidIntervals }
        let predicate = HKQuery.predicateForSamples(withStart: first.start, end: last.end)
        let query = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: metric.quantityType, predicate: predicate),
            options: .cumulativeSum,
            anchorDate: first.start,
            intervalComponents: DateComponents(calendar: calendar, timeZone: calendar.timeZone, day: days)
        )
        let collection = try await query.result(for: store)
        return try intervals.map { interval in
            guard let statistics = collection.statistics(for: interval.start) else { return nil }
            guard statistics.startDate == interval.start,
                  statistics.endDate == interval.end else { throw Failure.invalidIntervals }
            // No samples produces nil; a present sum quantity can explicitly contain zero.
            return metric.value(from: statistics.sumQuantity())
        }
    }

    func availableStore() throws -> HKHealthStore {
        guard isAvailable else { throw HKError(.errorHealthDataUnavailable) }
        let store = store ?? HKHealthStore()
        self.store = store
        return store
    }
}

extension ActivityMetric {
    var quantityType: HKQuantityType {
        HKQuantityType(self == .steps ? .stepCount : .activeEnergyBurned)
    }

    func value(from quantity: HKQuantity?) -> Double? {
        quantity?.doubleValue(for: self == .steps ? .count() : .kilocalorie())
    }
}
