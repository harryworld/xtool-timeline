import SwiftUI

struct MonthView: View {
    @Environment(CalendarStore.self) private var store
    let selected: Date
    let frames: BubbleFrames
    let hideSelected: Bool
    let onSelect: (Date) -> Void
    let onOpenDay: (Date) -> Void

    var body: some View {
        VStack(spacing: 0) {
            MonthPager(selected: selected, frames: frames, hideSelected: hideSelected,
                       onSelect: onSelect,
                       onTap: { d in
                           if Calendar.current.isDate(d, inSameDayAs: selected) { onOpenDay(d) } else { onSelect(d) }
                       })
            SelectedDayCards(day: selected, events: store.box(for: selected).events, onOpenDay: onOpenDay)
                .task(id: selected) { store.ensureLoaded(selected) }
        }
    }
}
