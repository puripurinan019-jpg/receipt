import SwiftUI
import SwiftData

/// หน้าหลัก: การ์ดสรุปยอด + กราฟสรุป + ปุ่มเปิดหน้ากราฟ + รายการล่าสุด
struct HomeView: View {
    @AppStorage(AppSettings.currencyKey) private var currencyCode = AppSettings.defaultCurrency
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var period: Period = .month
    @State private var showCharts = false

    private var filtered: [Transaction] {
        Analytics.filter(transactions, in: period)
    }

    private var summary: Summary {
        Analytics.summary(filtered)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    periodPicker
                    summaryCards
                    chartPreview
                    recentSection
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("home.title")
            .sheet(isPresented: $showCharts) {
                ChartsPageView(period: $period, transactions: transactions)
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

    private var summaryCards: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                SummaryCard(
                    title: "home.income",
                    value: summary.income,
                    color: AppTheme.incomeColor,
                    systemImage: "arrow.down.circle.fill",
                    currencyCode: currencyCode
                )
                SummaryCard(
                    title: "home.expense",
                    value: summary.expense,
                    color: AppTheme.expenseColor,
                    systemImage: "arrow.up.circle.fill",
                    currencyCode: currencyCode
                )
            }

            BalanceCard(
                value: summary.balance,
                currencyCode: currencyCode,
                isEmpty: filtered.isEmpty
            )
        }
    }

    @ViewBuilder
    private var chartPreview: some View {
        if filtered.isEmpty {
            EmptyStateView(
                systemImage: "chart.bar",
                message: "home.empty"
            )
            .cardStyle()
        } else {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("home.chartTitle")
                        .font(.headline)
                    Spacer()
                    Button("home.seeAllCharts") {
                        showCharts = true
                    }
                    .font(.subheadline)
                }

                BarByMonthChart(
                    buckets: Analytics.monthlyBuckets(transactions, count: 6),
                    currencyCode: currencyCode,
                    compact: true
                )
                .frame(height: 160)
            }
            .cardStyle()
        }
    }

    @ViewBuilder
    private var recentSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("home.recent")
                    .font(.headline)
                Spacer()
                if !filtered.isEmpty {
                    HStack(spacing: 4) {
                        Text("\(filteredCount)")
                        Text("common.itemUnit")
                    }
                    .font(.caption)
                    .foregroundStyle(.secondary)
                }
            }

            if filtered.isEmpty {
                EmptyStateView(
                    systemImage: "tray",
                    message: "home.emptyHint"
                )
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filtered.prefix(5))) { tx in
                        NavigationLink(value: tx) {
                            TransactionRow(transaction: tx, currencyCode: currencyCode)
                        }
                        .buttonStyle(.plain)

                        if tx.id != filtered.prefix(5).last?.id {
                            Divider().padding(.leading, 56)
                        }
                    }
                }
            }
        }
        .cardStyle()
        .navigationDestination(for: Transaction.self) { tx in
            TransactionDetailView(transaction: tx)
        }
    }

    private var filteredCount: Int {
        filtered.count
    }
}

/// การ์ดย่อยแสดงยอดเดียว
private struct SummaryCard: View {
    let title: LocalizedStringKey
    let value: Double
    let color: Color
    let systemImage: String
    let currencyCode: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Image(systemName: systemImage)
                    .foregroundStyle(color)
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(AppTheme.formatAmount(value, currencyCode: currencyCode))
                .font(.title3.bold())
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle()
    }
}

/// การ์ดยอดคงเหลือ กินความกว้างเต็มแถว
private struct BalanceCard: View {
    let value: Double
    let currencyCode: String
    let isEmpty: Bool

    private var color: Color {
        if isEmpty { return .secondary }
        return value >= 0 ? AppTheme.balanceColor : AppTheme.expenseColor
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 6) {
                Text("home.balance")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Text(AppTheme.formatAmount(value, currencyCode: currencyCode))
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }

            Spacer()

            Image(systemName: value >= 0 ? "chart.line.uptrend.xyaxis" : "chart.line.downtrend.xyaxis")
                .font(.system(size: 34))
                .foregroundStyle(color.opacity(0.8))
        }
        .cardStyle()
    }
}
