Scriptname Overture:Companions:Moments extends Quest
{C (O-19): THE ENTRY -- A MOMENT, NOT A MENU. And the companion module's clock.

A companion is never approached the way a stranger is (O-8, O-21). Their own talk
menu is theirs -- MEASURED 2026-09-23: every base-game companion's talk scene is
started by a GREETING in their own COM<Name>Talk quest (priority 30), and so is
Ivy's (70) -- and adding an option to it means overriding their records, the one
thing a compatible module must not do (C1). So Overture's own greeting, at 100,
wins only while its conditions pass (tools/overture_stages.py
companion_greetings), and what they read is written here:

  OvertureCompanionMoment (AVIF 0x853) on the current companion
    0  not ours: no adapter vouches for them (C6), they have an intimate scene of
       their own (C3), they are not an adult human or ghoul (O-25), their own state
       says no right now (C2), or Overture is switched off
    1  vouched: the PLAYER may start (O-23)
    2  a MOMENT is open: the companion speaks first

A MOMENT (reworked by microscope wave 3; the first build opened one on an edge of
wanting and never re-armed it, so a companion asked once per recruitment):
  OWED   when they want it -- their gates open and their wanting over its bar --
         and the last moment's cooldown is over;
  OPEN   at the first poll after that where they are somewhere private, the day's
         stamp is open (the greeting could fire), and the answer would not be a
         refusal by nature or the romantic's "not now" (Approach.CompanionOpenable:
         methodology 2, an invitation that can only be refused is never made).
         The Narrator says so once -- a hint, never a label (O-11) -- and the window
         runs WINDOW_DAYS from then;
  SPENT  by any answer but "not here" and "not now", which ask for another place or
         another hour and so keep it (and stretch it past the hour O-30 reopens
         at); a window that lapses unused is spent too. Either way the next one is
         owed only after fMomentCooldown game days.

THE CLOCK. One timer, every POLL_SECONDS: who is the current companion (the follower
system's Companion alias -- a clock is needed anyway, for the window and the privacy
check, and the greetings re-read the live faction so a lag can open nothing for an
ex-companion), the feeders' tick, and the moment. Their combat is heard through their
own OnCombatStateChanged.}

Int Property MOMENT_AV_ID = 0x00000853 AutoReadOnly
Int Property NEXT_DAY_AV_ID = 0x00000843 AutoReadOnly
Int Property APPROACH_QUEST_ID = 0x00000800 AutoReadOnly
Int Property MOMENT_NOT_OURS = 0 AutoReadOnly
Int Property MOMENT_VOUCHED = 1 AutoReadOnly
Int Property MOMENT_OPEN = 2 AutoReadOnly
Int Property POLL_TIMER = 1 AutoReadOnly
Float Property POLL_SECONDS = 20.0 AutoReadOnly
; Two game hours, in days (GetCurrentGameTime's unit). ASSUMED.
Float Property WINDOW_DAYS = 0.083333 AutoReadOnly
; "Not now" and "not here" reopen an hour later (O-30): the window outlasts that.
Float Property REOPEN_AFTER = 0.041667 AutoReadOnly
Int Property NEEDS_API = 201 AutoReadOnly

Actor _watching = None
Bool _owed = False
Float _openUntil = 0.0
Float _cooldownUntil = 0.0
Bool _inCombat = False

Overture:Companions:Registry Function Registry()
	Return (Self as Quest) as Overture:Companions:Registry
EndFunction

Overture:Companions:Feeders Function Feeders()
	Return (Self as Quest) as Overture:Companions:Feeders
EndFunction

Overture:Approach Function Overture()
	Return Game.GetFormFromFile(APPROACH_QUEST_ID, "Overture.esp") as Overture:Approach
EndFunction

ActorValue Function OurAV(Int aiID)
	Return Game.GetFormFromFile(aiID, "Overture.esp") as ActorValue
EndFunction

Event OnQuestInit()
	Self.Hook()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	Self.Hook()
EndEvent

; On the quest's start and every load: Ivy's ids checked, registrations re-made,
; the clock restarted.
Function Hook()
	Self.RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
	Overture:Companions:IvyAdapter ivyAdapter = (Self as Quest) as Overture:Companions:IvyAdapter
	If ivyAdapter != None
		ivyAdapter.Revalidate()
	EndIf
	If _watching != None
		Self.RegisterForRemoteEvent(_watching, "OnCombatStateChanged")
	EndIf
	; Ivy's own scenes (variant D), whether or not she travels with the player now.
	Overture:Companions:IvyNative ivy = (Self as Quest) as Overture:Companions:IvyNative
	If ivy != None
		ivy.Hook()
	EndIf
	Self.CancelTimer(POLL_TIMER)
	Self.StartTimer(2.0, POLL_TIMER)
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID != POLL_TIMER
		Return
	EndIf
	; The next tick first: nothing below may stop the clock.
	Self.StartTimer(POLL_SECONDS, POLL_TIMER)
	Self.Poll()
EndEvent

Function Poll()
	Actor now = Self.Registry().Current()
	If now != _watching
		If _watching != None
			Self.UnregisterForRemoteEvent(_watching, "OnCombatStateChanged")
			; Dismissed: not ours to open any more, and no wanting kept for them.
			Self.SetMoment(_watching, MOMENT_NOT_OURS)
			Self.Feeders().Left(_watching)
			Debug.Trace("Overture companions: " + _watching.GetFormID() + " is no longer the companion", 0)
		EndIf
		_watching = now
		_owed = False
		_openUntil = 0.0
		_cooldownUntil = 0.0
		_inCombat = False
		If now != None
			Self.RegisterForRemoteEvent(now, "OnCombatStateChanged")
			Self.Feeders().Joined(now)
		EndIf
	EndIf
	If now == None
		Return
	EndIf
	Overture:Approach approach = Self.Overture()
	If approach == None || !approach.Enabled()
		; Overture switched off: nothing opens, and nothing counts.
		Self.SetMoment(now, MOMENT_NOT_OURS)
		Return
	EndIf
	Self.Feeders().Tick(now)
	Self.Evaluate(now)
EndFunction

Event Actor.OnCombatStateChanged(Actor akSender, Actor akTarget, Int aeCombatState)
	If akSender != _watching
		Return
	EndIf
	If aeCombatState != 0
		_inCombat = True
		Return
	EndIf
	If _inCombat && !akSender.IsDead()
		Self.Feeders().SurvivedTogether(akSender)
	EndIf
	_inCombat = False
EndEvent

Function SetMoment(Actor akWho, Int aiValue)
	ActorValue av = Self.OurAV(MOMENT_AV_ID)
	If akWho == None || av == None || akWho.GetValue(av) == aiValue as Float
		Return
	EndIf
	akWho.SetValue(av, aiValue as Float)
EndFunction

; Somewhere nobody is watching, by Rapport's own count against its own tolerance.
; -1 is "no scan yet", NOT "nobody": a moment is not opened on a guess.
Bool Function Private(Actor akWho)
	If Rapport:Core.ApiVersion() < NEEDS_API
		Return False
	EndIf
	Int watching = Rapport:Core.ObserversNear(akWho.GetFormID())
	Return watching >= 0 && watching <= Rapport:Core.ObserverTolerance()
EndFunction

; The greeting's own once-a-day test: its stamp has come round.
Bool Function StampOpen(Actor akWho)
	ActorValue av = Self.OurAV(NEXT_DAY_AV_ID)
	Return av != None && akWho.GetValue(av) <= Utility.GetCurrentGameTime()
EndFunction

Function Evaluate(Actor akWho)
	Overture:Companions:Registry reg = Self.Registry()
	Overture:Companions:Adapter a = reg.AdapterFor(akWho)
	If a == None || !a.OpensMoments(akWho) || a.OwnIntimateScene(akWho) != None || !reg.Eligible(akWho) || a.Closed(akWho) || a.Refuses(akWho)
		Self.SetMoment(akWho, MOMENT_NOT_OURS)
		Return
	EndIf
	Float now = Utility.GetCurrentGameTime()
	Overture:Companions:Feeders feeders = Self.Feeders()
	If _openUntil > 0.0 && now >= _openUntil
		; The window lapsed unused: spent, and the next one waits out the cooldown.
		_openUntil = 0.0
		_cooldownUntil = now + feeders.Tuned("fMomentCooldown:Companions", 2.0)
		Debug.Trace("Overture companions: " + akWho.GetFormID() + "'s moment passed unused", 0)
	EndIf
	If !_owed && _openUntil <= 0.0 && now >= _cooldownUntil && feeders.Gate(akWho) == feeders.GATE_PASS
		_owed = True
		Debug.Trace("Overture companions: " + akWho.GetFormID() + " wants the player - a moment is owed (" + feeders.LastGateNote() + ")", 0)
	EndIf
	Bool private = Self.Private(akWho)
	If _owed && private && Self.StampOpen(akWho)
		Overture:Approach approach = Self.Overture()
		If approach != None && approach.CompanionOpenable(akWho)
			_owed = False
			_openUntil = now + WINDOW_DAYS
			; DRAFT wording, for the owner's review: a hint, never a label (O-11).
			Rapport:Core.NarrateLine(Game.GetPlayer().GetFormID(), akWho.GetFormID(), "{second} keeps glancing your way, like there's something on {their} mind.", "")
			Debug.Trace("Overture companions: " + akWho.GetFormID() + "'s moment is open", 0)
		EndIf
	EndIf
	If _openUntil > now && private
		Self.SetMoment(akWho, MOMENT_OPEN)
	Else
		Self.SetMoment(akWho, MOMENT_VOUCHED)
	EndIf
EndFunction

; A companion conversation ended (Overture:Approach.CompanionEnded). "Not here" and
; "not now" keep the moment, stretched past the hour they reopen at (O-30); every
; other end spends it, and the next is owed only after the cooldown.
Function Ended(Actor akWho, Bool abKeepMoment)
	If akWho == None || akWho != _watching
		Return
	EndIf
	Float now = Utility.GetCurrentGameTime()
	If abKeepMoment
		If _openUntil > 0.0 && _openUntil < now + REOPEN_AFTER + WINDOW_DAYS
			_openUntil = now + REOPEN_AFTER + WINDOW_DAYS
		EndIf
		Return
	EndIf
	_owed = False
	_openUntil = 0.0
	_cooldownUntil = now + Self.Feeders().Tuned("fMomentCooldown:Companions", 2.0)
	ActorValue av = Self.OurAV(MOMENT_AV_ID)
	If av != None && akWho.GetValue(av) == MOMENT_OPEN as Float
		akWho.SetValue(av, MOMENT_VOUCHED as Float)
	EndIf
EndFunction

; The dev verb's: a moment owed and opened now, on the current companion, whatever
; their wanting -- for testing the entry without waiting days of game time.
String Function ForceMoment()
	If _watching == None
		Return "no current companion"
	EndIf
	_owed = True
	_cooldownUntil = 0.0
	Self.Evaluate(_watching)
	ActorValue av = Self.OurAV(MOMENT_AV_ID)
	Return "moment=" + _watching.GetValue(av) + " private=" + Self.Private(_watching) + " stampOpen=" + Self.StampOpen(_watching) + " openUntil=" + _openUntil
EndFunction

Actor Function Watching()
	Return _watching
EndFunction
