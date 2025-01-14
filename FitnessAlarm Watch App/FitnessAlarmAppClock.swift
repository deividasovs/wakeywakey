// WatchOS App: Heart Rate Monitoring
import SwiftUI
import HealthKit

class HeartRateMonitor: ObservableObject {
    private var healthStore = HKHealthStore()
    private var heartRateQuery: HKQuery?
    @Published var currentBPM: Int = 0

    func startMonitoring(bpmThreshold: Int) {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let dataTypes = Set([heartRateType])

        healthStore.requestAuthorization(toShare: nil, read: dataTypes) { success, error in
            if success {
                self.beginHeartRateQuery(bpmThreshold: bpmThreshold)
            }
        }
    }

    private func beginHeartRateQuery(bpmThreshold: Int) {
        guard let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate) else { return }

        let query = HKAnchoredObjectQuery(type: heartRateType, predicate: nil, anchor: nil, limit: HKObjectQueryNoLimit) { [weak self] query, samples, _, _, _ in
            self?.process(samples: samples, bpmThreshold: bpmThreshold)
        }

        query.updateHandler = { [weak self] query, samples, _, _, _ in
            self?.process(samples: samples, bpmThreshold: bpmThreshold)
        }

        healthStore.execute(query)
        heartRateQuery = query
    }

    private func process(samples: [HKSample]?, bpmThreshold: Int) {
        guard let samples = samples as? [HKQuantitySample] else { return }

        for sample in samples {
            let heartRateUnit = HKUnit(from: "count/min")
            let bpm = Int(sample.quantity.doubleValue(for: heartRateUnit))

            DispatchQueue.main.async {
                self.currentBPM = bpm
                if bpm >= bpmThreshold {
                    self.triggerAlarm()
                }
            }
        }
    }

    private func triggerAlarm() {
        WKInterfaceDevice.current().play(.notification)
        NotificationCenter.default.post(name: Notification.Name("AlarmTriggered"), object: nil)
    }
}
