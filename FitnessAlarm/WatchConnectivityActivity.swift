import UIKit
import SwiftUI
import WatchConnectivity

@main
struct PhoneApp: App {
    @StateObject private var connectivityManager = ConnectivityManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(connectivityManager)
        }
    }
}

class ConnectivityManager: NSObject, ObservableObject, WCSessionDelegate {
    static let shared = ConnectivityManager()

    override init() {
        super.init()
        if WCSession.isSupported() {
            print("Activating wc from Phone...")
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
    @EnvironmentObject var connectivityManager: ConnectivityManager
    @State public var labelText = "Message from watch"

    
    var body: some View {
        VStack {
            Text(labelText)
                .font(.largeTitle)
                .padding()
            
            Button("Send Test Message to Watch") {
                labelText = "sending to watch"
                // Example message sending (would be from Watch to iPhone in your real case)
                if WCSession.default.isReachable {
                    let message = ["action": "buttonPressed"]
                    WCSession.default.sendMessage(message, replyHandler: nil) { error in
                        print("Failed to send message: \(error.localizedDescription)")
                    }
                }
            }
            .padding()
        }
        .onAppear {
            // Check if WCSession is activated
            if WCSession.default.activationState != .activated {
                print("WCSession is not activated yet.")
            }
        }
    }
}

#Preview {
    ContentView()
        .environmentObject(ConnectivityManager.shared)
}
