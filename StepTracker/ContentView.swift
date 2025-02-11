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

    // 日期格式化
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 20) {
            Text("最近七天步數")
                .font(.title)
                .fontWeight(.bold)

            // 長條圖
            HStack(alignment: .bottom, spacing: 12) {
                ForEach(healthKitManager.weeklyStepCount, id: \.date) { data in
                    VStack {
                        // 步數
                        Text("\(data.steps)")
                            .font(.caption)
                            .rotationEffect(.degrees(-60))
                            .offset(y: -20)

                        // 長條
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.blue)
                            .frame(width: 30, height: CGFloat(data.steps) / 100)

                        // 日期
                        Text(dateFormatter.string(from: data.date))
                            .font(.caption)
                            .rotationEffect(.degrees(-60))
                    }
                }
            }
            .frame(height: 300)
            .padding(.top, 40)

            // 更新按鈕
            Button(action: {
                healthKitManager.refreshData()
            }) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("更新資料")
                }
                .padding()
                .background(Color.blue)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
        }
        .padding()
        .onAppear {
            healthKitManager.requestAuthorization()
            healthKitManager.fetchWeeklySteps()
        }
    }
}

#Preview {
    ContentView()
}
