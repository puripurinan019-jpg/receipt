import SwiftUI
import SwiftData

/// หน้าประวัติ: รายการทั้งหมด ค้นหาได้ กรองตามประเภทและหมวด ลบทีละรายการได้
struct HistoryView: View {
    @Environment(\.modelContext) private var modelContext
    @AppStorage(AppSettings.currencyKey) private var currencyCode = AppSettings.defaultCurrency
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @State private var searchText = ""
    @State private var typeFilter: FilterType = .all
    @State private var categoryFilter: Category?

    enum FilterType: String, CaseIterable, Identifiable {
        case all
        case income
        case expense

        var id: String { rawValue }

        var titleKey: LocalizedStringKey {
            switch self {
            case .all: return "history.filter.all"
            case .income: return "income"
            case .expense: return "expense"
            }
        }
    }

    private var visible: [Transaction] {
        transactions.filter { tx in
            if typeFilter == .income, tx.type != .income { return false }
            if typeFilter == .expense, tx.type != .expense { return false }
            if let categoryFilter, tx.category != categoryFilter { return false }
            return matchesSearch(tx)
        }
    }

    private var visibleSummary: Summary {
        Analytics.summary(visible)
    }

    var body: some View {
        NavigationStack {
            Group {
                if visible.isEmpty {
                    EmptyStateView(systemImage: "magnifyingglass", message: "history.empty")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    list
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("history.title")
            .navigationDestination(for: Transaction.self) { tx in
                TransactionDetailView(transaction: tx)
            }
            .searchable(text: $searchText, prompt: "history.search")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    filterMenu
                }
                ToolbarItem(placement: .topBarTrailing) {
                    summaryLabel
                }
            }
        }
    }

    private var list: some View {
        List {
            if !visible.isEmpty {
                Section {
                    summaryStrip
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                }
            }

            Section {
                ForEach(visible) { tx in
                    NavigationLink(value: tx) {
                        TransactionRow(transaction: tx, currencyCode: currencyCode)
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            delete(tx)
                        } label: {
                            Label("common.delete", systemImage: "trash")
                        }
                    }
                }
            } header: {
                HStack(spacing: 4) {
                    Text("\(visible.count)")
                    Text("common.itemUnit")
                }
            }
        }
        .listStyle(.insetGrouped)
    }

    private var summaryStrip: some View {
        HStack(spacing: 12) {
            item(title: "income", value: visibleSummary.income, color: AppTheme.incomeColor)
            item(title: "expense", value: visibleSummary.expense, color: AppTheme.expenseColor)
            item(title: "home.balance", value: visibleSummary.balance, color: AppTheme.balanceColor)
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(Color(.secondarySystemBackground))
        )
    }

    private func item(title: LocalizedStringKey, value: Double, color: Color) -> some View {
        VStack(spacing: 3) {
            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
                .lineLimit(1)
            Text(AppTheme.compactAmount(value))
                .font(.footnote.weight(.semibold))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .frame(maxWidth: .infinity)
    }

    private var summaryLabel: some View {
        Text(AppTheme.formatAmount(visibleSummary.balance, currencyCode: currencyCode))
            .font(.footnote.weight(.semibold))
            .foregroundStyle(visibleSummary.balance >= 0 ? AppTheme.balanceColor : AppTheme.expenseColor)
    }

    private var filterMenu: some View {
        Menu {
            Picker("history.filterType", selection: $typeFilter) {
                ForEach(FilterType.allCases) { item in
                    Text(item.titleKey).tag(item)
                }
            }

            Picker("history.filterCategory", selection: $categoryFilter) {
                Text("history.filter.allCategories")
                    .tag(Category?.none)
                ForEach(Category.allCases) { category in
                    Label {
                        Text(category.titleKey)
                    } icon: {
                        Image(systemName: category.systemImage)
                    }
                    .tag(Category?.some(category))
                }
            }
        } label: {
            Label("history.filter", systemImage: "line.3.horizontal.decrease.circle")
        }
    }

    private func matchesSearch(_ tx: Transaction) -> Bool {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else { return true }

        let lowered = query.lowercased()
        if tx.note.lowercased().contains(lowered) { return true }
        if tx.codeValue.lowercased().contains(lowered) { return true }
        if tx.category.searchTerms.contains(where: { $0.lowercased().contains(lowered) }) { return true }
        // ค้นด้วยจำนวนเงิน เช่น "185" หรือ "185.0"
        let amountText = String(format: "%.2f", tx.amount)
        if amountText == lowered || amountText.hasPrefix(lowered + ".") { return true }
        return false
    }

    private func delete(_ tx: Transaction) {
        modelContext.delete(tx)
    }
}
