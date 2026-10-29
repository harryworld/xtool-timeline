import Foundation

/// Years addressed by integer offset from the current year; used as pager page ids.
enum YearIndex {
    private static var cal: Calendar { .current }

    static func startOfYear(for date: Date) -> Date {
        cal.dateInterval(of: .year, for: date)?.start ?? cal.startOfDay(for: date)
    }

    static func start(of offset: Int) -> Date {
        let anchor = startOfYear(for: .now)
        return cal.date(byAdding: .year, value: offset, to: anchor) ?? anchor
    }

    static func offset(for date: Date) -> Int {
        cal.dateComponents([.year], from: startOfYear(for: .now), to: startOfYear(for: date)).year ?? 0
    }

    static func months(ofYearStarting yearStart: Date) -> [Date] {
        (0..<12).compactMap { cal.date(byAdding: .month, value: $0, to: yearStart) }
    }

    static func dayCount(ofYearStarting yearStart: Date) -> Int {
        cal.range(of: .day, in: .year, for: yearStart)?.count ?? 365
    }

    /// The same month and day as `date` in the year at `offset` (Feb 29 clamps to Feb 28).
    static func sameDay(as date: Date, inYear offset: Int) -> Date {
        let month = MonthIndex.offset(for: date) + (offset - self.offset(for: date)) * 12
        return MonthIndex.sameDay(as: date, inMonth: month)
    }

    /// The day to select when a month is opened from the year grid: today if it is in that month,
    /// otherwise the selected day of month, clamped.
    static func dayToOpen(month monthStart: Date, selected: Date) -> Date {
        if cal.isDate(.now, equalTo: monthStart, toGranularity: .month) { return .now }
        return MonthIndex.sameDay(as: selected, inMonth: MonthIndex.offset(for: monthStart))
    }
}
