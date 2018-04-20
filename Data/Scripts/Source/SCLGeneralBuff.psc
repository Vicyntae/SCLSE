ScriptName SCLGeneralBuff Extends ActiveMagicEffect
{Magnitude = Perk increase amount}
String Property Setting_PerkID Auto
Bool Property Setting_Recover Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
  Int ActorData = SCLibrary.getActorData(akTarget)
  JMap.setInt(ActorData, Setting_PerkID, JMap.getInt(ActorData, Setting_PerkID) + (GetMagnitude() as Int))
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
  If Setting_Recover
    Int ActorData = SCLibrary.getActorData(akTarget)
    JMap.setInt(ActorData, Setting_PerkID, JMap.getInt(ActorData, Setting_PerkID) - (GetMagnitude() as Int))
  EndIf
EndEvent
