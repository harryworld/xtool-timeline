import SwiftUI

struct WeekAgendaView: View {
    @Environment(CalendarStore.self) private var store
    let selected: Date
    let frames: BubbleFrames
    let hideSelected: Bool
    let onSelect: (Date) -> Void
    let onOpenDay: (Date) -> Void

    /// Page ids are week offsets from the current week.
    @State private var pos: Int?
    @State private var window = PageWindow(around: 0, chunk: 52, margin: 8)

    /// A vertical swipe settled: keep the same weekday in the new week, no animation.
    private func settle() {
        guard let p = pos else { return }
        withoutAnimation { window.include(p) }
        guard WeekIndex.offset(for: selected) != p else { return }
        if let d = WeekIndex.sameWeekday(as: selected, inWeek: p) {
            onSelect(d)
        }
    }

    var body: some View {
        let current = WeekIndex.offset(for: selected)
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(window.lower...window.upper, id: \.self) { off in
                    WeekAgendaPage(weekStart: WeekIndex.start(of: off), selected: selected, frames: frames,
                                   isSelectedWeek: off == current, hideSelected: hideSelected,
                                   onSelect: onSelect, onOpenDay: onOpenDay)
                        .containerRelativeFrame(.vertical)
                        .id(off)
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
        .scrollIndicators(.hidden)
        .scrollPosition(id: $pos)
        .onAppear {
            if pos == nil {
                let p = WeekIndex.offset(for: selected)
                withoutAnimation {
                    window = PageWindow(around: p, chunk: 52, margin: 8)
                    pos = p
                }
            }
        }
        .onScrollPhaseChange { _, phase in
            if phase == .idle { settle() }
        }
        .onChange(of: selected) { _, newDate in
            // Programmatic only (Today): a settled swipe already put us on this week.
            let target = WeekIndex.offset(for: newDate)
            guard target != pos else { return }
            withoutAnimation { window.include(target) }
            if let p = pos, abs(target - p) <= 3 {
                withAnimation(.smooth(duration: 0.4)) { pos = target }
            } else {
                withoutAnimation { pos = target }
            }
        }
    }
}

struct WeekAgendaPage: View {
    @Environment(CalendarStore.self) private var store
    let weekStart: Date
    let selected: Date
    let frames: BubbleFrames
    /// Only the selected week's bubbles report frames and hand over to the flying overlay.
    let isSelectedWeek: Bool
    let hideSelected: Bool
    let onSelect: (Date) -> Void
    let onOpenDay: (Date) -> Void

    private var days: [Date] { WeekIndex.days(from: weekStart) }

    private var rangeTitle: String {
        guard let f = days.first, let l = days.last else { return "" }
        return "\(f.formatted(.dateTime.month(.abbreviated).day())) – \(l.formatted(.dateTime.month(.abbreviated).day()))"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Label(rangeTitle, systemImage: "sparkles")
                .font(.subheadline.weight(.bold))
                .foregroundStyle(Theme.lavenderDeep)
                .padding(.leading, 20)
                .padding(.top, 12)
            VStack(spacing: 6) {
                ForEach(days, id: \.self) { d in
                    WeekRow(day: d, selected: selected, events: store.box(for: d).events,
                            frames: frames, isSelectedWeek: isSelectedWeek, hideSelected: hideSelected,
                            onSelect: onSelect, onOpenDay: onOpenDay)
                        .frame(maxHeight: .infinity)
                        .task(id: d) { store.ensureLoaded(d) }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 8)
        }
    }
}
