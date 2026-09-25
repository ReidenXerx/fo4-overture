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
  - a conversation that OPENS AT THE PROPOSITION skips phases 1 and 2: they
    said yes before (O-12), the lover tier (O-14), or "not now" / "not here"
    earlier today (O-30). Three actor values, all written as a conversation
    ENDS, so a phase condition never reads one mid-conversation. Its verdict is
    decided as the scene begins (Approach.Opening), seconds before the player
    can pick; the gate itself reads only the markers.
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
# O-40c's male and female versions of a stage-3 answer. Stage 3's own layout gives each
# verdict set two slots and no spare, so gendered lines live in the free 0xF00 range:
# + (register slot * 4 + persona) * 16 + verdict set * 2 + (0 or 1). Up to two per set;
# O-31's lover sets reach set 5, so the highest id is 0xFFB.
GENDERED_S3_BASE = 0x01000F00
VERDICT_GLOBAL = 0x01000845     # Overture:Approach.VERDICT_*; the stage-3 replies read it
# O-46: which version of every player option this conversation shows (0-4), rolled by
# Approach as a conversation opens. The existing line is version 0 and keeps its id (and
# its voice file); versions 1-4 live in the free 0x90C-0x93B: + ((stage-1)*4 + slot)*4 + (v-1).
PLAYER_VARIANT_GLOBAL = 0x0100084D
PLAYER_VARIANT_BASE = 0x0100090C
PLAYER_VARIANTS = 5
# 0x846 was OvertureScenesEnabled: an MCM setting now (SWITCHES), and retired.

ENAM_END_RUNNING_SCENE = 0x40   # only the YES carries it now (see the docstring)
HAND_BACK = 'HandBack'          # the last phase's name (for the log and the CK; nothing jumps to it)
LAST_OUTCOME_GLOBAL = 0x01000847  # Overture:Reply's OnBegin writes it; phases 2 and 3 read it
# Fallbacks for the two states no authored line covers (records review): no
# persona from Rapport, and a stage-3 verdict never decided.
FALLBACK_NO_PERSONA = 0x01000D00   # + stage * 0x10 + register slot
FALLBACK_NO_VERDICT = 0x01000D40   # + register slot
FALLBACK_NO_VERDICT_LOVER = 0x01000D50   # + register slot * 4 + persona (O-31's lover sets)
RUNON_QUEST_ALIAS = 5

# THE COMPANION MODULE (methodology 11; O-19: B-lite + C + D). Its records, in the
# 0x850-0x8FF range reserved for it, and 0xE10-0xEFF for the wheel's answers.
COMPANIONS_QUEST = 0x01000855        # the companion scripts; a script holder like RapportBridgeQuest
COMPANIONS_QUEST_EDID = 'OvertureCompanionsQuest'
COMPANION_DESIRE_AV = 0x01000851     # PUBLISHED: fo4-anatomy reads it, 0..1. Never renumber.
COMPANION_MOMENT_AV = 0x01000853     # MOMENT_* below; written by Overture:Companions:Moments
COMPANION_LAST_TICK_AV = 0x01000856  # the game day the feeders last counted
COMPANION_FALL_AV = 0x01000857       # the negative level counted in the current fall (0, -1, -2)
COMPANION_PAIR_SEEN_AV = 0x01000858  # the player's scene count WITH them, plus one, as they knew it
COMPANION_SEEN_SCENE_AV = 0x0100085A  # the player's scene count with anyone ELSE, plus one, as they knew it
COMPANION_TIER_AV = 0x0100085B       # the highest level of their own affinity ever counted (0-4)
# Their own queued conversation (vanilla CA_WantsToTalk, Fallout4.esm): nonzero means an
# affinity scene of THEIRS is waiting, and it goes first -- read live in the greeting,
# so the 20 s between Moments' polls cannot let ours beat it (microscope wave 3).
CA_WANTS_TO_TALK_AV = 0x000FA86B
COMPANION_GREET_BASE = 0x01000860    # four: the moment's two, then the player's start's two
# O-35 (owner, 2026-09-23): the player's own way in, "Ask for a moment" on the companion's
# activation prompt -- a perk Activate choice on the player, like vanilla's "Pet" and "Hack".
COMPANION_ASK_PERK = 0x01000859
COMPANION_ASK_PERK_EDID = 'OvertureAskPerk'
COMPANION_ASK_FRAGMENT = 'Overture:Fragments:AskPerk'
COMPANION_ASK_LABEL = 'Ask for a moment'
COMPANION_PLAYER_TOPIC = 0x01000864  # four, one per wheel slot
COMPANION_PLAYER_INFO = 0x01000868
COMPANION_NPC_TOPIC = 0x0100086C
COMPANION_ANSWER_BASE = 0x01000E10   # + slot * 0x40; persona * 10 + verdict set * 2 + variant
COMPANION_SLOT_STRIDE = 0x40
COMPANION_FALLBACK = 0x28            # within a slot: + 0 no persona, + 1 no verdict
# O-40c's male and female companion answers, which the stride has no room for:
# + ((proposition * 4 + persona) * 5 + verdict set) * 2 + (0 or 1), where the propositions
# are the wheel's three non-"Later." slots in order. 0xD60..0xDD7; 0xDD8-0xDFF stay free.
COMPANION_GENDERED_BASE = 0x01000D60
COMPANION_SCRIPTS = ('Overture:Companions:Registry', 'Overture:Companions:EngineAdapter',
                     'Overture:Companions:VanillaAdapter', 'Overture:Companions:IvyAdapter',
                     'Overture:Companions:Feeders', 'Overture:Companions:Moments',
                     'Overture:Companions:IvyNative')
# OvertureCompanionMoment. 0: not ours to open (C6 -- no adapter vouches, their own
# scene, their state says no). 1: vouched, so the player may ask (O-23, O-35). 2: a
# moment is open (C), so the companion speaks first. 3: the player has just ASKED
# (the perk's choice), so their next talk opens it.
MOMENT_VOUCHED, MOMENT_OPEN, MOMENT_ASKED = 1, 2, 3
# The companion wheel. The offer's NEUTRAL slot holds the costless "Later."
# (voice/companion-lines.json has why); the other three are stage 3's propositions.
# Registers decide nothing here: a companion's answer is their state and their
# wanting, never the player's choice of words (O-22, B-lite).
COMPANION_WHEEL = (('PTOP', 'charm'), ('NETO', 'later'), ('NTOP', 'blunt'), ('QTOP', 'linger'))

# Overture:Reply's Outcome, continued from make_overture_esp's 1..5.
OUTCOME_ACCEPT, OUTCOME_NOTYET, OUTCOME_REFUSE, OUTCOME_NOT_HERE, OUTCOME_NOT_NOW = 6, 7, 8, 9, 10
# The companion's answer to "Later.": nothing happened, and nothing is paid.
OUTCOME_LATER = 11
# R-27 (owner poll, 2026-09-25): "not my type", orientation. Keyed on the PLAYER's sex.
OUTCOME_NOT_TYPE = 12
# OvertureVerdict. 0 = not decided. 5 "not now": the moment is wrong, not the
# person (the romantic out of their setting, Rapport busy) -- once folded into
# "not yet", which told the player to try harder at the one thing that was not
# the problem (design review 2026-09-23).
VERDICT_REFUSE, VERDICT_NOTYET, VERDICT_ACCEPT, VERDICT_NOT_HERE, VERDICT_NOT_NOW = 1, 2, 3, 4, 5
# R-27: they are not into the player's sex. It passes phase 3's gate (>= NOTYET) on
# purpose: the player asks, and learns it from them -- and it costs nothing.
VERDICT_NOT_TYPE = 6
# Phase 3 opens, after a stage-2 land, only for a verdict that has a chance: a
# proposition that could only be refused is never offered there, so the player is
# not punished for taking the only path on the wheel (design review 2026-09-23).
# The verdict is decided as the land BEGINS and the gate is read when it ENDS --
# no race. A conversation that opens AT the proposition opens it whatever the
# verdict (its markers are all the gate can read in time); Approach keeps the
# only-refusable case out of those markers, and a refusal there costs nothing.
# Six verdict sets of two lines per (register, persona) cell (R-27 added "not my type").
S3_CELL = 16

NPC_SLOT_ORDER = ('NPOT', 'NNGT', 'NNUT', 'NQUT')

# THE TUNABLE NUMBERS (methodology 3; every one ASSUMED, for the owner to tune).
# MCM ModSettings, NOT globals: a GLOB's value is written into every save, so a
# default changed in a later Overture would never reach a game that already had
# the plugin (microscope pass 1, lens 6). MCM keeps them in its own ini, and a new
# default ships in MCM/Config/Overture/settings.ini. tools/make_mcm.py writes the
# page and the ini from this table, and refuses to unless every Tuned call in
# Overture:Approach names a row here and falls back to that row's default.
#   (key, ini section, default, page section, label, help, min, max, step)
SETTINGS = [
    ('fLandFirst', 'Words', 0.05, 'What words are worth', 'The first thing that lands',
     'How much the bond grows when the first approach lands (a share of the distance left, as every source moves it).',
     0.0, 0.3, 0.01),
    ('fLandSecond', 'Words', 0.07, 'What words are worth', 'The second thing that lands',
     'The same, for the second exchange.', 0.0, 0.3, 0.01),
    ('fOffend', 'Words', -0.04, 'What words are worth', 'Blunt at the wrong person',
     'What crude words cost with someone who did not want them.', -0.3, 0.0, 0.01),
    ('fRecoil', 'Words', -0.06, 'What words are worth', 'Crude in public',
     'What an intimate line costs in front of people, with someone who would not have liked it anyway.', -0.3, 0.0, 0.01),
    ('fNotYet', 'Words', 0.02, 'What words are worth', 'Asked too soon',
     'A proposition answered "not yet" still means something.', 0.0, 0.2, 0.01),
    ('fRefuse', 'Words', -0.03, 'What words are worth', 'Asked the wrong way',
     'A proposition refused.', -0.3, 0.0, 0.01),
    ('fBarMercantile', 'Bars', 0.15, 'How close before a yes', 'Mercantile',
     'The bond a mercantile person needs before they say yes.', 0.0, 1.0, 0.01),
    ('fBarRomantic', 'Bars', 0.25, 'How close before a yes', 'Romantic',
     'The same for a romantic, who also wants the right moment.', 0.0, 1.0, 0.01),
    ('fBarVulgar', 'Bars', 0.08, 'How close before a yes', 'Vulgar', 'The fast lane.', 0.0, 1.0, 0.01),
    ('fBarReticent', 'Bars', 0.30, 'How close before a yes', 'Reticent',
     'They take days to open up.', 0.0, 1.0, 0.01),
    ('fLoverBond', 'Bars', 0.75, 'How close before a yes', 'Lovers from a bond of',
     'At this bond, conversations open at the proposition - from the next one after a conversation ends '
     'there. With a scene together as well, you are a couple to everyone else too.', 0.3, 1.0, 0.05),
    ('fFaithRefuses', 'SpokenFor', 0.80, 'Spoken for', 'Faithful enough to always refuse',
     'Someone married or courting refuses outright at this faithfulness or above.', 0.0, 1.0, 0.05),
    ('fFaithWeight', 'SpokenFor', 0.40, 'Spoken for', 'How much being spoken for raises the bar',
     'Below that, the bar rises by this much of their faithfulness.', 0.0, 1.0, 0.05),
    ('fJealousySting', 'Jealousy', -0.06, 'Jealousy', 'When it hurts',
     "What a romantic or reticent lover's bond loses on hearing you have been with someone else.",
     -0.3, 0.0, 0.01),
    ('fJealousyThrill', 'Jealousy', 0.03, 'Jealousy', 'When it thrills',
     "What a vulgar lover's bond gains on hearing it. The mercantile shrug.", 0.0, 0.2, 0.01),
    # THE COMPANION MODULE (methodology 11). Wanting (Desire, 0..1) is the one state
    # of its own: it builds with days on the road together and falls after a scene
    # together. Every number ASSUMED, for the owner to tune.
    ('fDesireMercantile', 'Companions', 0.50, 'Companions', 'Wanting before a yes: mercantile',
     'How much a mercantile companion has to want it before they say yes (0 to 1). It builds with every '
     'day on the road together, and a scene together sates it.', 0.0, 1.0, 0.05),
    ('fDesireRomantic', 'Companions', 0.50, 'Companions', 'Wanting before a yes: romantic',
     'The same, for a romantic companion.', 0.0, 1.0, 0.05),
    ('fDesireVulgar', 'Companions', 0.30, 'Companions', 'Wanting before a yes: vulgar',
     'The same, for a vulgar companion.', 0.0, 1.0, 0.05),
    ('fDesireReticent', 'Companions', 0.70, 'Companions', 'Wanting before a yes: reticent',
     'The same, for a reticent companion.', 0.0, 1.0, 0.05),
    ('fRomancedEase', 'Companions', 0.20, 'Companions', 'Romanced: the bar is lower by',
     'A companion you have romanced, by their own romance, needs this much less.', 0.0, 0.5, 0.05),
    ('fAffinityGate', 'Companions', 1.00, 'Companions', 'No romance of their own: affinity needed',
     'Companions the game gives no romance (X6-88, Deacon, Gage, Old Longfellow) need their own affinity '
     'this high first: 1 is their top level, 0.75 the one below it.', 0.25, 1.0, 0.25),
    ('fDesirePerDay', 'Companions', 0.10, 'Companions', 'Wanting grows per day together',
     'How much a game day travelling together builds wanting.', 0.0, 0.5, 0.01),
    ('fTogetherPerDay', 'Companions', 0.01, 'Companions', 'A day together adds to the bond',
     "A share of the distance left, as every source moves Rapport's bond.", 0.0, 0.1, 0.005),
    ('fThresholdUp', 'Companions', 0.08, 'Companions', 'Their affinity reaches a new level',
     'What each level of their own affinity adds to the bond, the first time they reach it (Friend, '
     'Admiration, Confidant, Infatuation).', 0.0, 0.3, 0.01),
    ('fThresholdDown', 'Companions', -0.08, 'Companions', 'Their affinity falls to Disdain or Hatred',
     'What each of those takes away, once per fall.', -0.3, 0.0, 0.01),
    ('fMomentCooldown', 'Companions', 2.0, 'Companions', 'Days between moments',
     'After a moment is used or passes unused, how many game days before a companion who still wants '
     'you asks again.', 0.5, 7.0, 0.5),
]
# The switches that are MCM settings (the other, OvertureEnabled, is a global: the
# greeting's own conditions read it).  (key, ini section, default, label, help)
SWITCHES = [
    ('bScenes', 'Switches', False, 'A yes starts a scene',
     'When someone says yes, Rapport starts the scene. Off: they say yes and nothing more happens.'),
    # O-20 (owner, 2026-09-23): ON by default -- and it acts only with "A yes starts a
    # scene" on, which is how "after a player scene is proven end to end" is kept.
    ('bIvyFade', 'Ivy', True, "Ivy: her fade becomes a scene",
     "When Ivy's own Favor: Sex scene fades to black, Rapport plays the scene, then hers carries on. "
     "Needs 'A yes starts a scene'."),
]
# In settings.ini and on no control: Approach.HasSettings's proof that MCM read THIS
# file. A key that is a slider cannot prove it -- a player's one moved slider made
# MCM answer for it while every other key read 0 (microscope pass 2).
META = 'iDefaults:Meta'


def glob(form_id, edid, value):
    f = m.field('EDID', m.zstring(edid))
    f += m.field('FNAM', b'f')
    f += m.field('FLTV', struct.pack('<f', value))
    return m.record('GLOB', form_id, f)


def verdict_condition(verdict):
    return m.field('CTDA', m.condition(m.FUNC_GET_GLOBAL_VALUE, VERDICT_GLOBAL,
                                       value=float(verdict), runon=0))


def a_lover():
    """On the speaker: they said yes before (O-12) OR the lover tier (O-14) -- the
    two markers O-31 lets every register reach the verdict for. One OR group."""
    return (m.field('CTDA', m.condition(m.FUNC_GET_VALUE, m.SAID_YES_AV, value=1.0,
                                        op=m.CTDA_OP_EQ | m.CTDA_OR, runon=m.RUNON_SUBJECT))
            + m.field('CTDA', m.condition(m.FUNC_GET_VALUE, m.TIER_AV, value=float(m.TIER_LOVER),
                                          op=m.CTDA_OP_EQ, runon=m.RUNON_SUBJECT)))


def not_a_lover():
    """Its negation: no yes before AND not the lover tier."""
    return (m.field('CTDA', m.condition(m.FUNC_GET_VALUE, m.SAID_YES_AV, value=1.0,
                                        op=m.CTDA_OP_NE, runon=m.RUNON_SUBJECT))
            + m.field('CTDA', m.condition(m.FUNC_GET_VALUE, m.TIER_AV, value=float(m.TIER_LOVER),
                                          op=m.CTDA_OP_NE, runon=m.RUNON_SUBJECT)))


def no_persona_condition():
    return m.field('CTDA', m.condition(m.FUNC_GET_GLOBAL_VALUE, m.PERSONA_GLOBAL,
                                       value=-1.0, runon=0))


def player_versions(p, stage, n, pid):
    """O-46: the option's five versions as INFOs, each shown only for its roll. The line
    itself is version 0 on its old id; exactly one version passes, whatever the roll."""
    versions = [p] + p.get('variants', [])
    if len(versions) != PLAYER_VARIANTS:
        raise SystemExit(f'stage {stage} {p["register"]}: {len(versions)} versions, the layout holds {PLAYER_VARIANTS}')
    block, ids = b'', []
    for v, version in enumerate(versions):
        iid = pid if v == 0 else PLAYER_VARIANT_BASE + ((stage - 1) * 4 + n) * 4 + (v - 1)
        cond = m.field('CTDA', m.condition(m.FUNC_GET_GLOBAL_VALUE, PLAYER_VARIANT_GLOBAL, value=float(v), runon=0))
        block += m.line(iid, version['text'], version.get('spoken', version['text']), enam=0, extra=cond)
        ids.append(iid)
    return block, ids


def player_stage(prompts, stage_key, topic_base, info_base, n, register):
    p = next(x for x in prompts[stage_key] if x['register'] == register)
    tid, pid = topic_base + n, info_base + n
    edid = f'OvertureTopic{register.capitalize()}{stage_key.capitalize()}'
    block, vids = player_versions(p, {'stage2': 2, 'stage3': 3}[stage_key], n, pid)
    rec = m.topic(tid, edid, infos=len(vids))
    rec += m.child_group(tid, 7, block)
    return tid, pid, rec, vids


def build_staged():
    prompts = json.loads((m.ROOT / 'voice' / 'player-prompts.json').read_text(encoding='utf-8'))
    for key in ('stage2', 'stage3'):
        if key not in prompts:
            raise SystemExit(f'player-prompts.json has no "{key}" lines')
    stage1_prompts = {p['register']: p for p in prompts['prompts']}
    bank = json.loads((m.ROOT / 'voice' / 'lines.json').read_text(encoding='utf-8'))
    lands_on = bank['lands_on']
    companion_bank = json.loads((m.ROOT / 'voice' / 'companion-lines.json').read_text(encoding='utf-8'))

    reply = {1: {}, 2: {}}
    recoil = {1: {}, 2: {}}
    propose = {}
    # Whole lines, not just their text: a line's gender (O-40c) becomes a condition.
    for l in bank['lines']:
        if l['kind'] == 'response' and l['stage'] in (1, 2):
            reply[l['stage']].setdefault((l['register'], l['persona']), []).append(l)
        elif l['kind'] == 'recoil' and l['stage'] in (1, 2):
            recoil[l['stage']].setdefault(l['persona'], []).append(l)
        elif l['kind'] == 'propose':
            propose.setdefault((l['persona'], l['outcome']), []).append(l)

    ids = [(m.QUEST_FORMID, 'quest'), (m.SCENE_FORMID, 'scene'),
           (m.PERSONA_GLOBAL, 'persona global'), (m.PUBLIC_GLOBAL, 'public global'),
           (m.ENABLED_GLOBAL, 'enabled global'), (m.OPENING_GLOBAL, 'opening global'), (VERDICT_GLOBAL, 'verdict global'),
           (LAST_OUTCOME_GLOBAL, 'last-outcome global'), (PLAYER_VARIANT_GLOBAL, 'player-variant global'),
           (m.NEXT_DAY_AV, 'next-day actor value'), (m.STAGE_REACHED_AV, 'stage-reached actor value'),
           (m.TIER_AV, 'tier actor value'), (m.SAID_YES_AV, 'said-yes actor value'),
           (m.INVITED_UNTIL_AV, 'invited-until actor value'), (m.JEALOUSY_MARK_AV, 'jealousy-mark actor value'),
           (m.JEALOUS_PENDING_AV, 'jealous-pending actor value'),
           (m.GREET_TOPIC, 'greeting topic'), (m.GREET_INFO, 'greeting line'),
           (COMPANIONS_QUEST, 'companions quest'), (COMPANION_DESIRE_AV, 'companion desire'),
           (COMPANION_MOMENT_AV, 'companion moment'), (COMPANION_LAST_TICK_AV, 'companion last tick'),
           (COMPANION_SEEN_SCENE_AV, 'companion seen scene'), (COMPANION_TIER_AV, 'companion affinity tier'),
           (COMPANION_FALL_AV, 'companion fall'), (COMPANION_PAIR_SEEN_AV, 'companion pair seen'),
           (COMPANION_ASK_PERK, 'companion ask perk')]
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
                block, vids = player_versions(p, 1, n, pid)
                prec = m.topic(tid, f'OvertureTopic{register.capitalize()}', infos=len(vids))
                prec += m.child_group(tid, 7, block)
            else:
                tid, pid, prec, vids = player_stage(prompts, 'stage2', ptopic, pinfo, n, register)
            ids += [(tid, f's{stage} player topic {register}')]
            ids += [(v, f's{stage} player line {register} version {k}') for k, v in enumerate(vids)]
            topics[stage][slot] = tid
            children += prec
            count += 2

            rtid = rtopic + n
            topics[stage][npc_slot] = rtid
            ids.append((rtid, f's{stage} reply topic {register}'))
            block, n_infos = b'', 0
            if register == m.INTIMATE_REGISTER:
                for k, persona in enumerate(m.PERSONAS):
                    lines = recoil[stage].get(persona, [])
                    if lines:
                        m.check_covers_everyone(lines, f's{stage} recoil {persona}')
                    liked = lands_on.get(persona) == register
                    code = m.OUTCOME_RECOIL_LIKED if liked else m.OUTCOME_RECOIL
                    # A gendered line never carries the fence.
                    ordered = m.fenced_order(m.variant_ids(lines, rbase + k * m.MAX_VARIANTS,
                                                           f's{stage} recoil {persona}'),
                                             f's{stage} recoil {persona}')
                    for i, (rid, l) in enumerate(ordered):
                        ids.append((rid, f's{stage} recoil {persona} {l["id"]}'))
                        last = i == len(ordered) - 1
                        enam = m.ENAM_RANDOM | (m.ENAM_RANDOM_END if last else 0)
                        block += m.line(rid, None, l['text'], persona_index=k, public=1,
                                        enam=enam, reply=(stage, code), extra=m.sex_conditions(l))
                        n_infos += 1
            for k, persona in enumerate(m.PERSONAS):
                lines = reply[stage].get((register, persona))
                if not lines:
                    raise SystemExit(f'no stage-{stage} response for {register}/{persona}')
                m.check_covers_everyone(lines, f's{stage} {register}/{persona}')
                for iid, l in m.variant_ids(lines, base + (n * len(m.PERSONAS) + k) * m.MAX_VARIANTS,
                                            f's{stage} {register}/{persona}'):
                    ids.append((iid, f's{stage} {register}/{persona} {l["id"]}'))
                    if l['outcome'] == 'land':
                        code = m.OUTCOME_LAND
                    elif register == m.INTIMATE_REGISTER:
                        code = m.OUTCOME_OFFEND
                    else:
                        code = m.OUTCOME_MISS
                    block += m.line(iid, None, l['text'], persona_index=k,
                                    enam=m.ENAM_RANDOM, reply=(stage, code), extra=m.sex_conditions(l))
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
        tid, pid, prec, vids = player_stage(prompts, 'stage3', PLAYER_TOPIC_S3, PLAYER_INFO_S3, n, register)
        ids += [(tid, f's3 player topic {register}')]
        ids += [(v, f's3 player line {register} version {k}') for k, v in enumerate(vids)]
        topics[3][slot] = tid
        children += prec
        count += 2

        rtid = NPC_TOPIC_S3 + n
        topics[3][npc_slot] = rtid
        ids.append((rtid, f's3 reply topic {register}'))
        block, n_infos = b'', 0
        for k, persona in enumerate(m.PERSONAS):
            # The persona's answers, one set per verdict. "Not here" has lines of
            # its own now (DRAFT, voice/lines.json): the stage-2 recoils it used to
            # borrow answer a crude line the player may not have said, and two of
            # them say no (review 2026-09-23).
            verdicts = ((VERDICT_NOT_HERE, OUTCOME_NOT_HERE, propose.get((persona, 'nothere'), [])),
                        (VERDICT_REFUSE, OUTCOME_REFUSE, propose.get((persona, 'refuse'), [])),
                        (VERDICT_NOTYET, OUTCOME_NOTYET, propose.get((persona, 'notyet'), [])),
                        (VERDICT_ACCEPT, OUTCOME_ACCEPT, propose.get((persona, 'accept'), [])),
                        (VERDICT_NOT_NOW, OUTCOME_NOT_NOW, propose.get((persona, 'notnow'), [])),
                        # R-27. The sixth set: slots 12-13 of the cell (7 sets with the
                        # lover branch's refusal, 14 of S3_CELL's 16), gendered 0xF00 + 13 max.
                        (VERDICT_NOT_TYPE, OUTCOME_NOT_TYPE, propose.get((persona, 'nottype'), [])))
            if lands_on.get(persona) == register:
                # The register that got here: the verdict decides.
                sets = tuple((v, c, t, b'') for v, c, t in verdicts)
            else:
                # Propositioned in another register: refused, whatever the bond --
                # unless they are the player's lover. O-31 (owner, 2026-09-23: "any
                # register answers"): someone who said yes, or the lover tier, has
                # nothing left to guess, so every register reaches the verdict, in
                # their own voice. The refusal carries NOT-a-lover and the verdict
                # sets carry the lover markers, so exactly one group can ever pass:
                # a Random run pools every line that passes, and two groups at once
                # would be a coin flip (make_overture_esp's recoil fence). The
                # refusal keeps set 0, so its ids -- which name voice files -- stay.
                sets = (((None, OUTCOME_REFUSE, propose.get((persona, 'refuse'), []), not_a_lover()),)
                        + tuple((v, c, t, a_lover()) for v, c, t in verdicts))
            for s_index, (verdict, code, lines, gate) in enumerate(sets):
                if s_index * 2 + 1 >= S3_CELL:
                    raise SystemExit(f'{persona}: verdict set {s_index} does not fit a stage-3 cell of {S3_CELL}')
                if not lines:
                    raise SystemExit(f'no stage-3 lines for {persona} verdict {verdict}')
                plain = [l for l in lines if not m.gendered(l)]
                sexed = [l for l in lines if m.gendered(l)]
                if len(plain) > 2 or len(sexed) > 2:
                    # The id layout gives each verdict set two slots, and O-40c's range
                    # two more for gendered lines; a third would be dropped without a word.
                    raise SystemExit(f'{persona} verdict {verdict}: {len(plain)} plain and {len(sexed)} '
                                     f'gendered lines; stage 3 has room for 2 of each')
                m.check_covers_everyone(lines, f's3 {persona} verdict {verdict}')
                # No flag on ANY answer, the yes included. XDI works out an
                # option's "endsScene" from its NPC reply's End Running Scene
                # flag and hands it to the menu (xdi DialogueEx.cpp:301,
                # Scaleform.cpp:398) -- F4MCP printed the yes as "[ends scene]"
                # on the wheel, which names the right register AND the answer.
                # The yes ends the scene by HandBack's own start condition
                # instead: it does not start after a yes.
                enam = m.ENAM_RANDOM
                cell = n * len(m.PERSONAS) + k
                entries = ([(INFO_BASE_S3 + cell * S3_CELL + s_index * 2 + v, l, str(v))
                            for v, l in enumerate(plain)]
                           + [(GENDERED_S3_BASE + cell * 16 + s_index * 2 + g, l, f'sexed {g}')
                              for g, l in enumerate(sexed)])
                # Stage 3 has no fence (Random End) to protect: exactly one set can pass.
                for iid, l, label in entries:
                    ids.append((iid, f's3 {register}/{persona} set {s_index} {label}'))
                    extra = (m.sex_conditions(l)
                             + (verdict_condition(verdict) if verdict is not None else b'') + gate)
                    block += m.line(iid, None, l['text'], persona_index=k, enam=enam,
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
            else:
                # A lover's verdict never decided (0), in another register: the same
                # neutral beat, or no line would match at all.
                fid = FALLBACK_NO_VERDICT_LOVER + n * len(m.PERSONAS) + k
                ids.append((fid, f's3 lover no-verdict fallback {register}/{persona}'))
                block += m.line(fid, None, '...', persona_index=k, enam=0,
                                reply=(3, m.OUTCOME_MISS), extra=verdict_condition(0) + a_lover())
                n_infos += 1
        fid = FALLBACK_NO_PERSONA + 3 * 0x10 + n
        ids.append((fid, f's3 no-persona fallback {register}'))
        block += m.line(fid, None, '...', enam=0, reply=(3, m.OUTCOME_MISS),
                        extra=no_persona_condition())
        n_infos += 1
        children += m.topic(rtid, f'OvertureReply{register.capitalize()}S3', infos=n_infos)
        children += m.child_group(rtid, 7, block)
        count += 1 + n_infos

    companion_topics, companion_children = companion_wheel(companion_bank, ids)
    children += companion_children
    companion_infos, companion_count = companion_greetings(companion_bank['lines'], ids)
    m.check_unique(ids)

    lover_lines = [l for l in bank['lines'] if l.get('kind') == 'lover_greeting']
    if len(lover_lines) > 4:
        raise SystemExit('more lover greetings than 0x832..0x835 holds')
    jealous_lines = [(m.PERSONAS.index(l['persona']), l)
                     for l in bank['lines'] if l.get('kind') == 'jealous_greeting']
    # Only PLAIN lines live in 0x836..0x83F. Gendered ones have their own range
    # (JEALOUS_GENDERED_BASE), capped per persona by greeting() -- counting them here
    # refused a bank that fit (tools/check_gendered.py caught it).
    if sum(1 for _p, l in jealous_lines if not m.gendered(l)) > 10:
        raise SystemExit('more plain jealous greetings than 0x836..0x83F holds')
    children += m.greeting(lover_lines, jealous_lines, companion_infos, companion_count)
    children += scene_staged(topics, companion_topics)
    quest_blob = m.quest(scripts=(m.SCRIPT_NAME, m.DEV_SCRIPT)) + m.child_group(m.QUEST_FORMID, 10, children)
    globs = (m.persona_global() + m.public_global() + m.enabled_global() + m.opening_global()
             + glob(VERDICT_GLOBAL, 'OvertureVerdict', 0.0)
             + glob(PLAYER_VARIANT_GLOBAL, 'OverturePlayerVariant', 0.0)
             + glob(LAST_OUTCOME_GLOBAL, 'OvertureLastOutcome', 0.0))
    blob = m.group('GLOB', globs) + m.group('QUST', quest_blob + companions_quest())
    blob += m.group('PERK', ask_perk())
    blob += m.group('AVIF', m.next_day_av() + m.stage_reached_av()
                    + m.actor_value(m.TIER_AV, 'OvertureTier')
                    + m.actor_value(m.SAID_YES_AV, 'OvertureSaidYes')
                    + m.actor_value(m.INVITED_UNTIL_AV, 'OvertureInvitedUntil')
                    + m.actor_value(m.JEALOUSY_MARK_AV, 'OvertureJealousyMark')
                    + m.actor_value(m.JEALOUS_PENDING_AV, 'OvertureJealousPending')
                    + m.actor_value(COMPANION_DESIRE_AV, 'OvertureCompanionDesire')
                    + m.actor_value(COMPANION_MOMENT_AV, 'OvertureCompanionMoment')
                    + m.actor_value(COMPANION_LAST_TICK_AV, 'OvertureCompanionLastTick')
                    + m.actor_value(COMPANION_FALL_AV, 'OvertureCompanionFall')
                    + m.actor_value(COMPANION_PAIR_SEEN_AV, 'OvertureCompanionPairSeen')
                    + m.actor_value(COMPANION_SEEN_SCENE_AV, 'OvertureCompanionSeenScene')
                    + m.actor_value(COMPANION_TIER_AV, 'OvertureCompanionAffinityTier'))

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


def alias_value(av, value, op, value_global=None):
    """One of our actor values on whoever is in the alias (run on Quest Alias 0),
    against a number -- or against a GLOB, with value_global."""
    return m.field('CTDA', m.condition(m.FUNC_GET_VALUE, av, value=value, op=op,
                                       runon=RUNON_QUEST_ALIAS, alias=m.ALIAS_INDEX,
                                       value_global=value_global))


def at_proposition():
    """They said yes before (O-12), OR the lover tier (O-14), OR an invitation
    that lasts until tonight (O-30): the conversation opens at the proposition.
    ONE OR group -- the flag on each but the last -- so a condition carrying the
    OR flag just before it joins the group. Approach.OpensAtProposition is the
    same test in Papyrus and must stay so."""
    return (alias_value(m.SAID_YES_AV, 1.0, m.CTDA_OP_EQ | m.CTDA_OR)
            + alias_value(m.TIER_AV, float(m.TIER_LOVER), m.CTDA_OP_EQ | m.CTDA_OR)
            + alias_value(m.INVITED_UNTIL_AV, 0.0, m.CTDA_OP_GT, value_global=m.GLOB_GAME_DAYS_PASSED))


def companion_here(value=1.0):
    """Whoever is in the alias IS the player's current companion (1.0), or is not
    (0.0). Only the companion greeting can put a current companion there: every
    stranger's line requires someone who has never been one."""
    return m.field('CTDA', m.condition(m.FUNC_GET_IN_FACTION, m.FACTION_CURRENT_COMPANION, value=value,
                                       runon=RUNON_QUEST_ALIAS, alias=m.ALIAS_INDEX))


def companion_greetings(lines, ids):
    """The companion's way in (methodology 11, C; O-23). Two runs, fenced:

      a MOMENT (OvertureCompanionMoment == 2): Overture:Companions:Moments opened
      one -- their wanting crossed its bar, or their own system's arousal rose --
      and the companion speaks first;
      the PLAYER'S START (the moment AV == 3): the player chose "Ask for a moment" on
      the companion's prompt (O-23, O-35).

    The AV's 1 is an adapter vouching for this companion (C6): 0 keeps a mod
    companion with voiced content of their own -- Ivy included -- invisible."""
    moment = [l['text'] for l in lines if l['kind'] == 'companion_moment']
    start = [l['text'] for l in lines if l['kind'] == 'companion_start']
    if not moment or not start or len(moment) + len(start) > 4:
        raise SystemExit('companion greetings: one to four in all, and at least one of each kind')
    theirs_first = m.field('CTDA', m.condition(m.FUNC_GET_VALUE, CA_WANTS_TO_TALK_AV, value=0.0,
                                               runon=m.RUNON_SUBJECT))
    open_now = theirs_first + m.field('CTDA', m.condition(m.FUNC_GET_VALUE, COMPANION_MOMENT_AV,
                                                          value=float(MOMENT_OPEN), runon=m.RUNON_SUBJECT))
    # O-35: the player asked through the perk's choice, which marks them ASKED and
    # activates them. (The first build's sneaking test is gone: vanilla never greets on
    # a sneaking E, and stealth players would have met it every day.)
    player_starts = theirs_first + m.field('CTDA', m.condition(m.FUNC_GET_VALUE, COMPANION_MOMENT_AV,
                                                               value=float(MOMENT_ASKED),
                                                               runon=m.RUNON_SUBJECT))
    infos, fid = b'', COMPANION_GREET_BASE
    for kind, group, gate in (('moment', moment, open_now), ('start', start, player_starts)):
        for i, text in enumerate(group):
            last = i == len(group) - 1
            enam = m.ENAM_REQUIRES_PLAYER_ACTIVATION | m.ENAM_RANDOM | (m.ENAM_RANDOM_END if last else 0)
            infos += m.greeting_info(fid, text, enam, gate, companion=True)
            ids.append((fid, f'companion greeting {kind} {i}'))
            fid += 1
    return infos, len(moment) + len(start)


def companion_wheel(bank, ids):
    """The companion phase's four options and the companion's answers.

    The answers are a set per persona and per verdict, one behind EVERY
    proposition: which register the player picked decides nothing (O-22 and
    B-lite: their own state and their wanting do). "Later." has its own answer,
    persona-neutral, and costs nothing."""
    wheel = bank['wheel']
    answers = {}
    for l in bank['lines']:
        if l['kind'] == 'companion_answer':
            answers.setdefault((l['persona'], l['outcome']), []).append(l)
        elif m.gendered(l):
            # Only the answers have a gendered layout (COMPANION_GENDERED_BASE); a
            # greeting or a "Later." line has no room for one and nothing needs it yet.
            raise SystemExit(f'{l["id"]}: a {l["kind"]} line cannot be gendered (only companion answers can)')
    later = [l['text'] for l in bank['lines'] if l['kind'] == 'companion_later']
    if not later:
        raise SystemExit('no companion_later lines')
    propositions = [key for _slot, key in COMPANION_WHEEL if key != 'later']
    sets = ((VERDICT_NOT_HERE, OUTCOME_NOT_HERE, 'nothere'), (VERDICT_REFUSE, OUTCOME_REFUSE, 'refuse'),
            (VERDICT_NOTYET, OUTCOME_NOTYET, 'notyet'), (VERDICT_ACCEPT, OUTCOME_ACCEPT, 'accept'),
            (VERDICT_NOT_NOW, OUTCOME_NOT_NOW, 'notnow'))
    topics, children = {}, b''
    for n, (slot, key) in enumerate(COMPANION_WHEEL):
        opt = wheel[key]
        tid, pid = COMPANION_PLAYER_TOPIC + n, COMPANION_PLAYER_INFO + n
        topics[slot] = tid
        ids += [(tid, f'companion player topic {key}'), (pid, f'companion player line {key}')]
        children += m.topic(tid, f'OvertureCompanion{key.capitalize()}', infos=1)
        children += m.child_group(tid, 7, m.line(pid, opt['prompt'], opt['spoken'], enam=0))

        rtid = COMPANION_NPC_TOPIC + n
        topics[m.NPC_SLOT[slot]] = rtid
        ids.append((rtid, f'companion reply topic {key}'))
        base = COMPANION_ANSWER_BASE + n * COMPANION_SLOT_STRIDE
        block, n_infos = b'', 0
        if key == 'later':
            for v, text in enumerate(later):
                iid = base + v
                ids.append((iid, f'companion later {v}'))
                last = v == len(later) - 1
                block += m.line(iid, None, text, enam=m.ENAM_RANDOM | (m.ENAM_RANDOM_END if last else 0),
                                reply=(0, OUTCOME_LATER))
                n_infos += 1
        else:
            prop = propositions.index(key)
            for k, persona in enumerate(m.PERSONAS):
                for s_index, (verdict, code, outcome) in enumerate(sets):
                    lines = answers.get((persona, outcome), [])
                    plain = [l for l in lines if not m.gendered(l)]
                    sexed = [l for l in lines if m.gendered(l)]
                    if not lines or len(plain) > 2 or len(sexed) > 2:
                        raise SystemExit(f'companion {persona} {outcome}: {len(plain)} plain and '
                                         f'{len(sexed)} gendered lines; need 1 to 2 of each kind')
                    m.check_covers_everyone(lines, f'companion {persona} {outcome}')
                    entries = ([(base + k * 10 + s_index * 2 + v, l, str(v)) for v, l in enumerate(plain)]
                               + [(COMPANION_GENDERED_BASE + ((prop * len(m.PERSONAS) + k) * len(sets)
                                                              + s_index) * 2 + g, l, f'sexed {g}')
                                  for g, l in enumerate(sexed)])
                    for iid, l, label in entries:
                        ids.append((iid, f'companion {key}/{persona} {outcome} {label}'))
                        # No flag on any answer, the yes included: the stranger
                        # stage 3's reason (XDI would mark the yes on the wheel).
                        block += m.line(iid, None, l['text'], persona_index=k, enam=m.ENAM_RANDOM,
                                        reply=(3, code), extra=m.sex_conditions(l) + verdict_condition(verdict))
                        n_infos += 1
            # No persona from Rapport, then no verdict decided: neutral beats that
            # end like a miss, not Random, last -- reached only when all above fail.
            fid = base + COMPANION_FALLBACK
            ids += [(fid, f'companion {key} no-persona fallback'), (fid + 1, f'companion {key} no-verdict fallback')]
            block += m.line(fid, None, '...', enam=0, reply=(3, m.OUTCOME_MISS), extra=no_persona_condition())
            block += m.line(fid + 1, None, '...', enam=0, reply=(3, m.OUTCOME_MISS), extra=verdict_condition(0))
            n_infos += 2
        children += m.topic(rtid, f'OvertureCompanionReply{key.capitalize()}', infos=n_infos)
        children += m.child_group(rtid, 7, block)
    return topics, children


def perk_vmad(fragment_script, fragments):
    """A PERK's VMAD: no scripts of its own, then the perk-fragment block -- MEASURED on
    CC_PetDogs_PetPerk 0024A158, MisterSandman01 0004B258 and RoboticsExpert01 0004D889:
    a version byte (3), the fragment script as a script entry (name, status 0, its
    properties -- none here), the fragment count, and per fragment its entry index, an
    int16 0, an int8 0, a byte 1, the script name again and the function's name."""
    f = struct.pack('<hhH', 6, 2, 0)
    f += bytes([3]) + m.wstring(fragment_script) + bytes([0]) + struct.pack('<H', 0)
    f += struct.pack('<H', len(fragments))
    for entry, function in fragments:
        f += struct.pack('<Hhb', entry, 0, 0) + bytes([1]) + m.wstring(fragment_script) + m.wstring(function)
    return f


def ask_perk():
    """O-35 (owner, 2026-09-23): "Ask for a moment" on the companion's activation prompt.

    Transcribed from CC_PetDogs_PetPerk (0024A158), vanilla's plainest Activate choice
    on an actor:
      DATA  00 00 01 00 01   not a trait, level 0, one rank, not playable, hidden
      PRKE  02 00 00          an entry point, rank 0, priority 0
      DATA  0E 09 02          entry point Activate (0x0E), Add Activate Choice (0x09),
                              two condition tabs
      PRKC  01                tab 1: the TARGET, the actor the prompt is on
      EPFT  04                a button label and a script fragment
      EPFB  00 00             fragment 0
      EPF2                    the label -- literal text, this plugin is not localized
      EPF3  00 00             no flags: an EXTRA choice beside their own Talk, never a
                              replacement (a replacement would take their menu, C1's
                              spirit)
    Shown only when a conversation could really open: their Moment value vouched (1-3),
    the day's stamp open, their own conversation not waiting, not in combat. Touches no
    record of theirs (C1). Moments.Hook gives the perk to the player."""
    target = b''
    for func, param, value, op, glob in (
            (m.FUNC_GET_IN_FACTION, m.FACTION_CURRENT_COMPANION, 1.0, m.CTDA_OP_EQ, None),
            (m.FUNC_GET_VALUE, COMPANION_MOMENT_AV, float(MOMENT_VOUCHED), m.CTDA_OP_GE, None),
            (m.FUNC_GET_VALUE, m.NEXT_DAY_AV, 0.0, m.CTDA_OP_LE, m.GLOB_GAME_DAYS_PASSED),
            (m.FUNC_GET_VALUE, CA_WANTS_TO_TALK_AV, 0.0, m.CTDA_OP_EQ, None),
            (m.FUNC_IS_IN_COMBAT, 0, 0.0, m.CTDA_OP_EQ, None),
            (m.FUNC_GET_GLOBAL_VALUE, m.ENABLED_GLOBAL, 1.0, m.CTDA_OP_EQ, None)):
        target += m.field('CTDA', m.condition(func, param, value=value, op=op, runon=m.RUNON_SUBJECT,
                                              value_global=glob))
    f = m.field('EDID', m.zstring(COMPANION_ASK_PERK_EDID))
    f += m.field('VMAD', perk_vmad(COMPANION_ASK_FRAGMENT, [(0, 'Fragment_Entry_00')]))
    f += m.field('DESC', m.zstring(''))
    f += m.field('DATA', bytes([0x00, 0x00, 0x01, 0x00, 0x01]))
    f += m.field('PRKE', bytes([0x02, 0x00, 0x00]))
    f += m.field('DATA', bytes([0x0E, 0x09, 0x02]))
    f += m.field('PRKC', bytes([0x01]))
    f += target
    f += m.field('EPFT', bytes([0x04]))
    f += m.field('EPFB', struct.pack('<H', 0))
    f += m.field('EPF2', m.zstring(COMPANION_ASK_LABEL))
    f += m.field('EPF3', struct.pack('<H', 0))
    f += m.field('PRKF', b'')
    return m.record('PERK', COMPANION_ASK_PERK, f)


def companions_quest():
    """The companion module's scripts, on a quest of their own: EDID, VMAD, DNAM,
    NEXT and nothing else -- RapportBridgeQuest's exact shape (Rapport.esp 01000800,
    which runs in game), start-game-enabled, no aliases, no dialogue. The dialogue
    is the approach quest's: one scene, a phase of its own."""
    f = m.field('EDID', m.zstring(COMPANIONS_QUEST_EDID))
    f += m.field('VMAD', m.vmad_scripts([(name, ()) for name in COMPANION_SCRIPTS]))
    f += m.field('DNAM', bytes.fromhex('110064670000000000000000'))
    f += m.field('NEXT', b'')
    return m.record('QUST', COMPANIONS_QUEST, f)


def not_at_proposition():
    """Its negation, three conditions ANDed (De Morgan): no yes before, not the
    lover tier, and no invitation still running."""
    return (alias_value(m.SAID_YES_AV, 1.0, m.CTDA_OP_NE)
            + alias_value(m.TIER_AV, float(m.TIER_LOVER), m.CTDA_OP_NE)
            + alias_value(m.INVITED_UNTIL_AV, 0.0, m.CTDA_OP_LE, value_global=m.GLOB_GAME_DAYS_PASSED))


def scene_staged(topics, companion_topics):
    """Six phases: 0 empty (the alias settles), 1 stage 1 (first meetings only),
    2 stage 2 (after a land, or for a returning NPC), 3 stage 3 (for a verdict of
    "not yet" or better, or a conversation that opens at the proposition), 4 the
    COMPANION's wheel (methodology 11: the player's current companion, and only
    them -- phases 1 to 3 refuse a companion), 5 HandBack -- the type-4 End Scene
    Say Greeting action the one-exchange scene ends with, reached by falling
    through after any line but a yes (nothing jumps to it).

    OnPhaseBegin numbers them from 1 (MEASURED in the 2026-09-23 Papyrus log: an
    approach logs "phase 1" and "phase 2" as it opens -- the empty phase and stage
    1 -- and never a "phase 0")."""
    f = m.field('EDID', m.zstring(m.SCENE_EDID))
    f += m.field('FNAM', struct.pack('<I', 0x00000024))
    # Stage 1: nothing reached yet, AND not a conversation that opens at the
    # proposition.
    first_meeting = alias_value(m.STAGE_REACHED_AV, 0.0, m.CTDA_OP_EQ) + not_at_proposition()
    # Stage 2: today's stage 1 landed, OR stage 1 was skipped because they reached
    # it on an earlier day -- AND not at the proposition. OR binds tighter than AND
    # in a condition list, so this reads (land OR reached >= 1) AND no yes AND not
    # the lover tier AND no invitation.
    stage_two = m.field('CTDA', m.condition(m.FUNC_GET_GLOBAL_VALUE, LAST_OUTCOME_GLOBAL,
                                            value=float(m.OUTCOME_LAND), op=m.CTDA_OR))
    stage_two += alias_value(m.STAGE_REACHED_AV, 1.0, m.CTDA_OP_GE)
    stage_two += not_at_proposition()
    # Stage 3: a verdict with a chance, OR a conversation that opens here. That one's
    # verdict is decided as the scene begins (Approach.Opening), seconds before the
    # player can pick; the gate reads only markers written before the conversation
    # began, so it cannot race -- and it opens even for a verdict that can only be
    # refused, which the Narrator then says is not the player's words.
    stage_three = m.field('CTDA', m.condition(m.FUNC_GET_GLOBAL_VALUE, VERDICT_GLOBAL,
                                              value=float(VERDICT_NOTYET), op=m.CTDA_OP_GE | m.CTDA_OR))
    stage_three += at_proposition()
    # HandBack: after anything but a yes. After a yes the scene simply ends -- the
    # dialogue closes so Rapport's scene can start, with no re-greet on top.
    not_after_yes = m.field('CTDA', m.condition(m.FUNC_GET_GLOBAL_VALUE, LAST_OUTCOME_GLOBAL,
                                                value=float(OUTCOME_ACCEPT), op=m.CTDA_OP_NE))
    # A companion never takes phases 1-3 -- a companion's conversation is not a
    # stranger's -- and phase 4 is theirs alone.
    not_companion = companion_here(0.0)
    f += (phase() + phase(first_meeting + not_companion) + phase(stage_two + not_companion)
          + phase(stage_three + not_companion) + phase(companion_here(), name='Companion')
          + phase(not_after_yes, name=HAND_BACK))
    # The actor list: alias 0, as the one-exchange scene has it.
    f += m.field('ALID', struct.pack('<I', m.ALIAS_INDEX))
    f += m.field('LNAM', struct.pack('<I', 4))
    f += m.field('DNAM', struct.pack('<I', 10))
    f += dialogue_action(1, 1, topics[1])
    f += dialogue_action(2, 2, topics[2])
    f += dialogue_action(3, 3, topics[3])
    f += dialogue_action(4, 4, companion_topics)
    # HandBack: type 4 with HTID, "End Scene Say Greeting" -- the NPC re-greets and
    # their own dialogue takes over (O-8). The one-exchange scene's last action.
    f += m.field('ANAM', struct.pack('<H', 4))
    f += m.field('NAM0', b'\0')
    f += m.field('ALID', struct.pack('<I', m.ALIAS_INDEX))
    f += m.field('INAM', struct.pack('<I', 5))
    f += m.field('SNAM', struct.pack('<I', 5))
    f += m.field('ENAM', struct.pack('<I', 5))
    f += m.field('STSC', struct.pack('<I', 0))
    f += m.field('HTID', b'')
    f += m.field('ANAM', b'')
    f += m.field('PNAM', struct.pack('<I', m.QUEST_FORMID))
    f += m.field('INAM', struct.pack('<I', 5))            # the highest action index, as vanilla's tails read
    f += m.field('VNAM', m.VNAM_DONT_SET_ALL)
    f += m.field('NNAM', m.zstring('Overture: an approach in three stages.'))
    f += m.field('XNAM', struct.pack('<I', 0))
    return m.record('SCEN', m.SCENE_FORMID, f)
