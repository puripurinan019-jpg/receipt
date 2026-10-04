import SwiftUI
import SwiftData

@main
struct ReceiptLedgerApp: App {
    /// สร้าง container ครั้งเดียวตอนเปิดแอป แล้ว seed ข้อมูลตัวอย่างรอบแรก
    private let container: ModelContainer = {
        do {
            let container = try ModelContainer(for: Transaction.self)
            SampleData.seedIfNeeded(container.mainContext)
            return container
        } catch {
            fatalError("เปิดฐานข้อมูลไม่สำเร็จ: \(error.localizedDescription)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(container)
    }
}
