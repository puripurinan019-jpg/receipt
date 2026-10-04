import SwiftUI

/// หมวดหมู่รายรับ-รายจ่าย ชุดเริ่มต้น
/// เก็บเป็น rawValue String ลง SwiftData เพื่อให้แก้ไข/เปลี่ยนชื่อภายหลังได้โดยไม่พังข้อมูลเดิม
enum Category: String, Codable, CaseIterable, Identifiable, Sendable {
    // รายจ่าย
    case food
    case transport
    case shopping
    case bills
    case health
    case housing
    case entertainment
    case education
    case pets
    case gifts
    case otherExpense

    // รายรับ
    case sales
    case salary
    case bonus
    case investment
    case otherIncome

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        LocalizedStringKey("category.\(rawValue)")
    }

    var transactionType: TransactionType {
        switch self {
        case .sales, .salary, .bonus, .investment, .otherIncome:
            return .income
        default:
            return .expense
        }
    }

    static var expenseCases: [Category] {
        allCases.filter { $0.transactionType == .expense }
    }

    static var incomeCases: [Category] {
        allCases.filter { $0.transactionType == .income }
    }

    static func cases(for type: TransactionType) -> [Category] {
        type == .income ? incomeCases : expenseCases
    }

    /// SF Symbol ใช้แสดงใน picker และกราฟโดนัท
    var systemImage: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car"
        case .shopping: return "bag"
        case .bills: return "doc.text"
        case .health: return "cross.case"
        case .housing: return "house"
        case .entertainment: return "play.tv"
        case .education: return "graduationcap"
        case .pets: return "pawprint"
        case .gifts: return "gift"
        case .otherExpense: return "ellipsis.circle"
        case .sales: return "storefront"
        case .salary: return "banknote"
        case .bonus: return "star"
        case .investment: return "chart.line.uptrend.xyaxis"
        case .otherIncome: return "tray.and.arrow.down"
        }
    }

    /// คำสำหรับค้นหาทั้งภาษาไทยและอังกฤษ
    /// ไม่พึ่งพา bundle localization เพื่อให้ค้นได้ทั้งสองภาษาไม่ว่าแอปจะเลือกภาษาไหนอยู่
    var searchTerms: [String] {
        let thai: String
        let english: String
        switch self {
        case .food: (thai, english) = ("อาหาร", "food")
        case .transport: (thai, english) = ("เดินทาง", "transport")
        case .shopping: (thai, english) = ("ช้อปปิ้ง", "shopping")
        case .bills: (thai, english) = ("บิล ค่าสาธารณูปโภค", "bills")
        case .health: (thai, english) = ("สุขภาพ", "health")
        case .housing: (thai, english) = ("ที่อยู่อาศัย", "housing")
        case .entertainment: (thai, english) = ("ความบันเทิง", "entertainment")
        case .education: (thai, english) = ("การศึกษา", "education")
        case .pets: (thai, english) = ("สัตว์เลี้ยง", "pets")
        case .gifts: (thai, english) = ("ของขวัญ", "gifts")
        case .otherExpense: (thai, english) = ("อื่นๆ", "other")
        case .sales: (thai, english) = ("ขายของ", "sales")
        case .salary: (thai, english) = ("เงินเดือน", "salary")
        case .bonus: (thai, english) = ("โบนัส", "bonus")
        case .investment: (thai, english) = ("ดอกเบี้ย ผลตอบแทน", "investment")
        case .otherIncome: (thai, english) = ("อื่นๆ", "other")
        }
        return [rawValue, thai, english]
    }

    /// สีประจำหมวด ใช้ทั้งในรายการและกราฟ
    var tint: Color {
        switch self {
        case .food: return .orange
        case .transport: return .blue
        case .shopping: return .pink
        case .bills: return .purple
        case .health: return .red
        case .housing: return .brown
        case .entertainment: return .indigo
        case .education: return .teal
        case .pets: return .green
        case .gifts: return .mint
        case .otherExpense: return .gray
        case .sales: return .green
        case .salary: return .blue
        case .bonus: return .yellow
        case .investment: return .cyan
        case .otherIncome: return .gray
        }
    }
}
