import EventKit
import SwiftUI
import Observation

struct TimelineEvent: Identifiable, Hashable, Sendable {
    let id: String
    let title: String
    let start: Date
    let end: Date
    let location: String?
    let color: Color
    let calendarName: String
    let isAllDay: Bool
}

struct DayEvents: Equatable, Sendable {
    var allDay: [TimelineEvent] = []
    var timed: [TimelineEvent] = []
    var isEmpty: Bool { allDay.isEmpty && timed.isEmpty }
}

/// Observable per-day holder so a page only re-renders when its own day loads.
@MainActor
@Observable
final class DayBox {
    var events: DayEvents?
    @ObservationIgnored var loading = false
}

struct StoreRef: @unchecked Sendable { let ek: EKEventStore }

@MainActor
@Observable
final class CalendarStore {
    enum Access: Equatable {
        case unknown, requesting, granted, denied, restricted
    }

    var access: Access = .unknown
    /// Selected day (start of day).
    var day: Date = Calendar.current.startOfDay(for: .now)
    @ObservationIgnored private var boxes: [Date: DayBox] = [:]

    var allDay: [TimelineEvent] { box(for: day).events?.allDay ?? [] }
    var timed: [TimelineEvent] { box(for: day).events?.timed ?? [] }
    var isToday: Bool { Calendar.current.isDateInToday(day) }

    @ObservationIgnored private let store = EKEventStore()
    @ObservationIgnored private var observer: NSObjectProtocol?

    init() {
        observer = NotificationCenter.default.addObserver(
            forName: .EKEventStoreChanged, object: store, queue: .main
        ) { [weak self] _ in
            Task { @MainActor in self?.reloadAll() }
        }
    }

    func start() async {
        switch EKEventStore.authorizationStatus(for: .event) {
        case .fullAccess:
            access = .granted
            reloadAll()
        case .denied, .writeOnly:
            access = .denied
        case .restricted:
            access = .restricted
        default:
            access = .requesting
            do {
                let ok = try await store.requestFullAccessToEvents()
                access = ok ? .granted : .denied
                if ok { reloadAll() }
            } catch {
                access = .denied
            }
        }
    }

    func refreshIfNeeded() {
        if EKEventStore.authorizationStatus(for: .event) == .fullAccess {
            if access != .granted { access = .granted }
            reloadAll()
        }
    }

    func select(_ date: Date) {
        let d = Calendar.current.startOfDay(for: date)
        ensureLoaded(d)
        if d != day { day = d }
    }

    func box(for d: Date) -> DayBox {
        let key = Calendar.current.startOfDay(for: d)
        if let b = boxes[key] { return b }
        let b = DayBox()
        boxes[key] = b
        return b
    }

    /// Fetch off the main thread; the page updates when its box fills.
    func ensureLoaded(_ d: Date) {
        guard access == .granted else { return }
        let b = box(for: d)
        guard b.events == nil, !b.loading else { return }
        let key = Calendar.current.startOfDay(for: d)
        load(from: key, through: key)
    }

    /// Load every not-yet-loaded day in `days` consecutive days from `start` with one EventKit query.
    func ensureLoaded(from start: Date, days count: Int) {
        guard access == .granted else { return }
        let cal = Calendar.current
        let first = cal.startOfDay(for: start)
        let pending = (0..<count)
            .compactMap { cal.date(byAdding: .day, value: $0, to: first) }
            .filter { let b = box(for: $0); return b.events == nil && !b.loading }
        guard let lo = pending.first, let hi = pending.last else { return }
        load(from: lo, through: hi)
    }

    private func load(from first: Date, through last: Date) {
        let cal = Calendar.current
        let days = (0...(cal.dateComponents([.day], from: first, to: last).day ?? 0))
            .compactMap { cal.date(byAdding: .day, value: $0, to: first) }
        for d in days { box(for: d).loading = true }
        let ref = StoreRef(ek: store)
        Task.detached(priority: .userInitiated) {
            let result = CalendarStore.fetch(ref, days: days)
            await MainActor.run { [weak self] in
                guard let self else { return }
                for d in days {
                    let b = self.box(for: d)
                    let ev = result[d] ?? DayEvents()
                    if b.events != ev { b.events = ev }
                    b.loading = false
                }
            }
        }
    }

    /// Re-fetch every loaded day, one query per run of consecutive days.
    func reloadAll() {
        guard access == .granted else { return }
        _ = box(for: day)
        let cal = Calendar.current
        let keys = boxes.filter { $0.value.events != nil || $0.key == day }.keys.sorted()
        var runStart: Date?
        var prev: Date?
        for k in keys {
            if let p = prev, let next = cal.date(byAdding: .day, value: 1, to: p), next == k {
                prev = k
                continue
            }
            if let s = runStart, let p = prev { load(from: s, through: p) }
            runStart = k
            prev = k
        }
        if let s = runStart, let p = prev { load(from: s, through: p) }
    }

    /// One query for the whole range, split into per-day buckets (events spanning days appear on each).
    nonisolated static func fetch(_ ref: StoreRef, days: [Date]) -> [Date: DayEvents] {
        let cal = Calendar.current
        guard let first = days.first, let last = days.last,
              let rangeEnd = cal.date(byAdding: .day, value: 1, to: last) else { return [:] }
        let predicate = ref.ek.predicateForEvents(withStart: first, end: rangeEnd, calendars: nil)
        let events = ref.ek.events(matching: predicate)
        var out: [Date: DayEvents] = [:]
        for day in days {
            guard let end = cal.date(byAdding: .day, value: 1, to: day) else { continue }
            var bucket = DayEvents()
            for e in events where e.startDate < end && e.endDate > day
                || (e.startDate == day && e.endDate == day) {
                let te = TimelineEvent(
                    id: (e.eventIdentifier ?? UUID().uuidString) + "\(e.startDate.timeIntervalSince1970)",
                    title: (e.title?.isEmpty == false ? e.title! : "Untitled"),
                    start: max(e.startDate, day),
                    end: min(e.endDate, end),
                    location: (e.location?.isEmpty == false) ? e.location : nil,
                    color: e.calendar.map { Color(cgColor: $0.cgColor) } ?? .accentColor,
                    calendarName: e.calendar?.title ?? "",
                    isAllDay: e.isAllDay
                )
                if e.isAllDay || (e.startDate <= day && e.endDate >= end) {
                    bucket.allDay.append(te)
                } else {
                    bucket.timed.append(te)
                }
            }
            bucket.allDay.sort { $0.title < $1.title }
            bucket.timed.sort { ($0.start, $1.end) < ($1.start, $0.end) }
            out[day] = bucket
        }
        return out
    }
}
