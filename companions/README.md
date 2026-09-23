# Companions — the module (O-19: B-lite + C + D)

N-7's module: companions get a relationship system of their own, bound to Rapport's store, with
modifiers no ordinary NPC has. The reasoning, the measured facts about vanilla companions and Ivy, and
the compatibility rules C1-C6 are in `docs/methodology.md` §11. What was built, what was measured on
the way, and every reading made without a poll are in §11.6 and in `docs/decisions.md`: "O-19 to O-26,
built" and "Microscope wave 3". **Built 2026-09-23 and reworked by microscope wave 3 the same night;
not yet run in game.**

The code is in `papyrus/Overture/Companions/` and ships with the plugin. The scaffolds this folder used
to hold, including the variants not chosen (A, the affinity mirror; B, the three-axis track), are in git
at `ab12f1c` (`git show ab12f1c:companions/...`). The reasons B lost to B-lite are in methodology §11.3.

## In one paragraph

No companion mod is a master and none is patched (C1). A companion no adapter vouches for is invisible
(C6): the vanilla adapter claims only the base game's own companions, so a mod companion with voiced
content of its own never hears Overture's lines as subtitles over it. Every foreign form is found at
runtime (`Game.IsPluginInstalled`, `Game.GetFormFromFile`, `CastAs` / `CallFunction`), and a lookup that
fails turns that adapter off (C4). Their state outranks ours (C2), their content comes first (C3), and
we call their functions rather than writing their globals (C5). Only Rapport's store moves (O-24).

For Ivy, Overture opens NO conversation of its own. Her Favor: Sex is hers:
- it counts toward the bond (D.1);
- with scenes on, her fade becomes a Rapport scene and her own scene carries on after it (D.3, O-20).

Her other favor scene, `Favor_Sex_Talk`, has no way in at all and is not counted.

## Wanting (Desire, `0x851`): the contract

fo4-anatomy draws this, so its meaning is fixed here:
- **0..1**, on the player's CURRENT companion only, and only one an adapter claims (a base-game
  companion). Everyone else reads **0**, including a companion who has just been dismissed.
- It **builds** by `fDesirePerDay` (0.10) on each game day spent TOGETHER (following the player, loaded),
  and only while their own gates are open: their romance done, or, with no romance of their own, their
  affinity at `fAffinityGate`.
- It **goes to 0** after a scene together.
- A vulgar companion who is romanced, or a Rapport lover, and hears about the player's scene with someone
  else gains 0.1.
- **None for a companion whose own mod keeps arousal** (Ivy): hers is `_ivy_IsAroused`, and anatomy reads
  that directly. Two opinions of one fact is R-1's problem.

## Its records in Overture.esp

| id | record | what |
| --- | --- | --- |
| `0x851` | AVIF OvertureCompanionDesire | wanting, above. **PUBLISHED** (below) |
| `0x853` | AVIF OvertureCompanionMoment | 0 not ours, 1 vouched (the player may start), 2 a moment is open |
| `0x855` | QUST OvertureCompanionsQuest | Registry, the adapters, Feeders, Moments, IvyNative |
| `0x856` | AVIF OvertureCompanionLastTick | the game day the feeders last counted |
| `0x857` | AVIF OvertureCompanionFall | the negative level counted in the current fall (0, -1 Disdain, -2 Hatred) |
| `0x858` | AVIF OvertureCompanionPairSeen | the player's scene count WITH them, plus one, as they last knew it |
| `0x85A` | AVIF OvertureCompanionSeenScene | the player's scene count with anyone else, plus one, as they last knew it |
| `0x85B` | AVIF OvertureCompanionAffinityTier | the highest level of their own affinity ever counted (0-4) |
| `0x860`-`0x863` | INFO | the companion greetings, in the approach's greeting topic `0x830` |
| `0x864`-`0x86F` | DIAL, INFO | the companion wheel: four player topics and lines, four reply topics |
| `0xE10`-`0xEF9` | INFO | the companion's answers, one set per persona and verdict behind each proposition |

`0x850`, `0x852` and `0x854` stay reserved for the variants not built (B's Trust and Devotion, A's
mirror). `0x859` and `0x85C`-`0x85F` are unused. `tools/make_overture_esp.py` has the whole id map, and
`finish()` checks every id actually written.

**`0x851` is PUBLISHED: never renumber it.** fo4-anatomy's `Anatomy:Arousal` (its commit ced951f) reads
`GetFormFromFile(0x851, "Overture.esp") as ActorValue` for a companion's Desire, read-only, 0 to 1, to
show arousal on the body (the owner's ask, 2026-09-23). Any other id another mod comes to read goes into
this list the same way.

## What is assumed, and what must be measured

- **ASSUMED**: every number (the feeders' sizes, the wanting bars, the moment's two hours and two days'
  cooldown); Ivy's affinity scale (200, from her message names).
- **MEASURED**:
  - vanilla companions' talk menus start from greetings;
  - who has a romance (`InfatuationRomanticMessage`);
  - Ivy's scene: fade at phase 1, the sex in phase 2 with a 12.5 s timer, the fade lifting at phase 3;
  - `Favor_Sex_Talk` has no way in.

  The evidence is in the decisions record.
- **MEASURE in game** (methodology §12; dev verbs `approach companion`, `approach moment`,
  `approach desire`):
  - a moment opening Overture's phase 4;
  - whether talking to a companion while sneaking reaches a greeting at all (O-23);
  - what Amazing Follower Tweaks does to the follower system's Companion alias;
  - Ivy's phase log and her recorded bond;
  - with scenes on: pausing her scene while AAF moves her, and her warper quest during a Rapport scene.
