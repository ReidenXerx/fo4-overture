Scriptname Overture:Fragments:TryPerk extends Perk Const Hidden
{O-53 (owner, 2026-09-30): Overture opens by its own key. "Overture" on a stranger's
activation prompt, beside their own Talk, so a plain E is always theirs -- a quest NPC's
quest, a trader's trade.

The perk (OvertureTryPerk, Overture.esp 0x944) is AskPerk's shape, with the stranger
greeting's own gates. This fragment is what the choice runs: Approach stamps them and
activates them, and the greeting -- which now needs that stamp, or an invitation -- opens
the conversation on its menu: Try your luck, Follow me, Later., Just talk.}

Function Fragment_Entry_00(ObjectReference akTargetRef, Actor akActor)
	Overture:Approach approach = Game.GetFormFromFile(0x00000800, "Overture.esp") as Overture:Approach
	If approach != None
		approach.TryYourLuck(akTargetRef as Actor)
	EndIf
EndFunction
