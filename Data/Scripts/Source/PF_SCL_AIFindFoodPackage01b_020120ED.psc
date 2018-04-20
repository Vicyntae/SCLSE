;BEGIN FRAGMENT CODE - Do not edit anything between this and the end comment
;NEXT FRAGMENT INDEX 1
Scriptname PF_SCL_AIFindFoodPackage01b_020120ED Extends Package Hidden
Spell Property SCL_AIFindFoodSpellStop01 Auto

;BEGIN FRAGMENT Fragment_0
Function Fragment_0(Actor akActor)
;BEGIN CODE
SCL_AIFindFoodSpellStop01.Cast(akActor)
Int handle = ModEvent.Create("SCL_AIFindFoodPackageComplete")
ModEvent.PushForm(handle, akActor)
ModEvent.Send(handle)
;END CODE
EndFunction
;END FRAGMENT

;END FRAGMENT CODE - Do not edit anything between this and the begin comment
