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

WHAT THIS SCRIPT DOES, on the scene's own events:
  OnBegin -- the persona and the room for whoever ALFA put in the alias, and the
             day stamp that makes them wait until tomorrow. Both land seconds
             before the NPC's reply is chosen, which is after the player picks;
             and the stamp closes the re-greet that follows the reply, 140 ms
             after it, so the conversation hands back to the NPC's own dialogue.
  OnEnd   -- one line from the Narrator on how it went (O-9); then, once the
             scene has really stopped, the alias is let go, and the persona and
             the room are forgotten.
And on a nameless NPC's first approach, Rapport gives them a name (O-10).
And on each NPC reply, through Overture:Reply: as the line BEGINS, stage 3's
verdict (only at the stage-2 land); as it ENDS, the bond and the stage reached.

THE DEV CHANNEL, through F4MCP's addon protocol (with no F4MCP.esp the bridge
resolves to None and none of it registers):
  approach <npc>         force the scene on this NPC now, eligible or not
  approach reset <npc>   clear the day stamp, so the next talk opens it again
  approach forget <npc>  clear the day stamp AND the stage reached (stage 1 again)
  approach status <npc>  what the gate sees for this NPC, the stage reached, the bond
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
Int Property STAGE_REACHED_AV_ID = 0x00000844 AutoReadOnly
Int Property BRIDGE_ID = 0x00000800 AutoReadOnly
Int Property TARGET_ALIAS = 0 AutoReadOnly

; What a reply is worth to the bond (docs/methodology.md 3). A fraction of the
; distance left, the way every source moves Rapport's store. ASSUMED numbers,
; for the owner to tune; they belong on the MCM page when there is one.
Float Property LAND_STAGE_1 = 0.05 AutoReadOnly
Float Property LAND_STAGE_2 = 0.07 AutoReadOnly
Float Property OFFEND = -0.04 AutoReadOnly
Float Property RECOIL = -0.06 AutoReadOnly
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
Float Property NOTYET = 0.02 AutoReadOnly
Float Property REFUSE = -0.03 AutoReadOnly
; Spoken for (methodology 7): refused outright at this faithfulness, otherwise
; the bar rises by this much of it. ASSUMED.
Float Property SPOKEN_FOR_FAITH = 0.8 AutoReadOnly
Float Property FAITH_WEIGHT = 0.4 AutoReadOnly

; Rapport 0.2.1: NarrateLine, Introduce and ObserversNear. Older, and none of
; the three is bound -- every call would be a Papyrus error and a wrong answer.
Int Property NEEDS_API = 201 AutoReadOnly
; Why a verdict came out as it did (Decide). The Narrator words two of them
; differently; all of them go into the trace.
Int Property WHY_NO_PERSONA = 1 AutoReadOnly
Int Property WHY_TAKEN = 2 AutoReadOnly
Int Property WHY_EARLY = 3 AutoReadOnly
Int Property WHY_BOND = 4 AutoReadOnly
Int Property WHY_PUBLIC = 5 AutoReadOnly
Int Property WHY_SETTING = 6 AutoReadOnly
Int Property WHY_BUSY = 7 AutoReadOnly
Int Property WHY_YES = 8 AutoReadOnly

Int _api = 0
Int _why = 0

; O-16, the player's priority lane (owner, 2026-09-23): Rapport's one scene slot is
; HELD for the player and this NPC from the moment the proposition would be a yes,
; so Chemistry cannot take it while the player picks, the yes plays and the request
; goes in. Refreshed at the yes to cover the minute of retries; let go when the
; conversation ends without one, or when the retries give up.
Float Property HOLD_AT_VERDICT = 90.0 AutoReadOnly
; OvertureStageReached: 0 never landed, 1-2 the stage that landed, 3 proposed,
; and 4 the LOVER state (O-12): they said yes once -- or, for the NEXT
; conversation, the bond or the engine made them that close (O-14's lover tier).
; A lover's conversation opens at the proposition. The scene's own conditions
; read this value as it starts, so it is written between conversations, never
; during one. tools/overture_stages.py STAGE_LOVER must match.
Int Property STAGE_LOVER = 4 AutoReadOnly
Float Property LOVER_BOND = 0.75 AutoReadOnly
Float Property HOLD_AT_YES = 70.0 AutoReadOnly
Actor _held = None

; ONE conversation's facts, for its one Narrator line (O-9). Set at OnBegin,
; filled by each reply as it ends, spoken and cleared at the real OnEnd.
Actor _talkWith = None
String _talkIntro = ""
Float _talkBondBefore = 0.0
Float _talkBondAfter = 0.0
Int _talkStage = 0
Int _talkOutcome = 0
Int _talkVerdict = 0
Int _talkWhy = 0

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

ActorValue Function NextDayAV()
	Return Game.GetFormFromFile(NEXT_DAY_AV_ID, "Overture.esp") as ActorValue
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
		Debug.Trace("Overture: Rapport's ApiVersion is " + _api + ", Overture needs " + NEEDS_API + " - no narration, no names, and nobody counts as watching", 2)
		Debug.Notification("Overture needs Rapport 0.2.1 or newer.")
	EndIf

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
	; A conversation whose real end this script never saw: its OnEnd came while
	; this one was already playing. Its line is still owed.
	Self.Narrate()
	String note = Self.Prepare(who)
	Self.Stamp(who)
	Self.BeginTalk(who)
	Self.LoverOpening(who)
	If _talkIntro != ""
		note = note + " | introduced as " + _talkIntro
	EndIf
	Debug.Trace("Overture: approach opened with " + who.GetFormID() + note, 0)
EndEvent

Event Scene.OnPhaseBegin(Scene akSender, Int auiPhaseIndex)
	Debug.Trace("Overture: scene phase " + auiPhaseIndex + " began", 0)
EndEvent

Event Scene.OnEnd(Scene akSender)
	; The line FIRST, and unconditionally. MEASURED 2026-09-23 on a Third Rail
	; Drifter, twice: this event arrives while the scene still reports
	; IsPlaying(), so the guard that used to stand here turned away every real end
	; and each line was spoken one conversation late, by the next OnBegin. The
	; facts in _talk* are this conversation's either way: events arrive in order,
	; so the next conversation's OnBegin cannot have run before this one.
	Actor who = _talkWith
	; No yes in this conversation: nothing will ask for the slot it may be holding.
	If _talkOutcome != OUTCOME_ACCEPT
		Self.LetGo()
	EndIf
	If who != None
		Self.BetweenConversations(who, _talkOutcome)
	EndIf
	Self.Narrate()
	; The tidy-up is different. One scene serves every conversation, and clearing
	; the alias under one that has already begun would break it. NOT IsPlaying():
	; MEASURED 2026-09-23, it still said True five seconds after this event
	; ("IsPlaying at the event True, after 5.000000 s True"), so it guarded nothing
	; and the tidy-up never ran. The alias says it instead: ALFA puts the next
	; speaker in it before their scene begins, so while it holds nobody else,
	; nobody else has the scene.
	Actor inAlias = Self.TargetAlias().GetActorReference()
	If inAlias != None && inAlias != who
		Debug.Trace("Overture: scene ended - " + inAlias.GetFormID() + " already holds the alias, left as it is", 0)
		Return
	EndIf
	Debug.Trace("Overture: scene ended - alias let go, persona and room forgotten", 0)
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
EndEvent

Actor _yesWith = None
Int _yesTries = 0

ActorValue Function StageReachedAV()
	Return Game.GetFormFromFile(STAGE_REACHED_AV_ID, "Overture.esp") as ActorValue
EndFunction

; A number the MCM page tunes: its global, or the built-in default when the
; global is missing (the one-exchange build has none). tools/overture_stages.py
; SETTINGS is the one table the globals, the page and these defaults come from.
Float Function Tuned(Int aiID, Float afDefault)
	GlobalVariable g = Game.GetFormFromFile(aiID, "Overture.esp") as GlobalVariable
	If g == None
		Return afDefault
	EndIf
	Return g.GetValue()
EndFunction

Float Function Worth(Int aiStage, Int aiOutcome)
	If aiOutcome == OUTCOME_LAND
		If aiStage >= 2
			Return Self.Tuned(0x00000E01, LAND_STAGE_2)
		EndIf
		Return Self.Tuned(0x00000E00, LAND_STAGE_1)
	ElseIf aiOutcome == OUTCOME_OFFEND
		Return Self.Tuned(0x00000E02, OFFEND)
	ElseIf aiOutcome == OUTCOME_RECOIL
		Return Self.Tuned(0x00000E03, RECOIL)
	ElseIf aiOutcome == OUTCOME_NOTYET
		Return Self.Tuned(0x00000E04, NOTYET)
	ElseIf aiOutcome == OUTCOME_REFUSE
		Return Self.Tuned(0x00000E05, REFUSE)
	EndIf
	; A miss is the player learning, a recoil on the persona it would have landed
	; with is "yes, not here", and a yes writes nothing: the scene does, and
	; writing both would be R-10's double count through the other door.
	Return 0.0
EndFunction

GlobalVariable Function VerdictGlobal()
	Return Game.GetFormFromFile(VERDICT_GLOBAL_ID, "Overture.esp") as GlobalVariable
EndFunction

GlobalVariable Function ScenesGlobal()
	Return Game.GetFormFromFile(SCENES_GLOBAL_ID, "Overture.esp") as GlobalVariable
EndFunction

; The bond a yes needs, per persona, in PERSONAS order (methodology 3). ASSUMED.
Float Function Threshold(Int aiPersona)
	If aiPersona == 0
		Return Self.Tuned(0x00000E06, 0.15)
	ElseIf aiPersona == 1
		Return Self.Tuned(0x00000E07, 0.25)
	ElseIf aiPersona == 2
		Return Self.Tuned(0x00000E08, 0.08)
	EndIf
	Return Self.Tuned(0x00000E09, 0.30)
EndFunction

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
; own tolerance (C-6). Unknown (-1: no scan yet) is public, as in Prepare.
Bool Function InPublic(Actor akWho)
	Int watching = Rapport:Core.ObserversNear(akWho.GetFormID())
	Return watching < 0 || watching > Rapport:Core.ObserverTolerance()
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
; (docs/methodology.md 2). The staged plugin reads it twice: phase 3 opens only
; if it is at least "not yet" -- so a proposition that could only be refused is
; never offered -- and the persona's own register answers with it.
; Leaves the reason in _why, for the caller that wants it.
Int Function Decide(Actor akWho, Float afBond, Bool abPublic, Bool abLover)
	Int persona = Self.PersonaIndex(akWho)
	If persona < 0
		_why = WHY_NO_PERSONA
		Return VERDICT_REFUSE
	EndIf
	; A LOVER (O-12) has cleared the bar already and is not "spoken for" against
	; the player; only the place and the moment still decide.
	If !abLover
		Float bar = Self.Threshold(persona)
		If Self.SpokenFor(akWho)
			Float faith = Rapport:Core.FaithfulnessOf(akWho.GetFormID())
			If faith >= Self.Tuned(0x00000E0B, SPOKEN_FOR_FAITH)
				_why = WHY_TAKEN
				Return VERDICT_REFUSE
			EndIf
			bar += Self.Tuned(0x00000E0C, FAITH_WEIGHT) * faith
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
	If Rapport:Core.Busy() || Rapport:Core.CanRun(Self.ScenarioFor(akWho, persona), Game.GetPlayer(), akWho) < 0
		_why = WHY_BUSY
		Return VERDICT_NOT_NOW
	EndIf
	_why = WHY_YES
	Return VERDICT_ACCEPT
EndFunction

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
	GlobalVariable last = Game.GetFormFromFile(LAST_OUTCOME_GLOBAL_ID, "Overture.esp") as GlobalVariable
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
	GlobalVariable inPublic = Self.PublicGlobal()
	Bool room = inPublic == None || inPublic.GetValue() != 0.0
	Float bond = Self.AfterLand(Rapport:Relations.BondBetween(Game.GetPlayer(), akWho), Self.Tuned(0x00000E01, LAND_STAGE_2))
	Int decided = Self.Decide(akWho, bond, room, False)
	verdict.SetValue(decided as Float)
	If akWho == _talkWith
		_talkVerdict = decided
		_talkWhy = _why
	EndIf
	Debug.Trace("Overture: " + akWho.GetFormID() + " stage 3 verdict " + decided + " (why " + _why + ") on bond " + bond, 0)
	If decided == VERDICT_ACCEPT && _api >= NEEDS_API
		Rapport:Core.ReservePlayerScene(akWho, HOLD_AT_VERDICT)
		_held = akWho
	EndIf
EndFunction

; Let Rapport's slot go, if this script is holding it.
Function LetGo()
	If _held == None
		Return
	EndIf
	If _api >= NEEDS_API
		Rapport:Core.ReservePlayerScene(_held, 0.0)
	EndIf
	_held = None
EndFunction

; Stage 4, behind OvertureScenesEnabled until a Rapport scene with the player in
; it has been watched end to end (methodology 5).
Function Proposition(Actor akWho)
	GlobalVariable scenes = Self.ScenesGlobal()
	If scenes == None || scenes.GetValue() == 0.0
		Debug.Trace("Overture: " + akWho.GetFormID() + " said yes; scenes are off (OvertureScenesEnabled 0)", 0)
		Self.LetGo()
		Return
	EndIf
	If _api >= NEEDS_API
		Rapport:Core.ReservePlayerScene(akWho, HOLD_AT_YES)
		_held = akWho
	EndIf
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
		_held = None
		_yesWith = None
		Return
	EndIf
	_yesTries += 1
	If _yesTries >= YES_RETRIES
		Debug.Trace("Overture: " + akWho.GetFormID() + " said yes and Rapport never had a free slot - the yes is lost", 1)
		If _api >= NEEDS_API
			Rapport:Core.NarrateLine(player.GetFormID(), akWho.GetFormID(), "{second} said yes, but the moment passed.", "")
		EndIf
		Self.LetGo()
		_yesWith = None
		Return
	EndIf
	Self.StartTimer(YES_RETRY_SECONDS, YES_TIMER)
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID == YES_TIMER
		Self.AskForTheScene()
	EndIf
EndEvent

; Called by Overture:Reply when an NPC's reply line has been said. Writes the
; bond (R-10: add this much, for this reason) and the stage this NPC has
; reached with the player, which decides where tomorrow's conversation starts.
Function Replied(Actor akWho, Int aiStage, Int aiOutcome)
	If akWho == None
		Return
	EndIf
	String note = "Overture: " + akWho.GetFormID() + " replied, stage " + aiStage + " outcome " + aiOutcome
	Float worth = Self.Worth(aiStage, aiOutcome)
	Float after = -2.0
	If worth != 0.0
		Float before = Rapport:Relations.BondBetween(Game.GetPlayer(), akWho)
		after = Rapport:Relations.AddBondBetween(Game.GetPlayer(), akWho, worth, REASON_DIALOGUE)
		note = note + " | bond " + before + " -> " + after
	EndIf
	; The Narrator speaks for the LAST reply of the conversation, and the bond
	; the whole conversation left.
	If akWho == _talkWith
		_talkStage = aiStage
		_talkOutcome = aiOutcome
		If after > -2.0
			_talkBondAfter = after
		EndIf
	EndIf
	; The stage they have reached with the player: a land at stages 1-2, and any
	; answer at all at stage 3 ("3 proposed", methodology 8).
	If aiOutcome == OUTCOME_LAND || aiStage == 3
		ActorValue reached = Self.StageReachedAV()
		If reached != None && akWho.GetValue(reached) < aiStage as Float
			akWho.SetValue(reached, aiStage as Float)
			note = note + " | stage reached " + aiStage
		EndIf
	EndIf
	If aiOutcome == OUTCOME_ACCEPT
		Self.BecomeLovers(akWho)
		note = note + " | lovers"
		Self.Proposition(akWho)
	EndIf
	Debug.Trace(note, 0)
EndFunction

; ---- O-12: the lover state ---------------------------------------------------
Bool Function IsLover(Actor akWho)
	ActorValue reached = Self.StageReachedAV()
	Return reached != None && akWho.GetValue(reached) >= STAGE_LOVER as Float
EndFunction

; After the first yes they are lovers: Overture's stage marker, which tomorrow's
; greeting and entry stage read, and Rapport's store (O-15), which Chemistry
; reads behind its own switch. Written at the yes itself, so a yes whose scene
; never starts still counts: the NPC said it.
Function BecomeLovers(Actor akWho)
	ActorValue reached = Self.StageReachedAV()
	If reached != None && akWho.GetValue(reached) < STAGE_LOVER as Float
		akWho.SetValue(reached, STAGE_LOVER as Float)
	EndIf
	If _api >= NEEDS_API
		Rapport:Core.SetLovers(Game.GetPlayer().GetFormID(), akWho.GetFormID(), True)
	EndIf
EndFunction

; A lover's conversation opens at the proposition (the scene skips stages 1 and
; 2 on the stage marker alone), so the verdict is decided HERE, as it begins --
; seconds before the player can pick, the same timing the persona relies on.
Function LoverOpening(Actor who)
	If !Self.IsLover(who)
		Return
	EndIf
	GlobalVariable verdict = Self.VerdictGlobal()
	If verdict == None
		Return
	EndIf
	GlobalVariable inPublic = Self.PublicGlobal()
	Bool room = inPublic == None || inPublic.GetValue() != 0.0
	Int decided = Self.Decide(who, Rapport:Relations.BondBetween(Game.GetPlayer(), who), room, True)
	verdict.SetValue(decided as Float)
	_talkVerdict = decided
	_talkWhy = _why
	Debug.Trace("Overture: " + who.GetFormID() + " is a lover - straight to the proposition, verdict " + decided + " (why " + _why + ")", 0)
	If decided == VERDICT_ACCEPT && _api >= NEEDS_API
		Rapport:Core.ReservePlayerScene(who, HOLD_AT_VERDICT)
		_held = who
	EndIf
EndFunction

; Between one conversation and the next: what tomorrow's scene will read as it
; starts, so it is written now, never during a conversation.
Function BetweenConversations(Actor who, Int aiLastOutcome)
	; O-13: a "not now" gives the day back. The moment was wrong, not the person,
	; so the right hour or the right room may still be found today.
	If aiLastOutcome == OUTCOME_NOT_NOW
		ActorValue day = Self.NextDayAV()
		If day != None
			who.SetValue(day, 0.0)
		EndIf
	EndIf
	; O-14's lover tier: close enough by the bond, or partners by the engine, opens
	; the next conversation at the proposition too. Overture's marker only: Rapport's
	; lovers flag is the yes's alone.
	If !Self.IsLover(who)
		Actor player = Game.GetPlayer()
		If Rapport:Relations.BondBetween(player, who) >= Self.Tuned(0x00000E0A, LOVER_BOND) || Rapport:Relations.ArePartners(player, who)
			ActorValue reached = Self.StageReachedAV()
			If reached != None
				who.SetValue(reached, STAGE_LOVER as Float)
				Debug.Trace("Overture: " + who.GetFormID() + " is close enough to open at the proposition next time", 0)
			EndIf
		EndIf
	EndIf
EndFunction

; ---- O-9: the Narrator ------------------------------------------------------
; The owner, 2026-09-23: "we definitely need a narrator here as we have for
; chemistry" -- to let players know, without killing the mood, what is
; happening and how when they act. So: ONE line per conversation, when it has
; really ended, through Rapport's Narrator (O-1: one module narrates every
; mod). It says what the player's words did and hints at what to do about it:
; the place, the time, patience, another way. It NEVER names a persona -- the
; README's rule, "you are never told who they are", stands over this too.
; And nothing on a yes: Rapport's own line says who and why as the scene starts.

; O-10: a nameless NPC gets a name on their first approach. Rapport decides who
; is nameless (a base not flagged Unique) and keeps it; "" means no new name.
Function BeginTalk(Actor who)
	_talkWith = who
	_talkIntro = ""
	If _api >= NEEDS_API
		_talkIntro = Rapport:Core.Introduce(who)
	EndIf
	_talkBondBefore = Rapport:Relations.BondBetween(Game.GetPlayer(), who)
	_talkBondAfter = _talkBondBefore
	_talkStage = 0
	_talkOutcome = 0
	_talkVerdict = 0
	_talkWhy = 0
EndFunction

; The conversation's line, then forget it. Safe to call twice: the second finds
; nobody.
Function Narrate()
	Actor who = _talkWith
	_talkWith = None
	If who == None || _api < NEEDS_API
		Return
	EndIf
	If _talkOutcome == OUTCOME_ACCEPT
		; Nothing on a yes, not even the name: Rapport's own line names them both
		; as the scene starts, and two lines at once is the noise O-9 rules out.
		Return
	EndIf
	String headline = Self.TalkLine(who)
	; Only a bond that MOVED. "bond +0.00" under a miss read as a change of nothing
	; when it was the bond itself (first run, 2026-09-23), and a line that says
	; nothing moved needs no number to prove it.
	String numbers = ""
	If headline != "" && _talkBondAfter != _talkBondBefore
		numbers = "bond " + Self.Signed(_talkBondBefore) + " -> " + Self.Signed(_talkBondAfter)
	EndIf
	If _talkIntro != ""
		; The name comes first, and the sentence after it says "she", not the name
		; twice (Subject).
		String intro = Self.Possessive(who) + " name is {second}."
		If headline == ""
			headline = intro
		Else
			headline = intro + " " + headline
		EndIf
	EndIf
	If headline == ""
		Return
	EndIf
	Rapport:Core.NarrateLine(Game.GetPlayer().GetFormID(), who.GetFormID(), headline, numbers)
EndFunction

; What the conversation's last reply did, in one sentence. "" for nothing said,
; for a fallback beat, and for a yes.
String Function TalkLine(Actor akWho)
	If Self.PersonaIndex(akWho) < 0
		; No persona from Rapport: every reply was a neutral "..." and none of the
		; sentences below would be true.
		Return ""
	EndIf
	String s = Self.Subject(akWho, True)
	If _talkOutcome == OUTCOME_MISS
		If _talkStage == 1
			Return s + " didn't take to that. Another day, another way."
		ElseIf _talkStage == 2
			; A stage-2 miss is a DIFFERENT register from the one that landed.
			Return s + " didn't take to that. What worked before might work again."
		EndIf
		; Stage 3's misses are the fallback beats, not something the player chose.
		Return ""
	ElseIf _talkOutcome == OUTCOME_OFFEND
		Return s + " took offence. Not everyone likes it blunt."
	ElseIf _talkOutcome == OUTCOME_RECOIL
		Return s + " didn't care for that - least of all in front of people."
	ElseIf _talkOutcome == OUTCOME_RECOIL_LIKED
		Return s + " liked that - just not with people watching."
	ElseIf _talkOutcome == OUTCOME_LAND
		If _talkStage == 1
			If Self.PersonaIndex(akWho) == 3
				; R-8: nothing more the first time; the conversation handed back.
				Return s + " heard you out. Some people take time."
			EndIf
			; A first land always opens stage 2, so the player walked away from it.
			Return s + " warmed to you. Talk again tomorrow."
		EndIf
		; The stage-2 land, and what stage 3 would have said.
		If _talkVerdict == VERDICT_REFUSE
			If _talkWhy == WHY_TAKEN
				Return s + " enjoyed that - but there's someone else."
			EndIf
			Return s + " enjoyed that. Only talk, for now - keep coming back."
		EndIf
		If _talkVerdict == 0
			; No verdict recorded for this conversation, so whether stage 3 was
			; offered is unknown -- say only what is known.
			Return s + " enjoyed that."
		EndIf
		; Stage 3 was on the wheel and the player left without asking.
		Return s + " enjoyed that. You could have asked for more."
	ElseIf _talkOutcome == OUTCOME_NOTYET
		Return "Close. A little more time with you, and " + Self.Subject(akWho, False) + " might."
	ElseIf _talkOutcome == OUTCOME_NOT_HERE
		Return s + " would - somewhere without an audience."
	ElseIf _talkOutcome == OUTCOME_NOT_NOW
		If _talkWhy == WHY_SETTING
			Return s + " would - indoors, or after dark."
		EndIf
		Return s + " would - just not right now."
	ElseIf _talkOutcome == OUTCOME_REFUSE
		Return s + " turned you down. That wasn't the way to ask."
	EndIf
	Return ""
EndFunction

; Their name ("{second}", which Rapport fills), or right after "Her name is
; ..." a pronoun. Every sentence above puts a pronoun subject before a past
; tense or a modal, so "they" never needs a different verb.
String Function Subject(Actor akWho, Bool abCapital)
	If _talkIntro == ""
		Return "{second}"
	EndIf
	Int sex = Self.SexOf(akWho)
	If sex == 1
		If abCapital
			Return "She"
		EndIf
		Return "she"
	ElseIf sex == 0
		If abCapital
			Return "He"
		EndIf
		Return "he"
	EndIf
	If abCapital
		Return "They"
	EndIf
	Return "they"
EndFunction

String Function Possessive(Actor akWho)
	Int sex = Self.SexOf(akWho)
	If sex == 1
		Return "Her"
	ElseIf sex == 0
		Return "His"
	EndIf
	Return "Their"
EndFunction

; 0 male, 1 female, -1 unknown.
Int Function SexOf(Actor akWho)
	ActorBase base = akWho.GetLeveledActorBase()
	If base == None
		Return -1
	EndIf
	Return base.GetSex()
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

; Once a game day (O-8). The greeting compares this against GameDaysPassed, so
; the NPC opens again with tomorrow's first conversation. No timer, no list.
Function Stamp(Actor who)
	ActorValue av = Self.NextDayAV()
	If av != None
		who.SetValue(av, (Math.Floor(Utility.GetCurrentGameTime()) + 1) as Float)
	EndIf
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
		Int watching = Rapport:Core.ObserversNear(who.GetFormID())
		If watching < 0
			; No scan has published yet. NOT the same as nobody watching, so
			; assume public: a recoil the player did not expect is a smaller
			; mistake than a proposition shouted across a room.
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
	GlobalVariable last = Game.GetFormFromFile(LAST_OUTCOME_GLOBAL_ID, "Overture.esp") as GlobalVariable
	If last != None
		last.SetValue(0.0)
	EndIf
	Return note
EndFunction

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
		ActorValue av = Self.NextDayAV()
		If av == None
			MCP:Core.Reply(tag, "approach reset: the next-day actor value did not resolve")
			Return
		EndIf
		who.SetValue(av, 0.0)
		MCP:Core.Reply(tag, "approach reset: " + who.GetFormID() + " may be approached again today")
		Return
	EndIf

	; approach forget <npc> -- as if the player had never approached them: the
	; day stamp AND the stage reached. The bond is Rapport's, and stays.
	If first == "forget"
		ActorValue day = Self.NextDayAV()
		ActorValue stage = Self.StageReachedAV()
		If day != None
			who.SetValue(day, 0.0)
		EndIf
		If stage != None
			who.SetValue(stage, 0.0)
		EndIf
		MCP:Core.Reply(tag, "approach forget: " + who.GetFormID() + " starts again at stage 1, today")
		Return
	EndIf

	; approach verdict <npc> -- what stage 3 would answer right now, changing
	; nothing. Its OWN room, not the global the last conversation left behind.
	If first == "verdict"
		Float bond = Rapport:Relations.BondBetween(Game.GetPlayer(), who)
		Bool room = Self.InPublic(who)
		MCP:Core.Reply(tag, "approach verdict: " + who.GetFormID() + " | verdict=" + Self.Decide(who, bond, room, Self.IsLover(who)) + " (1 refuse 2 notyet 3 accept 4 not here 5 not now) | bond=" + bond + " | bar=" + Self.Threshold(Self.PersonaIndex(who)) + " | public=" + room + " | spokenFor=" + Self.SpokenFor(who))
		Return
	EndIf

	If first == "status"
		ActorValue sav = Self.NextDayAV()
		Float stamp = -1.0
		If sav != None
			stamp = who.GetValue(sav)
		EndIf
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
		ActorValue reached = Self.StageReachedAV()
		If reached != None
			s = s + " | stageReached=" + who.GetValue(reached)
		EndIf
		s = s + " | bond=" + Rapport:Relations.BondBetween(Game.GetPlayer(), who)
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
