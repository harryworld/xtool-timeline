import SwiftUI

/// Plain (non-observed) frame registry: written on every layout/scroll without re-rendering anything.
@MainActor
final class BubbleFrames {
    nonisolated static let space = "timelineRoot"
    private var byMode: [ViewMode: [Date: CGRect]] = [:]

    func set(_ mode: ViewMode, _ day: Date, _ r: CGRect) {
        byMode[mode, default: [:]][Calendar.current.startOfDay(for: day)] = r
    }

    func clear(_ mode: ViewMode) {
        byMode[mode] = [:]
    }

    func snapshot(_ mode: ViewMode, _ days: [Date]) -> [Date: CGRect] {
        let src = byMode[mode] ?? [:]
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
    let fromMode: ViewMode
    let toMode: ViewMode
    let from: [Date: CGRect]
    var to: [Date: CGRect] = [:]
    var arrived = false

    var shownMode: ViewMode { arrived ? toMode : fromMode }
    var frames: [Date: CGRect] { arrived ? to : from }
}

/// The selected week's bubbles drawn once, above all scroll views, flying between strip, column and month grid.
struct FlyingBubbles: View {
    let flight: BubbleFlight
    let selected: Date

    var body: some View {
        let inMonth = flight.shownMode == .month
        ZStack(alignment: .topLeading) {
            ForEach(flight.days, id: \.self) { d in
                let k = Calendar.current.startOfDay(for: d)
                if let r = (flight.arrived ? flight.to[k] : nil) ?? flight.from[k] {
                    DayBubble(day: d, selected: selected, compact: inMonth)
                        .frame(width: r.width, height: r.height)
                        .opacity(inMonth && !Calendar.current.isDate(d, equalTo: selected, toGranularity: .month) ? MonthCell.outsideOpacity : 1)
                        .position(x: r.midX, y: r.midY)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(false)
    }
}
