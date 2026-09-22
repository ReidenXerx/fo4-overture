"""Dump the SCEN (dialogue scene) records that belong to a quest.

The topics live in the quest's child group; the SCEN record is top level and is
what actually runs the conversation. Overture needs both, so this prints the
scene's subrecords in order -- phases, actions and the alias it drives.

    python tools/dump_scen.py --quest 0010B654
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
    ap.add_argument('--quest', required=True)
    args = ap.parse_args()

    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')
    target = int(args.quest, 16)
    needle = struct.pack('<I', target)
    hits = []

    def visit(sig, formid, data):
        if sig == b'SCEN' and needle in data:
            hits.append((formid, data))

    walk(p.read_bytes(), visit)
    if not hits:
        sys.exit(f'no SCEN references quest {target:08X}')

    for formid, data in hits:
        print(f'=== SCEN {formid:08X} ===')
        for t, pay in fields(data):
            name = t.decode('latin1')
            note = ''
            if name == 'EDID':
                note = '  ' + pay.rstrip(b'\x00').decode('latin1')
            elif len(pay) == 4:
                v = struct.unpack('<I', pay)[0]
                note = f'  = {v} / 0x{v:08X}'
                if v == target:
                    note += '   <- the quest'
            elif len(pay) == 2:
                note = f'  = {struct.unpack("<H", pay)[0]}'
            elif len(pay) == 1:
                note = f'  = {pay[0]}'
            print(f'  {name:5} {len(pay):5}{note}  {pay[:16].hex()}')


if __name__ == '__main__':
    main()
