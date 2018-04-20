ScriptName SCLTransferObject2 Extends ObjectReference
Int DMID = 4
String Property DebugName
  String Function Get()
    Return "[SCLTransfer " + Target.GetLeveledActorBase().GetName() + "] "
  EndFunction
EndProperty
SCLibrary Property SCLib Auto
SCLSettings Property SCLSet Auto
Actor Property PlayerRef Auto
Actor Target
Int TargetData
Bool Locked

Actor Property TransferTarget
  Function Set(Actor akActor)
    Target = akActor
    TargetData = SCLib.getTargetData(akActor)
  EndFunction
EndProperty
String Property Destination Auto

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
  If GetNumItems() == 0
    SCLib.quickUpdate(Target, True)
  EndIf
  _UpdateLocked = False
EndFunction

Event OnItemAdded(Form akBaseItem, int aiItemCount, ObjectReference akItemReference, ObjectReference akSourceContainer)
  UpdateLock()

  Int ItemType
  If (akBaseItem as Potion || akBaseItem as Ingredient) && !SCLib.isInContainer(akBaseItem)
    ItemType = 1
  Else
    ItemType = 2
  EndIf

  While aiItemCount
    If ItemType == 1
      If akItemReference
        RemoveItem(akItemReference, 1, False, Target)
        Target.EquipItem(akItemReference, False, False)
      Else
        RemoveItem(akBaseItem, 1, False, Target)
        Target.EquipItem(akBaseItem, False, False)
      EndIf
    ElseIf ItemType == 2
      SCLib.addItem(Target, akItemReference, akBaseItem, ItemType)
      If !akItemReference
        RemoveItem(akBaseItem, 1, False)
      EndIf
    EndIf
    aiItemCount -= 1
  EndWhile
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
