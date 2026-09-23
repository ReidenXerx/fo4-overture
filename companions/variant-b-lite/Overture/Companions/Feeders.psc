Scriptname Overture:Companions:Feeders extends Quest
{VARIANT B-LITE -- THE STORE IS THE RELATIONSHIP; COMPANIONS FEED IT EVENTS.

The design review's middle path (2026-09-23), and the recommendation. It keeps
what makes a companion unique (N-7's "bunch unique modifiers") and drops what
made variant B a second opinion of closeness beside the store (R-1):

  THE RELATIONSHIP  Rapport's player<->companion bond, and nothing else. Every
                    companion-only modifier below is an EVENT written into it in
                    the store's own units -- R-10's "add this much, for this
                    reason", R-2's "import, do not mirror". No axis of ours
                    shadows it, so Chemistry, the Narrator and any third mod
                    read the same number Overture does.
  THEIR OWN GATES   their adapter: affinity (vanilla CA_Affinity, Ivy's own),
                    romance, anger, the closed door. Read, never written (C5).
  ONE STATE OF OURS DESIRE, 0..1 on the companion: it builds with days together
                    since the last scene with the player, spikes when their own
                    system is aroused, and falls when sated. A state, not a
                    closeness -- wanting someone less after a night together is
                    not the relationship getting worse -- so it gates moments
                    and never touches the store.

THE FEEDERS (all ASSUMED sizes, fractions of the distance left):
  their affinity crosses a threshold UP   +0.05 per threshold (Friend 250,
                                          Admiration 500, Confidant 750,
                                          Infatuation 1000, normalised)
  ... and DOWN                            -0.08 per threshold
  a game day travelling together          +0.01 (one day per tick at most)
  a fight survived together               +0.005, three a day at most
  the player with someone else            the companion's persona: -0.03 for
                                          romantic and reticent; for vulgar,
                                          desire rises instead; mercantile shrugs
  a scene with the player                 Rapport's own RecordScene writes it;
                                          here only desire falls

SCAFFOLD (2026-09-23): not in the shipping plugin. Needs, in Overture.esp:
AVIF OvertureCompanionDesire (0x851), OvertureCompanionLastTick (0x856),
OvertureCompanionSeenScene (0x85A), OvertureCompanionAffinityTier (0x85B), this
script on the companions quest (0x855) with the common adapters.}

Int Property DESIRE_AV_ID = 0x00000851 AutoReadOnly
Int Property LAST_TICK_AV_ID = 0x00000856 AutoReadOnly
Int Property SEEN_SCENE_AV_ID = 0x0000085A AutoReadOnly
Int Property TIER_AV_ID = 0x0000085B AutoReadOnly
Int Property REASON_ADDON = 5 AutoReadOnly

Float Property TIER_UP = 0.05 AutoReadOnly
Float Property TIER_DOWN = -0.08 AutoReadOnly
Float Property PER_DAY_TOGETHER = 0.01 AutoReadOnly
Float Property FIGHT_SURVIVED = 0.005 AutoReadOnly
Int Property FIGHTS_PER_DAY = 3 AutoReadOnly
Float Property JEALOUSY = -0.03 AutoReadOnly
Float Property DESIRE_PER_DAY = 0.10 AutoReadOnly
Float Property MAX_DAYS_PER_TICK = 1.0 AutoReadOnly

Int _fightsToday = 0
Float _fightDay = -1.0

Overture:Companions:Registry Function Registry()
	Return (Self as Quest) as Overture:Companions:Registry
EndFunction

ActorValue Function OurAV(Int aiID)
	Return Game.GetFormFromFile(aiID, "Overture.esp") as ActorValue
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

; Their affinity's threshold, 0 (below Friend) .. 4 (Infatuation), normalised
; the way every adapter reports affinity (-1..1, Infatuation at 1).
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

; Recruited: time together starts now, and the player's earlier scenes are old news.
Function Joined(Actor akWho)
	ActorValue lastAV = Self.OurAV(LAST_TICK_AV_ID)
	ActorValue seenAV = Self.OurAV(SEEN_SCENE_AV_ID)
	ActorValue tierAV = Self.OurAV(TIER_AV_ID)
	If akWho == None || lastAV == None || seenAV == None || tierAV == None
		Return
	EndIf
	akWho.SetValue(lastAV, Utility.GetCurrentGameTime())
	Float since = Rapport:Core.HoursSinceScene(Game.GetPlayer().GetFormID())
	If since < 100000000.0
		akWho.SetValue(seenAV, Utility.GetCurrentGameTime() * 24.0 - since)
	EndIf
	; Their tier as it stands is where they already are, not an event.
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	If a != None && a.KnowsAffinity(akWho)
		akWho.SetValue(tierAV, Self.Tier(a.Affinity(akWho)) as Float)
	EndIf
EndFunction

; The slow tick, for the CURRENT companion: days together, their affinity's
; thresholds, desire building, jealousy. Any real-time rate; it works in game days.
Function Tick(Actor akWho)
	If akWho == None || !Self.Registry().IsCurrentCompanion(akWho)
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
		Self.Feed(akWho, PER_DAY_TOGETHER * days)
		Self.MoveDesire(akWho, DESIRE_PER_DAY * days)
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
	akWho.SetValue(tierAV, now as Float)
	While was < now
		Self.Feed(akWho, TIER_UP)
		was += 1
	EndWhile
	While was > now
		Self.Feed(akWho, TIER_DOWN)
		was -= 1
	EndWhile
EndFunction

; A fight survived together. Hook from Actor.OnCombatStateChanged on the
; companion (left combat, both alive).
Function SurvivedTogether(Actor akWho)
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
	Int player = Game.GetPlayer().GetFormID()
	Float since = Rapport:Core.HoursSinceScene(player)
	Float at = Utility.GetCurrentGameTime() * 24.0 - since
	If since > 100000000.0 || at <= akWho.GetValue(seenAV) + 0.01
		Return
	EndIf
	akWho.SetValue(seenAV, at)
	If Rapport:Core.LastPartner(player) == akWho.GetFormID()
		; With them: Rapport's RecordScene already wrote the bond. Sated.
		Self.MoveDesire(akWho, -0.6)
		Return
	EndIf
	String persona = Rapport:Core.PersonaOf(akWho.GetFormID())
	If persona == "romantic" || persona == "reticent"
		Self.Feed(akWho, JEALOUSY)
	ElseIf persona == "vulgar"
		Self.MoveDesire(akWho, 0.1)
	EndIf
EndFunction

; Their own system's arousal RISING is a spike (the edge, not the level).
Function Aroused(Actor akWho)
	Self.MoveDesire(akWho, 0.2)
EndFunction

; A yes: their gates first (C2), then desire over the persona's bar. ASSUMED bars.
Bool Function WouldSayYes(Actor akWho)
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	If a == None || a.Refuses(akWho) || a.Closed(akWho)
		Return False
	EndIf
	String persona = Rapport:Core.PersonaOf(akWho.GetFormID())
	Float bar = 0.5
	If persona == "vulgar"
		bar = 0.3
	ElseIf persona == "reticent"
		bar = 0.7
	EndIf
	If a.IsRomanced(akWho)
		bar -= 0.2
	EndIf
	Return Self.Desire(akWho) >= bar
EndFunction
