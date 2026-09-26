Scriptname Overture:Follow extends Quest
{O-52 (owner poll, 2026-09-27): "Follow me" -- and the immersive part is the point: the
owner asked for it because "in old analogue mods [they] could go with you like on the
opposite of the map".

TWO WAYS IN. Someone who answers "not here" (they would have said yes, but too many are
watching) follows you, from Approach.Finish. And "Follow me" beside Talk (the perk,
Overture:Fragments:FollowPerk) asks anyone warm -- landed with you before, said yes
once, or invited back today -- and they answer in their own voice.

HOW THEY FOLLOW. Alias 0 of this quest carries vanilla's FollowPlayer package (Fallout4.esm
PACK 0002A105, its target the player): the engine walks them after you, through doors,
by its own procedure. Letting go of the alias gives them back to their day.

WHERE THEY STOP (the leash is their own place, never a radius around you):
  - anywhere inside the location they were in, and anywhere that is the same town or
    settlement (LocTypeSettlement / LocTypeWorkshopSettlement: a shop and the market
    are one Diamond City) -- never out of it: at its edge, "This is as far as I go";
  - in the open, where they stood in no location (or a lone one with no town above it),
    about 60 m from where they started, in the same worldspace;
  - two game hours without somewhere private, and they give up;
  - you running off (more than about 20 m for ten seconds), a fight, or a load, and
    it ends at once.

ARRIVAL. Somewhere private by Rapport's own count (the same rule as "not here"), and
near you: they speak first, and the next talk opens at the proposition (O-30) with the
day's stamp lifted -- a "not here" stamped it an hour ahead, and a greeting that could
not fire would have handed the talk to their vanilla dialogue. They keep following
until you talk, or their patience runs out. Any conversation with them lets go.

The lines are voice/follow-lines.json, one Say() topic per line (Rapport's shape): the
script picks the exact line by persona and version, so no line carries a condition.}

Int Property APPROACH_QUEST_ID = 0x00000800 AutoReadOnly
Int Property FOLLOWING_AV_ID = 0x00000943 AutoReadOnly
Int Property PLAYER_INFO_ID = 0x00000950 AutoReadOnly   ; five versions, 0x950-0x954
Int Property NPC_INFO_ID = 0x00000958 AutoReadOnly      ; + kind * 8 + persona * 2 + version
Int Property TOPIC_OFFSET = 0x30 AutoReadOnly           ; a line's topic is its INFO + this
Int Property KW_SETTLEMENT_ID = 0x00022611 AutoReadOnly          ; Fallout4.esm LocTypeSettlement
Int Property KW_WORKSHOP_SETTLEMENT_ID = 0x00083C9A AutoReadOnly ; Fallout4.esm LocTypeWorkshopSettlement

Int Property KIND_SILENT = -1 AutoReadOnly
Int Property KIND_AGREE = 0 AutoReadOnly
Int Property KIND_DECLINE = 1 AutoReadOnly
Int Property KIND_TOO_FAR = 2 AutoReadOnly
Int Property KIND_GIVE_UP = 3 AutoReadOnly
Int Property KIND_ARRIVAL = 4 AutoReadOnly

Int Property TICK_TIMER = 1 AutoReadOnly
Float Property TICK_SECONDS = 2.0 AutoReadOnly
; Two game hours, in days (GetCurrentGameTime's unit): the owner's poll.
Float Property PATIENCE_DAYS = 0.083334 AutoReadOnly
; About 60 m in the open (1 unit is about 1.43 cm).
Float Property LEASH_OPEN_UNITS = 4200.0 AutoReadOnly
; About 20 m: further than this, for RUNOFF_TICKS ticks in a row, and you have left them.
Float Property RUNOFF_UNITS = 1400.0 AutoReadOnly
Int Property RUNOFF_TICKS = 5 AutoReadOnly
; Near enough, somewhere private, to speak first.
Float Property ARRIVE_UNITS = 400.0 AutoReadOnly
; A line is said only where the player can hear it.
Float Property HEARD_UNITS = 1500.0 AutoReadOnly

Actor _who = None
Location _origin = None
WorldSpace _world = None
Float _startX = 0.0
Float _startY = 0.0
Float _until = 0.0
Int _strikes = 0
Bool _arrived = False

Overture:Approach Function Approach()
	Return Game.GetFormFromFile(APPROACH_QUEST_ID, "Overture.esp") as Overture:Approach
EndFunction

ReferenceAlias Function Follower()
	Return (Self as Quest).GetAlias(0) as ReferenceAlias
EndFunction

Event OnQuestInit()
	Self.RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
	Self.GivePerk()
EndEvent

; "Follow me" beside Talk: the perk is the player's, given on start and on every load
; (as Moments gives "Ask for a moment"). Its own conditions decide where it shows.
Function GivePerk()
	Actor player = Game.GetPlayer()
	Perk follow = Game.GetFormFromFile(0x00000942, "Overture.esp") as Perk
	If follow != None && !player.HasPerk(follow)
		player.AddPerk(follow, False)
	EndIf
EndFunction

; A load: whoever the save says is following goes on doing so, from where they are now.
; A save from before this quest existed has nobody here, and nothing happens.
Event Actor.OnPlayerLoadGame(Actor akSender)
	Self.GivePerk()
	If _who != None
		If Self.Follower().GetActorReference() != _who || _who.IsDead()
			Self.LetGo(KIND_SILENT, "the save's follower is gone")
		Else
			Self.StartTimer(TICK_SECONDS, TICK_TIMER)
		EndIf
	EndIf
EndEvent

Bool Function IsFollowing(Actor akWho)
	Return akWho != None && akWho == _who
EndFunction

; ---- the two ways in ------------------------------------------------------------

; "Follow me", from the perk beside Talk. The player says it, they answer in their own
; voice, and come along only if they would.
Function Ask(Actor akWho)
	If akWho == None
		Return
	EndIf
	Actor player = Game.GetPlayer()
	Topic said = Game.GetFormFromFile(PLAYER_INFO_ID + Utility.RandomInt(0, 4) + TOPIC_OFFSET, "Overture.esp") as Topic
	If said != None
		player.Say(said, None, False, akWho)
		Utility.Wait(1.5)
	EndIf
	If Self.Willing(akWho)
		Self.Speak(akWho, KIND_AGREE)
		Self.Begin(akWho, "asked")
	Else
		Self.Speak(akWho, KIND_DECLINE)
		Debug.Trace("Overture follow: " + akWho.GetFormID() + " declined 'Follow me'", 0)
	EndIf
EndFunction

; From Approach.Finish, after a "not here": they would, just not in front of everyone.
Function BeginAfterNotHere(Actor akWho)
	Self.Begin(akWho, "not here")
EndFunction

; Would they come? Their own rules, not the words: attracted, not faithfully taken,
; not fallen out, and warm enough -- invited back today, a yes before, or half their
; persona's bar in bond (the proposition takes the whole bar; a walk takes less).
Bool Function Willing(Actor akWho)
	Overture:Approach a = Self.Approach()
	If a == None || !a.Enabled() || a.IsCompanionTalk(akWho)
		Return False
	EndIf
	If !a.Attracted(akWho) || a.FaithfullyTaken(akWho)
		Return False
	EndIf
	Float bond = Rapport:Relations.BondBetween(Game.GetPlayer(), akWho)
	If bond <= a.BOND_FALLEN_OUT
		Return False
	EndIf
	If a.ValueOf(akWho, a.SAID_YES_AV_ID) == 1.0 || a.ValueOf(akWho, a.INVITED_UNTIL_AV_ID) > Utility.GetCurrentGameTime()
		Return True
	EndIf
	Int persona = a.PersonaIndex(akWho)
	If persona < 0
		Return False
	EndIf
	Return bond >= a.Threshold(persona) * 0.5
EndFunction

; ---- following ------------------------------------------------------------------

Function Begin(Actor akWho, String asWhy)
	Overture:Approach a = Self.Approach()
	If akWho == None || akWho.IsDead() || a == None || !a.Enabled()
		Return
	EndIf
	If _who != None && _who != akWho
		Self.LetGo(KIND_SILENT, "someone else asked to follow")
	EndIf
	_who = akWho
	_origin = akWho.GetCurrentLocation()
	_world = akWho.GetWorldSpace()
	_startX = akWho.GetPositionX()
	_startY = akWho.GetPositionY()
	_until = Utility.GetCurrentGameTime() + PATIENCE_DAYS
	_strikes = 0
	_arrived = False
	Self.Follower().ForceRefTo(akWho)
	Self.SetFollowing(akWho, 1.0)
	akWho.EvaluatePackage(False)
	Self.StartTimer(TICK_SECONDS, TICK_TIMER)
	Debug.Trace("Overture follow: " + akWho.GetFormID() + " follows (" + asWhy + "), their place " + _origin + ", in the open " + (_origin == None || !Self.InATown(_origin)), 0)
EndFunction

; From Approach.Finish: any conversation with the follower lets go (a yes goes on to
; Rapport's scene, anything else back to their day).
Function Release(Actor akWho)
	If akWho != None && akWho == _who
		Self.LetGo(KIND_SILENT, "a conversation with them ended")
	EndIf
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID == TICK_TIMER
		Self.Tick()
	EndIf
EndEvent

Function Tick()
	Actor who = _who
	If who == None
		Return
	EndIf
	If who.IsDead() || who.IsDisabled() || Self.Follower().GetActorReference() != who
		Self.LetGo(KIND_SILENT, "they are gone")
		Return
	EndIf
	Overture:Approach a = Self.Approach()
	If a != None && a.Talking()
		; A conversation is on: whatever it ends in, Finish lets go.
		Self.StartTimer(TICK_SECONDS, TICK_TIMER)
		Return
	EndIf
	Actor player = Game.GetPlayer()
	If who.IsInCombat() || player.IsInCombat()
		Self.LetGo(KIND_SILENT, "a fight")
		Return
	EndIf
	If Utility.GetCurrentGameTime() > _until
		Self.LetGo(KIND_GIVE_UP, "two game hours and nowhere private")
		Return
	EndIf
	If !Self.Inside(player)
		Self.LetGo(KIND_TOO_FAR, "the edge of their place")
		Return
	EndIf
	Float apart = player.GetDistance(who)
	If apart > RUNOFF_UNITS || player.GetWorldSpace() != who.GetWorldSpace()
		_strikes += 1
		If _strikes >= RUNOFF_TICKS
			Self.LetGo(KIND_GIVE_UP, "the player ran off")
			Return
		EndIf
	Else
		_strikes = 0
	EndIf
	If !_arrived && apart <= ARRIVE_UNITS && a != None && !a.InPublic(who)
		_arrived = True
		Self.OpenTheTalk(who)
		Self.Speak(who, KIND_ARRIVAL)
		Debug.Trace("Overture follow: " + who.GetFormID() + " arrived somewhere private - the talk opens at the proposition", 0)
	EndIf
	Self.StartTimer(TICK_SECONDS, TICK_TIMER)
EndFunction

; Still their place? See the header. Where the player stands, against where they came from.
Bool Function Inside(Actor akPlayer)
	Location here = akPlayer.GetCurrentLocation()
	If _origin != None
		If here == _origin
			Return True
		EndIf
		If here != None
			If _origin.IsChild(here)
				Return True   ; parent.IsChild(child), as vanilla reads it (DLC04PPHChangeLocationScript)
			EndIf
			If Self.OneTown(_origin, here)
				Return True
			EndIf
		EndIf
		If Self.InATown(_origin)
			Return False      ; a town's edge is the edge
		EndIf
	EndIf
	; The open, or a lone place with no town above it: a short way from where they stood.
	If akPlayer.GetWorldSpace() != _world || _world == None
		Return False
	EndIf
	Float dx = akPlayer.GetPositionX() - _startX
	Float dy = akPlayer.GetPositionY() - _startY
	Return dx * dx + dy * dy <= LEASH_OPEN_UNITS * LEASH_OPEN_UNITS
EndFunction

; The same town or settlement: IsSameLocation with the type keyword also counts a shared
; parent of that type, or one inside the other.
Bool Function OneTown(Location akA, Location akB)
	Keyword town = Game.GetFormFromFile(KW_SETTLEMENT_ID, "Fallout4.esm") as Keyword
	Keyword settlement = Game.GetFormFromFile(KW_WORKSHOP_SETTLEMENT_ID, "Fallout4.esm") as Keyword
	Return (town != None && akA.IsSameLocation(akB, town)) || (settlement != None && akA.IsSameLocation(akB, settlement))
EndFunction

; Is this place, or anything above it, a town or settlement?
Bool Function InATown(Location akWhere)
	If akWhere == None
		Return False
	EndIf
	Keyword town = Game.GetFormFromFile(KW_SETTLEMENT_ID, "Fallout4.esm") as Keyword
	Keyword settlement = Game.GetFormFromFile(KW_WORKSHOP_SETTLEMENT_ID, "Fallout4.esm") as Keyword
	If (town != None && akWhere.HasKeyword(town)) || (settlement != None && akWhere.HasKeyword(settlement))
		Return True
	EndIf
	Return (town != None && akWhere.HasCommonParent(akWhere, town)) || (settlement != None && akWhere.HasCommonParent(akWhere, settlement))
EndFunction

; The next talk opens at the proposition (O-30's invitation), and today's stamp comes
; down so the greeting can fire at all.
Function OpenTheTalk(Actor akWho)
	Overture:Approach a = Self.Approach()
	If a == None
		Return
	EndIf
	Float now = Utility.GetCurrentGameTime()
	If a.ValueOf(akWho, a.INVITED_UNTIL_AV_ID) < now + PATIENCE_DAYS
		a.SetTo(akWho, a.INVITED_UNTIL_AV_ID, now + PATIENCE_DAYS)
	EndIf
	a.SetTo(akWho, a.NEXT_DAY_AV_ID, now)
EndFunction

Function LetGo(Int aiKind, String asWhy)
	Actor who = _who
	_who = None
	Self.CancelTimer(TICK_TIMER)
	Self.Follower().Clear()
	If who != None
		Self.SetFollowing(who, 0.0)
		who.EvaluatePackage(False)
		If aiKind >= 0 && !who.IsDead() && Game.GetPlayer().GetDistance(who) <= HEARD_UNITS
			Self.Speak(who, aiKind)
		EndIf
		Debug.Trace("Overture follow: " + who.GetFormID() + " stops following - " + asWhy, 0)
	EndIf
	_origin = None
	_world = None
EndFunction

; ---- lines ----------------------------------------------------------------------

; Their line of this kind, in their persona's voice, one of two at random. No persona
; from Rapport: nothing is said (every line is written for one).
Function Speak(Actor akWho, Int aiKind)
	Overture:Approach a = Self.Approach()
	If akWho == None || a == None || aiKind < 0
		Return
	EndIf
	Int persona = a.PersonaIndex(akWho)
	If persona < 0
		Return
	EndIf
	Topic line = Game.GetFormFromFile(NPC_INFO_ID + aiKind * 8 + persona * 2 + Utility.RandomInt(0, 1) + TOPIC_OFFSET, "Overture.esp") as Topic
	If line != None
		akWho.Say(line, None, False, Game.GetPlayer())
	EndIf
EndFunction

Function SetFollowing(Actor akWho, Float afValue)
	ActorValue av = Game.GetFormFromFile(FOLLOWING_AV_ID, "Overture.esp") as ActorValue
	If av != None
		akWho.SetValue(av, afValue)
	EndIf
EndFunction
