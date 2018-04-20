ScriptName SCLRoomForMorePercentBuff Extends ActiveMagicEffect
{Magnitude = % increase in STBase (20 = 20% increase = Base * 1.2)}
Bool Property Setting_Recover Auto
Float StoredDelta
Event OnEffectStart(Actor akTarget, Actor akCaster)
  Int ActorData = SCLibrary.getActorData(akTarget)
  Float DeltaPercent = ((GetMagnitude() as Int) / 100)
  Float Base = JMap.getFlt(ActorData, "STBase")
  Float Delta = Base * DeltaPercent
  SCLibrary.modBase(akTarget, Delta, ActorData)
  StoredDelta = Delta
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
  If Setting_Recover
    Int ActorData = SCLibrary.getActorData(akTarget)
    SCLibrary.modBase(akTarget, -StoredDelta, ActorData)
  EndIf
EndEvent
