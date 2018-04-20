ScriptName SCLActorEatThreadManager Extends Quest

Quest Property SCL_ActorEatQuest Auto
SCLActorEatThread01 thread01
SCLActorEatThread02 thread02
SCLActorEatThread03 thread03
SCLActorEatThread04 thread04
SCLActorEatThread05 thread05
SCLActorEatThread06 thread06
SCLActorEatThread07 thread07
SCLActorEatThread08 thread08
SCLActorEatThread09 thread09
SCLActorEatThread10 thread10

Event OnInit()
  SCLibrary.addToReloadList(Self)
  SCLibrary Lib = SCLibrary.getSCLibrary()
  SCLSettings Set = SCLibrary.getSCLSettings()

  thread01 = SCL_ActorEatQuest as SCLActorEatThread01
  thread01.SCLib = Lib
  thread01.SCLSet = Set
  thread01.ThreadID = 1


  thread02 = SCL_ActorEatQuest as SCLActorEatThread02
  thread02.SCLib = Lib
  thread02.SCLSet = Set
  thread02.ThreadID = 2


  thread03 = SCL_ActorEatQuest as SCLActorEatThread03
  thread03.SCLib = Lib
  thread03.SCLSet = Set
  thread03.ThreadID = 3


  thread04 = SCL_ActorEatQuest as SCLActorEatThread04
  thread04.SCLib = Lib
  thread04.SCLSet = Set
  thread04.ThreadID = 4


  thread05 = SCL_ActorEatQuest as SCLActorEatThread05
  thread05.SCLib = Lib
  thread05.SCLSet = Set
  thread05.ThreadID = 5


  thread06 = SCL_ActorEatQuest as SCLActorEatThread06
  thread06.SCLib = Lib
  thread06.SCLSet = Set
  thread06.ThreadID = 6


  thread07 = SCL_ActorEatQuest as SCLActorEatThread07
  thread07.SCLib = Lib
  thread07.SCLSet = Set
  thread07.ThreadID = 7


  thread08 = SCL_ActorEatQuest as SCLActorEatThread08
  thread08.SCLib = Lib
  thread08.SCLSet = Set
  thread08.ThreadID = 8


  thread09 = SCL_ActorEatQuest as SCLActorEatThread09
  thread09.SCLib = Lib
  thread09.SCLSet = Set
  thread09.ThreadID = 9


  thread10 = SCL_ActorEatQuest as SCLActorEatThread10
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
  thread01.RegisterForModEvent("SCL_OnActorEatThread", "OnActorEatCall")
  thread02.RegisterForModEvent("SCL_OnActorEatThread", "OnActorEatCall")
  thread03.RegisterForModEvent("SCL_OnActorEatThread", "OnActorEatCall")
  thread04.RegisterForModEvent("SCL_OnActorEatThread", "OnActorEatCall")
  thread05.RegisterForModEvent("SCL_OnActorEatThread", "OnActorEatCall")
  thread06.RegisterForModEvent("SCL_OnActorEatThread", "OnActorEatCall")
  thread07.RegisterForModEvent("SCL_OnActorEatThread", "OnActorEatCall")
  thread08.RegisterForModEvent("SCL_OnActorEatThread", "OnActorEatCall")
  thread09.RegisterForModEvent("SCL_OnActorEatThread", "OnActorEatCall")
  thread10.RegisterForModEvent("SCL_OnActorEatThread", "OnActorEatCall")
EndFunction

Int Function actorEatAsync(Actor akTarget, Int aiType, Float afDelay, Bool abDisplayAnim)
  Int Future
  While !Future
    if !thread01.queued()
      thread01.setThread(akTarget, aiType, afDelay, abDisplayAnim)
      Future = 1
    ElseIf !thread02.queued()
      thread02.setThread(akTarget, aiType, afDelay, abDisplayAnim)
      Future = 2
    ElseIf !thread03.queued()
      thread03.setThread(akTarget, aiType, afDelay, abDisplayAnim)
      Future = 3
    ElseIf !thread04.queued()
      thread04.setThread(akTarget, aiType, afDelay, abDisplayAnim)
      Future = 4
    ElseIf !thread05.queued()
      thread05.setThread(akTarget, aiType, afDelay, abDisplayAnim)
      Future = 5
    ElseIf !thread06.queued()
      thread06.setThread(akTarget, aiType, afDelay, abDisplayAnim)
      Future = 6
    ElseIf !thread07.queued()
      thread07.setThread(akTarget, aiType, afDelay, abDisplayAnim)
      Future = 7
    ElseIf !thread08.queued()
      thread08.setThread(akTarget, aiType, afDelay, abDisplayAnim)
      Future = 8
    ElseIf !thread09.queued()
      thread09.setThread(akTarget, aiType, afDelay, abDisplayAnim)
      Future = 9
    ElseIf !thread10.queued()
      thread10.setThread(akTarget, aiType, afDelay, abDisplayAnim)
      Future = 10
    Else
      begin_waiting()
    EndIf
  EndWhile
  RaiseEvent_OnActorEatCall(Future)
  Return Future
EndFunction

;/Function wait_all()
  RaiseEvent_OnActorEatCall()
  begin_waiting()
EndFunction/;

Function RaiseEvent_OnActorEatCall(Int aiFuture)
  Int handle = ModEvent.Create("SCL_OnActorEatThread")
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

Float Function get_result(Int aiThreadID)
  Int i
  While i < 100
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
    EndIf
    i += 1
    Utility.Wait(0.5)
  EndWhile
  Return -1
EndFunction
