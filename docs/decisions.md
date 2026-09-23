# Decisions

Numbered, settled, owner-approved. Cite the `O-#` when something rests on one. A decision here
outranks inference; if one looks wrong, propose the change rather than working around it.

Same convention as Rapport's `R-#` and `N-#`.

---

## O-1 — Overture is downstream and owns no mechanism (2026-09-22)

Same rule as Chemistry. It reads the relationship store, writes to it through Rapport's API, and
keeps none of the machinery. If something it needs looks useful to a third mod, that thing belongs
in Rapport.

Carried over from `fo4-rapport/docs/relationship-and-personas.md` N-1.

## O-2 — The player picks through the VANILLA dialogue menu (owner, 2026-09-22)

Not a custom HUD prompt, not a contextual inference from what the player is doing. A real
conversation: you talk to someone and the registers are the options.

**Why this was not obvious.** The player's half was the open question — Fallout 4 voices its
protagonist, we cannot match that actor, and a custom line would leave the player silent with the
camera on their still face. That is what made a custom prompt look safer.

**O-3 removes the objection**, so the vanilla menu wins on every other count: it is what players
already know, it gets the dialogue camera, and it needs no invented UI.

## O-3 — XDI is a HARD requirement (owner, 2026-09-22)

Overture refuses to run without [Extended Dialogue Interface](https://www.nexusmods.com/fallout4/mods/27216).

**Not for the option count.** There are exactly four dialogue slots and Overture has exactly four
registers, so vanilla fits — see `player-topic-shape.md`.

**For the player's half.** XDI makes unvoiced player lines a first-class case and hot-patches the
dialogue camera to stay on the NPC. Without it the player's line is silent *and* the camera cuts to
a motionless face, which is the difference between a mod and a broken mod for every user who
installs it. Shipping a vanilla fallback would mean every bug report comes from someone without XDI.

It also leaves room for a fifth register later, which vanilla's four slots would not.

**Trap:** `XDI_AllowPlayerVoice` is nonfunctional. Do not build on it.

Linked, never bundled — its author asks for that.

## O-4 — Register to slot mapping is tone-faithful (owner, 2026-09-22)

| slot | register | |
| --- | --- | --- |
| `PTOP` positive | `charm` | fancy words, patience, a compliment |
| `NETO` neutral | `offer` | caps, a gift, something material |
| `NTOP` negative | `blunt` | crude, direct, explicit |
| `QTOP` question | `linger` | say little, stay, simply be present |

**Field names corrected 2026-09-23; the decision is unchanged.** This table first had `NTOP` neutral and
`NETO` negative, the way the names read. Measured through XDI's optionIDs, and named so by xEdit, `NTOP`
is the NEGATIVE slot and `NETO` the NEUTRAL one (`dialogue-route.md`; `tools/make_overture_esp.py`
`SLOTS`). The owner's decision -- the crude option where the aggressive one lives, the material one in
the neutral slot -- is exactly what the build does.

Each register sits in the slot whose engine meaning it resembles, so the wheel's own colouring and
position work for us rather than against us. The crude option lands where the aggressive one
normally lives; `linger` takes the question slot because it is the non-committal one.

Rejected: an escalation ramp ordered by explicitness (consistent, but fights the engine's
semantics), and a split putting `offer` in the question slot (defensible per slot, not learnable as
a pattern).

## O-5 — Six core voices first, and partial coverage is safe (owner, 2026-09-22)

Render six core settler voice types before widening. **Verified behaviour**: a voice type with no
audio file still shows the subtitle — never silence, never a wrong voice — because our lines carry
no voice-type condition, so the engine looks the audio up under the speaker's own type and finds
nothing. That makes partial coverage a scope choice rather than a risk.

At 6,406 characters the whole bank costs ~38,400 characters across six voices.

## O-6 — The vulgar persona says it out loud (owner, 2026-09-22)

The owner approved every persona's lines except `vulgar`, and was right to. The spec calls `blunt`
"crude, direct, explicit" and this persona's defining trait is the absence of euphemism — and all
32 of its lines had been written in euphemism, which made it the romantic persona in a bad mood.

Rewritten twice. The second pass exists because the first still hedged in the `land` cells, which
are the moment the player said something crude and this persona liked it, and therefore should carry
the most explicit lines in the bank.

**The rule for any future line in this persona: it names something.** A line that could be spoken by
the romantic persona in a bad mood is not a vulgar line.

Refusals and farewells stay deliberately tamer — someone turning you down is not obliged to be
filthy about it, and the contrast is characterisation.

## O-7 — The trigger is talking to them, in normal dialogue (owner, 2026-09-22)

The approach opens when the player talks to an eligible NPC (E), as part of normal dialogue. No hotkey,
no menu, no verb: the `approach` addon verb is a DEV tool and never ships as the trigger.

**Mechanism, verified 2026-09-23:** the greeting carries `ALFA` (Forced Alias), so the engine puts
whoever speaks it into the scene's alias -- vanilla's own generic-greeting shape
(`WorkshopVendorGreetingsGeneric`). Verified on Whitechapel Charlie and on Harold Roach, a generic ghoul
drifter, with the alias empty and nobody named. See `dialogue-route.md`, "O-7's mechanism".

## O-8 — Who, how often, and in what order (owner poll, 2026-09-23)

- **Who:** adults Rapport has a persona for -- humans and ghouls -- minus the player's CURRENT
  companion, anyone in combat, and anyone already in a quest scene.
- **How often:** once per NPC per game day. The first conversation of the day opens the approach; after
  that, their normal dialogue until tomorrow.
- **Order:** the approach first, then their own dialogue takes over (the hand-back verified the same
  night).

Rejected: companions included; strangers excluded until met (GetTalkedToPC); every conversation;
at random; their own dialogue first (impossible for any NPC with a dialogue scene of their own).

**Built and verified 2026-09-23** as the greeting's own conditions on the speaker -- nothing in a script
decides it. Once a day is an actor value of ours (`OvertureNextApproachDay`), stamped `floor(today)+1`
when the scene begins and compared against the live `GameDaysPassed` global. Six trials, no verb: a ghoul
and a human open it, a robot and the current companion get their own dialogue, a second talk the same
day gets theirs, and `approach reset` reopens it. `dialogue-route.md`, "O-8 at runtime".

Two readings of the owner's words, made without asking and recorded here so they can be overturned:
"adults Rapport has a persona for" is `ActorTypeNPC` minus `ActorTypeSynth` (gen-1/gen-2 synths
excluded; a gen-3 synth is in, because to these conditions it is a human), and "companion" means the CURRENT one
(`GetPlayerTeammate`) -- a dismissed companion standing in a settlement is approachable by Overture
until the companion module (N-7) claims them.

**The companion reading was REVISED the same night** (design review, 2026-09-23): "companions" now means
anyone who has EVER been one (`HasBeenCompanionFaction`, which recruitment adds and nothing removes). The
owner's option read "minus companions", and tonight's brief says companions get a module "unlike other
npcs"; the narrower reading let a dismissed Ivy be approached as a stranger at priority 100, in subtitles
over her own voice. One condition on the greeting, reversible; the morning poll asks the owner to confirm.

## O-9 — Overture is narrated, through Rapport's Narrator (owner, 2026-09-23)

In the owner's words: *"we definitely need a narrator here as we have for chemistry"* -- to let players
know, *"in not vibe destroying way"*, what is happening and how when they act.

- **Through Rapport's Narrator**, not Overture's own notifications (O-1; Rapport's roadmap 11: "one module
  narrates all of them"). Rapport 0.2.1 has `NarrateLine(first, second, headline, numbers)` for it, with
  its own MCM switch ("addon moments", on by default) and the Narrator's numbers switch for the second
  line.
- **One line per conversation**, when the scene has really ended. Never one per reply: the NPC's own reply
  already says it in their voice, and a notification on every line is what would break the mood.
- **What it says:** what the player's words did, plus a hint at what to do next: another way, another day,
  somewhere without an audience, indoors or after dark, more time. **Never the persona's name.** The README's
  rule ("you are never told who they are") still holds. How much the hints may give away is a morning poll
  (methodology §13, #16).
- **Nothing on a yes.** Rapport's own line already says who and why as the scene starts. A yes that never
  found a free scene slot does get a line ("said yes, but the moment passed"), so it doesn't vanish without
  a word.

Built 2026-09-23 (`Approach.psc`: `BeginTalk`, `Narrate`, `TalkLine`). The line table is in methodology §5b.

## O-10 — The nameless get a name when the player first approaches them (owner, 2026-09-23)

In the owner's words: *"generate persistent names for NPC if they didn't have names before in moment
player approach them"*, *"if it's not very hassle"*.

- **Rapport owns it** (O-1): `Rapport:Core.Introduce(actor)` in 0.2.1. It works for any mod, not only
  Overture.
- **Who counts as nameless:** an NPC whose base is not flagged Unique, OR whose name is a label that
  three or more NPC records share (Settler, Drifter, Diamond City Resident). Never the player, never
  anyone who has ever been a companion, and never someone who already has a custom name (the player's
  own rename, another mod's). The label rule was added the same day, after a measurement: TrainBar.esp's
  thirteen Third Rail patrons are all flagged Unique and all called "Drifter", so the Unique flag
  alone left them nameless. A count works in every language, where a list of label words would not.
- **Persistent:** the name is derived from the form id, so the same person always gets the same name and
  the name costs the save nothing. The save keeps only WHO was introduced. A death forgets them: a dead
  stranger's id can go to somebody new once the body is cleaned up, and a stranger must never walk in
  already named.
- **When:** at the first approach, as the scene begins. The conversation's Narrator line opens with it
  ("Her name is Dottie Flynn.").

Built 2026-09-23. **Not yet run in game.** The open question is whether the game keeps a custom name on an
actor through a save by itself. Rapport puts it back either way, and its log says which happened.
