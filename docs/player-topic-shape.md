# What a player dialogue option actually is

Measured out of `Fallout4.esm` on 2026-09-22 with `tools/topic_types.py` and
`tools/player_topic_shape.py`. Written down because the obvious design is wrong and would have
produced records the engine never looks at.

## The finding: player options are SCENE dialogue

12,513 `INFO` records in `Fallout4.esm` carry an `RNAM`, which is the text the player sees as a menu
option. Crossed against the type code (`SNAM`) of the topic that owns them:

| SNAM | category | INFOs | with RNAM | share |
| --- | --- | --- | --- | --- |
| `SCEN` | 16 | 18,814 | 4,090 | 22% |
| `SCEN` | 15 | 15,243 | 4,843 | 32% |
| `SCEN` | 17 | 5,460 | 1,591 | 29% |
| `SCEN` | 14 | 4,221 | 1,449 | 34% |
| `CUST` | 0 | 6,933 | 62 | 1% |
| `IDAT` | 99 | 1,955 | 243 | 12% |
| `HELO` / `GREE` / `IDLE` / `TAUT` / `NOTC` | — | thousands | 0–5 | ~0% |

**`SCEN` categories 14–17 hold 11,973 of the 12,513 — 96% of every player prompt in the game.**

So a player dialogue option is not a free-standing topic you attach to an NPC. It is **scene
dialogue**: a quest owns a scene, the scene runs when you talk to someone, and the player's choices
are topics of type `SCEN` hanging off it.

`CUST` category 0 — the shape Rapport's barks use — carries 62 player prompts out of 6,933. That is
noise, not a route.

**Independent corroboration.** XDI's own guide for modders says: *"To implement XDI in a mod, in
your scene, right click in the Alias Keywords section and select Add, then choose the XDI keyword."*
**In your scene.** Two sources that know nothing about each other agree, which is worth more than
either alone.

**That hypothesis was wrong, and here is the correction.** It said the four `SCEN` categories
(14–17) were probably the four dialogue-wheel slots. Checked against `FFGoodneighbor02`: **all eight
of its scene topics are category 15**, including the four sitting in different wheel slots. Category
is not the slot.

**The slot is which field of the SCEN record points at the topic.** That is the real mechanism, and
it is in the scene record's action block:

| field | slot | the NPC answers from |
| --- | --- | --- |
| `PTOP` | positive | `NPOT` |
| `NTOP` | **negative** | `NNGT` |
| `NETO` | **neutral** | `NNUT` |
| `QTOP` | question | `NQUT` |

**CORRECTED 2026-09-23, twice over.** This table first said `NTOP` neutral and `NETO` negative; XDI's
optionIDs showed the opposite in game, and xEdit names them "Player Negative Response" and "Player
Neutral Response". And the second set — `NPOT`, `NNGT`, `NNUT`, `NQUT` — was described here as
"where each option leads next". It is not. xEdit names them **"NPC Positive/Negative/Neutral/Question
Response"**: the topic the NPC ANSWERS from. The template pairs them slot for slot (PTOP `BEB7` → NPOT
`BEBB`, NTOP `BEB6` → NNGT `BEBA`, NETO `BEB5` → NNUT `BEB9`, QTOP `BEB4` → NQUT `BEB8`). Reading them
as "leads to" is why the first builds wrote them as 0 and put the NPC's reply into the player's own
line — see `dialogue-route.md`, "The NPC was never speaking".

Two things follow that matter more than the correction itself. **Four slots, and Overture has
exactly four registers**, so the base game's own structure fits the design with nothing left over.
And **that is precisely the cap XDI removes** — so XDI is not merely a nicer presentation, it is what
a fifth register would require. Category 15 appears to mean "scene player-dialogue topic"; what 14,
16 and 17 distinguish is still unknown and nothing here depends on it.

## The records, field by field

A real player topic, `DIAL 0007D58A` / `INFO 0007D5A3`:

```
DIAL 0007D58A
  PNAM  4   00004842   = 50.0f as a float  (priority)
  QNAM  4   00003648   the owning QUEST's form id
  DATA  4   00 02 0f 00   [1]=2 subtype, [2]=15 category
  SNAM  4   "SCEN"     the four-character type code
  TIFC  4   1          how many INFOs this topic holds

INFO 0007D5A3
  ENAM  4   0          flags (uint16) + reset hours (uint16); 0x02 Random, 0x04 Say Once, 0x20 Random End
  TRDA  20            response data (emotion, emotion value, ...)
  NAM1  4   string id  what the PLAYER says -- a player topic's line is spoken by the player
                       (corrected 2026-09-23; this said "the NPC's spoken response")
  NAM2  1   0          script notes
  NAM3  1   0          edits
  NAM4  1   0
  RNAM  4   string id  THE PLAYER'S PROMPT -- the menu text
  NAM0  1   0
  INAM  4   1
```

A second example (`INFO 0007D5C4`) adds what a real conditioned line carries: `VMAD` (a script),
two `CTDA` conditions with a `CIS2` naming `::var_Speech_var`, and `INCC` (the condition count). So
conditions and scripts are normal here, and a speech check is a `CTDA` on the player option — which
is how a register could later be gated on anything we like.

## The complete minimum, from FFGoodneighbor02

The smallest quest in the game that owns real player dialogue — 9 topics, 10 lines, 4 prompts. Every
part of it, and nothing spare:

```
QUST  <quest>                       EDID, DNAM, one ALID alias for the NPC
  GRUP type 10 <quest>              the quest's children
    DIAL <topic> x4 (player)        PNAM 50.0f · QNAM <quest> · DATA cat 15 · SNAM "SCEN" · TIFC 1
      GRUP type 7 <topic>
        INFO <line>                 ENAM 0 · NAM1 <the PLAYER's line> · NAM2/3/4 0 · NAM9
                                    · RNAM <player prompt> · NAM0 0 · INAM 1
    DIAL <topic> x4 (NPC reply)     the same DIAL shape; its INFO has NO RNAM and may hold
                                    several TRDA+NAM1 responses said in sequence
    DIAL GREE                       two INFOs, both TSCE -> the scene: one Say Once, one repeatable

SCEN  <scene>                       INSIDE the quest's GRUP type 10, a sibling of the topics
                                    (this line said "top level" until the first run proved otherwise)
  EDID · FNAM flags
  phase blocks                      HNAM · NEXT · NEXT · WNAM · CTDA
  action block                      ALID <alias> · ANAM <type> · SNAM/ENAM start+end phase
                                    · PTOP/NTOP/NETO/QTOP  <- the four topics
                                    · NPOT/NNGT/NNUT/NQUT  <- where each one leads
                                    · DTGT <target alias>
```

**No `BNAM`.** Scene topics carry no Dialogue Branch — only 1,290 of 35,443 `DIAL` records have one.
That is the opposite of the bark case, where a missing `DLBR` left 211 topics silent, and it is worth
stating plainly so nobody "fixes" a working scene topic by adding a branch it does not want.

## The quest's aliases, and what the scene points at

A reference alias inside `QUST`, measured from the same quest:

```
ALST  4   alias INDEX (0, 2, 3, 4 ...)   -- not a form id
ALID  str the alias name ("Player", "Daisy")
ALUA  4   a unique actor's form id       -- for an alias bound to one specific actor
  or
ALFA  4 + ALRT 4                         -- forced reference / by ref type
VTCK  4   0
ALED  0   end of this alias
```

`ANAM` at the head of the block is the next free alias index; `ALLS` marks a location alias rather
than a reference one.

**The scene's `ALID` is the alias INDEX, not a form id.** `FFGoodneighbor02RewardScene` carries
`ALID = 3`, and alias 3 in that quest is `Daisy` (`ALUA 0x00022952`). So a scene names its speaker by
the quest alias slot, and the quest decides at runtime who fills it.

That is what Overture needs: a **script-filled** reference alias — no fill-type field at all — that
the quest points at whoever the player is talking to. **Measured**, so nothing here is guessed:

`Fallout4.esm` holds **1,069** reference aliases carrying none of the fourteen fill-type fields
(`ALUA`, `ALFA`/`ALRT`, `ALFR`, `ALCO`/`ALCA`/`ALCL`, `ALEQ`/`ALEA`, `ALNA`/`ALNT`, `ALFE`/`ALFD`,
`ALFI`). Their shape is exactly five fields:

```
ALST  4   alias index
ALID  str name
FNAM  4   0x00000002        <- the flags
VTCK  4   0
ALED  0
```

**`FNAM` is the alias flags field, not `ALFL`.** `ALFL` appears only on location aliases (`ALLS`).
Among the 1,069, bit `0x02` is set in effectively all of them, and the plain value `0x00000002` is
the single most common at 279. So `FNAM = 2` is the canonical script-filled reference alias, read off
real records rather than inferred.

Re-run with `python tools/find_script_alias.py`.

## What this means for Overture

- **Build a dialogue scene, not loose topics.** Quest → aliases → scene → `SCEN` topics.
- **`NAM1` and `RNAM` are string-table ids here because `Fallout4.esm` is localized** (TES4 flag
  `0x80`). Overture is not localized, so both take the literal text. Copying the base game's field
  verbatim would put four bytes of garbage in every line — the same trap `fo4-rapport` already
  documented for barks.
- **Rapport's `make_dialogue.py` is the wrong starting point** for this, exactly as suspected. It
  builds `CUST` category 0 barks. The nesting rule and the not-localized rule carry over; the record
  shape does not.
- The four registers become four `SCEN` topics on one scene, and XDI is what lets there be more than
  four later.

## How to re-run it

```bash
python tools/topic_types.py                                   # the cross-tab above
python tools/player_topic_shape.py --examples 2 --category 15 # full field dumps
```

Both read `Fallout4.esm` only and write nothing. Set `PYTHONIOENCODING=utf-8` — a Windows console is
cp1252 and dies on the replacement character when a string id is printed as text.
