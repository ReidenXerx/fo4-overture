"""What in a DIAL record makes the engine pick among its lines?

Overture gives each topic several lines -- one per persona, and variants within
a persona -- and the engine returned the SAME line on three consecutive reads,
while a vanilla barter topic returns four different sentences on four reads. So
something marks a topic as "choose among these", and ours does not carry it.

A DIAL's DATA is four bytes. [2] is the category (15 for scene player dialogue).
[1] is unexplained. This groups every DIAL by DATA[1] and by how many lines it
holds (TIFC), on the theory that a flag meaning "pick one at random" will be
common on topics with many lines and rare on topics with one.

    python tools/dial_flags.py
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
    args = ap.parse_args()
    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')

    # DATA[1] value -> (topics with 1 line, topics with >1 line)
    single = collections.Counter()
    multi = collections.Counter()
    bycat = collections.defaultdict(collections.Counter)
    example = {}

    def visit(sig, formid, data):
        if sig != b'DIAL':
            return
        flags = cat = tifc = None
        snam = ''
        for t, pay in fields(data):
            if t == b'DATA' and len(pay) >= 3:
                flags, cat = pay[1], pay[2]
            elif t == b'TIFC' and len(pay) == 4:
                tifc = struct.unpack('<I', pay)[0]
            elif t == b'SNAM' and len(pay) == 4:
                snam = pay.decode('latin1')
        if flags is None or tifc is None:
            return
        (multi if tifc > 1 else single)[flags] += 1
        bycat[snam][flags] += 1
        if tifc > 1:
            example.setdefault(flags, (formid, snam, tifc))

    walk(p.read_bytes(), visit)

    print(f'{"DATA[1]":>8} {"1 line":>9} {"many lines":>11} {"% many":>7}   example')
    for flags in sorted(set(single) | set(multi)):
        s, m = single[flags], multi[flags]
        ex = example.get(flags)
        exs = f'{ex[0]:08X} {ex[1]} holds {ex[2]}' if ex else ''
        print(f'{flags:>8} (0x{flags:02X}) {s:>7,} {m:>11,} {100*m/max(s+m,1):>6.0f}%   {exs}')

    print('\nby topic type:')
    for snam, c in sorted(bycat.items(), key=lambda kv: -sum(kv[1].values()))[:8]:
        inner = ', '.join(f'{k}:{v:,}' for k, v in c.most_common(4))
        print(f'  {snam:6} {inner}')


if __name__ == '__main__':
    main()
