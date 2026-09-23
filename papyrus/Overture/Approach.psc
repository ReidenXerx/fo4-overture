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
  OnEnd   -- once every reply that began has ended too, the conversation ends:
             what the next one will read, one line from the Narrator on how it
             went (O-9), the scene a yes asked for, and -- once nobody else has
             the scene -- the alias let go, the persona and the room forgotten.
And on each NPC reply, through Overture:Reply: as the line BEGINS, stage 3's
verdict (only at the stage-2 land); as it ENDS, the bond, and how far the
conversation got.

THE DEV CHANNEL is Overture:Dev, on the same quest, apart from this script: F4MCP
is not a requirement, and a script type the VM cannot find should cost the verbs,
never the approach.

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
; OvertureJealousPending: the persona + 1 of a lover who heard, at the player's
; scene with someone else, and has not said it yet -- the greeting reads it (O-33).
Int Property JEALOUS_PENDING_AV_ID = 0x0000084C AutoReadOnly
Int Property TARGET_ALIAS = 0 AutoReadOnly
; Rapport.esp's quest, which carries Rapport:Bridge and its OnPlayerSceneRecorded.
Int Property RAPPORT_BRIDGE_ID = 0x00000800 AutoReadOnly
; THE COMPANION MODULE (docs/methodology.md 11; O-19 B-lite + C + D): Registry, the
; adapters, Feeders, Moments and IvyNative, on a quest of their own. A companion's
; conversation runs through THIS scene -- its phase 4, which the stranger's phases
; refuse -- and this script's verdict, request and Narrator line.
Int Property COMPANIONS_QUEST_ID = 0x00000855 AutoReadOnly
; The CURRENT companion (FollowersScript adds it on recruitment, takes it away on
; dismissal). The scene's phase 4 reads exactly this.
Int Property CURRENT_COMPANION_FACTION_ID = 0x00023C01 AutoReadOnly

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
; The companion's answer to "Later.": nothing happened, nothing is paid, and the day
; is not spent (CompanionEnded).
Int Property OUTCOME_LATER = 11 AutoReadOnly

; THE STAGED BUILD (tools/overture_stages.py, --stages 3). The one-exchange
; plugin has none of these records: every lookup below comes back None there,
; and every use is guarded.
Int Property VERDICT_GLOBAL_ID = 0x00000845 AutoReadOnly
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
; A yes Rapport could not take at once -- another scene in flight, the bridge not
; up -- is asked again this often, this many times.
Int Property YES_TIMER = 2 AutoReadOnly
Float Property YES_RETRY_SECONDS = 5.0 AutoReadOnly
Int Property YES_RETRIES = 12 AutoReadOnly
; A conversation ends when its scene has AND every reply that began has; this is
; the fallback, for a reply whose end never comes (a line cut off).
; Two timer ids on one script: Rapport's bridge keeps one, having once blamed a
; second id for a dead poll -- but its own run 2 (every StartTimer removed, the
; same result) put it on an AAF call that never returns, and OnTimer queues behind
; a stuck OnTimer (fo4-rapport docs/two-lifetimes.md). Nothing here calls AAF.
Int Property END_TIMER = 3 AutoReadOnly
Float Property END_FALLBACK = 3.0 AutoReadOnly

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
; A companion's own (methodology 11): their state says no right now (C2); their own
; romance, or their affinity, is not there yet (O-22); not wanting it enough yet (B-lite).
Int Property WHY_THEIRS = 10 AutoReadOnly
Int Property WHY_UNWON = 11 AutoReadOnly
Int Property WHY_WANTING = 12 AutoReadOnly

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

; Game days. The day stamp never closes before now + STAMP_MARGIN (about 2.4 game
; hours, seven real minutes at timescale 20), so a conversation that runs past
; midnight still finds its own re-greet closed (microscope pass 2).
Float Property STAMP_MARGIN = 0.1 AutoReadOnly
; O-30: after "not now" or "not here" the stamp comes down to an hour of game time
; ahead -- "ask again later" means later, not the instant the dialogue closes --
; and the invitation lasts the rest of the day, never less than INVITE_WINDOW
; after it reopens: at 23:50 there has to be a "later" too.
Float Property REOPEN_AFTER = 0.041667 AutoReadOnly
Float Property INVITE_WINDOW = 0.083333 AutoReadOnly

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
	; The last reply: its stage, what it did, and the game time it ended.
	Int stage = 0
	Int outcome = 0
	Float at = 0.0
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
	; The replies that began and ended, and whether the scene has: it is over when
	; the scene is and the two counts are level.
	Int begun = 0
	Int ended = 0
	Bool sceneEnded = False
	; No Narrator line: a reply that arrived after its conversation had one.
	Bool quiet = False
	; The player's current companion: the scene's phase 4, the companion's verdict,
	; and CompanionEnded (methodology 11).
	Bool companion = False
EndStruct

Conversation _current = None
Int _serial = 0
; The conversation whose OnEnd started the fallback timer.
Int _endingSerial = 0

Int _api = 0
Int _why = 0
Actor _held = None
Actor _yesWith = None
Int _yesTries = 0
; The room, pinned by the dev verb (approach room): 0 measured, 1 public, 2 private.
Int _roomPinned = 0
; Why the companion's gate said what it said, for the trace.
String _companionNote = ""

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

; The master switch ("Approaches" on the MCM page). The greetings read the global
; themselves; the companion module asks here, so off means off everywhere.
Bool Function Enabled()
	GlobalVariable g = Self.EnabledGlobal()
	Return g == None || g.GetValue() != 0.0
EndFunction

GlobalVariable Function VerdictGlobal()
	Return Game.GetFormFromFile(VERDICT_GLOBAL_ID, "Overture.esp") as GlobalVariable
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
	; Registrations are re-made on every load; doing the scene's here costs nothing.
	Self.Hook()
EndEvent

Function Hook()
	Self.RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
	; Overture:Dev (the F4MCP verbs) hooks itself only from its own OnQuestInit,
	; which never runs in a save where this quest was already running before
	; Dev.pex existed -- the owner's save: F4MCP listed no "approach" verb at all
	; (fo4-mcp, 09-24). Nudged on every load, BY NAME, so no F4MCP type enters
	; this script (microscope pass 2); without F4MCP, Dev's Hook returns early.
	ScriptObject dev = (Self as Quest).CastAs("Overture:Dev")
	If dev != None
		dev.CallFunctionNoWait("Hook", new Var[0])
	EndIf
	; The companion module's quest: start-game-enabled, but if a save somehow has it
	; stopped, nothing would hook and the module would be invisible without a word
	; (microscope wave 3). Its own OnQuestInit hooks the rest.
	Quest companionsQuest = Game.GetFormFromFile(COMPANIONS_QUEST_ID, "Overture.esp") as Quest
	If companionsQuest != None && !companionsQuest.IsRunning()
		Debug.Trace("Overture: the companions quest was not running - started", 1)
		companionsQuest.Start()
	EndIf

	_api = Rapport:Core.ApiVersion()
	If _api < NEEDS_API
		Debug.Trace("Overture: Rapport's ApiVersion is " + _api + ", Overture needs " + NEEDS_API + " - no narration, no names, no lovers, and nobody counts as watching", 2)
		Debug.Notification("Overture needs Rapport 0.2.1 or newer.")
	EndIf
	If MCM.IsInstalled() && !Self.HasSettings()
		Debug.Trace("Overture: MCM is installed but has not read Overture's settings (MCM/Config/Overture/settings.ini missing?) - the built-in numbers, and no scenes", 1)
	EndIf

	; A yes still waiting for its scene when the game was saved: Rapport forgets
	; every hold on a load, and a retry from before it asks for a moment that has
	; passed.
	Self.CancelTimer(YES_TIMER)
	_held = None
	If _yesWith != None
		Debug.Trace("Overture: " + _yesWith.GetFormID() + "'s yes was still waiting for its scene when the game was saved - let go", 1)
		_yesWith = None
	EndIf
	; And a conversation whose end was still owed: it ends now, whether or not its
	; timer outlived the load; the timer then finds nobody.
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

	; Rapport says when a scene with the player has ended and been recorded: the
	; moment O-27 is about, rather than the next conversation.
	If _api >= NEEDS_API
		Rapport:Bridge bridge = Game.GetFormFromFile(RAPPORT_BRIDGE_ID, "Rapport.esp") as Rapport:Bridge
		If bridge != None
			; The mangled name: the base sources are decompiled (Rapport:Bridge has why).
			Self.RegisterForCustomEvent(bridge, "rapport:bridge_OnPlayerSceneRecorded")
		EndIf
	EndIf
EndFunction

; A scene with the player has ended and Rapport has recorded it -- the bond, the
; pair's history. O-27's moment: lovers to the world now, and said now, not at the
; next conversation a day late; and the tier with it. A scene is never one of
; Overture's conversations, so the markers can be written.
Event Rapport:Bridge.OnPlayerSceneRecorded(Rapport:Bridge akSender, Var[] akArgs)
	If akArgs == None || akArgs.Length < 1
		Return
	EndIf
	Actor who = akArgs[0] as Actor
	If who == None
		Return
	EndIf
	Conversation c = new Conversation
	c.who = who
	c.quiet = True
	String note = Self.BetweenConversations(c)
	Debug.Trace("Overture: a scene with " + who.GetFormID() + " was recorded" + note, 0)
	If _api < NEEDS_API
		Return
	EndIf
	If c.lovers
		Rapport:Core.NarrateLine(Game.GetPlayer().GetFormID(), who.GetFormID(), "Word gets around - you and {second} are a couple now.", "")
	EndIf
	; O-33 (owner, 2026-09-23): every OTHER lover hears of it now, and says so in
	; their own voice when the player next talks to them -- the greeting reads the
	; marker. Once per conversation, as before: one who has not had their say yet
	; only has their count moved on, and reacts again after they have.
	Int p = Game.GetPlayer().GetFormID()
	Int count = Rapport:Core.LoverCount(p)
	Int i = 0
	While i < count
		Actor lover = Game.GetForm(Rapport:Core.LoverAt(p, i)) as Actor
		If lover != None && lover != who
			Conversation heard = new Conversation
			heard.who = lover
			If Self.IsCompanionTalk(lover)
				; The companion module answers for the current companion (Feeders,
				; within its next tick): here the count only moves on, so a later
				; conversation as a stranger-lover never hears it again.
				Self.Jealousy(heard, False)
			Else
				Bool react = Self.ValueOf(lover, JEALOUS_PENDING_AV_ID) <= 0.0
				String what = Self.Jealousy(heard, react)
				If heard.jealous != 0
					Self.SetTo(lover, JEALOUS_PENDING_AV_ID, (Self.PersonaIndex(lover) + 1) as Float)
					Debug.Trace("Overture: " + lover.GetFormID() + what + " - their next greeting says so", 0)
				EndIf
			EndIf
		EndIf
		i += 1
	EndWhile
EndEvent

Event Scene.OnBegin(Scene akSender)
	Actor who = Self.TargetAlias().GetActorReference()
	If who == None
		Debug.Trace("Overture: the approach scene began with NOBODY in the alias - ALFA did not fill it", 1)
		Return
	EndIf
	; This conversation is current FIRST, before anything that can yield: an OnEnd
	; or a reply arriving while the rest of this runs must find it, not the last one.
	Conversation last = _current
	Conversation c = new Conversation
	c.who = who
	_serial += 1
	c.serial = _serial
	_current = c
	c.companion = Self.IsCompanionTalk(who)
	; What the NPC's first reply reads -- chosen seconds from now.
	String note = Self.Prepare(who)
	; The last conversation, if its end is still owed (a reply still out, or an OnEnd
	; that never came): ended with its own facts, and without the tidy-up -- this one
	; has the alias and the globals now. Before this one's own stamp, so a "not now"
	; of the same NPC cannot lower it.
	If last != None
		Self.Finish(last, False)
	EndIf
	Self.Stamp(who)
	; O-10: a nameless NPC gets a name on their first approach. Rapport decides who
	; is nameless and keeps it; "" means no new name.
	If _api >= NEEDS_API
		c.intro = Rapport:Core.Introduce(who)
	EndIf
	c.bondBefore = Rapport:Relations.BondBetween(Game.GetPlayer(), who)
	c.bondAfter = c.bondBefore
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
	; The conversation ends when its scene has AND every reply that began has: the
	; last reply's own OnEnd (Overture:Reply, another script object) has no order
	; against this event, and that reply's facts are this conversation's -- its
	; stage, its outcome, a yes. Replied ends it when the count comes level; the
	; timer is only for a reply whose end never comes. (And NOT IsPlaying():
	; MEASURED 2026-09-23 on a Third Rail Drifter, this event arrives while the
	; scene still reports it, five seconds later too.)
	Conversation c = _current
	If c == None
		; Nobody's conversation: the tidy-up alone.
		Self.Tidy(None)
		Return
	EndIf
	c.sceneEnded = True
	If c.ended >= c.begun
		Self.EndConversation(True)
		Return
	EndIf
	_endingSerial = c.serial
	Self.StartTimer(END_FALLBACK, END_TIMER)
EndEvent

Event OnTimer(Int aiTimerID)
	If aiTimerID == YES_TIMER
		Self.AskForTheScene()
	ElseIf aiTimerID == END_TIMER
		; Only the conversation that started it: one that has begun since is not over.
		Conversation c = _current
		If c != None && c.serial == _endingSerial
			Debug.Trace("Overture: a reply of the conversation with " + c.who.GetFormID() + " never ended - ending it without", 1)
			Self.EndConversation(True)
		EndIf
	EndIf
EndEvent

; ---- one conversation ---------------------------------------------------------

; What this conversation opens with, decided as it begins -- seconds before the
; player can pick. Returns the note.
String Function Opening(Conversation c)
	Actor who = c.who
	String note = ""
	If _api >= NEEDS_API
		note = note + Self.UpdateWorldLovers(c)
		If c.companion
			; A companion's jealousy is the companion module's (Feeders), on its own
			; clock: here, only the count moves on, so nothing is heard twice.
			Self.Jealousy(c, False)
		Else
			Int pending = Self.ValueOf(who, JEALOUS_PENDING_AV_ID) as Int
			If pending > 0
				; Heard at the scene (O-33): the bond moved then, and their greeting has
				; just said it. What remains is the Narrator's line, and the count.
				c.jealous = Self.ReactionOf(pending - 1)
				note = note + Self.Jealousy(c, False) + " | said their piece in the greeting"
			Else
				note = note + Self.Jealousy(c, True)
			EndIf
		EndIf
	EndIf
	; A companion's conversation is the proposition, always: phase 4 (methodology 11).
	If !c.companion && !Self.OpensAtProposition(who)
		Return note
	EndIf
	; The scene skips stages 1 and 2 on markers written before it began; what the
	; proposition will answer is decided here, on the bond as it stands now, by
	; the same rules as everyone's.
	GlobalVariable verdict = Self.VerdictGlobal()
	If verdict == None
		Return note
	EndIf
	Int decided = Self.Decide(who, Rapport:Relations.BondBetween(Game.GetPlayer(), who), Self.RoomIsPublic(), c.serial)
	c.verdict = decided
	c.why = _why
	verdict.SetValue(decided as Float)
	If c.companion
		note = note + " | companion: " + _companionNote
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

; The current conversation's end: from its OnEnd once its replies are in, from its
; last reply, from the fallback timer, or from a load. Taken out of _current
; before anything can yield, so a second caller finds nobody.
Function EndConversation(Bool abTidy)
	Conversation c = _current
	If c == None
		Return
	EndIf
	_current = None
	Self.Finish(c, abTidy)
EndFunction

; A conversation's end, for whichever conversation it is -- the caller has already
; let go of it, so it runs once.
Function Finish(Conversation c, Bool abTidy)
	Actor who = c.who
	Bool yes = c.outcome == OUTCOME_ACCEPT
	; No yes in this conversation: nothing will ask for the slot it may be holding.
	If !yes
		Self.LetGo(who)
	EndIf
	; Whether a yes asks for its scene -- decided once, here, so the line and the
	; request cannot disagree.
	c.sceneAsked = yes && Self.ScenesOn()
	String note = Self.BetweenConversations(c)
	If !c.quiet
		Self.Narrate(c)
	EndIf
	Debug.Trace("Overture: the conversation with " + who.GetFormID() + " ended - last reply stage " + c.stage + " outcome " + c.outcome + note, 0)
	If abTidy
		Self.Tidy(who)
	EndIf
	; The yes's scene, asked for now that the dialogue has closed. O-16's hold has
	; kept the slot since the verdict.
	If yes
		Self.Proposition(who, c.sceneAsked)
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
	; O-12: they said yes once, and their conversations open at the proposition from
	; now on. Overture's marker only -- lovers to the world takes a scene as well (O-27).
	If c.outcome == OUTCOME_ACCEPT
		Self.SetTo(who, SAID_YES_AV_ID, 1.0)
		note = note + " | said yes"
	EndIf
	; O-30 (owner, 2026-09-23): after "not now" or "not here", the rest of the day
	; opens at the proposition -- no flirt replayed, no bond paid twice -- and the day
	; stamp comes down, so there is a rest of the day (O-13's "not now leaves the day
	; unstamped"). Until the "not here" follow is built, "not here" gets the same.
	; The DAY is the reply's, not the end's: a "not now" at 23:59 is today's.
	If c.outcome == OUTCOME_NOT_NOW || c.outcome == OUTCOME_NOT_HERE
		Float now = Utility.GetCurrentGameTime()
		Float said = c.at
		If said <= 0.0
			said = now
		EndIf
		Float until = (Math.Floor(said) + 1) as Float
		If until < now + REOPEN_AFTER + INVITE_WINDOW
			until = now + REOPEN_AFTER + INVITE_WINDOW
		EndIf
		Self.SetTo(who, INVITED_UNTIL_AV_ID, until)
		Self.SetTo(who, NEXT_DAY_AV_ID, now + REOPEN_AFTER)
		note = note + " | invited back until day " + until
	EndIf
	If _api >= NEEDS_API
		note = note + Self.UpdateWorldLovers(c)
	EndIf
	Int tier = Self.TierOf(who)
	Self.SetTo(who, TIER_AV_ID, tier as Float)
	note = note + " | tier " + tier
	; O-33: a conversation began with their jealous greeting, and it has been said.
	If !c.quiet && Self.ValueOf(who, JEALOUS_PENDING_AV_ID) > 0.0
		Self.SetTo(who, JEALOUS_PENDING_AV_ID, 0.0)
	EndIf
	; O-28, and the rule that a proposition which could only be refused is never
	; offered (methodology 2): a falling-out, or someone now spoken for and faithful
	; enough to always refuse (methodology 7), no longer opens at the proposition on
	; the strength of an old yes. Rapport ends its own lovers flag at the same line.
	If Self.ValueOf(who, SAID_YES_AV_ID) == 1.0 && (tier == TIER_FALLEN_OUT || Self.FaithfullyTaken(who))
		Self.SetTo(who, SAID_YES_AV_ID, 0.0)
		note = note + " | a yes no longer opens at the proposition"
	EndIf
	If c.companion
		note = note + Self.CompanionEnded(c)
	EndIf
	Return note
EndFunction

; ---- companions (methodology 11) ---------------------------------------------

Overture:Companions:Feeders Function Companions()
	Return Game.GetFormFromFile(COMPANIONS_QUEST_ID, "Overture.esp") as Overture:Companions:Feeders
EndFunction

; The player's CURRENT companion: the scene's phase 4 reads exactly this, so the
; script and the scene agree on whose conversation it is.
Bool Function IsCompanionTalk(Actor akWho)
	Faction current = Game.GetFormFromFile(CURRENT_COMPANION_FACTION_ID, "Fallout4.esm") as Faction
	Return akWho != None && current != None && akWho.IsInFaction(current)
EndFunction

; A companion's conversation has ended. The moment (Moments: "not here" and "not
; now" keep it, anything else spends it), and the day. NOTHING HAPPENED -- "Later.",
; the wheel left, a "..." fallback beat, or a refusal no words could have changed
; (the verdict refused every proposition) -- spends nothing: the stamp comes down to
; an hour ahead, as after "not now" (O-30), which still hands the re-greet back to
; their own dialogue. Anything else spends the day, stamped again here so a reply
; that ended after an earlier "nothing happened" end still does (microscope wave 3).
String Function CompanionEnded(Conversation c)
	Int o = c.outcome
	Bool keep = o == OUTCOME_NOT_HERE || o == OUTCOME_NOT_NOW
	Overture:Companions:Moments moments = Game.GetFormFromFile(COMPANIONS_QUEST_ID, "Overture.esp") as Overture:Companions:Moments
	If moments != None
		moments.Ended(c.who, keep)
	EndIf
	If keep
		; BetweenConversations has already brought the stamp down to the hour (O-30).
		Return ""
	EndIf
	If o == OUTCOME_LATER || o == 0 || o == OUTCOME_MISS || (o == OUTCOME_REFUSE && c.verdict == VERDICT_REFUSE)
		Self.SetTo(c.who, NEXT_DAY_AV_ID, Utility.GetCurrentGameTime() + REOPEN_AFTER)
		Return " | companion: nothing happened - the day is not spent"
	EndIf
	Self.Stamp(c.who)
	Return ""
EndFunction

; Would a moment opened now be an invitation that can only be refused or put off
; (methodology 2)? What Decide refuses by nature -- no persona, fallen out, faithfully
; taken -- and the romantic's setting, asked BEFORE a moment opens (Moments), so the
; companion never asks for a minute only to say no.
Bool Function CompanionOpenable(Actor akWho)
	Int persona = Self.PersonaIndex(akWho)
	If persona < 0
		Return False
	EndIf
	If Rapport:Relations.BondBetween(Game.GetPlayer(), akWho) <= BOND_FALLEN_OUT
		Return False
	EndIf
	If Self.FaithfullyTaken(akWho)
		Return False
	EndIf
	Return persona != 1 || Self.Setting(akWho)
EndFunction

; The companion's half of a verdict: their own gates (C2, O-22) and their wanting
; (B-lite) instead of the bond's bar, then the faithfulness rule as for everyone
; (methodology 7). 0: their side says yes, and the room, the setting and Rapport
; decide the rest as they do for everyone. Leaves the reason in _why.
Int Function CompanionVerdict(Actor akWho)
	Overture:Companions:Feeders companions = Self.Companions()
	If companions == None
		_companionNote = "the companion module did not resolve"
		_why = WHY_THEIRS
		Return VERDICT_REFUSE
	EndIf
	Int gate = companions.Gate(akWho)
	_companionNote = companions.LastGateNote() + " | inScene=" + akWho.IsInScene() + " scene=" + akWho.GetCurrentScene()
	If gate == companions.GATE_STATE
		_why = WHY_THEIRS
		Return VERDICT_REFUSE
	EndIf
	; Faithfulness refuses whatever else -- before a "not yet" that would promise
	; what it cannot keep (methodology 2's order; microscope wave 3).
	If Self.FaithfullyTaken(akWho)
		_why = WHY_TAKEN
		Return VERDICT_REFUSE
	EndIf
	If gate == companions.GATE_UNWON
		_why = WHY_UNWON
		Return VERDICT_REFUSE
	ElseIf gate == companions.GATE_WANTING
		_why = WHY_WANTING
		Return VERDICT_NOTYET
	EndIf
	Return 0
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
	Bool close = bond >= Self.Tuned("fLoverBond:Bars", 0.75) || Rapport:Relations.ArePartners(player, akWho)
	If !close && _api >= NEEDS_API
		close = Rapport:Core.AreLovers(player.GetFormID(), akWho.GetFormID())
	EndIf
	If close
		; Close enough to open at the proposition -- unless that proposition could
		; only be refused: someone spoken for and faithful enough to always refuse
		; stays close, and keeps the flirt (methodology 2 and 7).
		If Self.FaithfullyTaken(akWho)
			Return TIER_CLOSE
		EndIf
		Return TIER_LOVER
	EndIf
	If bond >= BOND_CLOSE
		Return TIER_CLOSE
	ElseIf bond >= BOND_WARM
		Return TIER_WARM
	EndIf
	Return TIER_STRANGER
EndFunction

; Spoken for, and faithful enough to refuse whatever the bond (methodology 7).
Bool Function FaithfullyTaken(Actor akWho)
	If !Self.SpokenFor(akWho)
		Return False
	EndIf
	Return Rapport:Core.FaithfulnessOf(akWho.GetFormID()) >= Self.Tuned("fFaithRefuses:SpokenFor", 0.80)
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
	If !Rapport:Core.AreLovers(p, id)
		; Rapport refused (a death this session, or fallen out): nothing to announce.
		Return " | lovers refused by Rapport"
	EndIf
	; Jealousy counts from here: what the player did before is not this lover's business.
	Self.SetTo(who, JEALOUSY_MARK_AV_ID, (Rapport:Core.SceneCount(p) - together + 1) as Float)
	c.lovers = True
	Return " | lovers now (bond " + bond + ", " + together + " scene(s) together)"
EndFunction

; O-29 (owner, 2026-09-23): a lover hears about the others. Rapport counts every
; scene the player has had and every one with this lover, so the difference is
; the scenes with anyone else; the player's own count never ages out (Rapport
; 17aac9a). The mark is that difference, plus one, as this lover last knew it; 0
; is "never counted", counted now with nothing to react to, so nobody answers for
; what happened before they were a lover. What it means is the persona's --
; methodology 11's table, which the owner applied to strangers too: the romantic
; and the reticent take it badly, the mercantile shrugs, the vulgar likes hearing
; it. Once per conversation, however many there were: abReact False moves the
; count on and nothing else (a lover who has not had their say yet). Returns the note.
String Function Jealousy(Conversation c, Bool abReact)
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
	If known == 0 || others < known || !abReact
		Return ""
	EndIf
	String note = " | heard about " + (others - known + 1) + " scene(s) with someone else"
	Int persona = Self.PersonaIndex(who)
	c.jealous = Self.ReactionOf(persona)
	If c.jealous == 0
		Return note + ", and no persona to react with"
	EndIf
	Float worth = 0.0
	If c.jealous == JEALOUS_STUNG
		worth = Self.Tuned("fJealousySting:Jealousy", -0.06)
	ElseIf c.jealous == JEALOUS_THRILLED
		worth = Self.Tuned("fJealousyThrill:Jealousy", 0.03)
	EndIf
	If worth != 0.0
		Float after = Rapport:Relations.AddBondBetween(player, who, worth, REASON_DIALOGUE)
		c.bondAfter = after
		note = note + ", bond now " + after
	EndIf
	Return note
EndFunction

; What a persona makes of hearing about the others (O-29): the romantic and the
; reticent are stung, the vulgar thrilled, the mercantile shrugs. 0: no persona.
Int Function ReactionOf(Int aiPersona)
	If aiPersona == 1 || aiPersona == 3
		Return JEALOUS_STUNG
	ElseIf aiPersona == 2
		Return JEALOUS_THRILLED
	ElseIf aiPersona == 0
		Return JEALOUS_SHRUGGED
	EndIf
	Return 0
EndFunction

; ---- the numbers --------------------------------------------------------------

; MCM has Overture's settings: installed, AND the shipped settings.ini read.
; iDefaults:Meta is in that file and on no control, so no slider a player moved
; can fake it -- MCM answers 0 for every key of a file it never read, and one
; moved slider used to pass for all of them (microscope pass 2).
Bool Function HasSettings()
	Return MCM.IsInstalled() && MCM.GetModSettingInt("Overture", "iDefaults:Meta") == 1
EndFunction

; A number the MCM page tunes, or the default without Overture's settings.
; tools/overture_stages.py SETTINGS is the table; tools/make_mcm.py writes the page
; and the ini from it, and refuses to if a call here names a key it lacks or falls
; back to a different default.
Float Function Tuned(String asKey, Float afDefault)
	If !Self.HasSettings()
		Return afDefault
	EndIf
	Return MCM.GetModSettingFloat("Overture", asKey)
EndFunction

; "A yes starts a scene" -- an MCM setting, like the numbers, so a new default
; reaches every save. Off without Overture's settings, which is its default.
Bool Function ScenesOn()
	If !Self.HasSettings()
		Return False
	EndIf
	Return MCM.GetModSettingBool("Overture", "bScenes:Switches")
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
; public, as in Prepare. The dev verb can pin it.
Bool Function InPublic(Actor akWho)
	If _roomPinned != 0
		Return _roomPinned == 1
	EndIf
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
; aiHoldFor is the conversation a yes verdict holds Rapport's slot for; 0 holds
; nothing (the dev verb's verdict changes nothing). Leaves the reason in _why.
Int Function Decide(Actor akWho, Float afBond, Bool abPublic, Int aiHoldFor)
	Int persona = Self.PersonaIndex(akWho)
	If persona < 0
		_why = WHY_NO_PERSONA
		Return VERDICT_REFUSE
	EndIf
	If afBond <= BOND_FALLEN_OUT
		_why = WHY_FALLEN_OUT
		Return VERDICT_REFUSE
	EndIf
	If Self.IsCompanionTalk(akWho)
		Int theirs = Self.CompanionVerdict(akWho)
		If theirs != 0
			Return theirs
		EndIf
	Else
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
	EndIf
	If abPublic
		_why = WHY_PUBLIC
		Return VERDICT_NOT_HERE
	EndIf
	If persona == 1 && !Self.Setting(akWho)
		_why = WHY_SETTING
		Return VERDICT_NOT_NOW
	EndIf
	; Everything but the moment has passed: take the slot BEFORE looking at it, so a
	; request that slips in between cannot take the scene a yes was just promised
	; (O-16, microscope pass 2).
	If aiHoldFor != 0
		Self.Hold(akWho, HOLD_AT_VERDICT, aiHoldFor)
	EndIf
	If Rapport:Core.Busy() || Rapport:Core.CanRun(Self.ScenarioFor(akWho, persona), Game.GetPlayer(), akWho) < 0
		If aiHoldFor != 0
			Self.LetGo(akWho)
		EndIf
		_why = WHY_BUSY
		Return VERDICT_NOT_NOW
	EndIf
	_why = WHY_YES
	Return VERDICT_ACCEPT
EndFunction

; ---- the replies --------------------------------------------------------------

; The current conversation, if akWho is the one it is with.
Conversation Function Theirs(Actor akWho)
	Conversation c = _current
	If c != None && c.who != akWho
		Return None
	EndIf
	Return c
EndFunction

; Called by Overture:Reply as an NPC's reply line BEGINS. The one thing decided
; here is stage 3's verdict, at the start of the stage-2 land: the land line
; itself runs about 4.5 s and the phase-3 gate is read only when it ENDS, so
; nothing races. The bond it decides on is the bond this land is about to write.
Function ReplyBegins(Actor akWho, Int aiStage, Int aiOutcome)
	If akWho == None
		Return
	EndIf
	; Counted FIRST, before anything that can yield: the conversation waits for
	; every reply that began to end.
	Conversation c = Self.Theirs(akWho)
	If c != None
		c.begun += 1
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
	Int holdFor = 0
	If c != None
		holdFor = c.serial
	EndIf
	Float bond = Self.AfterLand(Rapport:Relations.BondBetween(Game.GetPlayer(), akWho), Self.Tuned("fLandSecond:Words", 0.07))
	Int decided = Self.Decide(akWho, bond, Self.RoomIsPublic(), holdFor)
	Int why = _why
	verdict.SetValue(decided as Float)
	If c != None
		c.verdict = decided
		c.why = why
	EndIf
	Debug.Trace("Overture: " + akWho.GetFormID() + " stage 3 verdict " + decided + " (why " + why + ") on bond " + bond, 0)
EndFunction

; Called by Overture:Reply when an NPC's reply line has been said. Writes the
; bond (R-10: add this much, for this reason), and what the conversation has
; reached, which its end turns into where the next one starts.
Function Replied(Actor akWho, Int aiStage, Int aiOutcome)
	If akWho == None
		Return
	EndIf
	; This conversation's facts FIRST, before anything that can yield: its end
	; waits on exactly this reply.
	Int reached = 0
	If aiOutcome == OUTCOME_LAND || aiStage == 3
		reached = aiStage
	EndIf
	Conversation c = Self.Theirs(akWho)
	If c != None
		c.stage = aiStage
		c.outcome = aiOutcome
		If reached > c.reached
			c.reached = reached
		EndIf
		c.ended += 1
	EndIf
	String note = "Overture: " + akWho.GetFormID() + " replied, stage " + aiStage + " outcome " + aiOutcome
	Float worth = Self.Worth(aiStage, aiOutcome)
	; A refusal the words did not cause costs nothing: when the verdict itself was a
	; refusal every register was refused, and the Narrator says it was not the words.
	If aiOutcome == OUTCOME_REFUSE && c != None && c.verdict == VERDICT_REFUSE
		worth = 0.0
	EndIf
	If worth != 0.0
		Float before = Rapport:Relations.BondBetween(Game.GetPlayer(), akWho)
		Float after = Rapport:Relations.AddBondBetween(Game.GetPlayer(), akWho, worth, REASON_DIALOGUE)
		note = note + " | bond " + before + " -> " + after
		If c != None
			c.bondAfter = after
		EndIf
	EndIf
	If c == None
		; Its conversation had already ended -- this reply's end came after the
		; fallback. What its end would have written for this reply, written now; no
		; line, since that conversation's own was said.
		Conversation late = new Conversation
		late.who = akWho
		late.stage = aiStage
		late.outcome = aiOutcome
		late.reached = reached
		late.quiet = True
		late.companion = Self.IsCompanionTalk(akWho)
		Debug.Trace(note + " | after its conversation ended", 1)
		Self.Finish(late, False)
		Return
	EndIf
	c.at = Utility.GetCurrentGameTime()
	Debug.Trace(note, 0)
	; The last reply of a scene that has already ended: the conversation is complete.
	Conversation now = _current
	If c.sceneEnded && c.ended >= c.begun && now != None && now.serial == c.serial
		Self.EndConversation(True)
	EndIf
EndFunction

; ---- a yes --------------------------------------------------------------------

; Stage 4, behind "A yes starts a scene" until a Rapport scene with the player in
; it has been watched end to end (methodology 5).
Function Proposition(Actor akWho, Bool abScenes)
	If !abScenes
		Debug.Trace("Overture: " + akWho.GetFormID() + " said yes; scenes are off (MCM: A yes starts a scene)", 0)
		Self.LetGo(akWho)
		Return
	EndIf
	If _yesWith != None && _yesWith != akWho
		; The player has moved on to someone else: the older yes gives way, and says so.
		Self.GiveUpYes("the player said yes to someone else first")
	EndIf
	Self.Hold(akWho, HOLD_AT_YES, 0)
	; Seconds have passed since the verdict checked Rapport was free, and the scene
	; slot can still be taken (the hold is only as old as the verdict) -- so ask now,
	; and keep asking for a minute rather than letting a yes vanish.
	_yesWith = akWho
	_yesTries = 0
	Self.AskForTheScene()
EndFunction

Function AskForTheScene()
	Actor akWho = _yesWith
	If akWho == None
		Return
	EndIf
	If akWho.IsDead() || !akWho.Is3DLoaded()
		; Gone -- dead, or left behind by a fast travel: no scene will ever take.
		Self.GiveUpYes("they are gone")
		Return
	EndIf
	Actor player = Game.GetPlayer()
	Bool took = False
	; Ivy's own fade to black holds the player (her StartSex: AI-driven); her EndSex
	; would hand control back in the middle of a scene started now (microscope wave 3).
	Overture:Companions:IvyNative ivy = Game.GetFormFromFile(COMPANIONS_QUEST_ID, "Overture.esp") as Overture:Companions:IvyNative
	Bool herFade = ivy != None && ivy.HerFadeRunning()
	If !Rapport:Core.Busy() && !herFade
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
	; One retry chain, whatever StartTimer does with a pending id.
	Self.CancelTimer(YES_TIMER)
	Self.StartTimer(YES_RETRY_SECONDS, YES_TIMER)
EndFunction

; A yes that will never get its scene: said, so it does not vanish without a word.
Function GiveUpYes(String asWhy)
	Actor who = _yesWith
	If who == None
		Return
	EndIf
	_yesWith = None
	Self.CancelTimer(YES_TIMER)
	Debug.Trace("Overture: " + who.GetFormID() + " said yes and " + asWhy + " - the yes is lost", 1)
	If _api >= NEEDS_API
		Rapport:Core.NarrateLine(Game.GetPlayer().GetFormID(), who.GetFormID(), "{second} said yes, but the moment passed.", "")
	EndIf
	Self.LetGo(who)
EndFunction

; Hold Rapport's slot for the player and this NPC (O-16) -- only when a yes would
; really ask for a scene, never over a yes still waiting for its own (the slot has
; one hold, and a verdict is not a yes), and, for a verdict, only while its
; conversation is going: once it has ended, nothing would ever let the hold go.
; aiSerial 0: no conversation to wait on (a yes, after its conversation).
Function Hold(Actor akWho, Float afSeconds, Int aiSerial)
	If _api < NEEDS_API || !Self.ScenesOn()
		Return
	EndIf
	If _yesWith != None && _yesWith != akWho
		Return
	EndIf
	If aiSerial != 0 && (_current == None || _current.serial != aiSerial)
		Return
	EndIf
	Rapport:Core.ReservePlayerScene(akWho, afSeconds)
	_held = akWho
	If aiSerial != 0 && (_current == None || _current.serial != aiSerial)
		; It ended while the hold went in.
		Self.LetGo(akWho)
	EndIf
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
; the world's news of a couple, and a lover's jealousy -- since that line says
; who and why as the scene starts.
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
		; O-27 is what the WORLD sees: Chemistry treats them as spoken for from now on.
		headline = Self.Then(headline, "Word gets around - you and {second} are a couple now.")
		named = True
	EndIf
	If c.jealous == JEALOUS_STUNG
		If yes
			headline = Self.Then(headline, Self.Subject(named) + " heard you've been with someone else - and said yes anyway.")
		Else
			headline = Self.Then(headline, Self.Subject(named) + " heard you've been with someone else. It stung.")
		EndIf
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
		If c.why == WHY_WANTING
			; A companion's wanting builds with days on the road together (B-lite).
			Return "Not yet. A few more days on the road together, and " + s + " might."
		EndIf
		Return "Close. A little more time with you, and " + s + " might."
	ElseIf outcome == OUTCOME_NOT_HERE
		; The place is what is wrong, so the hint is the place (microscope pass 2):
		; "later" in the same crowd is the same answer.
		Return s + " would - somewhere without an audience. Catch {them} alone."
	ElseIf outcome == OUTCOME_NOT_NOW
		If c.why == WHY_SETTING
			Return s + " would - indoors, or after dark. Ask again later today."
		EndIf
		Return s + " would - just not right now. Ask again later today."
	ElseIf outcome == OUTCOME_REFUSE
		If c.verdict == VERDICT_REFUSE
			; Even the right words would have been refused (a conversation that
			; opened at the proposition asks whatever the verdict), so the words are
			; not the reason -- and the refusal costs nothing (Replied).
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
	ElseIf aiWhy == WHY_THEIRS
		Return " - {they} had other things on {their} mind."
	ElseIf aiWhy == WHY_UNWON
		Return " - win {them} over first, {their} own way."
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

; Once a game day (O-8): the greeting compares this against GameDaysPassed, so
; the NPC opens again with tomorrow's first conversation. No timer, no list. And
; never before now + STAMP_MARGIN: the stamp also closes the hand-back's re-greet,
; and a conversation that runs past midnight must not find it open (microscope
; pass 2).
Function Stamp(Actor who)
	Float now = Utility.GetCurrentGameTime()
	Float tomorrow = (Math.Floor(now) + 1) as Float
	If tomorrow < now + STAMP_MARGIN
		tomorrow = now + STAMP_MARGIN
	EndIf
	Self.SetTo(who, NEXT_DAY_AV_ID, tomorrow)
EndFunction

; The persona and the room, for whoever the approach is with. Returns the note.
; Must land before the NPC's reply is chosen -- after the player picks, seconds
; into the scene -- which OnBegin does.
String Function Prepare(Actor who)
	String note = ""
	; The verdict and the last reply's outcome belong to THIS conversation: a new one
	; can begin while the last is still owed (Finish without the tidy), and phase 3's
	; and HandBack's gates would read what it left (microscope wave 3).
	GlobalVariable verdictGlobal = Self.VerdictGlobal()
	If verdictGlobal != None
		verdictGlobal.SetValue(0.0)
	EndIf
	GlobalVariable lastGlobal = Self.LastOutcomeGlobal()
	If lastGlobal != None
		lastGlobal.SetValue(0.0)
	EndIf
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
		If _roomPinned == 1
			inPublic.SetValue(1.0)
			note = note + " | room PINNED public (approach room)"
		ElseIf _roomPinned == 2
			inPublic.SetValue(0.0)
			note = note + " | room PINNED private (approach room)"
		ElseIf watching < 0
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
	If _current != None
		; A conversation has begun since: the alias and the globals are its.
		Return
	EndIf
	Actor inAlias = Self.TargetAlias().GetActorReference()
	If inAlias != None && inAlias != akWas
		Debug.Trace("Overture: " + inAlias.GetFormID() + " already holds the alias - left as it is", 0)
		Return
	EndIf
	; Forget who it was: a persona, a room or a verdict left in the globals is the
	; next NPC's reply if their own OnBegin is late. -1 matches no reply (the staged
	; plugin's fallback says a neutral beat and hands back), an unknown room is
	; public, as everywhere else here, and 0 is "no verdict" and "no last line".
	GlobalVariable pg = Self.PersonaGlobal()
	If pg != None
		pg.SetValue(-1.0)
	EndIf
	GlobalVariable inPublic = Self.PublicGlobal()
	If inPublic != None
		inPublic.SetValue(1.0)
	EndIf
	GlobalVariable verdict = Self.VerdictGlobal()
	If verdict != None
		verdict.SetValue(0.0)
	EndIf
	GlobalVariable last = Self.LastOutcomeGlobal()
	If last != None
		last.SetValue(0.0)
	EndIf
	; The alias last, and looked at again: the next speaker may have taken it while
	; the globals were reset.
	If _current != None
		Return
	EndIf
	inAlias = Self.TargetAlias().GetActorReference()
	If inAlias == None || inAlias == akWas
		Debug.Trace("Overture: alias let go, persona and room forgotten", 0)
		Self.TargetAlias().Clear()
	EndIf
EndFunction

; ---- for Overture:Dev (the F4MCP verbs) ---------------------------------------

; Why the last Decide came out as it did.
Int Function LastWhy()
	Return _why
EndFunction

Bool Function HasApi()
	Return _api >= NEEDS_API
EndFunction

; 0 measured, 1 public, 2 private.
Function PinRoom(Int aiRoom)
	_roomPinned = aiRoom
EndFunction

Int Function RoomPinned()
	Return _roomPinned
EndFunction

; The scenes switch, as the MCM page would set it. False if MCM is not there to
; keep it.
Bool Function SetScenes(Bool abOn)
	If !MCM.IsInstalled()
		Return False
	EndIf
	MCM.SetModSettingBool("Overture", "bScenes:Switches", abOn)
	Return True
EndFunction

; Is a conversation going on?
Bool Function Talking()
	Return _current != None
EndFunction
