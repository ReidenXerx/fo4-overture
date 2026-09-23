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

### The greeting is now conditioned on the alias

It was not, for one build, and every actor in the game offered it while the quest ran. That is fixed,
and the fix is the condition format **measured rather than guessed**.

**Function 566 takes an alias index.** Of its 4,806 uses on dialogue INFOs in `Fallout4.esm`, **4,782
have a `param1` inside the owning quest's own alias range** (`0 .. ANAM-1`). The 24 that do not are
all `0xFFFFFFFE`, a sentinel. A number meaning anything else would have no reason to respect a
per-quest bound that closely. `tools/ctda_alias_check.py` is the check, so it is re-runnable rather
than a claim.

The `CTDA` layout, derived from four real conditions and checked against every dialogue condition in
the base game:

```
0       operator and flags (0x00 = equal to)
1-3     unused
4-7     comparison value, float
8-9     function index, uint16
10-11   padding
12-15   parameter 1
16-19   parameter 2
20-23   run-on type (0 = Subject, the speaker)
24-27   reference
28-31   unused
```

Overture's greeting now carries exactly one: function **566**, `param1` = the Target alias index,
value **1.0**, run on **Subject**. So it is offered only by the actor the quest has aliased.

A detail worth recording: the real records carry non-zero bytes in both padding runs — `7a d2 96` and
`d2 96`, *identical across unrelated conditions in unrelated quests*. That is uninitialised memory
written straight to disk by the Creation Kit. We write zeros.

### Two other things the survey settled

- **Function 72 is `GetIsID`** — its `param1` is a real form id (11% small, and those are the small
  base-game ids). The template's greeting uses it to name Daisy specifically.
- **Function 70** takes 0 or 1 and runs on the target, which is the shape of a sex check.

## IT WORKS — 2026-09-23, measured through XDI

```
dialogue with Whitechapel Charlie (00022688): 4 option(s)
  [0] (prompt "(Say nothing. Stay where you are.)")
  [1] (prompt "Nobody out here looks at you properly, do they.")
  [2] (prompt "I brought you something.")
  [3] (prompt "I want to fuck you. Here, against that wall, I don't care.")
```

Every record derived in this document is correct: the quest, the script-filled alias, the four `SCEN`
topics, the `GREE` topic whose `TSCE` starts the scene, the two-phase two-action structure, and the
scene living inside the quest's child group. The dialogue loop is real.

### And the first read of it found a bug nothing in the record would show

`optionID` is the vanilla wheel slot: **Positive 0, Negative 1, Neutral 2, Question 3.** Ours came
back:

| register | our SCEN field | optionID | the slot it actually landed in |
| --- | --- | --- | --- |
| charm | `PTOP` | 0 | positive — correct |
| offer | `NTOP` | **1** | **negative** — wrong |
| blunt | `NETO` | **2** | **neutral** — wrong |
| linger | `QTOP` | 3 | question — correct |

**`NTOP` is NEGATIVE and `NETO` is NEUTRAL.** The names read like "Neutral TOPic" and "NEgative
TOpic"; that reading is wrong, and this document asserted it for two days. O-4 wants offer in neutral
and blunt in negative, so the first working build had them exactly swapped — the crude line sitting
in the neutral slot and the gift in the aggressive one.

Nothing in the plugin would ever have shown this. The record is valid either way, the options appear
either way, and only the slot NUMBER the engine hands back distinguishes them. It took a tool that
prints what the engine holds rather than what the author intended.

### Two other things worth carrying

- **The response text is re-rolled on every read.** XDI hands back a fresh variant each time it is
  asked, so match a line by its **prompt or its position**, never by its response text.
- **`choose` is refused while the NPC is still speaking.** XDI returns false until the engine is
  awaiting player input — roughly 6s after the list appears. Retry rather than treating the first
  refusal as a failure.

## Both fixes verified, and the whole loop runs (2026-09-23)

**The choice is taken and control comes back.** Selecting an Overture option played the NPC's reply,
ended our scene, and handed the conversation back: `playerScene` moved from `27000801` (ours) to
`00075E89` (Charlie's own), and the menu became his normal bartender options. So Overture inserts
itself into a vanilla conversation and gets out again without breaking it.

**The alias condition works, tested both ways on the same NPC:**

| | what the menu showed |
| --- | --- |
| alias NOT filled | Charlie's own four options only — none of ours |
| alias filled with Charlie | Overture's four |

Before the `CTDA` every actor in the game offered the greeting. Now only the aliased one does.

**The slot fix is confirmed by the numbers the engine hands back:**

| register | optionID | slot |
| --- | --- | --- |
| charm | 0 | positive |
| blunt | **1** | **negative** |
| offer | **2** | **neutral** |
| linger | 3 | question |

That is O-4 exactly. Before the swap, blunt was in neutral and offer in negative.

## The matrix works — 2026-09-23

> **CORRECTION, same night.** The conditions worked; the speaker was wrong. Every "he answers" below
> was read from XDI's option list, whose line is the text of the PLAYER's INFO. These builds put the
> NPC's reply in the player's own line, so picking an option would have had the PLAYER say it. Fixed
> and re-verified with the engine's own speaker events — see "The NPC was never speaking" below.

Sixteen conditioned replies, four registers x four personas, gated on a global the script sets from
Rapport's own persona before the scene starts.

Whitechapel Charlie, whom Rapport calls **vulgar** (`persona=2`):

| the player picks | he answers | |
| --- | --- | --- |
| *I want to fuck you. Here, against that wall, I don't care.* | "Finally. Somebody who says fuck like it is not a swear word." | **lands** |
| *I brought you something.* | "Caps? I was hoping you wanted to fuck, not shop." | misses |
| *Nobody out here looks at you properly, do they.* | "All that talk and you still have not said the word fuck once." | misses |
| *(Say nothing. Stay where you are.)* | "Standing there quiet is not going to get my legs open." | misses |

The register that lands is the one his persona wants, and he is never named as vulgar anywhere the
player can see. That is the whole mechanic, running.

**Function 74 is `GetGlobalValue`.** MEASURED: of its 7,258 uses on dialogue INFOs in
`Fallout4.esm`, **100% have a `param1` resolving to a `GLOB` record**, run-on is always 0, and op
`0x00` with a value means equals. `tools/ctda_param_types.py` builds a form-id-to-record-type map of
the whole master and is the check.

**The global is set BEFORE the scene starts**, and that ordering is load-bearing: the conditions are
read when the options are built, so a global set afterwards is a global set too late.

**One coupling to watch.** The persona order lives in two places — `PERSONAS` in
`tools/make_overture_esp.py` and the name-to-index mapping in `Overture:Approach`. If they drift,
every NPC gets somebody else's reply **and nothing errors**. Both carry a comment saying so.

## Place overrides persona — O-4's recoil, running (2026-09-23)

> **Same correction as above**, and one more: once every reply was flagged Random, "order is the
> mechanism" stopped being enough, because Random pools a run of consecutive Random lines. Both are
> fixed and re-verified below: 5 of 5 public blunt picks drew a recoil, never a normal reply.

In the Third Rail, with **20 people watching**, Whitechapel Charlie (vulgar) answers the blunt
register with:

> "I want your hands on me and there are twelve people watching."

instead of the line he gives when it lands. Same NPC, same persona, same words from the player. The
room decided.

**The chain, end to end:** Rapport's actor scan publishes a crowd snapshot under a lock →
`Rapport:Core.ObserversNear(formID)` → Overture's script compares it to Rapport's own
`ObserverTolerance()` → sets `OverturePublic` → a second `CTDA` on the recoil lines.

**Order is the mechanism.** The recoil lines are emitted FIRST in the blunt topic. The engine takes
the first INFO whose conditions pass, so a recoil ahead of the normal reply wins when the room is
public and is skipped when it is not. Put them after and they would never be reached.

**Two CTDAs AND.** Each recoil carries persona *and* public, with the OR bit clear, so both must pass.

**-1 is not zero.** `ObserversNear` returns -1 when no scan has published yet, and the script says
"observers unknown, assuming public" rather than rounding it down. Seen in practice: for about the
first 25 seconds after a load the snapshot is empty, and treating that as "nobody is watching" would
have had NPCs propositioned across a crowded bar every time the player reloaded.

## The NPC was never speaking — and the three other things the engine does (2026-09-23, night)

Measured with F4MCP's `[event topic]` source, which names the speaker and the form id of every line
the engine plays. That turned "what XDI's list says" into "who said which record".

**1. A player option's INFO is what the PLAYER says.** In vanilla, on Magnolia: `Richard (00000014)
begins line 00075370` — the chosen option, in the player's voice — then `Magnolia begins line
001103B6`, her answer, from a different record. XDI's list shows the player INFO's text (xdi
`src/DialogueEx.cpp:265-295`). The NPC answers from the scene action's `NPOT/NNGT/NNUT/NQUT` topics,
which Overture had written as 0. So every reply in the lines bank had been the player's line.

Rebuilt the template's way: each player topic holds ONE line, the player's own words (`spoken` in
`voice/player-prompts.json`; empty for linger), and four new reply topics hold the persona lines. On
Charlie, picking offer:

```
Richard (00000014)   begins line 27000901   "I brought you something."
Whitechapel Charlie  begins line 27001031   the vulgar persona's answer
```

**2. Variants rotate.** ENAM `0x02` is Random (xEdit, `wbDefinitionsFO4.pas`). Six picks of offer:
`1031 1030 1030 1031 1031 1031` — both lines, at random, not alternating.

**3. Random pools a RUN, so the recoil needed a fence — and it holds.** With every line Random, a
public room would pick among recoils and normal replies alike. Each persona's last recoil now carries
Random End (`0x20`), the base game's fence (706 of its 722 Random End lines close a Random run;
`tools/random_groups.py`). Five blunt picks with 21 watching: `2010 2010 2011 2010 2011` — recoils
only, rotating, never the normal reply.

**4. The copied greeting was Say Once (`0x04`).** It opened the scene once per session; on the second
approach Charlie's own greeting won. The template carries two greetings for this, one Say Once and one
repeatable. Ours is now repeatable — which exposed the next problem below.

### Traps found on the way

- **`choose n` takes XDI's LIST position**, which runs Question, Positive, Negative, Neutral: linger 0,
  charm 1, blunt 2, offer 3. It is not the wheel slot.
- **A harness-opened dialogue can hang for ever.** On Charlie, from the end of the bar with the
  crosshair on a door, the engine never raised `awaitingPlayerInput`: every choice refused, Charlie
  looping his waiting-for-player (`WFPI`) lines, no list on screen, and it did so in HIS OWN vanilla
  scene too. Walked to 90u with `look 00022688` / `look off` — "WHITECHAPEL CHARLIE, E) TALK" under the
  crosshair — it takes the choice at +5 s. Charlie sits in bar furniture (`sit=3`). A player pressing E
  always has the NPC under the crosshair, so this is a harness trap first; whether a real player can
  hit it is open. The owner called the crosshair before the data did.
- **RETRACTED the same hour: "Face Target causes the hang."** Our action carried the template's
  `0x00228000` (Face Target, Headtrack Player, Camera Speaker Target) where Charlie's own scene carries
  `0x00200800` (`tools/action_flags.py`). Plausible, and dead: his own scene hung identically from the
  same spot. The build keeps `0x00200000` only because that is the configuration verified above.
- **Stopping the quest mid-dialogue crashed the game** (Windows error 1000 in KERNELBASE, no Addictol
  log), about a second after `stopquest OvertureDialogueQuest` with our scene's dialogue open. Prime
  suspect, not proven. End the dialogue first.

### Fixed the same night: one exchange, then theirs (owner poll: hand back to their own dialogue)

**The approach never let go.** After the reply our scene ended, the conversation re-greeted 140 ms
later, our repeatable greeting won again because the alias still held the NPC, and the player was back
at Overture's four options for ever.

Now the greeting also needs `OvertureArmed == 1` (GLOB `0842`). `approach ... noscene` arms it, and
`Overture:Approach` polls the scene every 0.5 s: the moment it is seen PLAYING it disarms, seconds
before the reply ends, so the re-greet goes to the NPC's own greeting; once it has stopped, the alias
is let go. A poll, not the scene's `OnEnd`, because a queued event is not guaranteed to land inside
those 140 ms. Unused, it disarms itself after 120 s. Verified on Charlie:

```
Charlie   27000831  "..."                               our greeting, armed
Richard   27000901  "I brought you something."
Charlie   27001031  "Put your money away and tell me what you want to do to me."
[dialogue] closed -> re-greet:
Charlie   0010D5D7  "Anyway, seeing as my primary function is the sale and distribution of
                     intoxicating substances, I gotta ask: you buyin' or what?"
                    -> his own scene 00075E89, his own options (singer, barter, not today)
```

## O-7's mechanism: the greeting says who it is for (2026-09-23, VERIFIED in game)

O-7 wants the approach to open whenever the player talks to an eligible NPC, without the dev verb
naming anybody. The problem was never the greeting -- a greeting's conditions already run on the
SPEAKER -- but the scene it starts, whose actions name their actor by ALIAS. That alias has to hold the
speaker by the time the scene runs, and the engine chooses the greeting in the same millisecond the
dialogue target is announced (Charlie's greeting and `[event target]` share a timestamp), so filling it
"when the dialogue starts" is already too late.

**Vanilla has the answer on the INFO itself: `ALFA`, "Forced Alias"** (xEdit, s32, right after `TSCE`).
The engine puts whoever speaks the line into that alias as the scene starts. It is how one quest serves
every vendor, merchant and doctor in the game:

| quest | greetings with TSCE + ALFA | the alias |
| --- | --- | --- |
| `DialogueGenericDoctors` | 61 | alias 0, conditions |
| `WorkshopVendorGreetingsGeneric` | 15 | alias 0, **no fill at all** -- our alias's exact shape |
| `WorkshopParent` | 13 | script-filled |
| `DialogueGenericMerchants` | 4 | alias 0 "Merchant", Optional, conditions |

102 base-game greetings carry it (`tools/greet_scene_aliases.py`). The vendor greeting `00076AAD` also
sets ENAM `0x08`, **Requires Player Activation**: it opens on the player's E and never as a walk-by
hello, which is what an approach must be too.

Overture's greeting now has the same shape: `TSCE` → our scene, `ALFA 0`, ENAM `0x08`, and no alias
condition (the alias is empty until the engine fills it). The persona and the room are prepared the
moment the scene is seen playing, for whoever ALFA put there. `approach arm` arms with an EMPTY alias;
then the player talks to anybody. **Verified on two NPCs, neither named:**

```
Whitechapel Charlie  27000831 "..."  ->  player 27000901  ->  27001031  vulgar/offer: "Put your money away..."
  re-greet: his own 0010D5DC "Now, you need one for the road?"  -> his scene 00075E89
Harold Roach         27000831 "..."  ->  player 27000901  ->  27001039  reticent/offer: "Please do not.
                                                                         I would not know what to say."
  re-greet: his own 00115E9A "What? Another one of you mercs looking for MacCready?..."
```

Harold is a generic Third Rail drifter, a ghoul with a greeting line and no dialogue scene of his own --
exactly the NPC O-7 is for. The reply's INFO id names the persona cell, so the persona the script read
off the alias is proven by which line he spoke. (The script's own "the scene started with" report does
not arrive: F4MCP drops a reply sent after its verb has finished.) What is still
to design, with the owner: WHO is eligible (conditions on the speaker), HOW OFTEN, and whether it runs
before or after the NPC's own greeting.

## Status

| | |
| --- | --- |
| Player's unvoiced half | **Solved** — XDI; the player's line now plays as the player's (`27000901`) |
| The NPC's answer | **Verified in game** — from its own reply topic, persona-conditioned |
| Variant rotation | **Verified in game** — 6 picks, both variants |
| Place override | **Verified in game** — 5/5 recoils in public, fenced by Random End |
| Hand-back to the NPC's own dialogue | **Verified in game** — armed greeting, disarmed at scene start, alias released at scene end |
| Lip generation | **Tool proven, output unverified in game** |
| The lines | 128 authored NPC lines + 4 player lines |
