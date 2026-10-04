# ReceiptLedger

แอป iOS สำหรับสแกน QR Code และ Barcode บนใบเสร็จ เพื่อบันทึกรายรับ-รายจ่าย
แล้วนำมาสร้างกราฟในหน้าแยกต่างหาก

## หน้าจอ (5 แท็บตามที่กำหนด)

| แท็บ | ไฟล์ | ทำอะไร |
|---|---|---|
| หน้าหลัก | `Features/Home/HomeView.swift` | การ์ดยอดรวม (เลือกช่วง สัปดาห์/เดือน/ปี), กราฟสรุป, ปุ่ม "ดูกราฟทั้งหมด", รายการล่าสุด |
| สแกน | `Features/Scan/ScanView.swift` | เปิดกล้องสแกนสดด้วย VisionKit แล้วเด้งฟอร์มยืนยันให้กรอกยอด/หมวด/หมายเหตุ |
| ประวัติ | `Features/History/HistoryView.swift` | ค้นหา, กรองตามประเภท/หมวด, swipe เพื่อลบ, กดดูรายละเอียด |
| บันทึก | `Features/Record/RecordEditView.swift` | ฟอร์มเพิ่มรายรับ-รายจ่ายด้วยมือ (ไม่ต้องสแกน) |
| ตั้งค่า | `Features/Settings/SettingsView.swift` | สกุลเงิน, สลับภาษา, หมวดหมู่, ส่งออก CSV/JSON, ล้างข้อมูล |

**หน้ากราฟ** (`Features/Home/ChartsPageView.swift`) เปิดจากปุ่ม "ดูกราฟทั้งหมด" ในหน้าหลัก
ครอบคลุม กราฟแท่งรายรับ-รายจ่าย 6 เดือน, กราฟโดนัทตามหมวด, กราฟเส้นแนวโน้มยอดคงเหลือ

## สแต็ก

- iOS 17.0+ / SwiftUI
- **SwiftData** เก็บข้อมูลในเครื่องล้วน ไม่มี network call
- **VisionKit** (`DataScannerViewController`) สำหรับสแกน
- **Swift Charts** สำหรับกราฟ
- ไม่มี third-party dependency ใด ๆ

## วิธีเปิดและ build (ต้องใช้ Mac)

1. คัดโฟลเดอร์ `ReceiptLedger/`, `ReceiptLedger.xcodeproj/` และ `ReceiptLedger-Info.plist`
   ไปไว้ในเครื่อง Mac (ต้องอยู่ด้วยกัน 3 ตัวนี้)
2. เปิด `ReceiptLedger.xcodeproj` ด้วย **Xcode 16 ขึ้นไป**
3. เลือกแท็บ **Signing & Capabilities** แล้วเลือก Team ของคุณ
   (ถ้ายังไม่มี ให้เพิ่มบัญชี Apple ID ใน Xcode → Settings → Accounts)
4. เลือกอุปกรณ์ iPhone ที่เสียบอยู่ แล้วกด **Run** (ปุ่ม Play)
5. ตอนแอปขึ้นถามสิทธิ์กล้อง ให้กด **Allow**

> การสแกนใช้กล้องจริง จึง **ทดสอบใน Simulator ไม่ได้** ต้องใช้ iPhone จริงเท่านั้น

ถ้ามีข้อความเตือน `No signing certificate` ให้กด **Automatically manage signing**

## โครงสร้าง

```
ReceiptLedger.xcodeproj/     โปรเจกต์ Xcode 16 (objectVersion 77, synchronized folder)
ReceiptLedger-Info.plist     สิทธิ์กล้อง NSCameraUsageDescription และค่าแอป
ReceiptLedger/
  App/                       จุดเริ่มต้นแอป, TabView, ธีม, คอมโพเนนต์ใช้ร่วม
  Models/                    Transaction, Category, TransactionType
  Services/                  ScanService, CodeParser, Analytics, ExportService, SampleData
  Features/                  โค้ดของแต่ละหน้า
  Resources/                 Localizable.xcstrings (ไทย/อังกฤษ), Assets.xcassets
scripts/                     สคริปต์ตรวจงานที่ใช้ตอนพัฒนา
```

## ข้อมูลตัวอย่าง

รอบแรกที่เปิดแอปจะ seed ข้อมูลตัวอย่าง 6 เดือน (28 รายการ) เพื่อให้เห็นกราฟทันที
ผู้ใช้ล้างได้จาก **ตั้งค่า → ล้างข้อมูลทั้งหมด** และจะไม่ถูก seed ทับอีก

## ตรวจงานด้วยสคริปต์

```bash
python3 scripts/validate_pbxproj.py   # structure + internal refs ของ pbxproj
python3 scripts/lint_swift.py         # สมดุลวงเล็บ/string/comment ทุกไฟล์ Swift
python3 scripts/check_inits.py        # ไม่มี type ซ้ำ, call site ตรง init, แท็บครบ, @main เดี่ยว
python3 scripts/check_strings.py      # localization key ตรง catalog ทั้งสองทิศ
python3 scripts/check_types.py        # ทุก type ที่อ้างต้องมีที่ declare หรือเป็นของ SDK
```

ทั้ง 5 ตัว **exit 1 เมื่อเจอปัญหา** (พิสูจน์แล้วด้วย mutation test: ฉีด typo เข้าไป → fail,
ลบออก → ผ่าน) จึงไม่ใช่ check ที่ผ่านเสมอ

## ทดสอบโดยไม่ต้องมี Mac — CI บน GitHub Actions

ถ้าไม่มี Xcode ในเครื่อง ให้ push ขึ้น GitHub (repo **public**) แล้วให้ CI build แทน:
runner macOS ของ GitHub ฟรีไม่จำกัดสำหรับ public repo

```bash
git init
git add .
git commit -m "ReceiptLedger: iOS receipt scanner with charts"
git branch -M main
git remote add origin https://github.com/<ชื่อคุณ>/ReceiptLedger.git
git push -u origin main
```

แล้วเปิดหน้า **Actions** ของ repo — ไฟล์ `.github/workflows/ci.yml` จะรัน 2 job:

| job | runner | ทำอะไร |
|---|---|---|
| `structural` | ubuntu | รันสคริปต์ 5 ตัวด้านบน (~1 นาที) |
| `build` | **macos-15 (มี Xcode 16)** | `xcodebuild -target ReceiptLedger -sdk iphonesimulator build` |

ถ้า `build` fail ให้ก็อป **full log จากขั้น Build for iOS Simulator** มาให้ผม
นั่นคือ error จริงจาก Swift compiler — ผมแก้ตามนั้นได้เลย

## สิ่งที่ CI ยังทดสอบไม่ได้

- **การรันแอปบนเครื่องจริง** และ **การสแกนด้วยกล้อง** — ต้องมี iPhone จริง
  (Simulator ไม่มีกล้อง ใช้ `DataScannerViewController` ไม่ได้)
- **หน้าจอ/UX จริง** — ต้องเปิดดูเอง

ดังนั้นยังไงก็ต้องมี Mac + iPhone อยู่ดีในขั้นตอนสุดท้าย แต่ **CI จะดัก compile error
ให้เกือบหมดก่อนที่คุณจะได้จับเครื่อง Mac เสียอีก**
