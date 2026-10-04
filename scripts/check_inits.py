# -*- coding: utf-8 -*-
import io, glob, re, collections, sys

files = sorted(glob.glob('ReceiptLedger/**/*.swift', recursive=True))
# glob บน Windows คืนพาธด้วย backslash จึงต้อง normalize ก่อนใช้เป็น key
src = {p.replace(chr(92), '/'): io.open(p, encoding='utf-8').read() for p in files}
files = [p.replace(chr(92), '/') for p in files]
errors = []

# ---- 1) ห้ามมีชื่อ type ซ้ำ (compile error แน่นอน) ----
decl = collections.defaultdict(list)
for p, s in src.items():
    for m in re.finditer(r'(?m)^\s*(?:@\w+\s+)?(?:final\s+)?(struct|enum|class|protocol|actor)\s+([A-Z]\w*)', s):
        decl[m.group(2)].append((p, m.group(1)))
for name, where in sorted(decl.items()):
    if len(where) > 1:
        errors.append('duplicate type ' + name + ' in ' + str(where))

# ---- 2) init ที่เขียนเอง ต้องตรงกับ call site ----
# CodeScannerView(onDetect:onError:)
if 'init(' in src['ReceiptLedger/Services/ScanService.swift']:
    calls = re.findall(r'CodeScannerView\(\s*([^)]*?)\)', src['ReceiptLedger/Features/Scan/ScanView.swift'], re.S)
    for c in calls:
        labels = [x.strip().split(':')[0].strip() for x in c.split(',') if ':' in x]
        if labels != ['onDetect', 'onError']:
            errors.append('CodeScannerView call labels wrong: ' + str(labels))

# ScanConfirmSheet(scannedCode:onDismiss:)
calls = re.findall(r'ScanConfirmSheet\(([^)]*?)\)', src['ReceiptLedger/Features/Scan/ScanView.swift'], re.S)
for c in calls:
    if 'scannedCode:' not in c:
        errors.append('ScanConfirmSheet call missing scannedCode: -> ' + c.strip())

# RecordEditView: transaction / onSaved เป็น optional จึงเรียกแบบตัดทอนได้
calls = []
for p, s in src.items():
    calls += re.findall(r'RecordEditView\(([^)]*?)\)', s, re.S)
for c in calls:
    if 'transaction:' not in c and 'onSaved:' not in c:
        errors.append('RecordEditView called with neither label -> ' + c.strip())

# ---- 3) ทุก View ที่ RootTabView อ้าง ต้องถูก declare ----
root = src['ReceiptLedger/App/RootTabView.swift']
tabs = re.findall(r'^\s{12}([A-Z]\w+)\(\)', root, re.M)
for t in tabs:
    if t not in decl:
        errors.append('tab view not declared: ' + t)

# ---- 4) @main ต้องมี exactly 1 ----
mains = [p for p, s in src.items() if '@main' in s]
if len(mains) != 1:
    errors.append('@main count = ' + str(len(mains)) + ' -> ' + str(mains))

# ---- 5) ทุก Features file ต้องถูก target (อยู่ใน ReceiptLedger/ sync group) ----
for p in files:
    if not p.replace(chr(92), '/').startswith('ReceiptLedger/'):
        errors.append('swift file outside synchronized group: ' + p)

print('types declared  :', len(decl))
print('tabs wired      :', tabs)
print('main entry      :', mains)
print('swift files     :', len(files))
if errors:
    print()
    print('FAILED ' + str(len(errors)) + ':')
    for e in errors:
        print('  - ' + e)
    sys.exit(1)
print('OK: no duplicate types, init call sites match, tabs wired, single @main')
