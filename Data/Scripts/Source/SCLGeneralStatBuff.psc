ScriptName SCLGeneralStatBuff Extends ActiveMagicEffect
{Magnitude = stat increase amount}
String Property Setting_StatKey Auto
Bool Property Setting_Recover Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
  Int ActorData = SCLibrary.getActorData(akTarget)
  JMap.setFlt(ActorData, Setting_StatKey, JMap.getFlt(ActorData, Setting_StatKey) + (GetMagnitude()))
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
  If Setting_Recover
    Int ActorData = SCLibrary.getActorData(akTarget)
    JMap.setFlt(ActorData, Setting_StatKey, JMap.getFlt(ActorData, Setting_StatKey) - (GetMagnitude()))
  EndIf
EndEvent
