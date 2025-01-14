import SwiftUI

struct ContentViewGpt: View {
    @StateObject private var heartRateMonitor = HeartRateMonitor()
    @State private var bpmThreshold: Int = 120 // Default value

    var body: some View {
        VStack {
            Text("Current BPM: \(heartRateMonitor.currentBPM)")
                .font(.headline)

            Button("Start Alarm") {
                heartRateMonitor.startMonitoring(bpmThreshold: bpmThreshold)
            }
            .padding()
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: Notification.Name("WatchMessageReceived"), object: nil, queue: .main) { notification in
                if let message = notification.object as? [String: Any], let threshold = message["bpmThreshold"] as? Int {
                    self.bpmThreshold = threshold
                }
            }
        }
    }
}


#Preview {
    ContentViewGpt()
}
