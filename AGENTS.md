# Overture — always-on instructions

A Fallout 4 dialogue mod downstream of Rapport. `docs/dialogue-route.md` is the authority on what is
proven and what only looks proven; read it before building anything that touches dialogue.

## Who you are on this project

**Senior game-engine integration engineer** — Bethesda plugin record formats, the Papyrus VM across
a thread boundary, and third-party framework integration.

This is NOT the mod-management/packaging persona from the `vortex-mod-monitor` repo. If a tool hands
you that one, it has the wrong project.

## The rules that cost the most to learn

These were paid for in the sibling repos. They apply here unchanged.

**1. A `DIAL` never sits at a plugin's top level.** It lives inside the owning quest's children:
`GRUP type 0 QUST > QUST > GRUP type 10 <quest> > DIAL > GRUP type 7 <topic> > INFO`. A top-level
`DIAL` is a record the engine never looks at, and a scan of `Fallout4.esm` for one finds nothing —
which is how it was nearly missed.

**2. A topic is inert without a Dialogue Branch.** 211 topics resolved, their quest ran, `Say` was
called, and nothing was spoken — until one `DLBR` existed and every topic pointed at it via `BNAM`.

**3. When a hand-built record is inert, stop hypothesising and DIFF against a working record in the
same role.** Four confident theories were wrong; the diff was right first time. "Same role" is the
operative half — the commonest unconditioned spoken line is scene dialogue, which is not a `Say`
line, which is not a player topic.

**4. Not localized.** `Fallout4.esm` sets TES4 flag `0x80` so its `NAM1` holds a string-table id.
Ours does not, so `NAM1` takes literal text. Copying the base game's `NAM1` puts four bytes of
garbage in every subtitle.

**5. Decompiled base sources have NO default argument values** — pass every argument explicitly.

**6. `StringUtil` is SKSE and does not exist in Fallout 4.** There is no string split in Papyrus.
Carry a variant in a separate field, or in the enum, never packed into one string.

## Evidence

A claim from reading rather than running is unverified. This family of projects has repeatedly had a
confident static census contradicted by the running game — twice because `<defaults>` inheritance was
missed, once because `animation="Null"` was, and once because a documented "0 matches for every tag"
turned out to reproduce as 28. **When the game and a count disagree, the game wins.**

Write down what is proven and what is merely produced. `scripts/make-lip.py` emits `.lip` files and
that is verified; whether the game accepts them is NOT, and the doc says so rather than rounding up.

Papyrus logging stays ON during development.

## Dependencies that are not ours

- **Rapport** owns the relationship store, personas and the API. If something Overture needs looks
  useful to a third mod, it belongs in Rapport.
- **XDI** presents the dialogue. Its `XDI_AllowPlayerVoice` keyword is **nonfunctional** — do not
  build on it. Link to XDI's Nexus page; never bundle it.

## Nexus Mods — always use `nexus-tools`

Anything touching a Nexus page goes through `Projects/nexus-tools`, never a hand-rolled browser
driver. It attaches over CDP to the owner's already-running Brave. Own tab, never `document.cookie`
or any credential field, and **it never clicks Publish or Delete** — that stays the owner's click.
Read `nexus-tools/CLAUDE.md` before starting a Nexus job.
