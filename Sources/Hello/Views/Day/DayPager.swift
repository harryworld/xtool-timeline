import SwiftUI

struct DayPager: View {
    @Environment(CalendarStore.self) private var store

    /// Page ids are day offsets from today.
    @State private var pos: Int?
    @State private var window = PageWindow(around: 0, chunk: 60, margin: 10)

    private var cal: Calendar { .current }
    private var anchor: Date { cal.startOfDay(for: .now) }

    private func date(_ offset: Int) -> Date {
        cal.date(byAdding: .day, value: offset, to: anchor) ?? anchor
    }

    private func offset(for d: Date) -> Int {
        cal.dateComponents([.day], from: anchor, to: cal.startOfDay(for: d)).day ?? 0
    }

    private func preload(around p: Int) {
        for o in (p - 1)...(p + 1) { store.ensureLoaded(date(o)) }
    }

    /// Swipe settled: commit the selection (no animation) and grow the window far from view.
    private func settle() {
        guard let p = pos else { return }
        withoutAnimation { window.include(p) }
        preload(around: p)
        let d = date(p)
        if d != store.day { store.select(d) }
    }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(window.lower...window.upper, id: \.self) { off in
                    DayPage(day: date(off))
                        .containerRelativeFrame(.horizontal)
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
                let p = offset(for: store.day)
                withoutAnimation {
                    window = PageWindow(around: p, chunk: 60, margin: 10)
                    pos = p
                }
                preload(around: p)
            }
        }
        .onScrollPhaseChange { _, phase in
            if phase == .idle { settle() }
        }
        .onChange(of: store.day) { _, newDay in
            // Only strip taps / Today / week swipes land here with a different page.
            let target = offset(for: newDay)
            guard target != pos else { return }
            withoutAnimation { window.include(target) }
            preload(around: target)
            if let p = pos, abs(target - p) <= 7 {
                withAnimation(.smooth(duration: 0.4)) { pos = target }
            } else {
                withoutAnimation { pos = target }
            }
        }
    }
}

struct DayPage: View {
    @Environment(CalendarStore.self) private var store
    let day: Date

    var body: some View {
        let box = store.box(for: day)
        VStack(spacing: 0) {
            if let ev = box.events, !ev.allDay.isEmpty {
                AllDayStrip(events: ev.allDay)
            }
            ZStack {
                TimelineGrid(events: box.events?.timed ?? [], day: day)
                if let ev = box.events, ev.isEmpty {
                    EmptyStateView(isToday: Calendar.current.isDateInToday(day))
                }
            }
        }
        .task(id: day) { store.ensureLoaded(day) }
    }
}
