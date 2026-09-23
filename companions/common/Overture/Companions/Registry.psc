Scriptname Overture:Companions:Registry extends Quest
{Who counts as a companion, and which adapter speaks for them.

A companion is anyone the engine has ever made one: HasBeenCompanionFaction
(Fallout4.esm 000A1B85), which FollowersScript.SetCompanion adds on recruitment
and never removes. The CURRENT one is in CurrentCompanionFaction (00023C01).
Ivy's own NPC record carries both, so a mod companion built on the vanilla
framework needs no registration at all.

Adapters are scripts on this same quest, asked most specific first. A new
companion mod means one new adapter script and one line in AdapterFor -- never
a patch to their plugin (C1).

SCAFFOLD (2026-09-23).}

Int Property CURRENT_COMPANION_FACTION_ID = 0x00023C01 AutoReadOnly
Int Property HAS_BEEN_COMPANION_FACTION_ID = 0x000A1B85 AutoReadOnly

Faction Function VanillaFaction(Int aiID)
	Return Game.GetFormFromFile(aiID, "Fallout4.esm") as Faction
EndFunction

Bool Function IsCompanion(Actor akWho)
	Faction hasBeen = Self.VanillaFaction(HAS_BEEN_COMPANION_FACTION_ID)
	Return akWho != None && hasBeen != None && akWho.IsInFaction(hasBeen)
EndFunction

Bool Function IsCurrentCompanion(Actor akWho)
	Faction current = Self.VanillaFaction(CURRENT_COMPANION_FACTION_ID)
	Return akWho != None && current != None && akWho.IsInFaction(current)
EndFunction

Overture:Companions:Adapter Function Named(String asScript)
	Return (Self as Quest).CastAs(asScript) as Overture:Companions:Adapter
EndFunction

Overture:Companions:Adapter Function AdapterFor(Actor akWho)
	Overture:Companions:Adapter a = Self.Named("Overture:Companions:IvyAdapter")
	If a != None && a.Claims(akWho)
		Return a
	EndIf
	a = Self.Named("Overture:Companions:VanillaAdapter")
	If a != None && a.Claims(akWho)
		Return a
	EndIf
	Return Self.Named("Overture:Companions:EngineAdapter")
EndFunction
