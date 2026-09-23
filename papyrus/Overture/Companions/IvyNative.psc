Scriptname Overture:Companions:IvyNative extends Quest
{D (O-19): IVY'S CONTENT FIRST (C3), BOUND TO THE STORE, HER FADE ANIMATED (O-20).

Ivy already has what Overture would build for her, in her own voice. Overture writes
no line of hers and opens no conversation for her (IvyAdapter.OpensMoments is False).
It does three things:

D.1 HER SCENES COUNT. When one of her Favor: Sex scenes has happened, the player
    and Ivy get what a Rapport scene gives the bond. Rapport has no call for a scene
    that was not its own yet (Rapport:Core.RecordExternalScene, proposed): until it
    exists, AddBondBetween gives the bond half -- 15% of the distance left, the size
    Rapport gives its own (Ledger.cpp kBondPerScene) -- and the scene COUNT is lost.
D.2 HER STATE IS READ for everything else (IvyAdapter).
D.3 HER FADE BECOMES A SCENE (O-20: on by default). As her scene fades to black,
    her own EndSex lifts it, her scene is PAUSED, Rapport plays the scene, and hers
    resumes when Rapport is free -- her lines after it play in order, nothing of hers
    skipped or doubled. Only with Overture's "A yes starts a scene" on: that switch
    stays off until a Rapport scene with the player has been proven end to end,
    which is O-20's "still after a player scene is proven".

MEASURED 2026-09-23 by decompiling her fragments out of "CompanionIvy - Main.ba2"
(version 6.1) -- the first draft guessed phase 3 from a string table, and phase 3
is where the fade LIFTS:
  _IvyCompQuest_Favor_Sex (0059BC), three phases:
      Phase_01_Begin  StartSex()   SetPlayerAIDriven(True), FadeOutGame(True, True,
                                   1.0, 1.0, True): black a second later, for a second
      Phase_03_Begin  EndSex()     fades back in, gives control back
      Phase_03_End    GrantFavor()
  _IvyCompQuest_Favor_Sex_Talk (00627B): her voiced talk through five stages, with a
      dialogue camera and no fade; Phase_12_Begin GrantFavor().
Two separate ways in -- one INFO starts the first, seven the second, and neither
scene starts the other -- so each finished scene is one scene.

OnPhaseBegin counts from 1, as the fragment names do: MEASURED on Overture's own
scene (the 2026-09-23 Papyrus log never shows a "phase 0"). Every phase of both of
her scenes is traced, so a wrong base shows in the first log.}

String Property PLUGIN = "CompanionIvy.esm" AutoReadOnly
Int Property IVY_NPC_ID = 0x000803 AutoReadOnly
Int Property FAVOR_SEX_ID = 0x0059BC AutoReadOnly
Int Property FAVOR_TALK_ID = 0x00627B AutoReadOnly
Int Property FADE_PHASE = 1 AutoReadOnly
Int Property GRANT_PHASE_SEX = 3 AutoReadOnly
Int Property GRANT_PHASE_TALK = 12 AutoReadOnly
; Her FadeOutGame waits a second, then fades for one: lifting it any sooner would
; be undone by her own fade arriving after ours.
Float Property FADE_SETTLES = 2.5 AutoReadOnly
Int Property APPROACH_QUEST_ID = 0x00000800 AutoReadOnly
Int Property REASON_ADDON = 5 AutoReadOnly
Float Property BOND_PER_SCENE = 0.15 AutoReadOnly
Int Property NEEDS_API = 201 AutoReadOnly
Int Property WAIT_TIMER = 7 AutoReadOnly
Float Property WAIT_SECONDS = 5.0 AutoReadOnly

Scene _sex = None
Scene _talk = None
Actor _ivy = None
; This run of a scene reached its favor (so it happened), and whether Rapport
; played it (so Rapport's own RecordScene already counted it).
Bool _sexGranted = False
Bool _talkGranted = False
Bool _handedToRapport = False
Bool _animating = False

Overture:Companions:IvyAdapter Function Adapter()
	Return (Self as Quest) as Overture:Companions:IvyAdapter
EndFunction

Overture:Approach Function Overture()
	Return Game.GetFormFromFile(APPROACH_QUEST_ID, "Overture.esp") as Overture:Approach
EndFunction

; On every load (Moments.Hook): find her and her scenes again, and listen. A
; version of her plugin that moved an id turns the adapter off, and this with it (C4).
Function Hook()
	Overture:Companions:IvyAdapter a = Self.Adapter()
	If a == None || !a.Installed()
		Return
	EndIf
	ActorBase base = Game.GetFormFromFile(IVY_NPC_ID, PLUGIN) as ActorBase
	If base != None
		_ivy = base.GetUniqueActor()
	EndIf
	_sex = Game.GetFormFromFile(FAVOR_SEX_ID, PLUGIN) as Scene
	_talk = Game.GetFormFromFile(FAVOR_TALK_ID, PLUGIN) as Scene
	If _ivy == None || _sex == None || _talk == None
		Debug.Trace("Overture companions: Ivy is installed but her actor or her scenes did not resolve - version change?", 1)
		Return
	EndIf
	Self.RegisterForRemoteEvent(_sex, "OnBegin")
	Self.RegisterForRemoteEvent(_sex, "OnPhaseBegin")
	Self.RegisterForRemoteEvent(_sex, "OnPhaseEnd")
	Self.RegisterForRemoteEvent(_sex, "OnEnd")
	Self.RegisterForRemoteEvent(_talk, "OnBegin")
	Self.RegisterForRemoteEvent(_talk, "OnPhaseBegin")
	Self.RegisterForRemoteEvent(_talk, "OnEnd")
	; A scene held for Rapport when the game was saved: Rapport forgets every scene
	; on a load, so hers goes on now rather than waiting for one that will never end.
	If _animating
		_animating = False
		_sex.Pause(False)
		Debug.Trace("Overture companions: Ivy's scene was held for Rapport when the game was saved - resumed", 1)
	EndIf
EndFunction

Event Scene.OnBegin(Scene akSender)
	If akSender == _sex
		_sexGranted = False
		_handedToRapport = False
	ElseIf akSender == _talk
		_talkGranted = False
	EndIf
	Debug.Trace("Overture companions: Ivy's " + Self.Which(akSender) + " began", 0)
EndEvent

Event Scene.OnPhaseBegin(Scene akSender, Int auiPhaseIndex)
	Debug.Trace("Overture companions: Ivy's " + Self.Which(akSender) + " phase " + auiPhaseIndex + " began", 0)
	If akSender == _talk && auiPhaseIndex == GRANT_PHASE_TALK
		_talkGranted = True
	ElseIf akSender == _sex && auiPhaseIndex == FADE_PHASE && Self.Armed()
		Self.Animate()
	EndIf
EndEvent

Event Scene.OnPhaseEnd(Scene akSender, Int auiPhaseIndex)
	Debug.Trace("Overture companions: Ivy's " + Self.Which(akSender) + " phase " + auiPhaseIndex + " ended", 0)
	If akSender == _sex && auiPhaseIndex == GRANT_PHASE_SEX
		_sexGranted = True
	EndIf
EndEvent

Event Scene.OnEnd(Scene akSender)
	Bool happened = (akSender == _sex && _sexGranted) || (akSender == _talk && _talkGranted)
	; Only a scene that HAPPENED, and only once. Played through Rapport: Rapport's
	; RecordScene already added its share -- adding ours too is R-10's double count
	; through a side door (design review 2026-09-23).
	If !happened || (akSender == _sex && _handedToRapport)
		Debug.Trace("Overture companions: Ivy's " + Self.Which(akSender) + " ended; nothing to record (happened=" + happened + ", Rapport played it=" + _handedToRapport + ")", 0)
		Return
	EndIf
	If Rapport:Core.ApiVersion() < NEEDS_API || _ivy == None
		Return
	EndIf
	Float after = Rapport:Relations.AddBondBetween(Game.GetPlayer(), _ivy, BOND_PER_SCENE, REASON_ADDON)
	Debug.Trace("Overture companions: Ivy's " + Self.Which(akSender) + " ended - the bond is now " + after + " (the scene count waits for Rapport's RecordExternalScene)", 0)
EndEvent

String Function Which(Scene akScene)
	If akScene == _sex
		Return "Favor: Sex"
	ElseIf akScene == _talk
		Return "Favor: Sex talk"
	EndIf
	Return "scene"
EndFunction

; O-20's switch, "A yes starts a scene", and a Rapport that can take it.
Bool Function Armed()
	Overture:Approach approach = Self.Overture()
	If approach == None || !approach.ScenesOn() || _ivy == None
		Return False
	EndIf
	If Rapport:Core.ApiVersion() < NEEDS_API
		Return False
	EndIf
	; The switch's own default is ON (O-20); without Overture's settings, the default.
	If approach.HasSettings() && !MCM.GetModSettingBool("Overture", "bIvyFade:Ivy")
		Return False
	EndIf
	Return True
EndFunction

; Her fade, lifted by her own function; her scene held; ours run; hers resumed.
Function Animate()
	Actor player = Game.GetPlayer()
	If Rapport:Core.Busy() || Rapport:Core.CanRun("athome", player, _ivy) < 0
		Debug.Trace("Overture companions: Ivy's fade stays hers - Rapport cannot take the scene now", 0)
		Return
	EndIf
	ScriptObject hers = Self.Adapter().IvyScript()
	If hers == None
		Return
	EndIf
	; Her FadeOutGame lands a second or two after her phase began; ours must come after.
	Utility.Wait(FADE_SETTLES)
	Var[] noArgs = new Var[0]
	_sex.Pause(True)
	hers.CallFunction("EndSex", noArgs)
	_animating = Rapport:Core.RequestScene(player, _ivy, "athome")
	_handedToRapport = _animating
	If !_animating
		; Rapport said not now: give her scene back exactly as it was.
		hers.CallFunction("StartSex", noArgs)
		_sex.Pause(False)
		Debug.Trace("Overture companions: Rapport refused Ivy's scene - her fade goes on as hers", 1)
		Return
	EndIf
	Debug.Trace("Overture companions: Ivy's fade is Rapport's scene now; hers waits", 0)
	Self.StartTimer(WAIT_SECONDS, WAIT_TIMER)
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID != WAIT_TIMER || !_animating
		Return
	EndIf
	If Rapport:Core.Busy()
		Self.StartTimer(WAIT_SECONDS, WAIT_TIMER)
		Return
	EndIf
	_animating = False
	_sex.Pause(False)
	Debug.Trace("Overture companions: Rapport's scene is over - Ivy's goes on", 0)
EndEvent
