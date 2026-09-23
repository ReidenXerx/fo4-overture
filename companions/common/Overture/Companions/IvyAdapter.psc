Scriptname Overture:Companions:IvyAdapter extends Overture:Companions:Adapter
{Ivy (CompanionIvy.esm). She runs the vanilla framework AND a system of her own:
CompanionIvyScript on _IvyCompQuest keeps love, arousal, irritation and anger
in globals, and her intimacy is her own voiced "Favor: Sex" scene ending in a
fade to black (CompanionIvyScript.StartSex: SetPlayerAIDriven + FadeOutGame;
EndSex undoes both). This adapter reads her globals and calls her functions.
It never writes her globals (C5), and it is not a master or a patch (C1): with
CompanionIvy.esm absent, every lookup is None and Claims() is False.

Ids are CompanionIvy.esm-relative, read 2026-09-23 from version 6.1
(tools/dump_record.py; functions from the CompanionIvyScript.psc that ships in
"No XDI Warning"). Another version may move them, which is why every lookup is
checked rather than trusted (C4).

  NPC_ IVYCOMP                            000803  (Rapport pins her vulgar, R-15)
  QUST _IvyCompQuest                      000805  (CompanionIvyScript, _ivyAffinityActionScript, ...)
  GLOB _ivy_Affinity                      00E7C4
  GLOB _ivy_IsAroused                     0011AA
  GLOB _ivy_Arousal_Threshold             0011AB  (7; 5 in love; 8 after a breakup; 12 denied forever)
  GLOB _ivy_Affinity_LoveRelationShipEstablished  017C76
  GLOB _ivy_Affinity_AvailableForRelationship     005994  (1 by default; 0 = closed for good)
  GLOB _ivy_Affinity_IsAngry              00F7C4
  GLOB _ivy_Affinity_IisIrritated         00EFF5
  SCEN _IvyCompQuest_Favor_Sex            0059BC  (fragments call StartSex / EndSex)

SCAFFOLD (2026-09-23).}

String Property PLUGIN = "CompanionIvy.esm" AutoReadOnly
Int Property IVY_NPC_ID = 0x000803 AutoReadOnly
Int Property IVY_QUEST_ID = 0x000805 AutoReadOnly
Int Property AFFINITY_ID = 0x00E7C4 AutoReadOnly
Int Property IS_AROUSED_ID = 0x0011AA AutoReadOnly
Int Property LOVE_ID = 0x017C76 AutoReadOnly
Int Property AVAILABLE_ID = 0x005994 AutoReadOnly
Int Property ANGRY_ID = 0x00F7C4 AutoReadOnly
Int Property IRRITATED_ID = 0x00EFF5 AutoReadOnly
Int Property FAVOR_SEX_SCENE_ID = 0x0059BC AutoReadOnly

; Her affinity messages run p_ivy_affinity_msg_05 .. _200, so 200 is taken as
; the top of her scale. ASSUMED, not measured: nothing read so far says what
; her maximum is.
Float Property AFFINITY_SCALE = 200.0 AutoReadOnly

; The last answer, so the log speaks only when it changes. NOT a cache: script
; variables live in the save, and "checked once" would survive an update of
; Ivy's plugin that moved every id.
Bool _valid = True

Bool Function Installed()
	If !Game.IsPluginInstalled(PLUGIN)
		Return False
	EndIf
	; C4 PER FIELD, not per plugin: a moved or missing global would otherwise read
	; as "not angry, not irritated, not closed" -- a permissive guess, the opposite
	; of what C4 promises (design review 2026-09-23). Every id, every time: ten
	; lookups, and this runs at most every few seconds.
	Bool valid = Self.Validate()
	If valid != _valid
		_valid = valid
		If !valid
			Debug.Trace("Overture companions: CompanionIvy.esm is installed but its ids do not match 6.1 - the Ivy adapter is OFF", 1)
		EndIf
	EndIf
	Return valid
EndFunction

Bool Function Validate()
	If (Game.GetFormFromFile(IVY_NPC_ID, PLUGIN) as ActorBase) == None
		Return False
	ElseIf (Game.GetFormFromFile(IVY_QUEST_ID, PLUGIN) as Quest) == None
		Return False
	ElseIf (Game.GetFormFromFile(FAVOR_SEX_SCENE_ID, PLUGIN) as Scene) == None
		Return False
	EndIf
	Int[] globals = new Int[7]
	globals[0] = AFFINITY_ID
	globals[1] = IS_AROUSED_ID
	globals[2] = LOVE_ID
	globals[3] = AVAILABLE_ID
	globals[4] = ANGRY_ID
	globals[5] = IRRITATED_ID
	globals[6] = 0x0011AB   ; _ivy_Arousal_Threshold: read nowhere yet, checked so a move is seen
	Int i = 0
	While i < globals.Length
		If (Game.GetFormFromFile(globals[i], PLUGIN) as GlobalVariable) == None
			Return False
		EndIf
		i += 1
	EndWhile
	Return True
EndFunction

; Her own Favor: Sex is the moment; Overture opens nothing of its own for her (C3).
Bool Function OpensMoments(Actor akWho)
	Return False
EndFunction

GlobalVariable Function IvyGlobal(Int aiID)
	If !Self.Installed()
		Return None
	EndIf
	Return Game.GetFormFromFile(aiID, PLUGIN) as GlobalVariable
EndFunction


; Her own script, for calling her own functions. None when absent or renamed.
ScriptObject Function IvyScript()
	If !Self.Installed()
		Return None
	EndIf
	Quest q = Game.GetFormFromFile(IVY_QUEST_ID, PLUGIN) as Quest
	If q == None
		Return None
	EndIf
	Return q.CastAs("CompanionIvyScript")
EndFunction

; True when the global exists AND is set. A missing global reads False.
Bool Function Flag(Int aiID)
	GlobalVariable g = Self.IvyGlobal(aiID)
	Return g != None && g.GetValue() != 0.0
EndFunction

Bool Function Claims(Actor akWho)
	If akWho == None || !Self.Installed()
		Return False
	EndIf
	ActorBase ivy = Game.GetFormFromFile(IVY_NPC_ID, PLUGIN) as ActorBase
	Return ivy != None && akWho.GetActorBase() == ivy
EndFunction

Bool Function KnowsAffinity(Actor akWho)
	Return Self.Claims(akWho) && Self.IvyGlobal(AFFINITY_ID) != None
EndFunction

Float Function Affinity(Actor akWho)
	GlobalVariable g = Self.IvyGlobal(AFFINITY_ID)
	If g == None
		Return 0.0
	EndIf
	Float a = g.GetValue() / AFFINITY_SCALE
	If a > 1.0
		Return 1.0
	ElseIf a < -1.0
		Return -1.0
	EndIf
	Return a
EndFunction

Bool Function IsRomanced(Actor akWho)
	Return Self.Flag(LOVE_ID)
EndFunction

; Angry or irritated, by her own reckoning, is a no -- whatever our numbers say.
; A global that stopped resolving is a no too.
Bool Function Refuses(Actor akWho)
	If Parent.Refuses(akWho)
		Return True
	EndIf
	If Self.IvyGlobal(ANGRY_ID) == None || Self.IvyGlobal(IRRITATED_ID) == None
		Return True
	EndIf
	Return Self.Flag(ANGRY_ID) || Self.Flag(IRRITATED_ID)
EndFunction

; Her story can close the door for good: DenyRelationShipForEver sets this to 0.
; A MISSING global is not a closed door, so it only counts when it resolved.
Bool Function Closed(Actor akWho)
	GlobalVariable g = Self.IvyGlobal(AVAILABLE_ID)
	Return g != None && g.GetValue() == 0.0
EndFunction

Bool Function Wants(Actor akWho)
	Return Self.Flag(IS_AROUSED_ID)
EndFunction

Scene Function OwnIntimateScene(Actor akWho)
	If !Self.Installed()
		Return None
	EndIf
	Return Game.GetFormFromFile(FAVOR_SEX_SCENE_ID, PLUGIN) as Scene
EndFunction

; Her own reactions, through her own functions: FlirtEvent counts to five and
; then lowers her irritation; DenyEvent counts to four unanswered denials and
; then disappoints her. Both live on CompanionIvyScript and take no arguments.
Function Notify(Actor akWho, String asWhat)
	ScriptObject ivy = Self.IvyScript()
	If ivy == None
		Return
	EndIf
	; "none" is the None keyword to a case-insensitive compiler.
	Var[] noArgs = new Var[0]
	If asWhat == "flirt"
		ivy.CallFunctionNoWait("FlirtEvent", noArgs)
	ElseIf asWhat == "deny"
		ivy.CallFunctionNoWait("DenyEvent", noArgs)
	EndIf
	; "scene": her counters are for her own scenes; ours tell her nothing.
EndFunction

String Function Name()
	Return "ivy"
EndFunction
