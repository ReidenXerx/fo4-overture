# Changelog

## 0.1.6 (2026-10-01)

- **"Try your luck" shows on the Overture menu.** Extended Dialogue Interface lists an option by the
  words you say, and leaves out any option with no words. "Try your luck" has none, so R opened a menu
  with only "Something else." and "Later." The same hid every silent option: **Linger** ("Say nothing.
  Stay where you are." and its versions) and **"Take their hand"**, so the quiet kind of person could
  never be won. Each silent option now shows its own description. Thanks to azurestrand for the report.
- **The installer** now opens with a "Checking your setup" page, then gives each feature a page of its
  own.

## 0.1.5 (2026-10-01)

- **R / X "Overture" and "Ask for a moment" now actually do something.** Since 0.1.2, every choice
  Overture adds beside Talk was silently inert: the record that tells the game which script to run had
  one byte too many, so the script never started. That was "Ask for a moment" on companions, "Follow me"
  in 0.1.3, and "Overture" with its menu in 0.1.4. Thanks to Daergil, MrN79 and lordgmlp for the reports
  and the log that found it.

## 0.1.4 (2026-09-30)

- **Overture has its own button now.** Pressing E on someone always gets you their own talk: their
  quest, their shop, their story. Overture is **R, "Overture"**, beside Talk. It opens a short menu:
  **Try your luck** (the approach, as before), **Follow me** (for anyone you've warmed up; it used to sit
  on the prompt), **Just talk** (their own dialogue) and **Later.** Someone who invited you back
  ("not now", "not here", or a Follow me arrival) still opens Overture on a plain E.
- **Nobody is approached in their sleep.** No greeting, no "Overture" choice and no companion moment
  while someone is asleep.
- **"Ask for a moment" works on companions.** Picking it made them say a short hello and nothing
  else, on every companion. It now opens the conversation it asks for.
- Following the menu and ending there ("Later.", "Just talk", Follow me) no longer uses up the
  day's approach with that person.

## 0.1.3 (2026-09-27)

- **"Follow me."** Someone who tells you "not here" now follows you somewhere quieter. And for anyone
  you've warmed up (a line landed, a yes before, or an invitation today), "Follow me" sits beside Talk.
  They answer in their own voice and come along if they would. They keep to their own place: anywhere in
  their town or settlement, never out of it ("This is as far as I go"); in the open, about 60 m. After two
  game hours without somewhere private, or if you run off, they head back. Once you're alone, they speak
  first, and your next talk opens at the proposition.
- **Heather Casdin: her romance counts.** Overture now recognises Heather, who runs her own companion
  system rather than the game's. Once her own story makes you a couple, the Narrator says so, other
  NPCs treat her as spoken for, and she hears about your other scenes like any lover. Moments and
  "Ask for a moment" stay off for her: her own voiced content is hers.
- **New and not yet played at length.** Both are new in this release. If someone follows you
  somewhere odd, or won't come, Papyrus.0.log says why (lines start "Overture follow:"). Please tell us.

## 0.1.2 (2026-09-26)

- **"A yes starts a scene" is now on by default.** When someone says yes, Rapport starts the scene.
  Updating flips it on for everyone who never touched the setting; if you switched it yourself in
  MCM, your choice is kept.
- **"Ask for a moment" shows only where it can open a conversation.** The choice on a companion's
  prompt could appear during the game's opening, or while they were in a scene, where Overture's
  conversation cannot start; picking it then just opened their own talk. It now follows the same
  rules as the conversation it opens.
- **The log says what happened to an "Ask for a moment".** Papyrus.0.log now says whether the
  conversation opened, and if it did not, why not (lines start "Overture companions:").

## 0.1.1 (2026-09-26)

- **Not during the game's opening.** Talking to your spouse, a neighbour or the Vault-Tec rep in
  pre-war Sanctuary, or anyone in Vault 111, no longer opens an approach. Overture starts when you
  leave the vault. Alternate starts and MS Skip Prewar Sanctuary work as expected.
- **Start now.** If an unusual alternate start means Overture never started, the MCM page's
  "Start now" starts it, and Rapport and the mods built on it, in that save. Needs Rapport 0.2.2.

## 0.1.0 (unreleased)

The first release. Overture is a way of approaching people: you walk up to someone and try, and whether it
lands depends on who they are.

**Requires** Rapport 0.2.1 or newer, XDI (Extended Dialogue Interface) and AAF. Against an older Rapport
Overture still runs, without narration, names or lovers, and a notification says it needs 0.2.1.

### Approaching people
- **Talking to someone opens it.** Adults, humans and ghouls, once a game day each. Then their own
  dialogue takes over. There is no hotkey and no menu.
- **Four ways to try:** offer them something, charm them, be blunt, or linger and say little. Each lands
  on one kind of person and misses the other three. Overture never tells you who they are; reading the
  person is the game.
- **Where you are matters.** Something intimate said in a crowded room recoils, even on the person it
  would have landed with.
- **Three stages in one conversation.** A line that lands carries on to the next, a miss ends it, and
  someone you have won over before starts further in. A yes can end in a scene, when the MCM switch
  "A yes starts a scene" is on. It is off by default.
- **"Not now" and "not here" are not "no".** Ask again later that day, or somewhere without an audience.
- **Orientation is a hard line.** Someone who is not into your character's sex says so in their own words,
  and no words or time change it.
- **Lovers.** A close bond and a scene together make you lovers to everyone else too. Chemistry then
  treats your lover as spoken for. A lover hears about your other scenes and tells you how they took it,
  in character. Falling out ends it.

### Voices
- **Every line is voiced**, with lip sync. Anyone with a human voice is heard in the nearest of the
  voices Overture has recorded, and each character always gets the same one.
- **Your character speaks too**, in one of two designed voices, a woman's and a man's. Every option on
  the wheel has five versions, so the same choice does not always sound the same.

### The Narrator
- **One line when a conversation ends** (through Rapport's Narrator): what your words did, and a hint
  at what to try next. It never names who they are.
- **The nameless get names.** A Settler or a Drifter you approach for the first time gets a name, and
  keeps it.

### Companions
- **A companion you travel with has wanting of their own.** It builds with days on the road together.
  When it turns, they find a moment and ask you for a minute.
- **"Ask for a moment"** appears beside Talk on a companion's prompt whenever a conversation could open.
  Their answer depends on their own state and their own romance, not on the words you pick.
- **Base-game companions and custom companions on the game's companion framework** both take part.
  Amazing Follower Tweaks' extra followers do too.
- **Ivy keeps her own route** (CompanionIvy): her own "Let's make love." Overture counts her scene
  towards your bond, and with scenes switched on, her fade to black becomes an animated scene.

### Settings
- Every number is on the MCM page. Without MCM, Overture runs on its defaults.
