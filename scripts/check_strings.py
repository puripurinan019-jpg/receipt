# -*- coding: utf-8 -*-
# ตรวจว่า localization key ที่โค้ดอ้างครบทุกตัวใน Localizable.xcstrings
# และไม่มี key ตายที่ไม่มีใครใช้ (เก็บไฟล์ catalog ให้สะอาด)
import json, io, glob, re, sys

CATALOG = 'ReceiptLedger/Resources/Localizable.xcstrings'
PREFIXES = ('tab.', 'home.', 'period.', 'charts.', 'scan.', 'record.',
            'history.', 'common.', 'detail.', 'settings.', 'category.',
            'source.', 'codeType.')

try:
    doc = json.load(io.open(CATALOG, encoding='utf-8'))
except Exception as exc:
    print('FAILED: cannot parse ' + CATALOG + ': ' + str(exc))
    sys.exit(1)

catalog = set(doc.get('strings', {}).keys())
if not catalog:
    print('FAILED: catalog has no strings')
    sys.exit(1)

# 1) key ที่มาจาก string literal ในโค้ด
used = set()
for path in glob.glob('ReceiptLedger/**/*.swift', recursive=True):
    text = io.open(path, encoding='utf-8').read()
    for m in re.finditer(r'"([a-zA-Z][a-zA-Z0-9]*(?:\.[a-zA-Z0-9]+)+)"', text):
        if m.group(1).startswith(PREFIXES):
            used.add(m.group(1))

# สอง key นี้ไม่มีจุด จึงเติมมือ
used |= {'income', 'expense'}

# 2) key ที่ประกอบขึ้นจาก interpolation: "category.<rawValue>"
cat_src = io.open('ReceiptLedger/Models/Category.swift', encoding='utf-8').read()
for m in re.finditer(r'(?m)^\s+case (\w+)$', cat_src):
    used.add('category.' + m.group(1))

# 3) key ที่ประกอบขึ้นจาก interpolation: "codeType.<rawValue>"
ct_src = io.open('ReceiptLedger/Services/CodeParser.swift', encoding='utf-8').read()
if 'enum CodeType' not in ct_src:
    print('FAILED: CodeType not found in CodeParser.swift')
    sys.exit(1)
block = ct_src.split('enum CodeType', 1)[1].split('}', 1)[0]
for m in re.finditer(r'case (\w+)', block):
    used.add('codeType.' + m.group(1))

missing = sorted(used - catalog)
unused = sorted(catalog - used)

print('used keys   :', len(used))
print('catalog keys:', len(catalog))

errors = []
if missing:
    errors.append('referenced but missing from catalog: ' + str(missing))
if unused:
    errors.append('present in catalog but never used: ' + str(unused))

if errors:
    print()
    print('FAILED ' + str(len(errors)) + ':')
    for e in errors:
        print('  - ' + e)
    sys.exit(1)

print('OK: localization keys match exactly in both directions')
