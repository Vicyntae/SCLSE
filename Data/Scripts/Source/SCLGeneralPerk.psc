ScriptName SCLGeneralPerk Extends ActiveMagicEffect
{Magnitude = Perk increase amount (int only)
Use this to add perks onto actors
Set the Perk ID in the script properties, set the Magnitude to set how much}
String Property Setting_PerkID Auto

Event OnEffectStart(Actor akTarget, Actor akCaster)
  Int ActorData = SCLibrary.getActorData(akTarget)
  JMap.setInt(ActorData, Setting_PerkID, JMap.getInt(ActorData, Setting_PerkID) + (GetMagnitude() as Int))
EndEvent
