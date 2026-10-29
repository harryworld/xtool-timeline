import SwiftUI

struct MonthPage: View {
    @Environment(CalendarStore.self) private var store
    let monthStart: Date
    let selected: Date
    let frames: BubbleFrames
    /// Only the selected month's page hands the selected week's bubbles to the flying overlay.
    let isSelectedMonth: Bool
    let hideSelected: Bool
    let onTap: (Date) -> Void

    var body: some View {
        let days = MonthIndex.gridDays(ofMonthStarting: monthStart)
        let cal = Calendar.current
        let selectedWeek = WeekIndex.startOfWeek(for: selected)
        VStack(alignment: .leading, spacing: 6) {
            Label(monthStart.formatted(.dateTime.month(.abbreviated).year()), systemImage: "sparkles")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.lavenderDeep)
                .padding(.leading, 20)
                .padding(.top, 12)
            WeekdayHeader()
                .padding(.horizontal, 12)
            VStack(spacing: 4) {
                ForEach(0..<(days.count / 7), id: \.self) { row in
                    HStack(spacing: 4) {
                        ForEach(days[(row * 7)..<(row * 7 + 7)], id: \.self) { d in
                            MonthCell(day: d, selected: selected,
                                      inMonth: cal.isDate(d, equalTo: monthStart, toGranularity: .month),
                                      events: store.box(for: d).events, frames: frames,
                                      tracksFrame: isSelectedMonth && WeekIndex.startOfWeek(for: d) == selectedWeek,
                                      hidden: hideSelected, onTap: onTap)
                        }
                    }
                    .frame(maxHeight: .infinity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 6)
        }
        .task(id: monthStart) {
            if let first = days.first { store.ensureLoaded(from: first, days: days.count) }
        }
    }
}

struct WeekdayHeader: View {
    var body: some View {
        HStack(spacing: 4) {
            ForEach(Array(MonthIndex.weekdaySymbols().enumerated()), id: \.offset) { _, symbol in
                Text(symbol)
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.softInk)
                    .frame(maxWidth: .infinity)
            }
        }
    }
}
