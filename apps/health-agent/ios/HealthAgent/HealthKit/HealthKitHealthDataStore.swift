import Foundation

#if canImport(HealthKit)
import HealthKit

final class HealthKitHealthDataStore: HealthDataStore {
    private let healthStore: HKHealthStore
    private let calendar: Calendar

    init(healthStore: HKHealthStore = HKHealthStore(), calendar: Calendar = .current) {
        self.healthStore = healthStore
        self.calendar = calendar
    }

    func fetchDailySnapshot() async -> DailyHealthSnapshot {
        async let hrv = latestAverage(metricID: "heart_rate_variability", range: .week)
        async let restingHeartRate = latestAverage(metricID: "resting_heart_rate", range: .week)
        async let sleep = sleepSeries(range: .week)
        async let load = latestAverage(metricID: "active_energy", range: .week)

        let hrvValue = await hrv
        let restingHeartRateValue = await restingHeartRate
        let sleepSamples = await sleep
        let loadValue = await load

        let latestSleep = sleepSamples.last?.value ?? 0
        return DailyHealthSnapshot(
            recoveryScore: hrvValue == nil || restingHeartRateValue == nil ? 0 : 62,
            sleepDuration: latestSleep > 0 ? String(format: "%.1fh", latestSleep) : "数据不足",
            restingHeartRate: restingHeartRateValue.map { String(format: "%.0f bpm", $0) } ?? "数据不足",
            hrv: hrvValue.map { String(format: "%.0f ms", $0) } ?? "数据不足",
            workoutLoad: loadValue.map { String(format: "%.0f kcal", $0) } ?? "数据不足",
            summary: "已读取授权范围内的 HealthKit 摘要数据。"
        )
    }

    func fetchMetricSeries(metricID: String, range: HealthTimeRange) async -> [HealthMetricSample] {
        switch metricID {
        case "sleep_duration":
            return await sleepSeries(range: range)
        default:
            return await quantitySeries(metricID: metricID, range: range)
        }
    }

    func fetchLatestECG() async -> ECGEpisode? {
        guard HKHealthStore.isHealthDataAvailable() else { return nil }
        let type = HKObjectType.electrocardiogramType()
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: [sort]) { _, samples, _ in
                guard let ecg = samples?.first as? HKElectrocardiogram else {
                    continuation.resume(returning: nil)
                    return
                }

                let averageHeartRate = ecg.averageHeartRate?
                    .doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                let recordedAt = Self.shortDateFormatter.string(from: ecg.startDate)
                continuation.resume(returning: ECGEpisode(
                    id: ecg.uuid.uuidString,
                    recordedAt: recordedAt,
                    quality: "待分析",
                    rhythmSummary: Self.classificationSummary(ecg.classification),
                    averageHeartRate: averageHeartRate.map { String(format: "%.0f bpm", $0) } ?? "数据不足",
                    classification: Self.classificationText(ecg.classification),
                    note: "来自 Apple Health ECG。波形级质量和节律细节需要进一步读取电压序列后分析。"
                ))
            }
            healthStore.execute(query)
        }
    }

    private func quantitySeries(metricID: String, range: HealthTimeRange) async -> [HealthMetricSample] {
        guard let descriptor = quantityDescriptor(for: metricID) else { return [] }
        let dates = dateWindow(for: range)
        let predicate = HKQuery.predicateForSamples(withStart: dates.start, end: dates.end, options: .strictStartDate)
        var interval = DateComponents()
        interval.day = 1

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: descriptor.type,
                quantitySamplePredicate: predicate,
                options: descriptor.options,
                anchorDate: dates.start,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, collection, _ in
                guard let collection else {
                    continuation.resume(returning: [])
                    return
                }

                var samples: [HealthMetricSample] = []
                collection.enumerateStatistics(from: dates.start, to: dates.end) { statistics, _ in
                    let quantity = descriptor.options.contains(.cumulativeSum) ? statistics.sumQuantity() : statistics.averageQuantity()
                    guard let quantity else { return }
                    let value = quantity.doubleValue(for: descriptor.unit)
                    samples.append(HealthMetricSample(
                        id: "\(metricID)-\(statistics.startDate.timeIntervalSince1970)",
                        dateLabel: Self.dayFormatter.string(from: statistics.startDate),
                        value: value
                    ))
                }
                continuation.resume(returning: samples)
            }

            healthStore.execute(query)
        }
    }

    private func sleepSeries(range: HealthTimeRange) async -> [HealthMetricSample] {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let dates = dateWindow(for: range)
        let predicate = HKQuery.predicateForSamples(withStart: dates.start, end: dates.end, options: .strictStartDate)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, _ in
                let categorySamples = (samples as? [HKCategorySample]) ?? []
                let asleepSamples = categorySamples.filter { $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue }
                let grouped = Dictionary(grouping: asleepSamples) { sample in
                    self.calendar.startOfDay(for: sample.startDate)
                }

                let result = grouped
                    .map { day, samples -> (Date, HealthMetricSample) in
                        let hours = samples.reduce(0.0) { partial, sample in
                            partial + sample.endDate.timeIntervalSince(sample.startDate) / 3600
                        }
                        return (day, HealthMetricSample(
                            id: "sleep-\(day.timeIntervalSince1970)",
                            dateLabel: Self.dayFormatter.string(from: day),
                            value: hours
                        ))
                    }
                    .sorted { $0.0 < $1.0 }
                    .map { $0.1 }

                continuation.resume(returning: result)
            }
            healthStore.execute(query)
        }
    }

    private func latestAverage(metricID: String, range: HealthTimeRange) async -> Double? {
        await fetchMetricSeries(metricID: metricID, range: range).last?.value
    }

    private func quantityDescriptor(for metricID: String) -> QuantityDescriptor? {
        switch metricID {
        case "heart_rate_variability":
            return quantityDescriptor(identifier: .heartRateVariabilitySDNN, unit: HKUnit.secondUnit(with: .milli), options: .discreteAverage)
        case "resting_heart_rate":
            return quantityDescriptor(identifier: .restingHeartRate, unit: HKUnit.count().unitDivided(by: HKUnit.minute()), options: .discreteAverage)
        case "heart_rate":
            return quantityDescriptor(identifier: .heartRate, unit: HKUnit.count().unitDivided(by: HKUnit.minute()), options: .discreteAverage)
        case "active_energy":
            return quantityDescriptor(identifier: .activeEnergyBurned, unit: HKUnit.kilocalorie(), options: .cumulativeSum)
        default:
            return nil
        }
    }

    private func quantityDescriptor(identifier: HKQuantityTypeIdentifier, unit: HKUnit, options: HKStatisticsOptions) -> QuantityDescriptor? {
        guard let type = HKObjectType.quantityType(forIdentifier: identifier) else { return nil }
        return QuantityDescriptor(type: type, unit: unit, options: options)
    }

    private func dateWindow(for range: HealthTimeRange) -> (start: Date, end: Date) {
        let end = Date()
        let dayCount: Int
        switch range {
        case .day: dayCount = 1
        case .week: dayCount = 7
        case .month: dayCount = 30
        case .quarter: dayCount = 90
        }
        let start = calendar.date(byAdding: .day, value: -dayCount, to: end) ?? end
        return (calendar.startOfDay(for: start), end)
    }

    private static func classificationText(_ classification: HKElectrocardiogram.Classification) -> String {
        switch classification {
        case .notSet: return "未设置"
        case .sinusRhythm: return "窦性心律"
        case .atrialFibrillation: return "房颤相关信号"
        case .inconclusiveLowHeartRate: return "不可判读，心率偏低"
        case .inconclusiveHighHeartRate: return "不可判读，心率偏高"
        case .inconclusivePoorReading: return "不可判读，信号质量不足"
        case .inconclusiveOther: return "不可判读"
        @unknown default: return "未知分类"
        }
    }

    private static func classificationSummary(_ classification: HKElectrocardiogram.Classification) -> String {
        switch classification {
        case .sinusRhythm:
            return "Apple Health 分类显示为窦性心律"
        case .atrialFibrillation:
            return "Apple Health 标记了房颤相关信号，建议结合症状和医生意见解读"
        case .inconclusiveLowHeartRate, .inconclusiveHighHeartRate, .inconclusivePoorReading, .inconclusiveOther:
            return "本次 ECG 不可判读，建议先查看信号质量或在安静状态下复测"
        default:
            return "本次 ECG 分类信息有限"
        }
    }

    private static let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()

    private static let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M月d日 HH:mm"
        return formatter
    }()
}

private struct QuantityDescriptor {
    let type: HKQuantityType
    let unit: HKUnit
    let options: HKStatisticsOptions
}

#else

final class HealthKitHealthDataStore: HealthDataStore {
    private let fallback = MockHealthDataStore()

    func fetchDailySnapshot() async -> DailyHealthSnapshot {
        await fallback.fetchDailySnapshot()
    }

    func fetchMetricSeries(metricID: String, range: HealthTimeRange) async -> [HealthMetricSample] {
        await fallback.fetchMetricSeries(metricID: metricID, range: range)
    }

    func fetchLatestECG() async -> ECGEpisode? {
        await fallback.fetchLatestECG()
    }
}

#endif
