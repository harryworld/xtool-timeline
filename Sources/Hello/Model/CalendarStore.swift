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
        load(b, day: Calendar.current.startOfDay(for: d))
    }

    private func load(_ b: DayBox, day: Date) {
        b.loading = true
        let ref = StoreRef(ek: store)
        Task.detached(priority: .userInitiated) {
            let result = CalendarStore.fetch(ref, day)
            await MainActor.run {
                if b.events != result { b.events = result }
                b.loading = false
            }
        }
    }

    func reloadAll() {
        guard access == .granted else { return }
        _ = box(for: day)
        for (k, b) in boxes where b.events != nil || k == day {
            load(b, day: k)
        }
    }

    nonisolated static func fetch(_ ref: StoreRef, _ day: Date) -> DayEvents {
        let cal = Calendar.current
        guard let end = cal.date(byAdding: .day, value: 1, to: day) else { return DayEvents() }
        let predicate = ref.ek.predicateForEvents(withStart: day, end: end, calendars: nil)
        var out = DayEvents()
        for e in ref.ek.events(matching: predicate) {
            let color = e.calendar.map { Color(cgColor: $0.cgColor) } ?? .accentColor
            let te = TimelineEvent(
                id: (e.eventIdentifier ?? UUID().uuidString) + "\(e.startDate.timeIntervalSince1970)",
                title: (e.title?.isEmpty == false ? e.title! : "Untitled"),
                start: max(e.startDate, day),
                end: min(e.endDate, end),
                location: (e.location?.isEmpty == false) ? e.location : nil,
                color: color,
                calendarName: e.calendar?.title ?? "",
                isAllDay: e.isAllDay
            )
            if e.isAllDay || (e.startDate <= day && e.endDate >= end) {
                out.allDay.append(te)
            } else {
                out.timed.append(te)
            }
        }
        out.allDay.sort { $0.title < $1.title }
        out.timed.sort { ($0.start, $1.end) < ($1.start, $0.end) }
        return out
    }
}
