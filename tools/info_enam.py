"""Does an INFO's ENAM decide whether the engine picks among a topic's lines?

Overture's variants do not rotate: each cell holds two lines with identical
conditions and the engine returns the same one every read. Setting the topic's
DATA[1] bit 0x04 changed nothing (tools/dial_flags.py found that bit on every
topic type that really does vary). The remaining lead is the INFO's own ENAM,
which is 0 on our lines and 4 on our greeting.

This groups every dialogue INFO by ENAM and by whether its topic holds one line
or several. A flag meaning "one of several" should be common on lines in
many-line topics and rare on lines that are alone.

    python tools/info_enam.py
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

    alone = collections.Counter()    # ENAM -> lines whose topic holds exactly 1
    among = collections.Counter()    # ENAM -> lines whose topic holds several
    by_type = collections.defaultdict(collections.Counter)
    state = {'tifc': 1, 'snam': ''}

    def visit(sig, formid, data):
        if sig == b'DIAL':
            state['tifc'] = 1
            state['snam'] = ''
            for t, pay in fields(data):
                if t == b'TIFC' and len(pay) == 4:
                    state['tifc'] = struct.unpack('<I', pay)[0]
                elif t == b'SNAM' and len(pay) == 4:
                    state['snam'] = pay.decode('latin1')
        elif sig == b'INFO':
            for t, pay in fields(data):
                if t == b'ENAM' and len(pay) == 4:
                    e = struct.unpack('<I', pay)[0]
                    (among if state['tifc'] > 1 else alone)[e] += 1
                    by_type[state['snam']][e] += 1
                    break

    walk(p.read_bytes(), visit)

    print(f'{"ENAM":>10} {"alone":>9} {"among many":>11} {"% among":>8}')
    for e in sorted(set(alone) | set(among), key=lambda k: -(alone[k] + among[k]))[:14]:
        a, m = alone[e], among[e]
        print(f'{e:>10} (0x{e:02X}) {a:>7,} {m:>11,} {100*m/max(a+m,1):>7.0f}%')

    print('\nby topic type (ENAM: count):')
    for snam, c in sorted(by_type.items(), key=lambda kv: -sum(kv[1].values()))[:6]:
        print(f'  {snam:6} ' + ', '.join(f'{k}:{v:,}' for k, v in c.most_common(4)))


if __name__ == '__main__':
    main()
