ScriptName SCLAIPlayerSpell Extends ActiveMagicEffect

Actor Property PlayerRef Auto
Package Property Setting_RunPackage Auto
Event OnEffectStart(Actor akTarget, Actor akCaster)
  If akTarget == PlayerRef
    Game.SetPlayerAIDriven(True)
  EndIf
  ActorUtil.AddPackageOverride(akTarget, Setting_RunPackage, 30, 0)
  akTarget.EvaluatePackage()
EndEvent

Event OnEffectFinish(Actor akTarget, Actor akCaster)
  If akTarget == PlayerRef
    Game.SetPlayerAIDriven(False)
  EndIf
  ActorUtil.RemovePackageOverride(akTarget, Setting_RunPackage)
  akTarget.EvaluatePackage()
EndEvent
