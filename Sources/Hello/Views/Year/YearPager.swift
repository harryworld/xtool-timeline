import SwiftUI

struct YearPager: View {
    @Environment(CalendarStore.self) private var store
    let selected: Date
    let onSelect: (Date) -> Void
    let onOpenMonth: (Date) -> Void

    /// Page ids are year offsets from the current year.
    @State private var pos: Int?
    @State private var window = PageWindow(around: 0, chunk: 10, margin: 3)

    private func preload(around p: Int) {
        for o in (p - 1)...(p + 1) {
            let start = YearIndex.start(of: o)
            store.ensureLoaded(from: start, days: YearIndex.dayCount(ofYearStarting: start))
        }
    }

    /// A vertical swipe settled: keep the same month and day in the new year, no animation.
    private func settle() {
        guard let p = pos else { return }
        withoutAnimation { window.include(p) }
        preload(around: p)
        guard YearIndex.offset(for: selected) != p else { return }
        onSelect(YearIndex.sameDay(as: selected, inYear: p))
    }

    var body: some View {
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(window.lower...window.upper, id: \.self) { off in
                    YearPage(yearStart: YearIndex.start(of: off), onOpenMonth: onOpenMonth)
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
                let p = YearIndex.offset(for: selected)
                withoutAnimation {
                    window = PageWindow(around: p, chunk: 10, margin: 3)
                    pos = p
                }
                preload(around: p)
            }
        }
        .onScrollPhaseChange { _, phase in
            if phase == .idle { settle() }
        }
        .onChange(of: selected) { _, newDate in
            // Programmatic only (Today): a settled swipe already put us here.
            let target = YearIndex.offset(for: newDate)
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
