import SwiftUI

/// A tiny month: title, 6 rows of day numbers, today highlighted, a dot on days with events.
struct MiniMonth: View {
    let monthStart: Date
    let onTap: () -> Void

    var body: some View {
        let cal = Calendar.current
        let isThisMonth = cal.isDate(.now, equalTo: monthStart, toGranularity: .month)
        let days = MonthIndex.gridDays(ofMonthStarting: monthStart)
            .map { cal.isDate($0, equalTo: monthStart, toGranularity: .month) ? $0 : nil }
        let cells = days + Array(repeating: nil, count: max(0, 42 - days.count))
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 3) {
                Text(monthStart.formatted(.dateTime.month(.abbreviated)))
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(isThisMonth ? Theme.pinkDeep : Theme.lavenderDeep)
                    .padding(.leading, 4)
                Grid(horizontalSpacing: 0, verticalSpacing: 1) {
                    ForEach(0..<6, id: \.self) { row in
                        GridRow {
                            ForEach(0..<7, id: \.self) { col in
                                MiniDay(day: cells[row * 7 + col])
                            }
                        }
                    }
                }
            }
            .padding(6)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .background(.white.opacity(isThisMonth ? 0.75 : 0.45), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous)
                .strokeBorder(isThisMonth ? Theme.pink : .white.opacity(0.9), lineWidth: 1))
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(monthStart.formatted(.dateTime.month(.wide).year()))
    }
}

struct MiniDay: View {
    @Environment(CalendarStore.self) private var store
    let day: Date?

    var body: some View {
        if let day {
            let isToday = Calendar.current.isDateInToday(day)
            let hasEvents = store.box(for: day).events.map { !$0.isEmpty } ?? false
            VStack(spacing: 0) {
                Text(day.formatted(.dateTime.day()))
                    .font(.system(size: 8, weight: isToday ? .heavy : .semibold, design: .rounded).monospacedDigit())
                    .foregroundStyle(isToday ? Color.white : Theme.ink)
                    .frame(width: 13, height: 12)
                    .background { if isToday { Circle().fill(Theme.pinkDeep) } }
                Circle()
                    .fill(Theme.pinkDeep.pastel(0.35))
                    .frame(width: 3, height: 3)
                    .opacity(hasEvents ? 1 : 0)
            }
            .frame(maxWidth: .infinity)
        } else {
            Color.clear.frame(maxWidth: .infinity).frame(height: 15)
        }
    }
}
