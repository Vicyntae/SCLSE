ScriptName Lib_SC Extends Quest
{Library API allowing inputs from addons. Library scripts must be registered using SCLibrary.addLibraryScript}
SCLibrary Property SCLib Auto
SCLSettings Property SCLSet Auto
Actor Property PlayerRef Auto

String DebugName = "[Lib_SC] "
Int DMID = 1
Spell[] Function getAbilityArray(String asPerkID)
  Return None
EndFunction

Bool Function canTakePerk(Actor akTarget, String asPerkID, Int aiCurrentPerkLevel, Bool abOverride = False, Int aiTargetData = 0)
  Return False
EndFunction

Int Function addActorStatsMenuOptions(Actor akTarget, Int JA_Description, Int JA_OptionList1, Int JA_OptionList2, Int JA_OptionList3, Int aiTargetData = 0)
  {Return entry names in JArray, Add to provided JArrays}
EndFunction

Int Function addActorContentsMenuOptions(Actor akTarget, Int JA_Description, Int JA_OptionList1, Int JA_OptionList2, Int JA_OptionList3, Int aiTargetData = 0)
EndFunction

Int Function addActorPerksMenuOptions(Actor akTarget, Int JA_Description, Int JA_OptionList1, Int JA_OptionList2, Int JA_OptionList3, Int aiTargetData = 0)
EndFunction

Event OnInit()
  SCLibrary.addLibraryScript(Self)
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

Bool Function PlayerThoughtDB(Actor akTarget, String sKey, Int iOverride = 0)
  {Use this to display player information. Returns whether the passed actor is
  the player.
  Pulls message from database; make sure sKey is valid.
  Will add POV int to end of key, so omit it in the parameter}
  If akTarget == PlayerRef
    Int Setting
    If iOverride != 0
      Setting = iOverride
    Else
      Setting = SCLSet.PlayerMessagePOV
    EndIf
    If Setting == -1
      Return True
    EndIf
    String sMessage = SCLib.getMessage(sKey + Setting)
    If sMessage
      Debug.Notification(sMessage)
    Else
      PlayerThought(akTarget, SCLib.getMessage(sKey + 1), SCLib.getMessage(sKey + 2),SCLib.getMessage(sKey + 3))
    EndIf
    Return True
  Else
    Return False
  EndIf
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
