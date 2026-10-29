import SwiftUI

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
