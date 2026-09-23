"""Build Overture.esp: one dialogue quest, one scene, four player options.

THE THINNEST LOOP FIRST (fo4-rapport N-2). This makes four player options
appear on the wheel in the four slots and nothing else -- no persona
conditions, no NPC responses selected by persona, no stages. Prove the options
appear, then add the matrix. Building all sixteen conditioned lines before one
option has ever shown up would be building it twice.

EVERY BYTE SHAPE HERE IS TRANSCRIBED from FFGoodneighbor02 (QUST 0010B654) and
FFGoodneighbor02RewardScene (SCEN 0010BECF) -- the smallest quest in
Fallout4.esm that owns real player dialogue. `docs/player-topic-shape.md` has
the measurements and `tools/` has the readers that produced them. Nothing below
is guessed; where something is not yet understood it is copied verbatim and
said so.

THE FOUR FACTS THAT DECIDE THE SHAPE:

1. A player option is SCENE dialogue. 96% of the 12,513 INFO records carrying
   RNAM sit under topics whose SNAM is "SCEN". A free-standing topic attached
   to an NPC is a record the engine never looks at.
2. The wheel slot is which SCEN field points at the topic -- PTOP positive,
   NTOP neutral, NETO negative, QTOP question -- NOT the DIAL category. All
   eight of the template's topics are category 15 and they sit in different
   slots.
3. Scene topics carry NO Dialogue Branch. Only 1,290 of 35,443 DIAL records
   have a BNAM. This is the opposite of the bark case, where a missing DLBR
   left 211 topics silent, so do not "fix" a topic here by adding one.
4. NAM1 and RNAM hold LITERAL TEXT here. They are string-table ids in
   Fallout4.esm because it sets TES4 flag 0x80 and is localized; this plugin
   does not, so copying the base game's four bytes would put garbage in every
   subtitle.

    python tools/make_overture_esp.py build/Overture.esp
"""
import json
import pathlib
import struct
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent

AUTHOR = 'ReidenXerx'
MASTER = 'Fallout4.esm'

# Index 01: Fallout4.esm is master 00, so every record this plugin owns is 01xxxxxx.
QUEST_FORMID = 0x01000800
SCENE_FORMID = 0x01000801
TOPIC_BASE = 0x01000810   # one DIAL per register
# Its own range, well clear of everything else. The variants made each topic's
# ids run 0x820..0x899, straight through GREET_TOPIC 0x830, GREET_INFO 0x831 and
# PERSONA_GLOBAL 0x840 -- duplicate form ids inside one plugin, which the engine
# answered by crashing in InitGameDataThread while loading the file. Twice.
INFO_BASE = 0x01001000
GREET_TOPIC = 0x01000830  # the GREE topic that starts the scene
GREET_INFO = 0x01000831
PERSONA_GLOBAL = 0x01000840   # GLOB the script sets before the scene starts

# The order IS the global's value. Overture:Approach maps Rapport's persona name
# onto these indices, so the two lists must not drift apart.
PERSONAS = ['mercantile', 'romantic', 'vulgar', 'reticent']

# Form ids are spaced this far apart per cell so variants never collide.
MAX_VARIANTS = 8

QUEST_EDID = 'OvertureDialogueQuest'
SCRIPT_NAME = 'Overture:Approach'
SCENE_EDID = 'OvertureApproachScene'

# The alias the quest points at whoever the player is talking to. Index 0 is
# ours to choose; the SCEN names it by INDEX, not by form id.
ALIAS_INDEX = 0
ALIAS_NAME = 'Target'

# O-4, tone-faithful. The slot is the SCEN field, so this mapping IS the design.
#
# NTOP IS NEGATIVE AND NETO IS NEUTRAL, not the other way round. The names read
# like "Neutral TOPic" and "NEgative TOpic" and that reading is wrong. MEASURED
# 2026-09-23 through XDI: our four topics came back with optionIDs
# charm 0, offer 1, blunt 2, linger 3, against the vanilla slot numbering
# Positive 0, Negative 1, Neutral 2, Question 3. The first build had offer in
# the negative slot and blunt in the neutral one -- the exact opposite of O-4 --
# and nothing in the record would ever have shown it.
SLOTS = [
    ('PTOP', 'charm'),    # positive
    ('NETO', 'offer'),    # NEutral
    ('NTOP', 'blunt'),    # Negative
    ('QTOP', 'linger'),   # question
]


# --------------------------------------------------------------------------
# primitives, the same shapes fo4-rapport's make_dialogue.py writes
# --------------------------------------------------------------------------

def field(sig, data):
    if len(data) > 0xFFFF:
        raise ValueError(f'{sig} too large for a plain field')
    return sig.encode('ascii') + struct.pack('<H', len(data)) + data


def zstring(text):
    # ASCII only: a smart quote or an em dash fails HERE rather than becoming
    # mojibake in a subtitle somebody reads six months later.
    return text.encode('ascii') + b'\0'


def record(sig, form_id, fields_blob, flags=0):
    return (sig.encode('ascii')
            + struct.pack('<III', len(fields_blob), flags, form_id)
            + struct.pack('<IHH', 0, 131, 0)
            + fields_blob)


def group(label, records_blob):
    """A top-level GRUP, labelled by record type."""
    return (b'GRUP' + struct.pack('<I', 24 + len(records_blob))
            + label.encode('ascii') + struct.pack('<i', 0)
            + struct.pack('<IHH', 0, 0, 0) + records_blob)


def child_group(form_id, group_type, blob):
    """A GRUP labelled by form id: type 10 (quest children), type 7 (topic)."""
    return (b'GRUP' + struct.pack('<I', 24 + len(blob))
            + struct.pack('<I', form_id) + struct.pack('<i', group_type)
            + struct.pack('<IHH', 0, 0, 0) + blob)


# --------------------------------------------------------------------------
# the records
# --------------------------------------------------------------------------

def quest():
    """The dialogue quest, with ONE script-filled reference alias.

    DNAM is copied from the known-good shape fo4-rapport uses: start game
    enabled, so the scene is available without anything having to start it.

    The alias is the measured minimum. Fallout4.esm holds 1,069 reference
    aliases carrying none of the fourteen fill-type fields, and every one has
    exactly this shape: ALST, ALID, FNAM, VTCK, ALED. FNAM is the flags field
    (ALFL appears only on LOCATION aliases) and bit 0x02 is set on effectively
    all of them, with the plain 0x00000002 the most common at 279.
    """
    dnam = bytes.fromhex('110064670000000000000000')
    # version 6, object format 2, one script, no properties. The script resolves
    # everything else by file-relative id at runtime, so there is nothing to bind.
    vmad = struct.pack('<hhH', 6, 2, 1)
    vmad += struct.pack('<H', len(SCRIPT_NAME)) + SCRIPT_NAME.encode('ascii')
    vmad += struct.pack('<B', 0)      # status: local
    vmad += struct.pack('<H', 0)      # no properties
    f = field('EDID', zstring(QUEST_EDID))
    f += field('VMAD', vmad)
    f += field('DNAM', dnam)
    f += field('NEXT', b'')
    # aliases
    f += field('ANAM', struct.pack('<I', ALIAS_INDEX + 1))   # next free index
    f += field('ALST', struct.pack('<I', ALIAS_INDEX))
    f += field('ALID', zstring(ALIAS_NAME))
    f += field('FNAM', struct.pack('<I', 0x00000002))
    f += field('VTCK', struct.pack('<I', 0))
    f += field('ALED', b'')
    return record('QUST', QUEST_FORMID, f)


def persona_global():
    """The global the script sets before starting the scene.

    Shape copied from GameHour (GLOB 00000038), which is what the base game's
    own GetGlobalValue conditions read: EDID, FNAM 'f' for float, FLTV. Some
    GLOBs omit FNAM entirely; GameHour does not, and it is the one actually
    exercised by this condition function.
    """
    f = field('EDID', zstring('OverturePersona'))
    f += field('FNAM', b'f')
    f += field('FLTV', struct.pack('<f', -1.0))   # -1: no persona chosen yet
    return record('GLOB', PERSONA_GLOBAL, f)


def topic(topic_id, edid, infos=1):
    """One DIAL. Transcribed from DIAL 0010BEB4.

    DATA is four bytes 00 02 0F 00: [1]=2 subtype, [2]=15 category. Category 15
    is what every scene player-dialogue topic in the template carries. No BNAM
    (fact 3). No EDID in the original either, but one is kept here because a
    nameless record is miserable to debug and the game ignores it.
    """
    f = field('EDID', zstring(edid))
    f += field('PNAM', struct.pack('<f', 50.0))
    f += field('QNAM', struct.pack('<I', QUEST_FORMID))
    # DATA[1] = 2, which is what 31,330 of the base game's 31,958 SCEN topics
    # carry. [2] = 15 is the category.
    #
    # VARIANTS DO NOT ROTATE and this is not the reason. Each topic holds two
    # lines per persona with identical conditions, and the engine returns the
    # same one every read. Tried and FAILED: setting bit 0x04 (DATA[1] = 6), on
    # the observation that every topic type which really does pick among many
    # lines -- HELO, GREE, NOTC, REFU -- carries it. Four reads, same line.
    #
    # Untested lead for whoever picks this up: the INFO's own ENAM. Ours is 0
    # and the greeting's is 4, so ENAM is an info-level flag field and "pick
    # among these" may live there rather than on the topic.
    f += field('DATA', bytes([0x00, 0x02, 0x0F, 0x00]))
    f += field('SNAM', b'SCEN')
    f += field('TIFC', struct.pack('<I', infos))
    return record('DIAL', topic_id, f)


def line(info_id, player_prompt, npc_response, persona_index=None):
    """One INFO. Transcribed from INFO 0010BEC4.

    RNAM is the PLAYER's menu text and NAM1 the NPC's spoken reply, both
    literal (fact 4).

    TRDA's first four bytes are the emotion id; ffffffff is none. Its second
    field is the RESPONSE NUMBER, which is the "_1" in the audio file name
    <INFO & 0xFFFFFF>_1.fuz, so it must be 1.

    NAM9 is omitted on purpose. In the template it is 900df0239989cf01 -- an
    8-byte Windows FILETIME, an editor timestamp rather than data, which is why
    fo4-rapport's barks work without it.
    """
    trda = bytes.fromhex('ffffffff' '01000000' '00010000' 'ffffffff' 'ffffffff')
    f = field('ENAM', struct.pack('<I', 0))
    f += field('TRDA', trda)
    f += field('NAM1', zstring(npc_response))
    f += field('NAM2', b'\0')
    f += field('NAM3', b'\0')
    f += field('NAM4', b'\0')
    if persona_index is not None:
        # Only when the global says this NPC is that persona. Four INFOs per
        # topic, one per persona, and the engine takes the first that passes.
        f += field('CTDA', condition(FUNC_GET_GLOBAL_VALUE, PERSONA_GLOBAL,
                                     value=float(persona_index), runon=0))
    f += field('RNAM', zstring(player_prompt))
    f += field('NAM0', b'\0')
    f += field('INAM', struct.pack('<I', 1))
    return record('INFO', info_id, f)


def condition(func, param1, value=1.0, runon=0, op=0x00):
    """One CTDA, 32 bytes.

    Layout, derived from four real conditions on FFGoodneighbor02's greeting and
    checked against every CTDA on every dialogue INFO in Fallout4.esm:

        0       operator and flags (0x00 = equal to)
        1-3     unused
        4-7     comparison value, float
        8-9     function index, uint16
        10-11   padding
        12-15   parameter 1
        16-19   parameter 2
        20-23   run-on type (0 = Subject, the speaker)
        24-27   reference
        28-31   unused

    The real records carry non-zero bytes in the two padding runs -- `7a d2 96`
    and `d2 96` -- identical across unrelated conditions, which is what
    uninitialised memory written straight to disk looks like. Zeros here.
    """
    return (struct.pack('<B', op) + b'\0' * 3
            + struct.pack('<f', value)
            + struct.pack('<H', func) + b'\0' * 2
            + struct.pack('<I', param1)
            + struct.pack('<I', 0)
            + struct.pack('<I', runon)
            + struct.pack('<I', 0)
            + struct.pack('<I', 0))


# GetIsAliasRef. MEASURED: of this function's 4,806 uses on dialogue INFOs in
# Fallout4.esm, 4,782 have a param1 inside the owning quest's own alias range,
# and the 24 that do not are all the sentinel 0xFFFFFFFE. See
# tools/ctda_alias_check.py, which is the check rather than the claim.
FUNC_GET_IS_ALIAS_REF = 566
RUNON_SUBJECT = 0

# GetGlobalValue. MEASURED: of its 7,258 uses on dialogue INFOs in
# Fallout4.esm, 100% have a param1 resolving to a GLOB record, run-on is always
# 0, and op 0x00 with a value means "equals". tools/ctda_param_types.py is the
# check.
FUNC_GET_GLOBAL_VALUE = 74


def greeting():
    """The GREE topic, and the line that starts the scene.

    THIS IS THE PIECE THAT MAKES IT WORK. Measured on FFGoodneighbor02: its
    greeting INFO carries `TSCE` holding the SCEN's form id, and that is what
    starts the scene when the player talks to the actor. A filled alias alone
    publishes nothing -- the first in-game run proved that, with the quest
    running, the alias filled and the scene playing, and not one option on the
    wheel.

    DATA is 00 07 73 00: [1]=7, [2]=0x73=115. Category 115 is what the
    template's greeting carries, against 15 for the player topics.

    ONE CONDITION: the speaker must be our Target alias (function 566,
    GetIsAliasRef, run on Subject). The first build had none, and was therefore
    offered by every actor in the game while the quest ran.
    """
    f = field('EDID', zstring('OvertureGreeting'))
    f += field('PNAM', struct.pack('<f', 50.0))
    f += field('QNAM', struct.pack('<I', QUEST_FORMID))
    f += field('DATA', bytes([0x00, 0x07, 0x73, 0x00]))
    f += field('SNAM', b'GREE')
    f += field('TIFC', struct.pack('<I', 1))
    topic = record('DIAL', GREET_TOPIC, f)

    trda = bytes.fromhex('ffffffff' '01000000' '00010000' 'ffffffff' 'ffffffff')
    g = field('ENAM', struct.pack('<I', 4))      # 4 on the template's greeting
    g += field('TRDA', trda)
    g += field('NAM1', zstring('...'))           # the NPC's greeting line
    g += field('NAM2', b'\0')
    g += field('NAM3', b'\0')
    g += field('NAM4', b'\0')
    # Only when the speaker IS our Target alias. Without this the greeting is
    # offered by every actor while the quest runs, which is what the first
    # build did and what O-7 cannot be built on top of.
    g += field('CTDA', condition(FUNC_GET_IS_ALIAS_REF, ALIAS_INDEX,
                                 value=1.0, runon=RUNON_SUBJECT))
    g += field('TSCE', struct.pack('<I', SCENE_FORMID))   # <- starts the scene
    g += field('NAM0', b'\0')
    g += field('INAM', struct.pack('<I', 1))
    line_rec = record('INFO', GREET_INFO, g)
    return topic + child_group(GREET_TOPIC, 7, line_rec)


def scene(topic_ids):
    """The SCEN. Transcribed field for field from SCEN 0010BECF.

    `topic_ids` is {slot: form id} for PTOP/NTOP/NETO/QTOP.

    The second set of four slots -- NPOT/NNGT/NNUT/NQUT -- is where each option
    LEADS. With one phase there is nowhere to lead, so they are written as 0.
    That is the one deliberate difference from the template, which points them
    at four further topics.

    Several fields are copied verbatim because their meaning is not established:
    LNAM, DNAM, the action FNAM, VNAM and XNAM. They are marked below. Copying
    an unexplained constant from a working record is honest; inventing one is
    not.
    """
    f = field('EDID', zstring(SCENE_EDID))
    f += field('FNAM', struct.pack('<I', 0x00000024))   # verbatim: scene flags

    # --- TWO phases, as the template has ------------------------------------
    # One phase was not enough: the scene started and ended inside a second,
    # visible in game as the actor dropping his idle and picking it straight
    # back up. A phase block runs HNAM .. HNAM.
    #
    # The template's SECOND phase carries a CTDA. Ours does not: that condition
    # names the template's own quest and actor form ids, and copying foreign ids
    # into this plugin would be worse than having no condition at all.
    for _phase in (0, 1):
        f += field('HNAM', b'')
        f += field('NAM0', b'\0')
        f += field('NEXT', b'')
        f += field('NEXT', b'')
        f += field('WNAM', struct.pack('<I', 500))      # verbatim
        f += field('HNAM', b'')

    # --- the dialogue action -------------------------------------------------
    f += field('ALID', struct.pack('<I', ALIAS_INDEX))
    f += field('LNAM', struct.pack('<I', 4))            # verbatim
    f += field('DNAM', struct.pack('<I', 10))           # verbatim
    f += field('ANAM', struct.pack('<H', 3))            # action type 3 = dialogue
    f += field('NAM0', b'\0')
    f += field('ALID', struct.pack('<I', ALIAS_INDEX))
    f += field('INAM', struct.pack('<I', 1))
    f += field('FNAM', struct.pack('<I', 0x00228000))   # verbatim: action flags
    f += field('SNAM', struct.pack('<I', 0))            # start phase
    f += field('ENAM', struct.pack('<I', 0))            # end phase
    for slot, _register in SLOTS:
        f += field(slot, struct.pack('<I', topic_ids[slot]))
    for slot in ('NPOT', 'NNGT', 'NNUT', 'NQUT'):
        f += field(slot, struct.pack('<I', 0))          # nowhere to lead yet
    f += field('DTGT', struct.pack('<I', ALIAS_INDEX))
    f += field('ANAM', b'')

    # --- the second action, type 4 -------------------------------------------
    # Verbatim in shape from the template, which runs it in phase 1 while the
    # dialogue action runs in phase 0. What type 4 does is not established, and
    # STSC/HTID with it; it is here because the difference between a scene that
    # holds and one that does not is the only thing still untested.
    f += field('ANAM', struct.pack('<H', 4))
    f += field('NAM0', b'\0')
    f += field('ALID', struct.pack('<I', ALIAS_INDEX))
    f += field('INAM', struct.pack('<I', 2))
    f += field('SNAM', struct.pack('<I', 1))            # start phase 1
    f += field('ENAM', struct.pack('<I', 1))            # end phase 1
    f += field('STSC', struct.pack('<I', 0))
    f += field('HTID', b'')
    f += field('ANAM', b'')

    # --- the tail ------------------------------------------------------------
    f += field('PNAM', struct.pack('<I', QUEST_FORMID))
    f += field('INAM', struct.pack('<I', 2))            # verbatim
    f += field('VNAM', struct.pack('<IIII', ALIAS_INDEX, ALIAS_INDEX,
                                  ALIAS_INDEX, ALIAS_INDEX))
    f += field('NNAM', zstring(
        'Overture: the player approaches someone and picks how.'))
    f += field('XNAM', struct.pack('<I', 0))            # verbatim
    return record('SCEN', SCENE_FORMID, f)


# --------------------------------------------------------------------------

def check_unique(ids):
    """Refuse to write a plugin that reuses a form id.

    This exists because the variants change silently produced duplicates and the
    engine's answer was an access violation in InitGameDataThread with no record
    named. A build error beats a crash log every time.
    """
    seen = {}
    for formid, what in ids:
        if formid in seen:
            raise SystemExit(
                f'DUPLICATE FORM ID {formid:08X}: "{what}" and "{seen[formid]}". '
                f'Every record in one plugin needs its own id.')
        seen[formid] = what
    return seen


def build():
    prompts = json.loads((ROOT / 'voice' / 'player-prompts.json')
                         .read_text(encoding='utf-8'))['prompts']
    by_register = {p['register']: p for p in prompts}
    missing = [r for _s, r in SLOTS if r not in by_register]
    if missing:
        raise SystemExit(f'no player prompt for: {missing}')

    # The reply for each (register, persona) cell: stage 1, kind "response".
    # Four lines exist per cell in the bank; the first is used and the other
    # three are variants for later.
    bank = json.loads((ROOT / 'voice' / 'lines.json').read_text(encoding='utf-8'))
    reply = {}
    for l in bank['lines']:
        if l['kind'] == 'response' and l['stage'] == 1:
            reply.setdefault((l['register'], l['persona']), []).append(l['text'])

    topic_ids, children, count = {}, b'', 0
    all_ids = [(QUEST_FORMID, 'quest'), (SCENE_FORMID, 'scene'),
               (PERSONA_GLOBAL, 'persona global'),
               (GREET_TOPIC, 'greeting topic'), (GREET_INFO, 'greeting line')]
    for n, (slot, register) in enumerate(SLOTS):
        tid = TOPIC_BASE + n
        topic_ids[slot] = tid
        all_ids.append((tid, f'topic {register}'))

        # EVERY variant, not just the first. Four lines exist per cell and the
        # engine picks among the INFOs whose conditions pass -- measured on the
        # base game, where one barter line came back as four different sentences
        # on four reads. Using one line per cell made an NPC who says the same
        # sentence every time you ever approach them.
        block, n_infos = b'', 0
        for k, persona in enumerate(PERSONAS):
            texts = reply.get((register, persona))
            if not texts:
                raise SystemExit(f'no stage-1 response for {register}/{persona}')
            if len(texts) > MAX_VARIANTS:
                raise SystemExit(f'{register}/{persona} has {len(texts)} variants, '
                                 f'more than the {MAX_VARIANTS} the id spacing allows')
            for v, text in enumerate(texts):
                iid = INFO_BASE + (n * len(PERSONAS) + k) * MAX_VARIANTS + v
                all_ids.append((iid, f'{register}/{persona} variant {v}'))
                block += line(iid, by_register[register]['text'], text,
                              persona_index=k)
                n_infos += 1

        # The lines are built before the topic, so TIFC is the REAL count. An
        # earlier version wrote the topic first with a placeholder and never went
        # back, leaving every topic claiming one line while holding sixteen.
        children += topic(tid, f'OvertureTopic{register.capitalize()}', infos=n_infos)
        children += child_group(tid, 7, block)
        count += 1 + n_infos

    # The greeting, then the scene -- and the SCEN goes INSIDE the quest's child
    # group, as a sibling of the topics. Measured: FFGoodneighbor02's
    # SCEN 0010BECF sits in its GRUP type 10, not at the top level. Ours was
    # top-level, which is one of the two reasons the first run showed nothing.
    # Before anything is written. A duplicate here is an access violation in
    # InitGameDataThread with no record named, which is a bad way to find out.
    check_unique(all_ids)

    children += greeting()
    children += scene(topic_ids)
    quest_blob = quest() + child_group(QUEST_FORMID, 10, children)
    blob = group('GLOB', persona_global()) + group('QUST', quest_blob)

    records = 1 + 1 + 1 + 2 + count  # glob, quest, scene, greeting pair, the rest
    next_object = max(SCENE_FORMID, TOPIC_BASE + len(SLOTS),
                      INFO_BASE + len(SLOTS) * len(PERSONAS),
                      GREET_INFO, PERSONA_GLOBAL) + 1
    hedr = struct.pack('<fiI', 1.0, records, next_object)
    head = field('HEDR', hedr)
    head += field('CNAM', zstring(AUTHOR))
    head += field('MAST', zstring(MASTER))
    head += field('DATA', struct.pack('<Q', 0))
    return record('TES4', 0, head) + blob, topic_ids


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    blob, topic_ids = build()
    out = pathlib.Path(sys.argv[1])
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(blob)
    print(f'wrote {out} ({len(blob)} bytes)')
    print(f'  quest {QUEST_EDID} {QUEST_FORMID:08X}, alias {ALIAS_NAME} index {ALIAS_INDEX}')
    print(f'  scene {SCENE_EDID} {SCENE_FORMID:08X}')
    for slot, register in SLOTS:
        print(f'  {slot}  {register:7} topic {topic_ids[slot]:08X}')
    print(f'  persona global {PERSONA_GLOBAL:08X}: ' +
          ', '.join(f'{k}={n}' for k, n in enumerate(PERSONAS)))
    print('  master', MASTER)
    return 0


if __name__ == '__main__':
    sys.exit(main())
