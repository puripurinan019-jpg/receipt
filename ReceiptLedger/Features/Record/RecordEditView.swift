import SwiftUI
import SwiftData

/// ฟอร์มบันทึกรายรับ-รายจ่ายด้วยมือ
/// ใช้เป็นทั้งหน้า "บันทึก" (เพิ่มใหม่) และหน้าแก้ไขรายการ (ส่ง transaction เข้ามา)
struct RecordEditView: View {
    /// ถ้าเป็น nil = เพิ่มรายการใหม่, ถ้ามีค่า = แก้ไขรายการเดิม
    var transaction: Transaction? = nil
    /// เรียกหลังบันทึกสำเร็จ (ใช้ปิด sheet หรือรีเซ็ตฟอร์ม)
    var onSaved: (() -> Void)? = nil

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @AppStorage(AppSettings.currencyKey) private var currencyCode = AppSettings.defaultCurrency

    @State private var amountText = ""
    @State private var type: TransactionType = .expense
    @State private var category: Category = .food
    @State private var note = ""
    @State private var date: Date = .now
    @State private var showsAmountError = false
    @State private var didLoad = false

    @FocusState private var amountFocused: Bool

    private var isEditing: Bool { transaction != nil }

    var body: some View {
        Form {
            amountSection
            categorySection
            noteSection
            dateSection

            if let transaction {
                sourceSection(for: transaction)
            }
        }
        .navigationTitle(isEditing ? "record.editTitle" : "record.newTitle")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isEditing {
                ToolbarItem(placement: .cancellationAction) {
                    Button("common.cancel") { dismiss() }
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button("common.save") { save() }
                    .fontWeight(.semibold)
            }
        }
        .onAppear(perform: loadIfNeeded)
    }

    // MARK: - ส่วนของฟอร์ม

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
            DatePicker("record.date", selection: $date)
                .datePickerStyle(.compact)
        }
    }

    private func sourceSection(for tx: Transaction) -> some View {
        Section("record.source") {
            LabeledContent("record.source") {
                Text(tx.source.titleKey)
                    .foregroundStyle(.secondary)
            }

            if !tx.codeValue.isEmpty {
                HStack {
                    Text("scan.codeValue")
                    Spacer()
                    Text(tx.codeValue)
                        .font(.caption.monospaced())
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .multilineTextAlignment(.trailing)
                }

                LabeledContent("scan.codeType") {
                    Text(tx.codeType.titleKey)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - การทำงาน

    private func loadIfNeeded() {
        guard !didLoad else { return }
        didLoad = true

        guard let transaction else {
            date = .now
            return
        }

        amountText = String(format: "%.2f", transaction.amount)
        type = transaction.type
        category = transaction.category
        note = transaction.note
        date = transaction.date
    }

    private func save() {
        let normalized = amountText
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: ",", with: ".")

        guard let amount = Double(normalized), amount > 0 else {
            showsAmountError = true
            amountFocused = true
            return
        }
        showsAmountError = false

        let cleanNote = note.trimmingCharacters(in: .whitespacesAndNewlines)

        if let transaction {
            transaction.amount = amount
            transaction.type = type
            transaction.category = category
            transaction.note = cleanNote
            transaction.date = date
        } else {
            let created = Transaction(
                amount: amount,
                type: type,
                category: category,
                note: cleanNote,
                date: date,
                source: .manual
            )
            modelContext.insert(created)
        }

        if let onSaved {
            onSaved()
        } else {
            dismiss()
        }
    }
}

/// แท็บ "บันทึก" — ฟอร์มเพิ่มรายการใหม่ห่อใน NavigationStack
/// บันทึกแล้วจะ remount ฟอร์ม เพื่อล้างค่าที่กรอกไว้ให้ว่างพร้อมรายการถัดไป
struct RecordView: View {
    @State private var formID = UUID()

    var body: some View {
        NavigationStack {
            RecordEditView(onSaved: { formID = UUID() })
                .id(formID)
        }
    }
}
