"""Dump every record that makes up one dialogue quest, in file order.

This is the template Overture's builder gets written against. Print the quest's
child-group tree, every topic and line under it, and the subrecords each one
carries, so the builder is a transcription of something that works rather than
an assembly of things that ought to.

    python tools/quest_anatomy.py --quest 0010B654
    python tools/quest_anatomy.py --quest 0010B654 --full
"""
import argparse
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


def decompress(flags, data):
    if flags & 0x00040000:
        try:
            return zlib.decompress(data[4:])
        except zlib.error:
            return b''
    return data


def find_quest_group(buf, target, depth=0):
    """Return the bytes of GRUP type 10 whose label is `target`, plus the QUST."""
    i, n = 0, len(buf)
    qust = None
    while i + HDR <= n:
        sig = buf[i:i + 4]
        size = struct.unpack('<I', buf[i + 4:i + 8])[0]
        if sig == b'GRUP':
            label = struct.unpack('<I', buf[i + 8:i + 12])[0]
            gtype = struct.unpack('<i', buf[i + 12:i + 16])[0]
            if gtype == 10 and label == target:
                return qust, buf[i + HDR:i + size]
            got = find_quest_group(buf[i + HDR:i + size], target, depth + 1)
            if got[1] is not None:
                return (got[0] or qust), got[1]
            i += size
            continue
        flags = struct.unpack('<I', buf[i + 8:i + 12])[0]
        formid = struct.unpack('<I', buf[i + 12:i + 16])[0]
        if sig == b'QUST' and formid == target:
            qust = decompress(flags, buf[i + HDR:i + HDR + size])
        i += HDR + size
    return qust, None


def text(pay):
    s = pay.rstrip(b'\x00').decode('utf-8', 'replace')
    return s.encode('ascii', 'replace').decode('ascii')


def dump_record(sig, formid, data, indent, full):
    print(f'{indent}{sig.decode()} {formid:08X}')
    for t, pay in fields(data):
        name = t.decode('latin1')
        note = ''
        if name in ('EDID', 'FULL', 'NNAM'):
            note = '  ' + text(pay)
        elif len(pay) == 4:
            v = struct.unpack('<I', pay)[0]
            note = f'  = {v} / 0x{v:08X}'
            if name == 'SNAM':
                note += f'  "{pay.decode("latin1")}"'
        elif name == 'DATA' and len(pay) >= 3:
            note = f'  bytes {list(pay[:4])}'
        if full or name not in ('VMAD', 'CTDA', 'TRDA'):
            print(f'{indent}  {name:5} {len(pay):5} {pay[:24].hex():<48}{note}')


def walk_group(buf, indent, full, limit):
    i, n, shown = 0, len(buf), 0
    while i + HDR <= n:
        sig = buf[i:i + 4]
        size = struct.unpack('<I', buf[i + 4:i + 8])[0]
        if sig == b'GRUP':
            label = struct.unpack('<I', buf[i + 8:i + 12])[0]
            gtype = struct.unpack('<i', buf[i + 12:i + 16])[0]
            print(f'{indent}GRUP type {gtype} label {label:08X}  ({size} bytes)')
            walk_group(buf[i + HDR:i + size], indent + '  ', full, limit)
            i += size
            continue
        flags = struct.unpack('<I', buf[i + 8:i + 12])[0]
        formid = struct.unpack('<I', buf[i + 12:i + 16])[0]
        if shown < limit:
            dump_record(sig, formid, decompress(flags, buf[i + HDR:i + HDR + size]),
                        indent, full)
            shown += 1
        i += HDR + size
    if shown >= limit:
        print(f'{indent}... more records suppressed (--limit)')


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--esm', default=r'D:\GOGGames\Fallout 4 GOTY\Data\Fallout4.esm')
    ap.add_argument('--quest', required=True)
    ap.add_argument('--full', action='store_true', help='include VMAD/CTDA/TRDA')
    ap.add_argument('--limit', type=int, default=99)
    args = ap.parse_args()

    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')
    target = int(args.quest, 16)
    qust, group = find_quest_group(p.read_bytes(), target)
    if qust is None and group is None:
        sys.exit(f'quest {target:08X} not found')

    if qust is not None:
        print('=== the QUST record ===')
        dump_record(b'QUST', target, qust, '', args.full)
    if group is None:
        print('\n(no child group - this quest owns no dialogue)')
        return
    print(f'\n=== its children (GRUP type 10, {len(group)} bytes) ===')
    walk_group(group, '', args.full, args.limit)


if __name__ == '__main__':
    main()
