"""Find quest aliases that are SCRIPT-FILLED, and print their exact field list.

Overture needs an alias the quest points at whoever the player is talking to:
no ALUA (bound to one specific actor), no ALFA/ALRT (forced reference), just a
slot a script fills at runtime. The flag bits that mark such an alias are the one
part of the structure not yet transcribed, and this reads them off real records
rather than guessing.

An alias block runs from ALST (reference) or ALLS (location) to ALED. This walks
those blocks, classifies each by which fill-type field it carries, and prints the
field list plus flag value of the script-filled ones.

    python tools/find_script_alias.py
    python tools/find_script_alias.py --examples 6
"""
import argparse
import collections
import pathlib
import struct
import sys
import zlib

HDR = 24
# Every way an alias can be filled by DATA. An alias carrying none of these
# is filled by a SCRIPT at runtime, which is what Overture needs.
FILL_TYPES = {b'ALUA', b'ALFA', b'ALRT', b'ALCO', b'ALCA', b'ALCL', b'ALEQ',
              b'ALEA', b'ALFI', b'ALFR', b'ALNA', b'ALNT', b'ALFE', b'ALFD'}


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


def alias_blocks(data):
    """Yield (kind, [(field, payload)]) for each ALST/ALLS .. ALED block."""
    block, kind = None, None
    for t, pay in fields(data):
        if t in (b'ALST', b'ALLS'):
            block, kind = [(t, pay)], t.decode()
        elif t == b'ALED':
            if block is not None:
                yield kind, block
            block, kind = None, None
        elif block is not None:
            block.append((t, pay))


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--esm', default=r'D:\GOGGames\Fallout 4 GOTY\Data\Fallout4.esm')
    ap.add_argument('--examples', type=int, default=4)
    args = ap.parse_args()

    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')

    shapes = collections.Counter()
    flags_seen = collections.Counter()
    examples = []

    def visit(sig, formid, data):
        if sig != b'QUST':
            return
        for kind, block in alias_blocks(data):
            names = [t.decode('latin1') for t, _ in block]
            has_fill = any(t in FILL_TYPES for t, _ in block)
            shapes[(kind, tuple(names))] += 1
            if kind == 'ALST' and not has_fill:
                flag = None
                name = ''
                for t, pay in block:
                    if t == b'FNAM' and len(pay) == 4:
                        flag = struct.unpack('<I', pay)[0]
                    elif t == b'ALID':
                        name = pay.rstrip(b'\x00').decode('latin1')
                flags_seen[flag] += 1
                if len(examples) < args.examples:
                    examples.append((formid, name, block))

    walk(p.read_bytes(), visit)

    print('Most common alias shapes (kind, fields):')
    for (kind, names), n in shapes.most_common(8):
        print(f'  {n:6,}  {kind}: {" ".join(names)}')

    total = sum(flags_seen.values())
    print(f'\nReference aliases with NO fill-type field (script-filled): {total:,}')
    print('FNAM (the alias flags) among them:')
    for flag, n in flags_seen.most_common(10):
        shown = 'absent' if flag is None else f'0x{flag:08X}'
        print(f'  {shown:>12}  {n:,}')

    for formid, name, block in examples:
        print(f'\n=== QUST {formid:08X}, alias "{name}" ===')
        for t, pay in block:
            note = ''
            if len(pay) == 4:
                note = f'  = 0x{struct.unpack("<I", pay)[0]:08X}'
            elif t == b'ALID':
                note = '  ' + pay.rstrip(b'\x00').decode('latin1')
            print(f'  {t.decode("latin1"):5} {len(pay):4} {pay[:16].hex():<34}{note}')


if __name__ == '__main__':
    main()
