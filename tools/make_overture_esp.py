"""Build Overture.esp: one dialogue quest, one scene, four player options, and
the NPC's answer to each -- chosen by the NPC's persona, overridden by the room.

It began as the thinnest loop (fo4-rapport N-2): four options on the wheel and
nothing else, proved in game before the matrix went on top.

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
   NTOP NEGATIVE, NETO NEUTRAL, QTOP question -- NOT the DIAL category. All
   eight of the template's topics are category 15 and they sit in different
   slots. (The names read the other way round, and the first build believed
   them; XDI's optionIDs settled it in game: Negative 1 came from NTOP.)
3. Scene topics carry NO Dialogue Branch. Only 1,290 of 35,443 DIAL records
   have a BNAM. This is the opposite of the bark case, where a missing DLBR
   left 211 topics silent, so do not "fix" a topic here by adding one.
4. NAM1 and RNAM hold LITERAL TEXT here. They are string-table ids in
   Fallout4.esm because it sets TES4 flag 0x80 and is localized; this plugin
   does not, so copying the base game's four bytes would put garbage in every
   subtitle.
5. A player option's INFO is what the PLAYER says. The NPC answers from a
   SECOND topic per slot, named by the action's NPOT/NNGT/NNUT/NQUT. The
   template has four of each; the first builds had only the player's four and
   put the NPC's words in them.

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
RECOIL_BASE = 0x01002000   # its own range again; see check_unique
GREET_TOPIC = 0x01000830  # the GREE topic that starts the scene
GREET_INFO = 0x01000831
PERSONA_GLOBAL = 0x01000840   # GLOB the script sets before the scene starts
PUBLIC_GLOBAL = 0x01000841    # 1 when other people can see them, 0 when not
ENABLED_GLOBAL = 0x01000842   # the master switch: 1 = approaches open (a future MCM toggle)
NEXT_DAY_AV = 0x01000843      # AVIF: the game day an NPC may be approached again (O-8)
STAGE_REACHED_AV = 0x01000844  # AVIF: the furthest stage that LANDED with the player (methodology 8)

# The register O-4 calls intimate. Only this one recoils in public: a gift or a
# compliment in a crowded bar is merely a gift or a compliment.
INTIMATE_REGISTER = 'blunt'

# The order IS the global's value. Overture:Approach maps Rapport's persona name
# onto these indices, so the two lists must not drift apart.
PERSONAS = ['mercantile', 'romantic', 'vulgar', 'reticent']

# Form ids are spaced this far apart per cell so variants never collide.
MAX_VARIANTS = 8

# INFO ENAM: uint16 flags, then uint16 reset hours. Names from xEdit's
# wbDefinitionsFO4.pas (dev-4.1.6, "Response flags"), checked against how
# Fallout4.esm uses them with tools/random_groups.py -- not from memory.
ENAM_RANDOM = 0x02       # pick among the valid lines of this run
ENAM_SAY_ONCE = 0x04     # the line is never said again after the first time
ENAM_RANDOM_END = 0x20   # closes a Random run; the next Random line starts a new one
ENAM_REQUIRES_PLAYER_ACTIVATION = 0x08   # a greeting only on the player's E, never a walk-by hello
ENAM_START_SCENE_ON_END = 0x01   # TSCE fires when the line ENDS, not as it begins

QUEST_EDID = 'OvertureDialogueQuest'
SCRIPT_NAME = 'Overture:Approach'
# On every NPC reply INFO. Its OnEnd tells Overture:Approach.Replied what the
# line did; the two Int properties say which stage and which outcome.
REPLY_SCRIPT = 'Overture:Reply'
# Overture:Reply's Outcome values -- Overture:Approach's OUTCOME_* must match.
OUTCOME_LAND, OUTCOME_MISS, OUTCOME_OFFEND, OUTCOME_RECOIL, OUTCOME_RECOIL_LIKED = 1, 2, 3, 4, 5
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

# WHERE THE NPC ANSWERS. A player option's own INFO is what the PLAYER says --
# XDI's list shows exactly that text (xdi src/DialogueEx.cpp:265-295 reads the
# player info's response), and in vanilla the chosen INFO is played by the
# player before the NPC speaks. The NPC's reply lives in a SECOND topic per
# slot, named by the action's second set of fields. MEASURED on SCEN 0010BECF:
# PTOP 0010BEB7 -> NPOT 0010BEBB, NTOP 0010BEB6 -> NNGT 0010BEBA,
# NETO 0010BEB5 -> NNUT 0010BEB9, QTOP 0010BEB4 -> NQUT 0010BEB8. xEdit names
# them "NPC Positive/Negative/Neutral/Question Response".
#
# The first builds wrote these four as 0 on the belief that they were "where
# an option leads", and put every NPC reply into the player's own INFO: the
# persona matrix picked the right sentence and handed it to the wrong speaker.
NPC_SLOT = {'PTOP': 'NPOT', 'NTOP': 'NNGT', 'NETO': 'NNUT', 'QTOP': 'NQUT'}
NPC_TOPIC_BASE = 0x01000820     # one reply topic per register
PLAYER_INFO_BASE = 0x01000900   # the player's one line per register


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


def wstring(text):
    """A VMAD string: uint16 length, then the bytes, no terminator."""
    raw = text.encode('ascii')
    return struct.pack('<H', len(raw)) + raw


def vmad(script, int_props=()):
    """One script, optionally with Int properties. version 6, object format 2.

    The INFO form of this is MEASURED on Fallout4.esm INFO 0001DABE: its VMAD is
    version 6, format 2, two plain scripts (CA_DialogueBump_TopicInfoScript with
    one edited property, CA_DB_Event01 with none) and NOTHING after them -- the
    fragment block is optional (xEdit wbVMADFragmentedINFO, SetOptionalFrom(3)).
    A property is: name, type (3 = Int), status (1 = edited, as vanilla's is),
    then the value.
    """
    v = struct.pack('<hhH', 6, 2, 1)
    v += wstring(script) + struct.pack('<B', 0)        # status: local
    v += struct.pack('<H', len(int_props))
    for name, value in int_props:
        v += wstring(name) + struct.pack('<BB', 3, 1) + struct.pack('<i', value)
    return v


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
    f = field('EDID', zstring(QUEST_EDID))
    f += field('VMAD', vmad(SCRIPT_NAME))
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


def public_global():
    """1 when other people can see the target, 0 when not.

    Set by Overture:Approach from Rapport:Core.ObserversNear against Rapport's
    own observer tolerance, so "public" means here what it means there.
    """
    f = field('EDID', zstring('OverturePublic'))
    f += field('FNAM', b'f')
    f += field('FLTV', struct.pack('<f', 0.0))
    return record('GLOB', PUBLIC_GLOBAL, f)


def enabled_global():
    """The master switch: 1 = the approach opens for eligible NPCs, 0 = never.

    It used to be OvertureArmed, a dev gate armed by the approach verb and
    disarmed as the scene started so the re-greet went to the NPC's own
    greeting. The per-NPC day stamp (NEXT_DAY_AV) does that job now, for
    everyone, so what is left is an on/off switch -- on by default -- that an
    MCM page can drive later.
    """
    f = field('EDID', zstring('OvertureEnabled'))
    f += field('FNAM', b'f')
    f += field('FLTV', struct.pack('<f', 1.0))
    return record('GLOB', ENABLED_GLOBAL, f)


def next_day_av():
    """AVIF: the game day this NPC may be approached again (O-8: once a day).

    Stamped by Overture:Approach as the scene begins -- floor(days passed) + 1 --
    and compared by the greeting against the vanilla GameDaysPassed global, so an
    NPC opens again at the start of the next calendar day with no timer and no
    list to clean up. It also closes the re-greet that follows the reply, for
    this NPC, because the stamp is already tomorrow by then.

    Shape from xEdit's AVIF definition and vanilla's own plain values: DESC is
    required, NAM0 is the default (0.0 = never approached), AVFL 0x400 "Default
    to 0". Not 0x80000000 "Hardcoded" -- that is for values the engine owns.
    """
    f = field('EDID', zstring('OvertureNextApproachDay'))
    f += field('DESC', zstring(''))
    f += field('NAM0', struct.pack('<f', 0.0))
    f += field('AVFL', struct.pack('<I', 0x00000400))
    return record('AVIF', NEXT_DAY_AV, f)


def stage_reached_av():
    """AVIF: the furthest stage that LANDED with the player, 0 = never.

    Written by Overture:Approach.Replied on a land; read to start a returning
    conversation at stage 2 rather than replaying first-meeting lines
    (docs/methodology.md 1 and 8). Same shape as the next-day value.
    """
    f = field('EDID', zstring('OvertureStageReached'))
    f += field('DESC', zstring(''))
    f += field('NAM0', struct.pack('<f', 0.0))
    f += field('AVFL', struct.pack('<I', 0x00000400))
    return record('AVIF', STAGE_REACHED_AV, f)


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
    # DATA is Topic Flags (u8), Category (u8), Subtype (u16) -- xEdit's reading.
    # 00 02 0F 00: no flags, category 2 (Scene), subtype 15. 31,330 of the base
    # game's 31,958 SCEN topics carry the same.
    #
    # SOLVED ELSEWHERE: variants rotate through the INFO's ENAM Random flag
    # (0x02), not through anything on the topic. The failed experiment once
    # recorded here -- "bit 0x04, DATA[1] = 6" -- changed the CATEGORY to 6
    # (Service), not a flag, so it says nothing about topic flags, which live
    # in DATA[0]. (Records review 2026-09-23.)
    f += field('DATA', bytes([0x00, 0x02, 0x0F, 0x00]))
    f += field('SNAM', b'SCEN')
    f += field('TIFC', struct.pack('<I', infos))
    return record('DIAL', topic_id, f)


def line(info_id, player_prompt, spoken, persona_index=None, public=None,
         enam=ENAM_RANDOM, reply=None, jump=None, extra=b''):
    """One INFO. Transcribed from INFO 0010BEC4 (a player line) and 0010BEBD
    (an NPC reply), which differ in exactly one field: the player's has RNAM.

    NAM1 is what the SPEAKER of this line says -- the player on a player topic,
    the NPC on a reply topic. RNAM is the menu prompt and exists only on a
    player's line; pass player_prompt=None for an NPC reply. Both literal
    (fact 4).

    TRDA's first four bytes are the emotion id; ffffffff is none. Its second
    field is the RESPONSE NUMBER, which is the "_1" in the audio file name
    <INFO & 0xFFFFFF>_1.fuz, so it must be 1.

    NAM9 is omitted on purpose. In the template it is 900df0239989cf01 -- an
    8-byte Windows FILETIME, an editor timestamp rather than data, which is why
    fo4-rapport's barks work without it.
    """
    trda = bytes.fromhex('ffffffff' '01000000' '00010000' 'ffffffff' 'ffffffff')
    # VMAD FIRST, where INFO 0001DABE has it. `reply` = (stage, outcome) puts
    # Overture:Reply on the line; the player's own lines carry none.
    f = b''
    if reply is not None:
        stage, outcome = reply
        f += field('VMAD', vmad(REPLY_SCRIPT, (('Stage', stage), ('Outcome', outcome))))
    # ENAM bit 0x02 = "one of several", the engine's Random flag. Ours was 0 and
    # every read returned the same line even though two passed their conditions.
    # MEASURED across every dialogue INFO in Fallout4.esm: of lines carrying
    # ENAM 2, 87% sit in a topic that holds more than one line (15,022 of
    # 17,269); of lines carrying 0, only 31% do. tools/info_enam.py is the check.
    f += field('ENAM', struct.pack('<HH', enam, 0))
    f += field('TRDA', trda)
    f += field('NAM1', zstring(spoken))
    f += field('NAM2', b'\0')
    f += field('NAM3', b'\0')
    f += field('NAM4', b'\0')
    if persona_index is not None:
        # Only when the global says this NPC is that persona. Four INFOs per
        # topic, one per persona, and the engine takes the first that passes.
        f += field('CTDA', condition(FUNC_GET_GLOBAL_VALUE, PERSONA_GLOBAL,
                                     value=float(persona_index), runon=0))
    if public is not None:
        # AND, not OR: two CTDAs with the OR bit clear both have to pass.
        f += field('CTDA', condition(FUNC_GET_GLOBAL_VALUE, PUBLIC_GLOBAL,
                                     value=float(public), runon=0))
    # Further conditions from the caller (a verdict, a fallback's persona -1).
    # CTDAs AND in file order, so they sit after the persona and public ones.
    f += extra
    if player_prompt is not None:
        f += field('RNAM', zstring(player_prompt))
    if jump is not None:
        # `jump` = a phase NAME of our own scene. TSCE + NAM0 on a line spoken
        # inside that scene moves it to the phase: vanilla's own pattern --
        # INFO 0001DA84 jumps its running scene 0000583D to the phase "synth
        # question loop" -- and 1,778 base-game INFOs do it. With ENAM 0x01
        # the jump waits for the line to END.
        f += field('TSCE', struct.pack('<I', SCENE_FORMID))
        f += field('NAM0', zstring(jump))
    else:
        f += field('NAM0', b'\0')
    f += field('INAM', struct.pack('<I', 1))
    return record('INFO', info_id, f)


def condition(func, param1, value=1.0, runon=0, op=0x00, value_global=None, alias=0):
    """One CTDA, 32 bytes.

    `value_global`: compare against a GLOBAL instead of a float -- the byte-0 flag
    0x04 "Use Global", with the global's form id where the float would be
    (xEdit wbDefinitionsCommon.pas, wbConditionTypeToStr). Byte 0's top three bits
    are the operator: 0 equal, 32 not equal, 64 greater, 96 greater-or-equal,
    128 less, 160 less-or-equal.

    Layout, derived from four real conditions on FFGoodneighbor02's greeting and
    checked against every CTDA on every dialogue INFO in Fallout4.esm:

        0       operator and flags (0x00 = equal to)
        1-3     unused
        4-7     comparison value, float
        8-9     function index, uint16
        10-11   padding
        12-15   parameter 1
        16-19   parameter 2
        20-23   run-on type (0 = Subject, the speaker; 5 = Quest Alias)
        24-27   reference
        28-31   parameter 3: the ALIAS ID when run-on is 5 (vanilla SCEN 0010C957
                carries its alias 0x42 here), else 0

    The real records carry non-zero bytes in the two padding runs -- `7a d2 96`
    and `d2 96` -- identical across unrelated conditions, which is what
    uninitialised memory written straight to disk looks like. Zeros here.
    """
    if value_global is not None:
        op |= CTDA_USE_GLOBAL
        compared = struct.pack('<I', value_global)
    else:
        compared = struct.pack('<f', value)
    return (struct.pack('<B', op) + b'\0' * 3
            + compared
            + struct.pack('<H', func) + b'\0' * 2
            + struct.pack('<I', param1)
            + struct.pack('<I', 0)
            + struct.pack('<I', runon)
            + struct.pack('<I', 0)
            + struct.pack('<i', alias))


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

# WHO the approach opens for (O-8, owner poll 2026-09-23), all run on the SPEAKER.
# Function indices from xEdit's condition table; form ids read out of Fallout4.esm.
FUNC_GET_VALUE = 14
FUNC_GET_IN_FACTION = 71
# FollowersScript.SetCompanion adds it on recruitment and nothing removes it.
FACTION_HAS_BEEN_COMPANION = 0x000A1B85
FUNC_IS_IN_COMBAT = 289
FUNC_IS_CHILD = 365
FUNC_GET_PLAYER_TEAMMATE = 453   # the player's current companion(s)
FUNC_HAS_KEYWORD = 560
FUNC_IS_IN_SCENE = 590
KW_ACTOR_TYPE_NPC = 0x00013794    # HumanRace, GhoulRace, HumanChildRace, SynthGen2Race -- not robots, dogs, mutants
KW_ACTOR_TYPE_SYNTH = 0x0010C3CE  # SynthGen2Race: "humans and ghouls" leaves them out
GLOB_GAME_DAYS_PASSED = 0x00000039
CTDA_OP_LE = 0xA0                 # "less than or equal to", byte 0's top three bits
CTDA_USE_GLOBAL = 0x04            # byte 0 flag: the compared value is a GLOB form id


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

    WHO IT OPENS FOR is decided on the SPEAKER, and ALFA puts the speaker into
    the Target alias -- vanilla's generic-greeting shape (see below). Until O-7's
    eligibility conditions land, the only gate is OvertureArmed. (It used to be
    GetIsAliasRef on a hand-filled alias, which is what the dev verb existed to
    fill.)
    """
    f = field('EDID', zstring('OvertureGreeting'))
    f += field('PNAM', struct.pack('<f', 50.0))
    f += field('QNAM', struct.pack('<I', QUEST_FORMID))
    f += field('DATA', bytes([0x00, 0x07, 0x73, 0x00]))
    f += field('SNAM', b'GREE')
    f += field('TIFC', struct.pack('<I', 1))
    topic = record('DIAL', GREET_TOPIC, f)

    trda = bytes.fromhex('ffffffff' '01000000' '00010000' 'ffffffff' 'ffffffff')
    # NOT the template's 4. That is ENAM_SAY_ONCE: right for FFGoodneighbor02,
    # whose greeting starts its quest's scene one time, and wrong for a greeting
    # that has to open the approach every time the player talks to someone (O-7).
    #
    # Requires Player Activation (0x08), as vanilla's generic vendor greeting
    # 00076AAD carries: the approach opens when the player presses E on someone,
    # never as a hello while they walk past.
    g = field('ENAM', struct.pack('<HH', ENAM_REQUIRES_PLAYER_ACTIVATION, 0))
    g += field('TRDA', trda)
    g += field('NAM1', zstring('...'))           # the NPC's greeting line
    g += field('NAM2', b'\0')
    g += field('NAM3', b'\0')
    g += field('NAM4', b'\0')
    # WHO it opens for (O-8), all on the SPEAKER -- the alias is still empty here;
    # ALFA below fills it. Adults, humans and ghouls (ActorTypeNPC, not a Gen-2
    # synth, not a child), not the player's current companion (teammate), not in
    # combat, not already in a scene, and once a game day: the stamp the script
    # writes as the scene begins must be <= GameDaysPassed. Plus the master switch.
    for func, param, value in (
            (FUNC_HAS_KEYWORD, KW_ACTOR_TYPE_NPC, 1.0),
            (FUNC_HAS_KEYWORD, KW_ACTOR_TYPE_SYNTH, 0.0),
            (FUNC_IS_CHILD, 0, 0.0),
            (FUNC_GET_PLAYER_TEAMMATE, 0, 0.0),
            # Anyone who has EVER been a companion -- a dismissed Ivy standing
            # in a settlement included. Companions get their own module (N-7),
            # and a stranger's approach at priority 100 would talk over a
            # companion mod's own voiced dialogue in subtitles. (Review 2026-09-23.)
            (FUNC_GET_IN_FACTION, FACTION_HAS_BEEN_COMPANION, 0.0),
            (FUNC_IS_IN_COMBAT, 0, 0.0),
            (FUNC_IS_IN_SCENE, 0, 0.0),
            (FUNC_GET_GLOBAL_VALUE, ENABLED_GLOBAL, 1.0)):
        g += field('CTDA', condition(func, param, value=value, runon=RUNON_SUBJECT))
    g += field('CTDA', condition(FUNC_GET_VALUE, NEXT_DAY_AV, runon=RUNON_SUBJECT,
                                 op=CTDA_OP_LE, value_global=GLOB_GAME_DAYS_PASSED))
    g += field('TSCE', struct.pack('<I', SCENE_FORMID))   # <- starts the scene
    # FORCED ALIAS: the engine puts whoever says this line into alias 0 as the
    # scene starts. xEdit calls it "Forced Alias" (s32), right after TSCE; it is
    # how ONE vanilla quest serves every vendor, merchant and doctor in the game
    # (WorkshopVendorGreetingsGeneric 00076AAD: TSCE + ALFA 0 into an alias with
    # no fill at all -- exactly our alias's shape). 102 base-game greetings carry
    # it (tools/greet_scene_aliases.py). This is O-7's mechanism.
    g += field('ALFA', struct.pack('<i', ALIAS_INDEX))
    g += field('NAM0', b'\0')
    g += field('INAM', struct.pack('<I', 1))
    line_rec = record('INFO', GREET_INFO, g)
    return topic + child_group(GREET_TOPIC, 7, line_rec)


# SCEN VNAM is "Actor Behavior Settings" (xEdit wbDefinitionsFO4.pas): Death,
# Combat, Player Dialogue, Observe Combat, each 0 Set All Normal, 1 Set All
# Pause, 2 Set All End, 3 Don't Set All. It is NOT four alias ids: the template's
# 03000000 x4 only happened to equal its alias 3, and our copy of the IDEA wrote
# 0 x4 -- Set All Normal, which contradicts our actor's own DNAM (Death End,
# Combat End). 3,137 of Fallout4.esm's 3,553 scenes carry 3 x4, Don't Set All:
# the actor's own behaviour decides. (Records review 2026-09-23.)
VNAM_DONT_SET_ALL = struct.pack('<IIII', 3, 3, 3, 3)


def scene(topic_ids):
    """The SCEN. Transcribed field for field from SCEN 0010BECF.

    `topic_ids` is {field: form id} for all eight: the player's PTOP/NTOP/
    NETO/QTOP and the NPC's NPOT/NNGT/NNUT/NQUT.

    The second four are the NPC's RESPONSE topics, one per slot, exactly as the
    template has them. The first builds wrote them as 0, reading them as "where
    an option leads" -- and so the NPC had nothing to say and the reply text sat
    in the player's own line.

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
    # Action flags: Camera Speaker Target (bit 21) only -- the configuration
    # VERIFIED in game 2026-09-23 (the NPC answered, variants rotated, the recoil
    # fence held). It is NOT known to be necessary. The template's 0x00228000
    # adds Face Target (15) and Headtrack Player (17), as 2,406 of the base
    # game's 2,422 player-dialogue actions do, while Whitechapel Charlie's own
    # scene 00075E89 carries 0x00200800 (tools/action_flags.py; names from xEdit
    # wbDefinitionsFO4.pas). Dropping Face Target was a response to a menu that
    # hung on Charlie -- and that theory DIED: his own vanilla scene hung the
    # same way from the same spot. What decided it was the player's position:
    # with Charlie (seated in bar furniture, sit=3) under the crosshair it
    # works; from the end of the bar, crosshair on a door, nothing does.
    # OPEN: A/B Face Target with the player positioned properly. With it, an
    # approached NPC turns to face the player, which is what vanilla does.
    f += field('FNAM', struct.pack('<I', 0x00200000))
    f += field('SNAM', struct.pack('<I', 0))            # start phase
    f += field('ENAM', struct.pack('<I', 0))            # end phase
    # The template's order, player then NPC, positive-negative-neutral-question.
    for slot in ('PTOP', 'NTOP', 'NETO', 'QTOP', 'NPOT', 'NNGT', 'NNUT', 'NQUT'):
        f += field(slot, struct.pack('<I', topic_ids[slot]))
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
    f += field('VNAM', VNAM_DONT_SET_ALL)
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
    recoil = {}
    for l in bank['lines']:
        if l['kind'] == 'response' and l['stage'] == 1:
            reply.setdefault((l['register'], l['persona']), []).append((l['text'], l['outcome']))
        elif l['kind'] == 'recoil' and l['stage'] == 1:
            recoil.setdefault(l['persona'], []).append(l['text'])

    topic_ids, children, count = {}, b'', 0
    all_ids = [(QUEST_FORMID, 'quest'), (SCENE_FORMID, 'scene'),
               (PERSONA_GLOBAL, 'persona global'), (PUBLIC_GLOBAL, 'public global'),
               (ENABLED_GLOBAL, 'enabled global'), (NEXT_DAY_AV, 'next-day actor value'),
               (STAGE_REACHED_AV, 'stage-reached actor value'),
               (GREET_TOPIC, 'greeting topic'), (GREET_INFO, 'greeting line')]
    for n, (slot, register) in enumerate(SLOTS):
        prompt = by_register[register]

        # THE PLAYER'S OPTION: one line, the player's own words. RNAM is the menu
        # text, NAM1 what the player then says -- empty for linger, whose whole
        # content is saying nothing. No conditions: every register is always on
        # the menu, and it is the ANSWER that depends on who is listening.
        tid = TOPIC_BASE + n
        pid = PLAYER_INFO_BASE + n
        topic_ids[slot] = tid
        all_ids += [(tid, f'player topic {register}'), (pid, f'player line {register}')]
        children += topic(tid, f'OvertureTopic{register.capitalize()}', infos=1)
        children += child_group(tid, 7, line(pid, prompt['text'],
                                             prompt.get('spoken', prompt['text']), enam=0))
        count += 2

        # THE NPC'S ANSWER, in its own topic, which the scene names in the
        # NPC-response field for the same slot (NPC_SLOT).
        rtid = NPC_TOPIC_BASE + n
        topic_ids[NPC_SLOT[slot]] = rtid
        all_ids.append((rtid, f'reply topic {register}'))

        # EVERY variant, not just the first. Four lines exist per cell and the
        # engine picks among the INFOs whose conditions pass -- measured on the
        # base game, where one barter line came back as four different sentences
        # on four reads. Using one line per cell made an NPC who says the same
        # sentence every time you ever approach them.
        block, n_infos = b'', 0

        # THE RECOILS COME FIRST, and that ordering IS the rule. The engine takes
        # the first INFO whose conditions pass, so a recoil ahead of the normal
        # reply wins whenever the room is public and is skipped when it is not.
        # Put them after and they would never be reached.
        #
        # BUT RANDOM POOLS A RUN, NOT A CONDITION. Every line here is Random so
        # a cell's variants rotate, and consecutive Random lines form ONE run
        # the engine picks from -- so without a fence a public room would pick
        # among the recoils AND the normal replies, and the override becomes a
        # coin flip. The base game fences runs with Random End: 706 of its 722
        # Random End lines close a run of Random lines, and 178 are followed at
        # once by another Random line, which is two groups back to back exactly
        # like these. Each persona's LAST recoil carries it.
        if register == INTIMATE_REGISTER:
            for k, persona in enumerate(PERSONAS):
                texts = recoil.get(persona, [])
                for v, text in enumerate(texts):
                    rid = RECOIL_BASE + k * MAX_VARIANTS + v
                    all_ids.append((rid, f'recoil {persona} variant {v}'))
                    last = v == len(texts) - 1
                    # The vulgar recoil is "yes -- not here": the register was
                    # right. Every other persona's is an embarrassment.
                    liked = bank['lands_on'].get(persona) == register
                    block += line(rid, None, text,
                                  persona_index=k, public=1,
                                  enam=ENAM_RANDOM | (ENAM_RANDOM_END if last else 0),
                                  reply=(1, OUTCOME_RECOIL_LIKED if liked else OUTCOME_RECOIL))
                    n_infos += 1

        for k, persona in enumerate(PERSONAS):
            texts = reply.get((register, persona))
            if not texts:
                raise SystemExit(f'no stage-1 response for {register}/{persona}')
            if len(texts) > MAX_VARIANTS:
                raise SystemExit(f'{register}/{persona} has {len(texts)} variants, '
                                 f'more than the {MAX_VARIANTS} the id spacing allows')
            for v, (text, outcome) in enumerate(texts):
                iid = INFO_BASE + (n * len(PERSONAS) + k) * MAX_VARIANTS + v
                all_ids.append((iid, f'{register}/{persona} variant {v}'))
                if outcome == 'land':
                    code = OUTCOME_LAND
                elif register == INTIMATE_REGISTER:
                    # Crude at someone who did not want crude is an insult, not
                    # a wrong guess (methodology 3).
                    code = OUTCOME_OFFEND
                else:
                    code = OUTCOME_MISS
                block += line(iid, None, text, persona_index=k, reply=(1, code))
                n_infos += 1

        # The lines are built before the topic, so TIFC is the REAL count. An
        # earlier version wrote the topic first with a placeholder and never went
        # back, leaving every topic claiming one line while holding sixteen.
        children += topic(rtid, f'OvertureReply{register.capitalize()}', infos=n_infos)
        children += child_group(rtid, 7, block)
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
    blob = group('GLOB', persona_global() + public_global() + enabled_global()) + group('QUST', quest_blob)
    blob += group('AVIF', next_day_av() + stage_reached_av())

    return finish(blob), topic_ids


def walk_written(blob):
    """(records, groups, form ids) of what was actually WRITTEN."""
    recs, groups, ids = 0, 0, []

    def walk(start, end):
        nonlocal recs, groups
        o = start
        while o < end:
            size = struct.unpack_from('<I', blob, o + 4)[0]
            if blob[o:o + 4] == b'GRUP':
                groups += 1
                walk(o + 24, o + size)
                o += size
            else:
                recs += 1
                ids.append((struct.unpack_from('<I', blob, o + 12)[0], blob[o:o + 4].decode('ascii')))
                o += 24 + size

    walk(0, len(blob))
    return recs, groups, ids


def finish(blob):
    """The TES4 header, from the records that were really written.

    The hand-kept id list and record count each drifted once; this walks the
    finished bytes instead, so a writer that forgets to register an id is
    still caught before the engine meets a duplicate in InitGameDataThread.

    numRecords counts records AND groups, as every real plugin does
    (DLCRobot.esm: 49,111 + 1,421 = 50,532, its HEDR exactly). The next object
    id is the bare object id, without the load-order byte.
    """
    recs, groups, ids = walk_written(blob)
    check_unique(ids)
    next_object = (max(i for i, _what in ids) + 1) & 0x00FFFFFF
    head = field('HEDR', struct.pack('<fiI', 1.0, recs + groups, next_object))
    head += field('CNAM', zstring(AUTHOR))
    head += field('MAST', zstring(MASTER))
    head += field('DATA', struct.pack('<Q', 0))
    return record('TES4', 0, head) + blob


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return 1
    # --stages 3: the staged conversation (tools/overture_stages.py), NOT YET
    # VERIFIED IN GAME. Without it, the verified one-exchange plugin, unchanged.
    stages = 1
    if '--stages' in sys.argv:
        stages = int(sys.argv[sys.argv.index('--stages') + 1])
    if stages == 3:
        import overture_stages
        blob, staged = overture_stages.build_staged()
        out = pathlib.Path(sys.argv[1])
        out.parent.mkdir(parents=True, exist_ok=True)
        out.write_bytes(blob)
        print(f'wrote {out} ({len(blob)} bytes) -- STAGED BUILD, unverified in game')
        for stage in (1, 2, 3):
            print(f'  stage {stage}: ' + ', '.join(f'{k} {v:08X}' for k, v in staged[stage].items()))
        return 0
    if stages != 1:
        raise SystemExit('--stages is 1 (the verified build) or 3')
    blob, topic_ids = build()
    out = pathlib.Path(sys.argv[1])
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_bytes(blob)
    print(f'wrote {out} ({len(blob)} bytes)')
    print(f'  quest {QUEST_EDID} {QUEST_FORMID:08X}, alias {ALIAS_NAME} index {ALIAS_INDEX}')
    print(f'  scene {SCENE_EDID} {SCENE_FORMID:08X}')
    for slot, register in SLOTS:
        print(f'  {slot}  {register:7} topic {topic_ids[slot]:08X}   '
              f'the NPC answers from {NPC_SLOT[slot]} {topic_ids[NPC_SLOT[slot]]:08X}')
    print(f'  persona global {PERSONA_GLOBAL:08X}: ' +
          ', '.join(f'{k}={n}' for k, n in enumerate(PERSONAS)))
    print(f'  public global  {PUBLIC_GLOBAL:08X}: 1 = others can see them')
    print(f'  enabled global {ENABLED_GLOBAL:08X}: 1 = approaches open (default)')
    print(f'  next-day AV    {NEXT_DAY_AV:08X}: the day an NPC may be approached again')
    print('  master', MASTER)
    return 0


if __name__ == '__main__':
    sys.exit(main())
