import SwiftUI

/// ช่วงเวลาที่ใช้กรองข้อมูลในหน้าหลักและหน้ากราф
enum Period: String, CaseIterable, Identifiable, Sendable {
    case week
    case month
    case year

    var id: String { rawValue }

    var titleKey: LocalizedStringKey {
        switch self {
        case .week: return "period.week"
        case .month: return "period.month"
        case .year: return "period.year"
        }
    }

    func startDate(now: Date = .now, calendar: Calendar = .current) -> Date {
        let comps: DateComponents
        switch self {
        case .week:
            comps = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        case .month:
            comps = calendar.dateComponents([.year, .month], from: now)
        case .year:
            comps = calendar.dateComponents([.year], from: now)
        }
        return calendar.date(from: comps) ?? now
    }
}

/// ข้อมูลสรุปยอดสำหรับแสดงบนหน้าหลัก
struct Summary: Equatable {
    var income: Double = 0
    var expense: Double = 0

    var balance: Double { income - expense }
}

/// ยอดรวมของหนึ่งเดือน ใช้ในกราฟแท่ง
struct MonthBucket: Identifiable {
    let id = UUID()
    let monthStart: Date
    let income: Double
    let expense: Double
}

/// ยอดสะสม ณ แต่ละวัน ใช้ในกราฟเส้น
struct BalancePoint: Identifiable {
    let id = UUID()
    let date: Date
    let balance: Double
}

/// หมวดหมู่ + ยอดรวม ใช้ในกราฟโดนัท
struct CategorySlice: Identifiable {
    let category: Category
    let total: Double

    var id: String { category.id }
}

enum Analytics {
    static func filter(_ transactions: [Transaction], in period: Period, now: Date = .now) -> [Transaction] {
        let start = period.startDate(now: now)
        return transactions.filter { $0.date >= start && $0.date <= now }
    }

    static func summary(_ transactions: [Transaction]) -> Summary {
        var result = Summary()
        for tx in transactions {
            switch tx.type {
            case .income: result.income += tx.amount
            case .expense: result.expense += tx.amount
            }
        }
        return result
    }

    /// รวมยอดเป็นรายเดือนย้อนหลัง `count` เดือน รวมเดือนที่ไม่มีข้อมูลด้วย (ค่า 0)
    static func monthlyBuckets(
        _ transactions: [Transaction],
        count: Int,
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [MonthBucket] {
        let currentStart = calendar.date(
            from: calendar.dateComponents([.year, .month], from: now)
        ) ?? now

        var buckets: [MonthBucket] = []
        var lookup: [Date: (income: Double, expense: Double)] = [:]

        for tx in transactions {
            guard let monthStart = calendar.date(
                from: calendar.dateComponents([.year, .month], from: tx.date)
            ) else { continue }

            var entry = lookup[monthStart] ?? (0, 0)
            if tx.type == .income {
                entry.income += tx.amount
            } else {
                entry.expense += tx.amount
            }
            lookup[monthStart] = entry
        }

        for offset in stride(from: count - 1, through: 0, by: -1) {
            guard let start = calendar.date(byAdding: .month, value: -offset, to: currentStart) else { continue }
            let entry = lookup[start] ?? (0, 0)
            buckets.append(MonthBucket(monthStart: start, income: entry.income, expense: entry.expense))
        }
        return buckets
    }

    /// ยอดรวมตามหมวด ใช้เรียงจากมากไปน้อยในกราฟโดนัท
    static func slicesByCategory(_ transactions: [Transaction], type: TransactionType) -> [CategorySlice] {
        var totals: [Category: Double] = [:]
        for tx in transactions where tx.type == type {
            totals[tx.category, default: 0] += tx.amount
        }
        return totals
            .map { CategorySlice(category: $0.key, total: $0.value) }
            .sorted { $0.total > $1.total }
    }

    /// ยอดคงเหลือสะสมเรียงตามวัน ใช้วาดกราฟเส้นแนวโน้ม
    static func balanceSeries(
        _ transactions: [Transaction],
        now: Date = .now,
        calendar: Calendar = .current
    ) -> [BalancePoint] {
        let sorted = transactions.sorted { $0.date < $1.date }
        guard !sorted.isEmpty else { return [] }

        var running = 0.0
        var points: [BalancePoint] = []

        // จุดเริ่มต้น = ยอดก่อนรายการแรก เพื่อให้เส้นเริ่มจากฐานที่แท้จริง
        for tx in sorted {
            running += (tx.type == .income ? tx.amount : -tx.amount)
            points.append(BalancePoint(date: tx.date, balance: running))
        }

        // จุดท้ายผูกกับวันนี้เพื่อให้แกน X สิ้นสุดที่ปัจจุบัน
        if let last = points.last, calendar.isDate(last.date, inSameDayAs: now) == false {
            points.append(BalancePoint(date: now, balance: running))
        }
        return points
    }
}
