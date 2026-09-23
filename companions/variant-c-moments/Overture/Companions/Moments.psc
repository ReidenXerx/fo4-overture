Scriptname Overture:Companions:Moments extends Quest
{VARIANT C -- THE ENTRY: A MOMENT, NOT A MENU.

A companion is never approached the way a stranger is (O-8 excludes the
current companion on purpose). Their own talk menu is theirs -- vanilla's
COM<Name>Talk scene, Ivy's 460 topics -- and adding an option to it means
overriding their records, which is the one thing a compatible module must not
do (C1). So the companion conversation opens at a MOMENT instead, through the
exact mechanism O-7 verified for strangers:

  a second greeting in Overture's dialogue quest, conditioned on the speaker:
      GetPlayerTeammate == 1
      GetValue OvertureCompanionMoment == 1        <- this script sets it
      GetValue OvertureNextApproachDay <= GameDaysPassed  (once a day, O-8's AV)
  with ALFA (Forced Alias) and TSCE -> the companion scene.

Overture's quest runs at priority 100 (DNAM 0x64); Ivy's _IvyCompQuest at 70
(0x46) and vanilla's COMPiperTalk at 30 (0x1E). So while a moment is open,
talking to them opens ours FIRST and their own menu follows -- O-8's order,
"approach, then theirs", which the hand-back already does. While no moment is
open, the greeting's conditions fail and their dialogue is untouched: the
module is invisible until it has something to say.

WHAT A MOMENT IS (ASSUMED, the owner's poll). An EDGE, not a level: the moment
opens when "wanting" turns true -- the intimacy track's DESIRE crossing its bar,
their own system's arousal rising -- and stays open for a window (two game
hours), then closes. A level ("affinity has reached Admiration") would make
every mid-game companion's first private talk of every day ours, including the
one to hand them the loot (design review 2026-09-23). And only for a companion
whose adapter vouches for it (OpensMoments) and who has no intimate scene of
their own -- Ivy's is hers, so Overture opens nothing for her (C3). The
companion scene's first wheel must carry a costless "Later." that hands back
without stamping the day (to build with the scene).

A moment can also be spoken: when one opens and the companion is close, they
say one line of their own ("Hey. Got a minute? Not for the road.") -- a hint,
never a forcegreet. New lines per persona; for a companion with their own voice
type, subtitles unless the owner picks a voice (V-9).

SCAFFOLD (2026-09-23): not in the shipping plugin. Needs, in Overture.esp:
AVIF OvertureCompanionMoment (reserved 0x853), the companion greeting and
scene (0x857-0x858, 0x859), and this script on the companions quest (0x855).}

Int Property MOMENT_AV_ID = 0x00000853 AutoReadOnly
Int Property NEXT_DAY_AV_ID = 0x00000843 AutoReadOnly
Int Property POLL_TIMER = 1 AutoReadOnly
Float Property POLL_SECONDS = 20.0 AutoReadOnly
; Two game hours, in days (GetCurrentGameTime's unit). ASSUMED.
Float Property WINDOW_DAYS = 0.0833 AutoReadOnly

Actor _watching = None
Bool _wasWanting = False
Float _openUntil = 0.0

Overture:Companions:Registry Function Registry()
	Return (Self as Quest) as Overture:Companions:Registry
EndFunction

ActorValue Function OurAV(Int aiID)
	Return Game.GetFormFromFile(aiID, "Overture.esp") as ActorValue
EndFunction

; Start watching a companion: on recruitment (FollowersScript's CompanionChange
; custom event) and on every load for whoever is current.
Function Watch(Actor akWho)
	_watching = akWho
	Self.StartTimer(POLL_SECONDS, POLL_TIMER)
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID != POLL_TIMER || _watching == None
		Return
	EndIf
	Self.Evaluate(_watching)
	If Self.Registry().IsCurrentCompanion(_watching)
		Self.StartTimer(POLL_SECONDS, POLL_TIMER)
	Else
		; Dismissed: the moment closes with them.
		Self.SetMoment(_watching, False)
		_watching = None
	EndIf
EndEvent

Function SetMoment(Actor akWho, Bool abOpen)
	ActorValue av = Self.OurAV(MOMENT_AV_ID)
	If akWho == None || av == None
		Return
	EndIf
	If abOpen
		akWho.SetValue(av, 1.0)
	Else
		akWho.SetValue(av, 0.0)
	EndIf
EndFunction

Bool Function Private(Actor akWho)
	Int watching = Rapport:Core.ObserversNear(akWho.GetFormID())
	; -1 is "no scan yet", NOT "nobody": a moment is not opened on a guess.
	Return watching >= 0 && watching <= Rapport:Core.ObserverTolerance()
EndFunction

Function Evaluate(Actor akWho)
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	If a == None || !a.OpensMoments(akWho) || a.OwnIntimateScene(akWho) != None
		; Not ours to open (C6), or theirs to play (C3).
		Self.SetMoment(akWho, False)
		Return
	EndIf
	Float now = Utility.GetCurrentGameTime()
	Bool wanting = a.Wants(akWho) || Self.TrackWants(akWho)
	If wanting && !_wasWanting
		; The edge: it opens now, for a window.
		_openUntil = now + WINDOW_DAYS
	EndIf
	_wasWanting = wanting
	Bool open = now < _openUntil && !a.Refuses(akWho) && !a.Closed(akWho) && Self.Private(akWho)
	Self.SetMoment(akWho, open)
EndFunction

; The player said "Later." or the moment was used: it closes until the next edge.
Function Close(Actor akWho)
	_openUntil = 0.0
	Self.SetMoment(akWho, False)
EndFunction

; The relationship variant's opinion, whichever is installed alongside: B-lite
; (the recommendation) or B. Resolved by name so this variant compiles and runs
; without either.
Bool Function TrackWants(Actor akWho)
	ScriptObject track = (Self as Quest).CastAs("Overture:Companions:Feeders")
	If track == None
		track = (Self as Quest).CastAs("Overture:Companions:Track")
	EndIf
	If track == None
		Return False
	EndIf
	Var[] args = new Var[1]
	args[0] = akWho
	Return track.CallFunction("WouldSayYes", args) as Bool
EndFunction
