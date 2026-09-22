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

Early. The lines are written and the route is proven; the plugin is not built yet.

- **128 lines**, 6,177 characters — every persona × register cell authored, four lines each, across
  four stages, plus greetings, recoils, proposals, farewells and returning lines.
- **The player's silent half is solved** by XDI, which also keeps the dialogue camera off the
  player's still face.
- **Lip sync is a scripted step** using the `LipGenerator` that ships with the game — no Creation
  Kit, no download.
- **Player dialogue records are not built yet**, and will be derived by diffing a real one out of
  `Fallout4.esm` rather than guessed at.

`docs/dialogue-route.md` has the detail, including what is proven and what merely looks proven.

## Requirements

- Fallout 4 1.10.163 (old-gen) and F4SE
- [Rapport](https://github.com/ReidenXerx/fo4-rapport)
- [Extended Dialogue Interface (XDI)](https://www.nexusmods.com/fallout4/mods/27216) — required, and
  linked rather than bundled at its author's request

## Building

```bash
python tools/make_overture_esp.py build/Overture.esp   # the plugin
python scripts/make-lip.py                             # .lip for every rendered line
```

The plugin currently builds the **thinnest loop**: one quest, one scene, four player options in the
four wheel slots, one placeholder NPC reply each. It has never been loaded by the game. Every byte
shape in it is transcribed from `FFGoodneighbor02`, and round-trips through this repo's own readers,
but reading your own output back proves the writer agrees with the reader and nothing more.

## Licence

GPL-3.0, same as Rapport and Chemistry.
