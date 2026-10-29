import SwiftUI

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

struct DottedLine: Shape {
    func path(in rect: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: rect.minX, y: rect.midY))
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.midY))
        return p
    }
}
