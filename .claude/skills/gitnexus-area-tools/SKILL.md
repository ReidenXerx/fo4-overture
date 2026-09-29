---
name: gitnexus-area-tools
description: "Skill for the Tools area of fo4-overture. 160 symbols across 21 files."
---

# Tools

160 symbols | 21 files | Cohesion: 86%

## When to Use

- Working with code in `tools/`
- Understanding how build, check_unique, condition work
- Modifying tools-related functionality

## Key Files

| File | Symbols |
|------|---------|
| `tools/make_overture_esp.py` | build, check_unique, condition, enabled_global, field (+28) |
| `tools/overture_stages.py` | a_lover, ask_perk, companion_greetings, companion_here, companions_quest (+19) |
| `tools/check_gendered.py` | all_gendered_fence, banks, build, check, expect_refusal (+12) |
| `tools/greet_scene_aliases.py` | fields, main, alias_blocks, kind_of, visit (+2) |
| `tools/quest_anatomy.py` | decompress, dump_record, fields, find_quest_group, main (+2) |
| `tools/player_topic_shape.py` | fields, main, sink, show, text_of (+1) |
| `tools/smallest_dialogue_quest.py` | decompress, fields, main, visit2, visit (+1) |
| `tools/action_flags.py` | fields, main, visit, names, walk |
| `tools/ctda_param_types.py` | fields, main, index, survey, walk |
| `tools/ctda_survey.py` | fields, main, visit, parse, walk |

## Entry Points

Start here when exploring this area:

- **`build`** (Function) — `tools/make_overture_esp.py:911`
- **`check_unique`** (Function) — `tools/make_overture_esp.py:894`
- **`condition`** (Function) — `tools/make_overture_esp.py:452`
- **`enabled_global`** (Function) — `tools/make_overture_esp.py:311`
- **`field`** (Function) — `tools/make_overture_esp.py:175`

## Key Symbols

| Symbol | Type | File | Line |
|--------|------|------|------|
| `build` | Function | `tools/make_overture_esp.py` | 911 |
| `check_unique` | Function | `tools/make_overture_esp.py` | 894 |
| `condition` | Function | `tools/make_overture_esp.py` | 452 |
| `enabled_global` | Function | `tools/make_overture_esp.py` | 311 |
| `field` | Function | `tools/make_overture_esp.py` | 175 |
| `finish` | Function | `tools/make_overture_esp.py` | 1074 |
| `greeting` | Function | `tools/make_overture_esp.py` | 628 |
| `greeting_info` | Function | `tools/make_overture_esp.py` | 723 |
| `line` | Function | `tools/make_overture_esp.py` | 388 |
| `opening_global` | Function | `tools/make_overture_esp.py` | 300 |
| `persona_global` | Function | `tools/make_overture_esp.py` | 274 |
| `public_global` | Function | `tools/make_overture_esp.py` | 288 |
| `quest` | Function | `tools/make_overture_esp.py` | 243 |
| `record` | Function | `tools/make_overture_esp.py` | 218 |
| `scene` | Function | `tools/make_overture_esp.py` | 802 |
| `sex_conditions` | Function | `tools/make_overture_esp.py` | 498 |
| `topic` | Function | `tools/make_overture_esp.py` | 362 |
| `vmad` | Function | `tools/make_overture_esp.py` | 193 |
| `vmad_scripts` | Function | `tools/make_overture_esp.py` | 198 |
| `wstring` | Function | `tools/make_overture_esp.py` | 187 |

## Execution Flows

| Flow | Type | Steps |
|------|------|-------|
| `Main → Wstring` | cross_community | 6 |
| `Player_stage → Wstring` | cross_community | 6 |
| `Main → Fields` | intra_community | 5 |
| `Main → Fields` | intra_community | 5 |
| `Main → Fields` | intra_community | 5 |
| `Main → U32` | intra_community | 5 |
| `Companion_wheel → Wstring` | cross_community | 5 |
| `Main → Fields` | intra_community | 4 |
| `Main → Names` | intra_community | 4 |
| `Main → Fields` | intra_community | 4 |

## How to Explore

1. `context({name: "build"})` — see callers and callees
2. `query({search_query: "tools"})` — find related execution flows
3. Read key files listed above for implementation details
4. `explain({target: "<file or symbol>"})` — persisted taint findings (source→sink data flows), when indexed with `--pdg`
