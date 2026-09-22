"""Decide whether condition function 566 takes an ALIAS INDEX.

The test: for every dialogue INFO using function 566, find the quest that owns
its topic (the DIAL's QNAM), read that quest's ANAM (its next free alias index,
so aliases run 0..ANAM-1), and check whether param1 falls inside that range.

"param1 is small" is a hint. "param1 is ALWAYS inside the owning quest's own
alias range, across thousands of records" is evidence, because a small number
that meant anything else would have no reason to respect a per-quest bound.

Overture needs this because its greeting is currently unconditioned -- every
actor offers it -- and O-7 cannot be built until the greeting can say "the
speaker is my Target alias". A CTDA written from a guess fails silently.

    python tools/ctda_alias_check.py
    python tools/ctda_alias_check.py --func 566
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


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--esm', default=r'D:\GOGGames\Fallout 4 GOTY\Data\Fallout4.esm')
    ap.add_argument('--func', type=int, default=566)
    args = ap.parse_args()

    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')
    buf = p.read_bytes()

    quest_aliases = {}       # quest form id -> ANAM (alias count)
    dial_owner = {}          # dial form id -> quest form id
    current_dial = [None]
    uses = []                # (quest, param1)

    def visit(sig, formid, data):
        if sig == b'QUST':
            for t, pay in fields(data):
                if t == b'ANAM' and len(pay) == 4:
                    quest_aliases[formid] = struct.unpack('<I', pay)[0]
                    break
        elif sig == b'DIAL':
            q = None
            for t, pay in fields(data):
                if t == b'QNAM' and len(pay) == 4:
                    q = struct.unpack('<I', pay)[0]
            dial_owner[formid] = q
            current_dial[0] = q
        elif sig == b'INFO':
            q = current_dial[0]
            for t, pay in fields(data):
                if t != b'CTDA' or len(pay) < 24:
                    continue
                if struct.unpack('<H', pay[8:10])[0] != args.func:
                    continue
                uses.append((q, struct.unpack('<I', pay[12:16])[0]))

    def walk(b):
        i, n = 0, len(b)
        while i + HDR <= n:
            sig = b[i:i + 4]
            size = struct.unpack('<I', b[i + 4:i + 8])[0]
            if sig == b'GRUP':
                walk(b[i + HDR:i + size])
                i += size
                continue
            flags = struct.unpack('<I', b[i + 8:i + 12])[0]
            formid = struct.unpack('<I', b[i + 12:i + 16])[0]
            data = b[i + HDR:i + HDR + size]
            if flags & 0x00040000:
                try:
                    data = zlib.decompress(data[4:])
                except zlib.error:
                    data = b''
            visit(sig, formid, data)
            i += HDR + size

    walk(buf)

    inside = outside = unknown = 0
    worst = collections.Counter()
    for q, p1 in uses:
        n = quest_aliases.get(q)
        if q is None or n is None:
            unknown += 1
        elif p1 < n:
            inside += 1
        else:
            outside += 1
            worst[(q, p1, n)] += 1

    total = len(uses)
    print(f'function {args.func}: {total:,} uses on dialogue INFOs')
    print(f'  owning quest known for {total - unknown:,}')
    print(f'  param1 INSIDE  the quest\'s alias range (0..ANAM-1): {inside:,}')
    print(f'  param1 OUTSIDE it:                                   {outside:,}')
    if total - unknown:
        pct = 100 * inside / (total - unknown)
        print(f'  -> {pct:.1f}% inside')
        if pct > 95:
            print('\n  VERDICT: param1 is an ALIAS INDEX. A number that meant anything else')
            print('  would have no reason to respect a per-quest bound this closely.')
    for (q, p1, n), c in worst.most_common(5):
        print(f'    outside: quest {q:08X} param1={p1} but ANAM={n}  ({c}x)')


if __name__ == '__main__':
    main()
