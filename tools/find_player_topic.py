"""Find real PLAYER dialogue topics in Fallout4.esm and dump their field shape.

Rapport's make_dialogue.py builds Say-driven barks. Overture needs topics the
player SELECTS, which is a different INFO shape. This project's own rule is to
establish that shape by diffing a record the game really uses, never by
extending the bark builder and hoping -- four confident theories were wrong
about an inert topic before a field-by-field diff found the answer first time.

So: walk the QUST groups, find DIAL/INFO records, and report which subrecords
each carries and how often. A player topic and a bark differ in exactly those
fields, and this prints both so the difference is readable rather than assumed.

    python tools/find_player_topic.py --esm "<path to Fallout4.esm>"
    python tools/find_player_topic.py --esm ... --dump 00048EB

Reads only; writes nothing into the game folder.
"""
import argparse
import collections
import pathlib
import struct
import sys
import zlib

HDR = 24  # record header: type(4) size(4) flags(4) id(4) vcs(4) ver(2) unk(2)


def records(buf, want, out, depth=0):
    """Walk a GRUP/record stream, collecting records whose type is in `want`."""
    i, n = 0, len(buf)
    while i + HDR <= n:
        sig = buf[i:i + 4]
        size = struct.unpack('<I', buf[i + 4:i + 8])[0]
        if sig == b'GRUP':
            # GRUP size INCLUDES its own 24-byte header.
            records(buf[i + HDR:i + size], want, out, depth + 1)
            i += size
            continue
        flags = struct.unpack('<I', buf[i + 8:i + 12])[0]
        formid = struct.unpack('<I', buf[i + 12:i + 16])[0]
        data = buf[i + HDR:i + HDR + size]
        if sig in want:
            if flags & 0x00040000:  # compressed
                try:
                    data = zlib.decompress(data[4:])
                except zlib.error:
                    data = b''
            out.append((sig, formid, data))
        i += HDR + size


def fields(data):
    """Yield (subrecord type, payload) pairs, honouring XXXX overrides."""
    i, n = 0, len(data)
    big = None
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
    ap.add_argument('--dump', default=None, help='hex form id of one INFO to print in full')
    ap.add_argument('--limit', type=int, default=12)
    args = ap.parse_args()

    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')
    buf = p.read_bytes()
    print(f'{p.name}: {len(buf):,} bytes')

    found = []
    records(buf, {b'DIAL', b'INFO'}, found)
    dials = [r for r in found if r[0] == b'DIAL']
    infos = [r for r in found if r[0] == b'INFO']
    print(f'DIAL {len(dials):,}   INFO {len(infos):,}')

    if args.dump:
        target = int(args.dump, 16)
        for sig, fid, data in found:
            if fid == target:
                print(f'\n=== {sig.decode()} {fid:08X} ===')
                for typ, payload in fields(data):
                    show = payload[:64]
                    txt = ''
                    if typ in (b'EDID', b'NAM1', b'RNAM', b'FULL'):
                        txt = '  ' + payload.rstrip(b'\x00').decode('utf-8', 'replace')[:90]
                    print(f'  {typ.decode():5} {len(payload):5}  {show.hex()[:60]}{txt}')
                return
        sys.exit(f'{args.dump} not found')

    # DIAL's DNAM/subtype and TDUM/"player text" fields are what separate a
    # selectable topic from a bark. Report the field vocabulary of each.
    for label, rows in (('DIAL', dials), ('INFO', infos)):
        c = collections.Counter()
        for _, _, data in rows:
            c.update(t.decode('latin1') for t, _ in fields(data))
        print(f'\n{label} subrecords, most common first:')
        for t, k in c.most_common(args.limit):
            print(f'  {t:6} {k:7,}  ({100*k/max(len(rows),1):.0f}% of records)')

    # A DIAL carries a category/subtype in DATA; group by it so the player
    # categories are visible as distinct populations.
    cats = collections.Counter()
    for _, fid, data in dials:
        for typ, payload in fields(data):
            if typ == b'DATA' and len(payload) >= 4:
                cats[payload[2]] += 1
    print('\nDIAL DATA[2] (subtype/category) histogram:')
    for k, v in cats.most_common(12):
        print(f'  {k:3}  {v:,}')


if __name__ == '__main__':
    main()
