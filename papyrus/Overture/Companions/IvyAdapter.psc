Scriptname Overture:Companions:IvyAdapter extends Overture:Companions:Adapter
{Ivy (CompanionIvy.esm). She runs the vanilla framework AND a system of her own:
CompanionIvyScript on _IvyCompQuest keeps love, arousal, irritation and anger in
globals, and her intimacy is her own voiced "Favor: Sex" scene ending in a fade to
black (IvyNative has it, measured). This adapter reads her globals. It never
writes them (C5), never moves her own state (O-24), and is not a master or a
patch (C1): with CompanionIvy.esm absent, every lookup is None and Claims() is False.

Ids are CompanionIvy.esm-relative, read 2026-09-23 from version 6.1
(tools/dump_record.py; functions decompiled from her archive). Another version may
move them, which is why every one is checked (C4).

  NPC_ IVYCOMP                            000803  (Rapport pins her vulgar, R-15)
  QUST _IvyCompQuest                      000805  (CompanionIvyScript, CompanionIvyProfanity, ...)
  GLOB _ivy_Affinity                      00E7C4
  GLOB _ivy_IsAroused                     0011AA
  GLOB _ivy_Arousal_Threshold             0011AB  (7; 5 in love; 8 after a breakup; 12 denied forever)
  GLOB _ivy_Affinity_LoveRelationShipEstablished  017C76
  GLOB _ivy_Affinity_AvailableForRelationship     005994  (1 by default; 0 = closed for good)
  GLOB _ivy_Affinity_IsAngry              00F7C4
  GLOB _ivy_Affinity_IisIrritated         00EFF5
  SCEN _IvyCompQuest_Favor_Sex            0059BC  (her fragments call StartSex / EndSex)

VALIDATED ONCE PER LOAD (Revalidate, from Moments.Hook), not on every question: a
load is when a plugin can have changed, and ten lookups per question ran several
times a poll (microscope wave 3). The answer is kept only until the next load.}

String Property PLUGIN = "CompanionIvy.esm" AutoReadOnly
Int Property IVY_NPC_ID = 0x000803 AutoReadOnly
Int Property IVY_QUEST_ID = 0x000805 AutoReadOnly
Int Property AFFINITY_ID = 0x00E7C4 AutoReadOnly
Int Property IS_AROUSED_ID = 0x0011AA AutoReadOnly
Int Property AROUSAL_THRESHOLD_ID = 0x0011AB AutoReadOnly
Int Property LOVE_ID = 0x017C76 AutoReadOnly
Int Property AVAILABLE_ID = 0x005994 AutoReadOnly
Int Property ANGRY_ID = 0x00F7C4 AutoReadOnly
Int Property IRRITATED_ID = 0x00EFF5 AutoReadOnly
Int Property FAVOR_SEX_SCENE_ID = 0x0059BC AutoReadOnly

; Her affinity messages run p_ivy_affinity_msg_05 .. _200, so 200 is taken as the
; top of her scale. ASSUMED, not measured: nothing read so far says what her maximum is.
Float Property AFFINITY_SCALE = 200.0 AutoReadOnly

; This load's answer, and her forms, found once. Script variables live in the save,
; so Revalidate runs on EVERY load before anything reads them.
Bool _valid = False
ActorBase _base = None
Quest _quest = None
Scene _favorSex = None
GlobalVariable _affinity = None
GlobalVariable _aroused = None
GlobalVariable _love = None
GlobalVariable _available = None
GlobalVariable _angry = None
GlobalVariable _irritated = None

; C4 PER FIELD, not per plugin: a moved or missing global would otherwise read as
; "not angry, not irritated, not closed" -- a permissive guess, the opposite of what
; C4 promises. The scene must belong to her quest, and her quest must carry her
; script: a type check alone passes a moved id that lands on another scene.
Function Revalidate()
	Bool was = _valid
	_valid = False
	If Game.IsPluginInstalled(PLUGIN)
		_base = Game.GetFormFromFile(IVY_NPC_ID, PLUGIN) as ActorBase
		_quest = Game.GetFormFromFile(IVY_QUEST_ID, PLUGIN) as Quest
		_favorSex = Game.GetFormFromFile(FAVOR_SEX_SCENE_ID, PLUGIN) as Scene
		_affinity = Game.GetFormFromFile(AFFINITY_ID, PLUGIN) as GlobalVariable
		_aroused = Game.GetFormFromFile(IS_AROUSED_ID, PLUGIN) as GlobalVariable
		_love = Game.GetFormFromFile(LOVE_ID, PLUGIN) as GlobalVariable
		_available = Game.GetFormFromFile(AVAILABLE_ID, PLUGIN) as GlobalVariable
		_angry = Game.GetFormFromFile(ANGRY_ID, PLUGIN) as GlobalVariable
		_irritated = Game.GetFormFromFile(IRRITATED_ID, PLUGIN) as GlobalVariable
		GlobalVariable threshold = Game.GetFormFromFile(AROUSAL_THRESHOLD_ID, PLUGIN) as GlobalVariable
		_valid = _base != None && _quest != None && _favorSex != None && _affinity != None
		_valid = _valid && _aroused != None && _love != None && _available != None
		_valid = _valid && _angry != None && _irritated != None && threshold != None
		_valid = _valid && _favorSex.GetOwningQuest() == _quest && _quest.CastAs("CompanionIvyScript") != None
		If !_valid
			Debug.Trace("Overture companions: CompanionIvy.esm is installed but its ids do not match 6.1 - the Ivy adapter is OFF", 1)
		ElseIf !was
			Debug.Trace("Overture companions: Ivy's ids check out (6.1) - her adapter is on", 0)
		EndIf
	EndIf
EndFunction

Bool Function Installed()
	Return _valid
EndFunction

; Her own script, for calling her own functions. None when she is not validated.
ScriptObject Function IvyScript()
	If !_valid
		Return None
	EndIf
	Return _quest.CastAs("CompanionIvyScript")
EndFunction

; True when the global exists AND is set.
Bool Function Flag(GlobalVariable akGlobal)
	Return _valid && akGlobal != None && akGlobal.GetValue() != 0.0
EndFunction

Bool Function Claims(Actor akWho)
	Return _valid && akWho != None && akWho.GetActorBase() == _base
EndFunction

; Is this HER, whether or not this adapter validated? Only the plugin and her NPC id,
; nothing of her version: an Ivy update that moves one of her globals turns this
; adapter off, and she must then go quiet (the engine fallback), not fall through to
; the framework adapter and get Overture's moments on top of her own (O-41).
Bool Function IsHers(Actor akWho)
	If akWho == None || !Game.IsPluginInstalled(PLUGIN)
		Return False
	EndIf
	ActorBase hers = Game.GetFormFromFile(IVY_NPC_ID, PLUGIN) as ActorBase
	Return hers != None && akWho.GetActorBase() == hers
EndFunction

; Her unique actor, for the scripts that act on her scenes.
Actor Function Ivy()
	If !_valid
		Return None
	EndIf
	Return _base.GetUniqueActor()
EndFunction

Scene Function FavorSex()
	If !_valid
		Return None
	EndIf
	Return _favorSex
EndFunction

; Her own Favor: Sex is the moment; Overture opens nothing of its own for her (C3).
Bool Function OpensMoments(Actor akWho)
	Return False
EndFunction

; She keeps arousal of her own: Overture writes no wanting for her (fo4-anatomy reads
; her own _ivy_IsAroused).
Bool Function HasOwnArousal(Actor akWho)
	Return Self.Claims(akWho)
EndFunction

Bool Function KnowsAffinity(Actor akWho)
	Return Self.Claims(akWho)
EndFunction

Float Function Affinity(Actor akWho)
	If !Self.Claims(akWho)
		Return 0.0
	EndIf
	Float a = _affinity.GetValue() / AFFINITY_SCALE
	If a > 1.0
		Return 1.0
	ElseIf a < -1.0
		Return -1.0
	EndIf
	Return a
EndFunction

; She has a romance of her own: LoveRelationShipEstablished (O-22 reads it first).
Bool Function HasRomance(Actor akWho)
	Return Self.Claims(akWho)
EndFunction

Bool Function IsRomanced(Actor akWho)
	Return Self.Flag(_love)
EndFunction

; Angry or irritated, by her own reckoning, is a no -- whatever our numbers say.
Bool Function Refuses(Actor akWho)
	If Parent.Refuses(akWho)
		Return True
	EndIf
	If !_valid
		Return True
	EndIf
	Return Self.Flag(_angry) || Self.Flag(_irritated)
EndFunction

; Her story can close the door for good: DenyRelationShipForEver sets this to 0.
Bool Function Closed(Actor akWho)
	Return _valid && _available.GetValue() == 0.0
EndFunction

Bool Function Wants(Actor akWho)
	Return Self.Flag(_aroused)
EndFunction

Scene Function OwnIntimateScene(Actor akWho)
	Return Self.FavorSex()
EndFunction

String Function Name()
	Return "ivy"
EndFunction
