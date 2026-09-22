"""Dump any record from any plugin, by form id, field by field.

The general version of the one-off dumpers this repo kept growing. Every record
shape Overture writes is transcribed from a real one, and this is what reads the
real one.

    python tools/dump_record.py --form 00000038
    python tools/dump_record.py --esm build/Overture.esp --form 01000800
    python tools/dump_record.py --type GLOB --limit 5
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


def show(sig, formid, data):
    print(f'=== {sig} {formid:08X} ===')
    for t, pay in fields(data):
        name = t.decode('latin1')
        note = ''
        if name in ('EDID', 'FULL', 'DESC', 'NNAM'):
            note = '  ' + pay.rstrip(b'\x00').decode('latin1', 'replace')[:70]
        elif len(pay) == 1:
            note = f'  byte={pay[0]} ({chr(pay[0]) if 32 <= pay[0] < 127 else "."!r})'
        elif len(pay) == 4:
            i4 = struct.unpack('<I', pay)[0]
            f4 = struct.unpack('<f', pay)[0]
            note = f'  int={i4} (0x{i4:08X})  float={f4}'
        print(f'  {name:5} {len(pay):5} {pay[:24].hex():<50}{note}')
    print()


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--esm', default=r'D:\GOGGames\Fallout 4 GOTY\Data\Fallout4.esm')
    ap.add_argument('--form', default=None, help='hex form id')
    ap.add_argument('--type', default=None, help='record type, e.g. GLOB')
    ap.add_argument('--limit', type=int, default=3)
    args = ap.parse_args()

    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')

    want_form = int(args.form, 16) if args.form else None
    shown = [0]

    def visit(sig, formid, data):
        s = sig.decode('latin1')
        if want_form is not None and formid != want_form:
            return
        if args.type and s != args.type:
            return
        if shown[0] >= args.limit:
            return
        shown[0] += 1
        show(s, formid, data)

    walk(p.read_bytes(), visit)
    if not shown[0]:
        sys.exit('nothing matched')


if __name__ == '__main__':
    main()
