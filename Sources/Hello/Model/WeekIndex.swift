import Foundation

/// Weeks addressed by integer offset from the current week; used as pager page ids.
enum WeekIndex {
    private static var cal: Calendar { .current }

    static func startOfWeek(for date: Date) -> Date {
        cal.dateInterval(of: .weekOfYear, for: date)?.start ?? cal.startOfDay(for: date)
    }

    static func days(from weekStart: Date) -> [Date] {
        (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: weekStart) }
    }

    static func days(ofWeekContaining date: Date) -> [Date] {
        days(from: startOfWeek(for: date))
    }

    static func start(of offset: Int) -> Date {
        let anchor = startOfWeek(for: .now)
        return cal.date(byAdding: .day, value: offset * 7, to: anchor) ?? anchor
    }

    static func offset(for date: Date) -> Int {
        let d = cal.dateComponents([.day], from: startOfWeek(for: .now), to: startOfWeek(for: date)).day ?? 0
        return Int((Double(d) / 7).rounded())
    }

    /// The same weekday as `date`, moved into the week at `offset`.
    static func sameWeekday(as date: Date, inWeek offset: Int) -> Date? {
        let dayIndex = cal.dateComponents([.day], from: start(of: self.offset(for: date)), to: cal.startOfDay(for: date)).day ?? 0
        return cal.date(byAdding: .day, value: dayIndex, to: start(of: offset))
    }
}
