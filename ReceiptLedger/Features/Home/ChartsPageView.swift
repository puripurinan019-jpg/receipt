import SwiftUI
import SwiftData

/// หน้ากราฟเต็มจอ เปิดจากปุ่ม "ดูกราฟทั้งหมด" ในหน้าหลัก
/// ครอบคลุม: แท่งรายรับ-รายจ่าย, โดนัทตามหมวด, เส้นแนวโน้มยอดคงเหลือ
struct ChartsPageView: View {
    @Binding var period: Period
    let transactions: [Transaction]

    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettings.currencyKey) private var currencyCode = AppSettings.defaultCurrency

    private var filtered: [Transaction] {
        Analytics.filter(transactions, in: period)
    }

    private var summary: Summary {
        Analytics.summary(filtered)
    }

    private var donutType: TransactionType {
        // ถ้ารายจ่ายมากกว่าหรือเท่ารายรับ ให้เจาะกลุ่มรายจ่าย มิฉะนั้นดูสัดส่วนรายรับ
        summary.income >= summary.expense ? .income : .expense
    }

    private var slices: [CategorySlice] {
        Analytics.slicesByCategory(filtered, type: donutType)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    periodPicker
                    summaryStrip
                    barSection
                    donutSection
                    lineSection
                }
                .padding(.horizontal)
                .padding(.bottom, 32)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("charts.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("common.done") { dismiss() }
                }
            }
        }
    }

    private var periodPicker: some View {
        Picker("home.period", selection: $period) {
            ForEach(Period.allCases) { item in
                Text(item.titleKey).tag(item)
            }
        }
        .pickerStyle(.segmented)
        .padding(.top, 8)
    }

    private var summaryStrip: some View {
        HStack(spacing: 12) {
            stripItem(title: "income", value: summary.income, color: AppTheme.incomeColor)
            stripItem(title: "expense", value: summary.expense, color: AppTheme.expenseColor)
            stripItem(title: "home.balance", value: summary.balance, color: AppTheme.balanceColor)
        }
    }

    private func stripItem(title: LocalizedStringKey, value: Double, color: Color) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(AppTheme.compactAmount(value))
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private var barSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "charts.barTitle", systemImage: "chart.bar.fill")
            BarByMonthChart(
                buckets: Analytics.monthlyBuckets(transactions, count: 6),
                currencyCode: currencyCode,
                compact: false
            )
            .frame(height: 220)
            ChartLegendRow()
        }
        .cardStyle()
    }

    private var donutSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader(
                    title: donutType == .income ? "charts.donutIncomeTitle" : "charts.donutExpenseTitle",
                    systemImage: "chart.pie.fill"
                )
                Spacer()
                Text(donutType.titleKey)
                    .font(.caption)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(Color(.tertiarySystemBackground)))
            }

            DonutByCategoryChart(slices: slices, currencyCode: currencyCode)
        }
        .cardStyle()
    }

    private var lineSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader(title: "charts.lineTitle", systemImage: "chart.line.uptrend.xyaxis")
            BalanceTrendLineChart(
                points: Analytics.balanceSeries(filtered)
            )
            .frame(height: 220)
        }
        .cardStyle()
    }
}
