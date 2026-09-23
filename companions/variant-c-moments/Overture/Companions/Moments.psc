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

WHAT A MOMENT IS (ASSUMED, the owner's poll): private (Rapport's own crowd
count), not in combat or a scene, their adapter neither refuses nor has closed
the door -- and one of
    their own system wants it (Ivy's arousal),
    the intimacy track's DESIRE is over the bar (variant B),
    or their affinity has reached Admiration (variant A, or B's TRUST input).

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
Float Property OPENS_AT_AFFINITY = 0.50 AutoReadOnly

Actor _watching = None

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
	Bool open = a != None && !a.Refuses(akWho) && !a.Closed(akWho) && Self.Private(akWho)
	If open
		open = a.Wants(akWho) || Self.TrackWants(akWho) || a.Affinity(akWho) >= OPENS_AT_AFFINITY
	EndIf
	Self.SetMoment(akWho, open)
EndFunction

; Variant B's opinion, when it is installed alongside. Resolved by name so this
; variant compiles and runs without it.
Bool Function TrackWants(Actor akWho)
	ScriptObject track = (Self as Quest).CastAs("Overture:Companions:Track")
	If track == None
		Return False
	EndIf
	Var[] args = new Var[1]
	args[0] = akWho
	Return track.CallFunction("WouldSayYes", args) as Bool
EndFunction
