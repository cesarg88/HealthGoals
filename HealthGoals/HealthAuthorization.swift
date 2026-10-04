import HealthKit

@MainActor
protocol HealthAuthorizing {
    var isAvailable: Bool { get }
    /// Completes the request without exposing read authorization status.
    func requestReadAuthorization() async throws
}

@MainActor
final class HealthAuthorization: HealthAuthorizing {
    var isAvailable: Bool {
        HKHealthStore.isHealthDataAvailable()
    }

    private var store: HKHealthStore?

    func requestReadAuthorization() async throws {
        guard isAvailable else { throw HKError(.errorHealthDataUnavailable) }
        let store = store ?? HKHealthStore()
        self.store = store
        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount), HKQuantityType(.activeEnergyBurned),
        ]
        // The async API throws if the request does not finish. It exposes no read permission status.
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }
}
