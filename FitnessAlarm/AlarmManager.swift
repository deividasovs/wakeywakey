import Foundation
import UserNotifications
import AudioToolbox
//import WatchConnectivityActivity

class AlarmManager {
    static let shared = AlarmManager()
    
    func requestNotificationPermissions() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound]) { granted, error in
            if let error = error {
                print("Error requesting notification permissions: \(error)")
            } else {
                print("Notification permissions granted: \(granted)")
            }
        }
    }
    
    func scheduleAlarm(for date: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Alarm"
        content.body = "Wake up! Your alarm is going off."
        content.sound = .default
        
        // Create a trigger for the selected time
        let triggerDate = Calendar.current.dateComponents([.hour, .minute], from: date)
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false) //for testing, set it for 5 seconds in the future
        //let trigger = UNCalendarNotificationTrigger(dateMatching: triggerDate, repeats: false)
        
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling alarm: \(error)")
            } else {
                print("Alarm scheduled for \(date)")
                DispatchQueue.main.asyncAfter(deadline: .now() + 5) { /// for testing, change deadling to the actual one
                                  self.triggerVibration()
                                    PhoneToWatchConnectivityManager.shared.sendAlarmMessageToWatch()
                              }
            }
        }
    }
    
    private func triggerVibration() {
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
}
