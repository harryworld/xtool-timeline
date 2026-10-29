import SwiftUI

struct ContentView: View {
    @Environment(CalendarStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var mode: ViewMode = .initial
    /// Where the selected week's bubbles sit in the strip and in the week column (root coordinates).
    @State private var frames = BubbleFrames()
    /// Non-nil while the selected week's bubbles fly between strip and column in the overlay.
    @State private var flight: BubbleFlight?
    @State private var flyToken = 0

    private func setMode(_ m: ViewMode) {
        guard m != mode else { return }
        flyToken += 1
        let token = flyToken
        let days = WeekIndex.days(ofWeekContaining: store.day)
        let from = flight?.frames ?? frames.snapshot(mode, days)
        frames.clear(m)
        let canFly = store.access == .granted && from.count == days.count
        // The overlay takes over the bubbles (in-pager ones hide) before anything moves.
        let fromMode = flight?.shownMode ?? mode
        withoutAnimation {
            flight = canFly ? BubbleFlight(days: days, fromMode: fromMode, toMode: m, from: from) : nil
        }
        withAnimation(.easeInOut(duration: 0.3)) { mode = m }
        guard canFly else { return }
        Task { @MainActor in
            // Wait until the incoming strip/column has laid out the week and its frames are stable.
            var to: [Date: CGRect] = [:]
            for _ in 0..<40 {
                try? await Task.sleep(for: .milliseconds(16))
                guard token == flyToken else { return }
                let now = frames.snapshot(m, days)
                if now.count == days.count && now == to { break }
                to = now
            }
            guard token == flyToken, to.count == days.count else {
                if token == flyToken { withoutAnimation { flight = nil } }
                return
            }
            withoutAnimation { flight?.to = to }
            withAnimation(.spring(response: 0.5, dampingFraction: 0.82)) {
                flight?.arrived = true
            } completion: {
                // Hand back to the in-pager bubbles, which are already at these frames.
                if token == flyToken { withoutAnimation { flight = nil } }
            }
        }
    }

    private func openDay(_ d: Date) {
        store.select(d)
        setMode(.day)
    }

    private func openMonth(_ monthStart: Date) {
        store.select(YearIndex.dayToOpen(month: monthStart, selected: store.day))
        setMode(.month)
    }

    /// Today is disabled on today, or in Year view anywhere in the current year.
    private var atToday: Bool {
        mode == .year ? YearIndex.offset(for: store.day) == 0 : store.isToday
    }

    var body: some View {
        VStack(spacing: 0) {
            HeaderView(day: store.day, count: store.allDay.count + store.timed.count,
                       showCount: store.access == .granted)
            if mode == .day {
                WeekPager(selected: store.day, frames: frames, hideSelected: flight != nil) { store.select($0) }
                    .transition(.opacity)
            }
            switch store.access {
            case .unknown, .requesting:
                LoadingView()
            case .denied, .restricted:
                AccessDeniedView(restricted: store.access == .restricted)
            case .granted:
                Group {
                    switch mode {
                    case .day:
                        DayPager()
                            .transition(.opacity)
                    case .week:
                        WeekAgendaView(selected: store.day, frames: frames, hideSelected: flight != nil,
                                       onSelect: { store.select($0) }, onOpenDay: openDay)
                    case .month:
                        MonthView(selected: store.day, frames: frames, hideSelected: flight != nil,
                                  onSelect: { store.select($0) }, onOpenDay: openDay)
                    case .year:
                        YearView(selected: store.day, onSelect: { store.select($0) }, onOpenMonth: openMonth)
                    }
                }
                .background(
                    UnevenRoundedRectangle(topLeadingRadius: 28, topTrailingRadius: 28, style: .continuous)
                        .fill(.white.opacity(0.55))
                        .shadow(color: Theme.pinkDeep.opacity(0.08), radius: 10, y: -2)
                        .ignoresSafeArea(edges: .bottom)
                )
            }
        }
        .coordinateSpace(.named(BubbleFrames.space))
        .overlay(alignment: .topLeading) {
            if let f = flight {
                FlyingBubbles(flight: f, selected: store.day)
            }
        }
        .foregroundStyle(Theme.ink)
        .fontDesign(.rounded)
        .background(Theme.background.ignoresSafeArea())
        .tint(Theme.pinkDeep)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            BottomBar(isToday: atToday, mode: mode,
                      onToday: { store.select(.now) },
                      onMode: { setMode($0) })
        }
        .task { await store.start() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refreshIfNeeded() }
        }
    }
}
