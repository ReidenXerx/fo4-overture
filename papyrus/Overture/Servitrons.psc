Scriptname Overture:Servitrons extends Quest
{O-60 (owner, 2026-10-08): "our robots should always love to have sex". A Servitron robot
(Servitron.esm, a soft dependency) always says yes, whoever asks, wherever she is.

She is a ROBOT: ActorTypeRobot, never ActorTypeNPC, and her base NPC is always flagged male
whatever her body. So this marks every Servitron near the player with her real role in the
actor value OvertureServitron, which the "Overture" choice, the greeting, the scene's phases
and the lines' male/female versions all read:
  1  a woman  (AAF_GenderOverride_Female, AAF.esm 0x0121BC)
  2  a man    (AAF_GenderOverride_Male,   AAF.esm 0x0121BB)
  0  no genitals worn (AAF_ActorBlocked, AAF.esm 0x022BB0) -- never offered -- or not known yet
Anatomy puts exactly one of the three keywords on the ACTOR on its arousal tick, from her
installed parts; a fresh one with none of them is skipped until it does.

Without Servitron.esm nothing here runs past the first lookup.}

Int Property SCAN_TIMER = 1 AutoReadOnly
Float Property SCAN_EVERY = 5.0 AutoReadOnly
Float Property SCAN_RADIUS = 4096.0 AutoReadOnly
Int Property SERVITRON_AV_ID = 0x00000870 AutoReadOnly
Int Property ROLE_NONE = 0 AutoReadOnly
Int Property ROLE_WOMAN = 1 AutoReadOnly
Int Property ROLE_MAN = 2 AutoReadOnly

Race _race
Keyword _robot
Keyword _woman
Keyword _man
Keyword _blocked
ActorValue _mark

Event OnQuestInit()
	Self.Hook()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	Self.Hook()
EndEvent

Function Hook()
	Self.RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
	_race = Game.GetFormFromFile(0x00000F99, "Servitron.esm") as Race
	_robot = Game.GetFormFromFile(0x0002CB73, "Fallout4.esm") as Keyword
	_woman = Game.GetFormFromFile(0x000121BC, "AAF.esm") as Keyword
	_man = Game.GetFormFromFile(0x000121BB, "AAF.esm") as Keyword
	_blocked = Game.GetFormFromFile(0x00022BB0, "AAF.esm") as Keyword
	_mark = Game.GetFormFromFile(SERVITRON_AV_ID, "Overture.esp") as ActorValue
	If _race == None || _robot == None || _mark == None
		Debug.Trace("Overture servitrons: Servitron.esm is not loaded - nothing to mark", 0)
		Return
	EndIf
	Debug.Trace("Overture servitrons: watching for Servitrons near the player", 0)
	Self.StartTimer(1.0, SCAN_TIMER)
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID != SCAN_TIMER
		Return
	EndIf
	Self.Scan()
	Self.StartTimer(SCAN_EVERY, SCAN_TIMER)
EndEvent

Function Scan()
	ObjectReference[] found = Game.GetPlayer().FindAllReferencesWithKeyword(_robot, SCAN_RADIUS)
	Int i = 0
	While i < found.Length
		Actor robot = found[i] as Actor
		If robot != None && robot.GetRace() == _race
			Int role = Self.RoleOf(robot)
			If role >= ROLE_NONE && robot.GetValue(_mark) != role as Float
				robot.SetValue(_mark, role as Float)
				Debug.Trace("Overture servitrons: " + robot.GetFormID() + " is role " + role + " (1 woman, 2 man, 0 not offered)", 0)
			EndIf
		EndIf
		i += 1
	EndWhile
EndFunction

; Her role from Anatomy's keyword, or -1 when Anatomy has not marked her yet (keep what
; she had: a fresh one is skipped, never unmarked by a missing tick).
Int Function RoleOf(Actor akWho)
	If _blocked != None && akWho.HasKeyword(_blocked)
		Return ROLE_NONE
	ElseIf _woman != None && akWho.HasKeyword(_woman)
		Return ROLE_WOMAN
	ElseIf _man != None && akWho.HasKeyword(_man)
		Return ROLE_MAN
	EndIf
	Return -1
EndFunction
