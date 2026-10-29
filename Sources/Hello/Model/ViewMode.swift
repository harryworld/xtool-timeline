import SwiftUI

enum ViewMode: String, CaseIterable {
    case day = "Day", week = "Week", month = "Month", year = "Year"

    var symbol: String {
        switch self {
        case .day: "sun.max.fill"
        case .week: "list.bullet.below.rectangle"
        case .month: "calendar"
        case .year: "square.grid.3x3.fill"
        }
    }
}

extension ViewMode {
    /// `.day`, unless a debug build is launched with TIMELINE_MODE=day|week|month|year (for screenshots).
    static var initial: ViewMode {
        #if DEBUG
        if let raw = ProcessInfo.processInfo.environment["TIMELINE_MODE"],
           let m = allCases.first(where: { $0.rawValue.lowercased() == raw.lowercased() }) { return m }
        #endif
        return .day
    }
}
