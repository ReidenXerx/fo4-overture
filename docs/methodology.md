# Overture — the methodology

**Status: DESIGN**, written 2026-09-23 overnight while the owner slept, so **no poll was possible**.
Everything the owner has already decided is cited (`O-#` here, `R-#` / `N-#` in
`fo4-rapport/docs/relationship-and-personas.md`, `C-#` in `fo4-chemistry/DESIGN.md`). Everything
decided tonight without them is marked **ASSUMED**, is reversible, and the ones that touch what the
mod *guarantees* are collected in the **morning poll list** at the end rather than settled here.

**Revised the same night** after a three-lens review (the script logic, the plugin's records, the
design) and a second round in game. What is BUILT and VERIFIED now (`dialogue-route.md` has every
measurement): the entry (O-7, O-8), stages 1 → 2 → 3 in one conversation with every branch walked in
game, and place recoils. What waits on the owner's one Vortex Deploy: `Reply.pex`, which writes the
bond, the stage reached and the verdict. Everything past that is this document.

---

## 0. What it rests on

| | | |
| --- | --- | --- |
| O-1 | Overture is downstream and owns no mechanism | anything a third mod would want goes to Rapport |
| O-2, O-3 | the vanilla dialogue menu, through XDI | the player's lines are text, unvoiced |
| O-4 | register → slot, tone-faithful | charm positive, offer neutral, blunt negative, linger question |
| README, N-6, N-3 | **place overrides persona**: an intimate register in public recoils even on the persona it would land with | the public recoil |
| O-7, O-8 | talking to them opens it; adults, humans and ghouls, nobody who has ever been a companion; once a game day; approach first, then theirs | built |
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
      |                                     land   -> STAGE 2  (the reticent: hand-back -- nothing more the first time, R-8)
      |                                     miss   -> their own dialogue (hand-back)
      |                                     recoil -> their own dialogue
      +-- landed on an earlier day ----> STAGE 2: four registers
                                            land   -> STAGE 3, IF it has a chance (the verdict is "not yet" or better)
                                                      else hand-back: a proposition that could only be refused is never offered
                                            miss / recoil -> hand-back
  STAGE 3  the proposition, in each of the four registers
      their register  -> ACCEPT (-> STAGE 4) | NOT YET | NOT HERE (public; §6) | NOT NOW (the moment; §2)
      any other       -> REFUSE
      every answer but a yes hands back; a yes just ends the scene, so Rapport's can start
      leaving the conversation is the goodbye (no bond change: leaving well costs nothing)
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

**OPEN — the clue is not in the game yet.** Today's greeting is a neutral `"..."`: the greeting is
the line that STARTS the scene, so it is chosen before any script has run, and the persona global is
set in the scene's `OnBegin` — too late for it. Three ways out, none built: (a) a persona FACTION set
on the NPC at their first approach, which a greeting condition can read — so the clue arrives from the
second meeting on, and the first meeting is read from the first reply; (b) an NPC line in phase 0,
after the persona is set — which needs a delay the scene can express, and races `OnBegin` without one;
(c) Rapport putting every NPC it scans into a persona faction — the clue from the first meeting, at the
price of writing a faction to every actor the player walks past, which is what R-5 exists to refuse.
The review's correction: (a) arrives when the clue is already useless — by the second meeting the first
reply has told the player who they are. Keep (a) for the RETURNING greetings, which have the same race;
for the first meeting, try (b) as pure data first: the staged scene already opens with an empty phase,
and a phase can hold an NPC line that plays after `OnBegin` has set the persona. Until one of them is
built, say it plainly: **the first meeting is a blind one-in-four guess**, and the clue is the first
reply, not the greeting.

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
| 1 | an intimate register (`blunt`) in a public room | Rapport `ObserversNear` vs `ObserverTolerance` | **recoil**, on every persona (place overrides persona, §0) |
| 2 | the register matches the persona | Rapport `PersonaOf` | **land** |
| 3 | anything else | | **miss** |

**Stage 3.** The verdict is decided as the stage-2 land BEGINS, on the bond that land is about to
write (§9), in this order:

| # | verdict | when | what the player gets |
| --- | --- | --- | --- |
| 1 | **refuse** | engine-partnered with someone else and faithfulness >= 0.8 (§7), or the bond is below half the threshold | **no stage 3 at all**: the conversation hands back after the stage-2 land |
| 2 | **not yet** | below the threshold | stage 3; their register hears *"Close. Keep working on it"* |
| 3 | **not here** (§6) | it would be a yes, but in public | *"Lower your voice. Find us somewhere with a door and I am yours."* (DRAFT) |
| 4 | **not now** | it would be a yes, but the romantic is out of their setting, or Rapport is already running someone else's scene | *"Not in broad daylight. Find me tonight, and ask me properly."* (DRAFT) |
| 5 | **accept** | everything else | the yes, and stage 4 |

**"Not now" is new** (review, 2026-09-23). It used to be folded into "not yet", which told the player to
try harder at the one thing that was not the problem: a romantic you only ever meet by day, or anyone at
all while Chemistry runs scenes, would say "not yet" forever. Now the moment is named, and the moment is
the puzzle — place and time are what the returning days are about (N-3).

The inputs:

- **the bond after today's lands**, against the persona's threshold (§3);
- **the persona's own condition**, which is what R-8's second column means:

| persona | responds to (R-8) | what that becomes at stage 3 | ASSUMED |
| --- | --- | --- | --- |
| mercantile | gifts, caps, material offers | the `offer` register actually costs caps (10 at stage 1, 25 at stage 2, paid to them) -- charged only when it LANDS, so a refused gift is kept; the option is hidden if the player cannot pay | decided tonight (§13), not built |
| romantic | fancy words, patience, **setting** | a yes needs a setting: a private interior, or anywhere private after dark -- Rapport's own night, 20:00-06:00 by the GameHour global, so the two mods agree on when it is dark; otherwise "not now" | yes |
| vulgar | prime, perverse, direct | nothing more — the fast lane | |
| reticent | nothing, the first few times | no stage 2 on the first day; a high threshold | |

- **Rapport can run it now**: `Busy()` false and `CanRun(scenario, player, npc) >= 0`, checked at the
  verdict and again right before `RequestScene`, which is retried for a minute (§5) — Chemistry can take
  the only scene slot in the seconds between.

**A proposition that could only be refused is never offered.** The first draft let the player propose
too early and charged them for it; the review's point stands — the player cannot see the bond, and the
wheel offered nothing else, so it punished them for taking the only path on it. Now stage 3 opens only
when the verdict is "not yet" or better, and its appearing IS the visible progress.

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
always picks the right register; stage 3 offered only when it has a chance):

| persona | a stranger (bond 0) | a unique NPC the player has helped (bond 0.15) |
| --- | --- | --- |
| vulgar | yes on **day 1** (0.117) | day 1 (0.249) |
| mercantile | day 2: not yet, yes | day 1 |
| romantic | day 3: no stage 3, not yet, yes | day 2: not yet, yes |
| reticent | day 5: first meeting ends, no stage 3, not yet, not yet, yes | day 3: first meeting ends, not yet, yes |

The second column is vanilla's own head start, and it is common: `Actor.ModFavorPoints` calls
`MakePlayerFriend`, which gives a UNIQUE NPC the player has done a favour for relationship rank 1 with
the player (`Actor.psc`), and Rapport seeds rank 1 as a bond of 0.15. Those are exactly the named NPCs
players court. The first scene then lifts the bond by 15% of the distance left: 0.117 → 0.249 for the
vulgar stranger, 0.317 → 0.419 for the reticent one. (The first draft's "patience pays a day" was real
arithmetic and invisible to a player — the romantic's day-3 yes cleared its bar by 0.0011 — and with the
early proposition gone it no longer exists.) Rapport's Narrator already announces 0.25 ("getting close"), 0.5 and 0.75
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
| the store | `Rapport:Relations.BondBetween(player, npc)` | thresholds; the engine's seed before the first write — rank 1 (0.15) for a unique NPC the player has helped (`MakePlayerFriend`), 0.80 for an engine spouse |
| the store | `IsPairSeeded` | never used to pick "returning" — Overture's own stage marker does that (§1) |
| the engine, via Rapport | `Rapport:Relations.HasPartner(npc)`, `ArePartners(player, npc)` | spoken for |
| Rapport | `FaithfulnessOf(npc)` | how spoken for (§7) |
| Rapport history | `HoursSinceScene(npc)` | **not used — ASSUMED.** "They had one an hour ago" is flavour Overture can add later with its own lines |
| Rapport | `Busy()`, `CanRun()` | whether a yes can become a scene now |
| Rapport | `ApiVersion()` | read on every load: below 201 (Rapport 0.2.1) there is no `NarrateLine`, `Introduce` or `ObserversNear`, so Overture skips the first two and says so, once, on the HUD |
| Rapport | `Introduce(npc)` | O-10: a nameless NPC's name, the first time they are approached; "" for everyone else |
| the engine | cell ownership (`GetActorOwner` / `GetFactionOwner`), `IsInInterior`, the hour | place (§6), the romantic's setting |

## 5. What Overture writes (how it influences)

| to | call | when |
| --- | --- | --- |
| the store | `AddBondBetween(player, npc, a, 3)` | every NPC reply that moves the bond (§3) |
| the store, through Rapport's scene | nothing of ours — `RecordScene` | the scene completes: +15% of the distance left, a scene counted, `HoursSincePair` reset |
| Rapport | `RequestScene(player, npc, scenario)` | stage 4 — re-checking `Busy()` first, and retried every 5 s for a minute if Rapport has no free slot, so a yes never silently vanishes |
| the store | `NoteAffair(player, npc)` | AFTER `RequestScene` took, when the NPC is partnered with someone else — Rapport stages an affair only for the pair already in flight (`PapyrusLink.cpp` `StageAffair`), which is the order Chemistry uses; the first draft had it before, where it was thrown away |
| the Narrator | `NarrateBonus(player, npc, "_bond", …)` just before `RequestScene` | a fact for the Narrator's words: the underscore marks the raw bond, where a plain `"bond"` is a score share and would be printed as one — **never a persona label** |
| the Narrator | `NarrateLine(player, npc, headline, numbers)` | O-9: once per conversation, when the scene has really ended (§5b) |
| its own AVs on the NPC | next approach day (built), stage reached (§8) | every conversation |

Because the player is an ordinary pair member (R-11), everything Rapport already does for a scene
happens for the player's too, with no Overture code: the bond write, the pair's history, the
Narrator's "a first time", the watchers (R-12) turning to look and commenting, aftermath. **Not yet
verified:** a Rapport scene with the player in it has never been run. `RequestScene` does not refuse
the player (`PapyrusLink.cpp`: the native refuses while autonomy is paused, and `RequestScene` itself
checks only for null actors, the bridge, and a scene already in flight), but everything downstream —
AAF's handling of the player, faces on the player, overlays on the player — is unexercised. That is the first thing stage 4 must prove.

**Rapport runs one scene at a time** (`_sceneInFlight`). A yes while Chemistry has two settlers in a
scene cannot start: §2 turns that into *not now*, §5's retry into a short wait, and §6 into a walk.
A deliberate request by the PLAYER arguably should outrank Chemistry's autonomy — a reservation or a
priority lane in Rapport — which is a Rapport change and an owner's call (poll).

**Not yet checked for the player in a Rapport scene: barks.** Rapport's `Barks::OnSceneStarted` picks a
line for BOTH participants by persona and has no check for the player, so the player would speak an NPC
bark in a persona hashed from form id `0x14` — against R-11 ("the player has no persona") and O-2/O-3 (the
player's side is text). Rapport must skip barks for the player before stage 4 is switched on; it is on
Rapport's roadmap with the other asks.

## 5a. The bond shapes the conversation (O-12 and O-14; partly BUILT 2026-09-23)

**Built, not yet run in game:**
- **The lover state.** `OvertureStageReached` = 4 means "lovers". It's set at the first yes, and
  Rapport's store records them as lovers too (`SetLovers`, which Chemistry reads behind its switch).
  It's also set, for the NEXT conversation, when a conversation ends with the bond at 0.75 or more,
  or the two engine partners.
- **What a lover's conversation looks like.** The greeting is one of four persona-neutral lover
  lines (DRAFT). Stages 1 and 2 are skipped by the scene's own conditions, and the proposition
  opens straight away. The verdict is decided as the scene begins: no bar, not spoken for, only the
  place and the moment. The slot is held on a yes verdict.
- **O-13's "not now" gives the day back**, so the right hour or room can still be found today.

**Not built yet:** the warm and close tiers' greetings, and the fallen-out tier (a cold line, then
their own dialogue). They need lines, and lines need the owner. Also not built: O-13's "not here"
follow, a Rapport helper.

Today the store is a GATE: the player↔NPC bond has one reader (stage 3's threshold) and one writer
(Overture's replies, and Rapport's scenes). A lover of twenty scenes, an engine friend, the player's own
spouse (seeded 0.80) and an NPC the Narrator just called "fallen out" all get the same stranger's stage
1 and the same lines. That is R-8's "a number that goes up in the corner" at its minimum.

The proposal: a **bond tier**, written into an Overture actor value at the end of each conversation, so
tomorrow's greeting and entry stage can read it with a plain condition on the speaker (the O-8 shape):

| tier | bond | greeting | opens at |
| --- | --- | --- | --- |
| fallen out | <= -0.25 (Rapport's own "fallen out" line) | a cold line, then their own dialogue | nothing — Overture stays out |
| stranger | < 0.25 | "greeting" | stage 1 (or 2 if landed before) |
| warm | 0.25 - 0.5 | "returning" | stage 2 |
| close | 0.5 - 0.75 | "returning", warmer | stage 2 |
| lover | >= 0.75, or engine partners with the player | a lover's greeting (new lines) | **stage 3** — no flirting needed |

Plus more writers than dialogue, each "add this much, for this reason" (R-10): vanilla already raises
the rank (`MakePlayerFriend`), and Rapport's seed follows it only until the pair's first interaction —
following `OnStoryRelationshipChange` afterwards would import vanilla's later friendships too (R-2);
trade and gifts (reason 4, R-8's "gifts, material offers") for the mercantile; companion affinity events
for companions (§11). None built; the tiers and the lover state are poll items.

---

## 5b. The Narrator and names (O-9, O-10)

**One line per conversation**, spoken when the scene has really ended (the same `IsPlaying()` guard the
tidy-up uses; a line whose end was missed is spoken as the next conversation begins). It describes the
conversation's LAST reply, with the bond before and after on the numbers line (`bond +0.12 -> +0.17`),
shown only when the bond moved.
`{second}` is the NPC's name, which Rapport fills in. After an introduction, the name comes first and the
sentence after it uses a pronoun. Every sentence puts a pronoun subject before a past tense or a modal, so
"they" never needs a different verb.

| last reply | the line (after "Her name is X." on a first approach) |
| --- | --- |
| stage 1 miss | *X didn't take to that. Another day, another way.* |
| stage 2 miss (a different register from the one that landed) | *X didn't take to that. What worked before might work again.* |
| offend (blunt, not the vulgar) | *X took offence. Not everyone likes it blunt.* |
| public recoil | *X didn't care for that - least of all in front of people.* |
| public recoil on the register that would have landed | *X liked that - just not with people watching.* |
| stage 1 land, the reticent (R-8, hand-back) | *X heard you out. Some people take time.* |
| stage 1 land, then the player left stage 2 | *X warmed to you. Talk again tomorrow.* |
| stage 2 land, verdict refuse: spoken for and faithful | *X enjoyed that - but there's someone else.* |
| stage 2 land, verdict refuse: the bond is too low | *X enjoyed that. Only talk, for now - keep coming back.* |
| stage 2 land, stage 3 offered, the player left | *X enjoyed that. You could have asked for more.* |
| stage 3 not yet | *Close. A little more time with you, and X might.* |
| stage 3 not here | *X would - somewhere without an audience.* |
| stage 3 not now: the romantic's setting | *X would - indoors, or after dark.* |
| stage 3 not now: Rapport busy | *X would - just not right now.* |
| stage 3 refuse (wrong register) | *X turned you down. That wasn't the way to ask.* |
| a yes | nothing, not even the name: Rapport's own scene-start line names them both |
| a yes Rapport never had a slot for | *X said yes, but the moment passed.* |
| nothing chosen, a fallback beat, or no persona | nothing (only the name, if they were just introduced) |

**What the hints give away.** None names a persona, but two are only ever said to one of them: "indoors,
or after dark" (the romantic) and "some people take time" (the reticent). A player who has learned the
rules can read the persona from those, the same way they can from the NPC's own reply. That's the level
built tonight: hint, never label. The owner decides it (§13, #16).

**Names (O-10).** `BeginTalk` calls `Rapport:Core.Introduce(npc)` at every approach. Rapport answers with
a new name only the first time, and only for a nameless NPC (base not Unique, no custom name), so
Overture keeps no list of its own.


Built: **public or private**, from Rapport's own count and tolerance, and the recoil (O-4).

Proposed, in order of value:

1. **"Not here" is an invitation.** A proposition in public that would otherwise have been a yes gets
   the persona's "not here" line — DRAFT lines of its own now (the stage-2 recoils it first borrowed
   answered a crude line the player may never have said, and two of them said no) — and the NPC
   **follows the player** for up to one game hour.
   Talk to them again somewhere private and the approach reopens at stage 3, where the yes is waiting.
   A follow is a generic NPC-action helper and belongs in Rapport's N-4 set, not in Overture — and it
   must not drag a vendor or a quest-giver off the mark their quest needs them on. It turns Rapport's
   one-scene-at-a-time limit into a short walk rather than a lost day. **It reopens the approach the same
   day, so it is an exception to O-8 → poll.** The accept lines already promise it (*"Find us a door"*,
   *"Take me somewhere that we will not be interrupted"*): today a yes happens only in private and the
   scene starts where they stand, so either the lines are re-authored or the yes becomes a walk to their
   bed — the better scene.
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
- **Blood**: R-14 makes incest a flag, never a refusal — but R-14 was decided about NPCs and their
  attitudes. Whether it covers the PLAYER propositioning their own blood kin (arguably Father) is a
  different content call, with the moderation risk N-5 names, and it is the owner's (poll), not a
  parenthesis here.

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
| `OvertureNextApproachDay` | the game day they may be approached again | built, verified (O-8) |
| `OvertureStageReached` | 0 never landed, 1 stage 1, 2 stage 2, 3 reached stage 3 (any answer) | built; set by `Reply.pex` |
| `OvertureBondTier` | the tier of §5a, written at a conversation's end | proposed |
| `OvertureInvitedUntil` | game time an invitation (§6) lapses | poll-dependent |

And three GLOBALS that belong to one conversation at a time, reset as each scene begins:
`OverturePersona`, `OverturePublic` (both also forgotten when a scene really ends), `OvertureVerdict`
and `OvertureLastOutcome` (§9). No list, no timer, no co-save of Overture's own.

---

## 9. How it is built (mechanisms, and what is proven)

| piece | mechanism | status |
| --- | --- | --- |
| entry | the greeting's own conditions on the speaker, `ALFA` Forced Alias, ENAM Requires Player Activation | **VERIFIED** (O-7, O-8) |
| once a day | `OvertureNextApproachDay <= GameDaysPassed`, the CTDA's Use Global bit | **VERIFIED** |
| persona and room | globals the script sets in the scene's `OnBegin`, read by INFO conditions | **VERIFIED** |
| stages | scene PHASES (`tools/overture_stages.py`, `--stages 3`), 1-based in the log: 1 empty (the alias settles), 2 stage 1 if `OvertureStageReached == 0` on the alias, 3 stage 2 if `OvertureLastOutcome` is a land OR a stage was reached on an earlier day, 4 stage 3 if the verdict is "not yet" or better, 5 HandBack (End Scene Say Greeting) unless the last line was a yes | **VERIFIED, every branch** (G1-G4, `dialogue-route.md`), with `console set` standing in for `Reply.pex` |
| "what the reply decided" | `Overture:Reply` on each NPC reply INFO, `extends TopicInfo` — vanilla's own pattern (`CA_DialogueBump_BaseScript`). `OnBegin`, as the line STARTS: `OvertureLastOutcome`, and the verdict at the stage-2 land — the scene moves on only when the line ENDS, so nothing races. `OnEnd`: the bond and the stage reached | built; the engine binds it on every reply INFO; runs once the owner's Deploy puts `Reply.pex` in Data |
| INFO VMAD | one plain script with two Int properties (`Stage`, `Outcome`), no fragment block — the shape of Fallout4.esm INFO `0001DABE` (xEdit `wbVMADFragmentedINFO`, fragments optional from 3) | **VERIFIED parsed** (the engine binds by it) |
| stage-3 verdict | `Overture:Approach.Decide(npc, bond, public)` at the stage-2 land's `OnBegin`, on the bond that land will write (`AfterLand`), into `OvertureVerdict` | built; the gate and every answer set **VERIFIED** with the verdict set by console |
| no line ends the scene | no reply carries ENAM `0x40` — XDI turns it into the option's `endsScene` for its menu (xdi `DialogueEx.cpp` 301), and the yes showed as `[ends scene]` on the wheel | **VERIFIED** (G2b) |
| failed, do not retry | `0x40` on the ending replies (it ended the scene before HandBack); a TSCE + NAM0 phase jump (the engine restarted the scene from phase 1, with and without Start Scene on End) | measured 2026-09-23 |
| stage 4 | the accept line's `OnEnd` → `RequestScene(player, npc, scenario)` re-checked and retried, then `NoteAffair` if it took, behind `OvertureScenesEnabled` (0 by default; `approach scenes on`) | built, OFF; to prove: the player in a Rapport scene (and Rapport's barks, §5) |
| scenario | vulgar → `quickie` outdoors, `athome` indoors; romantic → `tender`; mercantile and reticent → `athome` indoors, `tender` outdoors — ASSUMED | |
| the follow | a second alias with a follow package, filled by the "not here" reply's script, cleared on scene or lapse | to prove; poll |

A `TopicInfo` stub with those two events and `GetOwningQuest` is needed at compile time — the
reconstructed base has no `TopicInfo.psc` (the compiled `TopicInfo.pex` names `OnBegin`, `OnEnd`,
`GetOwningQuest`, `HasBeenSaid`). It is `papyrus-stubs/TopicInfo.psc`, import-only.

**Without `Reply.pex`**, `OvertureLastOutcome` stays 0, stage 2 never starts on a first meeting, and the
staged plugin is exactly the verified one-exchange conversation with its hand-back — a missing script
degrades to what already works. That is why the staged plugin is the one in Data.

---

## 10. Lines

Authored today: 128 NPC lines + 4 player lines (`voice/lines.json`, `voice/player-prompts.json`),
every persona × register cell for stages 1-2, stage-3 accept / not yet / refuse, greetings, returning,
farewells, recoils.

**Written tonight as DRAFTS**, built into the staged plugin, and unvoiced — the owner reviews every line
before anything is built on it for good (O-6 was exactly that review):

| lines | count | where |
| --- | --- | --- |
| the player's stage-2 lines, one per register | 4 | `voice/player-prompts.json` `stage2` |
| the player's proposition, one per register | 4 | `stage3` |
| "not here" per persona × 2 | 8 | `voice/lines.json`, `draft: true` |
| "not now" per persona × 2 | 8 | the same |

**Still to write** (none tonight):

| lines | count | where |
| --- | --- | --- |
| spoken for, per persona × 2 | 8 | stage 3 |
| lover's greetings and the tiers of §5a | ~24 | poll-dependent |
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
| C5 | **Call their functions, never write their globals.** | their bookkeeping stays consistent. (Whether intimacy may call a companion's own `ModAffinity` is NOT C5's to forbid — it is their function — and is a poll.) |
| C6 | **A companion no adapter vouches for is invisible.** The vanilla adapter claims only the base game's own companions; a mod companion gets its own adapter or nothing, and Overture opens no conversation for a companion with intimate content of their own. | the first draft claimed every actor carrying `CompanionActorScript` — Heather, the spouse companions, Ivy's own actor — and would have played Overture's subtitles over their voices (design review, 2026-09-23) |

### 11.3 The variants

| | variant | the relationship is | entry | Ivy |
| --- | --- | --- | --- | --- |
| **A** | Affinity mirror | THEIR affinity (vanilla `CA_Affinity`, Ivy's own); every change mirrored into the store | a moment (C) | read-only, fits |
| **B** | Intimacy track | **three axes of our own** — Trust, Desire, Devotion — fed by companion-only modifiers; Trust and Devotion added to the store, Desire gating moments | a moment (C) | her arousal feeds Desire; her anger refuses |
| **B-lite** | Store-fed | **the store itself**: companion-only modifiers are EVENTS written into it in its own units (their affinity's thresholds, days together, fights survived, jealousy); Desire is the one state of ours | a moment (C) | her arousal feeds Desire; her anger refuses |
| **C** | Moments | (the entry, not a model) a second greeting, conditioned on a moment the script opens; the verified O-7 mechanism | — | her priority 70 < our 100: ours first when a moment is open, hers otherwise |
| **D** | Adapters + Ivy-native | (the compatibility layer, not a model) one adapter per companion mod; for Ivy, her own scenes bound to the store and optionally animated | — | the whole point |
| ~~E~~ | Their menu | an option injected into their talk scene | their menu | **REJECTED: C1.** An override of `COMPiperTalk_TalkScene` or Ivy's topics is the most natural UX and the least compatible one |

**A** is honest and thin: the companion's own likes and dislikes ARE the unique modifiers, and vanilla
already turns them into affinity. Its limit is the owner's word *standalone*: intimacy never moves the
relationship unless it may call their `ModAffinity` (poll), so Overture adds nothing to it. And its
first draft mirrored affinity CHANGES straight into `AddBondBetween`, whose amount is a fraction of the
distance left: that is right for an event and wrong for a mirror — 0 → 0.4 → 0.8 → 0.4 left the bond at
-0.016, and a companion idling at the cap came out a stranger (re-computed from the review). The mirror
now solves for the exact change.

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

**The case against B** (the review's, and fair): Trust and Devotion are Overture's own opinion of how
close two people are, kept BESIDE the store — the thing R-1 exists to prevent ("two mods keeping separate
opinions of whether two NPCs are close"). And Devotion had no reader. **B-lite** answers it: the same
modifiers, written INTO the store as events — R-10's "add this much, for this reason", R-2's "import, do
not mirror" — so Chemistry, the Narrator and any third mod read the number Overture reads, and Desire,
a state rather than a closeness, is all that is kept on the side.

**C** is the entry, and it is O-7's mechanism again: a second greeting in Overture's quest with
`GetPlayerTeammate == 1`, `GetValue OvertureCompanionMoment == 1` and the once-a-day stamp, `ALFA` and
`TSCE` to the companion scene. A moment is an EDGE with a window, not a level: it opens when wanting
turns true — Desire crossing its bar, their own system's arousal rising — and closes two game hours
later. (The first draft opened on "affinity has reached Admiration", a level, which made every mid-game
companion's first private talk of every day ours — the one to hand them the loot included.) Only for an
adapter that vouches for it (C6) and a companion with no intimate scene of their own (C3), and the scene's
first wheel carries a costless "Later." that hands back without stamping the day. While a moment is open,
talking to them opens ours first and theirs follows — O-8's order, verified. While none is, their dialogue
is untouched: **the module is invisible until it has something to say.**

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
   scaffold ships in PROBE mode: it logs every phase before anything acts on a number. It records the
   scene only if the fade phase was reached and Rapport did not play it — an animated one is already
   counted by Rapport's own `RecordScene`, and adding ours too was R-10's double count through a side door.

### 11.4 Recommended: B-lite + C + D

- **D always**: without adapters, nothing is compatible; with them, a new companion mod is one script.
- **B-lite for the relationship**: a system of the companion's own — their gates, their events, their
  desire — bound to the store by writing INTO it, which is what "bound to relationship db" can mean
  without a second opinion beside it. A lives inside it: their affinity's thresholds are its events.
- **C for the entry**: no record of theirs touched, the one mechanism already proven, and edge-triggered.
- **For Ivy, D first, in two steps**: D.1 (her scenes count — needs Rapport's `RecordExternalScene` to
  count properly) and D.2 (her state read) carry no lines and no risk. D.3 (animating her fade) only
  after stage 4 has proven the player in a Rapport scene. Overture's own companion conversation is for
  companions WITHOUT content of their own — the base game's, whose intimacy lines Overture would have to
  write, and could only subtitle unless the owner picks voices (V-9, and cloning a vanilla actor is the
  moderation risk N-5 names).

**Two things B + C cannot know yet**, and the build must measure before it leans on them: whether
pausing her scene while AAF moves her fights her scene's own package, and whether her warper quest
teleports her mid-scene when the player is carried off by AAF.

### 11.5 Companion polls (for the morning list)

1. **Which variant?** B-lite + C + D (recommended) · B + C + D · A + C + D (thinner, affinity only) ·
   D only for now (Ivy's own content bound to the store; no Overture companion conversation yet).
2. **Animate Ivy's fade through Rapport?** (a) switch, off by default (recommended); (b) on by default;
   (c) never — her scene stays hers.
3. **Jealousy by persona** (romantic/reticent: a small store event against the bond; mercantile
   shrugs; vulgar: desire rises): yes as written, or a different table.
4. **Voices for companion lines** Overture writes (the vanilla twelve): subtitles only (recommended), or
   the owner picks generated voices per companion.
5. **Is a dismissed companion a companion?** Done tonight — the stranger approach now excludes
   `HasBeenCompanionFaction` (it is permanent), so the companion module keeps them. §13's first poll asks
   the owner to confirm.
6. **Which companions?** Recommend the strangers' own rule — adult humans and ghouls, no gen-1/gen-2
   synths — which keeps Cait, Danse, Deacon, Hancock, MacCready, Piper, Preston, X6-88 and Ivy, and
   leaves out Codsworth, Strong, Nick Valentine, Curie in her robot body, and Dogmeat. Curie is the
   edge case that resolves itself: vanilla only romances her after she moves into a synth body, which
   passes the rule. Also to place: the DLC's Gage and Old Longfellow (human; not romanceable in vanilla,
   nor is Deacon — whether that matters is §13's poll on their own gates).
7. **Several followers at once** (multi-follower mods): the scaffolds watch ONE current companion, and a
   new companion mod needs an adapter and an Overture release. Fine for now; said so it is not a surprise.

---

## 12. Build order

1. ~~Stages 2 and 3 on the existing bank~~ — **built and verified** (every branch, with the console
   standing in for the script).
2. **The owner's Deploy**, then one conversation to prove `Reply.pex`: the bond write
   (`Rapport.log`: `relationship: 00000014 + <npc> bond ... (reason 3)`), the stage reached, the verdict.
3. **Stage 4**: one scene with the player through `RequestScene`, watched end to end (faces, overlays,
   the watchers, the watchdog, the co-save) — after Rapport skips barks for the player.
4. **The MCM page**: the switch that exists as a global, the numbers in §3.
5. **The bond tiers and the lover state** (§5a), if the polls say yes.
6. **Spoken for** (§7) and its eight lines.
7. **The follow** (§6), as a Rapport helper, if the poll says yes.
8. **Companions** (§11), B-lite first.
9. Voicing, when the lines are final.

---

## 13. MORNING POLL LIST

**ANSWERED 2026-09-23 ~13:20: decisions O-11 to O-26 in `decisions.md`.** Three answers differ from
the recommendations below: Ivy's fade is animated ON by default (O-20), the player can start things
with a companion as well as the moments (O-23), and R-14 covers the player's own kin (O-17, which had
no recommendation). The persona pins wait on a table the owner reviews (O-26). The list stays as asked.

**First, not polls — two things only the owner can do:**

- ~~**Press Deploy in Vortex, with the game closed.**~~ **DONE** (the owner, 2026-09-23 ~11:00):
  `Reply.pex` is in Data, hardlinked from the staging folder (checked with `fsutil hardlink list`).
- **Review the 24 DRAFT lines** (§10): 8 player lines, 16 NPC lines, written tonight without you.

Each poll: the question, the options, the recommendation, and what the build does without an answer.

1. **Companions are out of the stranger approach entirely** — done tonight (`HasBeenCompanionFaction`),
   because a dismissed Ivy would otherwise be approached as a stranger at priority 100, in subtitles
   over her own voice. Confirm, or go back to "the current companion only". Without an answer: as built.
2. **The companion model** (§11): B-lite (recommended) · B · A · D only for now.
3. **What happens after the first yes?** (a) every day can be another (O-8 is the only limit); (b) a
   longer rest; (c) **a lover state** (§5a: lovers open at stage 3). Recommend (c) now — (b) does not fix
   replaying the flirt with a lover. Without an answer: (a), which is O-8 exactly as decided.
4. **Exceptions to once-a-day (O-8)**, each its own tick: the "not here" follow (§6); "not now" leaving
   the day unstamped, so the right hour or room can be found the same day; and a note that FO4's Wait
   makes a game day one key press away outside Survival. Recommend both exceptions. Without an answer:
   neither — "not here" and "not now" answer, and the day is spent.
5. **The bond tiers** (§5a): partners, engine friends and fallen-out NPCs get their own greeting and entry
   stage. Recommend yes. Without an answer: not built.
6. **The player's lover is spoken for, to Chemistry** (coupling 1, §7). It amends two owner decisions:
   C-4 ("the player is not a factor") and C-9's partner test. Recommend yes, behind an MCM switch.
   Without an answer: nothing coupled.
7. **A deliberate player request outranks Chemistry** — a reservation or priority lane in Rapport, so a
   yes is not lost to a settler's scene. Recommend yes. Without an answer: the one-minute retry only.
8. **Does R-14 cover the player's own blood kin?** (§7) Without an answer: nothing special-cased, and
   nothing built that depends on it.
9. **Animate Ivy's fade through Rapport?** (a) a switch, off by default (recommended, and only after
   stage 4 is proven); (b) on by default; (c) never.
10. **Companion persona pins** — only Ivy is pinned; Cait, Piper, Hancock, Danse and the rest get a hash,
    and every companion rule reads persona. Recommend a pin table from the owner. Without an answer: hashes.
11. **Must a companion be romanced (or romanceable) in their own system first?** Recommend: their own
    system's gates first (C2) — romanced where they have romance. Without an answer: their gates, not
    romance.
12. **Can the player start things with a companion, or only through moments?** Recommend moments plus
    the costless "Later.". Without an answer: moments only.
13. **May intimacy move a companion's own affinity** (their `ModAffinity`)? C5 as written allows it —
    it is their function — and forbidding it was a business rule decided silently. Recommend no, for now.
14. **Renumber the plugin to fit ESL before voicing** — ids run to `0x4103`; everything fits in
    `0x800-0xFFF`, and voice files are NAMED by INFO id, so after voicing a renumber costs every file.
    Recommend yes. Without an answer: as is.
15. **Which companions** (§11.5 #6's list), and **dismissed companions** — kept by the companion module.
16. **How much may the Narrator hint?** (O-9, §5b) (a) **hint, never label** — what worked, what didn't,
    and what to try (place, time, patience, another way), as built; two hints are only ever said to one
    persona. (b) **facts only**: landed / missed / refused, with no "how". (c) **name the persona**
    ("she's the romantic sort"), which overturns the README's rule. Recommend (a). Without an answer: (a).

**Decided tonight, not polled** (reversible; say if wrong): the `offer` register costs caps (10, then 25),
charged only when it LANDS — a refused gift is kept; the numbers go on the MCM page; a second persona
trait for stage 2 is later; bond decay stays Rapport's status quo (none); companion voices follow V-9
(subtitles unless the owner picks); coupling 2 (Chemistry's couples spoken for) waits for couples to exist.
