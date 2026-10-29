import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

enum Theme {
    static let cream = Color(red: 1.00, green: 0.97, blue: 0.94)
    static let blush = Color(red: 1.00, green: 0.92, blue: 0.94)
    static let pink = Color(red: 1.00, green: 0.80, blue: 0.86)
    static let pinkDeep = Color(red: 0.91, green: 0.36, blue: 0.56)
    static let peach = Color(red: 1.00, green: 0.86, blue: 0.76)
    static let lavender = Color(red: 0.88, green: 0.84, blue: 1.00)
    static let lavenderDeep = Color(red: 0.55, green: 0.45, blue: 0.85)
    static let mint = Color(red: 0.80, green: 0.95, blue: 0.88)
    static let baby = Color(red: 0.80, green: 0.90, blue: 1.00)
    static let ink = Color(red: 0.33, green: 0.25, blue: 0.36)
    static let softInk = Color(red: 0.58, green: 0.48, blue: 0.60)

    static let background = LinearGradient(
        colors: [cream, blush, lavender.opacity(0.55)],
        startPoint: .top, endPoint: .bottom
    )
}

extension Color {
    /// Mix toward white by `amount` (0 = original, 1 = white).
    func pastel(_ amount: Double) -> Color {
        #if canImport(UIKit)
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        guard UIColor(self).getRed(&r, green: &g, blue: &b, alpha: &a) else { return self.opacity(1 - amount) }
        let t = CGFloat(amount)
        return Color(red: Double(r + (1 - r) * t), green: Double(g + (1 - g) * t), blue: Double(b + (1 - b) * t))
        #else
        return self.opacity(1 - amount)
        #endif
    }
}
