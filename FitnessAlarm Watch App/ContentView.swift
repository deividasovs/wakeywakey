//
//  ContentView.swift
//  FitnessAlarm Watch App
//
//  Created by Deividas Ovsianikovas on 30/11/2024.
//

import SwiftUI
import HealthKit

struct ContentView: View {
    var body: some View {
        VStack {
            Image(systemName: "globe")
                .imageScale(.large)
                .foregroundStyle(.tint)
            Text("Logged in!")
            Text("Tap to vibrate")
                .fontWeight(.thin)
                .padding()
                .onTapGesture {
                       triggerHaptic()
               }
        }
        .padding()
    }
    
    func triggerHaptic() {
          WKInterfaceDevice.current().play(.success)
      }
    
}

#Preview {
    ContentView()
}
