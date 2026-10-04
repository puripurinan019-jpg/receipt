import Foundation

/// ส่งออกรายการเป็นไฟล์ CSV หรือ JSON เพื่อแชร์ออกนอกแอป
enum ExportService {
    static func csv(from transactions: [Transaction]) -> String {
        var rows: [String] = ["date,type,category,amount,currency,note,code_type,code_value,source"]

        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]

        for tx in transactions.sorted(by: { $0.date < $1.date }) {
            let cells = [
                formatter.string(from: tx.date),
                tx.type.rawValue,
                tx.categoryRaw,
                String(format: "%.2f", tx.amount),
                "AMOUNT_CURRENCY_PLACEHOLDER",
                csvEscape(tx.note),
                tx.codeTypeRaw,
                csvEscape(tx.codeValue),
                tx.sourceRaw
            ]
            rows.append(cells.joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    static func json(from transactions: [Transaction]) throws -> Data {
        let payload: [[String: Any]] = transactions
            .sorted { $0.date < $1.date }
            .map { tx in
                [
                    "id": tx.id.uuidString,
                    "date": ISO8601DateFormatter().string(from: tx.date),
                    "type": tx.typeRaw,
                    "category": tx.categoryRaw,
                    "amount": tx.amount,
                    "note": tx.note,
                    "codeType": tx.codeTypeRaw,
                    "codeValue": tx.codeValue,
                    "source": tx.sourceRaw
                ]
            }
        return try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    }

    private static func csvEscape(_ value: String) -> String {
        if value.contains(",") || value.contains("\"") || value.contains("\n") {
            return "\"" + value.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return value
    }

    /// เขียนลงไฟล์ชั่วคราวแล้วคืน URL ให้ ShareLink ใช้แชร์
    static func writeTemporaryFile(named name: String, data: Data) throws -> URL {
        let folder = FileManager.default.temporaryDirectory
        let url = folder.appendingPathComponent(name)
        try data.write(to: url, options: .atomic)
        return url
    }

    static func csvURL(from transactions: [Transaction], currencyCode: String) throws -> URL {
        let csv = csv(from: transactions).replacingOccurrences(
            of: "AMOUNT_CURRENCY_PLACEHOLDER",
            with: currencyCode
        )
        return try writeTemporaryFile(
            named: "receipt-ledger-\(fileStamp()).csv",
            data: Data(csv.utf8)
        )
    }

    static func jsonURL(from transactions: [Transaction]) throws -> URL {
        let data = try json(from: transactions)
        return try writeTemporaryFile(
            named: "receipt-ledger-\(fileStamp()).json",
            data: data
        )
    }

    private static func fileStamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter.string(from: .now)
    }
}
