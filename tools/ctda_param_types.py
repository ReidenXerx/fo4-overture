"""Classify each condition function by WHAT KIND of record its parameter names.

Overture needs to gate a dialogue line on the NPC's persona, which is Rapport's
idea and not the engine's. The idiomatic way is a global variable the script
sets before the scene starts, and a condition comparing it -- which means
knowing the function index that reads a global. Guessing it means a line that
silently never appears.

The method that worked for the alias function: build a map of every form id in
Fallout4.esm to the record type that defines it, then for each condition
function look at what its parameters resolve to. A function whose param1 is
nearly always a GLOB is the one that reads a global.

    python tools/ctda_param_types.py
    python tools/ctda_param_types.py --want GLOB
"""
import argparse
import collections
import pathlib
import struct
import sys
import zlib

HDR = 24


def fields(data):
    i, n, big = 0, len(data), None
    while i + 6 <= n:
        typ = data[i:i + 4]
        ln = struct.unpack('<H', data[i + 4:i + 6])[0]
        i += 6
        if typ == b'XXXX':
            big = struct.unpack('<I', data[i:i + 4])[0]
            i += ln
            continue
        if big is not None:
            ln, big = big, None
        yield typ, data[i:i + ln]
        i += ln


def walk(buf, visit):
    i, n = 0, len(buf)
    while i + HDR <= n:
        sig = buf[i:i + 4]
        size = struct.unpack('<I', buf[i + 4:i + 8])[0]
        if sig == b'GRUP':
            walk(buf[i + HDR:i + size], visit)
            i += size
            continue
        flags = struct.unpack('<I', buf[i + 8:i + 12])[0]
        formid = struct.unpack('<I', buf[i + 12:i + 16])[0]
        data = buf[i + HDR:i + HDR + size]
        if flags & 0x00040000:
            try:
                data = zlib.decompress(data[4:])
            except zlib.error:
                data = b''
        visit(sig, formid, data)
        i += HDR + size


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--esm', default=r'D:\GOGGames\Fallout 4 GOTY\Data\Fallout4.esm')
    ap.add_argument('--want', default=None, help='only functions whose param1 is mostly this type')
    ap.add_argument('--min', type=int, default=20)
    args = ap.parse_args()

    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')
    buf = p.read_bytes()

    # pass 1: every form id -> the record type that defines it
    kind = {}

    def index(sig, formid, data):
        kind[formid] = sig.decode('latin1')

    walk(buf, index)
    print(f'indexed {len(kind):,} forms')

    # pass 2: every condition on a dialogue INFO
    p1kind = collections.defaultdict(collections.Counter)
    total = collections.Counter()
    example = {}

    def survey(sig, formid, data):
        if sig != b'INFO':
            return
        for t, pay in fields(data):
            if t != b'CTDA' or len(pay) < 24:
                continue
            func = struct.unpack('<H', pay[8:10])[0]
            a = struct.unpack('<I', pay[12:16])[0]
            total[func] += 1
            p1kind[func][kind.get(a, 'not-a-form')] += 1
            example.setdefault((func, kind.get(a, 'not-a-form')), a)

    walk(buf, survey)

    rows = []
    for func, n in total.items():
        if n < args.min:
            continue
        top, c = p1kind[func].most_common(1)[0]
        rows.append((func, n, top, 100 * c / n))

    if args.want:
        rows = [r for r in rows if r[2] == args.want]
        rows.sort(key=lambda r: -r[1])
        print(f'\nfunctions whose param1 is mostly a {args.want}:')
        for func, n, top, pct in rows:
            ex = example.get((func, top), 0)
            print(f'  function {func:>5}  {n:>7,} uses  {pct:>5.0f}% {top}   e.g. param1={ex:08X}')
        return

    rows.sort(key=lambda r: -r[1])
    print(f'\n{"func":>6} {"uses":>8}  param1 is mostly')
    for func, n, top, pct in rows[:24]:
        print(f'{func:>6} {n:>8,}  {pct:>5.0f}% {top}')


if __name__ == '__main__':
    main()
