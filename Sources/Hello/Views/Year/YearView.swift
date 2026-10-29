import SwiftUI

struct YearView: View {
    let selected: Date
    let onSelect: (Date) -> Void
    let onOpenMonth: (Date) -> Void

    var body: some View {
        VStack(spacing: 0) {
            YearPager(selected: selected, onSelect: onSelect, onOpenMonth: onOpenMonth)
            // Keeps the pager above the bottom bar so the next year doesn't peek in under it.
            Color.clear.frame(height: 1)
        }
    }
}
