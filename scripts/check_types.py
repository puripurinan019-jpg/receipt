# -*- coding: utf-8 -*-
# ตรวจว่า identifier ที่ขึ้นตัวใหญ่ซึ่งโค้ดอ้าง มีที่ declare ไว้ในโปรเจกต์
# หรือเป็นของ Swift/SwiftUI/SDK ถ้าเจอตัวที่ไม่รู้จัก = ส่อว่ามี typo → exit 1
import io, glob, re, sys, collections

files = sorted(p.replace(chr(92), '/') for p in glob.glob('ReceiptLedger/**/*.swift', recursive=True))
declared = collections.defaultdict(list)
sources = {}

# ประกาศ type ได้ทั้ง top-level และ nested, มี access modifier หรือ attribute นำหน้าก็ได้
DECL = re.compile(
    r'(?m)^[ \t]*(?:@\w+[ \t]+)*(?:(?:public|private|internal|fileprivate|open|final|indirect)[ \t]+)*'
    r'(?:struct|enum|class|protocol|actor|extension)[ \t]+([A-Z]\w*)'
)

for path in files:
    text = io.open(path, encoding='utf-8').read()
    sources[path] = text
    for m in DECL.finditer(text):
        declared[m.group(1)].append(path)

SDK = set('''
SwiftUI SwiftData VisionKit AVFoundation UIKit Charts Foundation Swift
View Color Text Image VStack HStack ZStack ScrollView List Form Section Picker
Label Button Spacer Divider NavigationStack NavigationLink ToolbarItem
TextField DatePicker LabeledContent Capsule RoundedRectangle Circle Path
LinearGradient ForEach Array Optional String Double Int Bool UInt UUID Date Data
URL NSNumber CGRect CGSize CGPoint CGFloat Any Void Self Never Result Error
NumberFormatter DateFormatter ISO8601DateFormatter Bundle UserDefaults Calendar
DateComponents Locale Notification FileManager JSONSerialization NotificationCenter
FetchRequest FetchDescriptor ModelContext ModelContainer Query State Binding
AppStorage Environment FocusState ViewBuilder ShareLink ConfirmationDialog
ProgressView Toggle Stepper Menu DisclosureGroup Group Box TabView WindowGroup
Scene Preview Menu ToolbarPlacement Popover Alert
UIViewControllerRepresentable Context Coordinator NSObject UIViewController
DataScannerViewController RecognizedItem BarcodeSymbology DataScannerViewControllerDelegate
AVCaptureDevice AVAuthorizationStatus UIApplication Publisher DispatchQueue
Transaction TransactionType TransactionSource Category CodeType ScannedCode
Period Summary MonthBucket BalancePoint CategorySlice Analytics AppTheme
AppSettings CodeParser CodeScannerView ExportService SampleData
RootTabView HomeView HistoryView ScanView RecordView SettingsView
ScanConfirmSheet RecordEditView TransactionDetailView ChartsPageView
EmptyStateView SectionHeader TransactionRow SummaryCard BalanceCard
BarByMonthChart DonutByCategoryChart BalanceTrendLineChart ChartLegendRow
CardBackground ViewModifier Modifier Content ShapeStyle Edge Insets EdgeInsets
BarMark LineMark AreaMark PointMark SectorMark Chart AxisMarks AxisGridLine
AxisTick AxisValueLabel StrokeStyle LocalizedStringKey TupleView
Attribute Bindable Codable CaseIterable Identifiable Equatable Hashable
Sendable Observable AnyObject App Model ProjectedValue ObservedObject
WrappedValue Some AnyPublisher
Rectangle CameraState ExportFormat
THB USD EUR JPY GBP SGD MYR CNY HKD AUD
AMOUNT_CURRENCY_PLACEHOLDER CFBundleShortVersionString CFBundleVersion HHmmss Seed BTS
'''.split())

used = collections.defaultdict(set)
for path, text in sources.items():
    code = re.sub(r'//[^\n]*', '', text)
    code = re.sub(r'/\*.*?\*/', '', code, flags=re.S)
    for m in re.finditer(r'\b([A-Z]\w{2,})\b', code):
        used[m.group(1)].add(path)

unknown = {}
for name, paths in used.items():
    if name in declared or name in SDK:
        continue
    unknown[name] = sorted(paths)

print('files checked  :', len(files))
print('types declared :', len(declared))
print('identifiers    :', len(used))

if unknown:
    print()
    print('FAILED: ' + str(len(unknown)) + ' identifier(s) not declared and not a known SDK symbol:')
    for name in sorted(unknown):
        print('  - ' + name + '  <- ' + ', '.join(unknown[name]))
    sys.exit(1)

print('OK: every referenced type resolves to a project declaration or an SDK symbol')
