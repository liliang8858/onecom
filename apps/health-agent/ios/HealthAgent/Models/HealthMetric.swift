import SwiftUI

enum MetricStatus: String, Codable {
    case normal
    case up
    case down
    case attention
    case missing
}

struct HealthMetric: Identifiable, Codable, Hashable {
    let id: String
    let label: String
    let value: String
    let detail: String
    let status: MetricStatus
    let colorName: String

    var color: Color {
        switch colorName {
        case "sleep": return HAColor.sleepPurple
        case "heart": return HAColor.ecgRed
        case "workout": return HAColor.workoutAmber
        default: return HAColor.recoveryGreen
        }
    }
}
