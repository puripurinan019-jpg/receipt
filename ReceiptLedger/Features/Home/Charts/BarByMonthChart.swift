import SwiftUI
import Charts

/// กราฟแท่งเปรียบเทียบรายรับ-รายจ่ายรายเดือน
struct BarByMonthChart: View {
    let buckets: [MonthBucket]
    let currencyCode: String
    var compact: Bool = false

    private var hasData: Bool {
        buckets.contains { $0.income > 0 || $0.expense > 0 }
    }

    var body: some View {
        if hasData {
            chart
                .chartLegend(.hidden)
                .chartXAxis { xAxis }
                .chartYAxis { yAxis }
        } else {
            EmptyStateView(systemImage: "chart.bar", message: "charts.noData")
        }
    }

    private var chart: some View {
        Chart(buckets) { bucket in
            BarMark(
                x: .value("month", bucket.monthStart, unit: .month),
                y: .value("value", bucket.income),
                width: compact ? .fixed(7) : .fixed(11)
            )
            .foregroundStyle(AppTheme.incomeColor)
            .position(by: .value("series", "income"))

            BarMark(
                x: .value("month", bucket.monthStart, unit: .month),
                y: .value("value", bucket.expense),
                width: compact ? .fixed(7) : .fixed(11)
            )
            .foregroundStyle(AppTheme.expenseColor)
            .position(by: .value("series", "expense"))
        }
    }

    private var xAxis: AxisMarks<Date> {
        AxisMarks(values: .stride(by: .month)) { value in
            AxisGridLine().foregroundStyle(Color.primary.opacity(0.06))
            AxisTick().foregroundStyle(.clear)
            AxisValueLabel {
                if let date = value.as(Date.self) {
                    Text(date, format: .dateTime.month(.abbreviated))
                }
            }
        }
    }

    private var yAxis: AxisMarks<Double> {
        AxisMarks(position: .leading) { value in
            AxisGridLine().foregroundStyle(Color.primary.opacity(0.08))
            AxisValueLabel {
                if let number = value.as(Double.self) {
                    Text(AppTheme.compactAmount(number))
                }
            }
        }
    }
}

/// คำอธิบายสีใต้กราฟ (ใช้แทน legend ของ Swift Charts เพื่อให้แปลภาษาได้)
struct ChartLegendRow: View {
    var body: some View {
        HStack(spacing: 16) {
            legendItem(color: AppTheme.incomeColor, key: "income")
            legendItem(color: AppTheme.expenseColor, key: "expense")
            Spacer()
        }
    }

    private func legendItem(color: Color, key: LocalizedStringKey) -> some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 3)
                .fill(color)
                .frame(width: 10, height: 10)
            Text(key)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}
