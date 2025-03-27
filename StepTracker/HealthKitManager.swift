import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    // 健康資料儲存實例
    let healthStore = HKHealthStore()

    // 發布步數變數
    @Published var stepCount: Int = 0

    // 更新資料結構以儲存每日步數
    @Published var weeklyStepCount: [(date: Date, steps: Int)] = []

    // 檢查是否可以使用 HealthKit
    func requestAuthorization() {
        // 確認裝置是否支援 HealthKit
        guard HKHealthStore.isHealthDataAvailable() else {
            print("此裝置不支援 HealthKit")
            return
        }

        // 設定要讀取的資料類型
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!

        // 請求權限
        healthStore.requestAuthorization(toShare: nil, read: [stepType, distanceType]) { success, error in
            if success {
                print("HealthKit 權限獲取成功")
            } else {
                print("HealthKit 權限獲取失敗：\(error?.localizedDescription ?? "未知錯誤")")
            }
        }
    }

    // 取得今日步數
    func fetchTodaySteps() {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }

        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)

        let query = HKStatisticsQuery(quantityType: stepType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum)
        { [weak self] _, result, error in
            guard let result = result, let sum = result.sumQuantity() else {
                print("無法取得步數資料：\(String(describing: error))")
                return
            }

            DispatchQueue.main.async {
                self?.stepCount = Int(sum.doubleValue(for: HKUnit.count()))
            }
        }

        healthStore.execute(query)
    }

    // 取得最近七天的步數
    func fetchWeeklySteps() {
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else { return }

        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -6, to: calendar.startOfDay(for: endDate)) else { return }

        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        let interval = DateComponents(day: 1)

        let query = HKStatisticsCollectionQuery(
            quantityType: stepType,
            quantitySamplePredicate: predicate,
            options: .cumulativeSum,
            anchorDate: startDate,
            intervalComponents: interval
        )

        query.initialResultsHandler = { [weak self] _, results, error in
            guard let results = results else {
                print("無法取得步數資料：\(String(describing: error))")
                return
            }

            var stepData: [(date: Date, steps: Int)] = []

            results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                let count = statistics.sumQuantity()?.doubleValue(for: HKUnit.count()) ?? 0
                stepData.append((date: statistics.startDate, steps: Int(count)))
            }

            DispatchQueue.main.async {
                self?.weeklyStepCount = stepData
            }
        }

        healthStore.execute(query)
    }

    func fetchStepsAndDistance() {
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!

        let calendar = Calendar.current
        let now = Date()
        // 設定開始時間（7 天前）
        guard let startDate = calendar.date(byAdding: .day, value: -7, to: now) else { return }

        let interval = DateComponents(minute: 1) // 設定時間間隔為每分鐘

        // 建立查詢函數
        func createQuery(for type: HKQuantityType, completion: @escaping ([Date: Double]) -> Void) {
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: nil,
                options: .cumulativeSum,
                anchorDate: now,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, error in
                if let error = error {
                    print("查詢 \(type.identifier) 失敗: \(error.localizedDescription)")
                    return
                }

                guard let results = results else { return }
                var data: [Date: Double] = [:]

                results.enumerateStatistics(from: startDate, to: now) { statistics, _ in
                    if let sum = statistics.sumQuantity() {
                        let value = sum.doubleValue(for: type == stepType ? HKUnit.count() : HKUnit.meter())
                        data[statistics.startDate] = value
                    }
                }

                completion(data)
            }

            healthStore.execute(query)
        }

        // 執行步數和步行距離的查詢
        createQuery(for: stepType) { stepData in
            createQuery(for: distanceType) { distanceData in
                for (date, steps) in stepData {
                    let distance = distanceData[date] ?? 0
                    print("時間: \(date), 步數: \(steps), 距離: \(distance) 公尺")
                }
            }
        }
    }

    // 更新資料的函數
    func refreshData() {
        fetchWeeklySteps()
        fetchStepsAndDistance()
    }
}
