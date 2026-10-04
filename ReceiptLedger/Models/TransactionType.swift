import SwiftUI

/// ชนิดของรายการ: รายรับ หรือ รายจ่าย
enum TransactionType: String, Codable, CaseIterable, Identifiable, Sendable {
    case income
    case expense

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .income: return "income"
        case .expense: return "expense"
        }
    }

    /// ค่าเริ่มต้นของแต่ละ type ใช้ตอนเปิดฟอร์มใหม่
    var defaultCategory: Category {
        switch self {
        case .income: return .sales
        case .expense: return .food
        }
    }
}
