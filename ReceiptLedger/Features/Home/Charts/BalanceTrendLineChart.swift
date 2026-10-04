import SwiftUI
import Charts

/// กราฟเส้นแนวโน้มยอดคงเหลือสะสม
struct BalanceTrendLineChart: View {
    let points: [BalancePoint]

    var body: some View {
        if points.count < 2 {
            EmptyStateView(systemImage: "chart.line.uptrend.xyaxis", message: "charts.noData")
        } else {
            Chart(points) { point in
                AreaMark(
                    x: .value("date", point.date),
                    y: .value("balance", point.balance)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [
                            AppTheme.balanceColor.opacity(0.35),
                            AppTheme.balanceColor.opacity(0.02)
                        ],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.monotone)

                LineMark(
                    x: .value("date", point.date),
                    y: .value("balance", point.balance)
                )
                .foregroundStyle(AppTheme.balanceColor)
                .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round))
                .interpolationMethod(.monotone)

                PointMark(
                    x: .value("date", point.date),
                    y: .value("balance", point.balance)
                )
                .foregroundStyle(AppTheme.balanceColor)
                .symbolSize(28)
            }
            .chartXAxis { xAxis }
            .chartYAxis { yAxis }
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.primary.opacity(0.04))
            )
        }
    }

    private var xAxis: AxisMarks<Date> {
        AxisMarks(values: .stride(by: .month)) { value in
            AxisGridLine().foregroundStyle(Color.primary.opacity(0.08))
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
