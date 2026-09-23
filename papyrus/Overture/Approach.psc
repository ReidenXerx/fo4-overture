Scriptname Overture:Approach extends Quest
{The approach. For now it only proves the records work.

Fallout 4's Papyrus has no RegisterForKey -- that is SKSE -- so there is no
hotkey available to a vanilla-scripted mod. The dev trigger is F4MCP's addon
protocol instead, which exists for exactly this and costs a player nothing: with
no F4MCP.esp the bridge resolves to None and this script never registers.

O-7 is the SHIPPED trigger and it is not this: the registers are meant to appear
when you talk to an eligible NPC, in normal dialogue. That needs an alias filled
per conversation rather than by hand, and the mechanism for it is the next thing
to work out. This verb answers a smaller question first -- do the four options
appear on the wheel at all -- because building the real trigger on top of records
nobody has ever seen load would be building it twice.

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
Int Property BRIDGE_ID = 0x00000800 AutoReadOnly
Int Property TARGET_ALIAS = 0 AutoReadOnly
Int Property ARMED_GLOBAL_ID = 0x00000842 AutoReadOnly

; ONE EXCHANGE, then the NPC's own dialogue (owner poll 2026-09-23). The greeting
; that opens Overture's scene needs OvertureArmed == 1 as well as the alias. The
; scene is watched: the moment it is seen playing the approach is DISARMED, so
; when the engine re-greets after the reply -- 140 ms after it, measured -- the
; NPC's own greeting wins and their normal options come back. Once the scene has
; stopped, the alias is let go. Without this the repeatable greeting fired again
; after every reply and the player was held in Overture's four options for ever.
; A poll rather than the scene's OnEnd event, because a queued event is not
; guaranteed to land inside those 140 ms; disarming at the START is seconds early.
Int Property WATCH_TIMER = 1 AutoReadOnly
Float Property WATCH_EVERY = 0.5 AutoReadOnly
Float Property ARMED_FOR = 120.0 AutoReadOnly

Bool watchSawScene = false
Float watchArmedAt = 0.0

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

GlobalVariable Function ArmedGlobal()
	Return Game.GetFormFromFile(ARMED_GLOBAL_ID, "Overture.esp") as GlobalVariable
EndFunction

Function Watch()
	Self.CancelTimer(WATCH_TIMER)
	watchSawScene = false
	watchArmedAt = Utility.GetCurrentRealTime()
	Self.StartTimer(WATCH_EVERY, WATCH_TIMER)
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID != WATCH_TIMER
		Return
	EndIf
	Scene sc = Self.ApproachScene()
	If sc != None && sc.IsPlaying()
		If !watchSawScene
			watchSawScene = true
			GlobalVariable armed = Self.ArmedGlobal()
			If armed != None
				armed.SetValue(0.0)
			EndIf
		EndIf
		Self.StartTimer(WATCH_EVERY, WATCH_TIMER)
		Return
	EndIf
	If watchSawScene
		; the exchange happened and is over
		Self.Release()
		Return
	EndIf
	If Utility.GetCurrentRealTime() - watchArmedAt > ARMED_FOR
		; armed but never used: nobody should walk up to this NPC a day later and
		; still be ambushed by the approach
		Self.Release()
		Return
	EndIf
	Self.StartTimer(WATCH_EVERY, WATCH_TIMER)
EndEvent

Function Release()
	GlobalVariable armed = Self.ArmedGlobal()
	If armed != None
		armed.SetValue(0.0)
	EndIf
	ReferenceAlias target = Self.TargetAlias()
	If target != None
		target.Clear()
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
	; The plugin starts from nothing every launch and forgets every addon on a
	; save change, so the registration has to happen again on every load.
	Self.Hook()
EndEvent

Function Hook()
	Self.RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
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

	; Second token "noscene" fills the alias and does NOT start the scene.
	; The hypothesis it tests: in vanilla you ENTER a dialogue scene by talking to
	; the actor, rather than starting it first. An actor already inside a scene is
	; not activatable -- measured, the "Talk to" prompt disappears -- so starting
	; it by hand may be exactly backwards.
	Bool startScene = true
	If count > 1 && (akArgs[6] as String) == "noscene"
		startScene = false
	EndIf

	Actor who = None
	If count > 0
		Int formID = akArgs[5] as Int
		If formID != 0
			who = Game.GetForm(formID) as Actor
		EndIf
	EndIf
	If who == None
		; No id given, or it named nothing. Nearest actor is enough for "do the
		; options appear"; the shipped trigger will not work this way.
		who = Game.FindClosestActorFromRef(Game.GetPlayer(), 600.0)
	EndIf
	If who == None
		MCP:Core.Reply(tag, "approach: nobody within 600 units")
		Return
	EndIf

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

	; Report what the engine THINKS, not what we asked for. Scene.Start() is void,
	; so "started" was never a fact - the first version said it anyway and the
	; actor's state said scene=False.
	String note = "approach: quest running=" + (Self as Quest).IsRunning()
	Quest owner = sc.GetOwningQuest()
	If owner == None
		note = note + " | scene owner=None (the scene's PNAM did not resolve)"
	ElseIf owner == (Self as Quest)
		note = note + " | scene owner=this quest"
	Else
		note = note + " | scene owner=SOMEONE ELSE"
	EndIf

	; Which of the sixteen replies this NPC can give. Set BEFORE the scene
	; starts: the conditions are read when the options are built, and a global
	; set afterwards is a global set too late.
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

	If !startScene
		; Armed: the next time the player talks to them, the greeting opens the
		; approach -- once (see Watch).
		GlobalVariable armed = Self.ArmedGlobal()
		If armed == None
			MCP:Core.Reply(tag, note + " | OvertureArmed did not resolve - the greeting can never fire")
			Return
		EndIf
		armed.SetValue(1.0)
		Self.Watch()
		MCP:Core.Reply(tag, note + " | ARMED (noscene) - alias filled, now talk to them; one exchange, then theirs")
		Return
	EndIf

	sc.Start()
	Utility.Wait(0.5)
	note = note + " | playing after Start=" + sc.IsPlaying()
	If !sc.IsPlaying()
		sc.ForceStart()
		Utility.Wait(0.5)
		note = note + " | after ForceStart=" + sc.IsPlaying()
	EndIf
	; Started by hand, so nothing to arm -- but the alias still has to be let go
	; once the exchange is over, or the next conversation is ours again.
	Self.Watch()
	MCP:Core.Reply(tag, note)
EndEvent
