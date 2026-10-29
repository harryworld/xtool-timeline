import SwiftUI

/// The cute date bubble shared by the week strip (horizontal) and week view (vertical column).
struct DayBubble: View {
    let day: Date
    let selected: Date

    var body: some View {
        let cal = Calendar.current
        let isSel = cal.isDate(day, inSameDayAs: selected)
        let isToday = cal.isDateInToday(day)
        VStack(spacing: 4) {
            Text(day.formatted(.dateTime.weekday(.narrow)))
                .font(.caption2.weight(.bold))
                .foregroundStyle(isSel ? Color.white.opacity(0.95) : (isToday ? Theme.pinkDeep : Theme.softInk))
            Text(day.formatted(.dateTime.day()))
                .font(.title3.weight(isSel || isToday ? .heavy : .semibold).monospacedDigit())
                .foregroundStyle(isSel ? Color.white : (isToday ? Theme.pinkDeep : Theme.ink))
            Image(systemName: "heart.fill")
                .font(.system(size: 8, weight: .bold))
                .foregroundStyle(isSel ? Color.white : Theme.pinkDeep)
                .opacity(isToday ? 1 : 0)
        }
        .padding(.vertical, 8)
        .frame(minWidth: 44)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(isSel
                      ? AnyShapeStyle(LinearGradient(
                            colors: isToday ? [Theme.pinkDeep.pastel(0.15), Theme.pinkDeep.pastel(0.45)]
                                            : [Theme.lavenderDeep.pastel(0.1), Theme.lavenderDeep.pastel(0.45)],
                            startPoint: .top, endPoint: .bottom))
                      : AnyShapeStyle(Color.white.opacity(isToday ? 0.85 : 0.55)))
                .shadow(color: (isToday ? Theme.pinkDeep : Theme.lavenderDeep).opacity(isSel ? 0.35 : 0),
                        radius: 6, y: 3)
        }
        .scaleEffect(isSel ? 1.06 : 1)
        .animation(.spring(response: 0.35, dampingFraction: 0.65), value: isSel)
    }
}

extension View {
    /// Report this bubble's frame for the Day/Week flight, and hide it while the overlay draws it.
    func bubbleSlot(_ day: Date, mode: ViewMode, frames: BubbleFrames, active: Bool, hidden: Bool) -> some View {
        self
            .opacity(active && hidden ? 0 : 1)
            .onGeometryChange(for: CGRect.self) { $0.frame(in: .named(BubbleFrames.space)) } action: { r in
                if active { frames.set(mode, day, r) }
            }
    }
}
