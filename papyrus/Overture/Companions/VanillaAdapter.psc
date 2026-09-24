Scriptname Overture:Companions:VanillaAdapter extends Overture:Companions:Adapter
{Every companion on the game's own framework: CompanionActorScript on the actor,
affinity in CA_Affinity -- the base game's AND any mod's that builds on it (O-41,
owner 2026-09-24). Ivy's actor carries it too, but her adapter is asked first and
the Registry never hands her here.

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
Int Property CA_IS_ROMANCEABLE_NOW_ID = 0x00148F8D AutoReadOnly
Float Property INFATUATION = 1000.0 AutoReadOnly

ActorValue Function VanillaAV(Int aiID)
	Return Game.GetFormFromFile(aiID, "Fallout4.esm") as ActorValue
EndFunction

; EVERY companion built on the game's own framework: CompanionActorScript on the
; actor, or a script that extends it. O-41 (owner poll, 2026-09-24: "Full, like
; vanilla ones"): mod companions -- Heather, Dr Cabbage, Leer, Frost, Hosea -- get
; exactly what the base game's get, moments included. Everything read here is the
; framework's own bookkeeping (CA_Affinity through ModAffinity, CA_IsRomantic,
; CA_WantsToTalk, CA_IsRomanceableNow, TemporaryAngerLevel), so it holds for them as
; it does for Piper. This REVERSES the design review of 2026-09-23, which kept them
; out for fear of doubling their own content; the owner chose the content.
; A companion with a system of its own beyond the framework (Ivy) still gets its own
; adapter, asked first; the Registry never lets hers fall through to this one.
Bool Function Claims(Actor akWho)
	Return akWho != None && (akWho as CompanionActorScript) != None
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
	If av != None && akWho.GetValue(av) != 0.0
		Return True
	EndIf
	; Their own anger: CompanionActorScript.ModAffinity sets TemporaryAngerLevel to 1
	; (an hour) or 2 (eight) on any fall, and clears it on a timer. An actor value the
	; script names, read through its own property (C5).
	CompanionActorScript cas = akWho as CompanionActorScript
	If cas != None && cas.TemporaryAngerLevel != None && akWho.GetValue(cas.TemporaryAngerLevel) > 0.0
		Return True
	EndIf
	; Below Neutral -- Disdain, Hatred on the way -- is a no whatever their romance
	; says: CA_IsRomantic is never cleared once set, their affinity is their live
	; state (C2; microscope wave 3).
	Return Self.KnowsAffinity(akWho) && Self.Affinity(akWho) < 0.0
EndFunction

; A romance declined for good closes the door: CompanionActorScript.RomanceDeclined
; (True) sets CA_IsRomanceableNow (Fallout4.esm 00148F8D) to -1, and nothing sets it
; back. Their own story has said no; Overture does not ask around it.
Bool Function Closed(Actor akWho)
	If !Self.HasRomance(akWho)
		Return False
	EndIf
	ActorValue av = Self.VanillaAV(CA_IS_ROMANCEABLE_NOW_ID)
	Return av != None && akWho.GetValue(av) == -1.0
EndFunction

; "vanilla" for the base game's own, "framework" for a mod's -- for the traces, and so
; a report can tell which kind a verdict came from. Nothing branches on it.
String Function Name()
	Return "vanilla"
EndFunction

String Function KindOf(Actor akWho)
	If akWho != None && Self.FromOfficialMaster(akWho.GetActorBase())
		Return "vanilla"
	EndIf
	Return "framework"
EndFunction
