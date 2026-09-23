"""How does the base game fence a group of Random lines off from the lines after it?

Overture flags every reply Random (ENAM 0x02) so a cell's variants rotate. But
the blunt topic also holds the place-recoils, AHEAD of the normal replies,
because "first INFO whose conditions pass" is what lets a public room override
the persona. If Random pools every valid Random line in a topic, a recoil and a
normal reply become equally likely and the override is a coin flip.

The candidate fence is ENAM 0x20, which xEdit calls "Random End". This measures,
over every INFO in Fallout4.esm:

  - how many carry PNAM (previous INFO) and whether PNAM order is file order,
    since the engine may order a topic by the PNAM chain rather than by bytes;
  - where 0x20 sits: on a Random line? at the END of a run of Random lines?
    followed by more lines in the same topic?

    python tools/random_groups.py
"""
import argparse
import collections
import pathlib
import struct
import sys
import zlib

HDR = 24
RANDOM, RANDOM_END = 0x02, 0x20


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


def pnam_order(infos):
    """The topic's lines in PNAM-chain order, or None when the chain is not whole."""
    by_prev = {}
    for inf in infos:
        by_prev.setdefault(inf['pnam'], []).append(inf)
    heads = by_prev.get(0, [])
    if len(heads) != 1:
        return None
    out, cur, seen = [], heads[0], set()
    while cur is not None and cur['id'] not in seen:
        seen.add(cur['id'])
        out.append(cur)
        nxt = by_prev.get(cur['id'], [])
        cur = nxt[0] if len(nxt) == 1 else None
    return out if len(out) == len(infos) else None


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--esm', default=r'D:\GOGGames\Fallout 4 GOTY\Data\Fallout4.esm')
    args = ap.parse_args()
    p = pathlib.Path(args.esm)
    if not p.is_file():
        sys.exit(f'no such file: {p}')

    topics = []            # [(snam, [info, ...])]

    def visit(sig, formid, data):
        if sig == b'DIAL':
            snam = ''
            for t, pay in fields(data):
                if t == b'SNAM' and len(pay) == 4:
                    snam = pay.decode('latin1')
            topics.append((snam, []))
        elif sig == b'INFO' and topics:
            enam, pnam, nconds = 0, 0, 0
            for t, pay in fields(data):
                if t == b'ENAM' and len(pay) >= 2:
                    enam = struct.unpack('<H', pay[:2])[0]
                elif t == b'PNAM' and len(pay) == 4:
                    pnam = struct.unpack('<I', pay)[0]
                elif t == b'CTDA':
                    nconds += 1
            topics[-1][1].append({'id': formid, 'enam': enam, 'pnam': pnam, 'conds': nconds})

    walk(p.read_bytes(), visit)

    infos = [i for _s, t in topics for i in t]
    with_pnam = sum(1 for i in infos if i['pnam'])
    print(f'{len(infos):,} INFOs in {len(topics):,} topics; {with_pnam:,} carry a non-zero PNAM')

    # Is PNAM order the file order?
    multi = [(s, t) for s, t in topics if len(t) > 1]
    whole = same = 0
    for _s, t in multi:
        chain = pnam_order(t)
        if chain is None:
            continue
        whole += 1
        same += [c['id'] for c in chain] == [c['id'] for c in t]
    print(f'multi-line topics: {len(multi):,}; with a whole PNAM chain: {whole:,}; '
          f'chain order == file order: {same:,}')

    # Where does Random End sit? Use PNAM order where the chain is whole, file order otherwise.
    ends = collections.Counter()
    for _s, t in multi:
        seq = pnam_order(t) or t
        for k, inf in enumerate(seq):
            if not inf['enam'] & RANDOM_END:
                continue
            ends['total'] += 1
            ends['also Random' if inf['enam'] & RANDOM else 'NOT Random'] += 1
            prev_random = k > 0 and seq[k - 1]['enam'] & RANDOM
            ends['previous line is Random' if prev_random else 'previous line is not Random'] += 1
            after = seq[k + 1:]
            if not after:
                ends['last line of the topic'] += 1
            else:
                ends['lines follow it'] += 1
                if after[0]['enam'] & RANDOM:
                    ends['...and the next one is Random'] += 1
    for k, v in ends.items():
        print(f'  Random End: {k:32} {v:,}')

    # Topics that hold a Random run AND a non-random line after it: is the run fenced?
    fenced = unfenced = 0
    examples = []
    for snam, t in multi:
        seq = pnam_order(t) or t
        for k in range(len(seq) - 1):
            a, b = seq[k], seq[k + 1]
            if a['enam'] & RANDOM and not b['enam'] & RANDOM:
                if a['enam'] & RANDOM_END:
                    fenced += 1
                else:
                    unfenced += 1
                    if len(examples) < 5:
                        examples.append((snam, hex(a['id']), hex(a['enam']), hex(b['id']), hex(b['enam'])))
    print(f'\nRandom line followed by a NON-random line: fenced by Random End {fenced:,}, not fenced {unfenced:,}')
    for e in examples:
        print('  unfenced example', e)

    # Random runs followed by ANOTHER Random run: the only place a fence is needed to split them.
    split = 0
    for _s, t in multi:
        seq = pnam_order(t) or t
        for k in range(len(seq) - 1):
            a, b = seq[k], seq[k + 1]
            if a['enam'] & RANDOM and a['enam'] & RANDOM_END and b['enam'] & RANDOM:
                split += 1
    print(f'Random End line immediately followed by another Random line (two groups back to back): {split:,}')


if __name__ == '__main__':
    main()
