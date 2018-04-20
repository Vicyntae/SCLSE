ScriptName SCLTransferObject Extends ObjectReference
Int DMID = 4
String Property DebugName
  String Function Get()
    Return "[SCLTransfer " + Target.GetLeveledActorBase().GetName() + "] "
  EndFunction
EndProperty
SCLibrary Property SCLib Auto
SCLSettings Property SCLSet Auto
Actor Property PlayerRef Auto
SCLTransferObject2 Property SCL_TransferChest2 Auto
Actor Target
Int TargetData
Float MaxWeight = 100.0
Float CurrentWeight

Actor Property TransferTarget
  Function Set(Actor akActor)
    Target = akActor
    TargetData = SCLib.getTargetData(akActor)
    MaxWeight = SCLib.getMax(akActor)
    CurrentWeight = JMap.getFlt(TargetData, "STFullness")
  EndFunction
EndProperty
String Property Destination Auto

Event OnInit()
  RegisterForMenu("ContainerMenu")
EndEvent

Event OnMenuClose(string menuName)
  SCL_TransferChest2.TransferTarget = Target
  SCL_TransferChest2.Destination = Destination
  RemoveAllItems(SCL_TransferChest2, True, True)
EndEvent

Bool _UpdateLocked = False
Function UpdateLock()
  If _UpdateLocked
    While _UpdateLocked
      Utility.WaitMenuMode(0.1)
    EndWhile
  EndIf
  _UpdateLocked = True
EndFunction

Function UpdateUnlock()
  _UpdateLocked = False
EndFunction

Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
  UpdateLock()
  Float DigestValue = SCLib.genDigestValue(akBaseItem)
  If MaxWeight >= CurrentWeight + DigestValue
    CurrentWeight += DigestValue
  Else
    If !PlayerThought(Target, "I can't eat anymore!", "You can't eat anymore!", "%p can't eat anymore!")
      Debug.Notification("I'm sorry, but I can't eat anymore.")
    EndIf
    If akItemReference
      RemoveItem(akItemReference, aiItemCount, False, PlayerRef)
    Else
      RemoveItem(akBaseItem, aiItemCount, False, PlayerRef)
    EndIf
  EndIf
  UpdateUnlock()
EndEvent

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Debug Functions
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Bool Function PlayerThought(Actor akTarget, String sMessage1 = "", String sMessage2 = "", String sMessage3 = "", Int iOverride = 0)
  {Use this to display player information. Returns whether the passed actor is
  the player.
  Make sure sMessage1 is 1st person, sMessage2 is 2nd person, sMessage3 is 3rd person
  Make sure at least one is filled: it will default to it regardless of setting
  Use iOverride to force a particular message}

  If akTarget == PlayerRef
    Int Setting = SCLSet.PlayerMessagePOV
    If Setting == -1
      Return True
    EndIf
    If (sMessage1 && Setting == 1) || iOverride == 1
      Debug.Notification(sMessage1)
    ElseIf (sMessage2 && Setting == 2) || iOverride == 2
      Debug.Notification(sMessage3)
    ElseIf (sMessage3 && Setting == 3) || iOverride == 3
      Debug.Notification(sMessage3)
    ElseIf sMessage3
      Debug.Notification(sMessage3)
    ElseIf sMessage1
      Debug.Notification(sMessage1)
    ElseIf sMessage2
      Debug.Notification(sMessage2)
    Else
      Issue("Empty player thought. Skipping...", 1)
    EndIf
    Return True
  Else
    Return False
  EndIf
EndFunction

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
