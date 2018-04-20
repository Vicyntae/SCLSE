ScriptName SCLMonitorCycle Extends Quest

Quest Property SCLMonitorPickerQuest Auto

Bool Function Start()
  Bool bReturn = Parent.Start()
  ;Debug.Notification("Starting up monitor cycle")
  RegisterForMenu("Sleep/Wait Menu")
  RegisterForSingleUpdate(1)
  Return bReturn
EndFunction

;/Event OnInit()
  If !SCLibrary.getSCLModConfig().MCMInitialized
    Return
  EndIf
  Debug.Notification("Starting up monitor cycle")
  RegisterForSingleUpdate(1)
EndEvent/;

Event OnMenuOpen(String menuName)
  UnregisterForUpdate()
EndEvent

Event OnMenuClose(string menuName)
  RegisterForSingleUpdate(10)
EndEvent

Event OnUpdate()
  SCLMonitorPickerQuest.Stop()

  Int i = 0
  While !SCLMonitorPickerQuest.IsStopped() && i < 50
    Utility.Wait(0.1)
    i += 1
  EndWhile
  SCLMonitorPickerQuest.Start()
  RegisterForSingleUpdate(10)
EndEvent

Function Stop()
  UnregisterForUpdate()
  Parent.Stop()
EndFunction
