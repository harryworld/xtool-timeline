import SwiftUI

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
