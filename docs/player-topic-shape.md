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

| field | slot |
| --- | --- |
| `PTOP` | positive |
| `NTOP` | neutral |
| `NETO` | negative |
| `QTOP` | question |

with a second set — `NPOT`, `NNGT`, `NNUT`, `NQUT` — holding four more topic ids, which appear to be
where each option leads next.

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
  ENAM  4   0          flags
  TRDA  20            response data (emotion, emotion value, ...)
  NAM1  4   string id  the NPC's spoken response
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
    DIAL <topic>                    PNAM 50.0f · QNAM <quest> · DATA cat 15 · SNAM "SCEN" · TIFC 1
      GRUP type 7 <topic>
        INFO <line>                 ENAM 0 · NAM1 <npc text> · NAM2/3/4 0 · NAM9
                                    · RNAM <player prompt> · NAM0 0 · INAM 1
    ... one DIAL+INFO pair per option ...

SCEN  <scene>                       top level, NOT inside the quest
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
