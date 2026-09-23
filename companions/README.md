# Companions — the module (O-19: B-lite + C + D)

N-7's module: companions get a relationship system of their own, bound to Rapport's store, with
modifiers no ordinary NPC has. The reasoning, the measured facts about vanilla companions and Ivy, and
the compatibility rules C1-C6 are in `docs/methodology.md` §11. What was built, what was measured on
the way, and every reading made without a poll are in §11.6 and in `docs/decisions.md`, "O-19 to O-26,
built". **Built 2026-09-23, not yet run in game.**

The code is in `papyrus/Overture/Companions/` and ships with the plugin. The scaffolds this folder used
to hold, including the variants not chosen (A, the affinity mirror; B, the three-axis track), are in git
history before the build commit. The reasons B lost to B-lite are in methodology §11.3.

## In one paragraph

No companion mod is a master and none is patched (C1). A companion no adapter vouches for is invisible
(C6): the vanilla adapter claims only the base game's own companions, so a mod companion with voiced
content of its own never hears Overture's lines as subtitles over it. Every foreign form is found at
runtime (`Game.IsPluginInstalled`, `Game.GetFormFromFile`, `CastAs` / `CallFunction`), and a lookup that
fails turns that adapter off (C4). Their state outranks ours (C2), their content comes first (C3), and
we call their functions rather than writing their globals (C5). Only Rapport's store moves (O-24).

For Ivy, Overture opens NO conversation of its own. Her Favor: Sex scenes are hers: they count toward
the bond (D.1), and with scenes on her fade becomes a Rapport scene (D.3, O-20).

## Its records in Overture.esp

| id | record | what |
| --- | --- | --- |
| `0x851` | AVIF OvertureCompanionDesire | wanting, 0..1, on the companion. **PUBLISHED** (below) |
| `0x853` | AVIF OvertureCompanionMoment | 0 not ours, 1 vouched (the player may start), 2 a moment is open |
| `0x855` | QUST OvertureCompanionsQuest | Registry, the adapters, Feeders, Moments, IvyNative |
| `0x856` | AVIF OvertureCompanionLastTick | the game day the feeders last counted |
| `0x85A` | AVIF OvertureCompanionSeenScene | the player's last scene this companion has reacted to |
| `0x85B` | AVIF OvertureCompanionAffinityTier | their own affinity's level, as last counted |
| `0x860`-`0x863` | INFO | the companion greetings, in the approach's greeting topic `0x830` |
| `0x864`-`0x86F` | DIAL, INFO | the companion wheel: four player topics and lines, four reply topics |
| `0xE10`-`0xEF9` | INFO | the companion's answers, one set per persona and verdict behind each proposition |

`0x850`, `0x852` and `0x854` stay reserved for the variants not built (B's Trust and Devotion, A's
mirror), and `0x857`-`0x85F` are unused. `tools/make_overture_esp.py` has the whole id map, and
`finish()` checks every id actually written.

**`0x851` is PUBLISHED: never renumber it.** fo4-anatomy's `Anatomy:Arousal` (its commit ced951f) reads
`GetFormFromFile(0x851, "Overture.esp") as ActorValue` for a companion's Desire, read-only, 0 to 1, to
show arousal on the body (the owner's ask, 2026-09-23). Any other id another mod comes to read goes into
this list the same way.

## What is assumed, and what must be measured

- **ASSUMED**: every number (the feeders' sizes, the wanting bars, the moment's two hours); Ivy's affinity
  scale (200, from her message names).
- **MEASURED**: vanilla companions' talk menus start from greetings; who has a romance
  (`InfatuationRomanticMessage`); Ivy's fade at phase 1. The evidence is in the decisions record.
- **MEASURE in game** (methodology §12):
  - a moment opening Overture's phase 4;
  - whether talking to a companion while sneaking reaches a greeting at all (O-23);
  - Ivy's phase log and her recorded bond;
  - with scenes on: pausing her scene while AAF moves her, and her warper quest during a Rapport scene.
