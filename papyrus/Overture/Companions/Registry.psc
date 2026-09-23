Scriptname Overture:Companions:Registry extends Quest
{Who counts as a companion, who is the current one, and which adapter speaks for them.

A companion is anyone the engine has ever made one: HasBeenCompanionFaction
(Fallout4.esm 000A1B85), which FollowersScript adds when a companion becomes AVAILABLE
(SetAvailableToBeCompanion: Piper, Preston after Concord ...) as well as on recruitment,
and never removes -- the stranger approach leaves them to this module for good (O-21).
The CURRENT one is in CurrentCompanionFaction (00023C01) and in FollowersScript's
Companion alias. Ivy's own NPC record carries both, so a mod companion built on the
vanilla framework needs no registration at all.

Adapters are scripts on this same quest, asked most specific first. A new companion
mod means one new adapter script and one line in AdapterFor -- never a patch to
their plugin (C1).}

Int Property CURRENT_COMPANION_FACTION_ID = 0x00023C01 AutoReadOnly
Int Property HAS_BEEN_COMPANION_FACTION_ID = 0x000A1B85 AutoReadOnly
; O-25, "the strangers' rule": adult humans and ghouls -- the greeting's own test.
; ActorTypeNPC covers HumanRace, GhoulRace, HumanChildRace and SynthGen2Race;
; ActorTypeSynth takes the Gen-2 synths back out (Nick), IsChild the children.
Int Property KW_ACTOR_TYPE_NPC_ID = 0x00013794 AutoReadOnly
Int Property KW_ACTOR_TYPE_SYNTH_ID = 0x0010C3CE AutoReadOnly

Faction Function VanillaFaction(Int aiID)
	Return Game.GetFormFromFile(aiID, "Fallout4.esm") as Faction
EndFunction

Bool Function IsCompanion(Actor akWho)
	Faction hasBeen = Self.VanillaFaction(HAS_BEEN_COMPANION_FACTION_ID)
	Return akWho != None && hasBeen != None && akWho.IsInFaction(hasBeen)
EndFunction

; The scene's companion phase and the companion greeting test exactly this.
Bool Function IsCurrentCompanion(Actor akWho)
	Faction current = Self.VanillaFaction(CURRENT_COMPANION_FACTION_ID)
	Return akWho != None && current != None && akWho.IsInFaction(current)
EndFunction

; The one companion the base game's follower system travels with: its Companion
; alias. (Dogmeat has an alias of his own and is never a person here.)
Actor Function Current()
	FollowersScript followers = FollowersScript.GetScript()
	If followers == None || followers.Companion == None
		Return None
	EndIf
	Return followers.Companion.GetActorReference()
EndFunction

Bool Function Eligible(Actor akWho)
	If akWho == None || akWho.IsChild()
		Return False
	EndIf
	Keyword npc = Game.GetFormFromFile(KW_ACTOR_TYPE_NPC_ID, "Fallout4.esm") as Keyword
	Keyword synth = Game.GetFormFromFile(KW_ACTOR_TYPE_SYNTH_ID, "Fallout4.esm") as Keyword
	If npc == None || !akWho.HasKeyword(npc)
		Return False
	EndIf
	Return synth == None || !akWho.HasKeyword(synth)
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
