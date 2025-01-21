import SwiftUI
import WatchConnectivity

<<<<<<< Updated upstream
// @main
=======
//@main
>>>>>>> Stashed changes
struct WatchApp: App {
    @StateObject private var connectivityManager = WatchConnectivityManager()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityManager)
        }
    }
}

class WatchConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
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
    }

    func sendMessageToPhone() {
        if WCSession.default.isReachable {
            let message = ["action": "buttonPressed"]
            WCSession.default.sendMessage(message, replyHandler: nil) { error in
                print("Failed to send message: \(error.localizedDescription)")
            }
        } else {
            print("Phone is not reachable")
        }
    }
}

struct ContentView2: View {
    @EnvironmentObject var connectivityManager: WatchConnectivityManager
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
