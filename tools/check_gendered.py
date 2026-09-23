"""O-40c's check: gendered lines, built in a scratch copy of this repo.

    python tools/check_gendered.py      # needs a current build/Overture.esp

POSITIVE: the builder handles gendered lines correctly.
- Every gendered INFO carries GetIsSex (func 70) on the right run-on.
- It sits at the id its layout promises.
- No fenced run ends on a gendered line.
- Every PLAIN line keeps exactly the ids it has in build/Overture.esp. A voice file is
  named by its INFO's id, so a moved id is a renamed file. The first draft of this check
  lacked that one, and a real shift slipped past it.

NEGATIVE: the builder REFUSES
- a fenced run whose every line is gendered;
- a cell with no line for one sex;
- a gendered greeting;
- a third gendered line in a cell;
- a bad gender value.

PROBE: the id check is shown able to fail, on a plain line inserted mid-list (GP-2).
"""
import copy
import json
import pathlib
import shutil
import struct
import subprocess
import sys
import tempfile
import zlib

SRC = pathlib.Path(__file__).resolve().parent.parent
T = pathlib.Path(tempfile.mkdtemp(prefix='overture-gendered-')) / 'repo'
FAILS = []


def check(cond, what):
    print(('  ok   ' if cond else '  FAIL ') + what)
    if not cond:
        FAILS.append(what)


def fresh():
    if T.exists():
        shutil.rmtree(T)
    for d in ('tools', 'voice', 'papyrus', 'docs', 'data'):
        if (SRC / d).exists():
            shutil.copytree(SRC / d, T / d, ignore=shutil.ignore_patterns('__pycache__'))
    (T / 'build').mkdir()


def banks():
    return (json.loads((T / 'voice/lines.json').read_text(encoding='utf-8')),
            json.loads((T / 'voice/companion-lines.json').read_text(encoding='utf-8')))


def save(bank, cb):
    (T / 'voice/lines.json').write_text(json.dumps(bank, indent=2), encoding='utf-8')
    (T / 'voice/companion-lines.json').write_text(json.dumps(cb, indent=2), encoding='utf-8')


def build():
    r = subprocess.run([sys.executable, str(T / 'tools/make_overture_esp.py'), str(T / 'build/t.esp'),
                        '--stages', '3'], capture_output=True, text=True)
    return r.returncode, (r.stdout + r.stderr)


def add(bank_lines, like_id, suffix, text, **fields):
    """Insert a copy of line `like_id` straight after the LAST line of its cell."""
    i = next(n for n, l in enumerate(bank_lines) if l['id'] == like_id)
    new = copy.deepcopy(bank_lines[i])
    new['id'] = like_id.rsplit('_', 1)[0] + '_' + suffix
    new['text'] = text
    new.pop('chars', None)
    new.update(fields)
    key = lambda l: (l.get('kind'), l.get('stage'), l.get('persona'), l.get('register'), l.get('outcome'))
    j = max(n for n, l in enumerate(bank_lines) if key(l) == key(new))
    bank_lines.insert(j + 1, new)
    return new


def infos(esp):
    """[(group topic id, INFO id, enam flags, [ctda tuples], text)] in file order."""
    out = []

    def fields(body):
        o, big = 0, None
        while o < len(body):
            sig = body[o:o + 4]
            n = struct.unpack_from('<H', body, o + 4)[0]
            o += 6
            if sig == b'XXXX':
                big = struct.unpack_from('<I', body, o)[0]
                o += n
                continue
            if big is not None:
                n, big = big, None
            yield sig, body[o:o + n]
            o += n

    def walk(o, end, parent):
        while o < end:
            sig = esp[o:o + 4]
            size = struct.unpack_from('<I', esp, o + 4)[0]
            if sig == b'GRUP':
                label = struct.unpack_from('<I', esp, o + 8)[0]
                gtype = struct.unpack_from('<i', esp, o + 12)[0]
                walk(o + 24, o + size, label if gtype == 7 else parent)
                o += size
                continue
            flags, fid = struct.unpack_from('<II', esp, o + 8)
            body = esp[o + 24:o + 24 + size]
            if flags & 0x40000:
                body = zlib.decompress(body[4:])
            if sig == b'INFO':
                enam, ctdas, text = 0, [], ''
                for s, v in fields(body):
                    if s == b'ENAM':
                        enam = struct.unpack_from('<H', v)[0]
                    elif s == b'CTDA':
                        op = v[0]
                        value = struct.unpack_from('<f', v, 4)[0]
                        func = struct.unpack_from('<H', v, 8)[0]
                        p1 = struct.unpack_from('<I', v, 12)[0]
                        runon = struct.unpack_from('<I', v, 20)[0]
                        ref = struct.unpack_from('<I', v, 24)[0]
                        ctdas.append((func, p1, runon, ref, value, op))
                    elif s == b'NAM1':
                        text = v.split(b'\0')[0].decode('ascii')
                out.append((parent, fid, enam, ctdas, text))
            o += 24 + size

    walk(0, len(esp), None)
    return out


# ------------------------------------------------------------------ positive
print('POSITIVE: gendered lines in every place the builder allows them')
fresh()
bank, cb = banks()
L = bank['lines']
s1f = add(L, 'ov_vulgar_blunt_land_02', 'f1', 'TEST s1 land female', gender='f')
s1m = add(L, 'ov_vulgar_blunt_land_02', 'm1', 'TEST s1 land male', gender='m')
p1m = add(L, 'ov_vulgar_offer_miss_02', 'pm', 'TEST s1 offer to a male player', player_gender='m')
p1f = add(L, 'ov_vulgar_offer_miss_02', 'pf', 'TEST s1 offer to a female player', player_gender='f')
r2f = add(L, 'ov2_vulgar_recoil_02', 'f1', 'TEST s2 recoil female', gender='f')
r2m = add(L, 'ov2_vulgar_recoil_02', 'm1', 'TEST s2 recoil male', gender='m')
a3f = add(L, 'ov3_vulgar_accept_02', 'f1', 'TEST s3 accept female', gender='f')
a3m = add(L, 'ov3_vulgar_accept_02', 'm1', 'TEST s3 accept male', gender='m')
jf = add(L, 'ov_jealous_vulgar_02', 'f1', 'TEST jealous female', gender='f')
jm = add(L, 'ov_jealous_vulgar_02', 'm1', 'TEST jealous male', gender='m')
C = cb['lines']
cf = add(C, 'co_vulgar_accept_01', 'f1', 'TEST companion accept female', gender='f')
cm = add(C, 'co_vulgar_accept_01', 'm1', 'TEST companion accept male', gender='m')
save(bank, cb)
code, log = build()
check(code == 0, f'build succeeds (exit {code})' + ('' if code == 0 else ': ' + log[-400:]))
if code == 0:
    got = infos((T / 'build/t.esp').read_bytes())
    by_text = {}
    for parent, fid, enam, ctdas, text in got:
        by_text.setdefault(text, []).append((parent, fid, enam, ctdas))
    SEX = {'m': 0, 'f': 1}

    def sex_ctdas(ctdas):
        return [c for c in ctdas if c[0] == 70]

    for line, runon, ref in ((s1f, 0, 0), (s1m, 0, 0), (r2f, 0, 0), (r2m, 0, 0), (a3f, 0, 0), (a3m, 0, 0),
                             (jf, 0, 0), (jm, 0, 0), (cf, 0, 0), (cm, 0, 0), (p1m, 2, 0x14), (p1f, 2, 0x14)):
        sex = line.get('gender') or line.get('player_gender')
        hits = by_text.get(line['text'], [])
        check(bool(hits), f'{line["id"]}: written ({len(hits)} INFOs)')
        for parent, fid, enam, ctdas in hits:
            sc = sex_ctdas(ctdas)
            check(len(sc) == 1 and sc[0][1] == SEX[sex] and sc[0][2] == runon and sc[0][3] == ref
                  and sc[0][4] == 1.0 and sc[0][5] == 0,
                  f'{line["id"]} {fid:08X}: GetIsSex({SEX[sex]}) == 1 on runon {runon} ref {ref:#x} -> {sc}')
    # Ungendered lines carry no GetIsSex at all.
    stray = [(fid, t) for _p, fid, _e, ctdas, t in got if sex_ctdas(ctdas) and not t.startswith('TEST')]
    check(not stray, f'no ungendered line carries GetIsSex ({len(stray)} do)')
    # Ids: stage 1 in the cell's spare slots; stage 3 in 0xF00; companion in 0xD60; jealous 0x83E/F.
    ids = lambda line: sorted({fid & 0xFFF for _p, fid, _e, _c in by_text.get(line['text'], [])})
    check(ids(s1f) == [0xA56] and ids(s1m) == [0xA57], f's1 blunt/vulgar: the cell\'s last two slots: f {list(map(hex, ids(s1f)))} m {list(map(hex, ids(s1m)))}')
    check(ids(p1m) == [0xA36] and ids(p1f) == [0xA37], f's1 offer/vulgar player-gendered: {list(map(hex, ids(p1m) + ids(p1f)))}')
    check(ids(r2f) == [0xB96] and ids(r2m) == [0xB97], f's2 vulgar recoil: {list(map(hex, ids(r2f) + ids(r2m)))}')
    # THE check the first run lacked: every plain line keeps the ids it has in the real build.
    real = {}
    for _p, fid, _e, _c, t in infos((SRC / 'build/Overture.esp').read_bytes()):
        real.setdefault(t, set()).add(fid)
    mine = {}
    for _p, fid, _e, _c, t in got:
        if not t.startswith('TEST'):
            mine.setdefault(t, set()).add(fid)
    moved = [t for t in real if real[t] != mine.get(t)]
    check(not moved and set(real) == set(mine), f'every plain line keeps its ids from the real build ({len(moved)} moved: {moved[:3]})')
    check(all(0xF00 <= i <= 0xFFF for i in ids(a3f) + ids(a3m)) and len(ids(a3f)) == 4,
          f's3 accept in 0xF00 range, one per register: f {list(map(hex, ids(a3f)))} m {list(map(hex, ids(a3m)))}')
    check(0xFA6 in ids(a3f) and 0xFA7 in ids(a3m), 's3 vulgar/blunt accept at 0xFA6 (f) and 0xFA7 (m)')
    check(ids(jf) == [0xDDC] and ids(jm) == [0xDDD], f'jealous vulgar gendered at 0xDDC/0xDDD: {list(map(hex, ids(jf) + ids(jm)))}')
    check(all(0xD60 <= i <= 0xDD7 for i in ids(cf) + ids(cm)) and len(ids(cf)) == 3,
          f'companion accept in 0xD60..0xDD7, one per proposition: f {list(map(hex, ids(cf)))} m {list(map(hex, ids(cm)))}')
    # Fences: in every topic, each INFO carrying Random End (0x20) must be ungendered,
    # and within the s2 vulgar recoil run the gendered lines come before the neutral ones.
    fenced_bad = [(fid, t) for _p, fid, e, c, t in got if e & 0x20 and sex_ctdas(c)]
    check(not fenced_bad, f'no gendered INFO carries Random End ({fenced_bad})')
    rec = [(fid, t) for p, fid, e, c, t in got if 0xB80 <= (fid & 0xFFF) < 0xC00 and 'recoil' in t.lower()
           or t in (r2f['text'], r2m['text'])]
    order = [t for p, fid, e, c, t in got if (fid & 0xFFF) in range(0xB80 + 2 * 8, 0xB80 + 3 * 8)]
    check(order[:2] == [r2f['text'], r2m['text']] and len(order) == 4,
          f's2 vulgar recoil run order: gendered first, neutral last -> {order}')
    last_enam = [e for p, fid, e, c, t in got if (fid & 0xFFF) in range(0xB80 + 2 * 8, 0xB80 + 3 * 8)]
    check(last_enam[-1] & 0x20 and not any(x & 0x20 for x in last_enam[:-1]),
          f's2 vulgar recoil: only the last (neutral) line has Random End -> {list(map(hex, last_enam))}')
    jorder = [t for p, fid, e, c, t in got if 0x836 <= (fid & 0xFFF) <= 0x83F or 0xDD8 <= (fid & 0xFFF) <= 0xDDF]
    vul = [t for t in jorder if 'TEST jealous' in t or 'fuck' in t.lower()]
    check(vul[:2] == [jf['text'], jm['text']], f'jealous vulgar run: gendered first -> {vul}')

# ------------------------------------------------------------------ negative
def expect_refusal(label, mutate, needle):
    fresh()
    bank, cb = banks()
    mutate(bank['lines'], cb['lines'])
    save(bank, cb)
    code, log = build()
    check(code != 0 and needle in log, f'REFUSES {label} (exit {code}; "{needle}" in output: {needle in log})')


print('NEGATIVE: what the builder must refuse')


def all_gendered_fence(L, C):
    idx = [n for n, l in enumerate(L) if l['id'] in ('ov2_vulgar_recoil_01', 'ov2_vulgar_recoil_02')]
    L[idx[0]]['gender'] = 'f'
    L[idx[1]]['gender'] = 'm'


expect_refusal('a fenced run whose every line is gendered', all_gendered_fence, 'none can close the run')


def missing_sex(L, C):
    for l in L:
        if l['id'] in ('ov_vulgar_linger_miss_01', 'ov_vulgar_linger_miss_02'):
            l['gender'] = 'f'


expect_refusal('a cell with no line for a male speaker', missing_sex, 'no line for a m speaker')


def gendered_greeting(L, C):
    next(l for l in C if l['kind'] == 'companion_moment')['gender'] = 'f'


expect_refusal('a gendered companion greeting', gendered_greeting, 'cannot be gendered')


def bad_value(L, C):
    add(L, 'ov_vulgar_blunt_land_02', 'q', 'TEST bad', gender='x')


expect_refusal('gender "x"', bad_value, 'must be "m" or "f"')


def three_gendered(L, C):
    for s in ('a', 'b', 'c'):
        add(L, 'ov_vulgar_blunt_land_02', s, f'TEST extra {s}', gender='f' if s != 'b' else 'm')


expect_refusal('a third gendered line in a stage-1 cell', three_gendered, 'gendered lines; the id spacing')


def gendered_lover(L, C):
    next(l for l in L if l['kind'] == 'lover_greeting')['gender'] = 'f'


expect_refusal('a gendered lover greeting', gendered_lover, 'a lover greeting cannot be gendered')

print('PROBE CHECK: the id-stability check must be able to fail (GP-2)')
fresh()
bank, cb = banks()
add(bank['lines'], 'ov_jealous_vulgar_02', 'plain', 'TEST plain jealous inserted mid-list')
save(bank, cb)
code, log = build()
if code == 0:
    got2 = infos((T / 'build/t.esp').read_bytes())
    real = {}
    for _p, fid, _e, _c, t in infos((SRC / 'build/Overture.esp').read_bytes()):
        real.setdefault(t, set()).add(fid)
    mine = {}
    for _p, fid, _e, _c, t in got2:
        if not t.startswith('TEST'):
            mine.setdefault(t, set()).add(fid)
    moved = [t for t in real if real[t] != mine.get(t)]
    check(len(moved) == 2, f'a PLAIN line inserted mid-list is caught moving the 2 reticent greetings ({len(moved)} moved)')
else:
    check(False, 'probe build failed: ' + log[-300:])

shutil.rmtree(T.parent, ignore_errors=True)
print()
print('ALL PASSED' if not FAILS else f'{len(FAILS)} FAILED')
sys.exit(1 if FAILS else 0)
