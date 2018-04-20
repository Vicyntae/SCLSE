ScriptName SCLeveledListInjector Extends Quest
{Adds items to leveled lists.}
;/Increase stomach Stretch
  Some kind of stomach relaxer?
  Done: Chamomile, so some kind of white flower, possibly retexture existing ingredients
  Peppermint
  Ginger
  Lemon Tea

Decrease stomach Stretch
  Likely add as a side effect to another item

Increase stomach base
  Maybe keep this effect off specifically, and focus on expand effects

Decrease stomach base
  A temporary negative effect

Increase stretch bonus

Increase digest rate
  Some kind of acidic ingredient, maybe citrus(at least for low levels or temp effects)
  Orange 1
  Lemon
  Pineapple
  Vinegar
  Cleaning fluid  ;Also poisons you
  Dwarven Polish

Decrease digest rate
Increase storage capacity
  Resiliant stomach, so like a muscle toner?
  Maybe decrease stretch as well
  Maybe include as like an activity instead of an item

Increase heavy tier
  Requires ability to hold items, so maybe tie to carry capacity/stamina
  Backbrace enchantment?
  Muscle builder (increases heavy tier, stamina, and carry weight)

Frenzy Item
  Basic Frenzy Item, and one that gives additional buff
/;

LeveledItem Property LItemApothecaryIngredientsCommon75 Auto
LeveledItem Property LItemApothecaryIngredienstUncommon75 Auto
LeveledItem Property LItemIngredientsCommon Auto
LeveledItem Property LItemIngredientsUncommon Auto
LeveledItem Property LItemBarrelFoodSame70 Auto
LeveledItem Property LItemBarrelFoodSame75 Auto
LeveledItem Property LItemMiscVendorMiscItems75 Auto
LeveledItem Property LItemFoodInnCommon Auto

Ingredient Property SCL_MountainFlower01White Auto
Ingredient Property SCL_Lemon Auto
Ingredient Property SCL_Orange Auto
Potion Property SCL_WhiteMountainFlowerTea Auto

Event OnInit()
  SCLibrary.addToReloadList(Self)
  Maintenence()
EndEvent

Function Maintenence()
  _CheckVersion()
EndFunction

Int ScriptVersion = 1
Function _CheckVersion()
  Int StoredVersion = JDB.solveInt(".SCLExtraData.VersionRecords.SCLeveledLists")
  If ScriptVersion >= 1 && StoredVersion < 1
    LItemApothecaryIngredientsCommon75.addForm(SCL_MountainFlower01White, 1, 1)
    LItemIngredientsCommon.addForm(SCL_MountainFlower01White, 1, 1)

    LItemBarrelFoodSame70.addForm(SCL_Lemon, 15, 2)
    LItemBarrelFoodSame75.addForm(SCL_Lemon, 15, 2)
    LItemMiscVendorMiscItems75.addForm(SCL_Lemon, 15, 5)

    LItemBarrelFoodSame70.addForm(SCL_Orange, 5, 2)
    LItemBarrelFoodSame75.addForm(SCL_Orange, 5, 2)
    LItemMiscVendorMiscItems75.addForm(SCL_Orange, 5, 5)

    LItemFoodInnCommon.addForm(SCL_WhiteMountainFlowerTea, 7, 2)


  EndIf

  If ScriptVersion >= 2 && StoredVersion < 2
    ;Stuff Here
  EndIf
  JDB.solveIntSetter(".SCLExtraData.VersionRecords.SCLeveledLists", ScriptVersion, True)
EndFunction
