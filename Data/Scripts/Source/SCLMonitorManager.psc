ScriptName SCLMonitorManager Extends Quest

Function resetData()
EndFunction

String DebugName = "[SCLMonitorManager] "
Int DMID = 4
;Remember to delete calls to SCLib to speed up system later
Actor Property PlayerRef Auto
SCLibrary Property SCLib Auto
SCLSettings Property SCLSet Auto
Float LastDailyUpdate
Bool QueueDailyUpdate

Int Function GetStage()
  reloadAliasMaintenence()
  RegisterForModEvent("SCLReset", "OnSCLReset")
  RegisterForSingleUpdate(SCLSet.UpdateRate)
  Return Parent.GetStage()
EndFunction

;/Event OnSleepStop(bool abInterrupted)
  QueueDailyUpdate = True
  OnUpdate()
EndEvent/;

Event OnMenuOpen(String menuName)
  UnregisterForUpdate()
EndEvent

Event OnMenuClose(string menuName)
  ;If menuName = "Sleep/Wait Menu"
    ;Note("Sleep Detected. Updating actors.")
    QueueDailyUpdate = True
    RegisterForSingleUpdate(0.1)
    ;OnUpdate()
  ;EndIf
EndEvent

Function reloadAliasMaintenence()
  Int i = GetNumAliases()
  While i > 0
    i -= 1
    SCLMonitor TrackingAlias = GetNthAlias(i) as SCLMonitor
    If !SCLResetted
      TrackingAlias.reloadMaintenence()
    Else
      TrackingAlias.Setup()
    EndIf
  EndWhile
  If SCLResetted
    SCLResetted = False
  EndIf
EndFunction

Bool SCLResetted = False
Event OnSCLReset()
  SCLResetted = True
EndEvent

Bool Function Start()
  Bool bReturn = Parent.Start()
  Notice("Starting up monitor manager")
  ;RegisterForSleep()
  RegisterForMenu("Sleep/Wait Menu")
  RegisterForModEvent("SCLReset", "OnSCLReset")
  RegisterForSingleUpdate(SCLSet.UpdateRate)
  SCLibrary.addToReloadList(Self)
  Return bReturn
EndFunction

Function Stop()
  UnregisterForUpdate()
  Parent.Stop()
EndFunction

;/Event OnInit()
  If !SCLibrary.getSCLModConfig().MCMInitialized
    Return
  EndIf
  Notice("Starting up monitor manager")
  RegisterForSleep()
  RegisterForModEvent("SCLReset", "OnSCLReset")
  RegisterForSingleUpdate(SCLib.UpdateRate)
  SCLibrary.addToReloadList(Self)
EndEvent/;

Event OnUpdate()
  Float CurrentUpdateTime = Utility.GetCurrentGameTime()
  ;Notice("Updating actor list")
  Bool DailyUpdate = False
  If QueueDailyUpdate || CurrentUpdateTime - LastDailyUpdate > 1
    QueueDailyUpdate = False
    DailyUpdate = True
  EndIf

  Int i = 0
  Int NumAlias = GetNumAliases()
  ;Notice("NumAliases = " + NumAlias)
  ;Note("NumAliases = " + NumAlias)

  While i < NumAlias
    ReferenceAlias TrackingAlias = GetNthAlias(i) as ReferenceAlias
    ;Note("Looking at Alias " + TrackingAlias.GetName() + ", ID " + TrackingAlias.GetID())
    Actor akTarget = TrackingAlias.GetActorReference()
    If akTarget
      Int TargetData = SCLib.getTargetData(akTarget)
      Float TimePassed = ((CurrentUpdateTime - (JMap.getFlt(TargetData, "LastUpdateTime")))*24) ;In hours
      If TargetData
        If JMap.getInt(TargetData, "SCLEnableUpdates")
          Notice("Beginning full updates for " + SCLib.nameGet(akTarget))
          Int handle = ModEvent.Create("SCLFullUpdate" + TargetData)
          ModEvent.PushFloat(handle, TimePassed)
          ModEvent.pushFloat(handle, CurrentUpdateTime)
          ModEvent.PushBool(handle, DailyUpdate)
          ModEvent.Send(handle)
          ;(TrackingAlias as SCLMonitor).fullActorUpdate(TimePassed, DailyUpdate)
        Else
          Notice("Actor has declined to be updated")
        EndIf
        ;Notice("No target or invalid TargetData")
      EndIf
      JMap.setFlt(TargetData, "LastUpdateTime", CurrentUpdateTime)
      Utility.Wait(SCLSet.UpdateDelay)
    EndIf
    i += 1
  EndWhile
  LastDailyUpdate = CurrentUpdateTime
  RegisterForSingleUpdate(SCLSet.UpdateRate)
EndEvent

;Commenting all of these out until we finalize how this works. Until then, work on the SCLib versions
;/Int Function getTargetData(Actor akTarget)
{Consider: Generate an actor profile if findEntry returns 0}
Int Data = JFormDB.findEntry("SCLActorData", akTarget)
Return Data
EndFunction/;

;/Float Function getTotalBelly(Int aiTargetData)
  Int i = JArray.count(SCLib.JA_BellyValuesList)
  Float TotalWeight
  While i
    i -= 1
    TotalWeight += JMap.getFlt(aiTargetData, JArray.getStr(SCLib.JA_BellyValuesList, i))
  EndWhile
  Return TotalWeight
EndFunction/;


;/Function updateItemProcess(Actor akTarget, Int aiTargetData, Float afTimePassed)
  {AKA Digest function}
  Int ItemType = JIntMap.nextKey(SCLib.JI_ItemTypes, endKey = -1)
  While ItemType != -1
    Int JF_ItemList = JMap.getObj(aiTargetData, "Contents" + ItemType)
    If !JValue.empty(JF_ItemList)
      Int ProcessEvent = ModEvent.Create("SCLProcessEvent" + ItemType)
      ModEvent.pushForm(ProcessEvent, akTarget)
      ModEvent.pushInt(ProcessEvent, aiTargetData)
      ModEvent.pushInt(ProcessEvent, JF_ItemList)
      ModEvent.PushFloat(ProcessEvent, afTimePassed)
      ModEvent.send(ProcessEvent)
    EndIf
    ItemType = JIntMap.nextKey(SCLib.JI_ItemTypes, ItemType, -1)
  EndWhile
  ;Notice("Processing completed for " + SCLib.nameGet(akTarget))
EndFunction/;

;/Float Function updateFullness(Actor akTarget, Int aiTargetData)
  {Checks each reported fullness, set "STFullness to it"}
  ;Notice("updateFullness starting for " + akTarget.GetLeveledActorBase().GetName())
  Int ItemType = JIntMap.nextKey(SCLib.JI_ItemTypes, endKey = -1)
  Float Total
  While ItemType != -1
    Total += JMap.getFlt(aiTargetData, "ContentsFullness" + ItemType)
    ItemType = JIntMap.nextKey(SCLib.JI_ItemTypes, ItemType, -1)
  EndWhile
  Float Max = SCLib.getMax(akTarget)
  If Total > Max && JMap.getInt(aiTargetData, "SCLAllowOverflow") == 0 && !SCLib.GodMode1 && SCLib.canVomit(akTarget)
    Float Delta = Total - Max
    SCLib.vomitAmount(akTarget, Delta, True, 30, True)
    JMap.setInt(aiTargetData, "SCLAllowOverflowTracking", JMap.getInt(aiTargetData, "SCLAllowOverflowTracking") + 1)
    Total -= Delta
    SCLib.addVomitDamage(akTarget)
  ElseIf Total < 0
    Issue("updateFullness return a total of less than 0. Setting to 0")
    Total = 0
  EndIf
  JMap.setFlt(aiTargetData, "STFullness", Total)
  Return Total
EndFunction/;

;/Function updateDamage(Actor akTarget)
  Float Overfull = SCLib.getOverfullPercent(akTarget)
  Int OverfullTier = SCLib.getOverfullTier(Overfull)
  Int CurrentOverfull = SCLib.getCurrentOverfull(akTarget)
  If OverfullTier != CurrentOverfull
    akTarget.AddSpell(SCLib.SCL_OverfullAbilityArray[OverfullTier])
  EndIf

  Float Heavy = SCLib.getHeavyPercent(akTarget)
  Int HeavyTier = SCLib.getHeavyTier(Heavy)
  Int CurrentHeavy = SCLib.getCurrentHeavy(akTarget)
  If HeavyTier != CurrentHeavy
    akTarget.addSpell(SCLib.SCL_HeavyAbilityArray[HeavyTier])
  EndIf
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
