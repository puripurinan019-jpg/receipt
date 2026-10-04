# -*- coding: utf-8 -*-
# ตรวจ syntax พื้นฐานของ Swift โดยไม่ใช้ backslash ใน source
import io, os, sys, glob

BS = chr(92)
DQ = chr(34)
NL = chr(10)
problems = []
files = sorted(glob.glob('ReceiptLedger/**/*.swift', recursive=True))

for path in files:
    s = io.open(path, encoding='utf-8').read()
    stack = []
    line = 1
    i, n = 0, len(s)
    in_str = False
    multiline = False
    while i < n:
        c = s[i]
        if c == NL:
            line += 1
        if in_str:
            if not multiline and c == BS:
                i += 2
                continue
            if multiline:
                if s[i:i + 3] == DQ * 3:
                    in_str = False
                    multiline = False
                    i += 3
                    continue
            elif c == DQ:
                in_str = False
            i += 1
            continue
        # not in string
        if s[i:i + 3] == DQ * 3:
            in_str = True
            multiline = True
            i += 3
            continue
        if c == DQ:
            in_str = True
            i += 1
            continue
        if c == '/' and i + 1 < n and s[i + 1] == '/':
            j = s.find(NL, i)
            if j == -1:
                j = n
            i = j
            continue
        if c == '/' and i + 1 < n and s[i + 1] == '*':
            depth = 1
            i += 2
            while i < n and depth > 0:
                if s[i] == NL:
                    line += 1
                if s[i:i + 2] == '/*':
                    depth += 1
                    i += 2
                    continue
                if s[i:i + 2] == '*/':
                    depth -= 1
                    i += 2
                    continue
                i += 1
            continue
        if c in '({[':
            stack.append((c, line))
        elif c in ')}]':
            want = {'}': '{', ')': '(', ']': '['}[c]
            if not stack:
                problems.append((path, line, 'unmatched ' + c))
            else:
                opener, oline = stack.pop()
                if opener != want:
                    problems.append((path, line, 'mismatch ' + c + ' vs ' + opener + ' opened line ' + str(oline)))
        i += 1
    if stack:
        opener, oline = stack[-1]
        problems.append((path, oline, 'unclosed ' + opener))
    if in_str:
        problems.append((path, line, 'unterminated string'))
    # ต้องมี import อย่างน้อยหนึ่งอัน
    if 'import ' not in s:
        problems.append((path, 1, 'no import statement'))

print('checked files :', len(files))
if problems:
    print('PROBLEMS:', len(problems))
    for p in problems:
        print('  - %s:%d  %s' % p)
    sys.exit(1)
print('OK: all Swift files have balanced braces/parens and terminated literals')
