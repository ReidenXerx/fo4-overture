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
anyone who has EVER been one (`HasBeenCompanionFaction`, which recruitment adds and nothing removes --
CORRECTED by wave 3: vanilla adds it already when a companion becomes AVAILABLE, so available companions
count too; recorded as a reading there). The
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

Built 2026-09-23 (`Approach.psc`: `Narrate`, `TalkLine`; the conversation it speaks for is `Conversation`, from `OnBegin` to `Finish`). The line table is in methodology §5b.

## O-10 — The nameless get a name when the player first approaches them (owner, 2026-09-23)

In the owner's words: *"generate persistent names for NPC if they didn't have names before in moment
player approach them"*, *"if it's not very hassle"*.

- **Rapport owns it** (O-1): `Rapport:Core.Introduce(actor)` in 0.2.1. It works for any mod, not only
  Overture.
- **Who counts as nameless:** someone whose name is a LABEL, carried by five or more NPC records,
  not all of them Unique (Raider, Settler, Drifter, Resident). A Unique NPC counts only when that name
  comes from their template, not their own record. Never the player, never anyone who has ever been a
  companion, and never someone who already has a custom name (the player's own rename, another mod's).
  Settled by measurement the same day, in two steps. The Unique flag alone left TrainBar.esp's thirteen
  Third Rail patrons nameless: they're flagged Unique and all called "Drifter". Then a three-record
  label rule caught Preston Garvey, Magnolia, Curie, Shaun and Nora. At five records, not all Unique,
  plus the template test, the list (263 labels on this load order) holds no personal name that would
  be renamed. A count works in every language, where a list of label words would not.
- **Persistent:** the name is derived from the form id, so the same person always gets the same name and
  the name costs the save nothing. The save keeps only WHO was introduced. A death forgets them: a dead
  stranger's id can go to somebody new once the body is cleaned up, and a stranger must never walk in
  already named.
- **When:** at the first approach, as the scene begins. The conversation's Narrator line opens with it
  ("Her name is Dottie Flynn.").

Built 2026-09-23. **Not yet run in game.** The open question is whether the game keeps a custom name on an
actor through a save by itself. Rapport puts it back either way, and its log says which happened.

## O-11 to O-26 — The morning poll (owner, 2026-09-23 ~13:20)

The sixteen questions of methodology §13, asked in four rounds. Each is settled; the methodology
section named is where it gets built.

| # | question | answer |
| --- | --- | --- |
| O-11 | how much may the Narrator hint (O-9) | **hint, never label**, as built: what worked, what didn't, what to try; never the persona's name |
| O-12 | after the first yes | **a lover state**: lovers skip the flirt and open at the proposition (§5a) |
| O-13 | exceptions to once a day (O-8) | **both**: the "not here" follow, and "not now" leaves the day unstamped |
| O-14 | bond tiers (§5a) | **yes**: partners, engine friends and the fallen-out get their own greeting and entry stage |
| O-15 | the player's lover is spoken for, to Chemistry | **yes, behind an MCM switch**; amends Chemistry's C-4 and C-9 (noted there) |
| O-16 | a player's request outranks Chemistry | **yes, a priority lane** in Rapport (its roadmap item 12) |
| O-17 | does R-14 cover the player's own blood kin | **yes, same as NPCs**: flagged, never refused (vanilla: Father, the adult Shaun) |
| O-18 | renumber to fit ESL before voicing | **yes, now**: ids into 0x800-0xFFF |
| O-19 | the companion model (§11) | **B-lite + C + D** |
| O-20 | animate Ivy's fade through Rapport | **ON by default** (not the recommended "off"), switchable; still after a player scene is proven end to end |
| O-21 | dismissed companions | **confirmed**: anyone who has ever been a companion stays out of the stranger approach |
| O-22 | must a companion be romanced first | **their own gates first**: romanced where they have romance, their affinity gates where they don't |
| O-23 | who starts things with a companion | **the player can start too** (not the recommended "moments only"): a player option as well as the moments |
| O-24 | may intimacy move a companion's own affinity | **no, for now**: only Rapport's store moves |
| O-25 | which companions | **the strangers' rule**: adult humans and ghouls. Cait, Danse, Deacon, Hancock, MacCready, Piper, Preston, X6-88, Ivy, Curie once a synth, and the DLC's Gage and Old Longfellow; not Codsworth, Strong, Nick Valentine, robot Curie or Dogmeat |
| O-26 | companion persona pins | **the owner reviews a proposed table**: "U will give me proposition table and I will review" |

**Built the same afternoon, NOT YET RUN IN GAME:**
- Overture 85aabab: O-18's light plugin.
- Rapport 02bfdd6 and Overture 1cb437b: O-16's priority lane.
- Rapport e248fe0 and Chemistry 8d30da6: O-15's lovers.
- The lover state and the "not now" day (O-12, O-13's second half, O-14's lover tier), in the commit
  that adds this line.

## O-27 to O-30 — Lovers, and the day after "not now" (owner poll, 2026-09-23 ~15:30)

Asked after the microscope pass found the lover state as first built was wrong in two ways. First, a
faithful spouse became an automatic yes once the bond tier reached 0.75. Second, Rapport's world-wide
lovers flag was written on a promise (the yes), on a trigger nobody had approved.

| # | question | answer |
| --- | --- | --- |
| O-27 | what makes an NPC the player's lover to the WORLD (Chemistry's "spoken for", affairs against the player) | **a bond of 0.75 AND at least one scene together**, the methodology's original section 7 idea, not the first yes (the recommendation was "the first scene that happens"). Their conversations skipping the flirt after a yes (O-12) stays as it is |
| O-28 | can someone stop being the player's lover | **yes, when they fall out** (bond at -0.25 or below). Not by the player's choice, not "never" |
| O-29 | several lovers | **jealousy now** (not the recommended "fine for now"): the persona table section 11 planned for companions applies to stranger lovers too. Romantic and reticent take it badly (a bond event against the player), the mercantile shrugs, the vulgar likes hearing it |
| O-30 | after "not now" or "not here", where the rest of the day reopens | **at the proposition** (recommended): no flirt replayed, no bond paid twice. Until the follow (O-13) is built, "not here" gets the same same-day invitation |

What the microscope pass changes without a poll, because the recorded rules already answered it:
- **Faithfulness >= 0.8 refuses whatever the bond** (methodology section 7). A lover, or someone whose
  conversation opens at the proposition, only skips the flirt. The verdict's rules are the same for everyone.
- **"Stage reached" stays 0-3.** The proposition opening gets its own markers: said yes before (O-12),
  the lover tier (O-14), and invited back today (O-30).

**Built the same evening, NOT YET RUN IN GAME** (the commit that adds this line; methodology 5a, 5b, 8).
Four readings made while building it, each reversible, recorded so they can be overturned:
- **A falling-out ends the yes's opening too.** O-28 was asked about Rapport's lovers flag. Overture's own
  "said yes, opens at the proposition" is the same lover state seen from the conversation, so the fallen-out
  tier clears it at the next conversation's end.
- **The fallen-out still get the stranger's approach.** O-14's table had Overture stay out for them. The
  tier is only refreshed when a conversation ends, so a greeting that shut them out would never see the
  bond recover any other way. It waits for the fallen-out lines -- and the cold line needs a script of its
  own that refreshes the tier each time it is said (Overture:Reply's shape), which lifts the lockout.
  (Corrected by microscope pass 2: the first version of this said the lockout could not be avoided.)
- **Jealousy counts only what happened after they became lovers**, once per conversation, however many
  scenes there were. Scenes with the player's engine spouse count like any other.
- **Lovers to the world are checked when a conversation opens and when it ends**, and -- since
  microscope pass 2 -- the moment a scene with the player is recorded: Rapport's bridge sends
  `OnPlayerSceneRecorded`, so "a couple now" is said at the scene, not a day later.

Microscope pass 2 (the same evening) settled four more, also reversible:
- **A proposition that can only be refused is never offered on a marker's strength.** The design review's
  rule and O-27..O-30's "a lover only skips the flirt" disagreed for a faithful spouse at a bond of 0.75:
  every visit would have opened at a proposition that could only be refused, and each refusal cost bond.
  Now someone spoken for and faithful enough to always refuse is never the lover tier, an old yes stops
  opening at the proposition once they are faithfully taken (as at a falling-out), and a refusal where
  even the right words would have been refused costs nothing. Both rules hold.
- **On a yes, the Narrator still says a lover's news** -- a couple now, a sting or a thrill -- which
  Rapport's scene-start line cannot know. O-9's "nothing on a yes" was about what that line already says.
- **O-27's line is the world's news**: "Word gets around - you and X are a couple now." Lover greetings
  began at the first yes, so "lovers now" would have announced what the player took to be true already.
- **"A yes starts a scene" is an MCM setting, like the numbers.** A global's value is frozen into every
  save, and this is the one switch whose default is meant to change once stage 4 is proven.

## O-31 to O-34 — After the second microscope pass (owner poll, 2026-09-23 ~19:45)

| # | question | answer |
| --- | --- | --- |
| O-31 | a lover's conversation is four propositions, and three of them were refused (the persona already solved) | **any register answers** (recommended): for someone who said yes or is at the lover tier, all four propositions get the real verdict, in their own voice. An invitation (O-30) keeps the rule that only their register answers |
| O-32 | "not here" in a room that is always public (the Third Rail), with no follow built | **keep it, and build the follow once stage 4 is proven** (recommended). The hint points at the place ("Catch them alone") |
| O-33 | jealousy as a bond change and a Narrator line only | **their own jealous lines** (not the recommended same-day "not tonight"): the lover says it, in their own voice. Lines to write (DRAFT) and review before voicing |
| O-34 | Rapport's Narrator names the player in the third person, Overture says "you" | **"you" for the player** (recommended): every Narrator line about the player's own moment says "you" |

**Built the same evening, NOT YET RUN IN GAME:**
- O-31: every register's stage-3 topic carries each persona's verdict sets for a lover, gated on the lover
  markers; the refusal is gated on NOT being one, so exactly one group can pass. Existing ids kept.
- O-33 (the commit that adds this line, and Rapport 46d9777): at a scene with someone, each other lover reacts
  and a marker picks their jealous greeting, two DRAFT lines per persona, for the owner's review before
  voicing. The Narrator's line stays, after the greeting.
- O-34 (Rapport aeacc91): "You and Dottie are inseparable now", "A first time for you and Dottie".
- O-32 needs nothing now: the follow waits for stage 4.

Readings made while building O-8, O-30 and O-33, each reversible:
- **The day stamp never closes before 2.4 game hours after a conversation begins** (O-8). The stamp
  also closes the hand-back's re-greet, and "tomorrow" at midnight left a conversation that crossed it
  open to re-opening itself. So after a talk at 23:50, the NPC opens again at 02:14, not 00:00.
- **"Not now" and "not here" reopen an hour of game time later** (O-30: the rest of the day). "Ask again
  later" means later, and the instant the dialogue closed looked broken. The invitation lasts the rest of
  the reply's day, and never less than two game hours after it reopens: a "not now" at 23:50 still has a
  later.
- **"Not here" hints at the place**: "Catch them alone." (O-32: until the follow, the place is what the
  player can change.)
- **Jealousy happens at the scene** (O-33): the bond moves when the lover hears, which is when a scene
  with someone else is recorded, and the lover says it at the next conversation. Still once per
  conversation. A lover the game had not loaded at that moment reacts when their next conversation
  opens, without the greeting.

## O-19 to O-26, built — the companion module (2026-09-23, late evening)

**Built, NOT YET RUN IN GAME** (the commit that adds this section). It follows O-19 (B-lite + C + D), O-20
to O-25 as answered, and methodology 11:
- `papyrus/Overture/Companions/`: Registry, the three adapters, Feeders (B-lite), Moments (C) and
  IvyNative (D), on their own quest `0x855`.
- A sixth phase in the approach scene, the companion's own, with a four-option wheel.
- Two runs of companion greetings: the companion's moment, and the player's start.
- Five actor values, Desire `0x851` among them. It is published, and fo4-anatomy reads it.
- Ten MCM numbers and the O-20 switch.
- 26 DRAFT lines, subtitles only (`voice/companion-lines.json`).

O-26's persona pins still wait for the owner's review of the proposed table. Until then a companion
answers in the persona Rapport gives them.

**Measured while building it** (and why each reading below stands on something):
- **A vanilla companion's talk menu is a GREETING.** Every `COM<Name>Talk` quest's talk scene is started by
  a GREE INFO carrying `TSCE` (and `0x08`, requires player activation), in a dialogue quest of priority 30.
  Overture's greeting, at 100, is chosen first while its conditions pass, and theirs takes over after the
  hand-back. That is methodology 11's C, checked against Fallout4.esm, not assumed.
- **Who has a romance is in the game's own data.** `CompanionActorScript.InfatuationRomanticMessage`
  (optional) is filled on exactly the seven romanceable companions (Cait, Curie, Danse, Hancock,
  MacCready, Piper, Preston). It is empty on X6-88, Deacon, Gage, Old Longfellow and the non-humans. O-22's
  "romanced where they have romance" reads that property, so no hard-coded list is needed.
- **Ivy's fade is phase 1, not 3.** Decompiled from her `CompanionIvy - Main.ba2`:
  - `Favor_Sex` (0059BC): `StartSex()` at phase 1's begin (black a second later), `EndSex()` at phase 3's
    begin, `GrantFavor()` as phase 3 ends.
  - ~~`Favor_Sex_Talk` (00627B) is a second, separate way in~~ **CORRECTED by wave 3:** nothing starts it.
    The "seven INFOs" are its own lines jumping within it, and no record in her plugin or in 1,046
    installed plugins, nor any of her 603 scripts, names it. Orphaned content, not counted.
  - The first draft's "phase 3" came from a string table and was wrong.
- **`OnPhaseBegin` counts from 1**: the phase trails of the staged scene in `docs/dialogue-route.md` read
  1-2-5 and 1-2-3-4-5, which only a 1-based count can produce (wave 3's evidence; a missing "phase 0" in
  one log was weaker).
- **O-23's sneaking test is vanilla's own, but not proven as a way in.** The 11 base-game INFOs that ask
  `IsSneaking` of `PlayerRef` are hellos, idles and persuasion lines, and none is a greeting on activation.
  Whether talking to one's companion while sneaking opens a greeting at all is a game test (methodology 12).

**Readings made while building it**, each reversible:
- **One scene, not two.** A companion's conversation runs through the approach scene's own sixth phase,
  which the stranger phases refuse to a current companion. The verdict, the hold on Rapport's slot, the
  request and the Narrator are all the stranger's own, already built. A second scene would have been a
  second copy of all of them.
- **The companion wheel is "Later." plus three propositions.**
  - "Later." takes the offer's neutral slot: "Name your price for the night" is not a thing to say to
    someone who travels with you.
  - Registers decide nothing for a companion. Every proposition reaches the same answer, decided by their
    own state and their wanting (O-22, B-lite).
- **"Later.", or the wheel left without an answer, spends nothing.** No bond moves, the moment closes, and
  the day's stamp comes down to an hour ahead, the same as after "not now" (O-30). "Not here" and "not now"
  keep the moment open for another place or another hour.
- **O-22's gate for companions without a romance is their top affinity level** (`fAffinityGate`, 1 =
  Infatuation). That is parity with romance, which vanilla ties to that level: the romance's own message is
  CompanionActorScript's `InfatuationRomanticMessage`. MCM tunes it down to Friend.
- **The feeders count only for a companion an adapter claims** (vanilla, Ivy). The engine fallback vouches
  for nothing (C6), and a mod companion's days are not Overture's to count.
- **A companion's jealousy needs a romance, or Rapport's lovers.** This is the companion side of O-29's
  "counts only after they became lovers". The sting is `fJealousySting`, one number with the strangers'
  jealousy. The vulgar's wanting rises, and the mercantile shrug.
- **Ivy's scene counts** (D.1): `Favor_Sex`, once its phase 3 has begun (wave 3; `Favor_Sex_Talk` has no
  way in). It gives the bond Rapport's own 15%. Rapport has no call for an outside scene yet (proposed:
  `RecordExternalScene`), so her scene COUNT is lost. Until then O-27's "a scene together" cannot come from
  her fades, only from ones Rapport played.
- **D.3 acts on the measured phase** (reworked by wave 3, below: anchored at her phase 2). It lifts her
  fade with her `EndSex()`, pauses her scene, and runs Rapport's. It does this only with "A yes starts a scene" on: that
  switch stays off until a player scene is proven, which is how O-20's "still after a player scene is
  proven end to end" holds.

## Microscope wave 3 — the companion module (2026-09-23, night)

Five lenses (Papyrus runtime, records, the verdict and its rules, judgment, Ivy) reviewed 6315326. The
records came out clean: the plugin is byte-identical to the builder, and stranger and companion lines
cannot cross. The code did not. **Fixed the same night, NOT YET RUN IN GAME:**

- **CRITICAL, three lenses: every companion verdict came out "refused".** `Adapter.Refuses` counted
  `IsInScene()`, and the verdict is taken while the companion stands in Overture's own scene. A scene of
  THEIR OWN still refuses: `GetCurrentScene()` is compared with Overture's. CompanionVerdict traces
  both, so the first game test shows it.
- **A moment asked once per recruitment, then never again.** It opened only on an edge of wanting,
  nothing re-armed it, and after a scene wanting stayed over most bars. Now:
  - a moment is OWED when they want it and the last one's cooldown (`fMomentCooldown`, 2 game days) is
    over;
  - it OPENS at the first poll where they are private, the day's stamp is open, and the answer would
    not be a refusal by nature or the romantic's "not now" (methodology 2: an invitation that can only
    be refused is never made);
  - the Narrator hints at it once (DRAFT wording, O-11);
  - "not here" and "not now" keep it past the hour they reopen at.
- **Their affinity levels drained the bond.** Rapport moves a bond up by a(1-b) and down by a(1+b), and
  every crossing counted, so a companion hovering at a threshold slid toward fallen-out without a word.
  Now each positive level counts ONCE, the first time it is reached, as vanilla's own threshold scenes
  fire once (`fThresholdUp` 0.05 → 0.08). Disdain and Hatred are the only falls, once per fall, re-armed
  at Neutral.
- **Wanting (Desire, published to fo4-anatomy) had no meaning worth showing.** It rose for everyone,
  forever. Its contract is now in companions/README.md:
  - it builds only while their own gates are open, and only on a day spent together (following, loaded);
  - it goes to 0 after a scene together and when they stop being the companion;
  - Ivy gets none: she keeps arousal of her own, and anatomy reads hers.
- **The store is fed at day scale**: once a game day, only while together; fights one a day, near the
  player. It used to be every 20 s, a Rapport.log line each time, overwriting the pair's last reason.
- **Their own state counts in full (C2).** Vanilla's `TemporaryAngerLevel` and an affinity below Neutral
  refuse, whatever their romance: `CA_IsRomantic` is never cleared once set. A romance declined for good
  (`CA_IsRomanceableNow` -1) closes the door, so no moment ever opens on "win them over first".
- **Methodology 2's order** in CompanionVerdict: their state, then faithfulness, then their romance or
  affinity, then wanting. A faithful spouse used to hear "not yet" (+0.02, and a promise it could not
  keep). A spoken-for companion's bar rises with faithfulness, as everyone's does.
- **Nothing happened, nothing spent.** "Later.", the wheel left, a "..." fallback, and a refusal no words
  could have changed all leave the day open. Every other end stamps it again, so a reply that ends late
  still spends it.
- **Jealousy.**
  - A companion's reaction is counted in whole scene counts, not float hours that lose precision in an
    old save.
  - It uses the same table as strangers (sting, thrill, and for the vulgar wanting too), and the
    Narrator says it.
  - The strangers' jealousy path now leaves anyone who has EVER been a companion to the module: it only
    moves their count on. A dismissed companion-lover's jealousy is not modelled.
- **The master switch reaches the module**, and **Approach starts the companions quest** if a save has
  it stopped.
- **Ivy (D):**
  - D.1 counts only `Favor_Sex`, and only once her phase 3 has begun. The flag is set before anything
    can yield, because her last phase's end and her scene's end arrive together.
  - D.3 was reworked. It now anchors at her phase 2 (the sex itself, with a 12.5 s timer), not on a clock
    from phase 1. It holds Rapport's slot through the wait and checks again after it. It resumes when
    OUR request is no longer in flight (`InFlightRequest`), with a cap. It asks Rapport's own record
    whether the scene happened (`PairSceneCount`) and puts her fade back before her scene resumes.
    Exactly one of D.1 and Rapport counts every scene, and nothing she wrote for the dark plays in
    daylight.
  - Overture's own yes waits while her fade holds the player. Her ids are validated once per load,
    including that her scene belongs to her quest.
  - `Adapter.Notify` is gone: calling her `FlirtEvent`/`DenyEvent` would move her own irritation, which
    O-24 rules out.
- **Records.**
  - The greetings require `CA_WantsToTalk == 0` live, so their own queued conversation always goes first.
  - The sneaking condition's parameter 3 is -1, as vanilla writes it.
  - Each persona's jealous greeting run now has its own Random End fence. This was an O-33 bug from before
    this module.
  - Two actor values were added: `0x857` for the fall, and `0x858` for the pair scenes seen.
- **Four DRAFT lines rewritten:** a refusal is said for four reasons and a "not now" for two, so each has
  to be true for all of them. The yeses now promise no walk to a door.

**Corrected by the wave** (the section above now says so):
- `Favor_Sex_Talk` is not a way in. The "seven INFOs" were its own lines jumping within it, and nothing
  in her plugin or any of 1,046 installed plugins starts it.
- `OnPhaseBegin` counting from 1 rests on the phase trails in `docs/dialogue-route.md` (1-2-5,
  1-2-3-4-5), not on a missing "phase 0".

**Readings of the wave** (reversible, recorded here):
- **Available companions count as companions.** Vanilla adds `HasBeenCompanionFaction` when a companion
  becomes AVAILABLE (`SetAvailableToBeCompanion`: Piper, Preston after Concord and the rest), not at
  recruitment. So they never get the stranger approach, and they get the companion module once
  recruited. That is wider than O-21's words, and conservative: companion characters are the game's
  most-voiced people. The code comments that said "on recruitment" were wrong and are corrected.
- **Jealousy of a dismissed companion-lover is not modelled.** The module follows only the current one.
- **For you (the owner's poll):**
  - the O-23 way in: a prompt on the companion, a hotkey, or sneaking;
  - whether a companion's own romance makes you lovers to the world (O-27);
  - "Later." on the negative slot;
  - the bond's bar in a companion's yes.

## O-35 to O-38 — After the third microscope pass (owner poll, 2026-09-23 night)

| # | question | answer |
| --- | --- | --- |
| O-35 | how the player starts a companion's conversation (O-23) | **a prompt on the companion** (recommended): "Ask for a moment" beside their own Talk. It replaces the sneak-and-talk the first build tried, which was unproven (vanilla never greets on a sneaking E, and it may pickpocket) and which stealth players would have met every day |
| O-36 | does a companion's OWN romance make you lovers to the world (O-27) | **yes** (recommended): vanilla's romance success or Ivy's love flag counts as O-27's bond-and-scene does, so Chemistry treats them as spoken for |
| O-37 | where "Later." sits on the companion's wheel | **the neutral slot, as built** (recommended): the stranger wheel's layout, so the player learns one wheel |
| O-38 | does the bond also gate a companion's yes | **no** (recommended): their own gates and their wanting decide. The bond still refuses at fallen-out |

**Built the same night, NOT YET RUN IN GAME:**
- **O-35:** a perk, `OvertureAskPerk` (`0x859`), given to the player on every load.
  - It is an Activate entry point that adds the choice "Ask for a moment", transcribed field for field from
    vanilla's own (CC_PetDogs_PetPerk's "Pet"; the fragment layout also read on RoboticsExpert01 and
    MisterSandman01).
  - It shows only on the current companion, and only when a conversation could open: vouched (the Moment
    value 1 or more), the day's stamp open, their own conversation not waiting, not in combat, Overture on.
  - Its fragment (`Overture:Fragments:AskPerk`) marks them ASKED (the Moment value 3) and activates them
    by default processing. The greeting's second run needs ASKED, so the verified O-7 mechanism opens the
    conversation.
  - The choice sits BESIDE their Talk and never replaces it, which keeps C1's spirit.
- **O-36:** Feeders asks Rapport for lovers as soon as their own romance is done. Rapport refuses and ends
  it at a falling-out (O-28). A reading made while building it: their own story ending (Ivy's breakup)
  does not end it here, because the falling-out rule stays the one way out.
- O-37 and O-38 needed nothing: they are what was built.

**The O-26 table**, owed since the morning, went to the owner with this report for review.

## O-39 — The review: everything approved except the vulgar lines (owner, 2026-09-24)

The owner reviewed the O-26 persona table, the two wordings, and the 62 draft lines (26 companion and 36
stranger), and answered: **"i approve all and vulgar has your usual problems - its not vulgar at all,
where is obsense words where is abuse and naughty shit?"**

| item | answer |
| --- | --- |
| O-26 persona pins | **approved as drafted**: romantic Piper, Preston, Curie; vulgar Cait, Hancock (Ivy already, R-15); reticent Danse, Deacon, X6-88, Longfellow; mercantile MacCready, Gage. Rapport pins them |
| "Ask for a moment" (O-35's prompt) | **approved** |
| Moments' Narrator hint, "{second} keeps glancing your way, like there's something on {their} mind." | **approved** |
| the 62 draft lines | **approved, except the vulgar persona's 11** (O-40) |
| the lover and jealous greetings' contractions (the rest of the bank has none: 0 of 128) | **kept**. A reading: "approve all" covered the lines as they were shown, contractions included |

## O-40 — The vulgar persona swears, degrades and gets filthy (owner poll, 2026-09-24)

O-6's rule ("it names something") is the floor, and the second time drafts only met the floor, the owner
sent them back. **The test for every vulgar line now: it swears, it insults or degrades the one it talks
to, and it says something specifically dirty.** A line missing one of the three needs a reason.
Consensual throughout: the degradation is dirty talk from someone who wants it.

| # | question | answer |
| --- | --- | --- |
| O-40a | the 11 rewritten drafts (6 voiced stranger lines, 5 companion subtitles) | **record them** (recommended) |
| O-40b | the 32 older vulgar lines O-6 approved: only 7 swear, and none insults the player | **rewrite all 32** (recommended), shown to the owner before anything is recorded |
| O-40c | male and female versions, so the persona can say cock, pussy and tits | **yes** (recommended): each version is shown only to the speakers (and players) it fits |

**Why O-40c needed a question.** Every bank line is voiced in three female and three male voice types, and
the player may be either sex, so a line with no condition has to fit anyone. That is why the drafts
stayed with fuck, slut, whore, ass and mouth. It also exposed a defect in the approved bank:
`ov_vulgar_greet_01`, "You going to keep staring at my tits, or say something?", is RECORDED in the three
male voices too. The poll said male settlers speak it, and that was wrong. The plugin uses none of the
bank's 24 `greeting`, `farewell` and `returning` lines (the voice registry names 0 INFOs for them), so the
line has never played in game. Corrected to the owner the same night.

**Measured before the rewrite:** of the persona's 32 approved lines, 7 contain an obscene word, and the
only insults are "Completely useless" and "that desperate look".

**Applied the same night (O-40b and O-40c).** The owner approved the 74-line draft: "Yeah I agree".
- **The lines:**
  - the 32 older lines, rewritten to O-40's rule;
  - 32 new stranger lines, a female and a male version in each of the persona's 16 cells the plugin
    speaks: stages 1 and 2 five cells each, stage 3's five verdicts, and the jealous greeting;
  - 10 companion answers, a female and a male version for each verdict.
- **Voice constraints:** a gendered line is recorded only in its own sex's three voices. Voiced lines keep
  the bank's no-contraction style, with no hyphen, compound or digit (the STT gate).
- **The plugin** went from 393 INFOs to 491. 98 are new:
  - 10 at stage 1 and 10 at stage 2;
  - 46 at stage 3, where O-31's lover sets repeat each answer in every register, and a refusal seven times;
  - 30 companion answers and 2 jealous greetings.
- **Nothing existing moved:** none removed, and no existing id moved, so every voice file keeps its name.
  50 existing INFOs changed text: the 26 rewritten lines the plugin speaks, repeated across branches.
- **Deploy:** the new INFOs mean NEW voice files, which need the owner's Vortex Deploy.
- **Still unused:** the 6 `greeting`, `farewell` and `returning` lines are rewritten and recorded, and the
  plugin still does not use them.
- **Builder:** O-40c's support is `tools/make_overture_esp.py` `sex_conditions` / `variant_ids` /
  `fenced_order`, checked by `tools/check_gendered.py`. That check caught one builder bug before
  anything shipped: the jealous greetings' cap counted gendered lines against the plain range.
- **Recording:** 288 takes, 24,084 characters.
  - 286 matched their words on the first pass: 284 on eleven_v3, and 2 needed eleven_multilingual_v2.
  - The other 2 failed all 6 attempts: MaleBoston and MaleRough on `ov_vulgar_offer_miss_m1`.
- **One word changed after the owner's OK, for that reason.** "...your lips wrapped round my cock" became
  "...wrapped AROUND my cock". The meaning is the same. The male voices say "around": a diagnostic take
  transcribed v3 as "around", and only v2 managed "round", once. The line's three male takes were all
  re-recorded on the new words, verbatim first time.
