Scriptname Overture:Companions:AffinityMirror extends Quest
{VARIANT A -- THE COMPANION'S OWN AFFINITY IS THE RELATIONSHIP.

The thin variant. Overture keeps no opinion of its own about how much a
companion likes the player: it asks their adapter (vanilla CA_Affinity, Ivy's
_ivy_Affinity) and mirrors every CHANGE into Rapport's store, so the store's
player<->companion bond is their affinity's history plus whatever scenes added.
Gates read the adapter directly:

  conversation opens      Affinity >= 0.50  (vanilla Admiration)
  a yes is possible       Affinity >= 0.75  (vanilla Confidant), or romanced
  never                   their adapter Refuses() or Closed()

WHY IT MIRRORS DELTAS, NOT VALUES. Setting the bond to the affinity would erase
what Rapport's scenes add (15% of the distance left, R-10's "add this much, for
this reason"). Adding the change keeps every writer's contribution.

THE UNIQUE MODIFIERS here are the companion's own: their likes and dislikes of
what the player does, which vanilla already turns into affinity. That is the
case for A -- and its limit: intimacy never moves affinity (A is read-only on
their side, C5), so Overture adds nothing to the relationship itself.

SCAFFOLD (2026-09-23): not in the shipping plugin. Needs, in Overture.esp:
AVIF OvertureMirroredAffinity (reserved 0x854) and this script on the
companions quest (reserved 0x855).}

Int Property MIRRORED_AV_ID = 0x00000854 AutoReadOnly
Float Property MIN_CHANGE = 0.02 AutoReadOnly
Float Property OPENS_AT = 0.50 AutoReadOnly
Float Property YES_AT = 0.75 AutoReadOnly
Int Property REASON_ADDON = 5 AutoReadOnly

Overture:Companions:Registry Function Registry()
	Return (Self as Quest) as Overture:Companions:Registry
EndFunction

ActorValue Function MirroredAV()
	Return Game.GetFormFromFile(MIRRORED_AV_ID, "Overture.esp") as ActorValue
EndFunction

; Call on any conversation with the companion, and from a slow timer while they
; follow. Cheap: one AV read, one adapter read, a write only on real change.
Function Mirror(Actor akWho)
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	ActorValue av = Self.MirroredAV()
	If a == None || av == None || !a.KnowsAffinity(akWho)
		Return
	EndIf
	; The AV starts at 0 for everybody, which is also "never mirrored" -- so the
	; first mirror of an actor whose affinity is already 0.4 writes +0.4 once.
	Float now = a.Affinity(akWho)
	Float last = akWho.GetValue(av)
	Float change = now - last
	If change < MIN_CHANGE && change > -MIN_CHANGE
		Return
	EndIf
	Rapport:Relations.AddBondBetween(Game.GetPlayer(), akWho, change, REASON_ADDON)
	akWho.SetValue(av, now)
EndFunction

Bool Function ConversationOpens(Actor akWho)
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	If a == None || a.Refuses(akWho) || a.Closed(akWho)
		Return False
	EndIf
	Return a.IsRomanced(akWho) || a.Affinity(akWho) >= OPENS_AT
EndFunction

Bool Function WouldSayYes(Actor akWho)
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	If a == None || a.Refuses(akWho) || a.Closed(akWho)
		Return False
	EndIf
	Return a.IsRomanced(akWho) || a.Affinity(akWho) >= YES_AT
EndFunction
