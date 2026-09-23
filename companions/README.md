# Companions — the module's scaffolds

N-7's module: companions get a relationship system of their own, bound to Rapport's store, with
modifiers no ordinary NPC has. The reasoning, the measured facts about vanilla companions and Ivy,
the compatibility rules C1-C5 and the recommendation are all in `docs/methodology.md` §11. This
folder is the code that goes with it.

**Nothing here ships.** `scripts/build-papyrus.ps1` compiles `papyrus/` only; these compile into
`build/companions-check/` and nowhere else. The owner picks a variant; the chosen one moves into
`papyrus/` and gets its records in `tools/make_overture_esp.py`.

## Layout

| folder | what | status |
| --- | --- | --- |
| `common/` | `Adapter` (the questions), `EngineAdapter` (fallback), `VanillaAdapter` (CompanionActorScript + CA_Affinity), `IvyAdapter` (her globals and functions), `Registry` (who is a companion, which adapter) | compiles |
| `variant-a-affinity-mirror/` | their affinity IS the relationship; changes mirrored into the store | compiles |
| `variant-b-intimacy-track/` | Trust / Desire / Devotion, companion-only feeders, jealousy from Rapport's ledger -- a second opinion of closeness beside the store (the R-1 objection) | compiles |
| `variant-b-lite/` | **the store IS the relationship**: companion-only modifiers are EVENTS written into it (their affinity's thresholds, days together, fights, jealousy); Desire the one state of ours | compiles -- **recommended** |
| `variant-c-moments/` | the entry: a moment opens a second greeting (O-7's verified mechanism) | compiles |
| `variant-d-ivy-native/` | Ivy's own scenes bound to the store; her fade optionally animated through Rapport, PROBE mode first | compiles |
| `tools/check.ps1` | compiles `common` and each variant separately (run with pwsh 7) | |

**Recommended: B-lite + C + D** (methodology §11.4). B-lite came out of the design review (2026-09-23): B's Trust and Devotion were Overture's own opinion of closeness beside the store, which R-1 exists to prevent; B-lite writes the same modifiers INTO the store as events and keeps only Desire, a state. A's gates (their own affinity and romance) live inside it.

## Compatibility, in one paragraph

No companion mod is a master and none is patched (C1). A companion no adapter vouches for is
invisible (C6): the vanilla adapter claims only the base game's own companions, so a mod companion with
voiced content of its own never hears Overture's lines as subtitles over it. Every foreign form is found at runtime —
`Game.IsPluginInstalled`, `Game.GetFormFromFile`, `ScriptObject.CastAs` / `CallFunction` — and a
lookup that fails turns that adapter off (C4). Their state outranks ours (C2), their content comes
first (C3), and we call their functions rather than writing their globals (C5). For Ivy that means her
anger refuses, her arousal feeds desire, and Overture opens NO conversation of its own for her: her own
Favor: Sex scene is the moment and what plays (variant D binds it to the store). Her `FlirtEvent` /
`DenyEvent` are there for whatever does talk to her.

## Records the chosen variant needs (reserved, not built)

| id (Overture.esp) | record | used by |
| --- | --- | --- |
| `0x850` `0x851` `0x852` | AVIF OvertureCompanionTrust / Desire / Devotion | B (B-lite uses Desire only) |

**`0x851` is PUBLISHED: never renumber it.** fo4-anatomy's `Anatomy:Arousal` (its commit ced951f) reads
`GetFormFromFile(0x851, "Overture.esp") as ActorValue` for a companion's Desire, 0 to 1, read-only, to
show arousal on the body (the owner's ask, 2026-09-23). Until the companion module ships, today's
Overture.esp has no `0x851` and the lookup returns None. Any other id another mod comes to read goes
into this list the same way.
| `0x853` | AVIF OvertureCompanionMoment | C (the greeting's condition) |
| `0x854` | AVIF OvertureMirroredAffinity | A |
| `0x855` | QUST OvertureCompanions, with Registry, the adapters and the variant's scripts | all |
| `0x856` | AVIF OvertureCompanionLastTick | B, B-lite |
| `0x85A` | AVIF OvertureCompanionSeenScene (per-companion jealousy watermark) | B, B-lite |
| `0x85B` | AVIF OvertureCompanionAffinityTier | B-lite |
| `0x857` `0x858` | the companion greeting topic + INFO (conditions in `Moments.psc`) | C |
| `0x859` | the companion scene | C |

The stranger approach's own ids run to `0x84C` (and `0x900`-`0xD5F` for lines; `0x846` and `0xE00`-`0xE0F`
are retired). `tools/make_overture_esp.py` has the whole map. `tools/make_overture_esp.py`'s `finish()` checks every id actually written for
duplicates, so a collision in this range is a build error, not an InitGameDataThread crash.

## What is assumed, and what must be measured first

- **ASSUMED**: every number (the axes' rates, the gates, jealousy by persona), Ivy's affinity scale
  (200, from her message names), which phase of her scene is the fade (3, from a string table).
- **MEASURE before relying on it**: a Rapport scene with the player in it at all (the stranger module
  needs this first too); pausing Ivy's scene while AAF moves her; her warper quest during an AAF scene;
  `OnPhaseBegin`'s index base (the probe logs it).
