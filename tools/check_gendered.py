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
# The TEST lines go into the MERCANTILE persona's cells, which the bank leaves ungendered;
# the vulgar cells already hold their real male and female lines (O-40c).
s1f = add(L, 'ov_mercantile_blunt_miss_02', 'tf', 'TEST s1 blunt female', gender='f')
s1m = add(L, 'ov_mercantile_blunt_miss_02', 'tm', 'TEST s1 blunt male', gender='m')
p1m = add(L, 'ov_mercantile_offer_land_02', 'pm', 'TEST s1 offer to a male player', player_gender='m')
p1f = add(L, 'ov_mercantile_offer_land_02', 'pf', 'TEST s1 offer to a female player', player_gender='f')
r2f = add(L, 'ov2_mercantile_recoil_02', 'tf', 'TEST s2 recoil female', gender='f')
r2m = add(L, 'ov2_mercantile_recoil_02', 'tm', 'TEST s2 recoil male', gender='m')
a3f = add(L, 'ov3_mercantile_accept_02', 'tf', 'TEST s3 accept female', gender='f')
a3m = add(L, 'ov3_mercantile_accept_02', 'tm', 'TEST s3 accept male', gender='m')
jf = add(L, 'ov_jealous_mercantile_02', 'tf', 'TEST jealous female', gender='f')
jm = add(L, 'ov_jealous_mercantile_02', 'tm', 'TEST jealous male', gender='m')
C = cb['lines']
cf = add(C, 'co_mercantile_accept_01', 'tf', 'TEST companion accept female', gender='f')
cm = add(C, 'co_mercantile_accept_01', 'tm', 'TEST companion accept male', gender='m')
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

    # EVERY gendered line, the bank's own and the TEST ones: its INFOs carry exactly one
    # GetIsSex, on the speaker for `gender` and on PlayerRef for `player_gender`.
    gendered_lines = [l for l in L + C if l.get('gender') or l.get('player_gender')]
    for line in gendered_lines:
        key = 'gender' if line.get('gender') else 'player_gender'
        runon, ref = (0, 0) if key == 'gender' else (2, 0x14)
        sex = line[key]
        hits = by_text.get(line['text'], [])
        in_plugin = line['kind'] not in ('greeting', 'farewell', 'returning')
        if not in_plugin:
            continue
        check(bool(hits), f'{line["id"]}: written ({len(hits)} INFOs)')
        bad = [(fid, sex_ctdas(c)) for _p, fid, _e, c in hits
               if not (len(sex_ctdas(c)) == 1 and sex_ctdas(c)[0][1:] == (SEX[sex], runon, ref, 1.0, 0))]
        check(not bad, f'{line["id"]}: GetIsSex({SEX[sex]}) == 1 on runon {runon} on all {len(hits)} INFOs {bad[:2]}')
    # And no line outside that set carries one.
    gendered_texts = {l['text'] for l in gendered_lines}
    stray = [(fid, t) for _p, fid, _e, ctdas, t in got if sex_ctdas(ctdas) and t not in gendered_texts]
    check(not stray, f'no ungendered line carries GetIsSex ({len(stray)} do)')
    # Ids: stage 1/2 in the cell's last two slots; stage 3 in 0xF00; companion in 0xD60; jealous in 0xDD8.
    ids = lambda line: sorted({fid & 0xFFF for _p, fid, _e, _c in by_text.get(line['text'], [])})
    check(ids(s1f) == [0xA46] and ids(s1m) == [0xA47], f's1 blunt/mercantile: the cell\'s last two slots: f {list(map(hex, ids(s1f)))} m {list(map(hex, ids(s1m)))}')
    check(ids(p1m) == [0xA26] and ids(p1f) == [0xA27], f's1 offer/mercantile player-gendered: {list(map(hex, ids(p1m) + ids(p1f)))}')
    check(ids(r2f) == [0xB86] and ids(r2m) == [0xB87], f's2 mercantile recoil: {list(map(hex, ids(r2f) + ids(r2m)))}')
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
    check(sorted(ids(a3f)) == [0xF08, 0xF46, 0xF88, 0xFC8] and sorted(ids(a3m)) == [0xF09, 0xF47, 0xF89, 0xFC9],
          f's3 mercantile accept in 0xF00, one per register (its own offer set 3, the lover sets 4): '
          f'f {list(map(hex, ids(a3f)))} m {list(map(hex, ids(a3m)))}')
    check(ids(jf) == [0xDD8] and ids(jm) == [0xDD9], f'jealous mercantile gendered at 0xDD8/0xDD9: {list(map(hex, ids(jf) + ids(jm)))}')
    check(ids(cf) == [0xD66, 0xD8E, 0xDB6] and ids(cm) == [0xD67, 0xD8F, 0xDB7],
          f'companion mercantile accept, one per proposition: f {list(map(hex, ids(cf)))} m {list(map(hex, ids(cm)))}')
    # Fences: in every topic, each INFO carrying Random End (0x20) must be ungendered,
    # and within a fenced run the gendered lines come before the neutral ones.
    fenced_bad = [(fid, t) for _p, fid, e, c, t in got if e & 0x20 and sex_ctdas(c)]
    check(not fenced_bad, f'no gendered INFO carries Random End ({fenced_bad})')
    run = [(t, e) for p, fid, e, c, t in got if (fid & 0xFFF) in range(0xB80, 0xB88)]
    check([t for t, _ in run][:2] == [r2f['text'], r2m['text']] and len(run) == 4,
          f's2 mercantile recoil run order: gendered first, neutral last -> {[t for t, _ in run]}')
    check(run[-1][1] & 0x20 and not any(e & 0x20 for _, e in run[:-1]),
          f's2 mercantile recoil: only the last (neutral) line has Random End -> {[hex(e) for _, e in run]}')
    # The bank's own vulgar recoil run (O-40c's real lines) obeys the same rule.
    vrun = [(t, e, bool(sex_ctdas(c))) for p, fid, e, c, t in got if (fid & 0xFFF) in range(0xB90, 0xB98)]
    check(len(vrun) == 4 and vrun[-1][1] & 0x20 and not vrun[-1][2] and vrun[0][2] and vrun[1][2],
          f's2 vulgar recoil (real lines): gendered first, a neutral fence last -> {[(t[:24], hex(e), g) for t, e, g in vrun]}')
    jorder = [t for p, fid, e, c, t in got if 0x836 <= (fid & 0xFFF) <= 0x83F or 0xDD8 <= (fid & 0xFFF) <= 0xDDF]
    check(jorder[:2] == [jf['text'], jm['text']], f'jealous mercantile run: gendered first -> {jorder[:4]}')

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
    idx = [n for n, l in enumerate(L) if l['id'] in ('ov2_mercantile_recoil_01', 'ov2_mercantile_recoil_02')]
    L[idx[0]]['gender'] = 'f'
    L[idx[1]]['gender'] = 'm'


expect_refusal('a fenced run whose every line is gendered', all_gendered_fence, 'none can close the run')


def missing_sex(L, C):
    for l in L:
        if l['id'] in ('ov_mercantile_linger_miss_01', 'ov_mercantile_linger_miss_02'):
            l['gender'] = 'f'


expect_refusal('a cell with no line for a male speaker', missing_sex, 'no line for a m speaker')


def gendered_greeting(L, C):
    next(l for l in C if l['kind'] == 'companion_moment')['gender'] = 'f'


expect_refusal('a gendered companion greeting', gendered_greeting, 'cannot be gendered')


def bad_value(L, C):
    add(L, 'ov_mercantile_blunt_miss_02', 'q', 'TEST bad', gender='x')


expect_refusal('gender "x"', bad_value, 'must be "m" or "f"')


def three_gendered(L, C):
    for s in ('a', 'b', 'c'):
        add(L, 'ov_mercantile_blunt_miss_02', s, f'TEST extra {s}', gender='f' if s != 'b' else 'm')


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
