import Foundation

/// Months addressed by integer offset from the current month; used as pager page ids.
enum MonthIndex {
    private static var cal: Calendar { .current }

    static func startOfMonth(for date: Date) -> Date {
        cal.dateInterval(of: .month, for: date)?.start ?? cal.startOfDay(for: date)
    }

    static func start(of offset: Int) -> Date {
        let anchor = startOfMonth(for: .now)
        return cal.date(byAdding: .month, value: offset, to: anchor) ?? anchor
    }

    static func offset(for date: Date) -> Int {
        cal.dateComponents([.month], from: startOfMonth(for: .now), to: startOfMonth(for: date)).month ?? 0
    }

    /// Whole weeks covering the month, starting on the calendar's first weekday.
    static func gridDays(ofMonthStarting monthStart: Date) -> [Date] {
        let first = WeekIndex.startOfWeek(for: monthStart)
        let last = cal.date(byAdding: DateComponents(month: 1, day: -1), to: monthStart) ?? monthStart
        let lastWeekEnd = cal.date(byAdding: .day, value: 6, to: WeekIndex.startOfWeek(for: last)) ?? last
        let count = (cal.dateComponents([.day], from: first, to: lastWeekEnd).day ?? 34) + 1
        return (0..<count).compactMap { cal.date(byAdding: .day, value: $0, to: first) }
    }

    /// The same day-of-month as `date` in the month at `offset`, clamped to that month's length.
    static func sameDay(as date: Date, inMonth offset: Int) -> Date {
        let monthStart = start(of: offset)
        let length = cal.range(of: .day, in: .month, for: monthStart)?.count ?? 28
        let day = min(cal.component(.day, from: date), length)
        return cal.date(byAdding: .day, value: day - 1, to: monthStart) ?? monthStart
    }

    static func weekdaySymbols() -> [String] {
        let symbols = cal.veryShortStandaloneWeekdaySymbols
        let shift = cal.firstWeekday - 1
        return Array(symbols[shift...] + symbols[..<shift])
    }
}
