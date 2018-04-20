ScriptName SCLEditBodyThreadManager Extends Quest

Quest Property SCL_EditBodyQuest Auto

SCLEditBodyThread01 thread01
SCLEditBodyThread02 thread02
SCLEditBodyThread03 thread03
SCLEditBodyThread04 thread04
SCLEditBodyThread05 thread05
SCLEditBodyThread06 thread06
SCLEditBodyThread07 thread07
SCLEditBodyThread08 thread08
SCLEditBodyThread09 thread09
SCLEditBodyThread10 thread10

Event OnInit()
  SCLibrary.addToReloadList(Self)
  SCLibrary Lib = SCLibrary.getSCLibrary()
  SCLSettings Set = SCLibrary.getSCLSettings()

  thread01 = SCL_EditBodyQuest as SCLEditBodyThread01
  thread01.SCLib = Lib
  thread01.SCLSet = Set
  thread01.ThreadID = 1

  thread02 = SCL_EditBodyQuest as SCLEditBodyThread02
  thread02.SCLib = Lib
  thread02.SCLSet = Set
  thread02.ThreadID = 2

  thread03 = SCL_EditBodyQuest as SCLEditBodyThread03
  thread03.SCLib = Lib
  thread03.SCLSet = Set
  thread03.ThreadID = 3

  thread04 = SCL_EditBodyQuest as SCLEditBodyThread04
  thread04.SCLib = Lib
  thread04.SCLSet = Set
  thread04.ThreadID = 4

  thread05 = SCL_EditBodyQuest as SCLEditBodyThread05
  thread05.SCLib = Lib
  thread05.SCLSet = Set
  thread05.ThreadID = 5

  thread06 = SCL_EditBodyQuest as SCLEditBodyThread06
  thread06.SCLib = Lib
  thread06.SCLSet = Set
  thread06.ThreadID = 6

  thread07 = SCL_EditBodyQuest as SCLEditBodyThread07
  thread07.SCLib = Lib
  thread07.SCLSet = Set
  thread07.ThreadID = 7

  thread08 = SCL_EditBodyQuest as SCLEditBodyThread08
  thread08.SCLib = Lib
  thread08.SCLSet = Set
  thread08.ThreadID = 8

  thread09 = SCL_EditBodyQuest as SCLEditBodyThread09
  thread09.SCLib = Lib
  thread09.SCLSet = Set
  thread09.ThreadID = 9

  thread10 = SCL_EditBodyQuest as SCLEditBodyThread10
  thread10.SCLib = Lib
  thread10.SCLSet = Set
  thread10.ThreadID =10

  Maintenence()
EndEvent

Int Function GetStage()
  Maintenence()
  Return Parent.GetStage()
EndFunction

Function Maintenence()
  thread01.RegisterForModEvent("SCL_OnEditBody", "OnEditBodyCall")
  thread02.RegisterForModEvent("SCL_OnEditBody", "OnEditBodyCall")
  thread03.RegisterForModEvent("SCL_OnEditBody", "OnEditBodyCall")
  thread04.RegisterForModEvent("SCL_OnEditBody", "OnEditBodyCall")
  thread05.RegisterForModEvent("SCL_OnEditBody", "OnEditBodyCall")
  thread06.RegisterForModEvent("SCL_OnEditBody", "OnEditBodyCall")
  thread07.RegisterForModEvent("SCL_OnEditBody", "OnEditBodyCall")
  thread08.RegisterForModEvent("SCL_OnEditBody", "OnEditBodyCall")
  thread09.RegisterForModEvent("SCL_OnEditBody", "OnEditBodyCall")
  thread10.RegisterForModEvent("SCL_OnEditBody", "OnEditBodyCall")
EndFunction

Int Function editBodyAsync(Actor akTarget, String asType, Float afValue, String asMethodOverride, Int aiSetOverride, String asShortModKey, String asFullModKey)
  ;Debug.Notification("Edit body async called")
  Int Future
  While !Future
    if !thread01.queued()
      thread01.setThread(akTarget, asType, afValue, asMethodOverride, aiSetOverride, asShortModKey, asFullModKey)
      Future = 1
    ElseIf !thread02.queued()
      thread02.setThread(akTarget, asType, afValue, asMethodOverride, aiSetOverride, asShortModKey, asFullModKey)
      Future = 2
    ElseIf !thread03.queued()
      thread03.setThread(akTarget, asType, afValue, asMethodOverride, aiSetOverride, asShortModKey, asFullModKey)
      Future = 3
    ElseIf !thread04.queued()
      thread04.setThread(akTarget, asType, afValue, asMethodOverride, aiSetOverride, asShortModKey, asFullModKey)
      Future = 4
    ElseIf !thread05.queued()
      thread05.setThread(akTarget, asType, afValue, asMethodOverride, aiSetOverride, asShortModKey, asFullModKey)
      Future = 5
    ElseIf !thread06.queued()
      thread06.setThread(akTarget, asType, afValue, asMethodOverride, aiSetOverride, asShortModKey, asFullModKey)
      Future = 6
    ElseIf !thread07.queued()
      thread07.setThread(akTarget, asType, afValue, asMethodOverride, aiSetOverride, asShortModKey, asFullModKey)
      Future = 7
    ElseIf !thread08.queued()
      thread08.setThread(akTarget, asType, afValue, asMethodOverride, aiSetOverride, asShortModKey, asFullModKey)
      Future = 8
    ElseIf !thread09.queued()
      thread09.setThread(akTarget, asType, afValue, asMethodOverride, aiSetOverride, asShortModKey, asFullModKey)
      Future = 9
    ElseIf !thread10.queued()
      thread10.setThread(akTarget, asType, afValue, asMethodOverride, aiSetOverride, asShortModKey, asFullModKey)
      Future = 10
    Else
      begin_waiting()
    EndIf
  EndWhile
  ;Debug.Notification("Edit body future " + Future + " Found!")
  RaiseEvent_OnEditBodyCall(Future)
  Return Future
EndFunction

Function RaiseEvent_OnEditBodyCall(Int aiFuture)
  Int handle = ModEvent.Create("SCL_OnEditBody")
  If handle
    ModEvent.PushInt(handle, aiFuture)
    ModEvent.Send(handle)
  Else
    ;pass
  EndIf
EndFunction

Function begin_waiting()
  Bool waiting = True
  int i = 0
  While waiting
    if thread01.queued() || thread02.queued() || thread03.queued() || thread04.queued() || thread05.queued() || \
      thread06.queued() || thread07.queued() || thread08.queued() || thread09.queued() || thread10.queued()
      i += 1
      Utility.WaitMenuMode(0.1)
      if i >= 100
        Debug.Trace("Error: All threads have become non-responsive. Please debug this issue or contact the author")
        i = 0
        Return
      EndIf
    Else
      waiting = false
    EndIf
  EndWhile
EndFunction

;/Float Function get_result(Int aiThreadID)
  If aiThreadID == 1 && thread01.isReady()
    Return thread01.getResultEntry()
  ElseIf aiThreadID == 2 && thread02.isReady()
    Return thread02.getResultEntry()
  ElseIf aiThreadID == 3 && thread03.isReady()
    Return thread03.getResultEntry()
  ElseIf aiThreadID == 4 && thread04.isReady()
    Return thread04.getResultEntry()
  ElseIf aiThreadID == 5 && thread05.isReady()
    Return thread05.getResultEntry()
  ElseIf aiThreadID == 6 && thread06.isReady()
    Return thread06.getResultEntry()
  ElseIf aiThreadID == 7 && thread07.isReady()
    Return thread07.getResultEntry()
  ElseIf aiThreadID == 8 && thread08.isReady()
    Return thread08.getResultEntry()
  ElseIf aiThreadID == 9 && thread09.isReady()
    Return thread09.getResultEntry()
  ElseIf aiThreadID == 10 && thread10.isReady()
    Return thread10.getResultEntry()
  Else
    Return -1
  EndIf
EndFunction/;
