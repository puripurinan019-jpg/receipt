import SwiftUI
import AVFoundation
import UIKit

/// หน้าสแกน: เปิดกล้องสแกน QR/Barcode บนใบเสร็จ แล้วเด้งฟอร์มยืนยันเพื่อบันทึก
struct ScanView: View {
    @State private var pendingCode: ScannedCode?
    @State private var errorMessage: String?
    @State private var showManualInput = false
    @State private var manualCode = ""
    @State private var cameraStatus: AVAuthorizationStatus = .notDetermined

    var body: some View {
        NavigationStack {
            ZStack {
                Color.black.ignoresSafeArea()

                switch cameraState {
                case .ready:
                    scannerLayer
                case .unsupported:
                    unavailableView(message: "scan.unsupported")
                case .denied:
                    permissionDeniedView
                }
            }
            .navigationTitle("scan.title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.black, for: .navigationBar)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .safeAreaInset(edge: .bottom) {
                bottomBar
            }
            .onAppear(perform: refreshPermission)
            .onReceive(
                NotificationCenter.default.publisher(
                    for: UIApplication.didBecomeActiveNotification
                )
            ) { _ in
                refreshPermission()
            }
            .sheet(item: $pendingCode) { code in
                ScanConfirmSheet(scannedCode: code) {
                    pendingCode = nil
                }
            }
            .alert("scan.manualTitle", isPresented: $showManualInput) {
                TextField("scan.manualPlaceholder", text: $manualCode)
                Button("common.cancel", role: .cancel) {
                    manualCode = ""
                }
                Button("common.next") {
                    confirmManualCode()
                }
            } message: {
                Text("scan.manualMessage")
            }
            .alert(
                "scan.errorTitle",
                isPresented: Binding(
                    get: { errorMessage != nil },
                    set: { if !$0 { errorMessage = nil } }
                )
            ) {
                Button("common.ok", role: .cancel) { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    // MARK: - สถานะกล้อง

    private enum CameraState {
        case ready
        case unsupported
        case denied
    }

    private var cameraState: CameraState {
        if !CodeScannerView.isSupported { return .unsupported }
        switch cameraStatus {
        case .denied, .restricted: return .denied
        default: return .ready
        }
    }

    private func refreshPermission() {
        cameraStatus = AVCaptureDevice.authorizationStatus(for: .video)
        if cameraStatus == .notDetermined {
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    cameraStatus = granted ? .authorized : .denied
                }
            }
        }
    }

    // MARK: - จอต่าง ๆ

    @ViewBuilder
    private var scannerLayer: some View {
        // pendingCode != nil → ถอด scanner ออก เพื่อปล่อยกล้องระหว่างกรอกฟอร์ม
        // และเพื่อให้รอบสแกนถัดไปเริ่มด้วย state ใหม่สะอาด
        if pendingCode == nil {
            CodeScannerView(
                onDetect: { code in
                    pendingCode = code
                },
                onError: { message in
                    errorMessage = message
                }
            )
            .ignoresSafeArea()
        } else {
            Color.black.ignoresSafeArea()
        }

        overlayFrame
    }

    private var overlayFrame: some View {
        VStack(spacing: 20) {
            Spacer()

            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.85), lineWidth: 3)
                .frame(width: 240, height: 240)
    
            Text("scan.instruction")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Spacer()
        }
    }

    private func unavailableView(message: LocalizedStringKey) -> some View {
        VStack(spacing: 14) {
            Image(systemName: "camera.metering.unknown")
                .font(.system(size: 42))
                .foregroundStyle(.white.opacity(0.7))
            Text(message)
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.85))
                .multilineTextAlignment(.center)
            Text("scan.manualHint")
                .font(.caption)
                .foregroundStyle(.white.opacity(0.55))
                .multilineTextAlignment(.center)
        }
        .padding(32)
    }

    private var permissionDeniedView: some View {
        VStack(spacing: 16) {
            Image(systemName: "camera.fill")
                .font(.system(size: 42))
                .foregroundStyle(.white.opacity(0.7))
            Text("scan.denied")
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.9))
                .multilineTextAlignment(.center)

            Button("scan.openSettings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(32)
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            Button {
                manualCode = ""
                showManualInput = true
            } label: {
                Label("scan.manualEntry", systemImage: "keyboard")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
            .tint(.white)
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(.ultraThinMaterial)
    }

    private func confirmManualCode() {
        let trimmed = manualCode.trimmingCharacters(in: .whitespacesAndNewlines)
        manualCode = ""
        guard !trimmed.isEmpty else { return }
        pendingCode = ScannedCode(payload: trimmed, type: .other)
    }
}
