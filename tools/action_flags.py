"""What flags do the base game's player-dialogue actions carry?

Overture's action copies the template's FNAM 0x00228000: Face Target (bit 15),
Headtrack Player (17), Camera Speaker Target (21) -- names from xEdit's
wbDefinitionsFO4.pas. On Whitechapel Charlie the menu never reaches the player's
turn and the camera never turns to him. This histograms FNAM over every SCEN
action of type 3 and prints the flags of one named scene's actions.

    python tools/action_flags.py [--scene 00075E89]
"""
import argparse
import collections
import pathlib
import struct
import sys
import zlib

HDR = 24
NAMES = {7: 'PlayerPosSubtype/HoldIntoNextScene', 12: 'Keep/Clear Target on End', 14: 'Run on End of Phase',
         15: 'Face Target', 16: 'Looping', 17: 'Headtrack Player', 19: 'Ignore For Completion',
         21: 'Camera Speaker Target', 22: 'Complete Face Target'}


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


def names(v):
    return ', '.join(NAMES.get(b, f'bit{b}') for b in range(32) if v >> b & 1) or '-'


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--esm', default=r'D:\GOGGames\Fallout 4 GOTY\Data\Fallout4.esm')
    ap.add_argument('--scene', default='00075E89')
    args = ap.parse_args()
    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')
    want = int(args.scene, 16)

    hist = collections.Counter()
    bits = collections.Counter()
    total = [0]

    def visit(sig, formid, data):
        if sig != b'SCEN':
            return
        atype, fnam = None, None
        mine = (formid & 0xFFFFFF) == want
        for t, pay in fields(data):
            if t == b'ANAM' and len(pay) == 2:
                atype = struct.unpack('<H', pay)[0]
                fnam = None
            elif t == b'FNAM' and atype is not None and len(pay) == 4:
                fnam = struct.unpack('<I', pay)[0]
                if atype == 3:
                    hist[fnam] += 1
                    total[0] += 1
                    for b in range(32):
                        if fnam >> b & 1:
                            bits[b] += 1
                if mine:
                    print(f'scene {formid:08X} action type {atype}: FNAM 0x{fnam:08X} = {names(fnam)}')

    walk(p.read_bytes(), visit)
    print(f'\n{total[0]:,} player-dialogue actions. Most common FNAM values:')
    for v, n in hist.most_common(8):
        print(f'  0x{v:08X} {n:6,}  {names(v)}')
    print('bit frequency:', ', '.join(f'{NAMES.get(b, b)} {n:,}' for b, n in sorted(bits.items())))


if __name__ == '__main__':
    main()
