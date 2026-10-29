import SwiftUI

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
