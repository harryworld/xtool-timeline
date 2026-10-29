import SwiftUI

struct LoadingView: View {
    var body: some View {
        Spacer()
        VStack(spacing: 12) {
            Image(systemName: "heart.circle.fill")
                .font(.system(size: 44))
                .foregroundStyle(Theme.pinkDeep, Theme.pink)
                .symbolEffect(.pulse)
            Text("Peeking at your calendar…")
                .font(.headline)
                .foregroundStyle(Theme.softInk)
        }
        Spacer()
    }
}
