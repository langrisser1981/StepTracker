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
        guard let stepType = HKObjectType.quantityType(forIdentifier: .stepCount) else {
            print("無法取得步數資料類型")
            return
        }

        // 請求權限
        healthStore.requestAuthorization(toShare: [], read: [stepType]) { success, error in
            if success {
                print("成功取得健康資料存取權限")
                self.fetchTodaySteps()
            } else {
                print("無法取得健康資料存取權限：\(String(describing: error))")
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

    // 更新資料的函數
    func refreshData() {
        fetchWeeklySteps()
    }
}
