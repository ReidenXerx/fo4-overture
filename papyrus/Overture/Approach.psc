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
Int Property BRIDGE_ID = 0x00000800 AutoReadOnly
Int Property TARGET_ALIAS = 0 AutoReadOnly

MCP:Bridge Function Bridge()
	Return Game.GetFormFromFile(BRIDGE_ID, "F4MCP.esp") as MCP:Bridge
EndFunction

Scene Function ApproachScene()
	Return Game.GetFormFromFile(SCENE_ID, "Overture.esp") as Scene
EndFunction

ReferenceAlias Function TargetAlias()
	Return (Self as Quest).GetAlias(TARGET_ALIAS) as ReferenceAlias
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

	sc.Start()
	Utility.Wait(0.5)
	note = note + " | playing after Start=" + sc.IsPlaying()
	If !sc.IsPlaying()
		sc.ForceStart()
		Utility.Wait(0.5)
		note = note + " | after ForceStart=" + sc.IsPlaying()
	EndIf
	MCP:Core.Reply(tag, note)
EndEvent
