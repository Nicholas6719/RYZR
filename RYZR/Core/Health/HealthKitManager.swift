import Foundation
#if canImport(HealthKit)
import HealthKit
#endif

@MainActor
final class HealthKitManager {
    static let shared = HealthKitManager()
    private init() {}

    #if canImport(HealthKit)
    private let store = HKHealthStore()

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    func requestPermissions() async {
        guard isAvailable else { return }

        var read: Set<HKObjectType> = []
        var write: Set<HKSampleType> = []

        if let bodyMass = HKObjectType.quantityType(forIdentifier: .bodyMass) {
            read.insert(bodyMass)
        }
        if let activeEnergy = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
            read.insert(activeEnergy)
            write.insert(activeEnergy)
        }
        if let steps = HKObjectType.quantityType(forIdentifier: .stepCount) {
            read.insert(steps)
        }
        read.insert(HKObjectType.workoutType())
        write.insert(HKObjectType.workoutType())

        do {
            try await store.requestAuthorization(toShare: write, read: read)
        } catch {
            print("[HealthKitManager] auth error: \(error)")
        }
    }
    #else
    var isAvailable: Bool { false }
    func requestPermissions() async {}
    #endif
}
