import SwiftUI

struct MonthPager: View {
    @Environment(CalendarStore.self) private var store
    let selected: Date
    let frames: BubbleFrames
    let hideSelected: Bool
    let onSelect: (Date) -> Void
    let onTap: (Date) -> Void

    /// Page ids are month offsets from the current month.
    @State private var pos: Int?
    @State private var window = PageWindow(around: 0, chunk: 24, margin: 4)

    private func preload(around p: Int) {
        for o in (p - 1)...(p + 1) {
            let days = MonthIndex.gridDays(ofMonthStarting: MonthIndex.start(of: o))
            if let first = days.first { store.ensureLoaded(from: first, days: days.count) }
        }
    }

    /// A vertical swipe settled: keep the same day of month (clamped) in the new month, no animation.
    private func settle() {
        guard let p = pos else { return }
        withoutAnimation { window.include(p) }
        preload(around: p)
        guard MonthIndex.offset(for: selected) != p else { return }
        onSelect(MonthIndex.sameDay(as: selected, inMonth: p))
    }

    var body: some View {
        let current = MonthIndex.offset(for: selected)
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(window.lower...window.upper, id: \.self) { off in
                    MonthPage(monthStart: MonthIndex.start(of: off), selected: selected, frames: frames,
                              isSelectedMonth: off == current, hideSelected: hideSelected, onTap: onTap)
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
                let p = MonthIndex.offset(for: selected)
                withoutAnimation {
                    window = PageWindow(around: p, chunk: 24, margin: 4)
                    pos = p
                }
                preload(around: p)
            }
        }
        .onScrollPhaseChange { _, phase in
            if phase == .idle { settle() }
        }
        .onChange(of: selected) { _, newDate in
            // Programmatic only (Today, tapping a dimmed day): a settled swipe already put us here.
            let target = MonthIndex.offset(for: newDate)
            guard target != pos else { return }
            withoutAnimation { window.include(target) }
            preload(around: target)
            if let p = pos, abs(target - p) <= 2 {
                withAnimation(.smooth(duration: 0.4)) { pos = target }
            } else {
                withoutAnimation { pos = target }
            }
        }
    }
}
