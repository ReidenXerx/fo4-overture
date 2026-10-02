# Overture — the end-to-end test, written for fo4-mcp to drive

The owner asked for Overture to be tested end to end by fo4-mcp, because "there are dozens of different
dialogue scenarios and it is very exhausting for a human". This plan fits what fo4-mcp can do:
- activate, walk to an actor, and choose a dialogue option;
- read the wheel and capture every spoken line with its TEXT and its INFO form id;
- branch by save, choose and reload;
- read HUD messages and quest stages, and run console commands, Overture's dev verbs (the `approach` addon
  verb) and Rapport's mailbox verbs.

It leaves out what fo4-mcp cannot do and marks it **OWNER**: hearing the audio, AAF scenes, the MCM UI and
message boxes.

Report line by line: **PASS** with the quoted evidence, **FAIL** with what was captured against what was
expected, or **SKIP** with the reason. A captured line that matches no bank line is always a FAIL. Quote its
INFO id.

## 0. World state

- **The build under test:** Overture 0.1.6 (be1482c). In Data, `Overture.esp` is 224,024 bytes, sha256
  `65f9131c2eef...`, and `Sound\Voice\Overture.esp` holds 5,387 `*.fuz`. Check both before step 1: a different
  esp means a different test. **On 2026-10-02 both AE and GOG Data still held 0.1.3** (211,826 B,
  `cde6aab8fab8`): 0.1.6 has to be installed and deployed (the owner's click) before anything below.
- **Read the wheel as the player SEES it** (XDI's displayed entries), never only the options the scene
  holds. XDI drops any option whose spoken text is empty or whose conditions fail, and keeps the others'
  numbers (O-55). An option picked by index that is not displayed is a FAIL, not a PASS.
- **Save:** the owner's current one (Autosave2 loads cleanly). Anywhere with at least four adult human NPCs
  standing about: Goodneighbor, the Diamond City market or a settlement.
- **Before anything else:**
  - Rapport's mailbox `pause`, so autonomy starts no scene that moves people or makes Rapport "busy" (that
    would turn verdicts into "not now").
  - `approach scenes off`, so a yes records its markers without asking AAF for a scene. fo4-mcp does not run
    AAF.
  - End with `approach scenes on` (the owner's setting, if it was on) and mailbox `resume`.
- **The four test NPCs,** one per persona.
  - Run `approach status <ref>` on candidates. It prints `persona=` as 0 mercantile, 1 romantic, 2 vulgar,
    3 reticent; mailbox `bond <player> <ref>` prints the persona names too. Rapport derives a persona from the
    form id, so keep checking candidates until all four are covered.
  - Across the four, prefer the six core voice types (FemaleBoston, FemaleEvenToned, FemaleRough, MaleBoston,
    MaleEvenToned, MaleRough) and BOTH sexes. At least one vulgar NPC of each sex is needed for step 3's
    male/female lines.
  - Eligible: adult, human or ghoul, not a Gen-2 synth, not the player's teammate, and never a companion.
    `approach status` shows `child=` and `teammate=`, and the greeting's own conditions refuse the rest.
    Record each one's form id, persona, sex and voice type.
  - **A clean `approach status` is not enough.** An NPC with a greeting of their own can win over the approach.
    Charlie did (docs/dialogue-route.md), and so did Audrey 2E001E0E, a mod's Goodneighbor NPC: six activates
    opened her own greeting and wheel (fo4-mcp, 2026-09-24). Prefer a generic NPC (Settler, Drifter, Resident).
    Before adopting any candidate, activate once and check that the greeting is Overture's `...`.
  - Mailbox `bond 00000014 <ref>` prints both personas in one line, a cheaper persona probe than `approach
    status` for screening candidates.
- **Clean slate per NPC:** `approach forget <ref>` clears the day stamp, the stage, every marker and
  Rapport's lovers flag. The bond is Rapport's and stays.
- **Steering the bond:** Rapport's mailbox verb `bond 00000014 <ref>` reads it (the player is `00000014`).
  `bond 00000014 <ref> add <x>` moves it and replies with the new value. The verb is C++
  (fo4-rapport src/Mailbox.cpp), not Papyrus, and until the R-22 DLL the unknown-verb hint does not list it.
  - The move is a fraction of the distance left toward +1 or -1 (Ledger::AddBond), so ONE step lands exactly.
    From the current bond B to a target T:
    - up (T > B): x = (T - B) / (1 - B)
    - down (T < B): x = (T - B) / (1 + B), which is negative
  - Lowering a lover pair to the fallen-out line ends them as lovers (O-28). In step 4, only raise it.

## The oracle: how every captured line is judged

- **NPC lines.** Take the INFO id the Matrix captured, look it up in
  `fo4-overture/build/voice-registry.json` → `infos` → `line` (a line id), then that id in
  `fo4-overture/voice/lines.json` → `lines[]`. The entry must have:
  - `persona` = the NPC's persona (or `any` for a lover greeting);
  - `stage` = the stage the conversation is in;
  - `register` = the option chosen (for kind `response` or `recoil`);
  - `outcome` as the step expects;
  - `gender` absent, or equal to the NPC's sex (`f`/`m`). A male NPC saying an `f` line, or a female an
    `m` one, is a FAIL of O-40c;
  - `text` equal to the captured subtitle, exactly.
- **Voice.** For an NPC of a voice type Overture ships (the six core types and O-43's five),
  `Sound/Voice/Overture.esp/<VoiceType>/<INFO & 0xFFFFFF, 8 hex>_1.fuz` must exist. Any other human voice
  BORROWS (O-43): the line must be heard, and Rapport.log must say "dialogue voice: <id> (<its voice type>) -
  speaks dialogue lines as <voice>" once per voice type. A voice fo4-rapport voices.json keeps silent (children,
  robots, creatures) shows the subtitle alone. A gendered line has files only in its own sex's voices.
- **Companion lines** are subtitles only, and none is in the registry. Match their text in
  `voice/companion-lines.json`.
- **The player's options** must show the texts in `voice/player-prompts.json`:
  - stage 1: `prompts`;
  - stage 2: `stage2`;
  - stage 3: `stage3`.

  | slot | register |
  | --- | --- |
  | Positive | charm |
  | Neutral | offer |
  | Negative | blunt |
  | Question | linger |

  Match options by TEXT, and quote the optionID beside each.
- **The greeting that opens an approach** is `...` (wordless, by design). A lover's opens with one of the four
  `lover_greeting` lines. A jealous lover's opens with its persona's `jealous_greeting`.
- **Every conversation ends with ONE HUD line from Rapport's Narrator** (methodology §5b). A name, how it
  went, a hint, and the bond only if it moved, for example:
  `Her name is Wanda Conway. She enjoyed that. Only talk, for now - keep coming back. bond +0.00 -> +0.12`.
  - No line at the end is a FAIL.
  - Two lines for one conversation is a FAIL.

`lands_on` decides whose register lands:

| persona | lands on |
| --- | --- |
| mercantile | offer |
| romantic | charm |
| vulgar | blunt |
| reticent | linger |

**Driver notes (from the 2026-09-24 run, fo4-mcp).** Two scars that no Overture assertion can catch:
- **One `read_wheel()` for every path.** XDI can have the conversation open before the wheel is populated.
  After waiting, read the wheel; if it is empty, wait once more (4 s) and read again before concluding
  anything.
  - That re-read belongs in ONE helper that every entry point calls: the fresh greeting, the continuous
    route, and the retry.
  - The run pasted it into two of three paths. The third (stage 2's `run`) produced two empty-wheel "fails"
    that were the harness, not Overture. The two paths that had it kept passing, so the drift was invisible.
- **An empty wheel and a dead game look the same** in a result: "no option matched that register".
  - Before recording a cell, check the game is alive (`tasklist`) and re-read the wheel.
  - Otherwise a crash and a slow XDI both get written down as findings about Overture.

## 1. Stage 1: every persona x register x room (32 branches)

For each test NPC `P`:
1. Stand within 150 units, then `approach forget P`.
2. Pin the room with `approach room private`, and **checkpoint C1**.
3. For each of the four options: load C1, `activate P`, capture the greeting and the wheel, choose the option,
   and capture to the end of the conversation.
4. Repeat with `approach room public`: checkpoint C2, then the same four branches.

Expected in each branch:
- **Greeting `...`, then the stage-1 wheel.** Four options with the stage-1 prompt texts.
- **The reply.** A `response` line of stage 1, persona P, register as chosen:
  - `outcome: land` for P's own register;
  - `miss` for the other three.
- **Public room, blunt chosen:** a `recoil` line (stage 1, persona P) INSTEAD of the response. For the vulgar
  it is the "yes, just not here" kind. In a private room there is never a recoil.
- **After a land:** the stage-2 wheel (stage 2's prompt texts), with ONE exception: the reticent on the first
  day goes to the hand-back instead (R-8: no stage 2 on a first meeting).
- **After a miss or a recoil:** the hand-back. The NPC's own dialogue follows, meaning their vanilla greeting
  or wheel, not Overture's.
- **The Narrator line** at the end (see the oracle).
- **Once a day (O-8):** straight after, `activate P` again. It must open P's OWN dialogue, not the `...`
  greeting, and `approach status P` must say `closed until day N`.

**What a failure means.**
- Another persona's line: the persona global was wrong or unset.
- A line from the wrong register: a wheel slot is crossed (O-4).
- A recoil in a private room: the room was mis-read.
- No stage 2 after a land: the reply's outcome was not written, or the phase conditions are broken.
- A second `...` the same day: the stamp was not written.

## 2. Stage 2 (after a land)

For each P except the reticent:
1. Land at stage 1 and **checkpoint C3 at the stage-2 wheel**.
2. Branch all four options from C3.

Expected:
- a stage-2 `response` for P and the register chosen;
- a stage-2 `recoil` under `approach room public` + blunt.

For the reticent: land at stage 1, then `passtime 24` (mailbox) or `approach reset P`. The next talk must open
AT stage 2: `stageReached=1` in status, and the stage-2 wheel after `...`. Then branch as above.

## 3. Stage 3: the proposition, every verdict

1. Land at stages 1 and 2 to reach the stage-3 wheel, and **checkpoint C4 there**.
2. `approach verdict P` previews what stage 3 answers now, and why. Steer it:

| verdict wanted | how |
| --- | --- |
| refuse (why EARLY) | bond below half P's bar (`bar=` in the verdict reply): T = 0.4 × bar |
| not yet (why BOND) | bond between half the bar and the bar: T = 0.75 × bar |
| accept | bond at or above the bar (T = bar + 0.05), room private, Rapport not busy; for the romantic also indoors or at night (the setting) |
| not here | bond at the bar, `approach room public` |
| not now | the romantic outdoors by day with the bond at the bar (why SETTING) |

Then, from C4, choose each of the four options:
- **P's own register:** a `propose` line of stage 3, persona P, `outcome` = the verdict:
  - `accept` / `notyet` / `refuse` / `nothere` / `notnow`;
  - for the vulgar, possibly one of the O-40c male/female versions; its `gender` must match P's sex.
- **Any other register:** P's `refuse` line. It is refused whatever the bond, unless P is the player's lover
  (step 4).
- **After an accept** (scenes off): `approach status P` must show `saidYes=1`. No AAF scene should start.
- **After "not now" or "not here"** (O-30): `invitedUntil` is set. The rest of that day, a new talk (after
  `approach reset P`) opens AT the proposition: `...`, then the stage-3 wheel directly.

**For the vulgar, both sexes:** repeat the accept, not-here and not-now branches on a male and a female vulgar
NPC. Record which INFO ids each sex drew over at least 6 tries per cell (checkpoint and reload).
- A male drawing an `f` line, or a female an `m` line, is the O-40c failure.
- Neutral lines may come to both sexes.

## 4. Lovers (O-12, O-27, O-31)

1. After an accept, `approach reset P` (or wait a day). The next talk must open with a `lover_greeting` line
   (persona-neutral) and go straight to the stage-3 wheel. Status shows `opensAtProposition=True`.
2. Branch all four options: EVERY register reaches the verdict in P's own voice (O-31), not the refusal.
3. **OWNER:** "a couple now" appears at the SCENE (O-27), and the jealous greetings (O-33) need the player's
   AAF scene with someone else. List them for the owner and do not attempt them.

## 5. Names (O-10)

1. Approach a nameless NPC: a generic "Settler", "Drifter" or "Resident".
2. The Narrator line gives a name, and `state <ref>` shows it.
3. Save, reload, and talk again (`approach reset`). The name must hold, and Rapport.log must NOT say
   "is somebody new" for them.

## 6. Companions (the companion module; scenes off)

Recruit a base-game companion (Piper `002F1E` is pinned romantic).
- **`approach companion`:** must name them, with `adapter=`, `opensMoments=True`, `eligible=True`.
- **`approach desire 1.0`, then `approach moment`, then talk.** Their greeting is a `companion_moment` line:
  "Hey. Got a minute? Not for the road." or "Can we stop a while? Just the two of us."
  - The wheel shows: "Come away with me tonight. Just us." (Positive), "Later." (Neutral), "Enough talking.
    Let's fuck." (Negative), "(Take their hand.)" (Question).
- **Each option from a checkpoint:**
  - a `companion_answer` for their persona, with the verdict their own gates give (romance, affinity,
    wanting);
  - "Later." gives a `companion_later` line, and then THEIR OWN talk menu follows;
  - talk again within the hour and their own menu opens, not Overture's.
- **OWNER:**
  - "Ask for a moment" beside their Talk on the activation prompt (O-35). If fo4-mcp can pick an activation
    choice, try it and expect the `companion_start` greeting ("That look again. What's on your mind?").
  - Ivy's Favor: Sex (an AAF scene).

## 7. Voice presence, all of it at once

From every capture above, list each NPC INFO id against the NPC's voice type. Mark a line MISSING when the
file is absent for a core type, and STRAY when a file exists that a gendered line's sex should not have.
Both are FAILs. Hearing the audio and the lip sync is the owner's.

**Look INSIDE every file, too (fo4-mcp, 2026-09-24).** For each voiced line, the FUZE header's lip size
(the uint32 at offset 8) must be > 0. Mark it NOLIP otherwise; that is a FAIL.
- A file being there is not evidence that a face will move.
- All 6,656 of Rapport's barks shipped with lip 0 until 2e75926, and a presence-and-placement check would
  have passed them all.
- It is one pass over the folder and needs no game. On 2026-09-24 it read Overture.esp 1,860/1,860 and
  Rapport.esp 6,656/6,656 with lip data.

## 8. Overture's own key and its menu (0.1.4-0.1.6: O-53, O-54, O-55)

Since 0.1.4 a plain talk is ALWAYS the NPC's own. Overture opens only from R, "Overture", a perk choice
beside Talk, or for someone who invited the player back. fo4-mcp cannot press R, so the doors are the
functions the perk fragments call. Each one stamps or marks exactly as the key does, then runs
`Activate(player, False)`:
- **R on a stranger:** `cqf OvertureDialogueQuest "Overture:Approach.TryYourLuck" <ref>`. It sets
  `OvertureTryUntil` (AV 0x945) to now + 0.02 days (about 29 game minutes) and activates them.
- **"Ask for a moment" on the current companion:** `cqf OvertureCompanionsQuest
  "Overture:Companions:Moments.Ask" <ref>`. It needs their moment vouched first (`approach companion` must
  say a moment could open).
- **Not a door:** `approach <ref>` forces the scene with NO stamp, so it skips the menu and goes straight to
  the stages. Use it for steps 1-3, never for this step.

Proof that a fragment ran is its first log line in Papyrus.0.log: "the player chose Overture on <id>" or
"the player asked <id> for a moment". Neither line ever appeared before 0.1.5 (O-54).

1. **Plain talk on a stranger** (`approach forget <ref>`, then activate). Their own greeting plays, NOT
   Overture's `...` (INFO 01000831). FAIL if Overture's greeting opens.
2. **R on a cold stranger** (`approach forget <ref>`, then TryYourLuck). Expect:
   - the fragment's log line and Overture's greeting `...`, then the menu;
   - exactly THREE entries displayed, in this order: "Try your luck", "Something else.", "Later.". "Follow
     me" is hidden on purpose: they are not warm yet.
   - Picking "Try your luck" gives the beat `...` (010009B8), then the stage-1 wheel with FOUR entries
     displayed, one per register. Linger shows as its own description, e.g. "(Say nothing. Stay where you
     are.)". That is the 0.1.6 fix; before it, Linger was never displayed.
3. **"Later." from the menu.** Beat 010009B9, then the conversation closes with no Narrator line. The log
   says "ended on the menu - the day stays open". TryYourLuck again at once: the greeting must NOT open
   (NextApproachDay is an hour ahead); their own dialogue does. `approach status` shows the day open an hour
   from now, not tomorrow.
4. **"Something else."** (prompt "Just talk"). Beat 010009BA, then the hand-back re-greet opens THEIR OWN
   dialogue, not Overture's menu again. A loop back into the menu is a FAIL.
5. **R on a warm stranger:** stage reached >= 2 (after a stage-2 land on an earlier day), or said yes once,
   or invited back today. The menu displays FOUR entries, with "Follow me" first: one of the five versions
   from voice/follow-lines.json `player`. The log at the open says " | would follow" when they will.
   - Willing: an agree line (01000DE0-DE7 for their persona), then `Overture follow:` lines as they come
     along.
   - Not willing: a decline line (01000DE8-DEF), then the hand-back.
6. **Invited back, plain talk.** After a "not now" or "not here", activate within the day WITHOUT
   TryYourLuck. Overture's greeting opens with no menu, straight at the proposition (stage 3).
7. **Asleep.** TryYourLuck on a sleeping NPC: Overture's greeting must not open.
8. **Companion, "Ask for a moment".** On a recruited companion with a vouched moment, call Moments.Ask.
   Expect its log line, the `companion_start` greeting ("That look again. What's on your mind?"), then FOUR
   entries displayed, "(Take their hand.)" among them (hidden before 0.1.6).
9. **OWNER, or fo4-mcp if it can read the activation prompt:** "Overture" shows beside Talk on an eligible
   stranger, and is absent on a child, a companion, a sleeper, in combat, or after today's approach. "Ask for
   a moment" shows on a companion with a vouched moment.

## Not in this plan

These are the owner's, and each needs an AAF scene or the UI:
- the Narrator's "a couple now" (O-27);
- jealousy (O-29, O-33);
- a scene playing after a yes (scenes on);
- Ivy (D);
- the MCM page;
- anything in Rapport's R-22 work (faces and cum on every AAF scene), which has its own checks.
