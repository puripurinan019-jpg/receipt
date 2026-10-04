import SwiftUI
import Charts

/// กราฟโดนัทแสดงสัดส่วนรายจ่ายแยกตามหมวดหมู่
struct DonutByCategoryChart: View {
    let slices: [CategorySlice]
    let currencyCode: String

    private var total: Double {
        slices.reduce(0) { $0 + $1.total }
    }

    var body: some View {
        if slices.isEmpty {
            EmptyStateView(systemImage: "chart.pie", message: "charts.noData")
        } else {
            VStack(spacing: 16) {
                Chart(slices) { slice in
                    SectorMark(
                        angle: .value("amount", slice.total),
                        innerRadius: .ratio(0.62),
                        angularInset: 2
                    )
                    .foregroundStyle(slice.category.tint)
                    .cornerRadius(4)
                }
                .frame(height: 220)
                .chartLegend(.hidden)

                VStack(spacing: 8) {
                    ForEach(Array(slices.prefix(6))) { slice in
                        row(for: slice)
                    }
                }
            }
        }
    }

    private func row(for slice: CategorySlice) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 3)
                .fill(slice.category.tint)
                .frame(width: 10, height: 10)

            Image(systemName: slice.category.systemImage)
                .font(.caption)
                .foregroundStyle(slice.category.tint)
                .frame(width: 18)

            Text(slice.category.titleKey)
                .font(.subheadline)
                .lineLimit(1)

            Spacer()

            Text(percentText(for: slice.total))
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(width: 44, alignment: .trailing)

            Text(AppTheme.formatAmount(slice.total, currencyCode: currencyCode))
                .font(.subheadline.weight(.medium))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }

    private func percentText(for value: Double) -> String {
        guard total > 0 else { return "0%" }
        let percent = (value / total) * 100
        if percent < 10 {
            return String(format: "%.1f%%", percent)
        }
        return String(format: "%.0f%%", percent)
    }
}
