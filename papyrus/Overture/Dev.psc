Scriptname Overture:Dev extends Quest
{Overture's dev channel, through F4MCP's addon protocol -- apart from
Overture:Approach, on the same quest. Every MCP type is HERE and nowhere else:
F4MCP is not a requirement, and a player without it must lose the verbs and
nothing more. In Overture:Approach an MCP local sat in the function that
registers the scene's own events, so whether the approach worked at all hung on
whether the VM could find a dev tool's script (microscope pass 2). With no
F4MCP.esp the bridge resolves to None and none of this registers.

  approach <npc>              force the scene on this NPC now, eligible or not
  approach reset <npc>        clear the day stamp, so the next talk opens it again
  approach forget <npc>       as if never approached: the day, the stage, every
                              marker, and Rapport's lovers flag (the bond is
                              Rapport's, and stays)
  approach status <npc>       what the gate sees for this NPC, the markers, the bond
  approach verdict <npc>      what stage 3 would answer now, changing nothing
  approach scenes on|off      whether a yes really asks Rapport for a scene (MCM)
  approach room public|private|auto
                              pin the room for every approach, or let Rapport
                              count again: the Third Rail is never private}

Int Property BRIDGE_ID = 0x00000800 AutoReadOnly

Overture:Approach Function Approach()
	Return (Self as Quest) as Overture:Approach
EndFunction

MCP:Bridge Function Bridge()
	Return Game.GetFormFromFile(BRIDGE_ID, "F4MCP.esp") as MCP:Bridge
EndFunction

Event OnQuestInit()
	Self.Hook()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	; The F4MCP plugin forgets its addons on a save change: registered again on
	; every load.
	Self.Hook()
EndEvent

Function Hook()
	Self.RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
	MCP:Bridge bridge = Self.Bridge()
	If bridge == None
		; No F4MCP installed. Not an error - a player without it simply has no verbs.
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
	String first = ""
	If count > 0
		first = akArgs[4] as String
	EndIf
	String second = ""
	If count > 1
		second = akArgs[6] as String
	EndIf
	Overture:Approach app = Self.Approach()
	If app == None
		MCP:Core.Reply(tag, "approach: NOT DONE - Overture:Approach is not on this quest")
		Return
	EndIf

	; approach scenes on|off -- whether a yes really asks Rapport for a scene.
	; No actor: the switch is global, an MCM setting.
	If first == "scenes"
		If second == "on" || second == "off"
			If !app.SetScenes(second == "on")
				MCP:Core.Reply(tag, "approach scenes: NOT DONE - the switch is an MCM setting, and MCM is not installed")
				Return
			EndIf
		EndIf
		String scenes = "approach scenes: " + app.ScenesOn()
		If !app.HasSettings()
			scenes = scenes + " (MCM has not read Overture's settings.ini, so scenes stay off)"
		EndIf
		MCP:Core.Reply(tag, scenes)
		Return
	EndIf

	; approach room public|private|auto -- the room for every approach until auto.
	If first == "room"
		If second == "public"
			app.PinRoom(1)
		ElseIf second == "private"
			app.PinRoom(2)
		ElseIf second == "auto"
			app.PinRoom(0)
		EndIf
		Int pinned = app.RoomPinned()
		If pinned == 1
			MCP:Core.Reply(tag, "approach room: pinned PUBLIC for every approach - 'approach room auto' to count again")
		ElseIf pinned == 2
			MCP:Core.Reply(tag, "approach room: pinned PRIVATE for every approach - 'approach room auto' to count again")
		Else
			MCP:Core.Reply(tag, "approach room: counted by Rapport (observers against its tolerance)")
		EndIf
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
		If app.AV(app.NEXT_DAY_AV_ID) == None
			MCP:Core.Reply(tag, "approach reset: the next-day actor value did not resolve")
			Return
		EndIf
		app.SetTo(who, app.NEXT_DAY_AV_ID, 0.0)
		MCP:Core.Reply(tag, "approach reset: " + who.GetFormID() + " may be approached again today")
		Return
	EndIf

	; approach forget <npc> -- as if the player had never approached them: the day
	; stamp, the stage reached, every marker, and Rapport's lovers flag. The bond is
	; Rapport's, and stays -- so the next conversation's end may find the lover tier
	; again, which is the bond talking, not memory.
	If first == "forget"
		app.SetTo(who, app.NEXT_DAY_AV_ID, 0.0)
		app.SetTo(who, app.STAGE_REACHED_AV_ID, 0.0)
		app.SetTo(who, app.TIER_AV_ID, 0.0)
		app.SetTo(who, app.SAID_YES_AV_ID, 0.0)
		app.SetTo(who, app.INVITED_UNTIL_AV_ID, 0.0)
		app.SetTo(who, app.JEALOUSY_MARK_AV_ID, 0.0)
		app.SetTo(who, app.JEALOUS_PENDING_AV_ID, 0.0)
		If app.HasApi()
			Rapport:Core.SetLovers(Game.GetPlayer().GetFormID(), who.GetFormID(), False)
		EndIf
		MCP:Core.Reply(tag, "approach forget: " + who.GetFormID() + " starts again at stage 1, today, and is nobody's lover")
		Return
	EndIf

	; approach verdict <npc> -- what stage 3 would answer right now, changing
	; nothing and holding nothing. Its OWN room, not the global the last
	; conversation left behind.
	If first == "verdict"
		Float bond = Rapport:Relations.BondBetween(Game.GetPlayer(), who)
		Bool room = app.InPublic(who)
		Int decided = app.Decide(who, bond, room, 0)
		MCP:Core.Reply(tag, "approach verdict: " + who.GetFormID() + " | verdict=" + decided + " (1 refuse 2 notyet 3 accept 4 not here 5 not now) why=" + app.LastWhy() + " | bond=" + bond + " | bar=" + app.Threshold(app.PersonaIndex(who)) + " | public=" + room + " | spokenFor=" + app.SpokenFor(who) + " | faithfullyTaken=" + app.FaithfullyTaken(who))
		Return
	EndIf

	If first == "status"
		Float stamp = app.ValueOf(who, app.NEXT_DAY_AV_ID)
		Float today = Utility.GetCurrentGameTime()
		String s = "approach status: " + who.GetFormID() + " | stamp=" + stamp + " days=" + today
		If stamp <= today
			s = s + " (open today)"
		Else
			s = s + " (closed until day " + stamp + ")"
		EndIf
		s = s + " | persona=" + app.PersonaIndex(who) + " | teammate=" + who.IsPlayerTeammate()
		s = s + " | combat=" + who.IsInCombat() + " | scene=" + who.IsInScene() + " | child=" + who.IsChild()
		GlobalVariable en = app.EnabledGlobal()
		If en != None
			s = s + " | enabled=" + en.GetValue()
		EndIf
		s = s + " | stageReached=" + app.ValueOf(who, app.STAGE_REACHED_AV_ID) + " tier=" + app.ValueOf(who, app.TIER_AV_ID)
		s = s + " saidYes=" + app.ValueOf(who, app.SAID_YES_AV_ID) + " invitedUntil=" + app.ValueOf(who, app.INVITED_UNTIL_AV_ID)
		s = s + " | opensAtProposition=" + app.OpensAtProposition(who) + " | scenes=" + app.ScenesOn() + " room=" + app.RoomPinned()
		Actor player = Game.GetPlayer()
		s = s + " | bond=" + Rapport:Relations.BondBetween(player, who)
		If app.HasApi()
			s = s + " | lovers=" + Rapport:Core.AreLovers(player.GetFormID(), who.GetFormID()) + " scenesTogether=" + Rapport:Core.PairSceneCount(player.GetFormID(), who.GetFormID()) + " jealousyMark=" + app.ValueOf(who, app.JEALOUSY_MARK_AV_ID) + " jealousPending=" + app.ValueOf(who, app.JEALOUS_PENDING_AV_ID)
		EndIf
		MCP:Core.Reply(tag, s)
		Return
	EndIf

	; Force the scene on this NPC now, eligible or not. OnBegin prepares and stamps.
	Scene sc = app.ApproachScene()
	ReferenceAlias target = app.TargetAlias()
	If sc == None || target == None
		MCP:Core.Reply(tag, "approach: Overture.esp did not resolve - the scene or the alias came back None")
		Return
	EndIf
	; Start() does not restart a playing scene: OnBegin would never fire, and the
	; new NPC would get the last one's persona, room and verdict and no stamp.
	If sc.IsPlaying() || app.Talking()
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
