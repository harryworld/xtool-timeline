import SwiftUI

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
