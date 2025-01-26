import SwiftUI
import WatchConnectivity

struct WatchApp: App {
    @StateObject private var connectivityManager = WatchToPhoneConnectivityManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityManager)
        }
    }
}

class WatchToPhoneConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = WatchToPhoneConnectivityManager()

    override init() {
        super.init()
        if WCSession.isSupported() {
            print("Activating wc from watch...")
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed: \(error.localizedDescription)")
        } else {
            print("WCSession activated with state: \(activationState.rawValue)")
        }
        
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any], error: Error?) {
        if let action = message["action"] as? String, action == "buttonPressed" {
            print("Message received: The button was pressed on Phone")
            DispatchQueue.main.async {
                    ContentView2().titleMessage = "Some new text!"
                  }
        }
        
        if let action = message["action"] as? String, action == "alarmButtonPressed" {
            print("Message received: wow the alarm button was pressed on Phone!!")
            DispatchQueue.main.async {
                    ContentView2().titleMessage = "alarm button!!" // changing text not working properly..
                  }
        }
    }

    
    /// TODO: Change these to enums instead of just pure strings
    func sendStopalarmMessageToPhone(String action: String = "stopAlarm") {
        if WCSession.default.isReachable {
            let message = ["action": action]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Failed to send message: \(error.localizedDescription)")
            }
        } else {
            print("Phone is not reachable")
        }
    }
    
    func sendMessageToPhone(String action: String = "buttonPressed") {
        if WCSession.default.isReachable {
            let message = ["action": action]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Failed to send message: \(error.localizedDescription)")
            }
        } else {
            print("Phone is not reachable")
        }
    }
}

struct ContentView2: View {
    @EnvironmentObject var connectivityManager: WatchToPhoneConnectivityManager
    @State public var titleMessage: String = "Hello"
    
    var body: some View {
        VStack {
            Text(titleMessage)
            Button("Send Message") {
                titleMessage = "Sent!"
                connectivityManager.sendMessageToPhone()
            }
            .padding()
        }
    }
}

#Preview {
    //ContentView()
     //   .environmentObject(WatchConnectivityManager())
}
