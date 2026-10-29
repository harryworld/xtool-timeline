import SwiftUI

/// The selected day's events under the month grid; tap to open the day.
struct SelectedDayCards: View {
    let day: Date
    let events: DayEvents?
    let onOpenDay: (Date) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(Theme.pinkDeep)
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.softInk)
            }
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
                        }
                    }
                } else {
                    ProgressView().controlSize(.small)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .frame(height: 52)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.white.opacity(0.6), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 20, style: .continuous).strokeBorder(.white.opacity(0.9), lineWidth: 1))
        .contentShape(Rectangle())
        .onTapGesture { onOpenDay(day) }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)
    }
}
