Scriptname Overture:Companions:VanillaAdapter extends Overture:Companions:Adapter
{Every companion built on the vanilla framework: CompanionActorScript on the
actor, affinity in CA_Affinity. The twelve base-game companions, their DLC kin,
and every mod companion that reuses the framework -- Ivy's actor carries it
too, though her own system is IvyAdapter's and outranks this one for her.

Read 2026-09-23 from Fallout4.esm with tools/dump_record.py:
  CA_Affinity      AVIF 000A1B80    CA_IsRomantic  AVIF 00148DF6
  CA_WantsToTalk   AVIF 000FA86B    (0 no, 1 will forcegreet, 2 wants to but will not)
  thresholds (GLOB): Infatuation 1000, Confidant 750, Admiration 500,
                     Friend 250, Neutral 0, Disdain -500, Hatred -1000
CompanionActorScript.IsRomantic() is GetValue(CA_IsRomantic) == 1.0, and
ModAffinity clamps to MinAffinity/MaxAffinity (default -1100/1100), so dividing
by the Infatuation threshold and clamping gives -1..1 with Infatuation at 1.

READ ONLY. Moving a companion's affinity from outside would fire their own
threshold scenes, messages and perks -- their bookkeeping (C5).

SCAFFOLD (2026-09-23).}

Int Property CA_AFFINITY_ID = 0x000A1B80 AutoReadOnly
Int Property CA_IS_ROMANTIC_ID = 0x00148DF6 AutoReadOnly
Int Property CA_WANTS_TO_TALK_ID = 0x000FA86B AutoReadOnly
Float Property INFATUATION = 1000.0 AutoReadOnly

ActorValue Function VanillaAV(Int aiID)
	Return Game.GetFormFromFile(aiID, "Fallout4.esm") as ActorValue
EndFunction

Bool Function Claims(Actor akWho)
	If akWho == None
		Return False
	EndIf
	Return (akWho as CompanionActorScript) != None
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
	; A companion who "wants to talk" has one of THEIR affinity scenes queued --
	; a threshold, a romance retry, a murder they saw. That conversation is
	; theirs and goes first.
	ActorValue av = Self.VanillaAV(CA_WANTS_TO_TALK_ID)
	Return av != None && akWho.GetValue(av) != 0.0
EndFunction

String Function Name()
	Return "vanilla"
EndFunction
