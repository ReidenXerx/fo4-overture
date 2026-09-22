"""Work out FO4's CTDA layout, and which condition function tests an ALIAS.

Overture's greeting is currently unconditioned, which means every actor offers
it while the quest runs. O-7 -- the registers appear when you talk to an
eligible NPC -- cannot be built until the greeting can say "the speaker is my
Target alias". That needs a CTDA, and a CTDA written from a guess is the one
thing this project does not do.

So: survey every CTDA on a dialogue INFO in Fallout4.esm, histogram the function
indices, and for each one report what its first parameter looks like. A function
whose param1 is always a small integer is taking an INDEX (an alias, a slot),
not a form id -- and an alias check is exactly that shape.

    python tools/ctda_survey.py
    python tools/ctda_survey.py --func 72        # everything about one function

The layout this assumes, derived from four real CTDAs on FFGoodneighbor02's
greeting and checked against the survey:

    0       operator and flags
    1-3     unused
    4-7     comparison value (float)
    8-9     function index (uint16)
    10-11   padding
    12-15   parameter 1
    16-19   parameter 2
    20-23   run-on type
    24-27   reference
    28-31   unused / parameter 3
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
        data = buf[i + HDR:i + HDR + size]
        if flags & 0x00040000:
            try:
                data = zlib.decompress(data[4:])
            except zlib.error:
                data = b''
        visit(sig, data)
        i += HDR + size


def parse(pay):
    """-> (op, value, func, p1, p2, runon)"""
    op = pay[0]
    value = struct.unpack('<f', pay[4:8])[0]
    func = struct.unpack('<H', pay[8:10])[0]
    p1 = struct.unpack('<I', pay[12:16])[0]
    p2 = struct.unpack('<I', pay[16:20])[0]
    runon = struct.unpack('<I', pay[20:24])[0] if len(pay) >= 24 else 0
    return op, value, func, p1, p2, runon


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--esm', default=r'D:\GOGGames\Fallout 4 GOTY\Data\Fallout4.esm')
    ap.add_argument('--func', type=int, default=None)
    ap.add_argument('--top', type=int, default=16)
    args = ap.parse_args()

    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')

    counts = collections.Counter()
    small_p1 = collections.Counter()   # func -> how many have a small param1
    examples = collections.defaultdict(list)
    runons = collections.defaultdict(collections.Counter)

    def visit(sig, data):
        if sig != b'INFO':
            return
        for t, pay in fields(data):
            if t != b'CTDA' or len(pay) < 24:
                continue
            op, value, func, p1, p2, runon = parse(pay)
            counts[func] += 1
            runons[func][runon] += 1
            if p1 < 256:
                small_p1[func] += 1
            if len(examples[func]) < 4:
                examples[func].append((op, value, p1, p2, runon))

    walk(p.read_bytes(), visit)

    if args.func is not None:
        f = args.func
        print(f'function {f}: {counts[f]:,} conditions on dialogue INFOs')
        print(f'  param1 < 256 in {small_p1[f]:,} of them '
              f'({100*small_p1[f]/max(counts[f],1):.0f}%)')
        print(f'  run-on types: {dict(runons[f])}')
        for op, value, p1, p2, runon in examples[f]:
            print(f'    op=0x{op:02X} value={value} p1={p1} (0x{p1:08X}) p2={p2} runon={runon}')
        return

    print(f'{"func":>6} {"count":>8} {"param1<256":>11} {"share":>6}   most common run-on')
    for func, n in counts.most_common(args.top):
        small = small_p1[func]
        ro = runons[func].most_common(1)[0]
        print(f'{func:>6} {n:>8,} {small:>11,} {100*small/n:>5.0f}%   runon={ro[0]} ({ro[1]:,})')

    print('\nFunctions whose param1 is ALWAYS small - these take an INDEX, not a form id:')
    for func, n in counts.most_common(60):
        if n >= 50 and small_p1[func] == n:
            ex = examples[func][0]
            print(f'  function {func:>5}  {n:>7,} uses   e.g. p1={ex[2]} p2={ex[3]} value={ex[1]}')


if __name__ == '__main__':
    main()
