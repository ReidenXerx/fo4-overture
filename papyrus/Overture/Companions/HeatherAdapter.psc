Scriptname Overture:Companions:HeatherAdapter extends Overture:Companions:Adapter
{Heather Casdin (llamaCompanionHeatherv2.esp). O-51 (owner poll, 2026-09-26): ROMANCE ONLY.

She is NOT on the game's companion framework, whatever O-41 assumed: her actor script,
llama_:llama_HeatherActorScript, extends Actor, not CompanionActorScript, so the
framework adapter never claimed her, and a player she loved got no "you and Heather are
a couple now" (alasdairn, Discord, 2026-09-26). She keeps her own affinity points and
her own quests. What she does share with the framework is its romance flag: her core
quest's relationship stage runs HeatherActor.SetValue(CA_IsRomantic, 1.0), "added in
v2.4 for compatibility with various other mods" (her own comment, read from the source
her archive ships, QF_llamaCOMHeatherCore_0100C9BA).

So this adapter reads that one fact. Romanced, she becomes the player's lover to the world
(Feeders.OwnRomance: the Narrator's line, Chemistry's "spoken for", Rapport's lovers), and
a lover's jealousy applies to her as to anyone (O-29). No moments and no "Ask for a
moment": her voiced content is hers, as Ivy's is (O-49). Her affinity is not mapped
(KnowsAffinity is False): her points have a scale nothing here has measured.

Ids are her plugin's own, read 2026-09-26 from version 2.7 (tools/dump_record.py):
  NPC_ llamaCompanion       00AB33
  QUST llamaCOMHeatherCore  00C9BA  (llama_:llama_COMHeatherCoreQuest)
Checked once per load (Revalidate, from Moments.Hook). A version that moves either turns
this adapter off, and she goes quiet (the engine fallback), as before.}

String Property PLUGIN = "llamaCompanionHeatherv2.esp" AutoReadOnly
Int Property HEATHER_NPC_ID = 0x00AB33 AutoReadOnly
Int Property CORE_QUEST_ID = 0x00C9BA AutoReadOnly
Int Property CA_IS_ROMANTIC_ID = 0x00148DF6 AutoReadOnly

; This load's answer. Script variables live in the save, so Revalidate runs on EVERY
; load before anything reads them.
Bool _valid = False
ActorBase _base = None
ActorValue _romantic = None

Function Revalidate()
	Bool was = _valid
	_valid = False
	If Game.IsPluginInstalled(PLUGIN)
		_base = Game.GetFormFromFile(HEATHER_NPC_ID, PLUGIN) as ActorBase
		Quest core = Game.GetFormFromFile(CORE_QUEST_ID, PLUGIN) as Quest
		_romantic = Game.GetFormFromFile(CA_IS_ROMANTIC_ID, "Fallout4.esm") as ActorValue
		_valid = _base != None && core != None && _romantic != None
		_valid = _valid && core.CastAs("llama_:llama_COMHeatherCoreQuest") != None
		If !_valid
			Debug.Trace("Overture companions: llamaCompanionHeatherv2.esp is installed but its ids do not match 2.7 - the Heather adapter is OFF", 1)
		ElseIf !was
			Debug.Trace("Overture companions: Heather's ids check out (2.7) - her adapter is on (romance only)", 0)
		EndIf
	EndIf
EndFunction

Bool Function Claims(Actor akWho)
	Return _valid && akWho != None && akWho.GetActorBase() == _base
EndFunction

; Her own mod gives her a romance: the relationship stage of her core quest.
Bool Function HasRomance(Actor akWho)
	Return Self.Claims(akWho)
EndFunction

Bool Function IsRomanced(Actor akWho)
	Return Self.Claims(akWho) && akWho.GetValue(_romantic) == 1.0
EndFunction

; O-51: romance only. Her content is hers; Overture opens nothing for her.
Bool Function OpensMoments(Actor akWho)
	Return False
EndFunction

String Function Name()
	Return "heather"
EndFunction
