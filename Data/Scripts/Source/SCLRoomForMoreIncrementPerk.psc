ScriptName SCLRoomForMoreIncrementPerk Extends ActiveMagicEffect
{Magnitude = Increase in base}
Event OnEffectStart(Actor akTarget, Actor akCaster)
  SCLibrary.modBase(akTarget, GetMagnitude())
  Int ActorData = SCLibrary.getActorData(akTarget)
  JMap.setFlt(ActorData, "SCLRoomForMore", JMap.getFlt(ActorData, "SCLRoomForMore") + 1)
EndEvent
