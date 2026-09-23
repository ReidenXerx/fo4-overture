; IMPORT-ONLY. The reconstructed base sources have no TopicInfo.psc, so the
; compiler rejects any script that extends it. This stub is on the import path
; and NEVER under papyrus/: build-papyrus compiles papyrus/ with -all, and a
; stub there would produce a TopicInfo.pex shadowing the game's own at runtime.
;
; Shape: what the game's compiled TopicInfo.pex names in its string table
; (OnBegin, OnEnd, akSpeakerRef, abHasBeenSaid, GetOwningQuest, HasBeenSaid),
; and how vanilla scripts use it -- CA_TopicInfoScript and
; CA_DialogueBump_BaseScript override OnBegin/OnEnd with exactly these
; parameters. fo4-rapport's stub has no events because nothing there extends it.
ScriptName TopicInfo Extends Form Native hidden

Event OnBegin(ObjectReference akSpeakerRef, Bool abHasBeenSaid)
EndEvent

Event OnEnd(ObjectReference akSpeakerRef, Bool abHasBeenSaid)
EndEvent

Quest Function GetOwningQuest() Native

Bool Function HasBeenSaid() Native
