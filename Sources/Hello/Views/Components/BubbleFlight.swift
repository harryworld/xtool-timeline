import SwiftUI

/// Plain (non-observed) frame registry: written on every layout/scroll without re-rendering anything.
@MainActor
final class BubbleFrames {
    nonisolated static let space = "timelineRoot"
    private var strip: [Date: CGRect] = [:]
    private var column: [Date: CGRect] = [:]

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
