"""Dump the exact record shape of a real PLAYER dialogue topic from Fallout4.esm.

An INFO that carries RNAM carries the text the player sees as a menu option, so
RNAM is what separates a selectable topic from a bark. This walks the file
keeping the enclosing DIAL in hand, finds DIAL/INFO pairs where the INFO has an
RNAM, and prints both records field by field.

That printout is the thing Overture's builder gets derived from. This project's
rule is to diff a working record in the SAME ROLE rather than extend a builder
for a different role and hope -- four confident theories were wrong about an
inert topic before a diff answered it first time.

    python tools/player_topic_shape.py
    python tools/player_topic_shape.py --examples 3 --category 15
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


def walk(buf, sink, dial=None):
    """Call sink(sig, formid, data, enclosing_dial) for DIAL and INFO records."""
    i, n = 0, len(buf)
    while i + HDR <= n:
        sig = buf[i:i + 4]
        size = struct.unpack('<I', buf[i + 4:i + 8])[0]
        if sig == b'GRUP':
            walk(buf[i + HDR:i + size], sink, dial)
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
        if sig == b'DIAL':
            dial = (formid, data)
        elif sig == b'INFO':
            sink(sig, formid, data, dial)
        i += HDR + size


def text_of(payload):
    return payload.rstrip(b'\x00').decode('utf-8', 'replace')


def show(label, formid, data):
    print(f'  --- {label} {formid:08X} ---')
    for typ, payload in fields(data):
        t = typ.decode('latin1')
        extra = ''
        if t in ('EDID', 'NAM1', 'RNAM', 'FULL'):
            extra = '   ' + text_of(payload)[:88]
        elif len(payload) == 4:
            extra = '   = 0x%08X' % struct.unpack('<I', payload)[0]
        print(f'    {t:5} len {len(payload):<5}{payload[:28].hex():<56}{extra}')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--esm', default=r'D:\GOGGames\Fallout 4 GOTY\Data\Fallout4.esm')
    ap.add_argument('--examples', type=int, default=2)
    ap.add_argument('--category', type=int, default=None,
                    help='only DIALs whose DATA[2] equals this')
    args = ap.parse_args()

    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')
    buf = p.read_bytes()

    hits, cats, pairs = [], collections.Counter(), 0

    def sink(sig, formid, data, dial):
        nonlocal pairs
        has_rnam = any(t == b'RNAM' for t, _ in fields(data))
        if not has_rnam or dial is None:
            return
        pairs += 1
        cat = None
        for t, pay in fields(dial[1]):
            if t == b'DATA' and len(pay) >= 4:
                cat = pay[2]
        cats[cat] += 1
        if args.category is not None and cat != args.category:
            return
        if len(hits) < args.examples:
            hits.append((dial, formid, data, cat))

    walk(buf, sink)

    print(f'{p.name}: {pairs:,} INFO records carry RNAM (a player-selectable prompt)')
    print('\nParent DIAL category (DATA[2]) for those:')
    for k, v in cats.most_common(10):
        print(f'  category {k}: {v:,}')

    for dial, formid, data, cat in hits:
        print(f'\n=== player topic, parent DIAL category {cat} ===')
        show('DIAL', dial[0], dial[1])
        show('INFO', formid, data)


if __name__ == '__main__':
    main()
