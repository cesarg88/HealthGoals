import HealthKit

@MainActor
protocol HealthAuthorizing {
    var isAvailable: Bool { get }
    /// Finalización de la solicitud, sin estado de permiso de lectura.
    func requestReadAuthorization() async throws
}

@MainActor
final class HealthAuthorization: HealthAuthorizing {
    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }
    private var store: HKHealthStore?

    func requestReadAuthorization() async throws {
        guard isAvailable else { throw HKError(.errorHealthDataUnavailable) }
        let store = store ?? HKHealthStore()
        self.store = store
        let readTypes: Set<HKObjectType> = [
            HKQuantityType(.stepCount), HKQuantityType(.activeEnergyBurned)
        ]
        // La API async lanza error si la solicitud no finaliza. No expone permisos READ.
        try await store.requestAuthorization(toShare: [], read: readTypes)
    }
}
