Scriptname Overture:Companions:Feeders extends Quest
{B-LITE (O-19): THE STORE IS THE RELATIONSHIP; COMPANIONS FEED IT EVENTS.

  THE RELATIONSHIP  Rapport's player<->companion bond, and nothing else. Every
                    companion-only modifier below is an EVENT written into it in the
                    store's own units -- R-10's "add this much, for this reason",
                    R-2's "import, do not mirror". No axis of ours shadows it, so
                    Chemistry, the Narrator and any third mod read the number
                    Overture reads.
  THEIR OWN GATES   their adapter: affinity, romance, anger, the closed door. Read,
                    never written (C5; O-24: only Rapport's store moves).
  ONE STATE OF OURS WANTING (Desire, 0..1, AVIF 0x851 -- PUBLISHED: fo4-anatomy
                    reads it): it builds with days on the road together, spikes
                    when their own system's arousal rises, and falls after a scene
                    together. A state, not a closeness -- wanting someone less the
                    morning after is not the relationship getting worse -- so it
                    gates the yes and never touches the store.

THE FEEDERS (every size ASSUMED, fractions of the distance left, MCM-tunable):
  their affinity reaches a level        fThresholdUp per level (Friend 250,
                                        Admiration 500, Confidant 750,
                                        Infatuation 1000, normalised)
  ... and loses one                     fThresholdDown per level
  a game day travelling together        fTogetherPerDay (a day per tick at most)
  a fight survived together             FIGHT_SURVIVED, three a day at most
  the player with someone else          ONLY for someone it is their business:
                                        romanced by their own romance, or
                                        Rapport's lovers. Romantic and reticent:
                                        fJealousySting against the bond; vulgar:
                                        wanting rises; mercantile shrugs (O-29's
                                        table, which methodology 11 wrote first)
  a scene with the player               Rapport's own RecordScene writes the bond;
                                        here only wanting falls

ONLY for a companion an adapter claims (vanilla, Ivy): the engine fallback vouches
for nothing (C6), and a mod companion's days are not ours to count.}

Int Property APPROACH_QUEST_ID = 0x00000800 AutoReadOnly
Int Property DESIRE_AV_ID = 0x00000851 AutoReadOnly
Int Property LAST_TICK_AV_ID = 0x00000856 AutoReadOnly
Int Property SEEN_SCENE_AV_ID = 0x0000085A AutoReadOnly
Int Property TIER_AV_ID = 0x0000085B AutoReadOnly
; R-10's reasons: 3 dialogue, 4 gift, 5 any other addon.
Int Property REASON_ADDON = 5 AutoReadOnly
Int Property NEEDS_API = 201 AutoReadOnly

Float Property FIGHT_SURVIVED = 0.005 AutoReadOnly
Int Property FIGHTS_PER_DAY = 3 AutoReadOnly
Float Property MAX_DAYS_PER_TICK = 1.0 AutoReadOnly
; Wanting's own moves (ASSUMED).
Float Property SATED = -0.6 AutoReadOnly
Float Property THRILLED = 0.1 AutoReadOnly
Float Property AROUSED = 0.2 AutoReadOnly
; No scene yet: HoursSinceScene answers a huge number, not a negative.
Float Property NEVER = 100000000.0 AutoReadOnly

; What Gate decided. PASS: their gates are open and they want it. STATE: their own
; state says no right now (C2). UNWON: their own romance is not done, or their
; affinity is under the gate (O-22). WANTING: not wanting it enough yet.
Int Property GATE_PASS = 0 AutoReadOnly
Int Property GATE_STATE = 1 AutoReadOnly
Int Property GATE_UNWON = 2 AutoReadOnly
Int Property GATE_WANTING = 3 AutoReadOnly

Int _fightsToday = 0
Float _fightDay = -1.0
String _gateNote = ""

Overture:Companions:Registry Function Registry()
	Return (Self as Quest) as Overture:Companions:Registry
EndFunction

; The approach's quest, for its settings (one Tuned, one guard: Approach.HasSettings).
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

ActorValue Function OurAV(Int aiID)
	Return Game.GetFormFromFile(aiID, "Overture.esp") as ActorValue
EndFunction

Bool Function RapportReady()
	Return Rapport:Core.ApiVersion() >= NEEDS_API
EndFunction

; Whether this companion's days, fights and levels are ours to count at all.
Bool Function Counts(Actor akWho)
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	Return a != None && a.Name() != "engine"
EndFunction

; One event into the store, in its own units: "add this much, for this reason".
Function Feed(Actor akWho, Float afAmount)
	If akWho == None || afAmount == 0.0
		Return
	EndIf
	Rapport:Relations.AddBondBetween(Game.GetPlayer(), akWho, afAmount, REASON_ADDON)
EndFunction

Function MoveDesire(Actor akWho, Float afBy)
	ActorValue av = Self.OurAV(DESIRE_AV_ID)
	If akWho == None || av == None
		Return
	EndIf
	Float d = akWho.GetValue(av) + afBy
	If d < 0.0
		d = 0.0
	ElseIf d > 1.0
		d = 1.0
	EndIf
	akWho.SetValue(av, d)
EndFunction

Float Function Desire(Actor akWho)
	ActorValue av = Self.OurAV(DESIRE_AV_ID)
	If akWho == None || av == None
		Return 0.0
	EndIf
	Return akWho.GetValue(av)
EndFunction

; Their affinity's level, 0 (below Friend) .. 4 (Infatuation), normalised the way
; every adapter reports affinity (-1..1, Infatuation at 1).
Int Function Tier(Float afAffinity)
	If afAffinity >= 1.0
		Return 4
	ElseIf afAffinity >= 0.75
		Return 3
	ElseIf afAffinity >= 0.5
		Return 2
	ElseIf afAffinity >= 0.25
		Return 1
	EndIf
	Return 0
EndFunction

; Recruited: time together starts now, the player's earlier scenes are old news,
; and their level as it stands is where they already are, not an event.
Function Joined(Actor akWho)
	ActorValue lastAV = Self.OurAV(LAST_TICK_AV_ID)
	ActorValue seenAV = Self.OurAV(SEEN_SCENE_AV_ID)
	ActorValue tierAV = Self.OurAV(TIER_AV_ID)
	If akWho == None || lastAV == None || seenAV == None || tierAV == None || !Self.Counts(akWho)
		Return
	EndIf
	akWho.SetValue(lastAV, Utility.GetCurrentGameTime())
	If Self.RapportReady()
		Float since = Rapport:Core.HoursSinceScene(Game.GetPlayer().GetFormID())
		If since < NEVER
			akWho.SetValue(seenAV, Utility.GetCurrentGameTime() * 24.0 - since)
		EndIf
	EndIf
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	If a.KnowsAffinity(akWho)
		akWho.SetValue(tierAV, Self.Tier(a.Affinity(akWho)) as Float)
	EndIf
	Debug.Trace("Overture companions: " + akWho.GetFormID() + " joined (" + a.Name() + ")", 0)
EndFunction

; The slow tick, for the CURRENT companion: days together, their affinity's levels,
; wanting building, jealousy. Any real-time rate; it works in game days.
Function Tick(Actor akWho)
	If akWho == None || !Self.Registry().IsCurrentCompanion(akWho) || !Self.Counts(akWho) || !Self.RapportReady()
		Return
	EndIf
	ActorValue lastAV = Self.OurAV(LAST_TICK_AV_ID)
	If lastAV == None
		Return
	EndIf
	Float today = Utility.GetCurrentGameTime()
	Float last = akWho.GetValue(lastAV)
	akWho.SetValue(lastAV, today)
	If last > 0.0 && today > last
		Float days = today - last
		If days > MAX_DAYS_PER_TICK
			days = MAX_DAYS_PER_TICK
		EndIf
		Self.Feed(akWho, Self.Tuned("fTogetherPerDay:Companions", 0.01) * days)
		Self.MoveDesire(akWho, Self.Tuned("fDesirePerDay:Companions", 0.10) * days)
	EndIf
	Self.Thresholds(akWho)
	Self.Jealousy(akWho)
EndFunction

Function Thresholds(Actor akWho)
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	ActorValue tierAV = Self.OurAV(TIER_AV_ID)
	If a == None || tierAV == None || !a.KnowsAffinity(akWho)
		Return
	EndIf
	Int now = Self.Tier(a.Affinity(akWho))
	Int was = akWho.GetValue(tierAV) as Int
	If now == was
		Return
	EndIf
	; Written before the events: a second look finds nothing new.
	akWho.SetValue(tierAV, now as Float)
	Debug.Trace("Overture companions: " + akWho.GetFormID() + "'s own affinity went from level " + was + " to " + now, 0)
	While was < now
		Self.Feed(akWho, Self.Tuned("fThresholdUp:Companions", 0.05))
		was += 1
	EndWhile
	While was > now
		Self.Feed(akWho, Self.Tuned("fThresholdDown:Companions", -0.08))
		was -= 1
	EndWhile
EndFunction

; A fight survived together: Moments hears the companion leave combat, both alive.
Function SurvivedTogether(Actor akWho)
	If !Self.Counts(akWho) || !Self.RapportReady()
		Return
	EndIf
	Float today = Math.Floor(Utility.GetCurrentGameTime())
	If today != _fightDay
		_fightDay = today
		_fightsToday = 0
	EndIf
	If _fightsToday >= FIGHTS_PER_DAY
		Return
	EndIf
	_fightsToday += 1
	Self.Feed(akWho, FIGHT_SURVIVED)
EndFunction

; A scene of the player's since this companion last looked, per companion.
Function Jealousy(Actor akWho)
	ActorValue seenAV = Self.OurAV(SEEN_SCENE_AV_ID)
	If seenAV == None
		Return
	EndIf
	Actor player = Game.GetPlayer()
	Int p = player.GetFormID()
	Float since = Rapport:Core.HoursSinceScene(p)
	Float at = Utility.GetCurrentGameTime() * 24.0 - since
	If since >= NEVER || at <= akWho.GetValue(seenAV) + 0.01
		Return
	EndIf
	akWho.SetValue(seenAV, at)
	If Rapport:Core.LastPartner(p) == akWho.GetFormID()
		; With them: Rapport's RecordScene already wrote the bond. Sated.
		Self.MoveDesire(akWho, SATED)
		Debug.Trace("Overture companions: " + akWho.GetFormID() + " was the player's last scene - sated", 0)
		Return
	EndIf
	; Whose business is it? Someone romanced by their own romance, or Rapport's lovers
	; -- the companion side of O-29's "counts only after they became lovers".
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	If !a.IsRomanced(akWho) && !Rapport:Core.AreLovers(p, akWho.GetFormID())
		Return
	EndIf
	String persona = Rapport:Core.PersonaOf(akWho.GetFormID())
	If persona == "romantic" || persona == "reticent"
		Self.Feed(akWho, Self.Tuned("fJealousySting:Jealousy", -0.06))
		Debug.Trace("Overture companions: " + akWho.GetFormID() + " heard about the player's scene with someone else - it stung", 0)
	ElseIf persona == "vulgar"
		Self.MoveDesire(akWho, THRILLED)
		Debug.Trace("Overture companions: " + akWho.GetFormID() + " heard about the player's scene with someone else - and liked it", 0)
	EndIf
EndFunction

; Their own system's arousal RISING is a spike (the edge, not the level).
Function Aroused(Actor akWho)
	Self.MoveDesire(akWho, AROUSED)
EndFunction

; How much they must want it, by persona (Rapport's), less the romanced ease.
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
	Return bar
EndFunction

; The companion's half of a verdict: their gates first (C2, O-22), then wanting.
; GATE_* above; LastGateNote says why, for the trace.
Int Function Gate(Actor akWho)
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	If a == None || a.Refuses(akWho) || a.Closed(akWho)
		_gateNote = "their own state says no"
		Return GATE_STATE
	EndIf
	If a.HasRomance(akWho)
		If !a.IsRomanced(akWho)
			_gateNote = "not romanced, by their own romance"
			Return GATE_UNWON
		EndIf
	Else
		Float gate = Self.Tuned("fAffinityGate:Companions", 1.00)
		If !a.KnowsAffinity(akWho) || a.Affinity(akWho) < gate
			_gateNote = "their own affinity " + a.Affinity(akWho) + " is under " + gate
			Return GATE_UNWON
		EndIf
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
