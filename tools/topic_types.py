"""Which DIAL type codes carry player-selectable prompts, and how many.

A DIAL's SNAM is a four-character type code -- the thing that says what KIND of
dialogue a topic is. An INFO carrying RNAM carries the text the player sees as a
menu option. Crossing the two answers the only question Overture needs before it
can build a topic: what type code does a topic the player TALKS to an NPC
through actually use, as opposed to one the game plays inside a scene.

    python tools/topic_types.py
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
            sink(formid, data, dial)
        i += HDR + size


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--esm', default=r'D:\GOGGames\Fallout 4 GOTY\Data\Fallout4.esm')
    args = ap.parse_args()
    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')

    all_types = collections.Counter()
    player_types = collections.Counter()
    example = {}

    def sink(formid, data, dial):
        if dial is None:
            return
        snam = cat = None
        for t, pay in fields(dial[1]):
            if t == b'SNAM' and len(pay) == 4:
                snam = pay.decode('latin1')
            elif t == b'DATA' and len(pay) >= 3:
                cat = pay[2]
        key = (snam, cat)
        all_types[key] += 1
        if any(t == b'RNAM' for t, _ in fields(data)):
            player_types[key] += 1
            example.setdefault(key, (dial[0], formid))

    walk(p.read_bytes(), sink)

    print(f'{p.name}\n')
    print(f'{"SNAM":8} {"cat":>4} {"INFOs":>9} {"with RNAM":>10} {"%":>5}   example DIAL/INFO')
    for key, total in all_types.most_common(20):
        snam, cat = key
        pl = player_types.get(key, 0)
        ex = example.get(key)
        exs = f'{ex[0]:08X} / {ex[1]:08X}' if ex else ''
        print(f'{str(snam):8} {str(cat):>4} {total:9,} {pl:10,} {100*pl/total:5.0f}   {exs}')


if __name__ == '__main__':
    main()
