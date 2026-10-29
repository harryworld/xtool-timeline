import SwiftUI

struct WeekPager: View {
    let selected: Date
    let frames: BubbleFrames
    let hideSelected: Bool
    let onSelect: (Date) -> Void

    /// Page ids are week offsets from the current week.
    @State private var pos: Int?
    @State private var window = PageWindow(around: 0, chunk: 52, margin: 8)

    /// Called when a user swipe settles: keep the same weekday in the new week (Apple Calendar style).
    private func settle() {
        guard let p = pos else { return }
        withoutAnimation { window.include(p) }
        guard WeekIndex.offset(for: selected) != p else { return }
        if let d = WeekIndex.sameWeekday(as: selected, inWeek: p) {
            onSelect(d)   // no animation: the strip is already there
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(window.lower...window.upper, id: \.self) { off in
                        WeekdayStrip(days: WeekIndex.days(from: WeekIndex.start(of: off)), selected: selected, frames: frames,
                                     isSelectedWeek: off == WeekIndex.offset(for: selected),
                                     hideSelected: hideSelected, onSelect: onSelect)
                            .containerRelativeFrame(.horizontal)
                            .id(off)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollIndicators(.hidden)
            .scrollPosition(id: $pos)
            .frame(height: 84)
        }
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
            // Programmatic only: a settled swipe already put us on this week, so this is a no-op then.
            let target = WeekIndex.offset(for: newDate)
            guard target != pos else { return }
            withoutAnimation { window.include(target) }
            if let p = pos, abs(target - p) <= 3 {
                withAnimation(.smooth(duration: 0.35)) { pos = target }
            } else {
                withoutAnimation { pos = target }
            }
        }
    }
}

struct WeekdayStrip: View {
    let days: [Date]
    let selected: Date
    let frames: BubbleFrames
    /// Only the selected week's bubbles report frames and hand over to the flying overlay.
    let isSelectedWeek: Bool
    let hideSelected: Bool
    let onSelect: (Date) -> Void

    var body: some View {
        HStack(spacing: 6) {
            ForEach(days, id: \.self) { d in
                Button {
                    onSelect(d)   // no ambient animation: it would leak into the pagers' scroll updates
                } label: {
                    DayBubble(day: d, selected: selected)
                        .bubbleSlot(d, mode: .day, frames: frames, active: isSelectedWeek, hidden: hideSelected)
                        .frame(maxWidth: .infinity)
                        .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(d.formatted(date: .complete, time: .omitted))
                .accessibilityAddTraits(Calendar.current.isDate(d, inSameDayAs: selected) ? .isSelected : [])
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
    }
}
