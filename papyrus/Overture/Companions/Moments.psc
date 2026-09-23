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
       their own (C3), they are not an adult human or ghoul (O-25), or their own
       state says no right now (C2)
    1  vouched: the PLAYER may start -- the greeting's second run, which needs the
       player sneaking (O-23)
    2  a MOMENT is open: the companion speaks first

WHAT A MOMENT IS: an EDGE, not a level. It opens when wanting turns true -- their
gates open and their wanting over its bar (Feeders.Gate), or their own system's
arousal -- and stays open two game hours, while they are somewhere private. A
level would make every mid-game companion's first private talk of every day ours,
the one to hand them the loot included (design review 2026-09-23). Once used, it
closes until the next edge; "not here" and "not now" keep it.

THE CLOCK. One timer, every POLL_SECONDS: who is the current companion (the
follower system's Companion alias -- FollowersScript's CompanionChange event exists
only under a mangled name the decompiled base cannot compile against, and a poll
needs nothing it cannot see), the feeders' tick, and the moment. Their combat is
heard through their own OnCombatStateChanged.}

Int Property MOMENT_AV_ID = 0x00000853 AutoReadOnly
Int Property MOMENT_NOT_OURS = 0 AutoReadOnly
Int Property MOMENT_VOUCHED = 1 AutoReadOnly
Int Property MOMENT_OPEN = 2 AutoReadOnly
Int Property POLL_TIMER = 1 AutoReadOnly
Float Property POLL_SECONDS = 20.0 AutoReadOnly
; Two game hours, in days (GetCurrentGameTime's unit). ASSUMED.
Float Property WINDOW_DAYS = 0.083333 AutoReadOnly
Int Property NEEDS_API = 201 AutoReadOnly

Actor _watching = None
Bool _wasWanting = False
Float _openUntil = 0.0
Bool _inCombat = False

Overture:Companions:Registry Function Registry()
	Return (Self as Quest) as Overture:Companions:Registry
EndFunction

Overture:Companions:Feeders Function Feeders()
	Return (Self as Quest) as Overture:Companions:Feeders
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

; On the quest's start and every load: registrations are re-made, the clock restarted.
Function Hook()
	Self.RegisterForRemoteEvent(Game.GetPlayer(), "OnPlayerLoadGame")
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
			; Dismissed: not ours to open any more.
			Self.SetMoment(_watching, MOMENT_NOT_OURS)
			Debug.Trace("Overture companions: " + _watching.GetFormID() + " is no longer the companion", 0)
		EndIf
		_watching = now
		_wasWanting = False
		_openUntil = 0.0
		_inCombat = False
		If now != None
			Self.RegisterForRemoteEvent(now, "OnCombatStateChanged")
			Self.Feeders().Joined(now)
		EndIf
	EndIf
	If now == None
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
	If _inCombat && !akSender.IsDead() && !Game.GetPlayer().IsDead()
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

Function Evaluate(Actor akWho)
	Overture:Companions:Registry reg = Self.Registry()
	Overture:Companions:Adapter a = reg.AdapterFor(akWho)
	If a == None || !a.OpensMoments(akWho) || a.OwnIntimateScene(akWho) != None || !reg.Eligible(akWho) || a.Closed(akWho) || a.Refuses(akWho)
		Self.SetMoment(akWho, MOMENT_NOT_OURS)
		Return
	EndIf
	Float now = Utility.GetCurrentGameTime()
	Overture:Companions:Feeders feeders = Self.Feeders()
	Bool wanting = a.Wants(akWho) || feeders.Gate(akWho) == feeders.GATE_PASS
	If wanting && !_wasWanting
		; The edge: it opens now, for a window.
		_openUntil = now + WINDOW_DAYS
		Debug.Trace("Overture companions: " + akWho.GetFormID() + " wants the player - a moment opens (" + feeders.LastGateNote() + ")", 0)
	EndIf
	_wasWanting = wanting
	If now < _openUntil && Self.Private(akWho)
		Self.SetMoment(akWho, MOMENT_OPEN)
	Else
		Self.SetMoment(akWho, MOMENT_VOUCHED)
	EndIf
EndFunction

; A companion conversation ended (Overture:Approach). A moment is spent by any
; answer but "not here" and "not now" -- those ask for another place or another
; hour, and the window stays for it. "Later." spends it too: the player said so.
Function Ended(Actor akWho, Bool abKeepMoment)
	If akWho == None || abKeepMoment
		Return
	EndIf
	If akWho == _watching
		_openUntil = 0.0
	EndIf
	ActorValue av = Self.OurAV(MOMENT_AV_ID)
	If av != None && akWho.GetValue(av) == MOMENT_OPEN as Float
		akWho.SetValue(av, MOMENT_VOUCHED as Float)
	EndIf
EndFunction
