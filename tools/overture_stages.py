"""The staged conversation: stage 1 -> 2 -> 3 in one scene (docs/methodology.md 1-3).

Built only by `make_overture_esp.py <out> --stages 3`. The default build is the
verified one-exchange plugin, byte for byte; this module is the next step and
NOTHING HERE IS VERIFIED IN GAME YET. It reuses make_overture_esp's record
writers unchanged, so a shape proven there is the same shape here.

HOW IT BRANCHES, WITHOUT A SCRIPT RACE. Conditions cannot write, so the reply
writes, and the SCENE'S PHASES read:

  - Overture:Reply's OnBegin -- as the NPC's line STARTS -- sets
    OvertureLastOutcome to what the line is (land, miss, recoil...). The scene
    moves to its next phase only when that line ENDS, 2 to 7 seconds later, and
    the next phase's start conditions read the global then. Nothing races.
  - phase 2 (stage 2) starts if LastOutcome is a land, OR the NPC has reached
    stage 1 on an earlier day (then phase 1 was skipped and stage 2 is today's
    first wheel). phase 3 (stage 3) starts if the verdict -- decided in the same
    OnBegin, at the stage-2 land -- is "not yet" or better. Anything else falls
    through to phase 4, HandBack: the type-4 "Start Scene" action with HTID, End
    Scene Say Greeting, which is how the one-exchange scene has always handed
    back to the NPC's own dialogue (O-8's order).
  - the reticent's first-meeting land records no land for this purpose (R-8:
    no stage 2 on the first day), so it hands back too.
  - WITHOUT the script, LastOutcome stays 0: phase 2 never starts on a first
    meeting and the staged plugin behaves exactly like the verified one-exchange
    one. A missing script degrades to what already works.

TWO ROUTES THAT FAILED IN GAME (2026-09-23), so nobody tries them again:
  - ENAM 0x40 End Running Scene on the ending replies: it ended the scene before
    the hand-back phase could run -- the conversation closed with no re-greet.
  - a TSCE + NAM0 "phase jump" to a named HandBack phase, both at the line's
    begin and with ENAM 0x01 Start Scene on End: the engine RESTARTED the scene
    from its first phase instead (OnBegin fired again, phases 1 and 2 again, the
    stage-1 wheel again), though the fields match xEdit's INFO layout and
    vanilla's own self-jumping lines (0015FF09) field for field. Not understood.
    And no line carries 0x40 at all -- not even the yes, which once did: XDI
    turns that flag into the option's "endsScene" for its menu, which marked the
    winning proposition on the wheel. A yes ends the scene because HandBack's
    start condition refuses to run after one.

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
# Light-plugin ranges (O-18); make_overture_esp.py has the whole map.
INFO_BASE_S2 = 0x01000B00
RECOIL_BASE_S2 = 0x01000B80
INFO_BASE_S3 = 0x01000C00
VERDICT_GLOBAL = 0x01000845     # Overture:Approach.VERDICT_*; the stage-3 replies read it
SCENES_GLOBAL = 0x01000846      # 1 = an accept really asks Rapport for a scene; 0 until proven

ENAM_END_RUNNING_SCENE = 0x40   # only the YES carries it now (see the docstring)
HAND_BACK = 'HandBack'          # the last phase's name (for the log and the CK; nothing jumps to it)
LAST_OUTCOME_GLOBAL = 0x01000847  # Overture:Reply's OnBegin writes it; phases 2 and 3 read it
CTDA_OR = 0x01                    # byte-0 flag: OR with the next condition
CTDA_OP_NE = 0x20                 # "not equal to", byte 0's top three bits
# Fallbacks for the two states no authored line covers (records review): no
# persona from Rapport, and a stage-3 verdict never decided.
FALLBACK_NO_PERSONA = 0x01000D00   # + stage * 0x10 + register slot
FALLBACK_NO_VERDICT = 0x01000D40   # + register slot
RUNON_QUEST_ALIAS = 5

# Overture:Reply's Outcome, continued from make_overture_esp's 1..5.
OUTCOME_ACCEPT, OUTCOME_NOTYET, OUTCOME_REFUSE, OUTCOME_NOT_HERE, OUTCOME_NOT_NOW = 6, 7, 8, 9, 10
# OvertureVerdict. 0 = not decided. 5 "not now": the moment is wrong, not the
# person (the romantic out of their setting, Rapport busy) -- once folded into
# "not yet", which told the player to try harder at the one thing that was not
# the problem (design review 2026-09-23).
VERDICT_REFUSE, VERDICT_NOTYET, VERDICT_ACCEPT, VERDICT_NOT_HERE, VERDICT_NOT_NOW = 1, 2, 3, 4, 5
# Phase 3 opens only for a verdict that has a chance: a proposition that could
# only be refused is never offered, so the player is not punished for taking the
# only path on the wheel (design review 2026-09-23). The verdict is decided as
# the stage-2 land BEGINS and the gate is read when it ENDS -- no race.
FUNC_OP_GE = 0x60
# Five verdict sets of two lines per (register, persona) cell.
S3_CELL = 16

NPC_SLOT_ORDER = ('NPOT', 'NNGT', 'NNUT', 'NQUT')


def glob(form_id, edid, value):
    f = m.field('EDID', m.zstring(edid))
    f += m.field('FNAM', b'f')
    f += m.field('FLTV', struct.pack('<f', value))
    return m.record('GLOB', form_id, f)


def verdict_condition(verdict):
    return m.field('CTDA', m.condition(m.FUNC_GET_GLOBAL_VALUE, VERDICT_GLOBAL,
                                       value=float(verdict), runon=0))


def no_persona_condition():
    return m.field('CTDA', m.condition(m.FUNC_GET_GLOBAL_VALUE, m.PERSONA_GLOBAL,
                                       value=-1.0, runon=0))


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
           (SCENES_GLOBAL, 'scenes global'), (LAST_OUTCOME_GLOBAL, 'last-outcome global'),
           (m.NEXT_DAY_AV, 'next-day actor value'), (m.STAGE_REACHED_AV, 'stage-reached actor value'),
           (m.GREET_TOPIC, 'greeting topic'), (m.GREET_INFO, 'greeting line')]
    children, count = b'', 0
    topics = {1: {}, 2: {}, 3: {}}

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
                        enam = m.ENAM_RANDOM | (m.ENAM_RANDOM_END if last else 0)
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
                    block += m.line(iid, None, text, persona_index=k,
                                    enam=m.ENAM_RANDOM, reply=(stage, code))
                    n_infos += 1
            # No persona from Rapport: nothing above can match. A neutral beat
            # that ends like a miss -- NOT Random, and last, so it never joins a
            # pool; it is reached only when every line above has failed.
            fid = FALLBACK_NO_PERSONA + stage * 0x10 + n
            ids.append((fid, f's{stage} no-persona fallback {register}'))
            block += m.line(fid, None, '...', enam=0,
                            reply=(stage, m.OUTCOME_MISS), extra=no_persona_condition())
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
                # The register that got here: the verdict decides. "Not here" has
                # lines of its own now (DRAFT, voice/lines.json): the stage-2
                # recoils it used to borrow answer a crude line the player may
                # not have said, and two of them say no (review 2026-09-23).
                sets = ((VERDICT_NOT_HERE, OUTCOME_NOT_HERE, propose.get((persona, 'nothere'), [])),
                        (VERDICT_REFUSE, OUTCOME_REFUSE, propose.get((persona, 'refuse'), [])),
                        (VERDICT_NOTYET, OUTCOME_NOTYET, propose.get((persona, 'notyet'), [])),
                        (VERDICT_ACCEPT, OUTCOME_ACCEPT, propose.get((persona, 'accept'), [])),
                        (VERDICT_NOT_NOW, OUTCOME_NOT_NOW, propose.get((persona, 'notnow'), [])))
            else:
                # Propositioned in the wrong register: refused, whatever the bond.
                sets = ((None, OUTCOME_REFUSE, propose.get((persona, 'refuse'), [])),)
            for s_index, (verdict, code, texts) in enumerate(sets):
                if not texts:
                    raise SystemExit(f'no stage-3 lines for {persona} verdict {verdict}')
                if len(texts) > 2:
                    # The id layout gives each verdict set two slots; a third
                    # variant would be dropped without a word.
                    raise SystemExit(f'{persona} verdict {verdict} has {len(texts)} lines; stage 3 has room for 2')
                # No flag on ANY answer, the yes included. XDI works out an
                # option's "endsScene" from its NPC reply's End Running Scene
                # flag and hands it to the menu (xdi DialogueEx.cpp:301,
                # Scaleform.cpp:398) -- F4MCP printed the yes as "[ends scene]"
                # on the wheel, which names the right register AND the answer.
                # The yes ends the scene by HandBack's own start condition
                # instead: it does not start after a yes.
                enam = m.ENAM_RANDOM
                for v, text in enumerate(texts):
                    iid = INFO_BASE_S3 + (n * len(m.PERSONAS) + k) * S3_CELL + s_index * 2 + v
                    ids.append((iid, f's3 {register}/{persona} set {s_index} {v}'))
                    extra = verdict_condition(verdict) if verdict is not None else b''
                    block += m.line(iid, None, text, persona_index=k, enam=enam,
                                    reply=(3, code), extra=extra)
                    n_infos += 1
            if lands_on.get(persona) == register:
                # A verdict never decided (0): the stage-2 land's script did not
                # run or has not yet. Silence here is unproven -- it may leave the
                # wheel waiting -- so say a neutral beat and hand back.
                fid = FALLBACK_NO_VERDICT + n
                ids.append((fid, f's3 no-verdict fallback {register}'))
                block += m.line(fid, None, '...', persona_index=k, enam=0,
                                reply=(3, m.OUTCOME_MISS), extra=verdict_condition(0))
                n_infos += 1
        fid = FALLBACK_NO_PERSONA + 3 * 0x10 + n
        ids.append((fid, f's3 no-persona fallback {register}'))
        block += m.line(fid, None, '...', enam=0, reply=(3, m.OUTCOME_MISS),
                        extra=no_persona_condition())
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
             + glob(SCENES_GLOBAL, 'OvertureScenesEnabled', 0.0)
             + glob(LAST_OUTCOME_GLOBAL, 'OvertureLastOutcome', 0.0))
    blob = m.group('GLOB', globs) + m.group('QUST', quest_blob)
    blob += m.group('AVIF', m.next_day_av() + m.stage_reached_av())

    # The header, and the uniqueness check, from the bytes actually written.
    return m.finish(blob), topics


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


def phase(conditions=b'', name=''):
    f = m.field('HNAM', b'')
    f += m.field('NAM0', m.zstring(name))
    f += conditions                      # start conditions sit before the first NEXT
    f += m.field('NEXT', b'')
    f += m.field('NEXT', b'')
    f += m.field('WNAM', struct.pack('<I', 500))
    f += m.field('HNAM', b'')
    return f


def scene_staged(topics):
    """Five phases: 0 empty (the alias settles), 1 stage 1 (first meetings only),
    2 stage 2 (after a land, or for a returning NPC), 3 stage 3 (only for a verdict
    of "not yet" or better), 4 HandBack -- the type-4 End Scene Say Greeting action
    the one-exchange scene ends with, which every ending reply jumps to."""
    f = m.field('EDID', m.zstring(m.SCENE_EDID))
    f += m.field('FNAM', struct.pack('<I', 0x00000024))
    first_meeting = m.field('CTDA', m.condition(m.FUNC_GET_VALUE, m.STAGE_REACHED_AV,
                                                value=0.0, runon=RUNON_QUEST_ALIAS,
                                                alias=m.ALIAS_INDEX))
    # Stage 2: today's stage 1 landed, OR stage 1 was skipped because they reached
    # it on an earlier day. The OR flag on the first joins it to the second.
    stage_two = m.field('CTDA', m.condition(m.FUNC_GET_GLOBAL_VALUE, LAST_OUTCOME_GLOBAL,
                                            value=float(m.OUTCOME_LAND), op=CTDA_OR))
    stage_two += m.field('CTDA', m.condition(m.FUNC_GET_VALUE, m.STAGE_REACHED_AV,
                                             value=1.0, op=FUNC_OP_GE,
                                             runon=RUNON_QUEST_ALIAS, alias=m.ALIAS_INDEX))
    has_a_chance = m.field('CTDA', m.condition(m.FUNC_GET_GLOBAL_VALUE, VERDICT_GLOBAL,
                                               value=float(VERDICT_NOTYET), op=FUNC_OP_GE))
    # HandBack: after anything but a yes. After a yes the scene simply ends -- the
    # dialogue closes so Rapport's scene can start, with no re-greet on top.
    not_after_yes = m.field('CTDA', m.condition(m.FUNC_GET_GLOBAL_VALUE, LAST_OUTCOME_GLOBAL,
                                                value=float(OUTCOME_ACCEPT), op=CTDA_OP_NE))
    f += (phase() + phase(first_meeting) + phase(stage_two) + phase(has_a_chance)
          + phase(not_after_yes, name=HAND_BACK))
    # The actor list: alias 0, as the one-exchange scene has it.
    f += m.field('ALID', struct.pack('<I', m.ALIAS_INDEX))
    f += m.field('LNAM', struct.pack('<I', 4))
    f += m.field('DNAM', struct.pack('<I', 10))
    f += dialogue_action(1, 1, topics[1])
    f += dialogue_action(2, 2, topics[2])
    f += dialogue_action(3, 3, topics[3])
    # HandBack: type 4 with HTID, "End Scene Say Greeting" -- the NPC re-greets and
    # their own dialogue takes over (O-8). The one-exchange scene's last action.
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
    f += m.field('VNAM', m.VNAM_DONT_SET_ALL)
    f += m.field('NNAM', m.zstring('Overture: an approach in three stages.'))
    f += m.field('XNAM', struct.pack('<I', 0))
    return m.record('SCEN', m.SCENE_FORMID, f)
