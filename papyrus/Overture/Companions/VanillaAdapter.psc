Scriptname Overture:Companions:VanillaAdapter extends Overture:Companions:Adapter
{The BASE GAME's companions: CompanionActorScript on the actor, affinity in
CA_Affinity, the actor from Fallout4.esm or an official DLC master. A mod
companion that reuses the framework (Ivy's actor carries it too) is NOT claimed
here: it may have voiced content of its own, and only an adapter written for it
knows (C6, design review 2026-09-23).

Read 2026-09-23 from Fallout4.esm with tools/dump_record.py:
  CA_Affinity      AVIF 000A1B80    CA_IsRomantic  AVIF 00148DF6
  CA_WantsToTalk   AVIF 000FA86B    (0 no, 1 will forcegreet, 2 wants to but will not)
  thresholds (GLOB): Infatuation 1000, Confidant 750, Admiration 500,
                     Friend 250, Neutral 0, Disdain -500, Hatred -1000
CompanionActorScript.IsRomantic() is GetValue(CA_IsRomantic) == 1.0, and
ModAffinity clamps to MinAffinity/MaxAffinity (default -1100/1100), so dividing by
the Infatuation threshold and clamping gives -1..1 with Infatuation at 1.

READ ONLY (O-24): moving a companion's affinity from outside would fire their own
threshold scenes, messages and perks -- their bookkeeping (C5).}

Int Property CA_AFFINITY_ID = 0x000A1B80 AutoReadOnly
Int Property CA_IS_ROMANTIC_ID = 0x00148DF6 AutoReadOnly
Int Property CA_WANTS_TO_TALK_ID = 0x000FA86B AutoReadOnly
Float Property INFATUATION = 1000.0 AutoReadOnly

ActorValue Function VanillaAV(Int aiID)
	Return Game.GetFormFromFile(aiID, "Fallout4.esm") as ActorValue
EndFunction

; THE BASE GAME'S companions only -- Fallout4.esm and the official DLC masters.
; Claiming every actor that carries CompanionActorScript swept in every mod
; companion built on the framework (Heather, the spouse companions, Ivy's actor
; too), and sent them down the path meant for companions with no content of their
; own (design review 2026-09-23). A mod companion gets its own adapter, or the
; engine fallback, which opens nothing (C6).
Bool Function Claims(Actor akWho)
	If akWho == None || (akWho as CompanionActorScript) == None
		Return False
	EndIf
	Return Self.FromOfficialMaster(akWho.GetActorBase())
EndFunction

Bool Function FromOfficialMaster(Form akForm)
	If akForm == None
		Return False
	EndIf
	Int id = akForm.GetFormID()
	If id < 0
		; A load-order index of 0x80 or more is never an official master.
		Return False
	EndIf
	; No bitwise AND in Papyrus: the object id is the low 24 bits.
	Int local = id % 16777216
	If Game.GetFormFromFile(local, "Fallout4.esm") == akForm
		Return True
	EndIf
	If Game.IsPluginInstalled("DLCRobot.esm") && Game.GetFormFromFile(local, "DLCRobot.esm") == akForm
		Return True
	EndIf
	If Game.IsPluginInstalled("DLCCoast.esm") && Game.GetFormFromFile(local, "DLCCoast.esm") == akForm
		Return True
	EndIf
	Return Game.IsPluginInstalled("DLCNukaWorld.esm") && Game.GetFormFromFile(local, "DLCNukaWorld.esm") == akForm
EndFunction

; The base game's companions have no intimate content of their own: Overture's
; conversation is theirs to have.
Bool Function OpensMoments(Actor akWho)
	Return Self.Claims(akWho)
EndFunction

Bool Function KnowsAffinity(Actor akWho)
	Return Self.Claims(akWho) && Self.VanillaAV(CA_AFFINITY_ID) != None
EndFunction

Float Function Affinity(Actor akWho)
	ActorValue av = Self.VanillaAV(CA_AFFINITY_ID)
	If akWho == None || av == None
		Return 0.0
	EndIf
	Float a = akWho.GetValue(av) / INFATUATION
	If a > 1.0
		Return 1.0
	ElseIf a < -1.0
		Return -1.0
	EndIf
	Return a
EndFunction

; MEASURED 2026-09-23 across Fallout4.esm and the three story DLC masters:
; CompanionActorScript's optional InfatuationRomanticMessage ("the message shown
; when the companion is at Romantic Infatuation") is filled on exactly the seven
; romanceable companions -- Cait, Curie, Danse, Hancock, MacCready, Piper, Preston
; -- and on none of the others: X6-88, Deacon, Gage, Old Longfellow, Nick, Strong,
; Codsworth, Ada. So the game's own data says who has a romance, and no list here does.
Bool Function HasRomance(Actor akWho)
	CompanionActorScript cas = akWho as CompanionActorScript
	Return cas != None && cas.InfatuationRomanticMessage != None
EndFunction

Bool Function IsRomanced(Actor akWho)
	ActorValue av = Self.VanillaAV(CA_IS_ROMANTIC_ID)
	If akWho == None || av == None
		Return False
	EndIf
	Return akWho.GetValue(av) == 1.0
EndFunction

Bool Function Refuses(Actor akWho)
	If Parent.Refuses(akWho)
		Return True
	EndIf
	; A companion who "wants to talk" has one of THEIR affinity scenes queued -- a
	; threshold, a romance retry, a murder they saw. That conversation is theirs
	; and goes first.
	ActorValue av = Self.VanillaAV(CA_WANTS_TO_TALK_ID)
	Return av != None && akWho.GetValue(av) != 0.0
EndFunction

String Function Name()
	Return "vanilla"
EndFunction
