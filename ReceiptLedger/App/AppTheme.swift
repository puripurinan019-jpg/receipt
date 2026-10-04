import SwiftUI

/// ธีมสี รูปแบบตัวเลข และค่าคงที่ของแอป
enum AppTheme {
    static let incomeColor = Color.green
    static let expenseColor = Color.red
    static let balanceColor = Color.blue

    static let cornerRadius: CGFloat = 16

    /// รหัสสกุลเงินที่รองรับในหน้าตั้งค่า
    static let supportedCurrencies: [String] = ["THB", "USD", "EUR", "JPY", "GBP", "SGD", "MYR", "CNY", "HKD", "AUD"]

    static func currencyCode(from storage: String) -> String {
        storage.isEmpty ? "THB" : storage
    }

    /// จัดรูปแบบจำนวนเงินตามสกุลที่ผู้ใช้เลือก
    static func formatAmount(_ value: Double, currencyCode: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = currencyCode
        formatter.maximumFractionDigits = value.truncatingRemainder(dividingBy: 1) == 0 ? 0 : 2
        if let result = formatter.string(from: NSNumber(value: value)) {
            return result
        }
        return String(format: "%.2f", value)
    }

    /// ตัวเลขสั้น ๆ สำหรับแกนกราฟ (เช่น 1.2K, 3.4M)
    static func compactAmount(_ value: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        let absValue = abs(value)

        if absValue >= 1_000_000 {
            return (formatter.string(from: NSNumber(value: value / 1_000_000)) ?? "0") + "M"
        }
        if absValue >= 1_000 {
            return (formatter.string(from: NSNumber(value: value / 1_000)) ?? "0") + "K"
        }
        return formatter.string(from: NSNumber(value: value)) ?? "0"
    }
}

/// การ์ดพื้นหลังใช้ซ้ำทั่วแอป
struct CardBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: AppTheme.cornerRadius, style: .continuous)
                    .fill(Color(.secondarySystemBackground))
            )
    }
}

extension View {
    func cardStyle() -> some View {
        modifier(CardBackground())
    }
}
