import Foundation
import SwiftData

/// สร้างข้อมูลตัวอย่างรอบแรกที่เปิดแอป
/// เพื่อให้เห็นกราฟและหน้าประวัติทันที ไม่ต้องเริ่มจากจอว่างเปล่า
enum SampleData {
    static let seedFlagKey = "didSeedSampleData"

    static func seedIfNeeded(_ context: ModelContext, calendar: Calendar = .current) {
        guard !UserDefaults.standard.bool(forKey: seedFlagKey) else { return }

        let existing = (try? context.fetchCount(FetchDescriptor<Transaction>())) ?? 0
        if existing > 0 {
            // มีข้อมูลจริงอยู่แล้ว (เช่น กู้คืนมาจากเครื่องอื่น) ไม่ต้องทับ
            UserDefaults.standard.set(true, forKey: seedFlagKey)
            return
        }

        let today = Date.now

        for tx in makeSamples(now: today, calendar: calendar) {
            context.insert(tx)
        }

        do {
            try context.save()
            UserDefaults.standard.set(true, forKey: seedFlagKey)
        } catch {
            // ไม่บล็อกการเปิดแอปถ้า seed ไม่สำเร็จ ผู้ใช้เพิ่มรายการเองได้
            assertionFailure("Seed failed: \(error)")
        }
    }

    /// ข้อมูล 6 เดือนย้อนหลัง ให้กราฟมีข้อมูลพอวาด
    static func makeSamples(now: Date, calendar: Calendar = .current) -> [Transaction] {
        var result: [Transaction] = []

        func date(monthsAgo: Int, day: Int) -> Date {
            let base = calendar.date(byAdding: .month, value: -monthsAgo, to: now) ?? now
            let comps = calendar.dateComponents([.year, .month], from: base)
            guard var start = calendar.date(from: comps) else { return now }
            let range = calendar.range(of: .day, in: .month, for: start) ?? 1...31
            let clampedDay = min(max(day, 1), range.upperBound - 1)
            start = calendar.date(bySetting: .day, value: clampedDay, of: start) ?? start
            return calendar.date(bySettingHour: 12, minute: 0, second: 0, of: start) ?? start
        }

        // (monthsAgo, day, type, category, amount, note, source)
        let rows: [(Int, Int, TransactionType, Category, Double, String, TransactionSource)] = [
            (0, 3, .expense, .food, 185.0, "ข้าวมันไก่", .scan),
            (0, 5, .expense, .transport, 42.0, "BTS สถานีสยาม", .manual),
            (0, 8, .income, .sales, 3200.0, "ยอดขายหน้าร้าน", .scan),
            (0, 11, .expense, .shopping, 1290.0, "ช้อปปิ้งออนไลน์", .scan),
            (0, 14, .expense, .bills, 890.0, "ค่าไฟ", .manual),
            (0, 18, .expense, .food, 640.0, "อาหารมื้อเย็น", .scan),
            (1, 2, .expense, .housing, 8500.0, "ค่าเช่า", .manual),
            (1, 6, .income, .sales, 4100.0, "ยอดขายหน้าร้าน", .scan),
            (1, 9, .expense, .transport, 320.0, "เติมน้ำมัน", .scan),
            (1, 15, .expense, .health, 1450.0, "ค่ายา", .manual),
            (1, 21, .expense, .food, 980.0, "เลี้ยงทีมงาน", .scan),
            (2, 4, .income, .salary, 22000.0, "เงินเดือน", .manual),
            (2, 7, .expense, .education, 2500.0, "คอร์สออนไลน์", .scan),
            (2, 12, .expense, .entertainment, 790.0, "แพ็กสตรีมมิง", .manual),
            (2, 19, .expense, .food, 1560.0, "จัดปาร์ตี้", .scan),
            (3, 3, .income, .sales, 3750.0, "ยอดขายหน้าร้าน", .scan),
            (3, 10, .expense, .shopping, 2340.0, "อุปกรณ์ร้าน", .scan),
            (3, 16, .expense, .transport, 180.0, "รถไฟฟ้า", .manual),
            (3, 25, .expense, .gifts, 500.0, "ของขวัญวันเกิด", .manual),
            (4, 5, .income, .bonus, 5000.0, "โบนัสประจำปี", .manual),
            (4, 11, .expense, .bills, 1120.0, "อินเทอร์เน็ต", .manual),
            (4, 17, .expense, .pets, 860.0, "อาหารสุนัข", .scan),
            (4, 23, .expense, .food, 2100.0, "งานเลี้ยง", .scan),
            (5, 4, .income, .sales, 2980.0, "ยอดขายหน้าร้าน", .scan),
            (5, 8, .expense, .housing, 8500.0, "ค่าเช่า", .manual),
            (5, 14, .expense, .health, 2400.0, "ตรวจสุขภาพ", .manual),
            (5, 20, .expense, .transport, 450.0, "ค่าทางด่วน", .scan),
            (5, 27, .expense, .investment, 1500.0, "ซื้อกองทุน", .manual)
        ]

        for row in rows {
            result.append(
                Transaction(
                    amount: row.4,
                    type: row.2,
                    category: row.3,
                    note: row.5,
                    date: date(monthsAgo: row.0, day: row.1),
                    source: row.6
                )
            )
        }
        return result
    }
}
