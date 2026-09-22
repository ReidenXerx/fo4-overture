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

**Labelled as hypothesis, not fact:** there are exactly four `SCEN` categories carrying prompts
(14, 15, 16, 17) and vanilla Fallout 4 has exactly four dialogue-wheel slots. It is very likely those
four categories *are* the four slots, which would also explain why XDI — whose whole purpose is
removing the four-option cap — hooks the scene layer. **Not verified.** Do not build anything that
depends on the mapping until somebody checks it.

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
