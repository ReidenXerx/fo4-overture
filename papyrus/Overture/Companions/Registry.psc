Scriptname Overture:Companions:Registry extends Quest
{Who counts as a companion, who is the current one, and which adapter speaks for them.

A companion is anyone the engine has ever made one: HasBeenCompanionFaction
(Fallout4.esm 000A1B85), which FollowersScript adds when a companion becomes AVAILABLE
(SetAvailableToBeCompanion: Piper, Preston after Concord ...) as well as on recruitment,
and never removes -- the stranger approach leaves them to this module for good (O-21).
The CURRENT one is in CurrentCompanionFaction (00023C01) and in FollowersScript's
Companion alias. Ivy's own NPC record carries both, so a mod companion built on the
vanilla framework needs no registration at all.

Adapters are scripts on this same quest, asked most specific first. A companion mod
built on the game's framework needs NOTHING: the framework adapter reads it like the
base game's (O-41). Only one with a system of its own beyond the framework (Ivy)
needs an adapter script and a line in AdapterFor -- never a patch to their plugin (C1).}

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

; The follower system's Companion ALIAS: one actor. NOT "the companion" under Amazing
; Follower Tweaks, which rotates this alias among its followers every 15 seconds
; (TweakDFScript.RotateCompanion) unless the player locks it. Ask CurrentAll for who
; travels with the player. (Dogmeat has an alias of his own and is never a person here.)
Actor Function Current()
	FollowersScript followers = FollowersScript.GetScript()
	If followers == None || followers.Companion == None
		Return None
	EndIf
	Return followers.Companion.GetActorReference()
EndFunction

; EVERY current companion (AFT multi-follower support, owner 2026-09-24).
; ActiveCompanions holds everyone who has EVER been one -- AFT's own comment on it:
; "never cleaned up" -- so it is filtered by CurrentCompanionFaction, which AFT puts on
; every follower it recruits and takes off on dismissal (AFT 1.23 TweakDFScript
; SetCompanion / DismissCompanion, read from its archive 2026-09-24). Vanilla: one actor.
; AFT: up to five, plus Dogmeat, whom Eligible drops. No dependency on AFT: the
; collection and the faction are the game's own.
Actor[] Function CurrentAll()
	Actor[] out = new Actor[0]
	FollowersScript followers = FollowersScript.GetScript()
	If followers == None
		Return out
	EndIf
	RefCollectionAlias everyone = followers.ActiveCompanions
	If everyone != None
		Int i = 0
		Int n = everyone.GetCount()
		While i < n
			Actor a = everyone.GetAt(i) as Actor
			If a != None && Self.IsCurrentCompanion(a) && out.Find(a) < 0
				out.Add(a)
			EndIf
			i += 1
		EndWhile
	EndIf
	; The alias too, for a follower the collection lacks.
	Actor primary = Self.Current()
	If primary != None && Self.IsCurrentCompanion(primary) && out.Find(primary) < 0
		out.Add(primary)
	EndIf
	Return out
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
	; Ivy with her adapter off (an update moved one of her forms): the engine fallback,
	; which opens nothing -- never the framework adapter's moments over her own (O-41).
	Overture:Companions:IvyAdapter ivy = a as Overture:Companions:IvyAdapter
	If ivy != None && ivy.IsHers(akWho)
		Return Self.Named("Overture:Companions:EngineAdapter")
	EndIf
	a = Self.Named("Overture:Companions:VanillaAdapter")
	If a != None && a.Claims(akWho)
		Return a
	EndIf
	Return Self.Named("Overture:Companions:EngineAdapter")
EndFunction
