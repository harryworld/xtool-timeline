import SwiftUI

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
