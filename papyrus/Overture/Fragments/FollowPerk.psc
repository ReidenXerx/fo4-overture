Scriptname Overture:Fragments:FollowPerk extends Perk Const Hidden
{O-52 (owner, 2026-09-27): "Follow me" on an NPC's activation prompt, beside their own Talk.

The perk (OvertureFollowPerk, Overture.esp 0x942) is the same Activate entry point as
"Ask for a moment" (Overture:Fragments:AskPerk); its conditions show the choice only for
someone warm who could come along. This fragment hands the choice to Overture:Follow, which
has the player say it, has them answer, and does the following.}

Function Fragment_Entry_00(ObjectReference akTargetRef, Actor akActor)
	Overture:Follow follow = Game.GetFormFromFile(0x00000940, "Overture.esp") as Overture:Follow
	If follow != None
		follow.Ask(akTargetRef as Actor)
	EndIf
EndFunction
