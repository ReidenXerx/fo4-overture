Scriptname Overture:Companions:IvyNative extends Quest
{VARIANT D -- HER CONTENT FIRST (C3), BOUND TO THE STORE, OPTIONALLY ANIMATED.

Ivy already has what Overture would build for her: her own voiced sex talk
(_ivy_sextalk_script's stages) and her own "Favor: Sex" scene, which ends in a
fade to black -- CompanionIvyScript.StartSex() is SetPlayerAIDriven(True) plus
FadeOutGame, EndSex() undoes both. Her writing, her voice, her bookkeeping.
Replacing any of it with ours would be worse on every count.

So for Ivy, Overture does three things and writes no line of its own:

1. BINDS HER SCENES TO THE STORE. When her Favor: Sex scene ends, the
   player<->Ivy pair gets what a Rapport scene would have given it. Rapport has
   no call for "a scene that was not ours" yet -- proposed as
   Rapport:Core.RecordExternalScene(a, b), which any fade-to-black companion mod
   would want (O-1). Until it exists, AddBondBetween stands in for the bond half
   and the scene COUNT is lost.

2. READS HER STATE for everything else in the module (IvyAdapter): love,
   arousal, anger, irritation, the closed door.

3. OPTIONALLY ANIMATES HER FADE (an MCM switch, OFF by default -- the owner's
   poll). On the phase where her scene fades out, call her own EndSex() to lift
   it, PAUSE her scene, run the scene through Rapport, and unpause when Rapport
   is free again -- so her post-scene talk still plays, in order, with nothing
   of hers skipped or duplicated. Her fragments call StartSex at a phase begin
   and EndSex at that phase's end; her EndSex arriving after ours only fades in
   what is already in and hands back control nobody holds.

WHICH PHASE. The string table of SF__IvyCompQuest_Favor_Sex_010059BC.pex names
Fragment_Phase_01_Begin, _03_Begin, _03_End and the calls GrantFavor, StartSex,
EndSex, in that order -- so phase 3 is PROBABLY the fade. A string table is not
code order. PROBE MODE below logs every phase with the fade state before
anything acts on a phase number; nothing is animated until the probe has named
the phase in a real game.

SCAFFOLD (2026-09-23): not in the shipping plugin.}

Int Property FADE_PHASE = 3 AutoReadOnly   ; ASSUMED until the probe names it
Bool Property PROBE_ONLY = True AutoReadOnly
Int Property REASON_ADDON = 5 AutoReadOnly
Int Property WAIT_TIMER = 7 AutoReadOnly

Scene _hers = None
Actor _ivy = None
Bool _animating = False

Overture:Companions:IvyAdapter Function Adapter()
	Return (Self as Quest).CastAs("Overture:Companions:IvyAdapter") as Overture:Companions:IvyAdapter
EndFunction

; On every load: find her scene again and listen to it. Registrations do not
; survive a plugin that moved, and re-registering costs nothing.
Function Hook(Actor akIvy)
	Overture:Companions:IvyAdapter a = Self.Adapter()
	If a == None || !a.Claims(akIvy)
		Return
	EndIf
	_ivy = akIvy
	_hers = a.OwnIntimateScene(akIvy)
	If _hers == None
		Debug.Trace("Overture companions: Ivy is installed but her Favor: Sex scene did not resolve - version change?", 1)
		Return
	EndIf
	Self.RegisterForRemoteEvent(_hers, "OnBegin")
	Self.RegisterForRemoteEvent(_hers, "OnPhaseBegin")
	Self.RegisterForRemoteEvent(_hers, "OnPhaseEnd")
	Self.RegisterForRemoteEvent(_hers, "OnEnd")
EndFunction

Event Scene.OnBegin(Scene akSender)
	Debug.Trace("Overture companions: Ivy's Favor: Sex began", 0)
EndEvent

Event Scene.OnPhaseBegin(Scene akSender, Int auiPhaseIndex)
	Debug.Trace("Overture companions: Ivy's Favor: Sex phase " + auiPhaseIndex + " began", 0)
	If PROBE_ONLY || auiPhaseIndex != FADE_PHASE || _ivy == None
		Return
	EndIf
	Self.Animate()
EndEvent

Event Scene.OnPhaseEnd(Scene akSender, Int auiPhaseIndex)
	Debug.Trace("Overture companions: Ivy's Favor: Sex phase " + auiPhaseIndex + " ended", 0)
EndEvent

Event Scene.OnEnd(Scene akSender)
	If _ivy == None
		Return
	EndIf
	; The bond half of a scene: 15% of the distance left, the same size Rapport
	; gives its own (Ledger.cpp kBondPerScene). Not the count -- see 1. above.
	Rapport:Relations.AddBondBetween(Game.GetPlayer(), _ivy, 0.15, REASON_ADDON)
	Debug.Trace("Overture companions: Ivy's Favor: Sex ended; bond recorded", 0)
EndEvent

; Her fade, lifted by her own function; her scene held; ours run; hers resumed.
Function Animate()
	If !Rapport:Core.Busy() && Rapport:Core.CanRun("athome", Game.GetPlayer(), _ivy) >= 0
		Var[] noArgs = new Var[0]
		ScriptObject ivyScript = Self.Adapter().IvyScript()
		If ivyScript == None
			Return
		EndIf
		ivyScript.CallFunction("EndSex", noArgs)
		_hers.Pause(True)
		_animating = Rapport:Core.RequestScene(Game.GetPlayer(), _ivy, "athome")
		If !_animating
			; Rapport said not now: give her scene back exactly as it was.
			_hers.Pause(False)
			ivyScript.CallFunction("StartSex", noArgs)
			Return
		EndIf
		Self.StartTimer(5.0, WAIT_TIMER)
	EndIf
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID != WAIT_TIMER || !_animating
		Return
	EndIf
	If Rapport:Core.Busy()
		Self.StartTimer(5.0, WAIT_TIMER)
		Return
	EndIf
	_animating = False
	_hers.Pause(False)
EndEvent
