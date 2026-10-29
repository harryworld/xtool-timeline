import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Theme

enum Theme {
    static let cream = Color(red: 1.00, green: 0.97, blue: 0.94)
    static let blush = Color(red: 1.00, green: 0.92, blue: 0.94)
    static let pink = Color(red: 1.00, green: 0.80, blue: 0.86)
    static let pinkDeep = Color(red: 0.91, green: 0.36, blue: 0.56)
    static let peach = Color(red: 1.00, green: 0.86, blue: 0.76)
    static let lavender = Color(red: 0.88, green: 0.84, blue: 1.00)
    static let lavenderDeep = Color(red: 0.55, green: 0.45, blue: 0.85)
    static let mint = Color(red: 0.80, green: 0.95, blue: 0.88)
    static let baby = Color(red: 0.80, green: 0.90, blue: 1.00)
    static let ink = Color(red: 0.33, green: 0.25, blue: 0.36)
    static let softInk = Color(red: 0.58, green: 0.48, blue: 0.60)

    static let background = LinearGradient(
        colors: [cream, blush, lavender.opacity(0.55)],
        startPoint: .top, endPoint: .bottom
    )
}

extension Color {
    /// Mix toward white by `amount` (0 = original, 1 = white).
    func pastel(_ amount: Double) -> Color {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return self.opacity(1 - amount) }
        let t = CGFloat(amount)
        return Color(red: Double(r + (1 - r) * t), green: Double(g + (1 - g) * t), blue: Double(b + (1 - b) * t))
        #else
        return self.opacity(1 - amount)
        #endif
    }
}

enum EventEmoji {
    static func for_(_ title: String) -> String {
        let t = title.lowercased()
        func has(_ words: [String]) -> Bool { words.contains { t.contains($0) } }
        if has(["birthday", "生日", "bday"]) { return "🎂" }
        if has(["dinner", "lunch", "breakfast", "brunch", "food", "meal", "飯", "餐", "食"]) { return "🍽️" }
        if has(["coding", "code", "dev", "hack", "swift", "ios", "app", "程式"]) { return "💻" }
        if has(["class", "班", "課", "lesson", "course", "study", "學"]) { return "📚" }
        if has(["meeting", "sync", "call", "1:1", "standup", "會議", "chat"]) { return "💬" }
        if has(["gym", "run", "yoga", "workout", "運動"]) { return "🏃" }
        if has(["flight", "trip", "travel"]) { return "✈️" }
        if has(["coffee", "咖啡", "tea"]) { return "☕️" }
        return "✨"
    }
}

enum ViewMode: String, CaseIterable { case day = "Day", week = "Week" }

struct ContentView: View {
    @Environment(CalendarStore.self) private var store
    @Environment(\.scenePhase) private var scenePhase
    @State private var mode: ViewMode = .day
    /// Where the selected week's bubbles sit in the strip and in the week column (root coordinates).
    @State private var frames = BubbleFrames()
    /// Non-nil while the selected week's bubbles fly between strip and column in the overlay.
    @State private var flight: BubbleFlight?
    @State private var flyToken = 0

    private func setMode(_ m: ViewMode) {
        guard m != mode else { return }
        flyToken += 1
        let token = flyToken
        let days = BubbleFrames.week(of: store.day)
        let from = flight.map { $0.arrived ? $0.to : $0.from } ?? frames.snapshot(mode, days)
        frames.clear(m)
        let canFly = store.access == .granted && from.count == days.count
        // The overlay takes over the bubbles (in-pager ones hide) before anything moves.
        withoutAnimation { flight = canFly ? BubbleFlight(days: days, from: from) : nil }
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
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "heart.circle.fill")
                        .font(.system(size: 44))
                        .foregroundStyle(Theme.pinkDeep, Theme.pink)
                        .symbolEffect(.pulse)
                    Text("Peeking at your calendar…")
                        .font(.headline)
                        .foregroundStyle(Theme.softInk)
                }
                Spacer()
            case .denied, .restricted:
                AccessDeniedView(restricted: store.access == .restricted)
            case .granted:
                Group {
                    if mode == .day {
                        DayPager()
                            .transition(.opacity)
                    } else {
                        WeekAgendaView(selected: store.day, frames: frames, hideSelected: flight != nil,
                                       onSelect: { store.select($0) },
                                       onOpenDay: { store.select($0); setMode(.day) })
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
            BottomBar(isToday: store.isToday, mode: mode,
                      onToday: { store.select(.now) },
                      onMode: { setMode($0) })
        }
        .task { await store.start() }
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refreshIfNeeded() }
        }
    }
}

// MARK: - Bottom toolbar

struct BottomBar: View {
    let isToday: Bool
    let mode: ViewMode
    let onToday: () -> Void
    let onMode: (ViewMode) -> Void
    @Namespace private var seg

    var body: some View {
        HStack {
            Button {
                onToday()   // the pagers decide how to animate their own scroll
            } label: {
                Label("Today", systemImage: "heart.fill")
                    .font(.body.weight(.bold))
                    .foregroundStyle(isToday ? Theme.softInk.opacity(0.7) : Theme.pinkDeep)
                    .symbolEffect(.bounce, value: isToday)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(.regularMaterial, in: Capsule())
                    .background(Theme.pink.opacity(isToday ? 0.12 : 0.45), in: Capsule())
                    .overlay(Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 1))
                    .shadow(color: Theme.pinkDeep.opacity(isToday ? 0.04 : 0.22), radius: isToday ? 4 : 9, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(isToday)
            .opacity(isToday ? 0.6 : 1)
            .scaleEffect(isToday ? 0.94 : 1)
            .animation(.spring(response: 0.38, dampingFraction: 0.72), value: isToday)
            .accessibilityHint("Jump to today")
            Spacer()
            ModeToggle(mode: mode, seg: seg, onMode: onMode)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }
}

struct ModeToggle: View {
    let mode: ViewMode
    let seg: Namespace.ID
    let onMode: (ViewMode) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(ViewMode.allCases, id: \.self) { m in
                let on = m == mode
                Button { onMode(m) } label: {
                    Label(m.rawValue, systemImage: m == .day ? "sun.max.fill" : "list.bullet.below.rectangle")
                        .labelStyle(.titleAndIcon)
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(on ? Color.white : Theme.lavenderDeep)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 9)
                        .background {
                            if on {
                                Capsule()
                                    .fill(LinearGradient(colors: [Theme.lavenderDeep.pastel(0.1), Theme.lavenderDeep.pastel(0.4)],
                                                         startPoint: .top, endPoint: .bottom))
                                    .matchedGeometryEffect(id: "seg", in: seg)
                                    .shadow(color: Theme.lavenderDeep.opacity(0.3), radius: 5, y: 2)
                            }
                        }
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .background(.regularMaterial, in: Capsule())
        .background(Theme.lavender.opacity(0.4), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 1))
        .shadow(color: Theme.lavenderDeep.opacity(0.15), radius: 8, y: 3)
    }
}

// MARK: - Header

struct HeaderView: View {
    let day: Date
    let count: Int
    let showCount: Bool

    var body: some View {
        HStack(alignment: .bottom) {
            VStack(alignment: .leading, spacing: 6) {
                Text(day.formatted(.dateTime.weekday(.wide)))
                    .font(.caption.weight(.heavy))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        LinearGradient(colors: [Theme.pinkDeep.opacity(0.85), Theme.pinkDeep.pastel(0.25)],
                                       startPoint: .leading, endPoint: .trailing),
                        in: Capsule()
                    )
                Text(day.formatted(.dateTime.month(.abbreviated).day().year()))
                    .font(.system(.largeTitle, design: .rounded).weight(.heavy))
                    .foregroundStyle(Theme.ink)
                    .contentTransition(.numericText())
                    .animation(.spring(response: 0.4, dampingFraction: 0.8), value: day)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    Text("Timeline")
                    Image(systemName: "sparkles")
                        .foregroundStyle(Theme.lavenderDeep)
                }
                .font(.headline.weight(.bold))
                if showCount {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                        Text(count == 1 ? "1 event" : "\(count) events")
                            .font(.caption.weight(.bold))
                            .contentTransition(.numericText())
                    }
                    .foregroundStyle(Theme.lavenderDeep)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Theme.lavender, in: Capsule())
                    .overlay(Capsule().strokeBorder(.white, lineWidth: 1.5))
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 12)
    }
}

// MARK: - Shared paging helpers

/// Run a state change with animations explicitly disabled, overriding any inherited transaction.
@MainActor
func withoutAnimation(_ body: () -> Void) {
    var t = Transaction(animation: nil)
    t.disablesAnimations = true
    withTransaction(t, body)
}

/// Grow a page window on settle only, far from the visible page, so nothing shifts mid-gesture.
struct PageWindow: Equatable {
    var lower: Int
    var upper: Int
    let chunk: Int
    let margin: Int

    init(around p: Int, chunk: Int, margin: Int) {
        self.chunk = chunk; self.margin = margin
        lower = p - chunk; upper = p + chunk
    }

    mutating func include(_ p: Int) {
        if p - lower < margin { lower = p - chunk }
        if upper - p < margin { upper = p + chunk }
    }
}

// MARK: - Week pager (infinite, one week per page)

struct WeekPager: View {
    let selected: Date
    let frames: BubbleFrames
    let hideSelected: Bool
    let onSelect: (Date) -> Void

    /// Page ids are week offsets from the current week.
    @State private var pos: Int?
    @State private var window = PageWindow(around: 0, chunk: 52, margin: 8)

    private var cal: Calendar { .current }

    private var anchor: Date {
        cal.dateInterval(of: .weekOfYear, for: .now)?.start ?? cal.startOfDay(for: .now)
    }

    private func weekStart(_ offset: Int) -> Date {
        cal.date(byAdding: .day, value: offset * 7, to: anchor) ?? anchor
    }

    private func days(_ offset: Int) -> [Date] {
        let start = weekStart(offset)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    private func offset(for date: Date) -> Int {
        let ws = cal.dateInterval(of: .weekOfYear, for: date)?.start ?? cal.startOfDay(for: date)
        let d = cal.dateComponents([.day], from: anchor, to: ws).day ?? 0
        return Int((Double(d) / 7).rounded())
    }

    /// Called when a user swipe settles: keep the same weekday in the new week (Apple Calendar style).
    private func settle() {
        guard let p = pos else { return }
        withoutAnimation { window.include(p) }
        let current = offset(for: selected)
        guard current != p else { return }
        let dayIndex = cal.dateComponents([.day], from: weekStart(current), to: cal.startOfDay(for: selected)).day ?? 0
        if let d = cal.date(byAdding: .day, value: dayIndex, to: weekStart(p)) {
            onSelect(d)   // no animation: the strip is already there
        }
    }

    var body: some View {
        VStack(spacing: 4) {
            ScrollView(.horizontal) {
                LazyHStack(spacing: 0) {
                    ForEach(window.lower...window.upper, id: \.self) { off in
                        WeekdayStrip(days: days(off), selected: selected, frames: frames,
                                     isSelectedWeek: off == offset(for: selected),
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
                let p = offset(for: selected)
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
            let target = offset(for: newDate)
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

// MARK: - Day pager (infinite, one day per page)

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

// MARK: - Weekday selector

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

/// Plain (non-observed) frame registry: written on every layout/scroll without re-rendering anything.
@MainActor
final class BubbleFrames {
    static let space = "timelineRoot"
    private var strip: [Date: CGRect] = [:]
    private var column: [Date: CGRect] = [:]

    static func week(of date: Date) -> [Date] {
        let cal = Calendar.current
        let start = cal.dateInterval(of: .weekOfYear, for: date)?.start ?? cal.startOfDay(for: date)
        return (0..<7).compactMap { cal.date(byAdding: .day, value: $0, to: start) }
    }

    func set(_ mode: ViewMode, _ day: Date, _ r: CGRect) {
        let k = Calendar.current.startOfDay(for: day)
        if mode == .day { strip[k] = r } else { column[k] = r }
    }

    func clear(_ mode: ViewMode) {
        if mode == .day { strip = [:] } else { column = [:] }
    }

    func snapshot(_ mode: ViewMode, _ days: [Date]) -> [Date: CGRect] {
        let src = mode == .day ? strip : column
        var out: [Date: CGRect] = [:]
        for d in days {
            let k = Calendar.current.startOfDay(for: d)
            if let r = src[k], r.width > 0 { out[k] = r }
        }
        return out
    }
}

struct BubbleFlight: Equatable {
    let days: [Date]
    let from: [Date: CGRect]
    var to: [Date: CGRect] = [:]
    var arrived = false
}

/// The selected week's bubbles drawn once, above all scroll views, flying strip <-> column.
struct FlyingBubbles: View {
    let flight: BubbleFlight
    let selected: Date

    var body: some View {
        ZStack(alignment: .topLeading) {
            ForEach(flight.days, id: \.self) { d in
                let k = Calendar.current.startOfDay(for: d)
                if let r = (flight.arrived ? flight.to[k] : nil) ?? flight.from[k] {
                    DayBubble(day: d, selected: selected)
                        .frame(width: r.width, height: r.height)
                        .position(x: r.midX, y: r.midY)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}

// MARK: - Week agenda view

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

    private var cal: Calendar { .current }

    private var anchor: Date {
        cal.dateInterval(of: .weekOfYear, for: .now)?.start ?? cal.startOfDay(for: .now)
    }

    private func weekStart(_ offset: Int) -> Date {
        cal.date(byAdding: .day, value: offset * 7, to: anchor) ?? anchor
    }

    private func offset(for date: Date) -> Int {
        let ws = cal.dateInterval(of: .weekOfYear, for: date)?.start ?? cal.startOfDay(for: date)
        let d = cal.dateComponents([.day], from: anchor, to: ws).day ?? 0
        return Int((Double(d) / 7).rounded())
    }

    /// A vertical swipe settled: keep the same weekday in the new week, no animation.
    private func settle() {
        guard let p = pos else { return }
        withoutAnimation { window.include(p) }
        let current = offset(for: selected)
        guard current != p else { return }
        let dayIndex = cal.dateComponents([.day], from: weekStart(current), to: cal.startOfDay(for: selected)).day ?? 0
        if let d = cal.date(byAdding: .day, value: dayIndex, to: weekStart(p)) {
            onSelect(d)
        }
    }

    var body: some View {
        let current = offset(for: selected)
        ScrollView(.vertical) {
            LazyVStack(spacing: 0) {
                ForEach(window.lower...window.upper, id: \.self) { off in
                    WeekAgendaPage(weekStart: weekStart(off), selected: selected, frames: frames,
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
                let p = offset(for: selected)
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
            let target = offset(for: newDate)
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

    private var days: [Date] {
        (0..<7).compactMap { Calendar.current.date(byAdding: .day, value: $0, to: weekStart) }
    }

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

// MARK: - All-day

struct AllDayStrip: View {
    let events: [TimelineEvent]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                Label("all day", systemImage: "sun.max.fill")
                    .font(.caption2.weight(.bold))
                    .foregroundStyle(Theme.softInk)
                ForEach(events) { e in
                    HStack(spacing: 5) {
                        Text(EventEmoji.for_(e.title))
                            .font(.caption)
                        Text(e.title)
                            .font(.caption.weight(.bold))
                            .lineLimit(1)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(e.color.pastel(0.72), in: Capsule())
                    .overlay(Capsule().strokeBorder(.white, lineWidth: 1.5))
                    .shadow(color: e.color.opacity(0.18), radius: 4, y: 2)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Timeline

struct PlacedEvent: Identifiable {
    let event: TimelineEvent
    let column: Int
    let columns: Int
    var id: String { event.id }
}

enum OverlapLayout {
    static func place(_ events: [TimelineEvent]) -> [PlacedEvent] {
        let sorted = events.sorted { ($0.start, $1.end) < ($1.start, $0.end) }
        var result: [PlacedEvent] = []
        var cluster: [(TimelineEvent, Int)] = []
        var columnEnds: [Date] = []
        var clusterEnd = Date.distantPast

        func flush() {
            let n = max(columnEnds.count, 1)
            result += cluster.map { PlacedEvent(event: $0.0, column: $0.1, columns: n) }
            cluster.removeAll()
            columnEnds.removeAll()
        }

        for e in sorted {
            // Treat very short events as at least 20 minutes for overlap purposes.
            let effEnd = max(e.end, e.start.addingTimeInterval(20 * 60))
            if !cluster.isEmpty && e.start >= clusterEnd { flush() }
            if let col = columnEnds.firstIndex(where: { $0 <= e.start }) {
                columnEnds[col] = effEnd
                cluster.append((e, col))
            } else {
                columnEnds.append(effEnd)
                cluster.append((e, columnEnds.count - 1))
            }
            clusterEnd = cluster.isEmpty ? effEnd : max(clusterEnd, effEnd)
        }
        flush()
        return result
    }
}

struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}

struct TimelineGrid: View {
    let events: [TimelineEvent]
    let day: Date

    private let hourHeight: CGFloat = 64
    private let labelWidth: CGFloat = 70
    private let topInset: CGFloat = 16

    var body: some View {
        let isToday = Calendar.current.isDateInToday(day)
        let placed = OverlapLayout.place(events)

        ScrollViewReader { proxy in
            ScrollView {
                ZStack(alignment: .topLeading) {
                    // Hour grid + scroll anchors
                    VStack(spacing: 0) {
                        ForEach(0...24, id: \.self) { h in
                            HStack(alignment: .center, spacing: 6) {
                                Text(hourLabel(h))
                                    .font(.caption2.weight(.semibold).monospacedDigit())
                                    .foregroundStyle(Theme.lavenderDeep.opacity(0.6))
                                    .frame(width: labelWidth - 6, alignment: .trailing)
                                DottedLine()
                                    .stroke(Theme.lavenderDeep.opacity(0.22),
                                            style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [1, 5]))
                                    .frame(height: 1)
                            }
                            .frame(height: h == 24 ? 1 : hourHeight, alignment: .top)
                            .offset(y: -7)
                            .id(h)
                        }
                    }
                    .padding(.top, topInset)

                    // Events
                    GeometryReader { geo in
                        let width = geo.size.width - labelWidth - 10
                        ForEach(placed) { p in
                            let y = yFor(p.event.start, day: day)
                            let h = max(yFor(p.event.end, day: day) - y, 24)
                            let colW = width / CGFloat(p.columns)
                            EventBlock(event: p.event, height: h)
                                .frame(width: colW - 4, height: h - 3)
                                .offset(x: labelWidth + CGFloat(p.column) * colW, y: y + 1.5)
                        }
                    }
                    .frame(height: topInset + hourHeight * 24)

                    // Current time line (today only)
                    if isToday {
                    TimelineView(.periodic(from: .now, by: 30)) { ctx in
                        let y = yFor(ctx.date, day: day)
                        HStack(spacing: 2) {
                            Text(ctx.date.formatted(date: .omitted, time: .shortened))
                                .font(.system(size: 10, weight: .heavy, design: .rounded).monospacedDigit())
                                .foregroundStyle(.white)
                                .padding(.horizontal, 5)
                                .padding(.vertical, 2)
                                .background(Theme.pinkDeep, in: Capsule())
                                .fixedSize()
                                .frame(width: labelWidth - 2, alignment: .trailing)
                            Image(systemName: "heart.fill")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundStyle(Theme.pinkDeep)
                            Capsule()
                                .fill(LinearGradient(colors: [Theme.pinkDeep, Theme.pink],
                                                     startPoint: .leading, endPoint: .trailing))
                                .frame(height: 3)
                        }
                        .offset(y: y - 9)
                        .shadow(color: Theme.pinkDeep.opacity(0.25), radius: 3, y: 1)
                        .allowsHitTesting(false)
                    }
                    .frame(height: topInset + hourHeight * 24, alignment: .top)
                    }
                }
                .padding(.trailing, 10)
                .padding(.bottom, 32)
            }
            .onAppear { scroll(proxy, day: day) }
            .onChange(of: events.count) { _, _ in scroll(proxy, day: day) }
        }
    }

    private func scroll(_ proxy: ScrollViewProxy, day: Date) {
        let cal = Calendar.current
        let first = events.map(\.start).min()
        var target: Int
        if cal.isDateInToday(day) {
            target = cal.component(.hour, from: .now)
            // If nothing is left today but there were earlier events, show the first one instead.
            if let first, events.allSatisfy({ $0.end < .now }) {
                target = cal.component(.hour, from: first)
            }
        } else {
            target = first.map { cal.component(.hour, from: $0) } ?? 8
        }
        target = max(0, min(23, target - 1))
        DispatchQueue.main.async {
            withAnimation(.easeInOut) { proxy.scrollTo(target, anchor: .top) }
        }
    }

    private func yFor(_ date: Date, day: Date) -> CGFloat {
        let minutes = date.timeIntervalSince(day) / 60
        return topInset + CGFloat(max(0, min(minutes, 1440))) / 60 * hourHeight
    }

    private func hourLabel(_ h: Int) -> String {
        String(format: "%02d:00", h)
    }
}

struct EventBlock: View {
    let event: TimelineEvent
    let height: CGFloat

    var body: some View {
        let shape = RoundedRectangle(cornerRadius: 14, style: .continuous)
        HStack(alignment: .top, spacing: 6) {
            Text(EventEmoji.for_(event.title))
                .font(.system(size: height > 40 ? 15 : 11))
            VStack(alignment: .leading, spacing: 2) {
                Text(event.title)
                    .font(.caption.weight(.bold))
                    .foregroundStyle(Theme.ink)
                    .lineLimit(height > 60 ? 2 : 1)
                if height > 38 {
                    Text(timeRange)
                        .font(.caption2.weight(.medium).monospacedDigit())
                        .foregroundStyle(Theme.softInk)
                        .lineLimit(1)
                }
                if height > 58, let loc = event.location {
                    Label(loc, systemImage: "mappin.circle.fill")
                        .font(.caption2.weight(.medium))
                        .foregroundStyle(Theme.softInk)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, height > 30 ? 6 : 2)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(
            LinearGradient(colors: [event.color.pastel(0.68), event.color.pastel(0.82)],
                           startPoint: .topLeading, endPoint: .bottomTrailing),
            in: shape
        )
        .overlay(shape.strokeBorder(.white.opacity(0.9), lineWidth: 1.5))
        .overlay(alignment: .leading) {
            Capsule()
                .fill(event.color.pastel(0.25))
                .frame(width: 4)
                .padding(.vertical, 8)
                .padding(.leading, 3)
        }
        .shadow(color: event.color.opacity(0.22), radius: 6, y: 3)
    }

    private var timeRange: String {
        let f = Date.FormatStyle(date: .omitted, time: .shortened)
        return "\(event.start.formatted(f)) – \(event.end.formatted(f))"
    }
}

// MARK: - States

struct EmptyStateView: View {
    var isToday: Bool = true
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Theme.peach, Theme.pink], startPoint: .top, endPoint: .bottom))
                    .frame(width: 96, height: 96)
                Image(systemName: isToday ? "cloud.sun.fill" : "moon.stars.fill")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(.white, Theme.pinkDeep.pastel(0.2))
                    .font(.system(size: 44))
                Image(systemName: "sparkle")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(Theme.lavenderDeep)
                    .offset(x: 48, y: -38)
                Image(systemName: "heart.fill")
                    .font(.system(size: 12))
                    .foregroundStyle(Theme.pinkDeep.pastel(0.3))
                    .offset(x: -46, y: 34)
            }
            Text(isToday ? "Nothing planned — enjoy your day! 🌸" : "Nothing planned here 🌷")
                .font(.headline.weight(.bold))
                .multilineTextAlignment(.center)
            Text(isToday ? "A perfect day for a little treat." : "A cozy, wide-open day.")
                .font(.subheadline)
                .foregroundStyle(Theme.softInk)
        }
        .padding(28)
        .background(.white.opacity(0.75), in: RoundedRectangle(cornerRadius: 28, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 28, style: .continuous).strokeBorder(Theme.pink, lineWidth: 1.5))
        .shadow(color: Theme.pinkDeep.opacity(0.12), radius: 12, y: 4)
        .padding(.horizontal, 24)
        .allowsHitTesting(false)
    }
}

struct AccessDeniedView: View {
    let restricted: Bool

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Theme.lavender, Theme.pink], startPoint: .top, endPoint: .bottom))
                    .frame(width: 110, height: 110)
                Image(systemName: "calendar.badge.exclamationmark")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Theme.pinkDeep, .white)
                    .font(.system(size: 50))
            }
            Text("Can I peek at your calendar? 🥺")
                .font(.title3.weight(.heavy))
                .multilineTextAlignment(.center)
            Text(restricted
                 ? "Calendar access is restricted on this device, so I can't show your events."
                 : "Timeline needs full calendar access to draw your day. Turn it on in Settings › Timeline › Calendars.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.softInk)
                .padding(.horizontal, 36)
            if !restricted {
                Button {
                    #if canImport(UIKit)
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    #endif
                } label: {
                    Label("Open Settings", systemImage: "heart.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [Theme.pinkDeep, Theme.pinkDeep.pastel(0.35)],
                                           startPoint: .leading, endPoint: .trailing),
                            in: Capsule()
                        )
                        .shadow(color: Theme.pinkDeep.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}
