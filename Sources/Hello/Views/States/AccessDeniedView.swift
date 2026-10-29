import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AccessDeniedView: View {
    let restricted: Bool

    var body: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [Theme.lavender, Theme.pink], startPoint: .top, endPoint: .bottom))
                    .frame(width: 110, height: 110)
                Image(systemName: "calendar.badge.exclamationmark")
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Theme.pinkDeep, .white)
                    .font(.system(size: 50))
            }
            Text("Can I peek at your calendar? 🥺")
                .font(.title3.weight(.heavy))
                .multilineTextAlignment(.center)
            Text(restricted
                 ? "Calendar access is restricted on this device, so I can't show your events."
                 : "Timeline needs full calendar access to draw your day. Turn it on in Settings › Timeline › Calendars.")
                .multilineTextAlignment(.center)
                .foregroundStyle(Theme.softInk)
                .padding(.horizontal, 36)
            if !restricted {
                Button {
                    #if canImport(UIKit)
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    #endif
                } label: {
                    Label("Open Settings", systemImage: "heart.fill")
                        .font(.headline.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 24)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(colors: [Theme.pinkDeep, Theme.pinkDeep.pastel(0.35)],
                                           startPoint: .leading, endPoint: .trailing),
                            in: Capsule()
                        )
                        .shadow(color: Theme.pinkDeep.opacity(0.3), radius: 8, y: 4)
                }
                .buttonStyle(.plain)
            }
            Spacer()
        }
    }
}
