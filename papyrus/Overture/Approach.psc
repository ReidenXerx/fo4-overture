Scriptname Overture:Approach extends Quest
{Overture's approach: an eligible NPC the player talks to gets the player's four
registers first -- then their own dialogue takes over.

HOW IT OPENS (O-7, verified in game 2026-09-23). The greeting carries ALFA,
"Forced Alias": the engine puts whoever says it into alias 0 and starts the
scene. That is vanilla's own generic-greeting shape -- one quest serving every
vendor and doctor in the game. WHO it opens for is the greeting's conditions, run
on the speaker (O-8): adults, humans and ghouls, nobody who has ever been the
player's companion (they get their own module, N-7), not in combat, not already
in a scene, once per game day. Nothing in this script decides eligibility; the
engine does, before this script hears a thing.

WHERE IT OPENS is the scene's phase conditions (tools/overture_stages.py), and
they read only what was written BEFORE the conversation began: the stage reached,
and three markers that open it at the proposition -- they said yes before (O-12),
the lover tier (O-14), or "not now" or "not here" earlier today (O-30). So every
one of those is written as a conversation ENDS, never during one.

WHAT THIS SCRIPT DOES, on the scene's own events:
  OnBegin -- the persona and the room for whoever ALFA put in the alias, the day
             stamp that makes them wait until tomorrow, a name for the nameless
             (O-10), and the opening: lovers to the world (O-27), a lover's
             jealousy (O-29), and the verdict of a conversation that opens at the
             proposition. It all lands seconds before the NPC's first reply is
             chosen, which is after the player picks; and the stamp closes the
             re-greet that follows the reply, 140 ms after it, so the
             conversation hands back to the NPC's own dialogue.
  OnEnd   -- a second later, the conversation ends: what the next one will read,
             one line from the Narrator on how it went (O-9), and -- once nobody
             else has the scene -- the alias let go, the persona and the room
             forgotten.
And on each NPC reply, through Overture:Reply: as the line BEGINS, stage 3's
verdict (only at the stage-2 land); as it ENDS, the bond, and how far the
conversation got.

THE DEV CHANNEL, through F4MCP's addon protocol (with no F4MCP.esp the bridge
resolves to None and none of it registers):
  approach <npc>         force the scene on this NPC now, eligible or not
  approach reset <npc>   clear the day stamp, so the next talk opens it again
  approach forget <npc>  as if never approached: the day, the stage, every marker,
                         and Rapport's lovers flag (the bond is Rapport's, and stays)
  approach status <npc>  what the gate sees for this NPC, the markers, the bond
  approach verdict <npc> what stage 3 would answer now (staged build), changing nothing
  approach scenes on|off whether a yes really asks Rapport for a scene (staged build)

NO GetDisplayName ANYWHERE. It is absent from the decompiled base sources, and
the compiler reports an unknown method as

    Error while trying to typecheck script overture:approach: Index (zero based)
    must be greater than or equal to zero and less than the size of the argument
    list.

at line 0,0, naming no call and no line. Bisecting the file is the only way to
find which one it means.}

; Form-relative ids, resolved by FILE. The runtime index is the player's load
; order and is not ours to predict.
Int Property SCENE_ID  = 0x00000801 AutoReadOnly
Int Property PERSONA_GLOBAL_ID = 0x00000840 AutoReadOnly
Int Property PUBLIC_GLOBAL_ID = 0x00000841 AutoReadOnly
Int Property ENABLED_GLOBAL_ID = 0x00000842 AutoReadOnly
Int Property NEXT_DAY_AV_ID = 0x00000843 AutoReadOnly
; OvertureStageReached: 0 never landed, 1-2 the stage that landed, 3 proposed.
Int Property STAGE_REACHED_AV_ID = 0x00000844 AutoReadOnly
; The staged build's actor values for the proposition opening and the lover's
; bookkeeping. tools/make_overture_esp.py has the ids, tools/overture_stages.py
; the phase conditions that read the first three.
;   OvertureTier          O-14's tier, TIER_* below
;   OvertureSaidYes       1 once they have said yes to the player (O-12)
;   OvertureInvitedUntil  the game day a "not now" or "not here" lasts until (O-30)
;   OvertureJealousyMark  the player's scenes with anyone else, plus one, as this
;                         lover last knew it (O-29; 0 = never counted)
Int Property TIER_AV_ID = 0x00000848 AutoReadOnly
Int Property SAID_YES_AV_ID = 0x00000849 AutoReadOnly
Int Property INVITED_UNTIL_AV_ID = 0x0000084A AutoReadOnly
Int Property JEALOUSY_MARK_AV_ID = 0x0000084B AutoReadOnly
Int Property BRIDGE_ID = 0x00000800 AutoReadOnly
Int Property TARGET_ALIAS = 0 AutoReadOnly

; R-10: 3 is dialogue, the reason Rapport keeps for Overture.
Int Property REASON_DIALOGUE = 3 AutoReadOnly

; Overture:Reply's Outcome property, as the builder writes it (make_overture_esp
; 1-5, overture_stages 6-9).
Int Property OUTCOME_LAND = 1 AutoReadOnly
Int Property OUTCOME_MISS = 2 AutoReadOnly
Int Property OUTCOME_OFFEND = 3 AutoReadOnly
Int Property OUTCOME_RECOIL = 4 AutoReadOnly
Int Property OUTCOME_RECOIL_LIKED = 5 AutoReadOnly
Int Property OUTCOME_ACCEPT = 6 AutoReadOnly
Int Property OUTCOME_NOTYET = 7 AutoReadOnly
Int Property OUTCOME_REFUSE = 8 AutoReadOnly
Int Property OUTCOME_NOT_HERE = 9 AutoReadOnly
Int Property OUTCOME_NOT_NOW = 10 AutoReadOnly

; THE STAGED BUILD (tools/overture_stages.py, --stages 3). The one-exchange
; plugin has none of these records: every lookup below comes back None there,
; and every use is guarded.
Int Property VERDICT_GLOBAL_ID = 0x00000845 AutoReadOnly
Int Property SCENES_GLOBAL_ID = 0x00000846 AutoReadOnly
; What the NPC's current line IS, written as it begins; the scene's phase 2
; starts only after a land (tools/overture_stages.py's docstring has why this and
; not a phase jump).
Int Property LAST_OUTCOME_GLOBAL_ID = 0x00000847 AutoReadOnly
Int Property VERDICT_REFUSE = 1 AutoReadOnly
Int Property VERDICT_NOTYET = 2 AutoReadOnly
Int Property VERDICT_ACCEPT = 3 AutoReadOnly
Int Property VERDICT_NOT_HERE = 4 AutoReadOnly
; "Not now": the moment is wrong, not the person -- the romantic out of their
; setting, or Rapport already running someone else's scene. It used to be folded
; into "not yet", which told the player to try harder at the one thing that was
; not the problem (design review 2026-09-23).
Int Property VERDICT_NOT_NOW = 5 AutoReadOnly
; GameHour, Fallout4.esm -- the clock Rapport's own "night" reads (Pairing.cpp).
Int Property GAME_HOUR_ID = 0x00000038 AutoReadOnly
; A yes Rapport could not start at once is retried this often, this many times,
; after the dialogue has closed (a scene cannot start under an open menu).
Int Property YES_TIMER = 2 AutoReadOnly
Float Property YES_RETRY_SECONDS = 5.0 AutoReadOnly
Int Property YES_RETRIES = 12 AutoReadOnly
; A conversation ends this long after its scene's OnEnd (Scene.OnEnd has why).
Int Property END_TIMER = 3 AutoReadOnly
Float Property END_DELAY = 1.0 AutoReadOnly

; Rapport 0.2.1: NarrateLine, Introduce, ObserversNear, the priority lane and
; lovers. Older, and none of them is bound -- every call would be a Papyrus
; error and a wrong answer.
Int Property NEEDS_API = 201 AutoReadOnly
; Why a verdict came out as it did (Decide). The Narrator words some of them
; differently; all of them go into the trace.
Int Property WHY_NO_PERSONA = 1 AutoReadOnly
Int Property WHY_TAKEN = 2 AutoReadOnly
Int Property WHY_EARLY = 3 AutoReadOnly
Int Property WHY_BOND = 4 AutoReadOnly
Int Property WHY_PUBLIC = 5 AutoReadOnly
Int Property WHY_SETTING = 6 AutoReadOnly
Int Property WHY_BUSY = 7 AutoReadOnly
Int Property WHY_YES = 8 AutoReadOnly
Int Property WHY_FALLEN_OUT = 9 AutoReadOnly

; O-14's tiers (OvertureTier), from the bond as a conversation leaves it. The
; lines are Rapport's own -- its Narrator's "getting close", "close" and "have
; fallen out", and the bond at which Rapport ends a lovers pair (O-28) -- so the
; two mods agree about what they mean. Only TIER_LOVER is read so far, by the
; greeting and the phase conditions: it opens at the proposition. The warm, close
; and fallen-out greetings wait for their lines.
; tools/make_overture_esp.py TIER_LOVER must match.
Int Property TIER_FALLEN_OUT = -1 AutoReadOnly
Int Property TIER_STRANGER = 0 AutoReadOnly
Int Property TIER_WARM = 1 AutoReadOnly
Int Property TIER_CLOSE = 2 AutoReadOnly
Int Property TIER_LOVER = 3 AutoReadOnly
Float Property BOND_WARM = 0.25 AutoReadOnly
Float Property BOND_CLOSE = 0.5 AutoReadOnly
Float Property BOND_FALLEN_OUT = -0.25 AutoReadOnly

; O-29: what a lover made of hearing about the others.
Int Property JEALOUS_STUNG = 1 AutoReadOnly
Int Property JEALOUS_THRILLED = 2 AutoReadOnly
Int Property JEALOUS_SHRUGGED = 3 AutoReadOnly

; O-30: after "not now" or "not here" the day stamp comes down to this far ahead
; of now (game days; about 14 game minutes), not to 0 -- so nothing of that
; conversation's own tail can reopen it.
Float Property REOPEN_AFTER = 0.01 AutoReadOnly

; O-16, the player's priority lane (owner, 2026-09-23): Rapport's one scene slot is
; HELD for the player and this NPC from the moment the proposition would be a yes,
; so Chemistry cannot take it while the player picks, the yes plays and the request
; goes in. Refreshed at the yes to cover the minute of retries; let go when the
; conversation ends without one, or when the retries give up.
Float Property HOLD_AT_VERDICT = 90.0 AutoReadOnly
Float Property HOLD_AT_YES = 70.0 AutoReadOnly

; ONE conversation: who, and what it learned, for what the next conversation
; reads and for the Narrator's one line (O-9). A NEW one per conversation, so the
; end of one can never read the next one's facts: whoever holds a reference holds
; that conversation, whatever begins meanwhile.
Struct Conversation
	Actor who
	Int serial = 0
	String intro = ""
	Float bondBefore = 0.0
	Float bondAfter = 0.0
	; The last reply: its stage and what it did.
	Int stage = 0
	Int outcome = 0
	; How far it got: a land at stages 1-2, any answer at all at stage 3.
	Int reached = 0
	; Stage 3's verdict and why, once decided (0: never).
	Int verdict = 0
	Int why = 0
	; O-29: JEALOUS_*, or 0.
	Int jealous = 0
	; O-27: they became lovers to the world during it.
	Bool lovers = False
	; A yes that asked Rapport for a scene (not when scenes are switched off).
	Bool sceneAsked = False
EndStruct

Conversation _current = None
Int _serial = 0
; The conversation whose OnEnd started the end timer.
Int _endingSerial = 0

Int _api = 0
Int _why = 0
Actor _held = None
Actor _yesWith = None
Int _yesTries = 0

MCP:Bridge Function Bridge()
	Return Game.GetFormFromFile(BRIDGE_ID, "F4MCP.esp") as MCP:Bridge
EndFunction

Scene Function ApproachScene()
	Return Game.GetFormFromFile(SCENE_ID, "Overture.esp") as Scene
EndFunction

ReferenceAlias Function TargetAlias()
	Return (Self as Quest).GetAlias(TARGET_ALIAS) as ReferenceAlias
EndFunction

GlobalVariable Function PersonaGlobal()
	Return Game.GetFormFromFile(PERSONA_GLOBAL_ID, "Overture.esp") as GlobalVariable
EndFunction

GlobalVariable Function PublicGlobal()
	Return Game.GetFormFromFile(PUBLIC_GLOBAL_ID, "Overture.esp") as GlobalVariable
EndFunction

GlobalVariable Function EnabledGlobal()
	Return Game.GetFormFromFile(ENABLED_GLOBAL_ID, "Overture.esp") as GlobalVariable
EndFunction

GlobalVariable Function VerdictGlobal()
	Return Game.GetFormFromFile(VERDICT_GLOBAL_ID, "Overture.esp") as GlobalVariable
EndFunction

GlobalVariable Function ScenesGlobal()
	Return Game.GetFormFromFile(SCENES_GLOBAL_ID, "Overture.esp") as GlobalVariable
EndFunction

GlobalVariable Function LastOutcomeGlobal()
	Return Game.GetFormFromFile(LAST_OUTCOME_GLOBAL_ID, "Overture.esp") as GlobalVariable
EndFunction

; One of this plugin's actor values, or None (the one-exchange build has only
; the first two).
ActorValue Function AV(Int aiID)
	Return Game.GetFormFromFile(aiID, "Overture.esp") as ActorValue
EndFunction

; An actor value's number on this actor, or -1 where the plugin has no such value.
Float Function ValueOf(Actor akWho, Int aiID)
	ActorValue av = Self.AV(aiID)
	If av == None
		Return -1.0
	EndIf
	Return akWho.GetValue(av)
EndFunction

Function SetTo(Actor akWho, Int aiID, Float afValue)
	ActorValue av = Self.AV(aiID)
	If av != None
		akWho.SetValue(av, afValue)
	EndIf
EndFunction

; Rapport owns the persona; Overture only reads it (O-1). The order here IS the
; global's value and it must match PERSONAS in tools/make_overture_esp.py -- if
; the two drift, every NPC gets somebody else's reply and nothing errors.
Int Function PersonaIndex(Actor akWho)
	If akWho == None
		Return -1
	EndIf
	String name = Rapport:Core.PersonaOf(akWho.GetFormID())
	If name == "mercantile"
		Return 0
	ElseIf name == "romantic"
		Return 1
	ElseIf name == "vulgar"
		Return 2
	ElseIf name == "reticent"
		Return 3
	EndIf
	Return -1
EndFunction

Event OnQuestInit()
	Self.Hook()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	; Registrations are re-made on every load: the F4MCP plugin forgets its addons
	; on a save change, and doing the scene's here too costs nothing.
	Self.Hook()
EndEvent

Function Hook()
	Self.RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")

	_api = Rapport:Core.ApiVersion()
	If _api < NEEDS_API
		Debug.Trace("Overture: Rapport's ApiVersion is " + _api + ", Overture needs " + NEEDS_API + " - no narration, no names, no lovers, and nobody counts as watching", 2)
		Debug.Notification("Overture needs Rapport 0.2.1 or newer.")
	EndIf
	If MCM.IsInstalled() && MCM.GetModSettingFloat("Overture", "fLoverBond:Bars") <= 0.0
		Debug.Trace("Overture: MCM is installed but has no Overture settings (MCM/Config/Overture/settings.ini missing?) - using the built-in numbers", 1)
	EndIf

	; A conversation whose end was still owed when the game was saved. Whether its
	; timer outlived the load or not, it ends now; the timer then finds nobody.
	Self.EndConversation(True)

	; THE ALWAYS-ON HALF. The scene's own events, for every approach the engine
	; opens -- the dev verb is not involved.
	Scene sc = Self.ApproachScene()
	If sc != None
		Self.RegisterForRemoteEvent(sc, "OnBegin")
		Self.RegisterForRemoteEvent(sc, "OnEnd")
		; The phase trail, for the log: which phase a conversation is in is the
		; one thing no F4MCP event shows, and the staged scene's branching is
		; nothing but phases.
		Self.RegisterForRemoteEvent(sc, "OnPhaseBegin")
	EndIf

	MCP:Bridge bridge = Self.Bridge()
	If bridge == None
		; No F4MCP installed. Not an error - this is a dev channel, and a player
		; without it simply has no verbs.
		Return
	EndIf
	; MANGLED names, and against the DECOMPILED base sources this is not
	; optional: registering "OnHello" makes the VM answer that it cannot handle
	; the event, because the handler below compiles under the mangled name.
	Self.RegisterForCustomEvent(bridge, "mcp:bridge_OnHello")
	Self.RegisterForCustomEvent(bridge, "mcp:bridge_OnVerb")
EndFunction

Event Scene.OnBegin(Scene akSender)
	Actor who = Self.TargetAlias().GetActorReference()
	If who == None
		Debug.Trace("Overture: the approach scene began with NOBODY in the alias - ALFA did not fill it", 1)
		Return
	EndIf
	; What the NPC's first reply reads, FIRST: it is chosen seconds from now.
	String note = Self.Prepare(who)
	Self.Stamp(who)
	; The last conversation, if its end is still owed -- its OnEnd's second has not
	; passed, or its OnEnd never came. It ends with its own facts, and without the
	; tidy-up: this conversation has the alias and the globals now.
	Self.EndConversation(False)
	Conversation c = Self.BeginTalk(who)
	note = note + Self.Opening(c)
	If c.intro != ""
		note = note + " | introduced as " + c.intro
	EndIf
	Debug.Trace("Overture: approach opened with " + who.GetFormID() + note, 0)
EndEvent

Event Scene.OnPhaseBegin(Scene akSender, Int auiPhaseIndex)
	Debug.Trace("Overture: scene phase " + auiPhaseIndex + " began", 0)
EndEvent

Event Scene.OnEnd(Scene akSender)
	; NOT NOW. This event and the last reply's own OnEnd (Overture:Reply, another
	; script object) have no order between them, and that reply's facts are this
	; conversation's: its stage, its outcome, a yes. A second later they are in;
	; if the next conversation begins sooner, its OnBegin ends this one first.
	; (And NOT IsPlaying(): MEASURED 2026-09-23 on a Third Rail Drifter, this event
	; arrives while the scene still reports it, five seconds later too.)
	Conversation c = _current
	If c == None
		; Nobody's conversation: the tidy-up alone.
		Self.Tidy(None)
		Return
	EndIf
	_endingSerial = c.serial
	Self.StartTimer(END_DELAY, END_TIMER)
EndEvent

Event OnTimer(Int aiTimerID)
	If aiTimerID == YES_TIMER
		Self.AskForTheScene()
	ElseIf aiTimerID == END_TIMER
		; Only the conversation that started it: one that has begun since is not over.
		Conversation c = _current
		If c != None && c.serial == _endingSerial
			Self.EndConversation(True)
		EndIf
	EndIf
EndEvent

; ---- one conversation ---------------------------------------------------------

Conversation Function BeginTalk(Actor who)
	Conversation c = new Conversation
	c.who = who
	_serial += 1
	c.serial = _serial
	; Current BEFORE anything that can yield, so a reply that ends meanwhile finds it.
	_current = c
	; O-10: a nameless NPC gets a name on their first approach. Rapport decides who
	; is nameless and keeps it; "" means no new name.
	If _api >= NEEDS_API
		c.intro = Rapport:Core.Introduce(who)
	EndIf
	c.bondBefore = Rapport:Relations.BondBetween(Game.GetPlayer(), who)
	c.bondAfter = c.bondBefore
	Return c
EndFunction

; What this conversation opens with, decided as it begins -- seconds before the
; player can pick. Returns the note.
String Function Opening(Conversation c)
	Actor who = c.who
	String note = ""
	If _api >= NEEDS_API
		note = note + Self.UpdateWorldLovers(c)
		note = note + Self.Jealousy(c)
	EndIf
	If !Self.OpensAtProposition(who)
		Return note
	EndIf
	; The scene skips stages 1 and 2 on markers written before it began; what the
	; proposition will answer is decided here, on the bond as it stands now, by
	; the same rules as everyone's.
	GlobalVariable verdict = Self.VerdictGlobal()
	If verdict == None
		Return note
	EndIf
	Int decided = Self.Decide(who, Rapport:Relations.BondBetween(Game.GetPlayer(), who), Self.RoomIsPublic())
	c.verdict = decided
	c.why = _why
	verdict.SetValue(decided as Float)
	If decided == VERDICT_ACCEPT
		Self.Hold(who, HOLD_AT_VERDICT)
	EndIf
	Return note + " | opens at the proposition, verdict " + decided + " (why " + c.why + ")"
EndFunction

; The phase conditions' own test (tools/overture_stages.py at_proposition), in
; Papyrus: they said yes before (O-12), the lover tier (O-14), or an invitation
; that lasts until tonight (O-30). If the two ever disagree, a conversation opens
; at the proposition with no verdict decided, and the fallback beat says so.
Bool Function OpensAtProposition(Actor akWho)
	If Self.ValueOf(akWho, SAID_YES_AV_ID) == 1.0
		Return True
	EndIf
	If Self.ValueOf(akWho, TIER_AV_ID) == TIER_LOVER as Float
		Return True
	EndIf
	Return Self.ValueOf(akWho, INVITED_UNTIL_AV_ID) > Utility.GetCurrentGameTime()
EndFunction

; The conversation's end, from its OnEnd a second late, from the next one's
; OnBegin, or from a load -- whichever comes first, and once: it is closed before
; anything that can yield, so a second caller finds nobody.
Function EndConversation(Bool abTidy)
	Conversation c = _current
	If c == None
		Return
	EndIf
	_current = None
	Actor who = c.who
	; No yes in this conversation: nothing will ask for the slot it may be holding.
	If c.outcome != OUTCOME_ACCEPT
		Self.LetGo(who)
	EndIf
	String note = Self.BetweenConversations(c)
	Self.Narrate(c)
	Debug.Trace("Overture: the conversation with " + who.GetFormID() + " ended - last reply stage " + c.stage + " outcome " + c.outcome + note, 0)
	If abTidy
		Self.Tidy(who)
	EndIf
EndFunction

; What the next conversation will read as it starts -- its greeting and its phase
; conditions, which cannot wait for a script -- so it is all written here, between
; conversations. Returns the note.
String Function BetweenConversations(Conversation c)
	Actor who = c.who
	String note = ""
	; How far it got. Never mid-conversation: phase 2 reads it the moment stage 1
	; ends, and a reticent's first land written then would open stage 2 on the day
	; R-8 says nothing more happens (microscope pass 1).
	If c.reached > 0 && Self.RaiseStageReached(who, c.reached)
		note = note + " | stage reached " + c.reached
	EndIf
	; O-30 (owner, 2026-09-23): after "not now" or "not here", the rest of today
	; opens at the proposition -- no flirt replayed, no bond paid twice -- and the
	; day stamp comes down, so there is a rest of today (O-13's "not now leaves the
	; day unstamped"). Until the "not here" follow is built, "not here" gets the same.
	If c.outcome == OUTCOME_NOT_NOW || c.outcome == OUTCOME_NOT_HERE
		Float now = Utility.GetCurrentGameTime()
		Self.SetTo(who, INVITED_UNTIL_AV_ID, (Math.Floor(now) + 1) as Float)
		Self.SetTo(who, NEXT_DAY_AV_ID, now + REOPEN_AFTER)
		note = note + " | invited back today"
	EndIf
	If _api >= NEEDS_API
		note = note + Self.UpdateWorldLovers(c)
	EndIf
	Int tier = Self.TierOf(who)
	Self.SetTo(who, TIER_AV_ID, tier as Float)
	note = note + " | tier " + tier
	; O-28: a falling-out ends it on Overture's side too -- the opening a yes
	; earned. Rapport ends its own lovers flag at the same line.
	If tier == TIER_FALLEN_OUT && Self.ValueOf(who, SAID_YES_AV_ID) == 1.0
		Self.SetTo(who, SAID_YES_AV_ID, 0.0)
		note = note + " | fallen out: a yes no longer opens at the proposition"
	EndIf
	Return note
EndFunction

; True if it moved: the marker only ever goes up.
Bool Function RaiseStageReached(Actor akWho, Int aiStage)
	ActorValue reached = Self.AV(STAGE_REACHED_AV_ID)
	If reached == None || akWho.GetValue(reached) >= aiStage as Float
		Return False
	EndIf
	akWho.SetValue(reached, aiStage as Float)
	Return True
EndFunction

; O-14's tier, from the bond as it stands.
Int Function TierOf(Actor akWho)
	Actor player = Game.GetPlayer()
	Float bond = Rapport:Relations.BondBetween(player, akWho)
	If bond <= BOND_FALLEN_OUT
		Return TIER_FALLEN_OUT
	EndIf
	If bond >= Self.Tuned("fLoverBond:Bars", 0.75) || Rapport:Relations.ArePartners(player, akWho)
		Return TIER_LOVER
	EndIf
	If _api >= NEEDS_API && Rapport:Core.AreLovers(player.GetFormID(), akWho.GetFormID())
		Return TIER_LOVER
	EndIf
	If bond >= BOND_CLOSE
		Return TIER_CLOSE
	ElseIf bond >= BOND_WARM
		Return TIER_WARM
	EndIf
	Return TIER_STRANGER
EndFunction

; O-27 (owner, 2026-09-23): lovers to the WORLD -- Rapport's lovers flag, which
; Chemistry reads as spoken for -- takes a bond of fLoverBond AND at least one
; scene together: a yes is a promise, the scene is the fact. Asked as a
; conversation opens and as it ends, the two moments Overture hears of. Rapport
; ends it by itself at a falling-out (O-28). Returns the note.
String Function UpdateWorldLovers(Conversation c)
	Actor who = c.who
	Actor player = Game.GetPlayer()
	Int p = player.GetFormID()
	Int id = who.GetFormID()
	If Rapport:Core.AreLovers(p, id)
		Return ""
	EndIf
	Int together = Rapport:Core.PairSceneCount(p, id)
	If together < 1
		Return ""
	EndIf
	Float bond = Rapport:Relations.BondBetween(player, who)
	If bond < Self.Tuned("fLoverBond:Bars", 0.75)
		Return ""
	EndIf
	Rapport:Core.SetLovers(p, id, True)
	; Jealousy counts from here: what the player did before is not this lover's business.
	Self.SetTo(who, JEALOUSY_MARK_AV_ID, (Rapport:Core.SceneCount(p) - together + 1) as Float)
	c.lovers = True
	Return " | lovers now (bond " + bond + ", " + together + " scene(s) together)"
EndFunction

; O-29 (owner, 2026-09-23): a lover hears about the others. Rapport counts every
; scene the player has had and every one with this lover, so the difference is
; the scenes with anyone else. The mark is that difference, plus one, as this
; lover last knew it; 0 is "never counted", counted now with nothing to react to,
; so nobody answers for what happened before they were a lover. What it means is
; the persona's -- methodology 11's table, which the owner applied to strangers
; too: the romantic and the reticent take it badly, the mercantile shrugs, the
; vulgar likes hearing it. Once per conversation, however many there were.
; Returns the note.
String Function Jealousy(Conversation c)
	Actor who = c.who
	Actor player = Game.GetPlayer()
	Int p = player.GetFormID()
	Int id = who.GetFormID()
	ActorValue mark = Self.AV(JEALOUSY_MARK_AV_ID)
	If mark == None || !Rapport:Core.AreLovers(p, id)
		Return ""
	EndIf
	Int others = Rapport:Core.SceneCount(p) - Rapport:Core.PairSceneCount(p, id)
	Int known = who.GetValue(mark) as Int
	; Written before anything else can run: a second look finds nothing new.
	who.SetValue(mark, (others + 1) as Float)
	If known == 0 || others < known
		Return ""
	EndIf
	String note = " | heard about " + (others - known + 1) + " scene(s) with someone else"
	Int persona = Self.PersonaIndex(who)
	Float worth = 0.0
	If persona == 1 || persona == 3
		c.jealous = JEALOUS_STUNG
		worth = Self.Tuned("fJealousySting:Jealousy", -0.06)
	ElseIf persona == 2
		c.jealous = JEALOUS_THRILLED
		worth = Self.Tuned("fJealousyThrill:Jealousy", 0.03)
	ElseIf persona == 0
		c.jealous = JEALOUS_SHRUGGED
	Else
		Return note + ", and no persona to react with"
	EndIf
	If worth != 0.0
		Float after = Rapport:Relations.AddBondBetween(player, who, worth, REASON_DIALOGUE)
		c.bondAfter = after
		note = note + ", bond now " + after
	EndIf
	Return note
EndFunction

; ---- the numbers --------------------------------------------------------------

; A number the MCM page tunes, or the default when MCM has nothing for Overture:
; not installed, or MCM/Config/Overture/settings.ini missing. MCM answers 0 for
; every key then, and fLoverBond can never be 0 -- its slider starts at 0.3 -- so
; a 0 there means "no settings", never a player's choice. tools/overture_stages.py
; SETTINGS is the table; tools/make_mcm.py writes the page and the ini from it and
; refuses to, if any call here names a key it lacks or falls back to a different
; default.
Float Function Tuned(String asKey, Float afDefault)
	If !MCM.IsInstalled() || MCM.GetModSettingFloat("Overture", "fLoverBond:Bars") <= 0.0
		Return afDefault
	EndIf
	Return MCM.GetModSettingFloat("Overture", asKey)
EndFunction

; What a reply is worth to the bond (docs/methodology.md 3): a fraction of the
; distance left, the way every source moves Rapport's store.
Float Function Worth(Int aiStage, Int aiOutcome)
	If aiOutcome == OUTCOME_LAND
		If aiStage >= 2
			Return Self.Tuned("fLandSecond:Words", 0.07)
		EndIf
		Return Self.Tuned("fLandFirst:Words", 0.05)
	ElseIf aiOutcome == OUTCOME_OFFEND
		Return Self.Tuned("fOffend:Words", -0.04)
	ElseIf aiOutcome == OUTCOME_RECOIL
		Return Self.Tuned("fRecoil:Words", -0.06)
	ElseIf aiOutcome == OUTCOME_NOTYET
		Return Self.Tuned("fNotYet:Words", 0.02)
	ElseIf aiOutcome == OUTCOME_REFUSE
		Return Self.Tuned("fRefuse:Words", -0.03)
	EndIf
	; A miss is the player learning, a recoil on the persona it would have landed
	; with is "yes, not here", and a yes writes nothing: the scene does, and
	; writing both would be R-10's double count through the other door.
	Return 0.0
EndFunction

; The bond a yes needs, per persona, in PERSONAS order (methodology 3). ASSUMED.
Float Function Threshold(Int aiPersona)
	If aiPersona == 0
		Return Self.Tuned("fBarMercantile:Bars", 0.15)
	ElseIf aiPersona == 1
		Return Self.Tuned("fBarRomantic:Bars", 0.25)
	ElseIf aiPersona == 2
		Return Self.Tuned("fBarVulgar:Bars", 0.08)
	EndIf
	Return Self.Tuned("fBarReticent:Bars", 0.30)
EndFunction

; ---- the verdict --------------------------------------------------------------

; The romantic's setting (R-8: "fancy words, patience, setting"): indoors, or
; after dark. Being in public is handled before this, by "not here". Night is
; RAPPORT's night -- the GameHour global, 20:00 to 06:00 (Pairing.cpp) -- so the
; two mods agree about when it is dark.
Bool Function Setting(Actor akWho)
	If akWho.IsInInterior()
		Return True
	EndIf
	GlobalVariable clock = Game.GetFormFromFile(GAME_HOUR_ID, "Fallout4.esm") as GlobalVariable
	If clock == None
		Return False
	EndIf
	Float hour = clock.GetValue()
	Return hour >= 20.0 || hour < 6.0
EndFunction

; Public or private, for this actor, right now: Rapport's own count against its
; own tolerance (C-6). Unknown -- no scan yet, or a Rapport too old to count -- is
; public, as in Prepare.
Bool Function InPublic(Actor akWho)
	If _api < NEEDS_API
		Return True
	EndIf
	Int watching = Rapport:Core.ObserversNear(akWho.GetFormID())
	Return watching < 0 || watching > Rapport:Core.ObserverTolerance()
EndFunction

; The room this conversation's Prepare measured. No global: public.
Bool Function RoomIsPublic()
	GlobalVariable inPublic = Self.PublicGlobal()
	Return inPublic == None || inPublic.GetValue() != 0.0
EndFunction

; What the bond WILL be once a land worth afWorth has been written: Rapport's
; own arithmetic, a fraction of the distance left (Ledger.cpp AddBond).
Float Function AfterLand(Float afBond, Float afWorth)
	If afWorth > 0.0
		Return afBond + afWorth * (1.0 - afBond)
	EndIf
	Return afBond + afWorth * (1.0 + afBond)
EndFunction

String Function ScenarioFor(Actor akWho, Int aiPersona)
	Bool inside = akWho.IsInInterior()
	If aiPersona == 1
		Return "tender"
	ElseIf inside
		Return "athome"
	ElseIf aiPersona == 2
		Return "quickie"
	EndIf
	Return "tender"
EndFunction

Bool Function SpokenFor(Actor akWho)
	Return Rapport:Relations.HasPartner(akWho) && !Rapport:Relations.ArePartners(Game.GetPlayer(), akWho)
EndFunction

; Stage 3's verdict for the register that got here, for a given bond and room
; (docs/methodology.md 2). The rules are the same for everyone: a lover, or
; someone whose conversation opens at the proposition, only skips the flirt --
; faithfulness at fFaithRefuses refuses whatever the bond (methodology 7).
; Leaves the reason in _why, for the caller that wants it.
Int Function Decide(Actor akWho, Float afBond, Bool abPublic)
	Int persona = Self.PersonaIndex(akWho)
	If persona < 0
		_why = WHY_NO_PERSONA
		Return VERDICT_REFUSE
	EndIf
	If afBond <= BOND_FALLEN_OUT
		_why = WHY_FALLEN_OUT
		Return VERDICT_REFUSE
	EndIf
	Float bar = Self.Threshold(persona)
	If Self.SpokenFor(akWho)
		Float faith = Rapport:Core.FaithfulnessOf(akWho.GetFormID())
		If faith >= Self.Tuned("fFaithRefuses:SpokenFor", 0.80)
			_why = WHY_TAKEN
			Return VERDICT_REFUSE
		EndIf
		bar += Self.Tuned("fFaithWeight:SpokenFor", 0.40) * faith
	EndIf
	If afBond < bar
		If afBond < bar * 0.5
			_why = WHY_EARLY
			Return VERDICT_REFUSE
		EndIf
		_why = WHY_BOND
		Return VERDICT_NOTYET
	EndIf
	If abPublic
		_why = WHY_PUBLIC
		Return VERDICT_NOT_HERE
	EndIf
	If persona == 1 && !Self.Setting(akWho)
		_why = WHY_SETTING
		Return VERDICT_NOT_NOW
	EndIf
	If Rapport:Core.Busy() || Rapport:Core.CanRun(Self.ScenarioFor(akWho, persona), Game.GetPlayer(), akWho) < 0
		_why = WHY_BUSY
		Return VERDICT_NOT_NOW
	EndIf
	_why = WHY_YES
	Return VERDICT_ACCEPT
EndFunction

; ---- the replies --------------------------------------------------------------

; Called by Overture:Reply as an NPC's reply line BEGINS. The one thing decided
; here is stage 3's verdict, at the start of the stage-2 land: the land line
; itself runs about 4.5 s and the phase-3 gate is read only when it ENDS, so
; nothing races. The bond it decides on is the bond this land is about to write.
Function ReplyBegins(Actor akWho, Int aiStage, Int aiOutcome)
	If akWho == None
		Return
	EndIf
	; The branch: the next phase reads this when the line ENDS. The reticent's
	; first-meeting land records no land here -- R-8, nothing more the first time
	; -- so that conversation hands back after it.
	GlobalVariable last = Self.LastOutcomeGlobal()
	; Every stage: after a yes, HandBack must not start (the dialogue closes for
	; Rapport's scene), and it reads this to know.
	If last != None
		Int recorded = aiOutcome
		If aiStage == 1 && aiOutcome == OUTCOME_LAND && Self.PersonaIndex(akWho) == 3
			recorded = 0
		EndIf
		last.SetValue(recorded as Float)
	EndIf

	GlobalVariable verdict = Self.VerdictGlobal()
	If verdict == None || aiStage != 2 || aiOutcome != OUTCOME_LAND
		Return
	EndIf
	Float bond = Self.AfterLand(Rapport:Relations.BondBetween(Game.GetPlayer(), akWho), Self.Tuned("fLandSecond:Words", 0.07))
	Int decided = Self.Decide(akWho, bond, Self.RoomIsPublic())
	Int why = _why
	verdict.SetValue(decided as Float)
	Conversation c = _current
	If c != None && c.who == akWho
		c.verdict = decided
		c.why = why
	EndIf
	Debug.Trace("Overture: " + akWho.GetFormID() + " stage 3 verdict " + decided + " (why " + why + ") on bond " + bond, 0)
	If decided == VERDICT_ACCEPT
		Self.Hold(akWho, HOLD_AT_VERDICT)
	EndIf
EndFunction

; Called by Overture:Reply when an NPC's reply line has been said. Writes the
; bond (R-10: add this much, for this reason), and what the conversation has
; reached, which its end turns into where the next one starts.
Function Replied(Actor akWho, Int aiStage, Int aiOutcome)
	If akWho == None
		Return
	EndIf
	; This conversation's facts FIRST, before anything that can yield: its end may
	; be waiting on exactly this reply.
	Int reached = 0
	If aiOutcome == OUTCOME_LAND || aiStage == 3
		reached = aiStage
	EndIf
	Conversation c = _current
	If c != None && c.who != akWho
		c = None
	EndIf
	If c != None
		c.stage = aiStage
		c.outcome = aiOutcome
		If reached > c.reached
			c.reached = reached
		EndIf
	EndIf
	String note = "Overture: " + akWho.GetFormID() + " replied, stage " + aiStage + " outcome " + aiOutcome
	Float worth = Self.Worth(aiStage, aiOutcome)
	If worth != 0.0
		Float before = Rapport:Relations.BondBetween(Game.GetPlayer(), akWho)
		Float after = Rapport:Relations.AddBondBetween(Game.GetPlayer(), akWho, worth, REASON_DIALOGUE)
		note = note + " | bond " + before + " -> " + after
		If c != None
			c.bondAfter = after
		EndIf
	EndIf
	If c == None && reached > 0 && Self.RaiseStageReached(akWho, reached)
		; Its conversation had already ended: nothing reads a stage mid-conversation
		; any more, so it goes straight in.
		note = note + " | stage reached " + reached + ", after its conversation ended"
	EndIf
	If aiOutcome == OUTCOME_ACCEPT
		; O-12: they said yes once, and their conversations open at the proposition
		; from now on. Overture's marker only -- lovers to the world takes a scene
		; as well (O-27).
		Self.SetTo(akWho, SAID_YES_AV_ID, 1.0)
		Bool asked = Self.ScenesOn()
		If c != None
			c.sceneAsked = asked
		EndIf
		Self.Proposition(akWho, asked)
		note = note + " | said yes"
	EndIf
	Debug.Trace(note, 0)
EndFunction

; ---- a yes --------------------------------------------------------------------

Bool Function ScenesOn()
	GlobalVariable scenes = Self.ScenesGlobal()
	Return scenes != None && scenes.GetValue() != 0.0
EndFunction

; Stage 4, behind OvertureScenesEnabled until a Rapport scene with the player in
; it has been watched end to end (methodology 5).
Function Proposition(Actor akWho, Bool abScenes)
	If !abScenes
		Debug.Trace("Overture: " + akWho.GetFormID() + " said yes; scenes are off (OvertureScenesEnabled 0)", 0)
		Self.LetGo(akWho)
		Return
	EndIf
	If _yesWith != None && _yesWith != akWho
		; The player has moved on to someone else: the older yes gives way, and says so.
		Self.GiveUpYes("the player said yes to someone else first")
	EndIf
	Self.Hold(akWho, HOLD_AT_YES)
	; Seconds have passed since the verdict checked Rapport was free, and Chemistry
	; can take the only scene slot in between -- so ask now, and keep asking for a
	; minute rather than letting a yes vanish.
	_yesWith = akWho
	_yesTries = 0
	Self.AskForTheScene()
EndFunction

Function AskForTheScene()
	Actor akWho = _yesWith
	If akWho == None
		Return
	EndIf
	Actor player = Game.GetPlayer()
	Bool took = False
	If !Rapport:Core.Busy()
		; "_bond": the raw bond, a fact for the Narrator's words; a label without
		; the underscore is a score share and would be printed as one.
		Rapport:Core.NarrateBonus(player.GetFormID(), akWho.GetFormID(), "_bond", Rapport:Relations.BondBetween(player, akWho))
		took = Rapport:Core.RequestScene(player, akWho, Self.ScenarioFor(akWho, Self.PersonaIndex(akWho)))
	EndIf
	If took
		; AFTER the request, as Chemistry does it: Rapport stages an affair only
		; for the pair already in flight, and records it only if the scene
		; really starts (PapyrusLink.cpp StageAffair; C-9).
		If Self.SpokenFor(akWho)
			Rapport:Core.NoteAffair(player.GetFormID(), akWho.GetFormID())
		EndIf
		Debug.Trace("Overture: " + akWho.GetFormID() + " said yes; Rapport took the scene", 0)
		; Rapport let the hold go itself when it accepted the request.
		If _held == akWho
			_held = None
		EndIf
		If _yesWith == akWho
			_yesWith = None
		EndIf
		Return
	EndIf
	If _yesWith != akWho
		; Given up, or replaced by a newer yes, while this was asking.
		Return
	EndIf
	_yesTries += 1
	If _yesTries >= YES_RETRIES
		Self.GiveUpYes("Rapport never had a free slot")
		Return
	EndIf
	Self.StartTimer(YES_RETRY_SECONDS, YES_TIMER)
EndFunction

; A yes that will never get its scene: said, so it does not vanish without a word.
Function GiveUpYes(String asWhy)
	Actor who = _yesWith
	If who == None
		Return
	EndIf
	_yesWith = None
	Debug.Trace("Overture: " + who.GetFormID() + " said yes and " + asWhy + " - the yes is lost", 1)
	If _api >= NEEDS_API
		Rapport:Core.NarrateLine(Game.GetPlayer().GetFormID(), who.GetFormID(), "{second} said yes, but the moment passed.", "")
	EndIf
	Self.LetGo(who)
EndFunction

; Hold Rapport's slot for the player and this NPC (O-16) -- only when a yes would
; really ask for a scene, and never over a yes still waiting for its own: the
; slot has one hold, and a verdict is not a yes.
Function Hold(Actor akWho, Float afSeconds)
	If _api < NEEDS_API || !Self.ScenesOn()
		Return
	EndIf
	If _yesWith != None && _yesWith != akWho
		Return
	EndIf
	Rapport:Core.ReservePlayerScene(akWho, afSeconds)
	_held = akWho
EndFunction

; Let this NPC's hold go, if this script holds one for them. A release names its
; hold -- Rapport's rule too -- so one conversation cannot free another's.
Function LetGo(Actor akWho)
	If akWho == None || _held != akWho
		Return
	EndIf
	_held = None
	If _api >= NEEDS_API
		Rapport:Core.ReservePlayerScene(akWho, 0.0)
	EndIf
EndFunction

; ---- O-9: the Narrator --------------------------------------------------------
; The owner, 2026-09-23: "we definitely need a narrator here as we have for
; chemistry" -- to let players know, without killing the mood, what is
; happening and how when they act. So: ONE line per conversation, when it has
; really ended, through Rapport's Narrator (O-1: one module narrates every
; mod). It says what the player's words did and hints at what to do about it:
; the place, the time, patience, another way. It NEVER names a persona -- the
; README's rule, "you are never told who they are", stands over this too.
; On a yes that asked for a scene, only what Rapport's own line cannot know --
; lovers now, and a lover's jealousy -- since that line says who and why as the
; scene starts.
Function Narrate(Conversation c)
	If _api < NEEDS_API
		Return
	EndIf
	Bool yes = c.outcome == OUTCOME_ACCEPT && c.sceneAsked
	String headline = ""
	; Once {second} has been said, the sentences after it say {they}. Rapport fills
	; both, and capitalises each sentence -- never write a pronoun here as a
	; literal: Papyrus pools strings case-insensitively, and "He" came back "he".
	Bool named = False
	If c.intro != "" && !yes
		headline = "{their} name is {second}."
		named = True
	EndIf
	If c.lovers
		headline = Self.Then(headline, "You and {second} are lovers now.")
		named = True
	EndIf
	If c.jealous == JEALOUS_STUNG
		headline = Self.Then(headline, Self.Subject(named) + " heard you've been with someone else. It stung.")
		named = True
	ElseIf c.jealous == JEALOUS_THRILLED
		headline = Self.Then(headline, Self.Subject(named) + " heard you've been with someone else - and liked hearing it.")
		named = True
	ElseIf c.jealous == JEALOUS_SHRUGGED && !yes
		headline = Self.Then(headline, Self.Subject(named) + " heard you've been with someone else, and didn't mind.")
		named = True
	EndIf
	If !yes
		headline = Self.Then(headline, Self.TalkLine(c, named))
	EndIf
	If headline == ""
		Return
	EndIf
	; Only a bond that MOVED. "bond +0.00" under a miss read as a change of nothing
	; when it was the bond itself (first run, 2026-09-23).
	String numbers = ""
	If c.bondAfter != c.bondBefore
		numbers = "bond " + Self.Signed(c.bondBefore) + " -> " + Self.Signed(c.bondAfter)
	EndIf
	Rapport:Core.NarrateLine(Game.GetPlayer().GetFormID(), c.who.GetFormID(), headline, numbers)
EndFunction

String Function Then(String asFirst, String asNext)
	If asFirst == ""
		Return asNext
	ElseIf asNext == ""
		Return asFirst
	EndIf
	Return asFirst + " " + asNext
EndFunction

; Their name the first time, their pronoun after. Every sentence puts it before
; a past tense or a modal, so "they" never needs a different verb.
String Function Subject(Bool abNamed)
	If abNamed
		Return "{they}"
	EndIf
	Return "{second}"
EndFunction

; What the conversation's last reply did, in one sentence. "" for nothing said
; and for a fallback beat.
String Function TalkLine(Conversation c, Bool abNamed)
	Int persona = Self.PersonaIndex(c.who)
	If persona < 0
		; No persona from Rapport: every reply was a neutral "..." and none of the
		; sentences below would be true.
		Return ""
	EndIf
	String s = Self.Subject(abNamed)
	Int outcome = c.outcome
	If outcome == OUTCOME_MISS
		If c.stage == 1
			Return s + " didn't take to that. Another day, another way."
		ElseIf c.stage == 2
			; A stage-2 miss is a DIFFERENT register from the one that landed.
			Return s + " didn't take to that. What worked before might work again."
		EndIf
		; Stage 3's misses are the fallback beats, not something the player chose.
		Return ""
	ElseIf outcome == OUTCOME_OFFEND
		Return s + " took offence. Not everyone likes it blunt."
	ElseIf outcome == OUTCOME_RECOIL
		Return s + " didn't care for that - least of all in front of people."
	ElseIf outcome == OUTCOME_RECOIL_LIKED
		Return s + " liked that - just not with people watching."
	ElseIf outcome == OUTCOME_LAND
		If c.stage == 1
			If persona == 3
				; R-8: nothing more the first time; the conversation handed back.
				Return s + " heard you out. Some people take time."
			EndIf
			; A first land always opens stage 2, so the player walked away from it.
			Return s + " warmed to you. Talk again tomorrow."
		EndIf
		; The stage-2 land, and what stage 3 would have said.
		If c.verdict == VERDICT_REFUSE
			Return s + " enjoyed that" + Self.WhyNot(c.why, " Only talk, for now - keep coming back.")
		EndIf
		If c.verdict == 0
			; No verdict recorded for this conversation, so whether stage 3 was
			; offered is unknown -- say only what is known.
			Return s + " enjoyed that."
		EndIf
		; Stage 3 was on the wheel and the player left without asking.
		Return s + " enjoyed that. You could have asked for more."
	ElseIf outcome == OUTCOME_ACCEPT
		; Only with scenes switched off (Narrate): nothing else will say it.
		Return s + " said yes."
	ElseIf outcome == OUTCOME_NOTYET
		Return "Close. A little more time with you, and " + s + " might."
	ElseIf outcome == OUTCOME_NOT_HERE
		Return s + " would - somewhere without an audience. Ask again later today."
	ElseIf outcome == OUTCOME_NOT_NOW
		If c.why == WHY_SETTING
			Return s + " would - indoors, or after dark. Ask again later today."
		EndIf
		Return s + " would - just not right now. Ask again later today."
	ElseIf outcome == OUTCOME_REFUSE
		If c.verdict == VERDICT_REFUSE
			; Even the right words would have been refused (a conversation that
			; opened at the proposition asks whatever the verdict), so the words are
			; not the reason.
			Return s + " turned you down" + Self.WhyNot(c.why, " Not yet - keep coming back.")
		EndIf
		Return s + " turned you down. That wasn't the way to ask."
	EndIf
	Return ""
EndFunction

; The end of a sentence about a refusal: the reason where it is one the player
; should know, else asWhenEarly.
String Function WhyNot(Int aiWhy, String asWhenEarly)
	If aiWhy == WHY_TAKEN
		Return " - but there's someone else."
	ElseIf aiWhy == WHY_FALLEN_OUT
		Return " - but there's bad blood between you."
	EndIf
	Return "." + asWhenEarly
EndFunction

; "+0.17", "-0.05": the Narrator's own format for a bond (Narrator.cpp Signed).
String Function Signed(Float afValue)
	String sign = "+"
	Float size = afValue
	If afValue < 0.0
		size = -afValue
	EndIf
	Int hundredths = Math.Floor(size * 100.0 + 0.5)
	If afValue < 0.0 && hundredths > 0
		sign = "-"
	EndIf
	Int fraction = hundredths % 100
	String digits = fraction as String
	If fraction < 10
		digits = "0" + digits
	EndIf
	Return sign + (hundredths / 100) + "." + digits
EndFunction

; ---- the scene ----------------------------------------------------------------

; Once a game day (O-8). The greeting compares this against GameDaysPassed, so
; the NPC opens again with tomorrow's first conversation. No timer, no list.
Function Stamp(Actor who)
	Self.SetTo(who, NEXT_DAY_AV_ID, (Math.Floor(Utility.GetCurrentGameTime()) + 1) as Float)
EndFunction

; The persona and the room, for whoever the approach is with. Returns the note.
; Must land before the NPC's reply is chosen -- after the player picks, seconds
; into the scene -- which OnBegin does.
String Function Prepare(Actor who)
	String note = ""
	GlobalVariable pg = Self.PersonaGlobal()
	Int persona = Self.PersonaIndex(who)
	If pg == None
		note = note + " | persona global did not resolve"
	ElseIf persona < 0
		pg.SetValue(-1.0)
		note = note + " | NO PERSONA from Rapport - no reply will match"
	Else
		pg.SetValue(persona as Float)
		note = note + " | persona=" + persona
	EndIf

	; O-4: an intimate register in a public room recoils even on the persona it
	; would otherwise land with. Rapport owns what "public" means -- its own
	; observer count against its own tolerance -- so the two never disagree.
	GlobalVariable inPublic = Self.PublicGlobal()
	If inPublic != None
		Int watching = -1
		If _api >= NEEDS_API
			watching = Rapport:Core.ObserversNear(who.GetFormID())
		EndIf
		If watching < 0
			; No scan has published yet, or this Rapport cannot count. NOT the same
			; as nobody watching, so assume public: a recoil the player did not
			; expect is a smaller mistake than a proposition shouted across a room.
			inPublic.SetValue(1.0)
			note = note + " | observers unknown, assuming public"
		ElseIf watching > Rapport:Core.ObserverTolerance()
			inPublic.SetValue(1.0)
			note = note + " | " + watching + " watching - PUBLIC"
		Else
			inPublic.SetValue(0.0)
			note = note + " | " + watching + " watching - private"
		EndIf
	EndIf

	; A verdict belongs to one conversation. 0 matches no stage-3 reply, so a
	; conversation that reaches stage 3 without a fresh one is silent, never
	; somebody else's yes.
	GlobalVariable verdict = Self.VerdictGlobal()
	If verdict != None
		verdict.SetValue(0.0)
	EndIf
	; And so does the last outcome: 0 opens no later phase.
	GlobalVariable last = Self.LastOutcomeGlobal()
	If last != None
		last.SetValue(0.0)
	EndIf
	Return note
EndFunction

; One scene serves every conversation, and clearing the alias under one that has
; already begun would break it. NOT IsPlaying(): MEASURED 2026-09-23, it still
; said True five seconds after OnEnd ("IsPlaying at the event True, after
; 5.000000 s True"), so it guarded nothing and the tidy-up never ran. The alias
; says it instead: ALFA puts the next speaker in it before their scene begins, so
; while it holds nobody else, nobody else has the scene.
Function Tidy(Actor akWas)
	Actor inAlias = Self.TargetAlias().GetActorReference()
	If inAlias != None && inAlias != akWas
		Debug.Trace("Overture: " + inAlias.GetFormID() + " already holds the alias - left as it is", 0)
		Return
	EndIf
	Debug.Trace("Overture: alias let go, persona and room forgotten", 0)
	Self.TargetAlias().Clear()
	; And forget who it was: a persona or a room left in the globals is the next
	; NPC's reply if their own OnBegin is late. -1 matches no reply (the staged
	; plugin's fallback says a neutral beat and hands back), and an unknown room
	; is public, as everywhere else here.
	GlobalVariable pg = Self.PersonaGlobal()
	If pg != None
		pg.SetValue(-1.0)
	EndIf
	GlobalVariable inPublic = Self.PublicGlobal()
	If inPublic != None
		inPublic.SetValue(1.0)
	EndIf
EndFunction

; ---- the dev channel ----------------------------------------------------------

Event MCP:Bridge.OnHello(MCP:Bridge akSender, Var[] akArgs)
	MCP:Core.RegisterAddon("overture", "approach")
EndEvent

Event MCP:Bridge.OnVerb(MCP:Bridge akSender, Var[] akArgs)
	; akArgs is FLAT: [0] verb, [1] rest, [2] tag, [3] token count, then
	; (token as String, token as form id) pairs from [4]. Fallout 4's Papyrus
	; cannot split a string, so the plugin hands over both readings.
	String verb = akArgs[0] as String
	If verb != "approach"
		Return
	EndIf
	String tag = akArgs[2] as String
	Int count = akArgs[3] as Int
	String first = ""
	If count > 0
		first = akArgs[4] as String
	EndIf

	; approach scenes on|off -- whether a yes really asks Rapport for a scene.
	; No actor: the switch is global.
	If first == "scenes"
		GlobalVariable scenes = Self.ScenesGlobal()
		If scenes == None
			MCP:Core.Reply(tag, "approach scenes: this Overture.esp has no OvertureScenesEnabled - build with --stages 3")
			Return
		EndIf
		If count > 1 && (akArgs[6] as String) == "on"
			scenes.SetValue(1.0)
		ElseIf count > 1 && (akArgs[6] as String) == "off"
			scenes.SetValue(0.0)
		EndIf
		MCP:Core.Reply(tag, "approach scenes: " + scenes.GetValue())
		Return
	EndIf

	; WHICH ACTOR. After a keyword (reset/forget/status/verdict) the actor is the
	; SECOND token; without one it is the FIRST. A token that is there and does not
	; resolve is NOT DONE -- never "whoever is nearest": `approach forget <typo>`
	; must not wipe a bystander (review 2026-09-23; F4MCP's own rule).
	; ("keyword" would be the Keyword type to a case-insensitive compiler.)
	Bool afterKeyword = first == "reset" || first == "forget" || first == "status" || first == "verdict"
	Int actorToken = 1
	If afterKeyword
		actorToken = 2
	EndIf
	Actor who = None
	If count >= actorToken
		Int formID = akArgs[3 + 2 * actorToken] as Int
		If formID != 0
			who = Game.GetForm(formID) as Actor
		EndIf
		If who == None
			MCP:Core.Reply(tag, "approach: NOT DONE - '" + (akArgs[2 + 2 * actorToken] as String) + "' is not a loaded actor reference")
			Return
		EndIf
	Else
		; No actor named: the nearest -- but FindClosestActorFromRef is a plain
		; radius search around the player's own position (decompiled Game.psc),
		; so it can hand back the player.
		who = Game.FindClosestActorFromRef(Game.GetPlayer(), 600.0)
		If who == Game.GetPlayer()
			who = None
		EndIf
	EndIf
	If who == None
		MCP:Core.Reply(tag, "approach: NOT DONE - nobody but the player within 600 units; name the actor")
		Return
	EndIf

	If first == "reset"
		If Self.AV(NEXT_DAY_AV_ID) == None
			MCP:Core.Reply(tag, "approach reset: the next-day actor value did not resolve")
			Return
		EndIf
		Self.SetTo(who, NEXT_DAY_AV_ID, 0.0)
		MCP:Core.Reply(tag, "approach reset: " + who.GetFormID() + " may be approached again today")
		Return
	EndIf

	; approach forget <npc> -- as if the player had never approached them: the day
	; stamp, the stage reached, every marker, and Rapport's lovers flag. The bond is
	; Rapport's, and stays -- so the next conversation's end may find the lover tier
	; again, which is the bond talking, not memory.
	If first == "forget"
		Self.SetTo(who, NEXT_DAY_AV_ID, 0.0)
		Self.SetTo(who, STAGE_REACHED_AV_ID, 0.0)
		Self.SetTo(who, TIER_AV_ID, 0.0)
		Self.SetTo(who, SAID_YES_AV_ID, 0.0)
		Self.SetTo(who, INVITED_UNTIL_AV_ID, 0.0)
		Self.SetTo(who, JEALOUSY_MARK_AV_ID, 0.0)
		If _api >= NEEDS_API
			Rapport:Core.SetLovers(Game.GetPlayer().GetFormID(), who.GetFormID(), False)
		EndIf
		MCP:Core.Reply(tag, "approach forget: " + who.GetFormID() + " starts again at stage 1, today, and is nobody's lover")
		Return
	EndIf

	; approach verdict <npc> -- what stage 3 would answer right now, changing
	; nothing. Its OWN room, not the global the last conversation left behind.
	If first == "verdict"
		Float bond = Rapport:Relations.BondBetween(Game.GetPlayer(), who)
		Bool room = Self.InPublic(who)
		MCP:Core.Reply(tag, "approach verdict: " + who.GetFormID() + " | verdict=" + Self.Decide(who, bond, room) + " (1 refuse 2 notyet 3 accept 4 not here 5 not now) why=" + _why + " | bond=" + bond + " | bar=" + Self.Threshold(Self.PersonaIndex(who)) + " | public=" + room + " | spokenFor=" + Self.SpokenFor(who))
		Return
	EndIf

	If first == "status"
		Float stamp = Self.ValueOf(who, NEXT_DAY_AV_ID)
		Float today = Utility.GetCurrentGameTime()
		String s = "approach status: " + who.GetFormID() + " | stamp=" + stamp + " days=" + today
		If stamp <= today
			s = s + " (open today)"
		Else
			s = s + " (closed until day " + stamp + ")"
		EndIf
		s = s + " | persona=" + Self.PersonaIndex(who) + " | teammate=" + who.IsPlayerTeammate()
		s = s + " | combat=" + who.IsInCombat() + " | scene=" + who.IsInScene() + " | child=" + who.IsChild()
		GlobalVariable en = Self.EnabledGlobal()
		If en != None
			s = s + " | enabled=" + en.GetValue()
		EndIf
		s = s + " | stageReached=" + Self.ValueOf(who, STAGE_REACHED_AV_ID) + " tier=" + Self.ValueOf(who, TIER_AV_ID)
		s = s + " saidYes=" + Self.ValueOf(who, SAID_YES_AV_ID) + " invitedUntil=" + Self.ValueOf(who, INVITED_UNTIL_AV_ID)
		s = s + " | opensAtProposition=" + Self.OpensAtProposition(who)
		Actor player = Game.GetPlayer()
		s = s + " | bond=" + Rapport:Relations.BondBetween(player, who)
		If _api >= NEEDS_API
			s = s + " | lovers=" + Rapport:Core.AreLovers(player.GetFormID(), who.GetFormID()) + " scenesTogether=" + Rapport:Core.PairSceneCount(player.GetFormID(), who.GetFormID()) + " jealousyMark=" + Self.ValueOf(who, JEALOUSY_MARK_AV_ID)
		EndIf
		MCP:Core.Reply(tag, s)
		Return
	EndIf

	; Force the scene on this NPC now, eligible or not. OnBegin prepares and stamps.
	Scene sc = Self.ApproachScene()
	ReferenceAlias target = Self.TargetAlias()
	If sc == None || target == None
		MCP:Core.Reply(tag, "approach: Overture.esp did not resolve - the scene or the alias came back None")
		Return
	EndIf
	; Start() does not restart a playing scene: OnBegin would never fire, and the
	; new NPC would get the last one's persona, room and verdict and no stamp.
	If sc.IsPlaying()
		MCP:Core.Reply(tag, "approach: NOT DONE - the approach scene is already playing; end that conversation first")
		Return
	EndIf
	; A conversation whose end is still owed ends before the alias changes hands.
	Self.EndConversation(True)
	If !(Self as Quest).IsRunning()
		(Self as Quest).Start()
	EndIf
	target.ForceRefTo(who)
	; Report what the engine THINKS, not what we asked for: Scene.Start() is void.
	sc.Start()
	Utility.Wait(0.5)
	String note = "approach: forced on " + who.GetFormID() + " | playing after Start=" + sc.IsPlaying()
	If !sc.IsPlaying()
		sc.ForceStart()
		Utility.Wait(0.5)
		note = note + " | after ForceStart=" + sc.IsPlaying()
	EndIf
	MCP:Core.Reply(tag, note)
EndEvent
