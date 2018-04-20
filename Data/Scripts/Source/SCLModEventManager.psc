ScriptName SCLModEventManager Extends Quest
Int DMID = 2
String DebugName = "[SCLEvent] "
Function _CheckVersion()
EndFunction

Bool SCLResetted = False
Event OnSCLReset()
  SCLResetted = True
EndEvent

SCLibrary Property SCLib Auto
SCLSettings Property SCLSet Auto
Actor Property PlayerRef Auto

Function Maintenence()
  RegisterForModEvent("SCLActorMainMenuOpen0", "OnActorMainMenuOpen")
  RegisterForModEvent("SCLProcessEvent", "OnDigest")
  RegisterForModEvent("SCLReset", "OnSCLReset")
  _CheckVersion()
EndFunction

Event OnInit()
  Maintenence()
  SCLibrary.addToReloadList(self)
EndEvent

Int Function GetStage()
  Notice("Reload Maintenence")
  If SCLResetted
    Notice("SCL has been reset!")
    ;Stuff Here
    SCLResetted = False
  EndIf
  Maintenence()
  Return Parent.GetStage()
EndFunction

;*******************************************************************************
;Actor Main Menu Events
;*******************************************************************************
Event OnActorMainMenuOpen(Form akTarget, Int aiMode)
  If akTarget as Actor
    Notice("OnActorMainMenuOpen recieved! Sending ")
    SCLib.showActorMainMenu(akTarget as Actor, aiMode)
  EndIf
EndEvent

;*******************************************************************************
;Digestion Events
;*******************************************************************************
Event OnDigest(Form akForm, Float afTimePassed)
  ;Note("Digest Event Recieved.")
  If !akForm as Actor
    ;Note("Invalid event.")
    Return
  EndIf
  SCLSet.DigestThreadManager.digestAsync(akForm as Actor, afTimePassed)
EndEvent
;/Event OnDigest(Form akForm, Int aiActorData, Int JF_ItemList, Float afTimePassed)
  Actor akTarget
  If akForm as Actor
    akTarget = akForm as Actor
  Else
    Return
  EndIf

  Int TargetData
  If aiActorData
    TargetData = aiActorData
  Else
    Return
  EndIf

  Int JF_DigestContents
  If JF_ItemList
    JF_DigestContents = JF_ItemList
  Else
    Return
  EndIf

  Notice("OnDigest event recieved, beginning digestion for " + SCLib.nameGet(akTarget))
  Float DigestRate = JMap.getFlt(TargetData, "STDigestionRate")
  If DigestRate <= 0
    Notice("Digest Rate is zero! Canceling digestion.")
    Return
  EndIf
  Int JA_Remove = JArray.object()
  Int NumOfItems = JFormMap.count(JF_DigestContents)
  Float IndvRemoveAmount = (DigestRate * afTimePassed * SCLSet.GlobalDigestMulti) / NumOfItems
  ;Notice("# Items = " + NumOfItems + ", Remove Amount/Item = " + IndvRemoveAmount)
  Form ItemKey = JFormMap.nextKey(JF_DigestContents)
  Float Fullness
  Float TotalDigested
  While ItemKey

    If ItemKey as ObjectReference
      Int JM_ItemEntry = JFormMap.getObj(JF_DigestContents, ItemKey)

      If ItemKey as SCLBundle
        Int JM_DataEntry = SCLib.getItemDataEntry((ItemKey as SCLBundle).ItemForm)
        Float RemoveAmount = IndvRemoveAmount * JMap.getFlt(JM_DataEntry, "Durablity", 1)
        ;Note("SCLBundle found! Remove Amount = " + RemoveAmount)
        Float DigestedAmount = RemoveAmount
        Bool Done ;If we finish off the item
        Float Indv = JMap.getFlt(JM_ItemEntry, "IndvDVal")
        Float Active = JMap.getFlt(JM_ItemEntry, "ActiveDVal")
        Int ItemNum = (ItemKey as SCLBundle).NumItems
        While RemoveAmount > 0 && !Done
          If Active > RemoveAmount
            Active -= RemoveAmount
            ;Note("Ran out of RemoveAmount! Resetting DigestValue")
            RemoveAmount = 0  ;didn't manage to finish the stack before we ran out
            JMap.setFlt(JM_ItemEntry, "ActiveDVal", Active)
            (ItemKey as SCLBundle).NumItems = ItemNum
            Float DValue = SCLib.updateDValue(JM_ItemEntry)

            Fullness += DValue
          Else
            RemoveAmount -= Active
            ;Debug.notification("Remove Amount = " + RemoveAmount)
            Active = 0
            If ItemNum > 1  ;If there's more than 1 item left
              ;Debug.notification("Item Number = " + ItemNum + ", resetting Active value")
              ItemNum -= 1 ;Remove 1
              Active = Indv ;Reset the active amount
              sendDigestItemFinishEvent(akTarget, (ItemKey as SCLBundle).ItemForm, Indv)
              ;Debug.notification("Active = " + Active)
              ;Notice("More items found! Resetting active amount")
            Else
              ;Debug.notification("Items finished.")
              Done = True ;That was the last item
              JArray.addForm(JA_Remove, ItemKey)
              ;Don't have to reset dvalues, we're going to delete this
              ;Notice("No more items left!")
            EndIf
          EndIf
        EndWhile
        DigestedAmount -= RemoveAmount  ;If there's anything left of the remove amount, subtract it from the digested amount
        TotalDigested += DigestedAmount
      Else
        ;Note("Regular reference found!")
        Float Active = JMap.getFlt(JM_ItemEntry, "ActiveDVal")
        Float DigestedAmount = Active ;If it finishes the item, then it adds the active amount
        Int JM_DataEntry = SCLib.getItemDataEntry(ItemKey)
        Float RemoveAmount = IndvRemoveAmount * JMap.getFlt(JM_DataEntry, "Durablity", 1)
        If Active > RemoveAmount ;Failed to remove everything from item
          Active -= RemoveAmount
          RemoveAmount = 0
          Fullness += Active
          JMap.setFlt(JM_ItemEntry, "ActiveDVal", Active)
          JMap.setFlt(JM_ItemEntry, "DigestValue", Active)
          ;Notice("Active amount = " + Active + ", resetting digest value")
          DigestedAmount -= RemoveAmount  ;If there's anything left of the remove amount, subtract it from the digested amount
        Else
          RemoveAmount -= Active ;Removed everything from the item
          Active = 0
          ;Notice("Active amount = " + Active + ", removing item")
          JArray.addForm(JA_Remove, ItemKey)
          sendDigestItemFinishEvent(akTarget, ItemKey, JMap.getFlt(JM_ItemEntry, "IndvDVal"))
        EndIf
        TotalDigested += DigestedAmount
      EndIf
    EndIf
    Utility.WaitMenuMode(0.5)
    ItemKey = JFormMap.nextKey(JF_DigestContents, ItemKey)
  EndWhile
  ;Notice("Done processing items, setting final stats:")
  JMap.setFlt(TargetData, "ContentsFullness1", Fullness)
  JMap.setFlt(TargetData, "STTotalDigestedFood", JMap.getFlt(TargetData, "STTotalDigestedFood") + TotalDigested)
  JMap.setFlt(TargetData, "STLastDigestAmount", TotalDigested)
  ;Notice("Fullness = " + Fullness + ", TotalDigested=" + TotalDigested)
  SCLib.quickUpdate(akTarget)
  sendDigestFinishEvent(akTarget, TotalDigested)
  JF_eraseKeys(JF_DigestContents, JA_Remove, akTarget)
EndEvent

Bool Function sendDigestFinishEvent(Actor akEater, Float afDigestedAmount)
  Int FinishEvent = ModEvent.Create("SCLDigestFinishEvent")
  ModEvent.PushForm(FinishEvent, akEater)
  ModEvent.PushFloat(FinishEvent, afDigestedAmount)
  ModEvent.Send(FinishEvent)
EndFunction

Bool Function sendDigestItemFinishEvent(Actor akEater, Form akFood, Float afDigestValue)
  Int FinishEvent = ModEvent.Create("SCLDigestItemFinishEvent")
  ModEvent.PushForm(FinishEvent, akEater)
  ModEvent.PushForm(FinishEvent, akFood)
  ModEvent.PushFloat(FinishEvent, afDigestValue)
  ModEvent.Send(FinishEvent)
EndFunction

Function JF_eraseKeys(Int JF_Source, Int JA_Remove, Actor akEater)
  Int i = JArray.count(JA_Remove)
  While i
    i -= 1
    Form Erase = JArray.getForm(JA_Remove, i)
    If Erase as Actor
      (Erase as Actor).Kill(akEater)
      SCLibrary.addToActorTrashList(Erase as Actor, 3)
    EndIf
    JFormMap.removeKey(JF_Source, Erase)
    SCLibrary.addToObjectTrashList(Erase as ObjectReference, 3)
  EndWhile
EndFunction/;
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
