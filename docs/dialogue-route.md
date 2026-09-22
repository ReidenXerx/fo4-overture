# The dialogue route

The three things that decided whether Overture is buildable at all, each settled on 2026-09-22.
`fo4-rapport/docs/relationship-and-personas.md` N-2 called dialogue "the only part of the roadmap
that could fail outright". It does not fail. Here is why, and what is still unproven.

---

## 1. The player's half — solved by XDI, not by us

**N-5 open question 5** asked whether the player's side of a custom conversation should be silent,
text-only, or scavenged from vanilla. Fallout 4 voices its protagonist and we cannot match that
actor, so a custom topic would leave the player mute mid-conversation with the camera pointed at
their still face.

**XDI (Extended Dialogue Interface) exists for exactly this.** It:

- removes the hard-coded four-option limit, so any number of player options can be offered — which
  our four registers want anyway, plus whatever a later stage adds;
- lets a mod add **unvoiced player lines** as a first-class case, with no empty voice files to fake;
- **hot-patches the dialogue camera to stay on the NPC** rather than cutting to the silent player.

Authoring is otherwise identical to vanilla dialogue. There is no XDI API to code against: you
author normal `DIAL`/`INFO` records and XDI changes how they are presented.

**The trap.** `XDI.esm` ships exactly two keywords — `XDI` and `XDI_AllowPlayerVoice`. The second
one **does not work**; mods that depended on it had to ship a patched DLL. Do not build on it.

**Dependency.** XDI is a hard requirement for Overture's dialogue to present correctly. It is
already in this machine's load order at index 4. Link to its Nexus page rather than bundling it —
that is what its author asks for.

## 2. Lip sync — Bethesda's own tool, already on disk

**N-5 open question 6** asked whether `.lip` files can be generated outside the Creation Kit, and
noted it "stands harder for Overture than it did for R-9": a scene bark blocks the face anyway, but
an actor in conversation with a still mouth is conspicuous.

**The game ships the tool.** `<game>/Tools/LipGen/LipGenerator/LipGenerator.exe`, with
`FonixData.cdf` beside it and `LIPFuzer.exe` next door for the fuz step.

```
LipGenerator <wav> "<spoken text>" [-Language:USEnglish] [-GestureExaggeration:1.0]
             [-OutputFileName:...] [-LipAnimDelay:..] [-LipAnimSpeed:..]
```

`scripts/make-lip.py` wraps it over the whole line bank.

**Measured**, because neither of these is documented anywhere:

- It accepts a **44.1kHz mono 16-bit** wav directly. The widely-cited alternative — Nukem9's
  `FaceFXWrapper` — demands 16kHz and a resample step first. Ours do not need one. `FaceFXWrapper`
  remains a viable fallback and we already have the `FonixData.cdf` it needs.
- The `Tools/LipGen/Readme.txt` tells you to move the 32-bit Creation Kit to the game root and
  generate lip sync through its GUI. **That advice is for the CK; `LipGenerator.exe` beside it is a
  plain CLI and needs none of it.** Reading only the readme would have concluded the opposite.

**What is NOT yet proven.** A `.lip` has been *produced* — 1,741 bytes from a real line, and 1,981
from another. Whether the game **accepts** it and the mouth actually moves is untested, because it
needs the game. Until somebody watches a face, this is an untested output rather than a working
pipeline. It is written down this way on purpose: the same project has twice had a confident static
count contradicted by the running game.

## 3. The topic records — prior art exists, and it is NOT the same shape

`fo4-rapport/tools/make_dialogue.py` builds voiced topics and its scars carry over:

- **The nesting.** A `DIAL` never sits at a plugin's top level. It lives inside the owning quest's
  children: `GRUP type 0 QUST > QUST > GRUP type 10 <quest> > DIAL > GRUP type 7 <topic> > INFO`.
  A top-level `DIAL` is a record the engine never looks at.
- **A topic is inert without a Dialogue Branch.** 211 topics resolved, their quest ran, `Say` was
  called, and nothing was ever spoken — until one `DLBR` existed and every topic pointed at it
  through `BNAM`. Four confident theories were wrong before a field-by-field diff against a line the
  game really speaks found it first time.
- **Not localized.** `Fallout4.esm` sets TES4 flag `0x80` so its `NAM1` holds a string-table id.
  Ours does not, so `NAM1` takes the literal text. Copying the base game's `NAM1` puts four bytes of
  garbage in every subtitle.
- **No voice-type condition.** With no `CTDA`, any speaker may say the line and the engine looks the
  audio up under *their* voice type — so one line serves all 32 types, and a type with no file
  degrades to **subtitle**, never to silence or to the wrong voice. This is what makes shipping six
  voices safe.

**The part that does not carry over:** Rapport's topics are `Say`-driven barks. Overture needs
**player dialogue**, which is a different record entirely — and the diff has now been done. It is
in [`player-topic-shape.md`](player-topic-shape.md), and the headline is that a player option is
**scene dialogue** (`SNAM` = `SCEN`), not a free-standing topic. 96% of every player prompt in
`Fallout4.esm` lives there. Building loose topics would have produced records the engine never
looks at, which is the same class of mistake as putting a `DIAL` at the top level.

---

## First in-game run, 2026-09-23

The plugin loads and the scene runs. The options do not appear yet.

**What is verified working:**

| | |
| --- | --- |
| `Overture.esp` loads, no missing-content box | yes |
| The quest starts itself and `OnQuestInit` fires | yes |
| The script resolves `F4MCP.esp` and registers as an addon | yes — `addons` lists `overture: approach` |
| `Game.GetFormFromFile(0x801, "Overture.esp")` resolves the scene | yes |
| `Scene.GetOwningQuest()` returns our quest | **yes — the scene's `PNAM` wired correctly** |
| `ReferenceAlias.ForceRefTo()` on the script-filled alias | yes |
| `Scene.IsPlaying()` after `Start()` | **yes** |

So every record this repo generates is accepted by the engine, the alias shape is right, and the
scene is genuinely running. That is the whole structural question answered.

**What does not work:** talking to the aliased actor shows no Overture options. The scene plays and
its dialogue action presents nothing.

**A wrong conclusion, corrected in the same session.** The first run reported
`state <actor> scene=False` and I read that as "the scene did not start". It means the *actor* is not
in a scene, which is a different fact. Adding `Scene.IsPlaying()` and `GetOwningQuest()` to the verb
showed the scene was playing the whole time. **`Scene.Start()` is void, so "scene started" was never
something the code could know** — the first version of the verb said it anyway, which is exactly the
kind of claim that sends you debugging the wrong thing.

**Also learned:** Magnolia is a useless test subject. She is a singer and permanently inside a vanilla
performance scene (`sceneForm=00074D26`, a `Fallout4.esm` form). Check `state <id>` for
`scene=False` before choosing anybody.

**The next suspects**, in order, none of them tested:

1. **The scene has one phase and one action; the template has two of each.** The second action is
   type 4 with `STSC`/`HTID`, and what it does is unknown. A dialogue action may need it.
2. **There is no Player alias.** `FFGoodneighbor02` carries `Player` as alias index 2. A dialogue
   action plausibly needs both ends, and ours only has the target.
3. **`DTGT`** is set to the target alias, copied from the template where `ALID` and `DTGT` were both
   alias 3. If `DTGT` means "who is spoken to", that reading cannot be right and the template needs
   re-reading rather than copying.
4. The verbatim action `FNAM` (`0x00228000`) may encode something specific to that scene.

The honest position is that the record layer is proven and the scene *semantics* are not understood
yet. That is a smaller and better-defined problem than the one this file started with.

## The greeting is what starts the scene (2026-09-23)

The first run left four suspects. Two of them were right, and both were sitting in the template I had
already dumped and not read far enough down.

**1. A `GREE` topic whose INFO carries `TSCE`.** `FFGoodneighbor02`'s greeting INFO holds
`TSCE = 0x0010BECF` — the form id of its own scene. **`TSCE` is what starts the scene when the player
talks to the actor.** Without it, a filled alias and a running scene publish nothing, which is exactly
what the first run showed: quest running, alias filled, `IsPlaying` true, and not one option.

**2. The `SCEN` belongs INSIDE the quest's child group**, as a sibling of the topics. Ours was in a
top-level `GRUP 'SCEN'`. Measured: `SCEN 0010BECF` sits in `FFGoodneighbor02`'s `GRUP type 10`.

**3. One phase and one action were not enough.** With both fixes in, the owner reported the actor
**stopping his idle for about a second and then resuming it** — a scene starting and immediately
ending. The template has two phases and two actions; ours had one of each. With the second phase and
the type-4 action added, our scene's field sequence is **identical to the template's** apart from a
single `CTDA` that is deliberately absent (see below).

Still unproven in game: whether the options now appear. The test was interrupted by an unrelated
crash — see `Documents/FO4-Investigations/backpacks-perk-crash/`, which is a pre-existing fault whose
earliest instance predates this repo by two days.

### The greeting is UNCONDITIONED, and must not ship that way

The template's greeting carries four `CTDA` conditions — three quest-stage checks and one naming the
actor. Ours carries none, because decoding FO4's 32-byte `CTDA` well enough to write one is a
separate job and copying the template's verbatim would put its quest and actor form ids into our
plugin.

The cost: **while Overture's quest runs, every actor may offer the greeting.** For a dev test that is
convenient — talk to anybody. For anything shipped it is unacceptable, and O-7 (the registers appear
when you talk to an eligible NPC) cannot be built until the condition exists.

## Status

| | |
| --- | --- |
| Player's unvoiced half | **Solved** — XDI, verified in its own docs and its shipped keywords |
| Lip generation | **Tool proven, output unverified in game** |
| Bark topic records | Prior art, working, in `fo4-rapport` |
| Player topic records | **Shape derived** from real records — they are scene dialogue, see `player-topic-shape.md`. Builder not written. |
| The lines | 128 authored, 6,177 characters, matrix complete |
