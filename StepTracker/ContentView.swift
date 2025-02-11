//
//  ContentView.swift
//  StepTracker
//
//  Created by 程信傑 on 2025/2/11.
//

import HealthKit
import SwiftUI

struct ContentView: View {
    @StateObject private var healthKitManager = HealthKitManager()

    var body: some View {
        VStack(spacing: 20) {
            Text("今日步數")
                .font(.title)
                .fontWeight(.bold)

            Text("\(healthKitManager.stepCount)")
                .font(.system(size: 48))
                .fontWeight(.bold)

            Image(systemName: "figure.walk")
                .font(.system(size: 50))
                .foregroundColor(.blue)
        }
        .onAppear {
            healthKitManager.requestAuthorization()
        }
    }
}

#Preview {
    ContentView()
}
