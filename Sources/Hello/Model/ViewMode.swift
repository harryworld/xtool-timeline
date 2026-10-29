import SwiftUI

enum ViewMode: String, CaseIterable {
    case day = "Day", week = "Week", month = "Month"

    var symbol: String {
        switch self {
        case .day: "sun.max.fill"
        case .week: "list.bullet.below.rectangle"
        case .month: "calendar"
        }
    }
}
