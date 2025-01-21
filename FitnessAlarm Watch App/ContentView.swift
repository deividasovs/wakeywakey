import SwiftUI
import HealthKit
import AVFoundation

class HeartRateManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    @Published var heartRate: Int = 0
    @Published var alarmActive: Bool = false

    private var heartRateBuffer: [Double] = []
    private let bufferSize = 5
    private var audioPlayer: AVAudioPlayer?

    func requestHealthKitPermissions() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data not available on this device.")
            return
        }

        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        healthStore.requestAuthorization(toShare: [], read: [heartRateType]) { success, error in
            if success {
                print("HealthKit authorization granted.")
            } else {
                print("HealthKit authorization failed: \(String(describing: error))")
            }
        }
    }

    func startHeartRateMonitoring() {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        heartRateQuery = HKAnchoredObjectQuery(
            type: heartRateType,
            predicate: nil,
            anchor: nil,
            limit: HKObjectQueryNoLimit
        ) { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        heartRateQuery?.updateHandler = { [weak self] _, samples, _, _, _ in
            self?.processHeartRateSamples(samples)
        }

        if let query = heartRateQuery {
            print("Executing heart rate query...")
            healthStore.execute(query)
        } else {
            print("Failed to create heart rate query.")
        }

        // Start alarm sound immediately when monitoring begins
        playAlarmSound()
    }

    func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        heartRateQuery = nil
        alarmActive = false

        // Stop alarm sound and haptic feedback
        stopAlarmSoundAndHaptics()
    }

    
    func testPlaySound() {
        guard let soundURL = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") else {
            print("Alarm sound file not found.")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.play()
            print("Playing sound...")
        } catch {
            print("Failed to play sound: \(error.localizedDescription)")
        }
    }

    private func processHeartRateSamples(_ samples: [HKSample]?) {
        guard let quantitySamples = samples as? [HKQuantitySample] else {
            print("No heart rate samples available.")
            return
        }
        guard let sample = quantitySamples.last else {
            print("No latest heart rate sample found.")
            return
        }

        let heartRateValue = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
        print("Fetched heart rate: \(heartRateValue) bpm")

        DispatchQueue.main.async {
            // Add the new heart rate value to the buffer
            self.heartRateBuffer.append(heartRateValue)

            // Limit the buffer size to the specified size
            if self.heartRateBuffer.count > self.bufferSize {
                self.heartRateBuffer.removeFirst()
            }

            // Calculate the moving average
            let averageHeartRate = self.heartRateBuffer.reduce(0, +) / Double(self.heartRateBuffer.count)
            self.heartRate = Int(averageHeartRate)

            // Stop the alarm automatically if the heart rate reaches 150 bpm
            if self.heartRate >= 150 && self.alarmActive {
                self.stopHeartRateMonitoring()
                print("Alarm stopped. Heart rate threshold reached.")
            }
        }
    }

    private func triggerAlarm() {
        playAlarmSound()
        triggerHapticFeedback()
        print("Alarm is triggered!")
    }

    private func playAlarmSound() {
        guard let soundURL = Bundle.main.url(forResource: "alarm_sound", withExtension: "mp3") else {
            print("Alarm sound file not found.")
            return
        }
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.numberOfLoops = -1 // Loop indefinitely
            audioPlayer?.play()
        } catch {
            print("Failed to play alarm sound: \(error.localizedDescription)")
        }
    }

    private func stopAlarmSoundAndHaptics() {
        audioPlayer?.stop()
    }

    private func triggerHapticFeedback() {
        WKInterfaceDevice.current().play(.notification)
        print("Haptic feedback triggered.")
    }
}

struct ContentView: View {
    @StateObject private var heartRateManager = HeartRateManager()

    var body: some View {
        VStack {
            // Heart rate display with smaller font and dynamic resizing
            Text("Heart Rate: \(heartRateManager.heartRate) bpm")
                .font(.system(size: 24)) // Smaller font size
                .minimumScaleFactor(0.5) // Allows the text to scale down if needed
                .lineLimit(1) // Ensures the text stays on one line
                .padding()

            // Alarm button
            Button(heartRateManager.alarmActive ? "Stop Alarm" : "Start Alarm") {
                if heartRateManager.alarmActive {
                    heartRateManager.stopHeartRateMonitoring()
                } else {
                    heartRateManager.alarmActive = true
                    heartRateManager.startHeartRateMonitoring()
                }
            }
            .font(.headline)
            .padding()
            .background(heartRateManager.alarmActive ? Color.red : Color.green)
            .foregroundColor(.white)
            .cornerRadius(10)
            
            Button("Test Haptics") {
                WKInterfaceDevice.current().play(.notification)
            }

            // Alarm state description
            if heartRateManager.alarmActive {
                Text("Alarm is active. Waiting for heart rate to reach 150 bpm...")
                    .font(.caption) // Smaller font size for the description
                    .padding()
            }
        }
        .onAppear {
            heartRateManager.requestHealthKitPermissions()
        }
    }
}
