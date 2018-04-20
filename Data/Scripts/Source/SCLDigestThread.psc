ScriptName SCLDigestThread Extends Quest Hidden
SCLibrary Property SCLib Auto
SCLSettings Property SCLSet Auto
Actor Property PlayerRef Auto
String Property DebugName
  String Function Get()
    Return "[SCLDigestThread" + ThreadID + "] "
  EndFunction
EndProperty
Int DMID = 5
Bool thread_queued = False
Actor MyActor
Int TargetData
Int ItemList
Float TimePassed

Int Property ThreadID Auto

Function setThread(Actor akTarget, Float afTimePassed)
  thread_queued = True
  MyActor = akTarget
  TargetData = SCLib.getTargetData(akTarget)
  ItemList = SCLib.getContents(akTarget, 1)
  TimePassed = afTimePassed
EndFunction

Bool Function queued()
  Return thread_queued
EndFunction

Bool Function force_unlock()
  clear_thread_vars()
  thread_queued = False
  Return True
EndFunction

Event OnDigestCall(Int aiID)
  If thread_queued && aiID == ThreadID
    If !MyActor
      clear_thread_vars()
      thread_queued = False
      Return
    EndIf
    If !JValue.empty(ItemList)
      ;Note("Starting digestion for " + MyActor.GetLeveledActorBase().GetName())
      Float DigestRate = JMap.getFlt(TargetData, "STDigestionRate")
      If DigestRate <= 0
        Notice("Digest Rate is zero! Canceling digestion.")
        Return
      EndIf
      Int JA_Remove = JArray.object()
      Int NumOfItems = JFormMap.count(ItemList)
      Float IndvRemoveAmount = (DigestRate * TimePassed * SCLSet.GlobalDigestMulti) / NumOfItems
      ;Notice("# Items = " + NumOfItems + ", Remove Amount/Item = " + IndvRemoveAmount)
      Form ItemKey = JFormMap.nextKey(ItemList)
      Float Fullness
      Float TotalDigested
      While ItemKey

        If ItemKey as ObjectReference
          Int JM_ItemEntry = JFormMap.getObj(ItemList, ItemKey)

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
                Float DValue = Active + (Indv * (ItemNum - 1))
                JMap.setFlt(JM_ItemEntry, "DigestValue", DValue)

                ;Float DValue = SCLib.updateDValue(JM_ItemEntry)


                Fullness += DValue
              Else
                RemoveAmount -= Active
                ;Debug.notification("Remove Amount = " + RemoveAmount)
                Active = 0
                If ItemNum > 1  ;If there's more than 1 item left
                  ;Debug.notification("Item Number = " + ItemNum + ", resetting Active value")
                  ItemNum -= 1 ;Remove 1
                  Active = Indv ;Reset the active amount
                  sendDigestItemFinishEvent(MyActor, (ItemKey as SCLBundle).ItemForm, Indv)
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
              If ItemKey as Actor
                (ItemKey as Actor).DamageActorValue("Health", RemoveAmount)
              EndIf
            Else
              RemoveAmount -= Active ;Removed everything from the item
              Active = 0
              ;Notice("Active amount = " + Active + ", removing item")
              JArray.addForm(JA_Remove, ItemKey)
              sendDigestItemFinishEvent(MyActor, ItemKey, JMap.getFlt(JM_ItemEntry, "IndvDVal"))
            EndIf
            TotalDigested += DigestedAmount
          EndIf
        EndIf
        Utility.WaitMenuMode(0.5)
        ItemKey = JFormMap.nextKey(ItemList, ItemKey)
      EndWhile
      ;Notice("Done processing items, setting final stats:")
      JMap.setFlt(TargetData, "ContentsFullness1", Fullness)
      JMap.setFlt(TargetData, "STTotalDigestedFood", JMap.getFlt(TargetData, "STTotalDigestedFood") + TotalDigested)
      JMap.setFlt(TargetData, "STLastDigestAmount", TotalDigested)
      JF_eraseKeys(ItemList, JA_Remove, MyActor)
      sendDigestFinishEvent(MyActor, TotalDigested)
    Else
      JMap.setFlt(TargetData, "ContentsFullness1", 0)
      JMap.setFlt(TargetData, "STLastDigestAmount", 0)
      sendDigestFinishEvent(MyActor, 0)

    EndIf

    ;Notice("Fullness = " + Fullness + ", TotalDigested=" + TotalDigested)
    ;Note("Final ContentsFullness1 = " + JMap.getFlt(TargetData, "ContentsFullness1"))
    clear_thread_vars()
    thread_queued = False
  EndIf
EndEvent

Bool Function sendDigestFinishEvent(Actor akEater, Float afDigestedAmount)
  Int FinishEvent = ModEvent.Create("SCLDigestFinishEvent")
  ModEvent.PushForm(FinishEvent, akEater)
  ModEvent.PushFloat(FinishEvent, afDigestedAmount)
  Return ModEvent.Send(FinishEvent)
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
EndFunction

Function clear_thread_vars()
  MyActor = None
  TargetData = 0
  ItemList = 0
  TimePassed = 0
EndFunction

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
