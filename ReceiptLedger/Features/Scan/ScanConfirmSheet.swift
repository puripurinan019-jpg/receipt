import SwiftUI
import SwiftData

/// ฟอร์มยืนยันหลังจับโค้ดได้: แสดงรหัสที่สแกน + ให้กรอกจำนวนเงิน/ประเภท/หมวด/หมายเหตุ
/// ถ้า payload เป็น QR จ่ายเงิน (EMVCo) จะเติมยอดให้อัตโนมัติ
struct ScanConfirmSheet: View {
    let scannedCode: ScannedCode
    private let onDismiss: () -> Void

    /// ระบุ @escaping ชัดเจน เพราะค่าถูกเก็บเป็น property แล้วเรียกภายหลัง
    init(scannedCode: ScannedCode, onDismiss: @escaping () -> Void) {
        self.scannedCode = scannedCode
        self.onDismiss = onDismiss
    }

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettings.currencyKey) private var currencyCode = AppSettings.defaultCurrency

    @State private var amountText: String = ""
    @State private var type: TransactionType = .expense
    @State private var category: Category = .food
    @State private var note: String = ""
    @State private var date: Date = .now
    @State private var merchantHint: String = ""
    @State private var showsAmountError = false
    @FocusState private var amountFocused: Bool

    private var parsed: CodeParser.Parsed {
        CodeParser.parse(payload: scannedCode.payload, type: scannedCode.type)
    }

    var body: some View {
        NavigationStack {
            Form {
                scannedCodeSection
                amountSection
                categorySection
                noteSection
                dateSection
            }
            .navigationTitle("record.newTitle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel", role: .cancel) {
                        close()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("common.save") {
                        save()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .presentationDetents([.large])
        .onAppear(perform: prefill)
    }

    // MARK: - ส่วนต่าง ๆ ของฟอร์ม

    private var scannedCodeSection: some View {
        Section {
            LabeledContent("scan.codeType") {
                Text(scannedCode.type.titleKey)
            }

            HStack {
                Text("scan.codeValue")
                Spacer()
                Text(scannedCode.payload)
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .truncationMode(.middle)
                    .multilineTextAlignment(.trailing)
            }

            if !merchantHint.isEmpty {
                LabeledContent("scan.merchant") {
                    Text(merchantHint)
                        .lineLimit(1)
                }
            }
        } header: {
            Text("scan.detected")
        }
    }

    private var amountSection: some View {
        Section {
            HStack {
                TextField("record.amount", text: $amountText)
                    .keyboardType(.decimalPad)
                    .focused($amountFocused)
                Text(currencyCode)
                    .foregroundStyle(.secondary)
                    .font(.subheadline)
            }

            if showsAmountError {
                Text("record.invalidAmount")
                    .font(.caption)
                    .foregroundStyle(AppTheme.expenseColor)
            }

            Picker("record.type", selection: $type) {
                ForEach(TransactionType.allCases) { item in
                    Text(item.titleKey).tag(item)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: type) { _, newValue in
                // หมวดต้องตรงกับชนิดเสมอ มิฉะนั้นจะเลือกหมวดรายจ่ายตอนเป็นรายรับได้
                if category.transactionType != newValue {
                    category = newValue.defaultCategory
                }
            }
        } header: {
            Text("record.amountSection")
        }
    }

    private var categorySection: some View {
        Section("record.category") {
            Picker("record.category", selection: $category) {
                ForEach(Category.cases(for: type)) { item in
                    Label {
                        Text(item.titleKey)
                    } icon: {
                        Image(systemName: item.systemImage)
                    }
                    .tag(item)
                }
            }
            .pickerStyle(.navigationLink)
        }
    }

    private var noteSection: some View {
        Section("record.note") {
            TextField("record.notePlaceholder", text: $note, axis: .vertical)
                .lineLimit(2...5)
        }
    }

    private var dateSection: some View {
        Section("record.date") {
            DatePicker("record.date", selection: $date, in: ...Date.now)
                .datePickerStyle(.compact)
        }
    }

    // MARK: - การทำงาน

    private func prefill() {
        let result = parsed
        if let amount = result.amount {
            amountText = String(format: "%.2f", amount)
        }
        if let name = result.merchantName {
            merchantHint = name
        }
        // เติม note แรกเริ่มจากชื่อร้าน ถ้ามี
        if note.isEmpty, let name = result.merchantName {
            note = name
        }
        date = .now
    }

    private func close() {
        dismiss()
        onDismiss()
    }

    private func save() {
        guard let amount = Double(amountText.replacingOccurrences(of: ",", with: ".")),
              amount > 0
        else {
            showsAmountError = true
            amountFocused = true
            return
        }

        let transaction = Transaction(
            amount: amount,
            type: type,
            category: category,
            note: note.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            codeValue: scannedCode.payload,
            codeType: scannedCode.type,
            source: .scan
        )
        modelContext.insert(transaction)

        dismiss()
        onDismiss()
    }
}
