import HealthKit

@MainActor
protocol HealthAuthorizing {
    var isAvailable: Bool { get }
    /// Completes the request without exposing read authorization status.
    func requestReadAuthorization() async throws
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
final class HealthAuthorization: HealthAuthorizing, HealthReading, HealthProgressReading {
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private var store: HKHealthStore?

    func requestReadAuthorization() async throws {
        guard isAvailable else { throw HKError(.errorHealthDataUnavailable) }
        let store = try availableStore()
        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount), HKQuantityType(.activeEnergyBurned),
        ]
        // The async API throws if the request does not finish. It exposes no read permission status.
        try await store.requestAuthorization(toShare: [], read: readTypes)
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
        let store = try availableStore()
        guard let first = window.intervals.first, let last = window.intervals.last else {
            throw Failure.invalidIntervals
        }
        let predicate = HKQuery.predicateForSamples(withStart: first.start, end: last.end)
        let query = HKStatisticsCollectionQueryDescriptor(
            predicate: .quantitySample(type: metric.quantityType, predicate: predicate),
            options: .cumulativeSum,
            anchorDate: first.start,
            intervalComponents: DateComponents(
                calendar: window.calendar,
                timeZone: window.calendar.timeZone,
                day: Constants.daysPerBlock
            )
        )
        let collection = try await query.result(for: store)
        return try window.intervals.map { interval in
            guard let statistics = collection.statistics(for: interval.start) else { return nil }
            // Do not silently accept an interval shifted by a calendar or time-zone mismatch.
            guard statistics.startDate == interval.start, statistics.endDate == interval.end else {
                throw Failure.invalidIntervals
            }
            // Missing quantity is unknown; a present quantity may explicitly contain zero.
            return metric.value(from: statistics.sumQuantity())
        }
    }
}

private extension HealthAuthorization {
    enum Constants {
        static let daysPerBlock = 7
    }

    enum Failure: Error { case invalidIntervals }

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
