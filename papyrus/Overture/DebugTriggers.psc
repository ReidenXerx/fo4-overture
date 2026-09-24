Scriptname Overture:DebugTriggers Hidden
{R-23 (owner poll, 2026-09-24): Overture's entry points on demand, from the MCM's
Debug page and its hotkeys. Face the NPC you mean.

  Approach now   FORCED: Overture's approach scene on them, eligible or not.
                 REAL:   you talk to them; the engine picks the greeting as in play.
  Straight to yes FORCED: a yes without asking, and its scene even with "A yes
                         starts a scene" off.
                 REAL:   the stage-3 verdict decides; a yes asks for its scene only
                         with that switch on.

No F4MCP type here: this must work for a player without it (microscope pass 2). The
target comes from Rapport's "in front of you", the same one Rapport's buttons use.
Global functions with no parameters, so MCM buttons and keybinds call them alike.}

Overture:Approach Function App() Global
	Return Game.GetFormFromFile(0x00000800, "Overture.esp") as Overture:Approach
EndFunction

Actor Function Target() Global
	Return Rapport:Core.ActorInFront(600.0, 35.0)
EndFunction

Function Say(String asLine) Global
	Debug.Notification(asLine)
	Debug.Trace(asLine, 0)
EndFunction

Function Approach(Bool abForce) Global
	Overture:Approach app = Overture:DebugTriggers.App()
	If app == None
		Overture:DebugTriggers.Say("Overture debug: Overture.esp's quest did not resolve")
		Return
	EndIf
	Actor who = Overture:DebugTriggers.Target()
	If who == None
		Overture:DebugTriggers.Say("Overture debug: nobody in front of you - face them, within a few steps")
		Return
	EndIf
	Overture:DebugTriggers.Say(app.DebugApproach(who, abForce))
EndFunction

Function Yes(Bool abForce) Global
	Overture:Approach app = Overture:DebugTriggers.App()
	If app == None
		Overture:DebugTriggers.Say("Overture debug: Overture.esp's quest did not resolve")
		Return
	EndIf
	Actor who = Overture:DebugTriggers.Target()
	If who == None
		Overture:DebugTriggers.Say("Overture debug: nobody in front of you - face them, within a few steps")
		Return
	EndIf
	Overture:DebugTriggers.Say(app.DebugYes(who, abForce))
EndFunction

; ---- what the MCM calls -----------------------------------------------------
Function ApproachForced() Global
	Overture:DebugTriggers.Approach(true)
EndFunction

Function ApproachReal() Global
	Overture:DebugTriggers.Approach(false)
EndFunction

Function YesForced() Global
	Overture:DebugTriggers.Yes(true)
EndFunction

Function YesReal() Global
	Overture:DebugTriggers.Yes(false)
EndFunction
