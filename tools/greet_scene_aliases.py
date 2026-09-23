"""How does the base game fill the alias of a scene that a GREETING starts?

O-7 wants Overture's approach to open whenever the player talks to an eligible
NPC. A greeting's own conditions already run on the SPEAKER, so the greeting
needs no alias to know who is talking -- but the scene it starts (TSCE) names
its actors by ALIAS, so that alias has to hold the speaker by the time the
scene runs. Overture fills it by hand today (the dev verb).

This finds every GREE INFO carrying TSCE, the scene it starts, that scene's
owning quest (SCEN PNAM), the aliases the scene's actions use (ALID), and how
each of those aliases is FILLED -- by the subrecords the alias block carries:

    ALFR forced ref · ALUA unique actor · ALFA+ALRT location ref ·
    ALFE+ALFD from a Story Manager event · ALCO created · ALEQ+ALEA external ·
    none of those + CTDA = find matching reference (by conditions)

plus the alias FNAM flags. And, per quest, whether a Story Manager node starts
it (SMQN pointing at it), which is how "from event" aliases get their actor.

    python tools/greet_scene_aliases.py
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


def u32(b):
    return struct.unpack('<I', b[:4])[0] if len(b) >= 4 else 0


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--esm', default=r'D:\GOGGames\Fallout 4 GOTY\Data\Fallout4.esm')
    ap.add_argument('--show', type=int, default=12, help='example rows to print per fill kind')
    args = ap.parse_args()
    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')

    gree_scenes = collections.Counter()   # scene id -> greetings that start it
    state = {'snam': ''}
    scenes = {}                           # scene id -> (quest id, {alias ids used})
    quests = {}                           # quest id -> (edid, {alias id: (kind, flags)})
    sm_started = set()                    # quests a Story Manager quest node starts
    sm_events = collections.Counter()

    def alias_blocks(data):
        """Yield (alias id, [subrecord types], FNAM flags) for each ALST/ALLS block."""
        cur, types, flags = None, [], 0
        for t, pay in fields(data):
            if t in (b'ALST', b'ALLS'):
                if cur is not None:
                    yield cur, types, flags
                cur, types, flags = u32(pay), [], 0
            elif cur is not None:
                if t == b'ALED':
                    yield cur, types, flags
                    cur, types, flags = None, [], 0
                    continue
                types.append(t)
                if t == b'FNAM' and len(pay) >= 4:
                    flags = u32(pay)
        if cur is not None:
            yield cur, types, flags

    def kind_of(types):
        s = set(types)
        if b'ALFR' in s: return 'forced ref (ALFR)'
        if b'ALUA' in s: return 'unique actor (ALUA)'
        if b'ALFE' in s or b'ALFD' in s: return 'from Story Manager event (ALFE/ALFD)'
        if b'ALCO' in s: return 'created ref (ALCO)'
        if b'ALEQ' in s: return 'external alias (ALEQ)'
        if b'ALFA' in s: return 'location alias ref (ALFA)'
        if b'CTDA' in s: return 'find matching ref (conditions)'
        return 'script-filled / none'

    def visit(sig, formid, data):
        if sig == b'DIAL':
            state['snam'] = ''
            for t, pay in fields(data):
                if t == b'SNAM' and len(pay) == 4:
                    state['snam'] = pay.decode('latin1')
        elif sig == b'INFO' and state['snam'] == 'GREE':
            for t, pay in fields(data):
                if t == b'TSCE' and len(pay) == 4 and u32(pay):
                    gree_scenes[u32(pay)] += 1
        elif sig == b'SCEN':
            quest, used = 0, set()
            for t, pay in fields(data):
                if t == b'PNAM' and len(pay) == 4:
                    quest = u32(pay)
                elif t == b'ALID' and len(pay) == 4:
                    used.add(u32(pay))
            scenes[formid] = (quest, used)
        elif sig == b'QUST':
            edid, aliases = '', {}
            for t, pay in fields(data):
                if t == b'EDID':
                    edid = pay.rstrip(b'\0').decode('latin1')
                    break
            for aid, types, flags in alias_blocks(data):
                aliases[aid] = (kind_of(types), flags)
            quests[formid] = (edid, aliases)
        elif sig == b'SMQN':
            for t, pay in fields(data):
                if t == b'NNAM' and len(pay) == 4:
                    sm_started.add(u32(pay))
        elif sig == b'SMEN':
            for t, pay in fields(data):
                if t == b'ENAM' and len(pay) == 4:
                    sm_events[pay.decode('latin1')] += 1

    walk(p.read_bytes(), visit)

    print(f'{len(gree_scenes):,} scenes are started by {sum(gree_scenes.values()):,} greeting lines (TSCE)')
    kinds = collections.Counter()
    examples = collections.defaultdict(list)
    for sid in gree_scenes:
        quest, used = scenes.get(sid, (0, set()))
        edid, aliases = quests.get(quest, ('?', {}))
        for aid in sorted(used):
            kind, flags = aliases.get(aid, ('alias not found', 0))
            kinds[kind] += 1
            examples[kind].append(f'{edid} alias {aid} flags {flags:#x}'
                                  f'{" [SM-started quest]" if quest in sm_started else ""}')
    print('\nhow the aliases those scenes act through are filled:')
    for k, n in kinds.most_common():
        print(f'  {n:5,}  {k}')
        for e in examples[k][:args.show]:
            print(f'           {e}')
    print('\nStory Manager event types in use (SMEN ENAM):',
          ', '.join(f'{k}:{v}' for k, v in sm_events.most_common()))


if __name__ == '__main__':
    main()
