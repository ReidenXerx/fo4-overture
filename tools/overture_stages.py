"""The staged conversation: stage 1 -> 2 -> 3 in one scene (docs/methodology.md 1-3).

Built only by `make_overture_esp.py <out> --stages 3`. The default build is the
verified one-exchange plugin, byte for byte; this module is the next step and
NOTHING HERE IS VERIFIED IN GAME YET. It reuses make_overture_esp's record
writers unchanged, so a shape proven there is the same shape here.

HOW IT BRANCHES, WITHOUT A SCRIPT RACE. Conditions cannot write, and a script
that sets a gate in a reply's OnEnd races the scene's own move to the next
phase. So the branch is DATA:

  - a reply that ends the conversation carries ENAM 0x40, "End Running Scene"
    (xEdit's INFO response flags): every miss, offend and recoil, the
    reticent's first-meeting land (no stage 2 on the first day, R-8), and every
    stage-3 answer. A land carries nothing and the scene runs on into the next
    phase, where the next four options are.
  - the scene's phase 1 (stage 1) has a start condition on the ALIAS:
    OvertureStageReached == 0. A returning NPC skips it and the conversation
    opens at stage 2. Vanilla does exactly this: WorkshopRecruitVaultTec
    (SCEN 0010C957), started by an ALFA greeting like ours, gates its phase 2
    with a CTDA run on the ALFA alias (run-on 5, alias id in bytes 28-31).
    Phase 0 is left EMPTY so the alias is certainly filled before phase 1's
    condition is read -- the vanilla example conditions a later phase, never
    the first.
  - the stage-3 verdict is computed by Overture:Approach when the stage-2 LAND
    has been said (Overture:Reply's OnEnd), seconds before the stage-3 wheel
    even opens, and set in OvertureVerdict. The stage-3 replies are
    conditioned on it.

STAGE 3 IS FOUR REGISTERS, not "propose or goodbye". Every one of the base
game's 2,848 player-dialogue actions fills all four slots (measured
2026-09-23), so the wheel keeps its four: the proposition, phrased in each
register. Only the persona's own register gets a verdict; the other three are
refused. Leaving the conversation is the goodbye, and it costs nothing.
"""
import json
import struct

import make_overture_esp as m

# --------------------------------------------------------------------------
# ids -- clear of every range the one-exchange build uses (check_unique runs)
# --------------------------------------------------------------------------
PLAYER_TOPIC_S2 = 0x01000814    # four, after stage 1's 0x810..0x813
PLAYER_TOPIC_S3 = 0x01000818
NPC_TOPIC_S2 = 0x01000824       # four, after stage 1's 0x820..0x823
NPC_TOPIC_S3 = 0x01000828
PLAYER_INFO_S2 = 0x01000904     # after stage 1's 0x900..0x903
PLAYER_INFO_S3 = 0x01000908
INFO_BASE_S2 = 0x01001100
RECOIL_BASE_S2 = 0x01002100
INFO_BASE_S3 = 0x01003000
VERDICT_GLOBAL = 0x01000845     # Overture:Approach.VERDICT_*; the stage-3 replies read it
SCENES_GLOBAL = 0x01000846      # 1 = an accept really asks Rapport for a scene; 0 until proven

ENAM_END_RUNNING_SCENE = 0x40
RUNON_QUEST_ALIAS = 5

# Overture:Reply's Outcome, continued from make_overture_esp's 1..5.
OUTCOME_ACCEPT, OUTCOME_NOTYET, OUTCOME_REFUSE, OUTCOME_NOT_HERE = 6, 7, 8, 9
# OvertureVerdict. 0 = not decided, which matches nothing: silence rather than a guess.
VERDICT_REFUSE, VERDICT_NOTYET, VERDICT_ACCEPT, VERDICT_NOT_HERE = 1, 2, 3, 4

NPC_SLOT_ORDER = ('NPOT', 'NNGT', 'NNUT', 'NQUT')


def glob(form_id, edid, value):
    f = m.field('EDID', m.zstring(edid))
    f += m.field('FNAM', b'f')
    f += m.field('FLTV', struct.pack('<f', value))
    return m.record('GLOB', form_id, f)


def verdict_condition(verdict):
    return m.field('CTDA', m.condition(m.FUNC_GET_GLOBAL_VALUE, VERDICT_GLOBAL,
                                       value=float(verdict), runon=0))


def with_conditions(info, extra):
    """Insert extra CTDA fields into a built INFO, before its RNAM/NAM0 tail.

    make_overture_esp.line() writes persona/public CTDAs itself; the verdict is
    one more, and conditions are ANDed in file order, so it goes after them.
    The record header's size is rewritten to match.
    """
    head, body = info[:24], info[24:]
    o, out, done = 0, b'', False
    while o < len(body):
        sig = body[o:o + 4]
        size = struct.unpack_from('<H', body, o + 4)[0]
        if not done and sig in (b'RNAM', b'NAM0'):
            out += extra
            done = True
        out += body[o:o + 6 + size]
        o += 6 + size
    if not done:
        out += extra
    return head[:4] + struct.pack('<I', len(out)) + head[8:] + out


def player_stage(prompts, stage_key, topic_base, info_base, n, register):
    p = next(x for x in prompts[stage_key] if x['register'] == register)
    tid, pid = topic_base + n, info_base + n
    edid = f'OvertureTopic{register.capitalize()}{stage_key.capitalize()}'
    rec = m.topic(tid, edid, infos=1)
    rec += m.child_group(tid, 7, m.line(pid, p['text'], p.get('spoken', p['text']), enam=0))
    return tid, pid, rec


def build_staged():
    prompts = json.loads((m.ROOT / 'voice' / 'player-prompts.json').read_text(encoding='utf-8'))
    for key in ('stage2', 'stage3'):
        if key not in prompts:
            raise SystemExit(f'player-prompts.json has no "{key}" lines')
    stage1_prompts = {p['register']: p for p in prompts['prompts']}
    bank = json.loads((m.ROOT / 'voice' / 'lines.json').read_text(encoding='utf-8'))
    lands_on = bank['lands_on']

    reply = {1: {}, 2: {}}
    recoil = {1: {}, 2: {}}
    propose = {}
    for l in bank['lines']:
        if l['kind'] == 'response' and l['stage'] in (1, 2):
            reply[l['stage']].setdefault((l['register'], l['persona']), []).append((l['text'], l['outcome']))
        elif l['kind'] == 'recoil' and l['stage'] in (1, 2):
            recoil[l['stage']].setdefault(l['persona'], []).append(l['text'])
        elif l['kind'] == 'propose':
            propose.setdefault((l['persona'], l['outcome']), []).append(l['text'])

    ids = [(m.QUEST_FORMID, 'quest'), (m.SCENE_FORMID, 'scene'),
           (m.PERSONA_GLOBAL, 'persona global'), (m.PUBLIC_GLOBAL, 'public global'),
           (m.ENABLED_GLOBAL, 'enabled global'), (VERDICT_GLOBAL, 'verdict global'),
           (SCENES_GLOBAL, 'scenes global'),
           (m.NEXT_DAY_AV, 'next-day actor value'), (m.STAGE_REACHED_AV, 'stage-reached actor value'),
           (m.GREET_TOPIC, 'greeting topic'), (m.GREET_INFO, 'greeting line')]
    children, count = b'', 0
    topics = {1: {}, 2: {}, 3: {}}

    def ends(stage, persona, outcome_code):
        if stage == 3:
            return True
        if outcome_code != m.OUTCOME_LAND:
            return True
        # R-8: the reticent answers nothing the first few times. Stage 1 only
        # ever plays on a first meeting (phase 1's condition), so ending the
        # reticent's stage-1 land is "no stage 2 on the first day".
        return stage == 1 and persona == 'reticent'

    for n, (slot, register) in enumerate(m.SLOTS):
        npc_slot = m.NPC_SLOT[slot]

        # ---- stages 1 and 2: the same shape, the bank's own lines ----------
        for stage, ptopic, pinfo, rtopic, base, rbase in (
                (1, m.TOPIC_BASE, m.PLAYER_INFO_BASE, m.NPC_TOPIC_BASE, m.INFO_BASE, m.RECOIL_BASE),
                (2, PLAYER_TOPIC_S2, PLAYER_INFO_S2, NPC_TOPIC_S2, INFO_BASE_S2, RECOIL_BASE_S2)):
            if stage == 1:
                p = stage1_prompts[register]
                tid, pid = ptopic + n, pinfo + n
                prec = m.topic(tid, f'OvertureTopic{register.capitalize()}', infos=1)
                prec += m.child_group(tid, 7, m.line(pid, p['text'], p.get('spoken', p['text']), enam=0))
            else:
                tid, pid, prec = player_stage(prompts, 'stage2', ptopic, pinfo, n, register)
            ids += [(tid, f's{stage} player topic {register}'), (pid, f's{stage} player line {register}')]
            topics[stage][slot] = tid
            children += prec
            count += 2

            rtid = rtopic + n
            topics[stage][npc_slot] = rtid
            ids.append((rtid, f's{stage} reply topic {register}'))
            block, n_infos = b'', 0
            if register == m.INTIMATE_REGISTER:
                for k, persona in enumerate(m.PERSONAS):
                    texts = recoil[stage].get(persona, [])
                    liked = lands_on.get(persona) == register
                    code = m.OUTCOME_RECOIL_LIKED if liked else m.OUTCOME_RECOIL
                    for v, text in enumerate(texts):
                        rid = rbase + k * m.MAX_VARIANTS + v
                        ids.append((rid, f's{stage} recoil {persona} {v}'))
                        last = v == len(texts) - 1
                        enam = m.ENAM_RANDOM | (m.ENAM_RANDOM_END if last else 0) | ENAM_END_RUNNING_SCENE
                        block += m.line(rid, None, text, persona_index=k, public=1,
                                        enam=enam, reply=(stage, code))
                        n_infos += 1
            for k, persona in enumerate(m.PERSONAS):
                texts = reply[stage].get((register, persona))
                if not texts:
                    raise SystemExit(f'no stage-{stage} response for {register}/{persona}')
                for v, (text, outcome) in enumerate(texts):
                    iid = base + (n * len(m.PERSONAS) + k) * m.MAX_VARIANTS + v
                    ids.append((iid, f's{stage} {register}/{persona} {v}'))
                    if outcome == 'land':
                        code = m.OUTCOME_LAND
                    elif register == m.INTIMATE_REGISTER:
                        code = m.OUTCOME_OFFEND
                    else:
                        code = m.OUTCOME_MISS
                    enam = m.ENAM_RANDOM | (ENAM_END_RUNNING_SCENE if ends(stage, persona, code) else 0)
                    block += m.line(iid, None, text, persona_index=k, enam=enam, reply=(stage, code))
                    n_infos += 1
            children += m.topic(rtid, f'OvertureReply{register.capitalize()}S{stage}', infos=n_infos)
            children += m.child_group(rtid, 7, block)
            count += 1 + n_infos

        # ---- stage 3: the proposition, in this register --------------------
        tid, pid, prec = player_stage(prompts, 'stage3', PLAYER_TOPIC_S3, PLAYER_INFO_S3, n, register)
        ids += [(tid, f's3 player topic {register}'), (pid, f's3 player line {register}')]
        topics[3][slot] = tid
        children += prec
        count += 2

        rtid = NPC_TOPIC_S3 + n
        topics[3][npc_slot] = rtid
        ids.append((rtid, f's3 reply topic {register}'))
        block, n_infos = b'', 0
        for k, persona in enumerate(m.PERSONAS):
            if lands_on.get(persona) == register:
                # The register that got here: the verdict decides. "Not here" is
                # the stage-2 recoil, which already IS that line (methodology 6).
                sets = ((VERDICT_NOT_HERE, OUTCOME_NOT_HERE, recoil[2].get(persona, [])),
                        (VERDICT_REFUSE, OUTCOME_REFUSE, propose.get((persona, 'refuse'), [])),
                        (VERDICT_NOTYET, OUTCOME_NOTYET, propose.get((persona, 'notyet'), [])),
                        (VERDICT_ACCEPT, OUTCOME_ACCEPT, propose.get((persona, 'accept'), [])))
            else:
                # Propositioned in the wrong register: refused, whatever the bond.
                sets = ((None, OUTCOME_REFUSE, propose.get((persona, 'refuse'), [])),)
            for s_index, (verdict, code, texts) in enumerate(sets):
                if not texts:
                    raise SystemExit(f'no stage-3 lines for {persona} verdict {verdict}')
                for v, text in enumerate(texts[:2]):
                    iid = INFO_BASE_S3 + (n * len(m.PERSONAS) + k) * m.MAX_VARIANTS + s_index * 2 + v
                    ids.append((iid, f's3 {register}/{persona} set {s_index} {v}'))
                    info = m.line(iid, None, text, persona_index=k,
                                  enam=m.ENAM_RANDOM | ENAM_END_RUNNING_SCENE, reply=(3, code))
                    if verdict is not None:
                        info = with_conditions(info, verdict_condition(verdict))
                    block += info
                    n_infos += 1
        children += m.topic(rtid, f'OvertureReply{register.capitalize()}S3', infos=n_infos)
        children += m.child_group(rtid, 7, block)
        count += 1 + n_infos

    m.check_unique(ids)

    children += m.greeting()
    children += scene_staged(topics)
    quest_blob = m.quest() + m.child_group(m.QUEST_FORMID, 10, children)
    globs = (m.persona_global() + m.public_global() + m.enabled_global()
             + glob(VERDICT_GLOBAL, 'OvertureVerdict', 0.0)
             + glob(SCENES_GLOBAL, 'OvertureScenesEnabled', 0.0))
    blob = m.group('GLOB', globs) + m.group('QUST', quest_blob)
    blob += m.group('AVIF', m.next_day_av() + m.stage_reached_av())

    records = 5 + 2 + 1 + 1 + 2 + count   # globs, AVIFs, quest, scene, greeting pair, the rest
    next_object = max(i for i, _ in ids) + 1
    head = m.field('HEDR', struct.pack('<fiI', 1.0, records, next_object))
    head += m.field('CNAM', m.zstring(m.AUTHOR))
    head += m.field('MAST', m.zstring(m.MASTER))
    head += m.field('DATA', struct.pack('<Q', 0))
    return m.record('TES4', 0, head) + blob, topics


def dialogue_action(index, phase, slots):
    """A player-dialogue action: the one-exchange scene's, with its own phase."""
    f = m.field('ANAM', struct.pack('<H', 3))
    f += m.field('NAM0', b'\0')
    f += m.field('ALID', struct.pack('<I', m.ALIAS_INDEX))
    f += m.field('INAM', struct.pack('<I', index))
    f += m.field('FNAM', struct.pack('<I', 0x00200000))   # the verified flags (make_overture_esp.scene)
    f += m.field('SNAM', struct.pack('<I', phase))
    f += m.field('ENAM', struct.pack('<I', phase))
    for slot in ('PTOP', 'NTOP', 'NETO', 'QTOP') + NPC_SLOT_ORDER:
        f += m.field(slot, struct.pack('<I', slots[slot]))
    f += m.field('DTGT', struct.pack('<I', m.ALIAS_INDEX))
    f += m.field('ANAM', b'')
    return f


def phase(conditions=b''):
    f = m.field('HNAM', b'')
    f += m.field('NAM0', b'\0')
    f += conditions                      # start conditions sit before the first NEXT
    f += m.field('NEXT', b'')
    f += m.field('NEXT', b'')
    f += m.field('WNAM', struct.pack('<I', 500))
    f += m.field('HNAM', b'')
    return f


def scene_staged(topics):
    """Five phases: 0 empty (the alias settles), 1 stage 1 (first meetings only),
    2 stage 2, 3 stage 3, 4 the hold the one-exchange scene needed."""
    f = m.field('EDID', m.zstring(m.SCENE_EDID))
    f += m.field('FNAM', struct.pack('<I', 0x00000024))
    first_meeting = m.field('CTDA', m.condition(m.FUNC_GET_VALUE, m.STAGE_REACHED_AV,
                                                value=0.0, runon=RUNON_QUEST_ALIAS))
    f += phase() + phase(first_meeting) + phase() + phase() + phase()
    # The actor list: alias 0, as the one-exchange scene has it.
    f += m.field('ALID', struct.pack('<I', m.ALIAS_INDEX))
    f += m.field('LNAM', struct.pack('<I', 4))
    f += m.field('DNAM', struct.pack('<I', 10))
    f += dialogue_action(1, 1, topics[1])
    f += dialogue_action(2, 2, topics[2])
    f += dialogue_action(3, 3, topics[3])
    # The hold, type 4, as make_overture_esp.scene has it -- in the last phase.
    f += m.field('ANAM', struct.pack('<H', 4))
    f += m.field('NAM0', b'\0')
    f += m.field('ALID', struct.pack('<I', m.ALIAS_INDEX))
    f += m.field('INAM', struct.pack('<I', 4))
    f += m.field('SNAM', struct.pack('<I', 4))
    f += m.field('ENAM', struct.pack('<I', 4))
    f += m.field('STSC', struct.pack('<I', 0))
    f += m.field('HTID', b'')
    f += m.field('ANAM', b'')
    f += m.field('PNAM', struct.pack('<I', m.QUEST_FORMID))
    f += m.field('INAM', struct.pack('<I', 4))            # the highest action index, as vanilla's tails read
    f += m.field('VNAM', struct.pack('<IIII', m.ALIAS_INDEX, m.ALIAS_INDEX, m.ALIAS_INDEX, m.ALIAS_INDEX))
    f += m.field('NNAM', m.zstring('Overture: an approach in three stages.'))
    f += m.field('XNAM', struct.pack('<I', 0))
    return m.record('SCEN', m.SCENE_FORMID, f)
