Scriptname Overture:Fragments:AskPerk extends Perk Const Hidden
{O-35 (owner, 2026-09-23): the player's own way into a companion's conversation --
"Ask for a moment" on the companion's activation prompt, beside their own Talk.

The perk (OvertureAskPerk, Overture.esp 0x859) is an Activate entry point, transcribed
from vanilla's own (CC_PetDogs_PetPerk's "Pet", RoboticsExpert01's "Hack"); its
conditions show the choice only when a conversation could really open. This fragment
is what the choice runs: Moments marks them ASKED and activates them, and Overture's
greeting -- the verified O-7 mechanism -- does the rest. Vanilla's fragments take
exactly these two arguments (PRKF_MisterSandman_0004B258, decompiled).}

Function Fragment_Entry_00(ObjectReference akTargetRef, Actor akActor)
	Overture:Companions:Moments moments = Game.GetFormFromFile(0x00000855, "Overture.esp") as Overture:Companions:Moments
	If moments != None
		moments.Ask(akTargetRef as Actor)
	EndIf
EndFunction
