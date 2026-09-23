Scriptname Overture:Reply extends TopicInfo
{On an NPC's reply line: once it has been SAID, tell the approach what it did.

Vanilla's own pattern -- CA_DialogueBump_BaseScript does exactly this for
companion affinity -- and the same VMAD shape Fallout4.esm's INFO 0001DABE
carries: plain scripts, no fragment block. Stage and Outcome are filled per
INFO by tools/make_overture_esp.py, so one script serves every reply.

OnEnd rather than OnBegin: a line cut off before its end (the player walked
away, combat) did not land, and should not move anybody's bond.}

; 1 = the first approach, 2 = the second exchange, 3 = the proposition.
Int Property Stage Auto Const
; 1 land, 2 miss, 3 offend (blunt at anyone but vulgar), 4 recoil,
; 5 recoil on the persona it would have landed with. Overture:Approach owns
; what each is worth.
Int Property Outcome Auto Const

Event OnEnd(ObjectReference akSpeakerRef, Bool abHasBeenSaid)
	Overture:Approach approach = Self.GetOwningQuest() as Overture:Approach
	If approach == None
		Debug.Trace("Overture: a reply ended outside the approach quest - nothing recorded", 1)
		Return
	EndIf
	approach.Replied(akSpeakerRef as Actor, Stage, Outcome)
EndEvent
