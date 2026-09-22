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
| `NTOP` neutral | `offer` | caps, a gift, something material |
| `NETO` negative | `blunt` | crude, direct, explicit |
| `QTOP` question | `linger` | say little, stay, simply be present |

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
