import SwiftUI

/// แถวแสดงรายการหนึ่งบรรทัด ใช้ในหน้าหลักและหน้าประวัติ
struct TransactionRow: View {
    let transaction: Transaction
    let currencyCode: String

    private var isIncome: Bool { transaction.type == .income }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(transaction.category.tint.opacity(0.18))
                    .frame(width: 40, height: 40)
                Image(systemName: transaction.category.systemImage)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(transaction.category.tint)
            }

            VStack(alignment: .leading, spacing: 3) {
                titleText
                    .font(.subheadline.weight(.medium))
                    .lineLimit(1)

                HStack(spacing: 6) {
                    Text(transaction.date, format: .dateTime.day().month().year())
                    if transaction.source == .scan {
                        Image(systemName: "qrcode.viewfinder")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 8)

            Text(signedAmount)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(isIncome ? AppTheme.incomeColor : AppTheme.expenseColor)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .padding(.vertical, 8)
        .contentShape(Rectangle())
    }

    /// ถ้ามีหมายเหตุให้แสดงหมายเหตุ (verbatim) ไม่งั้นแสดงชื่อหมวด (localized key)
    /// ใช้ Text(LocalizedStringKey) เพื่อให้รองรับการสลับภาษาในแอปผ่าน environment locale
    @ViewBuilder
    private var titleText: some View {
        let note = transaction.note.trimmingCharacters(in: .whitespacesAndNewlines)
        if note.isEmpty {
            Text(transaction.category.titleKey)
        } else {
            Text(note)
        }
    }

    private var signedAmount: String {
        let base = AppTheme.formatAmount(transaction.amount, currencyCode: currencyCode)
        return isIncome ? "+\(base)" : "-\(base)"
    }
}

/// จอว่างเปล่ากรณียังไม่มีข้อมูล
struct EmptyStateView: View {
    let systemImage: String
    let message: LocalizedStringKey

    var body: some View {
        VStack(spacing: 10) {
            Image(systemName: systemImage)
                .font(.system(size: 30))
                .foregroundStyle(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}

/// หัวข้อตอน (section header) ใช้ซ้ำในหน้ากราฟและหน้าตั้งค่า
struct SectionHeader: View {
    let title: LocalizedStringKey
    var systemImage: String? = nil

    var body: some View {
        HStack(spacing: 6) {
            if let systemImage {
                Image(systemName: systemImage)
            }
            Text(title)
        }
        .font(.headline)
        .foregroundStyle(.primary)
    }
}
