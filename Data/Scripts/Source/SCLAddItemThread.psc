ScriptName SCLAddItemThread Extends Quest Hidden

SCLibrary Property SCLib Auto
SCLSettings Property SCLSet Auto
Bool thread_queued = False
Actor MyActor
ObjectReference ItemObjectReference
Form ItemBaseObject
Int ItemType
Float DigestValueOverride
Int ItemCount
Bool MoveNow
Int Property ThreadID Auto
Int Result
Bool thread_ready

Int Function getResultEntry()
  thread_ready = False
  thread_queued = False
  Return Result
EndFunction

Function setThread(Actor akTarget, ObjectReference akReference = None, Form akBaseObject = None, Int aiItemType, Float afDigestValueOverRide = -1.0, Int aiItemCount = 1, Bool abMoveNow = True)
  thread_queued = True

  MyActor = akTarget
  ItemObjectReference = akReference
  ItemBaseObject = akBaseObject
  ItemType = aiItemType
  DigestValueOverride = afDigestValueOverRide
  ItemCount = aiItemCount
  MoveNow = abMoveNow
EndFunction

Bool Function queued()
  return thread_queued
EndFunction

Bool Function isReady()
  Return thread_ready
EndFunction

Bool Function force_unlock()
  clear_thread_vars()
  thread_queued = False
  thread_ready = False
  Return True
EndFunction

Event OnAddItemCall(Int aiID)
  If thread_queued && aiID == ThreadID
    String n = nameGet(MyActor) + ": "
    Int JF_ST_Contents = getContents(MyActor, ItemType)
    ;/If !JF_ST_Contents
      Notice(n + "Contents not found!", 1)
    Else
      Notice(n + "Contents found!", 1)
    EndIf/;
    Int JM_ItemEntry
    If ItemObjectReference as SCLBundle
      Form BundleForm = (ItemObjectReference as SCLBundle).ItemForm
      JM_ItemEntry = findObjBundle(JF_ST_Contents, BundleForm)
      If !JM_ItemEntry
        JM_ItemEntry = JMap.object()
        Float DValue = SCLib.genDigestValue(BundleForm)
        JMap.setFlt(JM_ItemEntry, "DigestValue", DValue * (ItemObjectReference as SCLBundle).NumItems)  ;(IndvDVal x (NumItems - 1)) + ActiveDVal
        JMap.setFlt(JM_ItemEntry, "ActiveDVal", DValue)  ;AKA All items DValue + in process item
        JMap.setFlt(JM_ItemEntry, "IndvDVal", DValue)  ;For a single item, just the ActiveDVal
        If MoveNow
          moveToHoldingCell(ItemObjectReference)
        EndIf
      Else
        SCLBundle ItemBundle = JMap.getForm(JM_ItemEntry, "ItemReference") as SCLBundle
        ItemBundle.NumItems += (ItemObjectReference as SCLBundle).NumItems
        Float DValue = JMap.getFlt(JM_ItemEntry, "ActiveDVal") + (JMap.getFlt(JM_ItemEntry, "IndvDVal") * (ItemBundle.NumItems - 1))
        ;Notice(n + "Recalculating DigestValue, DValue=" + DValue, 1)
        JMap.setFlt(JM_ItemEntry, "DigestValue", DValue)
      EndIf

    ElseIf ItemObjectReference  ;Make new entry for ItemObjectReference
      ;Notice(n + "ItemObjectReference detected. Creating new entry...", 1)
      JM_ItemEntry = JMap.object()
      Float DValue
      If DigestValueOverride < 0
        DValue = SCLib.genDigestValue(ItemObjectReference)  ;Make sure to check base object in genDigestValue
      Else
        DValue = DigestValueOverride
      EndIf
      ;Notice(n + "Digest value for " + nameGet(ItemObjectReference) + "=" + DValue, 1)
      JMap.setFlt(JM_ItemEntry, "ActiveDVal", DValue)
      JMap.setFlt(JM_ItemEntry, "DigestValue", DValue)
      JMap.setFlt(JM_ItemEntry, "IndvDVal", DValue)
      JMap.setForm(JM_ItemEntry, "ItemReference", ItemObjectReference) ;Redundancy, just in case you only have the ItemEntry
      JMap.setInt(JM_ItemEntry, "ItemType", ItemType) ;again, redundancy

      JFormMap.setObj(JF_ST_Contents, ItemObjectReference, JM_ItemEntry)
      If MoveNow
        ;Notice(n + "Moving ref to holding cell", 1)
        moveToHoldingCell(ItemObjectReference)
      EndIf
      ;Notice(nameGet(ItemObjectReference) + " added to " + nameGet(MyActor) + " as item type " + ItemType, 1)
    Else
      ;Find previous entries
      ;Notice(n + "Form detected", 1)
      JM_ItemEntry = findObjBundle(JF_ST_Contents, ItemBaseObject)

      If !JM_ItemEntry  ;Make new entry
        ;Notice(n + "No entry detected. Creating new entry.")
        JM_ItemEntry = JMap.object()

        Float DValue = SCLib.genDigestValue(ItemBaseObject)
        ;Notice(n + "Digest value for " + nameGet(ItemBaseObject) + "=" + DValue, 1)
        JMap.setFlt(JM_ItemEntry, "DigestValue", DValue * ItemCount)  ;(IndvDVal x (NumItems - 1)) + ActiveDVal
        JMap.setFlt(JM_ItemEntry, "ActiveDVal", DValue)  ;AKA All items DValue + in process item
        JMap.setFlt(JM_ItemEntry, "IndvDVal", DValue)  ;For a single item, just the ActiveDVal

        ;Notice(n + "Placing SCLBundle at holding cell", 1)
        SCLBundle ItemBundle = SCLSet.SCL_HoldingCell.PlaceAtMe(SCLSet.SCL_ItemBundle) as SCLBundle
        ;/If !ItemBundle
          Notice(n + "Placement failed", 1)
        Else
          Notice(n + "Placement succeeded", 1)
        EndIf/;
        JMap.setForm(JM_ItemEntry, "ItemReference", ItemBundle) ;Redundancy, just in case you only have the ItemEntry
        JMap.setInt(JM_ItemEntry, "ItemType", ItemType) ;again, redundancy
        ItemBundle.ItemForm = ItemBaseObject
        ItemBundle.NumItems = ItemCount
        ItemBundle.MyActor = MyActor
        ;Notice(n + "Setting data in SCLBundle: " + nameGet(ItemBundle.ItemForm) + ", " + ItemBundle.NumItems, 1)
        JFormMap.setObj(JF_ST_Contents, ItemBundle, JM_ItemEntry)

      Else ;Add to previous entry
        ;Notice(n + "Previous entry found! Adding...", 1)
        SCLBundle ItemBundle = JMap.getForm(JM_ItemEntry, "ItemReference") as SCLBundle
        ItemBundle.NumItems += ItemCount

        Float DValue = SCLib.updateDValue(JM_ItemEntry)
      EndIf
      ;Notice(nameGet(ItemBaseObject) + " added to " + nameGet(MyActor) + " as item type " + ItemType)
    EndIf

    Result = JM_ItemEntry
    clear_thread_vars()
    thread_ready = True
  EndIf
EndEvent

String Function nameGet(Form akTarget)
  If akTarget as SCLBundle
    Return (akTarget as SCLBundle).ItemForm.GetName()
  ElseIf akTarget as Actor
    Return (akTarget as Actor).GetLeveledActorBase().GetName()
  ElseIf akTarget as ObjectReference
    Return (akTarget as ObjectReference).GetBaseObject().GetName()
  Else
    Return akTarget.GetName()
  EndIf
EndFunction

Int Function getContents(Actor akTarget, Int aiItemType, Int aiTargetData = 0)
  {New setup: a JFormMap for each item type}
  Int TargetData = getData(akTarget, aiTargetData)
  Int JF_Return = JMap.getObj(TargetData, "Contents" + aiItemType)
  If !JF_Return
    JF_Return = JFormMap.object()
    JMap.setObj(TargetData, "Contents" + aiItemType, JF_Return)
  EndIf
  Return JF_Return
EndFunction

Int Function getData(Actor akTarget, Int aiTargetData = 0)
  {Convenience function, gets ActorData if needed}
  Int TargetData
  If aiTargetData
    TargetData = aiTargetData
  Else
    TargetData = SCLib.getTargetData(akTarget)
  EndIf
  Return TargetData
EndFunction

Int Function findObjBundle(Int JF_ContentsMap, Form akBaseObject)
  {Searches through all items in an actor's content array, returns the ItemEntry ID}
  Form SearchRef = JFormMap.nextKey(JF_ContentsMap)
  While SearchRef
    If SearchRef as ObjectReference
      If SearchRef as SCLBundle
        Form SearchForm = (SearchRef as SCLBundle).ItemForm
        If SearchForm == akBaseObject
          Return JFormMap.getObj(JF_ContentsMap, SearchRef)
        EndIf
      EndIf
    EndIf
    SearchRef = JFormMap.nextKey(JF_ContentsMap, SearchRef)
  EndWhile
  Return 0
EndFunction

Function moveToHoldingCell(ObjectReference akRef)
  ;akRef.DisableNoWait()
  akRef.MoveTo(SCLSet.SCL_HoldingCell)
  ;akRef.EnableNoWait()
EndFunction

Function clear_thread_vars()
  MyActor = None
  ItemObjectReference = None
  ItemBaseObject = None
  ItemType = 0
  DigestValueOverride = 0
  ItemCount = 0
  MoveNow = False
EndFunction
