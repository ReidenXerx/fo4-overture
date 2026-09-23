Scriptname Overture:Companions:Feeders extends Quest
{B-LITE (O-19): THE STORE IS THE RELATIONSHIP; COMPANIONS FEED IT EVENTS.

  THE RELATIONSHIP  Rapport's player<->companion bond, and nothing else. Every
                    companion-only modifier below is an EVENT written into it in the
                    store's own units -- R-10's "add this much, for this reason",
                    R-2's "import, do not mirror". No axis of ours shadows it.
  THEIR OWN GATES   their adapter: affinity, romance, anger, the closed door. Read,
                    never written (C5; O-24: only Rapport's store moves).
  ONE STATE OF OURS WANTING (Desire, AVIF 0x851, 0..1 -- PUBLISHED: fo4-anatomy
                    reads it). Its contract, since microscope wave 3:
                    - it builds only while their own gates are open (their romance
                      done, or their affinity at the gate) and only on a day spent
                      TOGETHER (following the player, loaded);
                    - it goes to 0 after a scene together, and 0 when they stop being
                      the companion;
                    - a companion whose own mod keeps arousal of its own (Ivy) gets
                      NONE of ours: two opinions of one fact is R-1's problem.
                    A state, not a closeness -- wanting someone less the morning after
                    is not the relationship getting worse -- so it gates the yes and
                    never touches the store.

THE FEEDERS (sizes ASSUMED, fractions of the distance left, the main ones on MCM),
at most once a game day, and only while TOGETHER:
  their affinity reaches a level        fThresholdUp, ONCE per level ever (Friend 250,
                                        Admiration 500, Confidant 750, Infatuation 1000)
                                        -- vanilla's own threshold scenes fire once
  their affinity falls to Disdain,      fThresholdDown each, once per fall, re-armed
  then Hatred                           when they are back at Neutral
  a day travelling together             fTogetherPerDay
  a fight survived together             FIGHT_SURVIVED, one a day
  the player with someone else          ONLY for someone it is their business:
                                        romanced by their own romance, or Rapport's
                                        lovers. O-29's table, as for strangers:
                                        romantic and reticent stung (fJealousySting),
                                        vulgar thrilled (fJealousyThrill, and wanting
                                        rises), mercantile shrug. Said by the Narrator.
  a scene with the player               Rapport's own RecordScene writes the bond;
                                        here wanting goes to 0

WHY ONCE: Rapport moves a bond by a fraction of the distance left, up by a(1-b) and
down by a(1+b), so a level lost and regained is never a wash. Counting every
crossing drained a companion hovering at a threshold toward fallen-out, silently
(microscope wave 3).

ONLY for a companion an adapter claims (vanilla, Ivy): the engine fallback vouches
for nothing (C6). Nothing runs with Overture switched off (OvertureEnabled).}

Int Property APPROACH_QUEST_ID = 0x00000800 AutoReadOnly
Int Property DESIRE_AV_ID = 0x00000851 AutoReadOnly
Int Property LAST_TICK_AV_ID = 0x00000856 AutoReadOnly
; The negative level counted in the current fall (0, -1 Disdain, -2 Hatred).
Int Property FALL_AV_ID = 0x00000857 AutoReadOnly
; The player's scene count WITH this companion, plus one, as they last knew it.
Int Property PAIR_SEEN_AV_ID = 0x00000858 AutoReadOnly
; The player's scene count with ANYONE ELSE, plus one, as they last knew it (0 = never).
Int Property SEEN_SCENE_AV_ID = 0x0000085A AutoReadOnly
; The highest level of their own affinity ever counted (0-4).
Int Property TIER_AV_ID = 0x0000085B AutoReadOnly
; R-10's reasons: 3 dialogue, 4 gift, 5 any other addon.
Int Property REASON_ADDON = 5 AutoReadOnly
Int Property NEEDS_API = 201 AutoReadOnly

Float Property FIGHT_SURVIVED = 0.002 AutoReadOnly
; "Together" for a fight: the companion within this of the player when it ends.
Float Property FIGHT_RANGE = 4096.0 AutoReadOnly
Float Property THRILLED = 0.1 AutoReadOnly

Int Property GATE_PASS = 0 AutoReadOnly
Int Property GATE_STATE = 1 AutoReadOnly
Int Property GATE_UNWON = 2 AutoReadOnly
Int Property GATE_WANTING = 3 AutoReadOnly

Float _fightDay = -1.0
String _gateNote = ""

Overture:Companions:Registry Function Registry()
	Return (Self as Quest) as Overture:Companions:Registry
EndFunction

; The approach's quest: its settings (one Tuned, one guard), its switch, its rules.
Overture:Approach Function Overture()
	Return Game.GetFormFromFile(APPROACH_QUEST_ID, "Overture.esp") as Overture:Approach
EndFunction

Float Function Tuned(String asKey, Float afDefault)
	Overture:Approach approach = Self.Overture()
	If approach == None
		Return afDefault
	EndIf
	Return approach.Tuned(asKey, afDefault)
EndFunction

; Overture's master switch reaches the module too, not only the greetings.
Bool Function Enabled()
	Overture:Approach approach = Self.Overture()
	Return approach != None && approach.Enabled()
EndFunction

ActorValue Function OurAV(Int aiID)
	Return Game.GetFormFromFile(aiID, "Overture.esp") as ActorValue
EndFunction

Float Function Mark(Actor akWho, Int aiID)
	ActorValue av = Self.OurAV(aiID)
	If akWho == None || av == None
		Return 0.0
	EndIf
	Return akWho.GetValue(av)
EndFunction

Function SetMark(Actor akWho, Int aiID, Float afValue)
	ActorValue av = Self.OurAV(aiID)
	If akWho != None && av != None
		akWho.SetValue(av, afValue)
	EndIf
EndFunction

Bool Function RapportReady()
	Return Rapport:Core.ApiVersion() >= NEEDS_API
EndFunction

; Whether this companion's days, fights and levels are ours to count at all.
Bool Function Counts(Actor akWho)
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	Return a != None && a.Name() != "engine"
EndFunction

; Whether wanting is ours to keep for them (see the contract above).
Bool Function Desires(Actor akWho)
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	Return a != None && a.Name() != "engine" && !a.HasOwnArousal(akWho)
EndFunction

; Following the player and loaded: a day or a fight counts only then. Told to wait
; at a settlement is not travelling together.
Bool Function Together(Actor akWho)
	FollowersScript followers = FollowersScript.GetScript()
	Return akWho != None && akWho.Is3DLoaded() && followers != None && followers.IsFollowing(akWho)
EndFunction

; One event into the store, in its own units: "add this much, for this reason".
Function Feed(Actor akWho, Float afAmount)
	If akWho == None || afAmount == 0.0
		Return
	EndIf
	Rapport:Relations.AddBondBetween(Game.GetPlayer(), akWho, afAmount, REASON_ADDON)
EndFunction

Function SetDesire(Actor akWho, Float afValue)
	If !Self.Desires(akWho)
		Return
	EndIf
	Float d = afValue
	If d < 0.0
		d = 0.0
	ElseIf d > 1.0
		d = 1.0
	EndIf
	Self.SetMark(akWho, DESIRE_AV_ID, d)
EndFunction

Float Function Desire(Actor akWho)
	Return Self.Mark(akWho, DESIRE_AV_ID)
EndFunction

; Their affinity's level, normalised the way every adapter reports it (-1..1,
; Infatuation at 1): 4 Infatuation, 3 Confidant, 2 Admiration, 1 Friend, 0 Neutral,
; -1 Disdain, -2 Hatred -- vanilla's own thresholds.
Int Function Tier(Float afAffinity)
	If afAffinity >= 1.0
		Return 4
	ElseIf afAffinity >= 0.75
		Return 3
	ElseIf afAffinity >= 0.5
		Return 2
	ElseIf afAffinity >= 0.25
		Return 1
	ElseIf afAffinity <= -1.0
		Return -2
	ElseIf afAffinity <= -0.5
		Return -1
	EndIf
	Return 0
EndFunction

; Their own romance done, or -- with no romance of their own -- their affinity at
; the gate (O-22).
Bool Function Won(Actor akWho, Overture:Companions:Adapter akAdapter)
	If akAdapter.HasRomance(akWho)
		Return akAdapter.IsRomanced(akWho)
	EndIf
	Return akAdapter.KnowsAffinity(akWho) && akAdapter.Affinity(akWho) >= Self.Tuned("fAffinityGate:Companions", 1.00)
EndFunction

; Recruited: time together starts now, the player's earlier scenes are old news, and
; the levels they already hold are where they are, not events.
Function Joined(Actor akWho)
	If akWho == None || !Self.Counts(akWho) || !Self.RapportReady()
		Return
	EndIf
	Self.SetMark(akWho, LAST_TICK_AV_ID, Utility.GetCurrentGameTime())
	Self.Watermarks(akWho)
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	If a.KnowsAffinity(akWho)
		Int now = Self.Tier(a.Affinity(akWho))
		If now > Self.Mark(akWho, TIER_AV_ID) as Int
			Self.SetMark(akWho, TIER_AV_ID, now as Float)
		EndIf
		If now < 0
			Self.SetMark(akWho, FALL_AV_ID, now as Float)
		EndIf
	EndIf
	Debug.Trace("Overture companions: " + akWho.GetFormID() + " joined (" + a.Name() + ")", 0)
EndFunction

; They are not the companion any more: wanting is not kept for someone away (the
; published value reads 0 for them).
Function Left(Actor akWho)
	If akWho != None && Self.Desires(akWho)
		Self.SetMark(akWho, DESIRE_AV_ID, 0.0)
	EndIf
EndFunction

; The player's scene counts as this companion knows them now.
Function Watermarks(Actor akWho)
	Int p = Game.GetPlayer().GetFormID()
	Int pair = Rapport:Core.PairSceneCount(p, akWho.GetFormID())
	Self.SetMark(akWho, PAIR_SEEN_AV_ID, (pair + 1) as Float)
	Self.SetMark(akWho, SEEN_SCENE_AV_ID, (Rapport:Core.SceneCount(p) - pair + 1) as Float)
EndFunction

; The tick, for the CURRENT companion, on Moments' clock. The store and wanting move
; at most once a game day; jealousy and their levels are read every tick.
Function Tick(Actor akWho)
	If akWho == None || !Self.Enabled() || !Self.Registry().IsCurrentCompanion(akWho) || !Self.Counts(akWho) || !Self.RapportReady()
		Return
	EndIf
	Float today = Utility.GetCurrentGameTime()
	Float last = Self.Mark(akWho, LAST_TICK_AV_ID)
	If last <= 0.0
		Self.SetMark(akWho, LAST_TICK_AV_ID, today)
	ElseIf today - last >= 1.0
		; A day has passed: counted once, and the rest of a long absence dropped.
		Self.SetMark(akWho, LAST_TICK_AV_ID, today)
		If Self.Together(akWho)
			Self.Feed(akWho, Self.Tuned("fTogetherPerDay:Companions", 0.01))
			Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
			If Self.Won(akWho, a)
				Self.SetDesire(akWho, Self.Desire(akWho) + Self.Tuned("fDesirePerDay:Companions", 0.10))
			EndIf
		EndIf
	EndIf
	Self.Thresholds(akWho)
	Self.Jealousy(akWho)
	Self.OwnRomance(akWho)
EndFunction

; O-36 (owner, 2026-09-23): their OWN romance -- vanilla's romance success, Ivy's love
; flag -- makes them the player's lover to the world, as a bond of 0.75 and a scene
; together does (O-27): Chemistry treats them as spoken for from then on. Rapport
; refuses it at a falling-out (O-28), and ends it there too; their own story ending
; (Ivy's breakup) does not end it here -- the fall-out rule is the one way out.
Function OwnRomance(Actor akWho)
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	If a == None || !a.IsRomanced(akWho)
		Return
	EndIf
	Int p = Game.GetPlayer().GetFormID()
	Int id = akWho.GetFormID()
	If Rapport:Core.AreLovers(p, id)
		Return
	EndIf
	Rapport:Core.SetLovers(p, id, True)
	If Rapport:Core.AreLovers(p, id)
		Rapport:Core.NarrateLine(p, id, "Word gets around - you and {second} are a couple now.", "")
		Debug.Trace("Overture companions: " + id + " is romanced by their own romance - lovers to the world (O-36)", 0)
	EndIf
EndFunction

Function Thresholds(Actor akWho)
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	If a == None || !a.KnowsAffinity(akWho)
		Return
	EndIf
	Int now = Self.Tier(a.Affinity(akWho))
	; Up: a level never reached before. Written before the events: a second look
	; finds nothing new.
	Int high = Self.Mark(akWho, TIER_AV_ID) as Int
	If now > high
		Self.SetMark(akWho, TIER_AV_ID, now as Float)
		Debug.Trace("Overture companions: " + akWho.GetFormID() + "'s own affinity reached level " + now + " for the first time", 0)
		While high < now
			high += 1
			Self.Feed(akWho, Self.Tuned("fThresholdUp:Companions", 0.08))
		EndWhile
	EndIf
	; Down: Disdain, then Hatred, once per fall; back at Neutral re-arms it.
	Int fall = Self.Mark(akWho, FALL_AV_ID) as Int
	If now >= 0
		If fall != 0
			Self.SetMark(akWho, FALL_AV_ID, 0.0)
		EndIf
	ElseIf now < fall
		Self.SetMark(akWho, FALL_AV_ID, now as Float)
		Debug.Trace("Overture companions: " + akWho.GetFormID() + "'s own affinity fell to level " + now, 0)
		While fall > now
			fall -= 1
			Self.Feed(akWho, Self.Tuned("fThresholdDown:Companions", -0.08))
		EndWhile
	EndIf
EndFunction

; A fight survived together: Moments hears the companion leave combat. One a day,
; and only near the player.
Function SurvivedTogether(Actor akWho)
	If !Self.Enabled() || !Self.Counts(akWho) || !Self.RapportReady()
		Return
	EndIf
	Actor player = Game.GetPlayer()
	If player.IsDead() || !akWho.Is3DLoaded() || akWho.GetDistance(player) > FIGHT_RANGE
		Return
	EndIf
	Float today = Math.Floor(Utility.GetCurrentGameTime())
	If today == _fightDay
		Return
	EndIf
	_fightDay = today
	Self.Feed(akWho, FIGHT_SURVIVED)
EndFunction

; The player's scenes since this companion last looked, in whole counts (Rapport's
; SceneCount and PairSceneCount), not game hours: a float hour stamp loses its
; precision in an old save (microscope wave 3).
Function Jealousy(Actor akWho)
	Actor player = Game.GetPlayer()
	Int p = player.GetFormID()
	Int id = akWho.GetFormID()
	Int pair = Rapport:Core.PairSceneCount(p, id)
	Int others = Rapport:Core.SceneCount(p) - pair
	Int knownPair = (Self.Mark(akWho, PAIR_SEEN_AV_ID) as Int) - 1
	Int knownOthers = (Self.Mark(akWho, SEEN_SCENE_AV_ID) as Int) - 1
	; Written before anything else can run: a second look finds nothing new.
	Self.Watermarks(akWho)
	If knownPair >= 0 && pair > knownPair
		; With them: Rapport's RecordScene already wrote the bond. Sated.
		Self.SetDesire(akWho, 0.0)
		Debug.Trace("Overture companions: " + id + " had a scene with the player - wanting back to 0", 0)
	EndIf
	If knownOthers < 0 || others <= knownOthers
		Return
	EndIf
	; Whose business is it? Their own romance, or Rapport's lovers -- the companion
	; side of O-29's "counts only after they became lovers".
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	If !a.IsRomanced(akWho) && !Rapport:Core.AreLovers(p, id)
		Return
	EndIf
	String persona = Rapport:Core.PersonaOf(id)
	If persona == "romantic" || persona == "reticent"
		Self.Feed(akWho, Self.Tuned("fJealousySting:Jealousy", -0.06))
		Rapport:Core.NarrateLine(p, id, "{second} heard you've been with someone else. It stung.", "")
	ElseIf persona == "vulgar"
		Self.Feed(akWho, Self.Tuned("fJealousyThrill:Jealousy", 0.03))
		Self.SetDesire(akWho, Self.Desire(akWho) + THRILLED)
		Rapport:Core.NarrateLine(p, id, "{second} heard you've been with someone else - and liked hearing it.", "")
	EndIf
	Debug.Trace("Overture companions: " + id + " heard about the player's scene with someone else (" + persona + ")", 0)
EndFunction

; How much they must want it, by persona (Rapport's), less the romanced ease, plus
; what being spoken for costs (methodology 7, as for everyone).
Float Function Bar(Actor akWho, Overture:Companions:Adapter akAdapter)
	String persona = Rapport:Core.PersonaOf(akWho.GetFormID())
	Float bar = 0.5
	If persona == "mercantile"
		bar = Self.Tuned("fDesireMercantile:Companions", 0.50)
	ElseIf persona == "romantic"
		bar = Self.Tuned("fDesireRomantic:Companions", 0.50)
	ElseIf persona == "vulgar"
		bar = Self.Tuned("fDesireVulgar:Companions", 0.30)
	ElseIf persona == "reticent"
		bar = Self.Tuned("fDesireReticent:Companions", 0.70)
	EndIf
	If akAdapter.IsRomanced(akWho)
		bar -= Self.Tuned("fRomancedEase:Companions", 0.20)
	EndIf
	Overture:Approach approach = Self.Overture()
	If approach != None && approach.SpokenFor(akWho)
		bar += Self.Tuned("fFaithWeight:SpokenFor", 0.40) * Rapport:Core.FaithfulnessOf(akWho.GetFormID())
	EndIf
	Return bar
EndFunction

; The companion's half of a verdict: their gates first (C2, O-22), then wanting.
; GATE_* above; LastGateNote says why, for the trace. (Faithfulness sits between
; UNWON and WANTING in Approach.CompanionVerdict, as methodology 2 orders refusals.)
Int Function Gate(Actor akWho)
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	If a == None || a.Refuses(akWho) || a.Closed(akWho)
		_gateNote = "their own state says no"
		Return GATE_STATE
	EndIf
	If !Self.Won(akWho, a)
		If a.HasRomance(akWho)
			_gateNote = "not romanced, by their own romance"
		Else
			_gateNote = "their own affinity " + a.Affinity(akWho) + " is under the gate"
		EndIf
		Return GATE_UNWON
	EndIf
	; A companion with arousal of their own is asked their own question.
	If a.HasOwnArousal(akWho)
		If a.Wants(akWho)
			_gateNote = "their own arousal says yes"
			Return GATE_PASS
		EndIf
		_gateNote = "their own arousal says not yet"
		Return GATE_WANTING
	EndIf
	Float bar = Self.Bar(akWho, a)
	Float wanting = Self.Desire(akWho)
	If wanting < bar
		_gateNote = "wanting " + wanting + " under " + bar
		Return GATE_WANTING
	EndIf
	_gateNote = "wanting " + wanting + " over " + bar
	Return GATE_PASS
EndFunction

String Function LastGateNote()
	Return _gateNote
EndFunction
