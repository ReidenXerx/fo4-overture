"""Find the SMALLEST quest in Fallout4.esm that owns real player dialogue, and
print its anatomy.

Overture needs a template, and the template should be the least complicated
working example rather than a big quest whose structure is mostly about being a
big quest. A quest owning three or four player topics shows the required parts
and nothing else.

Reports, per candidate quest: how many DIAL topics it owns, how many INFOs, how
many of those carry RNAM, and the record types that appear inside its child
group. Then dumps the child-group tree of the winner.

    python tools/smallest_dialogue_quest.py
    python tools/smallest_dialogue_quest.py --quest 0001DA33
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


def decompress(flags, data):
    if flags & 0x00040000:
        try:
            return zlib.decompress(data[4:])
        except zlib.error:
            return b''
    return data


def walk(buf, visit, path=()):
    """visit(sig, formid, data, path) for every record; path is the GRUP chain."""
    i, n = 0, len(buf)
    while i + HDR <= n:
        sig = buf[i:i + 4]
        size = struct.unpack('<I', buf[i + 4:i + 8])[0]
        if sig == b'GRUP':
            label = buf[i + 8:i + 12]
            gtype = struct.unpack('<i', buf[i + 12:i + 16])[0]
            walk(buf[i + HDR:i + size], visit, path + ((gtype, label),))
            i += size
            continue
        flags = struct.unpack('<I', buf[i + 8:i + 12])[0]
        formid = struct.unpack('<I', buf[i + 12:i + 16])[0]
        visit(sig, formid, decompress(flags, buf[i + HDR:i + HDR + size]), path)
        i += HDR + size


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--esm', default=r'D:\GOGGames\Fallout 4 GOTY\Data\Fallout4.esm')
    ap.add_argument('--quest', default=None, help='hex form id to dump instead of searching')
    ap.add_argument('--top', type=int, default=8)
    args = ap.parse_args()

    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')
    buf = p.read_bytes()

    owner = {}            # DIAL formid -> owning quest formid
    dial_of_quest = collections.Counter()
    info_of_quest = collections.Counter()
    rnam_of_quest = collections.Counter()
    kinds_of_quest = collections.defaultdict(collections.Counter)
    quest_edid = {}
    current_dial = [None]

    def visit(sig, formid, data, path):
        if sig == b'QUST':
            for t, pay in fields(data):
                if t == b'EDID':
                    quest_edid[formid] = pay.rstrip(b'\x00').decode('latin1')
                    break
        elif sig == b'DIAL':
            q = snam = None
            for t, pay in fields(data):
                if t == b'QNAM' and len(pay) == 4:
                    q = struct.unpack('<I', pay)[0]
                elif t == b'SNAM' and len(pay) == 4:
                    snam = pay.decode('latin1')
            owner[formid] = q
            current_dial[0] = (formid, q, snam)
            if q is not None:
                dial_of_quest[q] += 1
                kinds_of_quest[q][snam] += 1
        elif sig == b'INFO':
            d = current_dial[0]
            if not d or d[1] is None:
                return
            info_of_quest[d[1]] += 1
            if any(t == b'RNAM' for t, _ in fields(data)):
                rnam_of_quest[d[1]] += 1

    walk(buf, visit)

    if args.quest is None:
        cands = [q for q, n in rnam_of_quest.items() if n >= 3]
        cands.sort(key=lambda q: (info_of_quest[q], dial_of_quest[q]))
        print(f'{len(cands):,} quests own 3+ player prompts. Smallest first:\n')
        print(f'{"quest":>9} {"DIALs":>6} {"INFOs":>6} {"RNAM":>5}  {"types":22} EDID')
        for q in cands[:args.top]:
            kinds = ','.join(f'{k}:{v}' for k, v in kinds_of_quest[q].most_common(3))
            print(f'{q:09X} {dial_of_quest[q]:6} {info_of_quest[q]:6} {rnam_of_quest[q]:5}  '
                  f'{kinds:22} {quest_edid.get(q, "")}')
        print('\nRe-run with --quest <id> to dump one.')
        return

    target = int(args.quest, 16)
    print(f'quest {target:08X}  {quest_edid.get(target, "")}')
    print(f'  DIAL {dial_of_quest[target]}  INFO {info_of_quest[target]}  '
          f'with RNAM {rnam_of_quest[target]}')
    print(f'  topic types: {dict(kinds_of_quest[target])}')

    # Which top-level record types mention this quest at all.
    refs = collections.Counter()

    def visit2(sig, formid, data, path):
        if struct.pack('<I', target) in data:
            refs[sig.decode('latin1')] += 1

    walk(buf, visit2)
    print(f'\n  records containing this quest form id: {dict(refs)}')


if __name__ == '__main__':
    main()
