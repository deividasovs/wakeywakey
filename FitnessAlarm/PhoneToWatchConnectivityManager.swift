import UIKit
import SwiftUI
import WatchConnectivity

@main
struct PhoneApp: App {
    @StateObject private var connectivityManager = PhoneToWatchConnectivityManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityManager)
        }
    }
}

class PhoneToWatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = PhoneToWatchConnectivityManager()

    override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let action = message["action"] as? String, action == "buttonPressed" {
            print("Message received: Button pressed on Watch")
            DispatchQueue.main.async {
                    ContentView().labelText = "Some new text!"
                  }
        }
        
        if let action = message["action"] as? String, action == "stopAlarm" {
            print("Message received: heart rate reached, stop the alarm!!")
            DispatchQueue.main.async {
                    ContentView().labelText = "Good shit! Stopping alarm..."
                  }
        }
    }
    
    func sendAlarmMessageToWatch() {
        print("Telling Apple Watch to alarm!")
        
        
        ///TODO: Move on from here
        if WCSession.default.isReachable {
            let message = ["action": "alarmButtonPressed"]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Failed to send message: \(error.localizedDescription)")
            }
        }
    }

    func session(
        _ session: WCSession,
        activationDidCompleteWith activationState: WCSessionActivationState,
        error: Error?
    ) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
    }

    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {}
}

struct ContentView: View {
    @EnvironmentObject var connectivityManager: PhoneToWatchConnectivityManager
    @State public var labelText = "[Message from watch]"
    @State private var selectedTime = Date()
    @State private var isAlarmSet = false
    
    
    var body: some View {
        VStack {
            Text("Select Alarm")
                .font(.headline)
                .padding()
            
            DatePicker("Select Time", selection: $selectedTime, displayedComponents: .hourAndMinute)
                .datePickerStyle(WheelDatePickerStyle())
                .labelsHidden()
                .padding()
            
            if isAlarmSet {
                Text("Alarm set for \(formattedTime)")
                    .font(.headline)
                    .foregroundColor(.green)
                    .padding()
            }
            
           Button(action: {
               isAlarmSet = true
               AlarmManager.shared.scheduleAlarm(for: selectedTime)
           }) {
               Text("Set Alarm")
                   .fontWeight(.bold)
                   .foregroundColor(.white)
                   .frame(maxWidth: .infinity)
                   .padding()
                   .background(Color.blue)
                   .cornerRadius(10)
           }
           .padding(.horizontal)
           .padding()
    
            
            Button("Send Test Message to Watch") {
                labelText = "sending to watch"
                if WCSession.default.isReachable {
                    let message = ["action": "buttonPressed"]
                    WCSession.default.sendMessage(message, replyHandler: nil) { error in
                        print("Failed to send message: \(error.localizedDescription)")
                    }
                }
            }
            Text(labelText)
                .font(.subheadline)
                .padding()
            
            .padding()
        }
        .onAppear {
            AlarmManager.shared.requestNotificationPermissions()
            
            // Check if WCSession is activated
            if WCSession.default.activationState != .activated {
                print("WCSession is not activated yet.")
            }
        }
    }
    
    
    private var formattedTime: String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: selectedTime)
    }
}

#Preview {
    ContentView()
        .environmentObject(PhoneToWatchConnectivityManager.shared)
}
