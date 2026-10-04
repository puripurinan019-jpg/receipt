import SwiftUI
import SwiftData

/// หน้ารายละเอียดรายการเดียว + ปุ่มแก้ไขและลบ
struct TransactionDetailView: View {
    let transaction: Transaction

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettings.currencyKey) private var currencyCode = AppSettings.defaultCurrency

    @State private var showEdit = false
    @State private var showDeleteConfirm = false

    private var isIncome: Bool { transaction.type == .income }

    var body: some View {
        List {
            amountSection
            detailSection

            if !transaction.codeValue.isEmpty {
                codeSection
            }
        }
        .navigationTitle("detail.title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("common.edit") { showEdit = true }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteConfirm = true
                } label: {
                    Label("common.delete", systemImage: "trash")
                }
            }
        }
        .sheet(isPresented: $showEdit) {
            NavigationStack {
                RecordEditView(transaction: transaction, onSaved: { showEdit = false })
            }
        }
        .confirmationDialog(
            "detail.deleteConfirm",
            isPresented: $showDeleteConfirm,
            titleVisibility: .visible
        ) {
            Button("common.delete", role: .destructive) {
                delete()
            }
            Button("common.cancel", role: .cancel) {}
        }
    }

    private var amountSection: some View {
        Section {
            VStack(spacing: 8) {
                Text(transaction.type.titleKey)
                    .font(.subheadline)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 5)
                    .background(Capsule().fill((isIncome ? AppTheme.incomeColor : AppTheme.expenseColor).opacity(0.15)))
                    .foregroundStyle(isIncome ? AppTheme.incomeColor : AppTheme.expenseColor)

                Text(signedAmount)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundStyle(isIncome ? AppTheme.incomeColor : AppTheme.expenseColor)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .listRowBackground(Color.clear)
        }
    }

    private var detailSection: some View {
        Section {
            LabeledContent("record.category") {
                HStack(spacing: 6) {
                    Image(systemName: transaction.category.systemImage)
                        .foregroundStyle(transaction.category.tint)
                    Text(transaction.category.titleKey)
                }
            }

            LabeledContent("record.date") {
                Text(transaction.date, format: .dateTime.year().month().day().hour().minute())
            }

            LabeledContent("record.source") {
                Text(transaction.source.titleKey)
            }

            if !transaction.note.isEmpty {
                LabeledContent("record.note") {
                    Text(transaction.note)
                        .multilineTextAlignment(.trailing)
                }
            }
        }
    }

    private var codeSection: some View {
        Section("detail.codeSection") {
            LabeledContent("scan.codeType") {
                Text(transaction.codeType.titleKey)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("scan.codeValue")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(transaction.codeValue)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .textSelection(.enabled)
            }
        }
    }

    private var signedAmount: String {
        let base = AppTheme.formatAmount(transaction.amount, currencyCode: currencyCode)
        return isIncome ? "+\(base)" : "-\(base)"
    }

    private func delete() {
        modelContext.delete(transaction)
        dismiss()
    }
}
