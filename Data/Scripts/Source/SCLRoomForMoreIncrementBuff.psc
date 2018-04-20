ScriptName SCLRoomForMoreIncrementBuff Extends ActiveMagicEffect
{Magnitude = Increase in base}
Bool Property Setting_Recover Auto
Event OnEffectStart(Actor akTarget, Actor akCaster)
  SCLibrary.modBase(akTarget, GetMagnitude())
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
  If Setting_Recover
    SCLibrary.modBase(akTarget, -(GetMagnitude()))
  EndIf
EndEvent
