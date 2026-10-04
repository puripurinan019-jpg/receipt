# -*- coding: utf-8 -*-
# Validator สำหรับ project.pbxproj โดยไม่ใช้ backslash ใน source เลย
# (เพื่อเลี่ยงปัญหา escape ของ heredoc ในสภาพแวดล้อมนี้)
import io, sys, re

PATH = 'ReceiptLedger.xcodeproj/project.pbxproj'
BS = chr(92)
errors = []
warnings = []

src = io.open(PATH, encoding='utf-8').read()

# ---------- 1) ตัด comment ออก (ระวัง string literal) ----------
def strip_comments(s):
    out = []
    i, n = 0, len(s)
    in_str = False
    while i < n:
        c = s[i]
        if in_str:
            out.append(c)
            if c == BS:
                if i + 1 < n:
                    out.append(s[i + 1])
                    i += 2
                    continue
            elif c == chr(34):
                in_str = False
            i += 1
            continue
        if c == chr(34):
            in_str = True
            out.append(c)
            i += 1
            continue
        if c == '/' and i + 1 < n and s[i + 1] == '*':
            j = s.find('*' + chr(47), i + 2)
            if j == -1:
                errors.append('unterminated block comment at offset ' + str(i))
                break
            out.append(' ' * (j + 2 - i))
            i = j + 2
            continue
        if c == '/' and i + 1 < n and s[i + 1] == '/':
            j = s.find(chr(10), i)
            if j == -1:
                j = n
            out.append(' ' * (j - i))
            i = j
            continue
        out.append(c)
        i += 1
    return ''.join(out)

clean = strip_comments(src)

# ---------- 2) สมดุลวงเล็บ ----------
stack = []
line = 1
in_str = False
i, n = 0, len(clean)
while i < n:
    c = clean[i]
    if c == chr(10):
        line += 1
    if in_str:
        if c == BS:
            i += 2
            continue
        if c == chr(34):
            in_str = False
        i += 1
        continue
    if c == chr(34):
        in_str = True
        i += 1
        continue
    if c in '({':
        stack.append((c, line))
    elif c in ')}':
        want = '(' if c == ')' else '{'
        if not stack:
            errors.append('unmatched ' + c + ' at line ' + str(line))
        else:
            opener, oline = stack.pop()
            if opener != want:
                errors.append('mismatch: ' + c + ' line ' + str(line) +
                              ' vs ' + opener + ' line ' + str(oline))
    i += 1
if stack:
    for opener, oline in stack[-5:]:
        errors.append('unclosed ' + opener + ' opened at line ' + str(oline))
if in_str:
    errors.append('unterminated string literal at EOF')

# ---------- 3) section markers ----------
def markers(word):
    return [l.strip() for l in src.splitlines() if l.strip().startswith('/* ' + word + ' ')]

def section_names(lines, word):
    names = []
    for l in lines:
        body = l.strip()
        body = body[3:]
        parts = body.split(' ', 1)
        body = parts[1] if len(parts) > 1 else body
        if body.endswith(' section ' + chr(42) + chr(47)):
            body = body[:-(len(' section ' + chr(42) + chr(47)))]
        names.append(body)
    return names

begins = section_names(markers('Begin'), 'Begin')
ends = section_names(markers('End'), 'End')
if begins != ends:
    errors.append('section marker mismatch: ' + str(begins) + ' vs ' + str(ends))

# ---------- 4) เก็บ ID 24 หลัก hex ----------
HEX = set('0123456789ABCDEF')

def scan_ids(text):
    ids = []
    i, n = 0, len(text)
    while i < n:
        if text[i] in HEX:
            j = i
            while j < n and text[j] in HEX:
                j += 1
            if j - i == 24:
                before = text[i - 1] if i > 0 else ' '
                after = text[j] if j < n else ' '
                if before not in HEX and after not in HEX and not before.isalpha():
                    ids.append(text[i:j])
            i = j
        else:
            i += 1
    return ids

all_ids = scan_ids(clean)

# นิยาม object: ID ที่ขึ้นต้นบรรทัดและมี "=" ตามมา
defined = set()
for raw in clean.splitlines():
    s = raw.strip()
    if not s or not (s[0] in HEX):
        continue
    cand = scan_ids(s + ' ')
    if not cand:
        continue
    tok = cand[0]
    if s.startswith(tok):
        rest = s[len(tok):]
        # ข้าม comment ที่คั่นระหว่าง ID กับเครื่องหมาย =
        out = []
        k, m = 0, len(rest)
        while k < m:
            if rest[k:k + 2] == '/*':
                j = rest.find('*/', k + 2)
                if j == -1:
                    break
                k = j + 2
                continue
            out.append(rest[k])
            k += 1
        rest = ''.join(out).lstrip()
        if rest.startswith(chr(61)):
            defined.add(tok)

referenced = set(all_ids)
undefined = sorted(referenced - defined)
if undefined:
    errors.append('referenced but never defined: ' + str(undefined))

# ---------- 5) ID ที่ผิดรูป (ขึ้นต้น DA7A แต่ไม่ใช่ 24 hex) ----------
bad = set()
for raw in clean.splitlines():
    for token in raw.replace(chr(9), ' ').replace(chr(10), ' ').split():
        token = token.strip('/*,;{}()=')
        if token.startswith('DA7A') and not re.fullmatch('[0-9A-F]{24}', token):
            bad.add(token)
if bad:
    errors.append('malformed object ids (must be 24 hex): ' + str(sorted(bad)))

# ---------- 6) isa ที่รู้จัก ----------
known = {'PBXFileReference', 'PBXFileSystemSynchronizedRootGroup',
         'PBXFrameworksBuildPhase', 'PBXGroup', 'PBXNativeTarget', 'PBXProject',
         'PBXResourcesBuildPhase', 'PBXSourcesBuildPhase',
         'XCBuildConfiguration', 'XCConfigurationList'}
isa_count = 0
for i, raw in enumerate(clean.splitlines()):
    s = raw.strip()
    if s.startswith('isa = '):
        isa_count += 1
        val = s[6:].rstrip(chr(59))
        if val not in known:
            errors.append('unknown isa ' + val)

# ---------- 7) การต่อ wiring ที่ต้องมี ----------
needles = [
    'fileSystemSynchronizedGroups',
    'PBXFileSystemSynchronizedRootGroup',
    'INFOPLIST_FILE = ' + chr(34) + 'ReceiptLedger-Info.plist' + chr(34) + ';',
    'GENERATE_INFOPLIST_FILE = NO;',
    'rootObject = DA7A000000000000000000A1',
    'path = ReceiptLedger;',
    'objectVersion = 77;',
    'compatibilityVersion = ' + chr(34) + 'Xcode 15.0' + chr(34) + ';',
    'preferredProjectObjectVersion = 77;',
    'mainGroup = DA7A000000000000000000A0;',
]
for nd in needles:
    if nd not in clean:
        errors.append('expected text missing: ' + nd)

# ---------- 8) ทุก build config ต้องมี name / isa ----------
for nd in ['name = Debug;', 'name = Release;',
           'defaultConfigurationName = Release;']:
    if nd not in clean:
        errors.append('missing: ' + nd)

print('objects defined :', len(defined))
print('unique ids      :', len(set(all_ids)))
print('isa entries     :', isa_count)
print('sections        :', len(begins))
if warnings:
    for w in warnings:
        print('WARNING:', w)
if errors:
    print()
    print('FAILED with ' + str(len(errors)) + ' error(s):')
    for e in errors:
        print('  - ' + e)
    sys.exit(1)
print('OK: pbxproj structure and internal references are consistent')
