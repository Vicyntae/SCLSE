ScriptName SCLMonitorFinder Extends Quest
SCLibrary Property SCLib Auto
SCLSettings Property SCLSet Auto
Actor Property PlayerRef Auto
Quest Property SCL_MonitorManagerQuest Auto
String DebugName = "[SCLMonitorFinder] "
Int DMID = 3
;Can we devise a system to prioitize teammates?

Bool Function Start()
  Bool bReturn = Parent.Start()
  ;Notice("Starting up, getting actors")
  If !SCL_MonitorManagerQuest.IsRunning()
    Notice("Monitor Manager not running!")
    Return bReturn
  EndIf
  If !SCLSet.LoadedActors
    SCLSet.LoadedActors = getActors()
  EndIf
  Form[] NewActors = getNewActors()
  Int JA_Teammates = JArray.object()
  ;Notice("Removing no longer loaded actors")
  Int i
  Int LoadedNum = SCLSet.LoadedActors.length
  While i < LoadedNum
    Actor LoadedActor = SCLSet.LoadedActors[i] as Actor
    If LoadedActor && LoadedActor != PlayerRef
      Int j = NewActors.find(LoadedActor)
      If j < 0
        ;Notice(SCLib.nameGet(LoadedActor) + " is not in New Actors list! Removing...")
        SCLSet.LoadedActors[i] = None
        removeFromLoadedActors(LoadedActor, i)
      EndIf
    EndIf
    i += 1
  EndWhile

  ;Notice("Adding new actors")
  i = 0
  LoadedNum = NewActors.length
  While i < LoadedNum
    Actor NewActor = NewActors[i] as Actor
    If NewActor && NewActor != PlayerRef
      Int j = SCLSet.LoadedActors.find(NewActor)
      If j < 0
        ;Notice(SCLib.nameGet(NewActor) + " is not in Monitor Manager! Adding...")
        Int k = addToLoadedActors(NewActor)
        If k != -1
          SCLSet.LoadedActors[k] = NewActor
        Else
          Notice("No slots open!")
        EndIf
      EndIf
    EndIf
    i += 1
  EndWhile
  Return bReturn
EndFunction

;/Event OnInit()
  Notice("Starting up, getting actors")
  If !SCL_MonitorManagerQuest.IsRunning()
    Notice("Monitor Manager not running!")
    Return
  EndIf
  If !SCLib.LoadedActors
    SCLib.LoadedActors = getActors()
  EndIf
  Form[] NewActors = getNewActors()

  ;Notice("Removing no longer loaded actors")
  Int i = SCLib.LoadedActors.length
  While i
    i -= 1
    Actor LoadedActor = SCLib.LoadedActors[i] as Actor
    If LoadedActor && LoadedActor != PlayerRef
      Int j = NewActors.find(LoadedActor)
      If j < 0
        ;Notice(SCLib.nameGet(LoadedActor) + " is not in New Actors list! Removing...")
        SCLib.LoadedActors[i] = None
        removeFromLoadedActors(LoadedActor, i)
      EndIf
    EndIf
  EndWhile

  ;Notice("Adding new actors")
  i = NewActors.length
  While i
    i -= 1
    Actor NewActor = NewActors[i] as Actor
    If NewActor && NewActor != PlayerRef
      Int j = SCLib.LoadedActors.find(NewActor)
      If j < 0
        ;Notice(SCLib.nameGet(NewActor) + " is not in Monitor Manager! Adding...")
        Int k = addToLoadedActors(NewActor)
        If k != -1
          SCLib.LoadedActors[k] = NewActor
        Else
          Notice("No slots open!")
        EndIf
      EndIf
    EndIf
  EndWhile
EndEvent/;

Function removeFromLoadedActors(Actor akTarget, Int i)
  ;Notice("Removing Alias " + i + ": " + akTarget.GetLeveledActorBase().GetName())
  (SCL_MonitorManagerQuest.GetNthAlias(i) as ReferenceAlias).Clear()
  ;/Int i = SCL_MonitorManagerQuest.GetNumAliases()
  While i
    i -= 1
    Notice("Remove: Checking Alias " + i)
    ReferenceAlias LoadedAlias = SCL_MonitorManagerQuest.GetNthAlias(i) as ReferenceAlias
    If LoadedAlias.GetActorReference() == akTarget
      Notice("Remove: Found " akTarget.GetLeveledActorBase().GetName())
      LoadedAlias.Clear()
      Return
    EndIf
  EndWhile/;
EndFunction

Int Function addToLoadedActors(Actor akTarget)
  Int i
  Int NumAlias = SCL_MonitorManagerQuest.GetNumAliases()
  While i < NumAlias
    ;Notice("Add: Checking Alias " + i)
    ReferenceAlias LoadedAlias = SCL_MonitorManagerQuest.GetNthAlias(i) as ReferenceAlias
    If !LoadedAlias.GetActorReference()
      ;Notice("Add: Found empty alias " + i)
      LoadedAlias.ForceRefTo(akTarget)
      ;(LoadedAlias as SCLMonitor).Setup()
      Return i
    EndIf
    i += 1
  EndWhile
  Return -1
EndFunction

Form[] Function getActors()
  Int i
  Int NumAlias = SCL_MonitorManagerQuest.GetNumAliases()
  Form[] ReturnArray = Utility.CreateFormArray(NumAlias, None)
  While i <  NumAlias
    ReferenceAlias LoadedAlias = SCL_MonitorManagerQuest.GetNthAlias(i) as ReferenceAlias
    Actor Target = LoadedAlias.GetActorReference()
    If Target
      ReturnArray[i] = Target
    EndIf
    i += 1
  EndWhile
  Return ReturnArray
EndFunction

Form[] Function getNewActors()
  Int i
  Int NumAlias = GetNumAliases()
  Int JA_Teammates = JArray.object()
  Form[] ReturnArray = Utility.CreateFormArray(NumAlias, None)
  While i < NumAlias
    ReferenceAlias LoadedAlias = GetNthAlias(i) as ReferenceAlias
    Actor Target = LoadedAlias.GetActorReference()
    If Target
      ReturnArray[i] = Target
      If Target.IsPlayerTeammate()
        JArray.addForm(JA_Teammates, Target)
      EndIf
    EndIf
    i += 1
  EndWhile
  If JValue.empty(JA_Teammates) && SCLSet.TeammatesList.length != 0
    SCLSet.TeammatesList = new Form[1]
  Else
    SCLSet.TeammatesList = Utility.CreateFormArray(JArray.count(JA_Teammates))
    JArray.writeToFormPArray(JA_Teammates, SCLSet.TeammatesList)
  EndIf
  Return ReturnArray
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
