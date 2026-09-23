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
| `variant-b-intimacy-track/` | Trust / Desire / Devotion, companion-only feeders, jealousy from Rapport's ledger | compiles |
| `variant-c-moments/` | the entry: a moment opens a second greeting (O-7's verified mechanism) | compiles |
| `variant-d-ivy-native/` | Ivy's own scenes bound to the store; her fade optionally animated through Rapport, PROBE mode first | compiles |
| `tools/check.ps1` | compiles `common` and each variant separately (run with pwsh 7) | |

**Recommended: B + C + D** (methodology §11.4). A lives inside B as its Trust input.

## Compatibility, in one paragraph

No companion mod is a master and none is patched (C1). Every foreign form is found at runtime —
`Game.IsPluginInstalled`, `Game.GetFormFromFile`, `ScriptObject.CastAs` / `CallFunction` — and a
lookup that fails turns that adapter off (C4). Their state outranks ours (C2), their content comes
first (C3), and we call their functions rather than writing their globals (C5). For Ivy that means her
anger refuses, her arousal opens a moment, her own Favor: Sex scene is what plays, and her own
`FlirtEvent` / `DenyEvent` hear about what happened in ours.

## Records the chosen variant needs (reserved, not built)

| id (Overture.esp) | record | used by |
| --- | --- | --- |
| `0x850` `0x851` `0x852` | AVIF OvertureCompanionTrust / Desire / Devotion | B |
| `0x853` | AVIF OvertureCompanionMoment | C (the greeting's condition) |
| `0x854` | AVIF OvertureMirroredAffinity | A |
| `0x855` | QUST OvertureCompanions, with Registry, the adapters and the variant's scripts | all |
| `0x856` | AVIF OvertureCompanionLastTick | B |
| `0x857` `0x858` | the companion greeting topic + INFO (conditions in `Moments.psc`) | C |
| `0x859` | the companion scene | C |

The stranger approach's own ids stop at `0x843` (and `0x900+`, `0x1000+`, `0x2000+` for lines);
`tools/make_overture_esp.py`'s `check_unique` must learn this range before anything is built in it.

## What is assumed, and what must be measured first

- **ASSUMED**: every number (the axes' rates, the gates, jealousy by persona), Ivy's affinity scale
  (200, from her message names), which phase of her scene is the fade (3, from a string table).
- **MEASURE before relying on it**: a Rapport scene with the player in it at all (the stranger module
  needs this first too); pausing Ivy's scene while AAF moves her; her warper quest during an AAF scene;
  `OnPhaseBegin`'s index base (the probe logs it).
