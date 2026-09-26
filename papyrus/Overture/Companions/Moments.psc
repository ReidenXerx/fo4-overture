Scriptname Overture:Companions:Moments extends Quest
{C (O-19): THE ENTRY -- A MOMENT, NOT A MENU. And the companion module's clock.

A companion is never approached the way a stranger is (O-8, O-21). Their own talk
menu is theirs -- MEASURED 2026-09-23: every base-game companion's talk scene is
started by a GREETING in their own COM<Name>Talk quest (priority 30), and so is
Ivy's (70) -- and adding an option to it means overriding their records, the one
thing a compatible module must not do (C1). So Overture's own greeting, at 100,
wins only while its conditions pass (tools/overture_stages.py
companion_greetings), and what they read is written here:

  OvertureCompanionMoment (AVIF 0x853) on the current companion
    0  not ours: no adapter vouches for them (C6), they have an intimate scene of
       their own (C3), they are not an adult human or ghoul (O-25), their own state
       says no right now (C2), or Overture is switched off
    1  vouched: the PLAYER may ask (O-23, O-35)
    2  a MOMENT is open: the companion speaks first
    3  the player has just ASKED -- "Ask for a moment" on the companion's prompt, the
       perk OvertureAskPerk (O-35) -- so their next talk opens it (held ASK_DAYS)

A MOMENT (reworked by microscope wave 3; the first build opened one on an edge of
wanting and never re-armed it, so a companion asked once per recruitment):
  OWED   when they want it -- their gates open and their wanting over its bar --
         and the last moment's cooldown is over;
  OPEN   at the first poll after that where they are somewhere private, the day's
         stamp is open (the greeting could fire), and the answer would not be a
         refusal by nature or the romantic's "not now" (Approach.CompanionOpenable:
         methodology 2, an invitation that can only be refused is never made).
         The Narrator says so once -- a hint, never a label (O-11) -- and the window
         runs WINDOW_DAYS from then;
  SPENT  by any answer but "not here" and "not now", which ask for another place or
         another hour and so keep it (and stretch it past the hour O-30 reopens
         at); a window that lapses unused is spent too. Either way the next one is
         owed only after fMomentCooldown game days.

THE CLOCK. One timer, every POLL_SECONDS: who the current companions are, the
feeders' tick, and each one's moment. EVERY current companion, not the follower
system's Companion alias: Amazing Follower Tweaks keeps up to five followers and
rotates that alias among them every 15 seconds, which used to read as "the companion
left" three times a minute and wipe the wanting of each (owner, 2026-09-24). A
companion leaves when they are dismissed (Registry.CurrentAll). Their combat is heard
through their own OnCombatStateChanged.

SEVERAL AT ONCE: each keeps their own moment, window, cooldown and combat. ONE moment
is open at a time -- two companions asking at once is a queue, not a conversation --
and the others stay owed. Fellow companions are not onlookers (owner's call, 2026-09-24,
reversible): they travel with the player, and counting them would mean no companion
is ever alone with the player while others follow.}

Int Property MOMENT_AV_ID = 0x00000853 AutoReadOnly
Int Property NEXT_DAY_AV_ID = 0x00000843 AutoReadOnly
Int Property APPROACH_QUEST_ID = 0x00000800 AutoReadOnly
Int Property MOMENT_NOT_OURS = 0 AutoReadOnly
Int Property MOMENT_VOUCHED = 1 AutoReadOnly
Int Property MOMENT_OPEN = 2 AutoReadOnly
Int Property MOMENT_ASKED = 3 AutoReadOnly
; O-35's perk, given to the player on every load (Hook).
Int Property ASK_PERK_ID = 0x00000859 AutoReadOnly
; How long an ASKED mark waits for the talk it asks for: a few game minutes (about a
; real minute at timescale 20), so a choice made and walked away from does not linger.
Float Property ASK_DAYS = 0.012 AutoReadOnly
Int Property POLL_TIMER = 1 AutoReadOnly
Float Property POLL_SECONDS = 20.0 AutoReadOnly
; Two game hours, in days (GetCurrentGameTime's unit). ASSUMED.
Float Property WINDOW_DAYS = 0.083333 AutoReadOnly
; "Not now" and "not here" reopen an hour later (O-30): the window outlasts that.
Float Property REOPEN_AFTER = 0.041667 AutoReadOnly
Int Property NEEDS_API = 201 AutoReadOnly

; How near a fellow companion must be to have been counted by Rapport's observer scan,
; and so be taken back off it. A COPY of Rapport's scoring.json observerRadius (default
; 900), which Rapport does not publish: change one, change the other. An edited radius
; makes this subtract a companion Rapport never counted, or miss one it did.
Float Property FELLOW_RADIUS = 900.0 AutoReadOnly

; The companions being watched, and each one's state, index for index. A save made
; before AFT support held one companion in a variable that no longer exists; the
; first poll rebuilds these from the follower system, so nothing carries over wrong.
Actor[] _watched
Bool[] _owedEach
Float[] _openUntilEach
Float[] _cooldownEach
Bool[] _inCombatEach
; The last gate each one was logged under. SetMoment's "changed" missed the first
; answer: a companion already at 0 who a gate refuses logged nothing (Ivy, 2026-09-25).
String[] _whyEach
Float _askedAt = 0.0

Overture:Companions:Registry Function Registry()
	Return (Self as Quest) as Overture:Companions:Registry
EndFunction

Overture:Companions:Feeders Function Feeders()
	Return (Self as Quest) as Overture:Companions:Feeders
EndFunction

Overture:Approach Function Overture()
	Return Game.GetFormFromFile(APPROACH_QUEST_ID, "Overture.esp") as Overture:Approach
EndFunction

ActorValue Function OurAV(Int aiID)
	Return Game.GetFormFromFile(aiID, "Overture.esp") as ActorValue
EndFunction

Event OnQuestInit()
	Self.Hook()
EndEvent

Event Actor.OnPlayerLoadGame(Actor akSender)
	Self.Hook()
EndEvent

Function EnsureArrays()
	If _watched == None
		_watched = new Actor[0]
		_owedEach = new Bool[0]
		_openUntilEach = new Float[0]
		_cooldownEach = new Float[0]
		_inCombatEach = new Bool[0]
	EndIf
	; A save from before _whyEach: one entry per watched companion, all unsaid.
	If _whyEach == None || _whyEach.Length != _watched.Length
		_whyEach = new String[_watched.Length]
	EndIf
EndFunction

; On the quest's start and every load: Ivy's ids checked, registrations re-made,
; the clock restarted.
Function Hook()
	Self.EnsureArrays()
	Actor player = Game.GetPlayer()
	Self.RegisterForRemoteEvent(player, "OnPlayerLoadGame")
	; O-35's "Ask for a moment": the perk that puts it on a companion's prompt. Its own
	; conditions decide when it shows.
	Perk ask = Game.GetFormFromFile(ASK_PERK_ID, "Overture.esp") as Perk
	If ask != None && !player.HasPerk(ask)
		player.AddPerk(ask, False)
	EndIf
	Overture:Companions:IvyAdapter ivyAdapter = (Self as Quest) as Overture:Companions:IvyAdapter
	If ivyAdapter != None
		ivyAdapter.Revalidate()
	EndIf
	Int i = 0
	While i < _watched.Length
		If _watched[i] != None
			Self.RegisterForRemoteEvent(_watched[i], "OnCombatStateChanged")
		EndIf
		i += 1
	EndWhile
	; Ivy's own scenes (variant D), whether or not she travels with the player now.
	Overture:Companions:IvyNative ivy = (Self as Quest) as Overture:Companions:IvyNative
	If ivy != None
		ivy.Hook()
	EndIf
	Self.CancelTimer(POLL_TIMER)
	Self.StartTimer(2.0, POLL_TIMER)
EndFunction

Event OnTimer(Int aiTimerID)
	If aiTimerID != POLL_TIMER
		Return
	EndIf
	; The next tick first: nothing below may stop the clock.
	Self.StartTimer(POLL_SECONDS, POLL_TIMER)
	Self.Poll()
EndEvent

Function Poll()
	Self.EnsureArrays()
	Actor[] now = Self.Registry().CurrentAll()
	; Dismissed since the last poll: not ours to open any more, and no wanting kept.
	Int i = _watched.Length - 1
	While i >= 0
		Actor was = _watched[i]
		If was == None || now.Find(was) < 0
			If was != None
				Self.UnregisterForRemoteEvent(was, "OnCombatStateChanged")
				Self.SetMoment(was, MOMENT_NOT_OURS)
				Self.Feeders().Left(was)
				Debug.Trace("Overture companions: " + was.GetFormID() + " is no longer a companion", 0)
			EndIf
			_watched.Remove(i)
			_owedEach.Remove(i)
			_openUntilEach.Remove(i)
			_cooldownEach.Remove(i)
			_inCombatEach.Remove(i)
			_whyEach.Remove(i)
		EndIf
		i -= 1
	EndWhile
	; Recruited since the last poll.
	i = 0
	While i < now.Length
		If _watched.Find(now[i]) < 0
			_watched.Add(now[i])
			_owedEach.Add(False)
			_openUntilEach.Add(0.0)
			_cooldownEach.Add(0.0)
			_inCombatEach.Add(False)
			_whyEach.Add("")
			Overture:Companions:Adapter joined = Self.Registry().AdapterFor(now[i])
			String adapterName = "none"
			If joined != None
				adapterName = joined.Name()
			EndIf
			Debug.Trace("Overture companions: " + now[i].GetFormID() + " is a companion now (adapter " + adapterName + ")", 0)
			Self.RegisterForRemoteEvent(now[i], "OnCombatStateChanged")
			Self.Feeders().Joined(now[i])
		EndIf
		i += 1
	EndWhile
	If _watched.Length == 0
		Return
	EndIf
	Overture:Approach approach = Self.Overture()
	Bool enabled = approach != None && approach.Enabled()
	i = 0
	While i < _watched.Length
		If !enabled
			; Overture switched off: nothing opens, and nothing counts.
			Self.SetMoment(_watched[i], MOMENT_NOT_OURS)
		Else
			Self.Feeders().Tick(_watched[i])
			Self.Evaluate(i)
		EndIf
		i += 1
	EndWhile
EndFunction

Event Actor.OnCombatStateChanged(Actor akSender, Actor akTarget, Int aeCombatState)
	Int i = Self.IndexOf(akSender)
	If i < 0
		Return
	EndIf
	If aeCombatState != 0
		_inCombatEach[i] = True
		Return
	EndIf
	If _inCombatEach[i] && !akSender.IsDead()
		Self.Feeders().SurvivedTogether(akSender)
	EndIf
	_inCombatEach[i] = False
EndEvent

Int Function IndexOf(Actor akWho)
	If akWho == None || _watched == None
		Return -1
	EndIf
	Return _watched.Find(akWho)
EndFunction

; True when the value CHANGED -- the only moment worth a log line.
Bool Function SetMoment(Actor akWho, Int aiValue)
	ActorValue av = Self.OurAV(MOMENT_AV_ID)
	If akWho == None || av == None || akWho.GetValue(av) == aiValue as Float
		Return False
	EndIf
	akWho.SetValue(av, aiValue as Float)
	Return True
EndFunction

; Somewhere nobody is watching, by Rapport's own count against its own tolerance.
; -1 is "no scan yet", NOT "nobody": a moment is not opened on a guess. Fellow
; companions near enough to have been counted come back off the count: they travel
; with the player and are not an audience (owner, 2026-09-24).
Bool Function Private(Actor akWho)
	If Rapport:Core.ApiVersion() < NEEDS_API
		Return False
	EndIf
	Int watching = Rapport:Core.ObserversNear(akWho.GetFormID())
	If watching < 0
		Return False
	EndIf
	Int i = 0
	While _watched != None && i < _watched.Length
		Actor fellow = _watched[i]
		; Alive, as Rapport counts only the living: a fallen companion was never on its count.
		If fellow != None && fellow != akWho && fellow.Is3DLoaded() && !fellow.IsDead() && fellow.GetDistance(akWho) <= FELLOW_RADIUS
			watching -= 1
		EndIf
		i += 1
	EndWhile
	Return watching <= Rapport:Core.ObserverTolerance()
EndFunction

; The greeting's own once-a-day test: its stamp has come round.
Bool Function StampOpen(Actor akWho)
	ActorValue av = Self.OurAV(NEXT_DAY_AV_ID)
	Return av != None && akWho.GetValue(av) <= Utility.GetCurrentGameTime()
EndFunction

; Another companion's moment open right now: one at a time.
Bool Function OtherOpen(Int aiIndex, Float afNow)
	Int i = 0
	While i < _watched.Length
		If i != aiIndex && _openUntilEach[i] > afNow
			Return True
		EndIf
		i += 1
	EndWhile
	Return False
EndFunction

Function Evaluate(Int aiIndex)
	Actor akWho = _watched[aiIndex]
	Overture:Companions:Registry reg = Self.Registry()
	Overture:Companions:Adapter a = reg.AdapterFor(akWho)
	; WHICH gate said no, said once each time it changes: the owner saw no "Ask for a moment"
	; on Ivy (2026-09-25) and the log could not say why (six gates, none of them traced).
	String no = ""
	If a == None
		no = "no adapter vouches for them"
	ElseIf !a.OpensMoments(akWho)
		no = "their adapter does not open moments"
	ElseIf a.OwnIntimateScene(akWho) != None
		no = "their own intimate scene is running"
	ElseIf !reg.Eligible(akWho)
		no = "not eligible (Registry.Eligible)"
	ElseIf a.Closed(akWho)
		no = "their state is closed (Adapter.Closed)"
	ElseIf a.Refuses(akWho)
		no = "they refuse right now (Adapter.Refuses)"
	EndIf
	If no != ""
		Self.SetMoment(akWho, MOMENT_NOT_OURS)
		Self.SayWhy(aiIndex, akWho, "no moment, no 'Ask for a moment': " + no)
		Return
	EndIf
	Float now = Utility.GetCurrentGameTime()
	ActorValue momentAV = Self.OurAV(MOMENT_AV_ID)
	If momentAV != None && akWho.GetValue(momentAV) == MOMENT_ASKED as Float && now < _askedAt + ASK_DAYS
		; The player has just asked (O-35): the mark waits for the talk it asks for.
		Return
	EndIf
	Overture:Companions:Feeders feeders = Self.Feeders()
	If _openUntilEach[aiIndex] > 0.0 && now >= _openUntilEach[aiIndex]
		; The window lapsed unused: spent, and the next one waits out the cooldown.
		_openUntilEach[aiIndex] = 0.0
		_cooldownEach[aiIndex] = now + feeders.Tuned("fMomentCooldown:Companions", 2.0)
		Debug.Trace("Overture companions: " + akWho.GetFormID() + "'s moment passed unused", 0)
	EndIf
	If !_owedEach[aiIndex] && _openUntilEach[aiIndex] <= 0.0 && now >= _cooldownEach[aiIndex] && feeders.Gate(akWho) == feeders.GATE_PASS
		_owedEach[aiIndex] = True
		Debug.Trace("Overture companions: " + akWho.GetFormID() + " wants the player - a moment is owed (" + feeders.LastGateNote() + ")", 0)
	EndIf
	Bool private = Self.Private(akWho)
	If _owedEach[aiIndex] && private && Self.StampOpen(akWho) && !Self.OtherOpen(aiIndex, now)
		Overture:Approach approach = Self.Overture()
		If approach != None && approach.CompanionOpenable(akWho)
			_owedEach[aiIndex] = False
			_openUntilEach[aiIndex] = now + WINDOW_DAYS
			; DRAFT wording, for the owner's review: a hint, never a label (O-11).
			Rapport:Core.NarrateLine(Game.GetPlayer().GetFormID(), akWho.GetFormID(), "{second} keeps glancing your way, like there's something on {their} mind.", "")
			Debug.Trace("Overture companions: " + akWho.GetFormID() + "'s moment is open", 0)
		EndIf
	EndIf
	If _openUntilEach[aiIndex] > now && private
		Self.SetMoment(akWho, MOMENT_OPEN)
	Else
		Self.SetMoment(akWho, MOMENT_VOUCHED)
		Self.SayWhy(aiIndex, akWho, "vouched: 'Ask for a moment' is offered")
	EndIf
EndFunction

; Once per change of answer, per companion -- the first answer included.
Function SayWhy(Int aiIndex, Actor akWho, String asWhy)
	If aiIndex < _whyEach.Length && _whyEach[aiIndex] != asWhy
		_whyEach[aiIndex] = asWhy
		Debug.Trace("Overture companions: " + akWho.GetFormID() + " - " + asWhy, 0)
	EndIf
EndFunction

; A companion conversation ended (Overture:Approach.CompanionEnded). "Not here" and
; "not now" keep the moment, stretched past the hour they reopen at (O-30); every
; other end spends it, and the next is owed only after the cooldown.
Function Ended(Actor akWho, Bool abKeepMoment)
	Int i = Self.IndexOf(akWho)
	If i < 0
		Return
	EndIf
	Float now = Utility.GetCurrentGameTime()
	If abKeepMoment
		If _openUntilEach[i] > 0.0 && _openUntilEach[i] < now + REOPEN_AFTER + WINDOW_DAYS
			_openUntilEach[i] = now + REOPEN_AFTER + WINDOW_DAYS
		EndIf
		Return
	EndIf
	_owedEach[i] = False
	_openUntilEach[i] = 0.0
	_cooldownEach[i] = now + Self.Feeders().Tuned("fMomentCooldown:Companions", 2.0)
	ActorValue av = Self.OurAV(MOMENT_AV_ID)
	If av != None && akWho.GetValue(av) >= MOMENT_OPEN as Float
		akWho.SetValue(av, MOMENT_VOUCHED as Float)
	EndIf
EndFunction

; O-35: the player chose "Ask for a moment" on the companion's prompt (the perk's
; fragment, Overture:Fragments:AskPerk). Marked ASKED, then activated the way a talk
; is -- default processing only, so no perk choice runs again -- and Overture's
; greeting, whose second run needs ASKED, opens the conversation. Its conditions still
; decide: the perk shows only where they would pass.
;
; Every way this can come to nothing is said in the log: a Nexus report (2026-09-26)
; read "asking a companion for a moment does nothing", and the first build said
; nothing on either early return nor whether the conversation opened at all.
Function Ask(Actor akWho)
	If Self.IndexOf(akWho) < 0
		Debug.Trace("Overture companions: asked " + akWho.GetFormID() + " for a moment, but they are not a watched companion yet (the next poll adds them)", 0)
		Return
	EndIf
	ActorValue av = Self.OurAV(MOMENT_AV_ID)
	If av == None || akWho.GetValue(av) < MOMENT_VOUCHED as Float
		Debug.Trace("Overture companions: asked " + akWho.GetFormID() + " for a moment, but no adapter vouches for them now", 0)
		Return
	EndIf
	akWho.SetValue(av, MOMENT_ASKED as Float)
	_askedAt = Utility.GetCurrentGameTime()
	Debug.Trace("Overture companions: the player asked " + akWho.GetFormID() + " for a moment", 0)
	akWho.Activate(Game.GetPlayer(), True)
	; Did Overture's greeting take it? Its scene holds them once it has.
	Utility.Wait(2.0)
	Scene ours = Game.GetFormFromFile(0x00000801, "Overture.esp") as Scene
	If ours != None && akWho.GetCurrentScene() == ours
		Debug.Trace("Overture companions: " + akWho.GetFormID() + "'s conversation opened", 0)
	Else
		Debug.Trace("Overture companions: asked " + akWho.GetFormID() + " for a moment, but Overture's conversation did not open (their scene: " + akWho.GetCurrentScene() + ", in dialogue: " + akWho.IsInDialogueWithPlayer() + ")", 0)
	EndIf
EndFunction

; The dev verb's: a moment owed and opened now, whatever their wanting -- for testing
; the entry without waiting days of game time. On the follower system's Companion (the
; one Dev reports on) when they are watched, else the first companion watched.
String Function ForceMoment()
	Self.EnsureArrays()
	Int i = Self.IndexOf(Self.Registry().Current())
	If i < 0 && _watched.Length > 0
		i = 0
	EndIf
	If i < 0
		Return "no current companion"
	EndIf
	Actor who = _watched[i]
	_owedEach[i] = True
	_cooldownEach[i] = 0.0
	Self.Evaluate(i)
	ActorValue av = Self.OurAV(MOMENT_AV_ID)
	Return "moment=" + who.GetValue(av) + " private=" + Self.Private(who) + " stampOpen=" + Self.StampOpen(who) + " openUntil=" + _openUntilEach[i]
EndFunction

; The companion the dev verbs report on: the follower system's Companion when watched,
; else the first watched. None with no companion.
Actor Function Watching()
	Self.EnsureArrays()
	Actor primary = Self.Registry().Current()
	If Self.IndexOf(primary) >= 0
		Return primary
	EndIf
	If _watched.Length > 0
		Return _watched[0]
	EndIf
	Return None
EndFunction
