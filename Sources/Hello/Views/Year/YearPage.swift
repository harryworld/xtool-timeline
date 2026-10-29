import SwiftUI

/// One year: a 3-column grid of mini months.
struct YearPage: View {
    let yearStart: Date
    let onOpenMonth: (Date) -> Void

    var body: some View {
        let isThisYear = YearIndex.offset(for: yearStart) == 0
        VStack(alignment: .leading, spacing: 8) {
            Label(yearStart.formatted(.dateTime.year()), systemImage: "sparkles")
                .font(.title3.weight(.heavy))
                .foregroundStyle(isThisYear ? Theme.pinkDeep : Theme.lavenderDeep)
                .padding(.leading, 20)
                .padding(.top, 12)
            Grid(horizontalSpacing: 8, verticalSpacing: 8) {
                ForEach(0..<4, id: \.self) { row in
                    GridRow {
                        ForEach(YearIndex.months(ofYearStarting: yearStart)[(row * 3)..<(row * 3 + 3)], id: \.self) { m in
                            MiniMonth(monthStart: m, onTap: { onOpenMonth(m) })
                        }
                    }
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 8)
        }
    }
}
