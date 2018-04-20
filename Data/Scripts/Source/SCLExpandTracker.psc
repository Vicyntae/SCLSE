ScriptName SCLExpandTracker Extends ActiveMagicEffect
{Add to effect that checks if an effect has a keyword "SCL_OverfullKeyword"}
SCLibrary Property SCLib Auto
Float LastUpdateTime
Event OnEffectStart(Actor akTarget, Actor akCaster)
  Float Time = SCLib.getExpandTimer(akTarget)
  ;Debug.Notification("Expand tracker starting up! Timer set for " + Time)
  ;RegisterForSingleUpdateGameTime(SCLib.getExpandTimer(akTarget))
  LastUpdateTime = Utility.GetCurrentGameTime()
  RegisterForSingleUpdateGameTime(Time)
EndEvent

Event OnUpdateGameTime()
  Utility.Wait(5)
  Float CurrentUpdateTime = Utility.GetCurrentGameTime()
  Float TimePassed = ((CurrentUpdateTime - (LastUpdateTime))*24) ;In hours
  Float Timer = SCLib.getExpandTimer(GetTargetActor())
  Int NumExpand = Math.Floor(TimePassed / Timer)
  If NumExpand
    Float Expand = SCLib.giveExpandBonus(GetTargetActor(), NumExpand)
    ;Debug.Notification("Expand tracker timer is done! adding expand bonus: " + Expand)
    LastUpdateTime = CurrentUpdateTime
  EndIf
  RegisterForSingleUpdateGameTime(Timer)
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
  ;Debug.Notification("Expand tracker dispelled! Unregistering!")
  UnregisterForUpdateGameTime()
EndEvent
