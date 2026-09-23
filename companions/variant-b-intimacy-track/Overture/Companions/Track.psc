Scriptname Overture:Companions:Track extends Quest
{VARIANT B -- A RELATIONSHIP SYSTEM OF THEIR OWN, BOUND TO THE STORE.

The owner's words (N-7): "companions will have standalone unique relationship
system; it will also bound to relationship db but will have bunch unique
modifiers". Three axes of Overture's own, as actor values on the companion --
saved with the actor, written only for companions (R-5 for free):

  TRUST     they rely on you      fed by their affinity rising or falling, fights
                                  survived together
  DESIRE    they want you         builds day by day since your last scene
                                  together, spikes on their own system's arousal
                                  (Ivy), falls when sated
  DEVOTION  they are yours        days travelling together, scenes together;
                                  falls when you are with someone else

BOUND TO THE STORE: every change of TRUST or DEVOTION is also added to
Rapport's player<->companion bond (R-10, reason 5), so Chemistry, the Narrator
and any third mod see one number. DESIRE is a state, not a bond -- wanting
someone less after a night together is not the relationship getting worse --
so it gates moments and never touches the store.

THE UNIQUE MODIFIERS, one per feeder below, are what no ordinary NPC has: time
in the party, danger shared, jealousy, their own affinity system, their own
arousal.

JEALOUSY needs no new Rapport API. The player is an ordinary actor in Rapport's
ledger (R-11), so LastPartner(player) and HoursSinceScene(player) already say
"the player was with someone else, this long ago". How much it stings is the
COMPANION's persona: romantic and reticent lose devotion, mercantile shrugs,
vulgar is aroused by it. ASSUMED, all of it -- the owner's poll.

THE CASE AGAINST THIS VARIANT (design review 2026-09-23, and it is a fair one):
TRUST and DEVOTION are Overture's own opinion of how close two people are, kept
beside the store -- R-1 exists to prevent exactly "two mods keeping separate
opinions of whether two NPCs are close". Variant B-lite keeps DESIRE (a state,
not a closeness) and feeds the store with EVENTS instead; it is the
recommendation. This one stays as the heavier option for the owner to weigh.

SCAFFOLD (2026-09-23): not in the shipping plugin. Needs, in Overture.esp:
AVIF OvertureCompanionTrust / Desire / Devotion (reserved 0x850-0x852),
OvertureCompanionLastTick (0x856, game days), OvertureCompanionSeenScene
(0x85A, game hours), this script on the companions quest (0x855), and a timer
started when a companion is recruited.}

Int Property TRUST_AV_ID = 0x00000850 AutoReadOnly
Int Property DESIRE_AV_ID = 0x00000851 AutoReadOnly
Int Property DEVOTION_AV_ID = 0x00000852 AutoReadOnly
Int Property LAST_TICK_AV_ID = 0x00000856 AutoReadOnly
; Per COMPANION: the time of the player's last scene this companion has already
; reacted to. One script-wide watermark made a new recruit jealous of a scene from
; before they ever joined (design review 2026-09-23).
Int Property SEEN_SCENE_AV_ID = 0x0000085A AutoReadOnly
Int Property REASON_ADDON = 5 AutoReadOnly
; A tick never accrues more than this, in days: time APART is not time together.
Float Property MAX_DAYS_PER_TICK = 1.0 AutoReadOnly

; Per game day. ASSUMED: tuned so a companion who travels with you and is never
; cheated on reaches DEVOTION 0.5 in about three weeks of game time.
Float Property DEVOTION_PER_DAY = 0.03 AutoReadOnly
Float Property DESIRE_PER_DAY = 0.10 AutoReadOnly
Float Property TRUST_PER_AFFINITY = 1.0 AutoReadOnly
Float Property JEALOUSY = 0.10 AutoReadOnly

Overture:Companions:Registry Function Registry()
	Return (Self as Quest) as Overture:Companions:Registry
EndFunction

ActorValue Function OurAV(Int aiID)
	Return Game.GetFormFromFile(aiID, "Overture.esp") as ActorValue
EndFunction

Float Function Clamp01(Float afValue)
	If afValue < 0.0
		Return 0.0
	ElseIf afValue > 1.0
		Return 1.0
	EndIf
	Return afValue
EndFunction

; Move one axis, and -- for TRUST and DEVOTION -- the store with it.
Function Move(Actor akWho, Int aiAxisID, Float afBy)
	ActorValue av = Self.OurAV(aiAxisID)
	If akWho == None || av == None || afBy == 0.0
		Return
	EndIf
	Float before = akWho.GetValue(av)
	Float after = Self.Clamp01(before + afBy)
	akWho.SetValue(av, after)
	If aiAxisID != DESIRE_AV_ID && after != before
		; Half the axis move, EXACTLY: AddBondBetween's amount is a fraction of the
		; distance left, so a raw +x then -x would not come back (see
		; AffinityMirror.ExactAmount, and the review's -0.016).
		Actor player = Game.GetPlayer()
		Float amount = Self.ExactAmount(Rapport:Relations.BondBetween(player, akWho), (after - before) * 0.5)
		If amount != 0.0
			Rapport:Relations.AddBondBetween(player, akWho, amount, REASON_ADDON)
		EndIf
	EndIf
EndFunction

Float Function ExactAmount(Float afBond, Float afDelta)
	If afDelta > 0.0
		If afBond >= 1.0
			Return 0.0
		EndIf
		Float up = afDelta / (1.0 - afBond)
		If up > 1.0
			Return 1.0
		EndIf
		Return up
	EndIf
	If afBond <= -1.0
		Return 0.0
	EndIf
	Float down = afDelta / (1.0 + afBond)
	If down < -1.0
		Return -1.0
	EndIf
	Return down
EndFunction

Float Function Axis(Actor akWho, Int aiAxisID)
	ActorValue av = Self.OurAV(aiAxisID)
	If akWho == None || av == None
		Return 0.0
	EndIf
	Return akWho.GetValue(av)
EndFunction

; The slow tick, for the CURRENT companion only: days together, desire building,
; their affinity's movement, and jealousy. Call it from a real-time timer (every
; minute is plenty) -- it works in game days, so the rate does not matter.
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
	If last <= 0.0 || today <= last
		Return
	EndIf
	Float days = today - last
	; LastTick only moves while they travel with the player, so the first tick
	; after a month apart would otherwise count the month (review 2026-09-23).
	; Joined() resets it; the cap is the belt to that brace.
	If days > MAX_DAYS_PER_TICK
		days = MAX_DAYS_PER_TICK
	EndIf

	; Days together.
	Self.Move(akWho, DEVOTION_AV_ID, DEVOTION_PER_DAY * days)

	; Desire builds with time since your last scene together, and a scene with
	; the player resets it (below, in the jealousy check's twin).
	Self.Move(akWho, DESIRE_AV_ID, DESIRE_PER_DAY * days)

	; Their own system's arousal is a spike, not a rate.
	Overture:Companions:Adapter a = Self.Registry().AdapterFor(akWho)
	If a != None && a.Wants(akWho)
		Self.Move(akWho, DESIRE_AV_ID, 0.2)
	EndIf

	Self.Jealousy(akWho)
EndFunction

; A new scene for the player since the last look: with this companion, desire
; is sated and devotion grows; with anyone else, the companion's persona decides.
; Recruited (FollowersScript's CompanionChange event): time together starts NOW,
; and every scene the player had before they joined is already old news.
Function Joined(Actor akWho)
	ActorValue lastAV = Self.OurAV(LAST_TICK_AV_ID)
	ActorValue seenAV = Self.OurAV(SEEN_SCENE_AV_ID)
	If akWho == None || lastAV == None || seenAV == None
		Return
	EndIf
	akWho.SetValue(lastAV, Utility.GetCurrentGameTime())
	Float since = Rapport:Core.HoursSinceScene(Game.GetPlayer().GetFormID())
	If since < 100000000.0
		akWho.SetValue(seenAV, Utility.GetCurrentGameTime() * 24.0 - since)
	EndIf
EndFunction

Function Jealousy(Actor akWho)
	ActorValue seenAV = Self.OurAV(SEEN_SCENE_AV_ID)
	If seenAV == None
		Return
	EndIf
	Int player = Game.GetPlayer().GetFormID()
	Float since = Rapport:Core.HoursSinceScene(player)
	Float at = Utility.GetCurrentGameTime() * 24.0 - since
	; "Never" comes back as infinity. Papyrus has no exponent syntax, hence the digits.
	If since > 100000000.0 || at <= akWho.GetValue(seenAV) + 0.01
		Return
	EndIf
	akWho.SetValue(seenAV, at)
	If Rapport:Core.LastPartner(player) == akWho.GetFormID()
		Self.Move(akWho, DESIRE_AV_ID, -0.6)
		Self.Move(akWho, DEVOTION_AV_ID, 0.05)
		Return
	EndIf
	String persona = Rapport:Core.PersonaOf(akWho.GetFormID())
	If persona == "romantic" || persona == "reticent"
		Self.Move(akWho, DEVOTION_AV_ID, -JEALOUSY)
	ElseIf persona == "vulgar"
		Self.Move(akWho, DESIRE_AV_ID, JEALOUSY)
	EndIf
	; mercantile: what you do with your evenings is your business.
EndFunction

; Their affinity moved (vanilla or theirs): trust follows it. Call with the
; change the adapter reports between two looks.
Function AffinityMoved(Actor akWho, Float afChange)
	Self.Move(akWho, TRUST_AV_ID, afChange * TRUST_PER_AFFINITY)
EndFunction

; A fight survived together. Hook from Actor.OnCombatStateChanged on the
; companion (state 0 = left combat, both alive). Capped by the caller per day.
Function SurvivedTogether(Actor akWho)
	Self.Move(akWho, TRUST_AV_ID, 0.01)
EndFunction

; The gates, per the companion's persona: a yes needs DESIRE over the persona's
; bar and enough TRUST to be alone with you. ASSUMED numbers.
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
	Return Self.Axis(akWho, DESIRE_AV_ID) >= bar && Self.Axis(akWho, TRUST_AV_ID) >= 0.2
EndFunction
