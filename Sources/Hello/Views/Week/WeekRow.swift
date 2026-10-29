import SwiftUI

struct WeekRow: View {
    let day: Date
    let selected: Date
    let events: DayEvents?
    let frames: BubbleFrames
    let isSelectedWeek: Bool
    let hideSelected: Bool
    let onSelect: (Date) -> Void
    let onOpenDay: (Date) -> Void

    var body: some View {
        HStack(spacing: 10) {
            Button { onSelect(day) } label: {
                DayBubble(day: day, selected: selected)
                    .bubbleSlot(day, mode: .week, frames: frames, active: isSelectedWeek, hidden: hideSelected)
                    .frame(width: 52)
            }
            .buttonStyle(.plain)
            .accessibilityLabel(day.formatted(date: .complete, time: .omitted))

            Group {
                if let ev = events {
                    if ev.isEmpty {
                        Text(Calendar.current.isDateInToday(day) ? "Free today ✿" : "Free ✿")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(Theme.softInk.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .leading)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 6) {
                                ForEach(ev.allDay) { e in WeekCard(event: e, allDay: true) }
                                ForEach(ev.timed) { e in WeekCard(event: e, allDay: false) }
                            }
                            .padding(.vertical, 4)
                            .padding(.trailing, 8)
                        }
                    }
                } else {
                    ProgressView().controlSize(.small)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .contentShape(Rectangle())
            .onTapGesture { onOpenDay(day) }
            .transition(.opacity)
        }
        .padding(.vertical, 2)
    }
}

struct WeekCard: View {
    let event: TimelineEvent
    let allDay: Bool

    var body: some View {
        HStack(spacing: 6) {
            Text(EventEmoji.for_(event.title)).font(.subheadline)
            VStack(alignment: .leading, spacing: 1) {
                Text(event.title)
                    .font(.caption.weight(.bold))
                    .lineLimit(1)
                Text(allDay ? "all day" : event.start.formatted(date: .omitted, time: .shortened))
                    .font(.caption2.weight(.medium).monospacedDigit())
                    .foregroundStyle(Theme.softInk)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: 170, alignment: .leading)
        .background(
            LinearGradient(colors: [event.color.pastel(0.68), event.color.pastel(0.82)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 14, style: .continuous)
        )
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).strokeBorder(.white.opacity(0.9), lineWidth: 1.5))
        .shadow(color: event.color.opacity(0.18), radius: 4, y: 2)
    }
}
