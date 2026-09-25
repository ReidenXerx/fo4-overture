Scriptname Overture:Companions:IvyNative extends Quest
{D (O-19): IVY'S CONTENT FIRST (C3), BOUND TO THE STORE, HER FADE ANIMATED (O-20).

Ivy already has what Overture would build for her, in her own voice. Overture writes
no line of hers and opens no conversation for her (IvyAdapter.OpensMoments is False).

D.1 HER SCENE COUNTS. When her Favor: Sex has happened, the player and Ivy get what a
    Rapport scene gives the bond. Rapport has no call for a scene that was not its own
    yet (RecordExternalScene, proposed): until it exists, AddBondBetween gives the
    bond half -- 15% of the distance left, Rapport's own size (Ledger.cpp
    kBondPerScene) -- and the scene COUNT is lost.
D.2 HER STATE IS READ for everything else (IvyAdapter).
D.3 HER FADE BECOMES A SCENE (O-20: on by default, "bIvyFade:Ivy"), only with
    Overture's "A yes starts a scene" on -- that switch stays off until a Rapport
    scene with the player has been proven, which is O-20's "after proven".

HER SCENE, MEASURED 2026-09-23 (her fragments decompiled from "CompanionIvy -
Main.ba2", her records read from CompanionIvy.esm 6.1):
  _IvyCompQuest_Favor_Sex (0059BC), three phases, one way in (INFO 010059B8 "Let's
  make love."), no start conditions, no loops:
    phase 1  StartSex(): SetPlayerAIDriven(True), FadeOutGame(... 1.0, 1.0, stay) --
             black a second later, for a second; her line "Come to me.." (1.4 s)
    phase 2  THE SEX, in the dark: "(sex sounds)" and a 12.5 s timer action; the
             phase completes when that timer has
    phase 3  EndSex(): fades back in, a 0.8 s wait, control back; her closing line;
             GrantFavor() as it ends
  OnPhaseBegin counts from 1, as her fragment names do (Overture's own scene logged
  its phase trails 1-2-5 and 1-2-3-4-5: docs/dialogue-route.md).
  Her other favor scene, _IvyCompQuest_Favor_Sex_Talk (00627B), has NO way in: the
  INFOs that name it are its own lines jumping within it, and nothing in her plugin,
  her scripts or 1,046 installed plugins starts it (microscope wave 3 corrected the
  first reading). It is not counted.

D.3, AS REWORKED BY WAVE 3:
  - at phase 2's BEGIN (the sex, not a clock from phase 1): hold Rapport's slot,
    wait for her fade to have landed, then check again -- still phase 2, nobody in
    combat, her scene still playing -- before touching anything;
  - PAUSE her scene, lift her fade with her own EndSex, ask Rapport for the scene;
  - resume when OUR request is no longer in flight (Rapport:Core.InFlightRequest --
    Busy() is any pair's scene), or after a cap: Rapport's own record says whether
    it happened (PairSceneCount rose), not the request's acceptance;
  - put her fade back with her own StartSex BEFORE unpausing, so the rest of her
    scene plays as she wrote it: her beat in the dark, then her phase 3 fades in.
    Nothing of hers skipped, nothing played in daylight that she wrote for black.
  A scene Rapport never recorded (a refusal after acceptance, its watchdog, a load)
  is counted by D.1 instead: exactly one of the two counts every scene.}

Int Property FADE_PHASE = 1 AutoReadOnly
Int Property SEX_PHASE = 2 AutoReadOnly
Int Property LIFT_PHASE = 3 AutoReadOnly
; Her FadeOutGame waits a second, then fades for one, from her phase 1: by the end of
; this wait at phase 2 it has long landed.
Float Property FADE_SETTLES = 2.5 AutoReadOnly
Int Property APPROACH_QUEST_ID = 0x00000800 AutoReadOnly
Int Property REASON_ADDON = 5 AutoReadOnly
Float Property BOND_PER_SCENE = 0.15 AutoReadOnly
Int Property NEEDS_API = 201 AutoReadOnly
Int Property WAIT_TIMER = 7 AutoReadOnly
Float Property WAIT_SECONDS = 5.0 AutoReadOnly
; Past Rapport's own watchdog (600 + 180 s): if the request is still "in flight"
; by then, something is stuck, and her scene must not wait for it.
Float Property CAP_SECONDS = 900.0 AutoReadOnly
Float Property HOLD_SECONDS = 20.0 AutoReadOnly

Scene _sex = None
Actor _ivy = None
; This run of her scene: the phase it is in (set FIRST in each phase event, before
; anything can yield), whether Rapport played it, and the D.3 bookkeeping.
Int _sexPhase = 0
Bool _handedToRapport = False
Bool _animating = False
Int _requestId = 0
Int _pairBefore = 0
Float _animatingSince = 0.0

Overture:Companions:IvyAdapter Function Adapter()
	Return (Self as Quest) as Overture:Companions:IvyAdapter
EndFunction

Overture:Approach Function Overture()
	Return Game.GetFormFromFile(APPROACH_QUEST_ID, "Overture.esp") as Overture:Approach
EndFunction

; On every load (Moments.Hook, after IvyAdapter.Revalidate): a scene held for Rapport
; when the game was saved is given back FIRST -- Rapport forgets every request on a
; load -- then her scene is found again and listened to. A version of her plugin
; that moved an id turns this off (C4).
Function Hook()
	If _animating
		Debug.Trace("Overture companions: Ivy's scene was held for Rapport when the game was saved - given back", 1)
		Self.Resume()
	EndIf
	Overture:Companions:IvyAdapter a = Self.Adapter()
	If a == None || !a.Installed()
		Self.UnregisterForAllRemoteEvents()
		_sex = None
		_ivy = None
		Return
	EndIf
	_ivy = a.Ivy()
	_sex = a.FavorSex()
	If _ivy == None || _sex == None
		Debug.Trace("Overture companions: Ivy is installed but her actor or her scene did not resolve - version change?", 1)
		Self.UnregisterForAllRemoteEvents()
		Return
	EndIf
	Self.RegisterForRemoteEvent(_sex, "OnBegin")
	Self.RegisterForRemoteEvent(_sex, "OnPhaseBegin")
	Self.RegisterForRemoteEvent(_sex, "OnEnd")
EndFunction

; Overture on, and her adapter still valid: C4 on every event, not only at the hook.
Bool Function Live()
	Overture:Approach approach = Self.Overture()
	Overture:Companions:IvyAdapter a = Self.Adapter()
	Return approach != None && approach.Enabled() && a != None && a.Installed()
EndFunction

Event Scene.OnBegin(Scene akSender)
	_sexPhase = 0
	_handedToRapport = False
	Debug.Trace("Overture companions: Ivy's Favor: Sex began", 0)
EndEvent

Event Scene.OnPhaseBegin(Scene akSender, Int auiPhaseIndex)
	; FIRST, before anything can yield: OnEnd reads it.
	_sexPhase = auiPhaseIndex
	Debug.Trace("Overture companions: Ivy's Favor: Sex phase " + auiPhaseIndex + " began", 0)
	If auiPhaseIndex == SEX_PHASE && Self.Armed()
		Self.Animate()
	EndIf
EndEvent

Event Scene.OnEnd(Scene akSender)
	Int reached = _sexPhase
	_sexPhase = 0
	; It HAPPENED if it reached the phase where her fade lifts: the sex (phase 2) ran
	; to its timer. Played through Rapport and recorded there: Rapport's RecordScene
	; already added its share -- adding ours too is R-10's double count.
	If reached < LIFT_PHASE || _handedToRapport
		Debug.Trace("Overture companions: Ivy's Favor: Sex ended; nothing to record (reached phase " + reached + ", Rapport played it=" + _handedToRapport + ")", 0)
		Return
	EndIf
	If !Self.Live() || Rapport:Core.ApiVersion() < NEEDS_API || _ivy == None
		Return
	EndIf
	Float after = Rapport:Relations.AddBondBetween(Game.GetPlayer(), _ivy, BOND_PER_SCENE, REASON_ADDON)
	Debug.Trace("Overture companions: Ivy's Favor: Sex ended - the bond is now " + after + " (the scene count waits for Rapport's RecordExternalScene)", 0)
EndEvent

; O-20's switch, "A yes starts a scene", Overture on, and a Rapport that can take it.
Bool Function Armed()
	If !Self.Live() || _ivy == None || Rapport:Core.ApiVersion() < NEEDS_API
		Return False
	EndIf
	Overture:Approach approach = Self.Overture()
	If !approach.ScenesOn()
		Return False
	EndIf
	; The switch's own default is ON (O-20); without Overture's settings, the default.
	If !Rapport:Core.ModSettingBool("Overture", "bIvyFade:Ivy", True)
		Return False
	EndIf
	Return True
EndFunction

; Her fade playing as hers right now (not handed to Rapport): Overture's own yes must
; not start another scene with the player while she is driving them in the dark --
; her EndSex would hand control back in the middle of it (microscope wave 3).
Bool Function HerFadeRunning()
	Return _sex != None && !_animating && _sexPhase >= FADE_PHASE && _sexPhase < LIFT_PHASE && _sex.IsPlaying()
EndFunction

String Function Scenario()
	Overture:Approach approach = Self.Overture()
	Return approach.ScenarioFor(_ivy, approach.PersonaIndex(_ivy))
EndFunction

; Her fade, lifted by her own function; her scene held; ours run; hers resumed.
Function Animate()
	Actor player = Game.GetPlayer()
	String scenario = Self.Scenario()
	If Rapport:Core.Busy() || Rapport:Core.CanRun(scenario, player, _ivy) < 0
		Debug.Trace("Overture companions: Ivy's fade stays hers - Rapport cannot take the scene now", 0)
		Return
	EndIf
	; Held through the wait, so nothing else takes the slot meanwhile.
	Rapport:Core.ReservePlayerScene(_ivy, HOLD_SECONDS)
	Utility.Wait(FADE_SETTLES)
	If _sexPhase != SEX_PHASE || !_sex.IsPlaying() || player.IsInCombat() || _ivy.IsInCombat() || Rapport:Core.Busy()
		Rapport:Core.ReservePlayerScene(_ivy, 0.0)
		Debug.Trace("Overture companions: Ivy's fade stays hers - the moment changed during the wait", 0)
		Return
	EndIf
	ScriptObject hers = Self.Adapter().IvyScript()
	If hers == None
		Rapport:Core.ReservePlayerScene(_ivy, 0.0)
		Return
	EndIf
	Var[] noArgs = new Var[0]
	_sex.Pause(True)
	; CallFunction blocks until hers returns, her own 0.8 s wait included: her
	; SetPlayerAIDriven(False) lands before Rapport's request.
	hers.CallFunction("EndSex", noArgs)
	_pairBefore = Rapport:Core.PairSceneCount(player.GetFormID(), _ivy.GetFormID())
	_animating = Rapport:Core.RequestScene(player, _ivy, scenario)
	If !_animating
		; Rapport said not now: her fade back, and her scene on as it was.
		hers.CallFunction("StartSex", noArgs)
		_sex.Pause(False)
		Rapport:Core.ReservePlayerScene(_ivy, 0.0)
		Debug.Trace("Overture companions: Rapport refused Ivy's scene - her fade goes on as hers", 1)
		Return
	EndIf
	_requestId = Rapport:Core.InFlightRequest()
	_animatingSince = Utility.GetCurrentRealTime()
	Debug.Trace("Overture companions: Ivy's fade is Rapport's scene now (request " + _requestId + "); hers waits", 0)
	Self.StartTimer(WAIT_SECONDS, WAIT_TIMER)
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID != WAIT_TIMER || !_animating
		Return
	EndIf
	Bool ours = _requestId != 0 && Rapport:Core.InFlightRequest() == _requestId
	Bool expired = Utility.GetCurrentRealTime() - _animatingSince > CAP_SECONDS
	If ours && !expired
		Self.StartTimer(WAIT_SECONDS, WAIT_TIMER)
		Return
	EndIf
	Self.Resume()
EndEvent

; Our request is over (or forgotten, or stuck): did Rapport record it? Then her fade
; goes back on and her scene resumes as she wrote it.
Function Resume()
	_animating = False
	If _sex == None || _ivy == None
		Return
	EndIf
	Int p = Game.GetPlayer().GetFormID()
	_handedToRapport = Rapport:Core.PairSceneCount(p, _ivy.GetFormID()) > _pairBefore
	ScriptObject hers = Self.Adapter().IvyScript()
	If hers != None
		Var[] noArgs = new Var[0]
		hers.CallFunction("StartSex", noArgs)
	EndIf
	_sex.Pause(False)
	If _handedToRapport
		Debug.Trace("Overture companions: Rapport's scene with Ivy is recorded - hers goes on, in her dark", 0)
	Else
		Debug.Trace("Overture companions: Rapport never recorded Ivy's scene - hers goes on, and counts as hers", 1)
	EndIf
EndFunction
