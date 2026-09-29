---
name: gitnexus-area-scripts
description: "Skill for the Scripts area of fo4-overture. 59 symbols across 7 files."
---

# Scripts

59 symbols | 7 files | Cohesion: 87%

## When to Use

- Working with code in `scripts/`
- Understanding how verifyInstall, build_fuz, load_make_lip work
- Modifying scripts-related functionality

## Key Files

| File | Symbols |
|------|---------|
| `scripts/bearing-verify.mjs` | checkFile, checkManifest, checkPackageGates, checkRetiredHookKeys, checkSkillsStore (+13) |
| `scripts/bearing-ci.mjs` | blastRadius, collectDiff, detectChanges, num, git (+9) |
| `scripts/stage-voice.py` | build_fuz, load_make_lip, main, read_infos, walk (+3) |
| `scripts/bearing-token-benchmark.mjs` | answered, classicalCost, cypher, gn, graphCost (+2) |
| `scripts/bearing-agent.mjs` | currentBranch, git, resolveBaseRef, run, runAllowFail |
| `scripts/strip-pex.py` | main, pack_str, read_str, strip |
| `scripts/make-lip.py` | find_lipgen, main, one |

## Entry Points

Start here when exploring this area:

- **`verifyInstall`** (Function) — `scripts/bearing-verify.mjs:367`
- **`build_fuz`** (Function) — `scripts/stage-voice.py:121`
- **`load_make_lip`** (Function) — `scripts/stage-voice.py:114`
- **`main`** (Function) — `scripts/stage-voice.py:152`
- **`read_infos`** (Function) — `scripts/stage-voice.py:69`

## Key Symbols

| Symbol | Type | File | Line |
|--------|------|------|------|
| `verifyInstall` | Function | `scripts/bearing-verify.mjs` | 367 |
| `build_fuz` | Function | `scripts/stage-voice.py` | 121 |
| `load_make_lip` | Function | `scripts/stage-voice.py` | 114 |
| `main` | Function | `scripts/stage-voice.py` | 152 |
| `read_infos` | Function | `scripts/stage-voice.py` | 69 |
| `walk` | Function | `scripts/stage-voice.py` | 73 |
| `subrecords` | Function | `scripts/stage-voice.py` | 51 |
| `voice_gender` | Function | `scripts/stage-voice.py` | 101 |
| `wav_bytes` | Function | `scripts/stage-voice.py` | 108 |
| `answered` | Function | `scripts/bearing-token-benchmark.mjs` | 163 |
| `main` | Function | `scripts/strip-pex.py` | 51 |
| `pack_str` | Function | `scripts/strip-pex.py` | 30 |
| `read_str` | Function | `scripts/strip-pex.py` | 25 |
| `strip` | Function | `scripts/strip-pex.py` | 34 |
| `find_lipgen` | Function | `scripts/make-lip.py` | 40 |
| `main` | Function | `scripts/make-lip.py` | 77 |
| `one` | Function | `scripts/make-lip.py` | 56 |
| `blastRadius` | Function | `scripts/bearing-ci.mjs` | 110 |
| `collectDiff` | Function | `scripts/bearing-ci.mjs` | 78 |
| `detectChanges` | Function | `scripts/bearing-ci.mjs` | 92 |

## Execution Flows

| Flow | Type | Steps |
|------|------|-------|
| `Main → RuntimeSet` | cross_community | 4 |
| `Main → ReadStealth` | cross_community | 4 |
| `Main → Subrecords` | intra_community | 4 |
| `Main → Git` | intra_community | 3 |
| `Main → Num` | intra_community | 3 |
| `Main → Gn` | intra_community | 3 |
| `PickTargets → Gn` | intra_community | 3 |
| `Main → Run` | intra_community | 3 |
| `Main → CheckManifest` | cross_community | 3 |
| `Main → CheckSkillsStore` | cross_community | 3 |

## How to Explore

1. `context({name: "verifyInstall"})` — see callers and callees
2. `query({search_query: "scripts"})` — find related execution flows
3. Read key files listed above for implementation details
4. `explain({target: "<file or symbol>"})` — persisted taint findings (source→sink data flows), when indexed with `--pdg`
