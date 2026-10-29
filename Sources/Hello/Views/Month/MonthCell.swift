import SwiftUI

struct MonthCell: View {
    static let outsideOpacity = 0.4

    let day: Date
    let selected: Date
    let inMonth: Bool
    let events: DayEvents?
    let frames: BubbleFrames
    let tracksFrame: Bool
    let hidden: Bool
    let onTap: (Date) -> Void

    var body: some View {
        Button { onTap(day) } label: {
            VStack(spacing: 3) {
                DayBubble(day: day, selected: selected, compact: true)
                    .opacity(inMonth ? 1 : Self.outsideOpacity)
                    .bubbleSlot(day, mode: .month, frames: frames, active: tracksFrame, hidden: hidden)
                EventDots(events: events)
                    .opacity(inMonth ? 1 : Self.outsideOpacity)
            }
            .frame(maxWidth: .infinity)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(day.formatted(date: .complete, time: .omitted))
        .accessibilityAddTraits(Calendar.current.isDate(day, inSameDayAs: selected) ? .isSelected : [])
    }
}

struct EventDots: View {
    let events: DayEvents?

    var body: some View {
        let all = (events?.allDay ?? []) + (events?.timed ?? [])
        HStack(spacing: 2) {
            ForEach(all.prefix(3)) { e in
                Circle()
                    .fill(e.color.pastel(0.25))
                    .frame(width: 5, height: 5)
            }
            if all.count > 3 {
                Text("+\(all.count - 3)")
                    .font(.system(size: 8, weight: .bold, design: .rounded))
                    .foregroundStyle(Theme.softInk)
            }
        }
        .frame(height: 8)
    }
}
