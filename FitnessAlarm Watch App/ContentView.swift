import SwiftUI
import HealthKit
import AVFoundation

import Foundation
import Combine
import HealthKit
import AVFoundation
import WatchKit

class HeartRateManager: ObservableObject {
    private let healthStore = HKHealthStore()
    private var heartRateQuery: HKAnchoredObjectQuery?
    @Published var heartRate: Int = 0
    @Published var alarmActive: Bool = false
    @Published var alarmTime: Date? // Time to trigger the alarm

    private var heartRateBuffer: [Double] = []
    private let bufferSize = 5
    private var audioPlayer: AVAudioPlayer?
    private var timer: AnyCancellable?

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

    func setAlarmTime(_ time: Date) {
        alarmTime = time
        startAlarmTimer()
    }

    private func startAlarmTimer() {
        // Cancel any existing timer
        timer?.cancel()

        // Start a new timer that checks every second
        timer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] currentTime in
                guard let self = self, let alarmTime = self.alarmTime else { return }

                let calendar = Calendar.current
                if calendar.isDate(currentTime, equalTo: alarmTime, toGranularity: .minute) {
                    self.triggerAlarm()
                    self.timer?.cancel() // Stop the timer after triggering the alarm
                }
            }
    }

    private func triggerAlarm() {
        alarmActive = true
        playAlarmSound()
        triggerHapticFeedback()
        print("Alarm triggered at the set time!")
    }

    // MARK: - Heart Rate Monitoring
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
    }

    func stopHeartRateMonitoring() {
        if let query = heartRateQuery {
            healthStore.stop(query)
        }
        heartRateQuery = nil
        alarmActive = false
        stopAlarmSoundAndHaptics()
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

            // Stop the alarm automatically if the heart rate reaches 110 bpm
            
            // TODO: Set to specific bpm based on user settings
            if self.heartRate >= 110 && self.alarmActive {
                self.stopHeartRateMonitoring()
                WatchToPhoneConnectivityManager.shared.sendStopalarmMessageToPhone()
                print("Alarm stopped. Heart rate threshold reached.")
            }
        }
    }

    // MARK: - Alarm Sound
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

    // MARK: - Haptic Feedback
    private func triggerHapticFeedback() {
        WKInterfaceDevice.current().play(.notification)
        print("Haptic feedback triggered.")
    }
}


struct ContentView: View {
    @StateObject private var heartRateManager = HeartRateManager()
    @State private var selectedTime = Date() // Time selected by the user

    var body: some View {
        VStack {
            // Heart rate display
            Text("Heart Rate: \(heartRateManager.heartRate) bpm")
                .font(.title)
                .padding()

            // Time picker for setting the alarm
            if #available(watchOS 10.0, *) {
                DatePicker("Set Alarm Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .labelsHidden()
                    .datePickerStyle(WheelDatePickerStyle())
                    .padding()
            } else {
                // Fallback on earlier versions
            }

            Button("Set Alarm Time") {
                heartRateManager.setAlarmTime(selectedTime)
                print("Alarm set for: \(selectedTime)")
            }
            .font(.headline)
            .padding()
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)

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

            if heartRateManager.alarmActive {
                Text("Alarm is active. Waiting for heart rate to reach 150 bpm or set time...")
                    .font(.caption)
                    .padding()
            }
        }
        .onAppear {
            heartRateManager.requestHealthKitPermissions()
        }
    }
}
