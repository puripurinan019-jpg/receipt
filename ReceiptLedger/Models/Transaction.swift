import SwiftUI
import SwiftData

/// ที่มาของรายการ: สแกนมา หรือ กรอกเอง
enum TransactionSource: String, Codable, Sendable {
    case scan
    case manual

    var titleKey: LocalizedStringKey {
        switch self {
        case .scan: return "source.scan"
        case .manual: return "source.manual"
        }
    }
}

/// รายการรายรับ-รายจ่ายหนึ่งบรรทัด เก็บในเครื่องด้วย SwiftData
@Model
final class Transaction {
    @Attribute(.unique) var id: UUID
    var amount: Double
    var typeRaw: String
    var categoryRaw: String
    var note: String
    var date: Date
    /// ค่าดิบที่อ่านได้จาก QR/Barcode (ว่างถ้ากรอกเอง)
    var codeValue: String
    var codeTypeRaw: String
    var sourceRaw: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        amount: Double,
        type: TransactionType,
        category: Category,
        note: String = "",
        date: Date = .now,
        codeValue: String = "",
        codeType: CodeType = .unknown,
        source: TransactionSource = .manual
    ) {
        self.id = id
        self.amount = amount
        self.typeRaw = type.rawValue
        self.categoryRaw = category.rawValue
        self.note = note
        self.date = date
        self.codeValue = codeValue
        self.codeTypeRaw = codeType.rawValue
        self.sourceRaw = source.rawValue
        self.createdAt = .now
    }

    var type: TransactionType {
        get { TransactionType(rawValue: typeRaw) ?? .expense }
        set { typeRaw = newValue.rawValue }
    }

    var category: Category {
        get { Category(rawValue: categoryRaw) ?? .otherExpense }
        set { categoryRaw = newValue.rawValue }
    }

    var codeType: CodeType {
        get { CodeType(rawValue: codeTypeRaw) ?? .unknown }
        set { codeTypeRaw = newValue.rawValue }
    }

    var source: TransactionSource {
        get { TransactionSource(rawValue: sourceRaw) ?? .manual }
        set { sourceRaw = newValue.rawValue }
    }
}
