"""Do the base game's player-dialogue actions ever point at Random lines?

Overture's scene wedges the dialogue menu -- the engine never raises
awaitingPlayerInput, XDI refuses every choice, the NPC loops its
waiting-for-player lines -- in two builds that share one thing the working
builds lacked: INFOs flagged Random (ENAM 0x02) in topics a PLAYER DIALOGUE
action (SCEN action type 3) names. The engine consults those topics while it
builds the options.

This collects every topic named by a type-3 action's eight fields
(PTOP/NTOP/NETO/QTOP = the player's, NPOT/NNGT/NNUT/NQUT = the NPC's answer)
across Fallout4.esm and counts the INFOs in them by flag. If vanilla never, or
almost never, flags them Random, that is the signature.

    python tools/action_topic_flags.py
"""
import argparse
import collections
import pathlib
import struct
import sys
import zlib

HDR = 24
PLAYER = (b'PTOP', b'NTOP', b'NETO', b'QTOP')
NPC = (b'NPOT', b'NNGT', b'NNUT', b'NQUT')


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
    args = ap.parse_args()
    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')

    role = {}                          # topic id -> 'player' | 'npc'
    topic_infos = collections.defaultdict(list)   # topic id -> [enam flags]
    state = {'dial': None}

    def visit(sig, formid, data):
        if sig == b'SCEN':
            action_type = None
            for t, pay in fields(data):
                if t == b'ANAM' and len(pay) == 2:
                    action_type = struct.unpack('<H', pay)[0]
                elif action_type == 3 and t in PLAYER + NPC and len(pay) == 4:
                    tid = struct.unpack('<I', pay)[0]
                    if tid:
                        role[tid] = 'player' if t in PLAYER else 'npc'
        elif sig == b'DIAL':
            state['dial'] = formid
        elif sig == b'INFO' and state['dial'] is not None:
            enam = 0
            for t, pay in fields(data):
                if t == b'ENAM' and len(pay) >= 2:
                    enam = struct.unpack('<H', pay[:2])[0]
                    break
            topic_infos[state['dial']].append(enam)

    walk(p.read_bytes(), visit)

    for which in ('player', 'npc'):
        tids = [t for t, r in role.items() if r == which]
        infos = [e for t in tids for e in topic_infos.get(t, [])]
        rnd = sum(1 for e in infos if e & 0x02)
        multi = sum(1 for t in tids if len(topic_infos.get(t, [])) > 1)
        rnd_topics = sum(1 for t in tids if any(e & 0x02 for e in topic_infos.get(t, [])))
        print(f'{which:6} topics named by type-3 actions: {len(tids):,}  '
              f'holding {len(infos):,} INFOs; topics with >1 INFO: {multi:,}')
        print(f'        INFOs flagged Random: {rnd:,}   topics holding any Random INFO: {rnd_topics:,}')
        dist = collections.Counter(len(topic_infos.get(t, [])) for t in tids)
        print('        INFOs per topic:', ', '.join(f'{k}:{v}' for k, v in sorted(dist.items())[:10]))

        # HOW each run of consecutive Random lines ENDS: on a Random End line,
        # on a following non-random line, or by running off the end of the topic
        # unterminated -- which is how every one of Overture's runs ended.
        ends = collections.Counter()
        for t in tids:
            seq = topic_infos.get(t, [])
            k = 0
            while k < len(seq):
                if not seq[k] & 0x02:
                    k += 1
                    continue
                j = k
                while j < len(seq) and seq[j] & 0x02 and not seq[j] & 0x20:
                    j += 1
                if j < len(seq) and seq[j] & 0x20:
                    ends['closed by Random End'] += 1
                    k = j + 1
                elif j < len(seq):
                    ends['closed by a non-random line'] += 1
                    k = j
                else:
                    ends['runs off the end of the topic'] += 1
                    k = j
        print('        Random runs:', ', '.join(f'{k} {v:,}' for k, v in ends.items()))


if __name__ == '__main__':
    main()
