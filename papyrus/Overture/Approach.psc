Scriptname Overture:Approach extends Quest
{Overture's approach: an eligible NPC the player talks to gets the player's four
registers first -- then their own dialogue takes over.

HOW IT OPENS (O-7, verified in game 2026-09-23). The greeting carries ALFA,
"Forced Alias": the engine puts whoever says it into alias 0 and starts the
scene. That is vanilla's own generic-greeting shape -- one quest serving every
vendor and doctor in the game. WHO it opens for is the greeting's conditions, run
on the speaker (O-8): adults, humans and ghouls, not the player's current
companion, not in combat, not already in a scene, once per game day. Nothing in
this script decides eligibility; the engine does, before this script hears a
thing.

WHAT THIS SCRIPT DOES, on the scene's own events:
  OnBegin -- the persona and the room for whoever ALFA put in the alias, and the
             day stamp that makes them wait until tomorrow. Both land seconds
             before the NPC's reply is chosen, which is after the player picks;
             and the stamp closes the re-greet that follows the reply, 140 ms
             after it, so the conversation hands back to the NPC's own dialogue.
  OnEnd   -- the alias is let go.

THE DEV CHANNEL, through F4MCP's addon protocol (with no F4MCP.esp the bridge
resolves to None and none of it registers):
  approach <npc>         force the scene on this NPC now, eligible or not
  approach reset <npc>   clear the day stamp, so the next talk opens it again
  approach status <npc>  what the gate sees for this NPC

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

; Overture:Reply's Outcome property, as the builder writes it.
Int Property OUTCOME_LAND = 1 AutoReadOnly
Int Property OUTCOME_MISS = 2 AutoReadOnly
Int Property OUTCOME_OFFEND = 3 AutoReadOnly
Int Property OUTCOME_RECOIL = 4 AutoReadOnly
Int Property OUTCOME_RECOIL_LIKED = 5 AutoReadOnly

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

	; THE ALWAYS-ON HALF. The scene's own events, for every approach the engine
	; opens -- the dev verb is not involved.
	Scene sc = Self.ApproachScene()
	If sc != None
		Self.RegisterForRemoteEvent(sc, "OnBegin")
		Self.RegisterForRemoteEvent(sc, "OnEnd")
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
	String note = Self.Prepare(who)
	Self.Stamp(who)
	Debug.Trace("Overture: approach opened with " + who.GetFormID() + note, 0)
EndEvent

Event Scene.OnEnd(Scene akSender)
	Self.TargetAlias().Clear()
EndEvent

ActorValue Function StageReachedAV()
	Return Game.GetFormFromFile(STAGE_REACHED_AV_ID, "Overture.esp") as ActorValue
EndFunction

Float Function Worth(Int aiStage, Int aiOutcome)
	If aiOutcome == OUTCOME_LAND
		If aiStage >= 2
			Return LAND_STAGE_2
		EndIf
		Return LAND_STAGE_1
	ElseIf aiOutcome == OUTCOME_OFFEND
		Return OFFEND
	ElseIf aiOutcome == OUTCOME_RECOIL
		Return RECOIL
	EndIf
	; A miss is the player learning, and a recoil on the persona it would have
	; landed with is "yes, not here": neither costs anything.
	Return 0.0
EndFunction

; Called by Overture:Reply when an NPC's reply line has been said. Writes the
; bond (R-10: add this much, for this reason) and the stage this NPC has
; reached with the player, which decides where tomorrow's conversation starts.
Function Replied(Actor akWho, Int aiStage, Int aiOutcome)
	If akWho == None
		Return
	EndIf
	String note = "Overture: " + akWho.GetFormID() + " replied, stage " + aiStage + " outcome " + aiOutcome
	Float worth = Self.Worth(aiStage, aiOutcome)
	If worth != 0.0
		Float before = Rapport:Relations.BondBetween(Game.GetPlayer(), akWho)
		Float after = Rapport:Relations.AddBondBetween(Game.GetPlayer(), akWho, worth, REASON_DIALOGUE)
		note = note + " | bond " + before + " -> " + after
	EndIf
	If aiOutcome == OUTCOME_LAND
		ActorValue reached = Self.StageReachedAV()
		If reached != None && akWho.GetValue(reached) < aiStage as Float
			akWho.SetValue(reached, aiStage as Float)
			note = note + " | stage reached " + aiStage
		EndIf
	EndIf
	Debug.Trace(note, 0)
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

	; The actor is the LAST token (its form-id reading), or the nearest one.
	Actor who = None
	If count > 0
		Int formID = akArgs[3 + 2 * count] as Int
		If formID != 0
			who = Game.GetForm(formID) as Actor
		EndIf
	EndIf
	If who == None
		who = Game.FindClosestActorFromRef(Game.GetPlayer(), 600.0)
	EndIf
	If who == None
		MCP:Core.Reply(tag, "approach: nobody within 600 units")
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
