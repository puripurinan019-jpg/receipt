import SwiftUI
import SwiftData

/// หน้าตั้งค่า: สกุลเงิน, ภาษา, หมวดหมู่, ส่งออกข้อมูล, ล้างข้อมูล, เกี่ยวกับแอป
struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

    @AppStorage(AppSettings.currencyKey) private var currencyCode = AppSettings.defaultCurrency
    @AppStorage(AppSettings.languageKey) private var appLanguage = AppSettings.defaultLanguage

    @State private var exportURL: URL?
    @State private var errorMessage: String?
    @State private var showResetConfirm = false

    private var appVersion: String {
        let info = Bundle.main.infoDictionary
        let version = info?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = info?["CFBundleVersion"] as? String ?? "1"
        return "\(version) (\(build))"
    }

    var body: some View {
        NavigationStack {
            Form {
                generalSection
                categorySection
                dataSection
                aboutSection
            }
            .navigationTitle("settings.title")
            .sheet(isPresented: exportBinding) {
                exportSheet
            }
            .confirmationDialog(
                "settings.resetConfirmTitle",
                isPresented: $showResetConfirm,
                titleVisibility: .visible
            ) {
                Button("settings.reset", role: .destructive) {
                    resetAllData()
                }
                Button("common.cancel", role: .cancel) {}
            } message: {
                Text("settings.resetConfirm")
            }
            .alert(
                "settings.errorTitle",
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

    // MARK: - ส่วนต่าง ๆ

    private var generalSection: some View {
        Section("settings.general") {
            Picker("settings.currency", selection: $currencyCode) {
                ForEach(AppTheme.supportedCurrencies, id: \.self) { code in
                    Text(currencyLabel(code)).tag(code)
                }
            }

            Picker("settings.language", selection: $appLanguage) {
                Text("settings.language.auto").tag("auto")
                Text("settings.language.th").tag("th")
                Text("settings.language.en").tag("en")
            }
        }
    }

    private var categorySection: some View {
        Section("settings.categories") {
            categoryRows(for: .expense)
            categoryRows(for: .income)
        }
    }

    private func categoryRows(for type: TransactionType) -> some View {
        ForEach(Category.cases(for: type)) { category in
            HStack {
                Image(systemName: category.systemImage)
                    .frame(width: 24)
                    .foregroundStyle(category.tint)
                Text(category.titleKey)
                Spacer()
                Text("\(count(for: category))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var dataSection: some View {
        Section("settings.data") {
            Button {
                prepareExport(.csv)
            } label: {
                Label("settings.exportCSV", systemImage: "square.and.arrow.up")
            }

            Button {
                prepareExport(.json)
            } label: {
                Label("settings.exportJSON", systemImage: "curlybraces")
            }

            Button(role: .destructive) {
                showResetConfirm = true
            } label: {
                Label("settings.reset", systemImage: "trash")
            }
        }
    }

    private var aboutSection: some View {
        Section("settings.about") {
            LabeledContent("settings.version") {
                Text(appVersion)
                    .foregroundStyle(.secondary)
            }

            LabeledContent("settings.transactionCount") {
                Text("\(transactions.count)")
                    .foregroundStyle(.secondary)
            }

            Text("settings.storageNote")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    // MARK: - ส่งออก

    private enum ExportFormat {
        case csv
        case json
    }

    private var exportBinding: Binding<Bool> {
        Binding(
            get: { exportURL != nil },
            set: { if !$0 { exportURL = nil } }
        )
    }

    private var exportSheet: some View {
        NavigationStack {
            Group {
                if let exportURL {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 46))
                            .foregroundStyle(AppTheme.incomeColor)
                        Text("settings.exportReady")
                            .font(.headline)

                        ShareLink(item: exportURL) {
                            Label("settings.shareFile", systemImage: "square.and.arrow.up")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                        .padding(.horizontal, 32)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("settings.export")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.done") { exportURL = nil }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func prepareExport(_ format: ExportFormat) {
        do {
            switch format {
            case .csv:
                exportURL = try ExportService.csvURL(from: transactions, currencyCode: currencyCode)
            case .json:
                exportURL = try ExportService.jsonURL(from: transactions)
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    // MARK: - อื่น ๆ

    private func count(for category: Category) -> Int {
        transactions.filter { $0.category == category }.count
    }

    private func currencyLabel(_ code: String) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = code
        formatter.maximumFractionDigits = 0
        let name = formatter.string(from: NSNumber(value: 0)) ?? code
        return "\(name) · \(code)"
    }

    private func resetAllData() {
        for tx in transactions {
            modelContext.delete(tx)
        }
        do {
            // คง flag ไว้ เพื่อไม่ให้ seed ข้อมูลตัวอย่างทับหลังผู้ใช้ล้างเอง
            try modelContext.save()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
