//
//  ContentView.swift
//  StepTracker
//
//  Created by 程信傑 on 2025/2/11.
//

import HealthKit
import SwiftUI

struct ContentView: View {
    // 使用 StateObject 來管理 HealthKit 資料
    @StateObject private var healthKitManager = HealthKitManager()

    // 設定日期格式化器，用於顯示日期標籤
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd" // 以月/日格式顯示
        return formatter
    }()

    var body: some View {
        VStack(spacing: 20) {
            // 標題
            Text("最近七天步數")
                .font(.title)
                .fontWeight(.bold)

            // 步數長條圖區域
            HStack(alignment: .bottom, spacing: 12) {
                // 遍歷每日步數資料
                ForEach(healthKitManager.weeklyStepCount, id: \.date) { data in
                    VStack {
                        // 顯示步數數值
                        Text("\(data.steps)")
                            .font(.caption)
                            .rotationEffect(.degrees(-60)) // 旋轉標籤以避免重疊
                            .offset(y: -20)

                        // 步數長條圖
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color.blue)
                            .frame(width: 30, height: CGFloat(data.steps) / 100) // 步數除以100作為高度比例

                        // 顯示日期標籤
                        Text(dateFormatter.string(from: data.date))
                            .font(.caption)
                            .rotationEffect(.degrees(-60)) // 旋轉標籤以避免重疊
                    }
                }
            }
            .frame(height: 300) // 設定圖表區域高度
            .padding(.top, 40) // 為旋轉的標籤預留空間

            // 手動更新資料按鈕
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
            // 畫面出現時請求權限並載入資料
            healthKitManager.requestAuthorization()
            healthKitManager.fetchWeeklySteps()
        }
    }
}

#Preview {
    ContentView()
}
