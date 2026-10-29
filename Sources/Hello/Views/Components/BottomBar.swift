import SwiftUI

struct BottomBar: View {
    let isToday: Bool
    let mode: ViewMode
    let onToday: () -> Void
    let onMode: (ViewMode) -> Void
    @Namespace private var seg

    var body: some View {
        HStack {
            Button {
                onToday()   // the pagers decide how to animate their own scroll
            } label: {
                Label("Today", systemImage: "heart.fill")
                    .font(.body.weight(.bold))
                    .foregroundStyle(isToday ? Theme.softInk.opacity(0.7) : Theme.pinkDeep)
                    .symbolEffect(.bounce, value: isToday)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 11)
                    .background(.regularMaterial, in: Capsule())
                    .background(Theme.pink.opacity(isToday ? 0.12 : 0.45), in: Capsule())
                    .overlay(Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 1))
                    .shadow(color: Theme.pinkDeep.opacity(isToday ? 0.04 : 0.22), radius: isToday ? 4 : 9, y: 3)
            }
            .buttonStyle(.plain)
            .disabled(isToday)
            .opacity(isToday ? 0.6 : 1)
            .scaleEffect(isToday ? 0.94 : 1)
            .animation(.spring(response: 0.38, dampingFraction: 0.72), value: isToday)
            .accessibilityHint("Jump to today")
            Spacer()
            ModeToggle(mode: mode, seg: seg, onMode: onMode)
        }
        .padding(.horizontal, 20)
        .padding(.top, 6)
        .padding(.bottom, 4)
    }
}

struct ModeToggle: View {
    let mode: ViewMode
    let seg: Namespace.ID
    let onMode: (ViewMode) -> Void

    var body: some View {
        HStack(spacing: 2) {
            ForEach(ViewMode.allCases, id: \.self) { m in
                let on = m == mode
                Button { onMode(m) } label: {
                    HStack(spacing: 5) {
                        Image(systemName: m.symbol)
                        if on {
                            Text(m.rawValue).transition(.opacity.combined(with: .scale(scale: 0.8)))
                        }
                    }
                    .font(.subheadline.weight(.bold))
                    .foregroundStyle(on ? Color.white : Theme.lavenderDeep)
                    .padding(.horizontal, on ? 12 : 11)
                    .padding(.vertical, 9)
                    .background {
                        if on {
                            Capsule()
                                .fill(LinearGradient(colors: [Theme.lavenderDeep.pastel(0.1), Theme.lavenderDeep.pastel(0.4)],
                                                     startPoint: .top, endPoint: .bottom))
                                .matchedGeometryEffect(id: "seg", in: seg)
                                .shadow(color: Theme.lavenderDeep.opacity(0.3), radius: 5, y: 2)
                        }
                    }
                    .contentShape(Capsule())
                }
                .buttonStyle(.plain)
                .accessibilityLabel(m.rawValue)
                .accessibilityAddTraits(on ? .isSelected : [])
            }
        }
        .padding(3)
        .background(.regularMaterial, in: Capsule())
        .background(Theme.lavender.opacity(0.4), in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.9), lineWidth: 1))
        .shadow(color: Theme.lavenderDeep.opacity(0.15), radius: 8, y: 3)
    }
}
