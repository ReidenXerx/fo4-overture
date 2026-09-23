# Overture — the methodology

**Status: DESIGN**, written 2026-09-23 overnight while the owner slept, so **no poll was possible**.
Everything the owner has already decided is cited (`O-#` here, `R-#` / `N-#` in
`fo4-rapport/docs/relationship-and-personas.md`, `C-#` in `fo4-chemistry/DESIGN.md`). Everything
decided tonight without them is marked **ASSUMED**, is reversible, and the ones that touch what the
mod *guarantees* are collected in the **morning poll list** at the end rather than settled here.

What is BUILT and verified today: the entry (O-7, O-8) and one exchange of stage 1, with place
recoils (`dialogue-route.md`). Everything past that is this document.

---

## 0. What it rests on

| | | |
| --- | --- | --- |
| O-1 | Overture is downstream and owns no mechanism | anything a third mod would want goes to Rapport |
| O-2, O-3 | the vanilla dialogue menu, through XDI | the player's lines are text, unvoiced |
| O-4 | register → slot, and **place overrides persona** | the public recoil |
| O-7, O-8 | talking to them opens it; adults, humans and ghouls, not the current companion; once a game day; approach first, then theirs | built |
| R-1, R-10 | the store is Rapport's; the API is "add this much, for this reason" | reason 3 is ours |
| R-5 | a pair record is written on interaction, never on sight | Overture writes only when something was SAID |
| R-7, R-8 | persona derived from the form id; reticent answers "nothing, the first few times" | reticent is what makes the store load-bearing |
| R-11 | the player is a pair member like any other | player↔NPC bonds are ordinary rows |
| R-14 | incest is a flag, never a refusal | Overture refuses nothing on blood |
| N-3 | place decides which advance is appropriate | |
| N-4 | NPC-action helpers are extracted from F4MCP, then grown | the follow in §6 |
| N-7 | companions get their own module | §11 |
| C-4, C-9 | Chemistry never consults the player; faithfulness is per NPC, 0..1, derived | |

The README's rule sits over all of it: **you are never told who they are; reading the person is the
game.** Nothing below may show a persona — not a notification, not the Narrator, not an MCM page.
(The scene's `OnBegin` trace writes the persona index to the Papyrus log today; that is a dev
convenience, and gating it off in a release build is a packaging item.)

---

## 1. One conversation, end to end

```
  talk to an eligible NPC (O-7/O-8: the greeting's conditions decide)
      |
  STAGE 0  greeting: "greeting" if Overture never landed with them, else "returning"
      |
      +-- never landed ----------------> STAGE 1: four registers
      |                                     land   -> STAGE 2  (reticent: not on the first day -> farewell)
      |                                     miss   -> their own dialogue (hand-back)
      |                                     recoil -> their own dialogue
      +-- landed on an earlier day ----> STAGE 2: four registers
                                            land   -> STAGE 3
                                            miss / recoil -> hand-back
  STAGE 3  two options: the proposition, or goodbye
      propose -> ACCEPT (-> STAGE 4) | NOT YET | REFUSE | NOT HERE (public; §6)
      goodbye -> their farewell line (no bond change: leaving well costs nothing)
  STAGE 4  the scene, through Rapport (player + NPC)
```

One conversation per NPC per game day (O-8), so a stage is a day's progress, and a persona's
difficulty is **how many days it takes**, not how many clicks.

**Why stage 2 exists when stage 1 already found the register.** It is not a second puzzle. It is the
reward for reading them, it is where place bites hardest (the lines are more intimate), and it is the
bond's second write of the day. The puzzle is stage 1 on the first meeting, and the greeting is the
clue: *"If you are buying, then I am listening"* and *"Oh. Hello. Did you need something from me?"* are
two different people, and the player who listens to the greeting reads the persona before choosing.
**ASSUMED** — a second trait that makes stage 2 its own puzzle is in the poll list, as a later idea.

**Returning conversations start at stage 2.** Stage-1 lines are first-meeting lines (*"You are still
here. Most people are not."*); hearing them on day five is wrong. Overture keeps one fact of its own on
the NPC for this — the stage they last reached (§8) — because it is a fact about THIS mod's
conversation, not about the relationship (O-1: a third mod does not need it).

---

## 2. What decides an answer

**Stages 1 and 2.** The NPC's reply is chosen by INFO conditions, first match wins (the order IS the
rule, as the recoil build already proved):

| # | rule | reads | outcome |
| --- | --- | --- | --- |
| 1 | an intimate register (`blunt`) in a public room | Rapport `ObserversNear` vs `ObserverTolerance` | **recoil**, on every persona (O-4) |
| 2 | the register matches the persona | Rapport `PersonaOf` | **land** |
| 3 | anything else | | **miss** |

**Stage 3.** The verdict is computed by the script before the NPC answers (§9 has the mechanism), and
the four reply sets are conditioned on it, first match wins:

| # | verdict | when |
| --- | --- | --- |
| 1 | **refuse**, with a spoken-for line (new, §10) | engine-partnered with someone else and faithfulness >= 0.8 (§7) |
| 2 | **not here** (§6) | in public, and it would otherwise have been a yes |
| 3 | **refuse** | the bond is below half the threshold |
| 4 | **not yet** | below the threshold, or Rapport cannot run a scene right now |
| 5 | **accept** | everything else |

The inputs:

- **the bond after today's lands**, against the persona's threshold (§3);
- **the persona's own condition**, which is what R-8's second column means:

| persona | responds to (R-8) | what that becomes at stage 3 | ASSUMED |
| --- | --- | --- | --- |
| mercantile | gifts, caps, material offers | the `offer` register actually costs caps (10 at stage 1, 25 at stage 2, paid to them); the option is hidden if the player cannot pay | yes — poll |
| romantic | fancy words, patience, **setting** | a yes needs a setting: a private interior, or anywhere private after dark (20:00-05:00) | yes |
| vulgar | prime, perverse, direct | nothing more — the fast lane | |
| reticent | nothing, the first few times | no stage 2 on the first day; a high threshold | |

- **Rapport can run it now**: `Busy()` false and `CanRun(scenario, player, npc) >= 0`. If not, the
  verdict is *not yet* — an honest "not now" that costs the player nothing but the day. **ASSUMED**; the
  better answer is the follow in §6, which covers this case too.

**The proposition too early is a mistake, not a coin toss.** Below half the threshold the answer is
*refuse* (and costs a little); between half and the threshold it is *not yet* (and gains a little);
at the threshold, *accept*. Saying goodbye instead costs nothing. So a patient player gets there a day
sooner with the romantic and the reticent — patience is what the romantic answers and time is what
the reticent needs (R-8), and the arithmetic makes it so without a rule saying it (§3).

---

## 3. The numbers: what Overture writes, and the arcs they make

Every write is `Rapport:Relations.AddBondBetween(player, npc, amount, 3)` — reason 3, dialogue (R-10,
`Ledger.h` `BondReason::kDialogue` "Overture"). `AddBondBetween` imports the engine's relationship
first, so a pair the game already calls friends keeps its head start (R-2). The amount is a **fraction
of the distance left** (`Ledger.cpp` `AddBond`: `+a` moves `a·(1-bond)`, `-a` moves `a·(1+bond)`), so
nothing overshoots and every source diminishes alike.

| moment | amount | why |
| --- | --- | --- |
| stage 1 land | +0.05 | a first good exchange |
| stage 2 land | +0.07 | deeper, and harder to reach |
| miss | 0 | the player is learning; the day is already the price |
| `blunt` miss on anyone but vulgar | -0.04 | an insult is not a neutral guess |
| recoil, persona it would NOT have landed on | -0.06 | embarrassed in public is worse than offended in private |
| recoil on the persona it WOULD have landed on (vulgar) | 0 | they liked it; they just did not want it here |
| stage 3 not yet | +0.02 | *"I do not want you to stop coming over"* |
| stage 3 refuse | -0.03 | proposing to someone who is not there yet |
| stage 3 accept | **0** | **the scene writes it** — see below |
| goodbye / farewell | 0 | |

**The accept writes nothing, on purpose.** Rapport already adds 15% of the distance left when a scene
COMPLETES (`Ledger.cpp` `kBondPerScene`, reason 1). Writing a bond for the yes as well would count the
same event twice — R-10's double count, arriving through the other door. The yes is a promise; the
scene is the fact.

**Thresholds for a yes** (bond, player↔NPC): vulgar **0.08**, mercantile **0.15**, romantic **0.25**,
reticent **0.30**. ASSUMED, and all of the above belongs on Overture's MCM page, the way Chemistry's
curve is on its own (C-3).

**The arcs they make**, computed, not estimated (a player who talks to the same NPC once a day and
always picks the right register):

| persona | always proposes | says goodbye until close |
| --- | --- | --- |
| vulgar | yes on **day 1** (bond 0.117) | day 1 |
| mercantile | day 2 (0.134 → 0.195) | day 2 |
| romantic | day 4: refuse, not yet, not yet, yes | **day 3** |
| reticent | day 6: bye, refuse, refuse, not yet, not yet, yes | **day 5** |

The first scene then lifts the bond by 15% of the distance left: 0.117 → 0.249 for the vulgar NPC, 0.317
→ 0.419 for the reticent one. Rapport's Narrator already announces 0.25 ("getting close"), 0.5 and 0.75
for ANY bond change, dialogue included (`Narrator.cpp` `OnBondChanged`), so the player sees the
relationship move without ever being told the persona.

**There is no decay.** Rapport's store has none (checked 2026-09-23: no code lowers a stored bond over
time). A courtship abandoned for a year is still where it was. That is a Rapport-wide property, not
Overture's to change; it is in the poll list.

---

## 4. What Overture reads (how it is influenced)

| from | call | used for |
| --- | --- | --- |
| Rapport persona | `Rapport:Core.PersonaOf(id)` | which register lands; pins from `personas.json` (Ivy is pinned vulgar) |
| Rapport crowd | `ObserversNear(id)`, `ObserverTolerance()` | public or private — one number shared with Chemistry (C-6); the player is not counted as an audience |
| the store | `Rapport:Relations.BondBetween(player, npc)` | thresholds; the engine's seed before the first write |
| the store | `IsPairSeeded` | never used to pick "returning" — Overture's own stage marker does that (§1) |
| the engine, via Rapport | `Rapport:Relations.HasPartner(npc)`, `ArePartners(player, npc)` | spoken for |
| Rapport | `FaithfulnessOf(npc)` | how spoken for (§7) |
| Rapport history | `HoursSinceScene(npc)` | **not used — ASSUMED.** "They had one an hour ago" is flavour Overture can add later with its own lines |
| Rapport | `Busy()`, `CanRun()` | whether a yes can become a scene now |
| the engine | cell ownership (`GetActorOwner` / `GetFactionOwner`), `IsInInterior`, the hour | place (§6), the romantic's setting |

## 5. What Overture writes (how it influences)

| to | call | when |
| --- | --- | --- |
| the store | `AddBondBetween(player, npc, a, 3)` | every NPC reply that moves the bond (§3) |
| the store, through Rapport's scene | nothing of ours — `RecordScene` | the scene completes: +15% of the distance left, a scene counted, `HoursSincePair` reset |
| the store | `NoteAffair(player, npc)` | before `RequestScene`, when the NPC is partnered with someone else. Staged: Rapport records it only if the scene actually starts |
| Rapport | `RequestScene(player, npc, scenario)` | stage 4 |
| the Narrator | `NarrateBonus(player, npc, "bond", …)` just before `RequestScene` | the scene-start line explains it — **never a persona label** |
| its own AVs on the NPC | next approach day (built), stage reached (§8) | every conversation |

Because the player is an ordinary pair member (R-11), everything Rapport already does for a scene
happens for the player's too, with no Overture code: the bond write, the pair's history, the
Narrator's "a first time", the watchers (R-12) turning to look and commenting, aftermath. **Not yet
verified:** a Rapport scene with the player in it has never been run. `RequestScene` does not refuse
the player (`PapyrusLink.cpp`: the native refuses while autonomy is paused, and `RequestScene` itself
checks only for null actors, the bridge, and a scene already in flight), but everything downstream —
AAF's handling of the player, faces on the player, overlays on the player — is unexercised. That is the first thing stage 4 must prove.

**Rapport runs one scene at a time** (`_sceneInFlight`). A yes while Chemistry has two settlers in a
scene cannot start. §2 turns that into *not yet*; §6 into a short wait.

---

## 6. Place (N-3)

Built: **public or private**, from Rapport's own count and tolerance, and the recoil (O-4).

Proposed, in order of value:

1. **"Not here" is an invitation.** A proposition in public that would otherwise have been a yes gets
   the persona's "not here" line — the stage-2 recoils already are exactly that (*"You are killing me.
   Four walls and a door, right now."*) — and the NPC **follows the player** for up to one game hour.
   Talk to them again somewhere private and the approach reopens at stage 3, where the yes is waiting.
   This is the first N-4 helper Overture grows (a follow package on a second alias), and it turns
   Rapport's one-scene-at-a-time limit into a short walk rather than a lost day. **It reopens the
   approach the same day, so it is an exception to O-8 → poll.**
2. **Their own home.** Being let in is itself the signal (N-3). An approach in a cell the NPC owns (or
   their faction owns) lowers the stage-3 threshold by 0.05 — ASSUMED. Being in their home WITHOUT
   leave (trespass) is an attitude matter, and the attitude layer is deliberately deferred.
3. **Where "whose place" lives.** Chemistry computes it in Papyrus (`WhosePlace`, up to eight natives a
   pair, snapshotted per pass). Overture needs it once per conversation, for one NPC, so a direct check
   costs nothing — but by O-1 a third mod will want it too, and the right home is a Rapport native
   (`Rapport:Core.PlaceOf(npc)` → nobody's / theirs / their faction's / the player's). Proposed to
   Rapport, not built there tonight.

---

## 7. Partners, faithfulness, and the store's flags

Chemistry charges a partnered NPC `fFaithWeight × FaithfulnessOf` for straying (C-9). Overture mirrors
it for the player, so one NPC is the same person in both mods:

- **Spoken for** = the engine says spouse or courting with someone who is not the player.
- **Faithfulness >= 0.8**: the proposition is refused with a spoken-for line, whatever the bond.
- **Otherwise**: the threshold rises by `0.4 × faithfulness`. A spouse of middling faithfulness can be
  talked round, slowly.
- **If it happens anyway**, `NoteAffair(player, npc)` — the "bad thing" the attitude layer will judge
  (C-9's own words: *"it will be in future related to 'bad things' if character cheating on partner"*).
- **Blood**: R-14 — a flag, never a refusal. Nothing in the vanilla game makes a player↔NPC pair blood
  kin except, arguably, Father; the flag records it and the attitude layer judges it.

ASSUMED: 0.8 and 0.4. Poll: whether the partner's REACTION (the spouse finds out) is Overture's or
waits for the attitude layer.

**The two couplings that would make Chemistry and Overture one world — both proposed, both polls:**

1. **The player's lover is spoken for, to Chemistry.** Today Chemistry's `HasPartner` asks the engine,
   and the engine knows nothing of Overture. If the store could mark a player↔NPC pair as partners
   (a store flag, set by Overture at a bond of 0.75 and at least one scene — ASSUMED), then
   `Rapport:Relations.HasPartner` would see it, Chemistry would charge that NPC's faithfulness when a
   settler propositions them, and a scene that happens anyway is an affair against the player — which
   Overture can then answer, in the NPC's next greeting (guilty lines, new). This changes what
   Chemistry does, so it is the owner's.
2. **Chemistry's couples are spoken for, to Overture.** Two settlers Chemistry has brought to 0.75
   ("inseparable") are a couple in every way but the engine's. An Overture proposition to one of them
   could meet the same spoken-for rule. Needs a Rapport query that does not exist —
   `StrongestBondOf(npc, excluding)` → the other person and the value.

---

## 8. Overture's own state (and why it is so small)

Everything about the RELATIONSHIP lives in Rapport's store (R-1). Overture keeps only facts about its
own conversation, on the NPC, as actor values — saved with the actor, written only for NPCs the player
actually talked to (R-5's rule, for free), and gone with the actor:

| AV | meaning | status |
| --- | --- | --- |
| `OvertureNextApproachDay` | the game day they may be approached again | built (O-8) |
| `OvertureStageReached` | 0 never landed, 1 stage 1, 2 stage 2, 3 proposed | new |
| `OvertureInvitedUntil` | game time an invitation (§6) lapses | new, poll-dependent |

No list, no timer, no co-save of Overture's own.

---

## 9. How it is built (mechanisms, and what is proven)

| piece | mechanism | status |
| --- | --- | --- |
| entry | the greeting's own conditions on the speaker, `ALFA` Forced Alias, ENAM Requires Player Activation | **VERIFIED** (O-7, O-8) |
| once a day | `OvertureNextApproachDay <= GameDaysPassed`, the CTDA's Use Global bit | **VERIFIED** |
| persona and room | globals the script sets in the scene's `OnBegin`, read by INFO conditions | **VERIFIED** |
| stages | scene PHASES, one player-dialogue action each; a phase's start conditions read what the previous reply decided | to prove |
| "what the reply decided" | a script on each NPC reply INFO, `extends TopicInfo`, `Event OnEnd(ObjectReference akSpeakerRef, Bool abHasBeenSaid)` — vanilla's own pattern (`CA_TopicInfoScript`, `CA_DialogueBump_BaseScript`). It writes the bond and sets the next phase's gate | to prove |
| INFO VMAD | scripts array, then an OPTIONAL fragments section (xEdit `wbVMADFragmentedINFO`, `SetOptionalFrom(3)`) — so a plain script needs no fragment block. The script can identify its INFO by `Self.GetFormID()` against the builder's id layout, so the VMAD needs no properties, the same shape as the quest's | to prove |
| stage-3 verdict | computed at the stage-2 reply's `OnEnd` (after the bond write), set in a global the stage-3 reply sets are conditioned on (§2's order) | to prove |
| stage 4 | the accept line's `OnEnd` → `NoteAffair` if needed → `NarrateBonus` → `RequestScene(player, npc, scenario)` | to prove: the player in a Rapport scene |
| scenario | vulgar → `quickie` outdoors, `athome` indoors; romantic → `tender`; mercantile and reticent → `athome` indoors, `tender` outdoors — ASSUMED | |
| the follow | a second alias with a follow package, filled by the "not here" reply's script, cleared on scene or lapse | to prove; poll |

A `TopicInfo` stub with those two events and `GetOwningQuest` is needed at compile time — the
reconstructed base has no `TopicInfo.psc` (the compiled `TopicInfo.pex` names `OnBegin`, `OnEnd`,
`GetOwningQuest`, `HasBeenSaid`).

---

## 10. Lines

Authored today: 128 NPC lines + 4 player lines (`voice/lines.json`, `voice/player-prompts.json`),
every persona × register cell for stages 1-2, stage-3 accept / not yet / refuse, greetings, returning,
farewells, recoils.

New lines this methodology needs — none written tonight; the owner reviews every line before it is
voiced (O-6 was exactly that review):

| lines | count | where |
| --- | --- | --- |
| the player's proposition, one per register | 4 | stage 3 (unvoiced) |
| the player's goodbye | 1 | stage 3 (unvoiced) |
| spoken for, per persona × 2 variants | 8 | stage 3 |
| "not here" at stage 3 | 0 | the stage-2 recoils already are this |
| guilty greeting after an affair against the player (coupling 1) | 8 | poll-dependent |

Voices: six core voice types first (O-5), the owner picks every voice by ear (V-9), partial coverage
is safe (a missing file shows the subtitle). A modded companion's own voice type — Ivy's `_NPC_IVY` —
has no rendered audio and never will unless the owner chooses a voice for it: her lines would be
subtitles. That is §11's problem.

---

## 11. Companions (N-7)

Owner (N-7): *"Sex with companions will be separate module in our next mod and companions will have
standalone unique relationship system; it will also bound to relationship db but will have bunch
unique modifiers."* And tonight: *"they should have unique module unlike other npcs … highly
compatible with such companions as Ivy."* The scaffolds are in `companions/` (README there); every
one compiles (`companions/tools/check.ps1`), none ships.

### 11.1 What a companion has that a stranger does not (measured)

**Vanilla** (Fallout4.esm, read 2026-09-23):

- Affinity in the actor value `CA_Affinity` (`000A1B80`), thresholds as globals: Infatuation **1000**,
  Confidant **750**, Admiration **500**, Friend **250**, Neutral 0, Disdain -500, Hatred -1000.
  `CompanionActorScript.ModAffinity` clamps to ±1100 and fires threshold scenes, messages and perks.
- Likes and dislikes: `FollowersScript.SendAffinityEvent` raises a keyword; every companion's
  `CompanionActorScript` answers it with their OWN disposition (`CA_Event_Loves` +35, `Likes` +15,
  `Dislikes` -15, `Hates` -35, times a size).
- Romance: `CA_IsRomantic` (`00148DF6`) = 1 after `RomanceSuccess()`; `IsInfatuated()`; an infatuated
  romantic companion sleeps near the player for a bonus (`FollowersScript.HandleOnSleepStart`).
- Their own conversation: a `COM<Name>Talk` quest per companion with a talk scene
  (`COMPiperTalk_TalkScene`), dialogue quest priority 30.
- `CurrentCompanionFaction` (`00023C01`), `HasBeenCompanionFaction` (`000A1B85`, never removed).

**Ivy** (CompanionIvy.esm 6.1, read 2026-09-23 — `IvyAdapter.psc` carries every id):

- Her actor carries vanilla's `companionactorscript` AND she runs a system of her own on
  `_IvyCompQuest` (`CompanionIvyScript`, `CompanionIvyProfanity`, `_ivyAffinityActionScript`,
  `_ivy_sextalk_script`): globals for her affinity, love (`LoveRelationShipEstablished`), availability
  (`AvailableForRelationship`, 0 after `DenyRelationShipForEver`), arousal (`IsAroused`,
  `Arousal_Threshold` 7 → 5 in love, 8 after a breakup, 12 denied), irritation and anger.
- Functions of her own another mod can call by name: `FlirtEvent` (five of them lower her
  irritation), `DenyEvent` (four unanswered denials disappoint her), `NicePlaceEvent`,
  `ApologizeToIvy`, `PlayerLovesIvy`, `PlayerBreaksUpWithIvy`.
- **Her intimacy already exists**: a voiced "Favor: Sex" scene (`SCEN 0059BC`) with staged sex talk,
  ending in a **fade to black** — `StartSex()` is `SetPlayerAIDriven(True)` + `FadeOutGame`, `EndSex()`
  undoes both. Nothing is animated.
- 460 dialogue topics, one greeting topic with 31 lines, quest priority **70** (DNAM byte `0x46`) against
  Overture's **100** (`0x64`).
- Voice type `_NPC_IVY`, her own. Rapport pins her **vulgar** (R-15).

### 11.2 The compatibility rules (derived, and binding on every variant)

| | rule | why |
| --- | --- | --- |
| C1 | **Never override a companion mod's records.** Find them at runtime: `Game.IsPluginInstalled`, `GetFormFromFile`, `CastAs`, `CallFunction`. No master, no patch. | their talk menu is theirs; an override of Ivy's 460 topics breaks on her next update |
| C2 | **Their state outranks ours.** Ivy angry means no, whatever our numbers say. | a companion who is furious in her own mod and willing in ours is two people |
| C3 | **Their content first.** If they have a line or a scene for the moment, use theirs. | her writing and her voice beat ours, and cost no voice budget (V-9) |
| C4 | **A lookup that fails turns the adapter off**, never guesses. | a new version moves ids |
| C5 | **Call their functions, never write their globals.** Read-only on vanilla affinity too. | their bookkeeping stays consistent: `ModAffinity` fires their scenes and perks |

### 11.3 The variants

| | variant | the relationship is | entry | Ivy |
| --- | --- | --- | --- | --- |
| **A** | Affinity mirror | THEIR affinity (vanilla `CA_Affinity`, Ivy's own); every change mirrored into the store | a moment (C) | read-only, fits |
| **B** | Intimacy track | **three axes of our own** — Trust, Desire, Devotion — fed by companion-only modifiers; Trust and Devotion added to the store, Desire gating moments | a moment (C) | her arousal feeds Desire; her anger refuses |
| **C** | Moments | (the entry, not a model) a second greeting, conditioned on a moment the script opens; the verified O-7 mechanism | — | her priority 70 < our 100: ours first when a moment is open, hers otherwise |
| **D** | Adapters + Ivy-native | (the compatibility layer, not a model) one adapter per companion mod; for Ivy, her own scenes bound to the store and optionally animated | — | the whole point |
| ~~E~~ | Their menu | an option injected into their talk scene | their menu | **REJECTED: C1.** An override of `COMPiperTalk_TalkScene` or Ivy's topics is the most natural UX and the least compatible one |

**A** is honest and thin: the companion's own likes and dislikes ARE the unique modifiers, and vanilla
already turns them into affinity. Its limit is the owner's word *standalone*: intimacy never moves the
relationship (C5 forbids writing affinity), so Overture adds nothing to it.

**B** is what N-7 describes. Its modifiers, none of which an ordinary NPC has:

| axis | rises with | falls with |
| --- | --- | --- |
| Trust | their affinity rising (either system); fights survived together | their affinity falling |
| Desire | every day since your last scene together; their own system's arousal (Ivy) | a scene together (sated); jealousy, for a vulgar companion it RISES |
| Devotion | days travelling together; scenes together | the player's scenes with someone else — for a romantic or reticent companion |

Jealousy needs nothing new from Rapport: the player is an ordinary actor in the ledger (R-11), so
`LastPartner(player)` and `HoursSinceScene(player)` already say *the player was with someone else, this
long ago*. How much it stings is the companion's persona — which is why Ivy, pinned vulgar, would be
the one companion who is aroused by it.

**C** is the entry, and it is O-7's mechanism again: a second greeting in Overture's quest with
`GetPlayerTeammate == 1`, `GetValue OvertureCompanionMoment == 1` and the once-a-day stamp, `ALFA` and
`TSCE` to the companion scene. The script opens the moment (private by Rapport's count, their adapter
neither refusing nor closed, and one of: their own system wants it, B's Desire is over the bar, their
affinity has reached Admiration). While a moment is open, talking to them opens ours first and theirs
follows — O-8's order, and the hand-back is already verified. While none is, their dialogue is
untouched: **the module is invisible until it has something to say.**

**D, for Ivy**, writes no line of its own:

1. **Her scenes count.** When her Favor: Sex scene ends, the player↔Ivy pair gets what a Rapport scene
   gives. Rapport has no call for a scene that was not its own — **proposed:
   `Rapport:Core.RecordExternalScene(a, b)`**, which every fade-to-black companion mod would want
   (O-1). Until then `AddBondBetween(…, 0.15, 5)` stands in for the bond, and the scene count is lost.
2. **Her state is read** for everything (IvyAdapter).
3. **Her fade can be animated** — an MCM switch, OFF by default. On the phase her scene fades out,
   call HER `EndSex()` to lift it, pause HER scene, run the scene through Rapport, unpause when Rapport
   is free: her post-scene talk still plays, in order, nothing of hers skipped or doubled. **Which
   phase** is not known — her fragment's string table names phases 1 and 3 and the calls GrantFavor,
   StartSex, EndSex in that order, which suggests 3, and a string table is not code order. The
   scaffold ships in PROBE mode: it logs every phase before anything acts on a number.

### 11.4 Recommended: B + C + D

- **D always**: without adapters, nothing is compatible; with them, a new companion mod is one script.
- **B for the relationship**: the owner asked for a standalone system bound to the store, and B is the
  only variant that is one. A survives inside it — their affinity is B's Trust input — so nothing A
  offers is lost.
- **C for the entry**: no record of theirs touched, and it reuses the one mechanism already proven.
- **For Ivy, D's native path first**: her scene, her voice, animated if the owner wants it. Overture's
  own companion conversation (registers, stages) is then for companions WITHOUT content of their own —
  the vanilla twelve, whose intimacy lines Overture would have to write, and could only subtitle unless
  the owner picks voices (V-9, and cloning a vanilla actor is the moderation risk N-5 names).

**Two things B + C cannot know yet**, and the build must measure before it leans on them: whether
pausing her scene while AAF moves her fights her scene's own package, and whether her warper quest
teleports her mid-scene when the player is carried off by AAF.

### 11.5 Companion polls (for the morning list)

1. **Which variant?** B + C + D (recommended) · A + C + D (thinner, affinity only) · D only for now
   (Ivy's own content bound to the store; no Overture companion conversation yet).
2. **Animate Ivy's fade through Rapport?** (a) switch, off by default (recommended); (b) on by default;
   (c) never — her scene stays hers.
3. **Jealousy by persona** (romantic/reticent lose devotion, mercantile shrugs, vulgar is aroused):
   yes as written, or a different table.
4. **Voices for companion lines** Overture writes (the vanilla twelve): subtitles only (recommended), or
   the owner picks generated voices per companion.
5. **Is a dismissed companion a companion?** Recommend yes: `HasBeenCompanionFaction` is permanent, so
   the companion module keeps them, and O-8's stranger approach should then exclude them too — a
   one-condition change to O-8's greeting, which is the owner's.
6. **Which companions?** Recommend the strangers' own rule — adult humans and ghouls, no gen-1/gen-2
   synths — which keeps Cait, Danse, Deacon, Hancock, MacCready, Piper, Preston, X6-88 and Ivy, and
   leaves out Codsworth, Strong, Nick Valentine, Curie in her robot body, and Dogmeat. Curie is the
   edge case that resolves itself: vanilla only romances her after she moves into a synth body, which
   passes the rule.

---

## 12. Build order

1. **Stages 2 and 3 on the existing bank**: scene phases, the `TopicInfo` script, the bond writes, the
   verdict. Proves the two unproven mechanisms before anything leans on them.
2. **Stage 4**: one scene with the player through `RequestScene`, watched end to end (faces, overlays,
   the watchers, the watchdog, the co-save).
3. **The MCM page**: the switch that exists as a global, the numbers in §3.
4. **Spoken for** (§7) and its eight lines.
5. **The follow** (§6), if the poll says yes.
6. **Companions** (§11).
7. Voicing, when the lines are final.

---

## 13. MORNING POLL LIST

Each: the question, the options, the recommendation, and what the build does without an answer.

1. **Does the `offer` register cost caps?** (a) yes, 10 then 25, paid to them; (b) no, the words are
   the offer; (c) a gift item. Recommend (a): *"I brought you something"* followed by nothing is the
   register lying. Without an answer: (a).
2. **"Not here" → they follow you (one game hour) and the approach reopens in private — an exception to
   once-a-day (O-8).** Recommend yes: it is the place mechanic's payoff, and it covers Rapport's
   one-scene limit. Without an answer: not built; public propositions get *not yet*.
3. **What happens after the first yes?** (a) every day can be another (the stamp is the only limit);
   (b) a longer rest after a scene (e.g. three days); (c) a lover tier with its own lines. Recommend
   (b) now, (c) later. Without an answer: (a), because (a) is O-8 exactly as the owner decided it.
4. **Should the player's lover be spoken for, to Chemistry?** (coupling 1, §7) Recommend yes, behind
   an MCM switch — it is what makes the two mods one world, and cheating becomes a thing that can
   happen to the player. Without an answer: nothing coupled.
5. **Should Chemistry's couples be spoken for, to Overture?** (coupling 2) Needs a Rapport query.
   Recommend yes. Without an answer: not built.
6. **Bond decay** (Rapport-wide). None exists. Recommend none for the player's pairs (a courtship
   waits), and a question for Chemistry's own. Without an answer: none.
7. **The thresholds and amounts** in §3 — the owner's feel, after playing it. Without an answer: §3.
8. **A second trait for stage 2** (a later idea): each NPC derives a second persona that stage 2 needs,
   so stage 2 is its own puzzle. Recommend NOT now — it doubles the lines. Without an answer: no.
9. **Companions** — §11's own list.
