ScriptName SCLPostBattleAutoEat Extends ActiveMagicEffect

Int eatQueued
SCLibrary Property SCLib Auto
String Property DebugName
  String Function Get()
    Return "[SCLPostBattleEat " + GetTargetActor().GetLeveledActorBase().GetName() + "] "
  EndFunction
EndProperty
Int DMID = 6

Event OnEffectStart(Actor akTarget, Actor akCaster)
  RegisterForSingleUpdate(120)
EndEvent

Event OnUpdate()
  If eatQueued == 0
    eatQueued = 1
    RegisterForSingleUpdate(480)
    Note("Battle time over 3 minutes. Prepping autoeat for potions and a snack.")
  ElseIf eatQueued == 1
    eatQueued == 2
    Note("Battle time over 10 minutes. Prepping autoeat for potions and a light meal.")
  EndIf
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
  If eatQueued == 1
    SCLib.actorEat(akTarget, 0, 30)
    Utility.Wait(2)
    SCLib.actorEat(akTarget, 1, 30)
  ElseIf eatQueued == 2
    SCLib.actorEat(akTarget, 0, 30)
    Utility.Wait(2)
    SCLib.actorEat(akTarget, 2, 30)
  EndIf
EndEvent

Bool Function PlayerThoughtDB(Actor akTarget, String sKey, Int iOverride = 0, Actor[] akActors = None, Int aiActorIndex = -1)
  {Use this to display player information. Returns whether the passed actor is
  the player.
  Pulls message from database; make sure sKey is valid.
  Will add POV int to end of key, so omit it in the parameter}
  Return SCLib.ShowPlayerThoughtDB(akTarget, sKey, iOverride, akActors, aiActorIndex)
EndFunction

Function Popup(String sMessage)
  SCLib.ShowPopup(sMessage, DebugName)
EndFunction

Function Note(String sMessage)
  SCLib.ShowNote(sMessage, DebugName)
EndFunction

Function Notice(String sMessage, Int aiID = 0)
  Int ID
  If aiID > 0
    ID = aiID
  Else
    ID = DMID
  EndIf
  SCLib.showNotice(sMessage, ID, DebugName)
EndFunction

Function Issue(String sMessage, Int iSeverity = 0, Int aiID = 0, Bool bOverride = False)
  Int ID
  If aiID > 0
    ID = aiID
  Else
    ID = DMID
  EndIf
  SCLib.ShowIssue(sMessage, iSeverity, ID, bOverride, DebugName)
EndFunction
