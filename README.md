# Overture

An approach made to somebody, and a musical opening.

A Fallout 4 mod where you walk up to someone and try. You pick **how** you approach — offer them
something, charm them, be blunt, or just stay and say nothing — and whether it lands depends on who
they are. You are never told who they are. Reading the person is the game.

Overture is downstream of [Rapport](https://github.com/ReidenXerx/fo4-rapport): it reads and writes
the same relationship store and owns none of the mechanism. Anything it needs that a third mod would
also want belongs in Rapport, not here.

## The model

| register | what you do | lands on |
| --- | --- | --- |
| `offer` | caps, a gift, something material | mercantile |
| `charm` | fancy words, patience, a compliment | romantic |
| `blunt` | crude, direct, explicit | vulgar |
| `linger` | say little, stay, simply be present | reticent |

Each register lands on exactly one persona and misses the other three. A persona is derived from
the NPC and is stable for that character across a playthrough.

**Place overrides both.** An intimate register in a public room recoils *even on the persona it
would otherwise land with*. The vulgar NPC likes being propositioned and still does not want it
shouted across a market. That is what makes place load-bearing rather than decorative.

## Status

Early, and running. What the game has actually done (`docs/dialogue-route.md` has every measurement):

- **Talking to someone opens it** (O-7): adults, humans and ghouls, nobody who has ever been your
  companion, once a game day (O-8) — then their own dialogue takes over. No hotkey, no menu, no verb.
- **The NPC answers in their persona**, with every authored variant rotating, and **place overrides
  it**: the crude register recoils in a crowded room, even on the persona it would have landed with.
- **Three stages in one conversation** (the `--stages 3` build): a land runs on into the next wheel, a
  miss ends it, a returning NPC starts at stage 2, and a proposition in the wrong register is refused.
- **Every reply now writes to Rapport's relationship store** — built, and read by the game on all 40
  reply lines, and watched in game on 2026-09-23: two lands, +0.05 and +0.07 of the distance left.
- **The Narrator tells you how it went** (O-9): one line from Rapport's Narrator when a conversation
  ends, saying what your words did and hinting at what to try next. It never says who they are.
  Verified in game.
- **The nameless get names** (O-10): a Settler or a Drifter you approach for the first time gets a
  name, and keeps it through saves. People with real names keep theirs. Verified in game (Rapport 0.2.1).
- The player's half is text through XDI, which keeps the camera off the player's still face; lip sync
  is a scripted step with the game's own `LipGenerator`.

Built, not yet run in game: after a yes, or once you are close enough, a conversation opens straight at
the proposition, and then any way you ask gets their real answer. A bond of 0.75 and a scene together make you lovers to everyone else too (Chemistry
treats your lover as spoken for), and falling out ends it. A lover hears about your other scenes, takes it the way
their persona would, and tells you so in their own words the next time you talk. "Not now" and "not here" mean you can ask again later that day.
Every number is on the MCM page.

What it is becoming: `docs/methodology.md` — the whole design, the numbers it writes and why, the
companion module (`companions/`, four variants, none shipped), and the owner's open questions.

## Requirements

- Fallout 4 1.10.163 (old-gen) and F4SE
- [Rapport](https://github.com/ReidenXerx/fo4-rapport) 0.2.1 or newer
- [Extended Dialogue Interface (XDI)](https://www.nexusmods.com/fallout4/mods/27216) — required, and
  linked rather than bundled at its author's request
- MCM, for the settings page. Without it, the built-in numbers apply and a yes starts no scene.
- F4MCP is NOT required: it is the dev channel (`approach ...` verbs), in its own script,
  `Overture:Dev`, so without it only the verbs are missing.

## Building

```bash
python tools/make_overture_esp.py build/Overture.esp              # the verified one-exchange plugin
python tools/make_overture_esp.py build/Overture.esp --stages 3   # stages 1-3 (data half verified)
pwsh scripts/build-papyrus.ps1                                     # Overture:Approach, Overture:Reply, Overture:Dev
python tools/make_mcm.py                                           # the MCM page and its settings.ini, from the settings table
pwsh scripts/deploy-dev.ps1                                        # copy into the Vortex dev mod (game closed)
python scripts/make-lip.py                                         # .lip for every rendered line
pwsh companions/tools/check.ps1                                    # compile-check the companion scaffolds
```

Every byte shape in the plugin is transcribed from a vanilla record and says which one; where a
field is not understood it is copied verbatim and marked. Reading our own output back only proves
the writer agrees with the reader — the game is the test, and the test results are in
`docs/dialogue-route.md`.

## Licence

GPL-3.0, same as Rapport and Chemistry.
