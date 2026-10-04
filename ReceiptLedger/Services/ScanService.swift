import SwiftUI
import VisionKit

/// ห่อ DataScannerViewController ของ VisionKit ไว้ใช้ใน SwiftUI
/// สแกนสดแบบวางกล้องบนโค้ด แล้วไฮไลต์ให้ทันที
///
/// วิธีใช้: View รอบนอกจะ unmount คอมโพเนนต์นี้ทันทีที่จับโค้ดได้
/// ทำให้ camera ถูกปล่อยและ coordinator ถูกสร้างใหม่ตอนสแกนครั้งต่อไป
/// ไม่ต้องมี state ซับซ้อนในการสั่ง start/stop
struct CodeScannerView: UIViewControllerRepresentable {
    private let onDetect: (ScannedCode) -> Void
    private let onError: (String) -> Void

    /// เขียน init เองเพื่อระบุ @escaping ชัดเจน
    /// (memberwise initializer ของการประกาศ `let` closure ไม่การันตีว่าจะใส่ @escaping ให้)
    init(
        onDetect: @escaping (ScannedCode) -> Void,
        onError: @escaping (String) -> Void
    ) {
        self.onDetect = onDetect
        self.onError = onError
    }

    static var isSupported: Bool {
        DataScannerViewController.supportsScanning
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(onDetect: onDetect, onError: onError)
    }

    func makeUIViewController(context: Context) -> DataScannerViewController {
        let controller = DataScannerViewController(
            allowedDataTypes: [.barcode],
            recognizesMultipleItems: false
        )
        controller.delegate = context.coordinator

        // DataScannerViewController ต้องสั่ง startScanning เองหลังถูก present
        DispatchQueue.main.async {
            guard DataScannerViewController.supportsScanning else { return }
            if !controller.isScanning {
                controller.startScanning()
            }
        }
        return controller
    }

    func updateUIViewController(_ controller: DataScannerViewController, context: Context) {
        // ไม่มี state ภายนอกที่ต้องซิงก์
    }

    static func dismantleUIViewController(
        _ controller: DataScannerViewController,
        coordinator: Coordinator
    ) {
        if controller.isScanning {
            controller.stopScanning()
        }
    }

    final class Coordinator: NSObject, DataScannerViewControllerDelegate {
        private let onDetect: (ScannedCode) -> Void
        private let onError: (String) -> Void
        private var lastPayload: String?

        init(onDetect: @escaping (ScannedCode) -> Void, onError: @escaping (String) -> Void) {
            self.onDetect = onDetect
            self.onError = onError
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didAdd addedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            handle(allItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didUpdate updatedItems: [RecognizedItem],
            allItems: [RecognizedItem]
        ) {
            handle(allItems)
        }

        func dataScanner(
            _ dataScanner: DataScannerViewController,
            didFinishWith error: Error
        ) {
            onError(error.localizedDescription)
        }

        private func handle(_ items: [RecognizedItem]) {
            for item in items {
                guard case .barcode(let barcode) = item else { continue }
                guard let payload = barcode.payloadString, !payload.isEmpty else { continue }

                // กันไม่ให้รายงานโค้ดเดิมซ้ำ ๆ ระหว่างที่ยังอยู่ในเฟรมเดียวกัน
                if payload == lastPayload { return }
                lastPayload = payload

                onDetect(
                    ScannedCode(
                        payload: payload,
                        type: CodeType.from(symbology: barcode.symbology)
                    )
                )
                return
            }
        }
    }
}
