Scriptname Overture:Companions:Adapter extends Quest
{The questions the companion module asks of ANY companion, answered by whatever
knows that companion best.

This base answers them from the engine alone, so a companion nobody wrote an
adapter for still works -- it is the fallback (C4 in docs/methodology.md 11),
not an abstract class. Papyrus has no interfaces; a subclass overrides what its
companion's own mod can answer better.

ONE RULE FOR EVERY ADAPTER: their state outranks ours (C2), their content comes
first (C3), and their bookkeeping is theirs -- call their functions, never
write their globals (C5). Nothing here is a master or a patch (C1): a companion
mod is found at runtime with Game.IsPluginInstalled and Game.GetFormFromFile,
and when a lookup comes back None the adapter says "I do not know", never a
guess.

SCAFFOLD (2026-09-23). Not compiled into the shipping plugin; see
companions/README.md.}

; Does this adapter speak for this actor? The registry asks each adapter in
; turn, most specific first.
Bool Function Claims(Actor akWho)
	Return akWho != None
EndFunction

; How much they like the player, in THEIR system's terms, normalised to -1..1.
; 0 when unknown -- which the caller must not read as "neutral".
Float Function Affinity(Actor akWho)
	Return 0.0
EndFunction

; Whether Affinity() measured anything. False means 0.0 above is "unknown".
Bool Function KnowsAffinity(Actor akWho)
	Return False
EndFunction

; Their own system's romance: vanilla CA_IsRomantic, Ivy's love flag.
Bool Function IsRomanced(Actor akWho)
	Return False
EndFunction

; Their own system says NO right now: angry, irritated, in a scene of their own,
; wanting to talk about something else. Outranks every number of ours (C2).
Bool Function Refuses(Actor akWho)
	If akWho == None
		Return True
	EndIf
	Return akWho.IsDead() || akWho.IsInCombat() || akWho.IsInScene()
EndFunction

; Their own story has closed the door for good (Ivy's DenyRelationShipForEver).
Bool Function Closed(Actor akWho)
	Return False
EndFunction

; Their own system says they WANT the player now (Ivy's arousal flag). A moment,
; in Variant C's terms.
Bool Function Wants(Actor akWho)
	Return False
EndFunction

; Their OWN intimate scene, when their mod has one (C3). None: use Overture's.
Scene Function OwnIntimateScene(Actor akWho)
	Return None
EndFunction

; May Overture open a conversation of its own with this companion (variant C's
; moment)? FALSE by default -- C6: a companion no adapter vouches for stays
; invisible. A companion from a mod with voiced content of its own would
; otherwise hear Overture's lines as subtitles over their own voice (design
; review 2026-09-23). An adapter says True only when it knows the companion has
; nothing of their own for the moment.
Bool Function OpensMoments(Actor akWho)
	Return False
EndFunction

; Tell their system what just happened, in its own vocabulary. asWhat is one of
; "flirt", "deny", "scene". The base knows no vocabulary and says nothing.
Function Notify(Actor akWho, String asWhat)
EndFunction

; A short name for traces. Never shown to the player.
String Function Name()
	Return "engine"
EndFunction
