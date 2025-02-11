import Foundation
import HealthKit

class HealthKitManager: ObservableObject {
    // 健康資料儲存實例
    let healthStore = HKHealthStore()

    // 發布步數變數
    @Published var stepCount: Int = 0

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
}
