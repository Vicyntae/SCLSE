ScriptName SCLDigestThreadManager Extends Quest

Quest Property SCL_DigestQuest Auto

SCLDigestThread01 thread01
SCLDigestThread02 thread02
SCLDigestThread03 thread03
SCLDigestThread04 thread04
SCLDigestThread05 thread05
SCLDigestThread06 thread06
SCLDigestThread07 thread07
SCLDigestThread08 thread08
SCLDigestThread09 thread09
SCLDigestThread10 thread10

Event OnInit()
  SCLibrary.addToReloadList(Self)
  SCLibrary Lib = SCLibrary.getSCLibrary()
  SCLSettings Set = SCLibrary.getSCLSettings()

  thread01 = SCL_DigestQuest as SCLDigestThread01
  thread01.SCLib = Lib
  thread01.SCLSet = Set
  thread01.ThreadID = 1


  thread02 = SCL_DigestQuest as SCLDigestThread02
  thread02.SCLib = Lib
  thread02.SCLSet = Set
  thread02.ThreadID = 2


  thread03 = SCL_DigestQuest as SCLDigestThread03
  thread03.SCLib = Lib
  thread03.SCLSet = Set
  thread03.ThreadID = 3


  thread04 = SCL_DigestQuest as SCLDigestThread04
  thread04.SCLib = Lib
  thread04.SCLSet = Set
  thread04.ThreadID = 4


  thread05 = SCL_DigestQuest as SCLDigestThread05
  thread05.SCLib = Lib
  thread05.SCLSet = Set
  thread05.ThreadID = 5


  thread06 = SCL_DigestQuest as SCLDigestThread06
  thread06.SCLib = Lib
  thread06.SCLSet = Set
  thread06.ThreadID = 6


  thread07 = SCL_DigestQuest as SCLDigestThread07
  thread07.SCLib = Lib
  thread07.SCLSet = Set
  thread07.ThreadID = 7


  thread08 = SCL_DigestQuest as SCLDigestThread08
  thread08.SCLib = Lib
  thread08.SCLSet = Set
  thread08.ThreadID = 8


  thread09 = SCL_DigestQuest as SCLDigestThread09
  thread09.SCLib = Lib
  thread09.SCLSet = Set
  thread09.ThreadID = 9


  thread10 = SCL_DigestQuest as SCLDigestThread10
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
  thread01.RegisterForModEvent("SCL_OnDigestion", "OnDigestCall")
  thread02.RegisterForModEvent("SCL_OnDigestion", "OnDigestCall")
  thread03.RegisterForModEvent("SCL_OnDigestion", "OnDigestCall")
  thread04.RegisterForModEvent("SCL_OnDigestion", "OnDigestCall")
  thread05.RegisterForModEvent("SCL_OnDigestion", "OnDigestCall")
  thread06.RegisterForModEvent("SCL_OnDigestion", "OnDigestCall")
  thread07.RegisterForModEvent("SCL_OnDigestion", "OnDigestCall")
  thread08.RegisterForModEvent("SCL_OnDigestion", "OnDigestCall")
  thread09.RegisterForModEvent("SCL_OnDigestion", "OnDigestCall")
  thread10.RegisterForModEvent("SCL_OnDigestion", "OnDigestCall")
EndFunction

Int Function digestAsync(Actor akTarget, Float afTimePassed)
  Int Future
  While !Future
    if !thread01.queued()
      thread01.setThread(akTarget, afTimePassed)
      Future = 1
    ElseIf !thread02.queued()
      thread02.setThread(akTarget, afTimePassed)
      Future = 2
    ElseIf !thread03.queued()
      thread03.setThread(akTarget, afTimePassed)
      Future = 3
    ElseIf !thread04.queued()
      thread04.setThread(akTarget, afTimePassed)
      Future = 4
    ElseIf !thread05.queued()
      thread05.setThread(akTarget, afTimePassed)
      Future = 5
    ElseIf !thread06.queued()
      thread06.setThread(akTarget, afTimePassed)
      Future = 6
    ElseIf !thread07.queued()
      thread07.setThread(akTarget, afTimePassed)
      Future = 7
    ElseIf !thread08.queued()
      thread08.setThread(akTarget, afTimePassed)
      Future = 8
    ElseIf !thread09.queued()
      thread09.setThread(akTarget, afTimePassed)
      Future = 9
    ElseIf !thread10.queued()
      thread10.setThread(akTarget, afTimePassed)
      Future = 10
    Else
      begin_waiting()
    EndIf
  EndWhile
  RaiseEvent_OnDigestCall(Future)
  Return Future
EndFunction

Function RaiseEvent_OnDigestCall(Int aiFuture)
  Int handle = ModEvent.Create("SCL_OnDigestion")
  if handle
    ModEvent.PushInt(handle, aiFuture)
    ModEvent.Send(handle)
  else
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
      Utility.Wait(0.1)
      if i >= 100
        Debug.Trace("Error: All threads have become non-responsive. Please debug this issue or contact the author")
        i=0
        Return
      EndIf
    Else
      waiting = false
    EndIf
  EndWhile
EndFunction
