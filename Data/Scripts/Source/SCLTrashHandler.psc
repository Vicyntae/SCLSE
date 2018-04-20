ScriptName SCLTrashHandler Extends Quest

Function resetData()
  _JF_ObjectTrash = 0
  _JF_ActorTrash = 0
  _JFD_ActorData = 0
EndFunction

Event OnSCLReset()
  resetData()
EndEvent
;*******************************************************************************
;Variables and Properties
;*******************************************************************************
String DebugName = "[SCLTrash] "
Int DMID = 6
SCLibrary Property SCLib Auto
SCLSettings Property SCLSet Auto
Bool UpdateRegistered = False
Float LastUpdateTime
Int _JFD_ActorData
Int Property JFD_ActorData
  Int Function Get()
    If !_JFD_ActorData
      _JFD_ActorData = JDB.solveObj(".SCLActorData")
    EndIf
    Return _JFD_ActorData
  EndFunction
EndProperty
;Settings **********************************************************************
Int Property ObjectTrashLimit = 15 Auto
Int Property ActorTrashLimit = 50 Auto
Int Property TrashUpdateRate = 300 Auto

;Access Properties *************************************************************
Int _JF_ObjectTrash
Int Property JF_ObjectTrash
  Int Function Get()  ;Registers for an update of the trashlist everytime its accessed
    If !_JF_ObjectTrash
      _JF_ObjectTrash = JFormMap.object()
      JDB.solveObjSetter(".SCLTrashList.ObjectTrash", _JF_ObjectTrash, True)
    EndIf
    Notice("Trash List accessed, registering for single update")
    If !UpdateRegistered
      RegisterForSingleUpdate(TrashUpdateRate)
      UpdateRegistered = True
    EndIf
    Return _JF_ObjectTrash
  EndFunction
EndProperty

Int _JF_ActorTrash
Int Property JF_ActorTrash
  Int Function Get()
    If !_JF_ActorTrash
      _JF_ActorTrash = JFormMap.object()
      JDB.solveObjSetter(".SCLTrashList.ActorTrash", _JF_ActorTrash, True)
    Endif
    Notice("Trash List accessed, registering for single update")
    If !UpdateRegistered
      RegisterForSingleUpdate(TrashUpdateRate)
      UpdateRegistered = True
    EndIf
    Return _JF_ActorTrash
  EndFunction
EndProperty



Event OnUpdate()
  UpdateRegistered = False
  Float CurrentUpdateTime = Utility.GetCurrentGameTime()
  Float TimePassed = (CurrentUpdateTime - LastUpdateTime) * 24
  Bool TrashRemaining
  Notice("Cleaning Trash")

  If JFormMap.count(_JF_ObjectTrash) > ObjectTrashLimit
    Notice("Overflow detected, removing objects now")
    While JFormMap.count(_JF_ObjectTrash) > ObjectTrashLimit
      ObjectReference Overflow = findOldestTrash(_JF_ObjectTrash)
      Notice("Deleting " + SCLib.nameGet(Overflow) + "due to overflow")
      If !(Overflow as Actor).IsDead()
        (Overflow as Actor).Kill()
      EndIf
      JFormMap.removeKey(_JF_ObjectTrash, Overflow)  ;Don't need to use JF_eraseKeys, not iterating through it
      Overflow.Disable()
      Overflow.MoveToMyEditorLocation() ;This is to fix problems with enemy respawning
      Overflow.Delete()
    EndWhile
  EndIf

  Int JA_Remove = JArray.object()
  ObjectReference TrashKey = JFormMap.nextKey(_JF_ObjectTrash) as ObjectReference
  While TrashKey
    Float TimeLeft = JFormMap.getFlt(_JF_ObjectTrash, TrashKey)
    TimeLeft -= TimePassed
    If TimeLeft <= 0
      JArray.addForm(JA_Remove, TrashKey)
    Else
      JFormMap.setFlt(_JF_ObjectTrash, TrashKey, TimeLeft)
    EndIf
    TrashKey = JFormMap.nextKey(_JF_ObjectTrash, TrashKey) as ObjectReference
  EndWhile

  removeObjectTrash(JA_Remove)
  JA_Remove = JValue.zeroLifetime(JA_Remove)

  If !JValue.empty(_JF_ObjectTrash)
    TrashRemaining = True
  EndIf

  If JFormMap.count(_JF_ActorTrash) > ActorTrashLimit
    Notice("Overflow detected, removing actors now")
    While JFormMap.count(_JF_ActorTrash) > ActorTrashLimit
      Actor Overflow = FindOldestTrash(_JF_ActorTrash) as Actor
      Notice("Deleting " + SCLib.nameGet(Overflow) + "due to overflow")
      JFormMap.removeKey(_JF_ActorTrash, Overflow)
      JFormMap.removeKey(JFD_ActorData, Overflow)
    EndWhile
  EndIf

  JA_Remove = JArray.object()
  TrashKey = JFormMap.nextKey(_JF_ActorTrash) as ObjectReference
  While TrashKey
    Float TimeLeft = JFormMap.getFlt(_JF_ActorTrash, TrashKey)
    TimeLeft -= TimePassed
    If TimeLeft <= 0
      JArray.addForm(JA_Remove, TrashKey)
    Else
      JFormMap.setFlt(_JF_ActorTrash, TrashKey, TimeLeft)
    EndIf
    TrashKey = JFormMap.nextKey(_JF_ActorTrash, TrashKey) as ObjectReference
  EndWhile

  removeActorTrash(JA_Remove)
  JA_Remove = JValue.zeroLifetime(JA_Remove)

  If !JValue.empty(_JF_ActorTrash)
    TrashRemaining = True
  EndIf

  If TrashRemaining && !UpdateRegistered
    RegisterForSingleUpdate(TrashUpdateRate)
    UpdateRegistered = True
  EndIf
EndEvent

Function removeObjectTrash(Int JA_Remove)
  If !JValue.empty(JA_Remove)
    Int i = JArray.count(JA_Remove)
    While i
      i -= 1
      ObjectReference Trash = JArray.getForm(JA_Remove, i) as ObjectReference
      If !(Trash as Actor).IsDead()
        (Trash as Actor).Kill()
      EndIf
      JFormMap.removeKey(_JF_ObjectTrash, Trash)
      Trash.Disable()
      Trash.MoveToMyEditorLocation()
      Trash.Delete()
    EndWhile
  EndIf
EndFunction

Function removeActorTrash(Int JA_Remove)
  If !JValue.empty(JA_Remove)
    Int i = JArray.count(JA_Remove)
    While i
      i -= 1
      Actor Trash = JArray.getForm(JA_Remove, i) as Actor
      JFormMap.removeKey(_JF_ActorTrash, Trash)
      JFormMap.removeKey(JFD_ActorData, Trash)
    EndWhile
  EndIf
EndFunction

ObjectReference Function findOldestTrash(Int TrashList)
  ObjectReference TrashKey = JFormMap.nextKey(TrashList) as ObjectReference
  ObjectReference LowestTimeObject
  Float LowestTimeValue = 99999
  While TrashKey
    Float TimeValue = JFormMap.getFlt(TrashList, TrashKey)
    If TimeValue < LowestTimeValue
      LowestTimeValue = TimeValue
      LowestTimeObject = TrashKey
    EndIf
    TrashKey = JFormMap.nextKey(TrashList, TrashKey) as ObjectReference
  EndWhile
  Return LowestTimeObject
EndFunction

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Debug Functions
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
