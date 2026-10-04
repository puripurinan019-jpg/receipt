import Foundation
import SwiftUI
import VisionKit

/// ชนิดของโค้ดที่อ่านได้จากใบเสร็จ
enum CodeType: String, Codable, CaseIterable, Sendable {
    case qr
    case ean8
    case ean13
    case upce
    case code39
    case code93
    case code128
    case dataMatrix
    case pdf417
    case aztec
    case other
    case unknown

    var titleKey: LocalizedStringKey {
        LocalizedStringKey("codeType.\(rawValue)")
    }

    /// map จาก VisionKit symbology
    /// ใช้ String(describing:) แทนการอ้าง case ตรง ๆ เพื่อไม่ผูกโค้ดกับชื่อ case เฉพาะเวอร์ชัน SDK
    static func from(symbology: BarcodeSymbology) -> CodeType {
        let name = String(describing: symbology).lowercased()
        switch name {
        case "qr": return .qr
        case "ean8": return .ean8
        case "ean13", "ean_13": return .ean13
        case "upce", "upc_e": return .upce
        case "code39", "code_39": return .code39
        case "code93", "code_93": return .code93
        case "code128", "code_128": return .code128
        case "datamatrix", "data_matrix": return .dataMatrix
        case "pdf417", "pdf_417": return .pdf417
        case "aztec": return .aztec
        default: return .other
        }
    }
}

/// ผลการอ่านโค้ดหนึ่งครั้ง
struct ScannedCode: Equatable, Identifiable {
    let id = UUID()
    let payload: String
    let type: CodeType
}

/// แปลง payload ของโค้ดให้เป็นข้อมูลที่ใช้เติมฟอร์มได้
enum CodeParser {
    struct Parsed {
        var amount: Double?
        var merchantName: String?
    }

    /// อ่าน payload ให้เป็นยอดเงิน (ถ้าเป็นไปได้)
    static func parse(payload: String, type: CodeType) -> Parsed {
        var result = Parsed()

        if type == .qr {
            if let amount = parseEMVCoAmount(payload) {
                result.amount = amount
            }
            if let name = parseEMVCoMerchantName(payload) {
                result.merchantName = name
            }
        }

        // กรณีเป็น barcode เลขล้วนที่พิมพ์ยอดมาตรง ๆ (เช่น SKU พิเศษ) ไม่เดา ปล่อยให้ผู้ใช้กรอกเอง
        return result
    }

    /// EMVCo TLV payload (PromptPay/QR จ่ายเงิน) รูปแบบ: tag(2) + length(2) + value(n)
    /// tag "54" คือ transaction amount
    static func parseEMVCoAmount(_ payload: String) -> Double? {
        guard let value = tlvValue(payload, tag: "54") else { return nil }
        let cleaned = value.replacingOccurrences(of: ",", with: "")
        guard let amount = Double(cleaned), amount > 0 else { return nil }
        return amount
    }

    /// tag "58" คือ merchant name (ขึ้นต้นด้วย country code 2 ตัวอักษร)
    static func parseEMVCoMerchantName(_ payload: String) -> String? {
        guard let raw = tlvValue(payload, tag: "58") else { return nil }
        var name = raw
        if name.count > 2 {
            // ตัด country code เช่น "TH" ออก
            let prefix = String(name.prefix(2))
            if prefix == prefix.uppercased(), prefix.rangeOfCharacter(from: .letters) != nil {
                name = String(name.dropFirst(2))
            }
        }
        name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        return name.isEmpty ? nil : name
    }

    static func tlvValue(_ payload: String, tag: String) -> String? {
        guard payload.hasPrefix("00") else { return nil } // ต้องเป็น EMVCo payload
        var index = payload.startIndex

        while index < payload.endIndex {
            let tagEnd = payload.index(index, offsetBy: 2, limitedBy: payload.endIndex)
            guard let tagEnd else { return nil }
            let currentTag = String(payload[index..<tagEnd])

            let lenStart = tagEnd
            let lenEnd = payload.index(lenStart, offsetBy: 2, limitedBy: payload.endIndex)
            guard let lenEnd else { return nil }
            guard let length = Int(payload[lenStart..<lenEnd]) else { return nil }

            let valueStart = lenEnd
            guard let valueEnd = payload.index(valueStart, offsetBy: length, limitedBy: payload.endIndex) else { return nil }

            if currentTag == tag {
                return String(payload[valueStart..<valueEnd])
            }
            index = valueEnd
        }
        return nil
    }
}
