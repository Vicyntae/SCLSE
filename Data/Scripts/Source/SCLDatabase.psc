ScriptName SCLDatabase Extends Quest

;*******************************************************************************
;Variables and Properties
;*******************************************************************************
String ScriptID = "SCLData"
SCLibrary Property SCLib Auto
SCLSettings Property SCLSet Auto
Bool Property Dawnguard_Initialized Auto
Bool Property HearthFires_Initialized Auto
Bool Property Dragonborn_Initialized Auto
Bool SCLResetted = False

Event OnSCLReset()
  SCLResetted = True
  resetLibraryData()
EndEvent

Function resetLibraryData()
  SCLSet.JI_WM_Actor = 0
  SCLSet.JI_ItemTypes = 0
  SCLSet.JM_TotalValueList = 0
  SCLSet.JA_BellyValuesList = 0
  SCLSet.JM_Messages = 0
  SCLSet.JA_ReloadList = 0
EndFunction

Bool Property DatabaseInitialized Auto
Event OnInit()
  setDatabase()
EndEvent

Int Function GetStage()
  If SCLResetted
    setDatabase()
    SCLResetted = False
  EndIf
  RegisterForModEvent("SCLReset", "OnSCLReset")
  Return Parent.GetStage()
EndFunction

Function setDatabase()
  DatabaseInitialized = False
  setupReloadSystems()
  setupActorData()
  setupLibraryList()
  setupActorMainMenus()
  setupItemTypes()
  setupPerksList()
  setupBellyValues()
  setupTotalValues()
  ;setupDynMorphList()
  setupEditBodyEntries()
  setupMessages()
  setupItemDatabase()
  setupInstalledMods()
  RegisterForModEvent("SCLReset", "OnSCLReset")
  Int SetDatabaseEvent = ModEvent.create("SCLDatabaseSetup")  ;Sends out an event for other scripts to modify database as needed
  ModEvent.Send(SetDatabaseEvent)
  DatabaseInitialized = True
EndFunction

Function setupReloadSystems()
  If !SCLSet.JA_ReloadList
    SCLSet.JA_ReloadList = JArray.object()
    JDB.solveObjSetter(".SCLExtraData.ReloadList", SCLSet.JA_ReloadList, True)
    SCLibrary.addToReloadList(Self)
  EndIf
EndFunction

Function setupActorData()
  JDB.setObj("SCLActorData", JFormMap.object())
EndFunction

Function setupLibraryList()
  If !SCLSet.JA_LibraryList
    SCLSet.JA_LibraryList = JArray.object()
    JDB.solveObjSetter(".SCLExtraData.LibraryList", SCLSet.JA_LibraryList, True)
  EndIf
EndFunction

Function setupActorMainMenus()
  If !SCLSet.JI_WM_Actor
    SCLSet.JI_WM_Actor = JIntMap.object()
    JDB.solveObjSetter(".SCLExtraData.ActorMainMenus", SCLSet.JI_WM_Actor, True)
    SCLibrary.addActorMainMenu(0, "SCL Main Menu", True)
  EndIf
EndFunction

Function setupItemTypes()
  If !SCLSet.JI_ItemTypes
    SCLSet.JI_ItemTypes = JIntMap.object()
    JDB.solveObjSetter(".SCLExtraData.ItemTypeMap", SCLSet.JI_ItemTypes, True)
    SCLibrary.addItemType(1, "Digesting", "Food digesting in actor's stomach.", "ContentsFullness1", True)
    SCLibrary.addItemType(2, "Stored", "Items held within the actor's stomach.", "ContentsFullness2", True)
  EndIf
EndFunction

Function setupPerksList()
  If !SCLSet.JM_PerkIDs
    SCLSet.JM_PerkIDs = JMap.object()
    JDB.solveObjSetter(".SCLExtraData.PerkIDList", SCLSet.JM_PerkIDs, True)

    ;Room For More ***************************************************************
    Int JA_Desc = JArray.object()
    JArray.addStr(JA_Desc, "Increases base capacity.")
    JArray.addStr(JA_Desc, "Increases base capacity by 2.5.")
    JArray.addStr(JA_Desc, "Increases base capacity by 5.")
    JArray.addStr(JA_Desc, "Increases base capacity by 10.")
    JArray.addStr(JA_Desc, "Increases base capacity by 15.")
    JArray.addStr(JA_Desc, "Increases base capacity by 10%.")

    Int JA_Reqs = JArray.object()
    JArray.addStr(JA_Reqs, "No Requirements")
    JArray.addStr(JA_Reqs, "Digest a total of at least 10 units food.")
    JArray.addStr(JA_Reqs, "Digest a total of at least 25 units food.")
    JArray.addStr(JA_Reqs, "Digest a total of at least 45 units food.")
    JArray.addStr(JA_Reqs, "Digest a total of at least 60 units food.")
    JArray.addStr(JA_Reqs, "Digest a total of at least 90 units food.")

    SCLibrary.addPerkID("SCLRoomForMore", JA_Desc, JA_Reqs)

    ;Storage Limit Up ************************************************************
    JA_Desc = JArray.object()
    JArray.addStr(JA_Desc, "Allows you to store items in your stomach.")
    JArray.addStr(JA_Desc, "Increases item storage by 2.")
    JArray.addStr(JA_Desc, "Increases item storage by 2.")
    JArray.addStr(JA_Desc, "Increases item storage by 2.")
    JArray.addStr(JA_Desc, "Increases item storage by 2.")
    JArray.addStr(JA_Desc, "Increases item storage by 2.")

    JA_Reqs = JArray.object()
    JArray.addStr(JA_Reqs, "No Requirements.")
    JArray.addStr(JA_Reqs, "Have a stomach capacity greater than 25.")
    JArray.addStr(JA_Reqs, "Have a stomach capacity greater than 50.")
    JArray.addStr(JA_Reqs, "Have a stomach capacity greater than 75.")
    JArray.addStr(JA_Reqs, "Have a stomach capacity greater than 115.")
    JArray.addStr(JA_Reqs, "Have a stomach capacity greater than 150.")

    SCLibrary.addPerkID("SCLStoredLimitUp", JA_Desc, JA_Reqs)

    ;Heavy Burden ****************************************************************
    JA_Desc = JArray.object()
    JArray.addStr(JA_Desc, "Allows actor to move freely when their weight is high.")
    JArray.addStr(JA_Desc, "Allows actor to move freely when their weight exceeds " + (100 * (1 + 1)) + ".")
    JArray.addStr(JA_Desc, "Allows actor to move freely when their weight exceeds " + (100 * (2 + 1)) + ".")
    JArray.addStr(JA_Desc, "Allows actor to move freely when their weight exceeds " + (100 * (3 + 1)) + ".")
    JArray.addStr(JA_Desc, "Allows actor to move freely when their weight exceeds " + (100 * (4 + 1)) + ".")
    JArray.addStr(JA_Desc, "Allows actor to move freely when their weight exceeds " + (100 * (5 + 1)) + ".")

    JA_Reqs = JArray.object()
    JArray.addStr(JA_Reqs, "No Requirements.")
    JArray.addStr(JA_Reqs, "Have " + (150 * (1 + 1)) + " units in your stomach at some point and reach level " + (150 * (1 + 1)) / 10 + ".")
    JArray.addStr(JA_Reqs, "Have " + (150 * (2 + 1)) + " units in your stomach at some point and reach level " + (150 * (2 + 1)) / 10 + ".")
    JArray.addStr(JA_Reqs, "Have " + (150 * (3 + 1)) + " units in your stomach at some point and reach level " + (150 * (3 + 1)) / 10 + ".")
    JArray.addStr(JA_Reqs, "Have " + (150 * (4 + 1)) + " units in your stomach at some point and reach level " + (150 * (4 + 1)) / 10 + ".")
    JArray.addStr(JA_Reqs, "Have " + (150 * (5 + 1)) + " units in your stomach at some point and reach level " + (150 * (5 + 1)) / 10 + ".")

    SCLibrary.addPerkID("SCLHeavyBurden", JA_Desc, JA_Reqs)

    ;Allow Overflow ****************************************************************
    JA_Desc = JArray.object()
    JArray.addStr(JA_Desc, "Allows actor to eat above the maximum without vomiting (other effects may apply).")
    JArray.addStr(JA_Desc, "Allows actor to eat above the maximum without vomiting (other effects may apply).")

    JA_Reqs = JArray.object()
    JArray.addStr(JA_Reqs, "No Requirements.")
    JArray.addStr(JA_Reqs, "Overeat and vomit at least 30 times, and reach level 30.")

    SCLibrary.addPerkID("SCLAllowOverflow", JA_Desc, JA_Reqs)
  EndIf
EndFunction

Function setupBellyValues()
  If !SCLSet.JA_BellyValuesList
    SCLSet.JA_BellyValuesList = JArray.object()
    JDB.solveObjSetter(".SCLExtraData.BellyValueList", SCLSet.JA_BellyValuesList, True)
    SCLibrary.addBellyValue("STFullness")
  EndIf
EndFunction

Function setupTotalValues()
  If !SCLSet.JM_TotalValueList
    SCLSet.JM_TotalValueList = JMap.object()
    JDB.solveObjSetter(".SCLExtraData.TotalValuesList", SCLSet.JM_TotalValueList, True)
    If !SCLSet.JA_BellyValuesList
      setupBellyValues()
    EndIf
    SCLibrary.addTotalValue("SCLStomach", SCLSet.JA_BellyValuesList)
  EndIf
EndFunction

Function setupEditBodyEntries()
  If !SCLSet.JM_BellyInflateData
    ;Debug.Notification("Setting Edit body Entries")
    Int BellyEntry = JMap.object()
    JDB.solveObjSetter(".SCLExtraData.SCLBellyInflateData", BellyEntry, True)
    SCLSet.JM_BellyInflateData = BellyEntry
    JMap.setFlt(BellyEntry, "Multiplier", 1)
    JMap.setFlt(BellyEntry, "HighScale", 0)
    JMap.setFlt(BellyEntry, "Minimum", 1)
    JMap.setFlt(BellyEntry, "Maximum", 10)
    JMap.setFlt(BellyEntry, "Curve", 1.75)
    JMap.setFlt(BellyEntry, "DynEquipMultiplier", 0.7)

    Int JI_DynEquipSetList = JIntMap.object()
    JMap.setObj(BellyEntry, "DynEquipSetList", JI_DynEquipSetList)

    Int DynEntry = JMap.object()
    JIntMap.setObj(JI_DynEquipSetList, 1, DynEntry)
    Int JA_MorphList = JArray.object()
    JMap.setObj(DynEntry, "MorphMap", JA_MorphList)

    Int Morph1 = JMap.object()
    JArray.addObj(JA_MorphList, Morph1)
    JMap.setStr(Morph1, "MorphName", "SCLBigBelly")
    JMap.setFlt(Morph1, "MorphThreshold", -1)

    Armor BellyMesh = Game.GetFormFromFile(0x0200F068, "SCL.esp") as Armor
    JMap.setForm(DynEntry, "DynEquipment", BellyMesh)
    JMap.setObj(DynEntry, "MorphMap", JA_MorphList)

    Int JI_EquipSetList = JIntMap.object()
    JMap.setObj(BellyEntry, "EquipSetList", JI_EquipSetList)

    ;/Int EquipEntry01 = JFormMap.object()
    Armor Armor1 = Game.GetFormFromFile(int aiFormID, "SCL.esp") as Armor
    JFormMap.setFlt(EquipEntry01, Armor1, 10)
    JIntMap.setObj(JI_EquipSetList, 1, EquipEntry01)/;
    ;Debug.Notification("Done setting edit body entries.")
  EndIf
EndFunction

;/Function setupDynMorphList()
  If !SCLSet.JM_DynMorphList
    SCLSet.JM_DynMorphList = JMap.object()
    JDB.solveObjSetter(".SCLExtraData.DynMorphList", SCLSet.JM_DynMorphList, True)
    JMap.setObj(SCLSet.JM_DynMorphList, "Belly", JIntMap.object())

    Int JM_MorphList = JMap.object()
    JMap.setFlt(JM_MorphList, "SCLBigBelly", -1)
    Armor BellyMesh = Game.GetFormFromFile(0x0200F068, "SCL.esp") as Armor
    SCLibrary.addDynMorph(1, "Belly", BellyMesh, JM_MorphList)
  EndIf
EndFunction/;

Function setupMessages()
  If !SCLSet.JM_Messages
    SCLSet.JM_Messages = JMap.object()
    JDB.solveObjSetter(".SCLExtraData.Messages", SCLSet.JM_Messages, True)
    SCLibrary.addMessage("SCLOverfullMessage1", "I think I ate too much.")
    SCLibrary.addMessage("SCLOverfullMessage1", "Too much food...")
    SCLibrary.addMessage("SCLOverfullMessage1", "I think I need to rest for a little while.")
    SCLibrary.addMessage("SCLOverfullMessage1", "It's getting hard to move...")
    ;SCLibrary.addMessage("SCLStarvingMessage1", "")
  EndIf
EndFunction

Function setupItemDatabase()
  ;Input base information here
;Formlists *********************************************************************
  ;SCLSystem.AddSearchFormlist(Formlist Here)
;Keywords ********************************************************************
  Int PotionEntry = SCLibrary.AddSearchKeyword(Game.GetFormFromFile(0x0008cdec, "Skyrim.esm") as Keyword) ;VendorItemPotion
  JMap.setFlt(PotionEntry, "WeightModifier", 0.7)
  JMap.setFlt(PotionEntry, "Durablity", 1.1)
  JMap.setInt(PotionEntry, "IsInContainer", 1)
  JMap.setFlt(PotionEntry, "LiquidRatio", 1)
  JMap.setInt(PotionEntry, "IsDrink", 1)


  Int PoisonEntry = SCLibrary.AddSearchKeyword(Game.GetFormFromFile(0x0008cded, "Skyrim.esm") as Keyword) ;VendorItemPoison
  JMap.setInt(PoisonEntry, "IsNotFood", 1)
  JMap.setInt(PoisonEntry, "IsInContainer", 1)

  ;Generic Entries -------------------------------------------------------------
  Int JM_AlcoholProfile = JMap.object()
  ;"WeightOverride"
  JMap.setFlt(JM_AlcoholProfile, "WeightModifier", 0.8)
  JMap.setFlt(JM_AlcoholProfile, "Durablity", 1.2)
  JMap.setInt(JM_AlcoholProfile, "IsInContainer", 1)
  JMap.setFlt(JM_AlcoholProfile, "LiquidRatio", 1)
  JMap.setInt(JM_AlcoholProfile, "Alcoholic", 1)
  JMap.setInt(JM_AlcoholProfile, "IsDrink", 1)

  ;FirebrandWine
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x0001895F, "Skyrim.esm"), JM_AlcoholProfile)

  ;FoodBlackBriarMead
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x0002c65A, "Skyrim.esm"), JM_AlcoholProfile)

  ;FoodWineAlto
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x0003133b, "Skyrim.esm"), JM_AlcoholProfile)

  ;FoodWineBottle02
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x0003133c, "Skyrim.esm"), JM_AlcoholProfile)

  ;FoodMead
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x00034c5d, "Skyrim.esm"), JM_AlcoholProfile)

  ;Ale
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x00034c5e, "Skyrim.esm"), JM_AlcoholProfile)

  ;MQ201Drink, Colovian Brandy
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x00035d53, "Skyrim.esm"), JM_AlcoholProfile)

  ;FoodHonningbrewMead
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x000508CA, "Skyrim.esm"), JM_AlcoholProfile)

  ;FreeformDragonBridgeMead
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x000555e8, "Skyrim.esm"), JM_AlcoholProfile)

  ;RiftenSpecial01, Velvet LeChance
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x00065c37, "Skyrim.esm"), JM_AlcoholProfile)

  ;RiftenSpecial02, White-Gold Tower
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x00065c38, "Skyrim.esm"), JM_AlcoholProfile)

  ;RiftenSpecial03, Cliff Racer
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x00065c39, "Skyrim.esm"), JM_AlcoholProfile)

  ;FoodSolitudeSpicedWine
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x00085368, "Skyrim.esm"), JM_AlcoholProfile)

  ;AleWhiterunQuest, Argonian Ale
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x0009380d, "Skyrim.esm"), JM_AlcoholProfile)

  ;WEDLO3CyrodilicBrandy
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x000b91d7, "Skyrim.esm"), JM_AlcoholProfile)

  ;FoodWineBottle02A
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x000c5348, "Skyrim.esm"), JM_AlcoholProfile)

  ;FoodWineAltoA
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x000c5349, "Skyrim.esm"), JM_AlcoholProfile)

  ;FavorSorexRum, StrosM'Kai Rum
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x000d055e, "Skyrim.esm"), JM_AlcoholProfile)

  ;MQ101JuniperMead
  JFormDB.setEntry("SCLItemDatabase", Game.GetFormFromFile(0x00107A8A, "Skyrim.esm"), JM_AlcoholProfile)

  ;ALL OF THIS INFORMATION WENT UNUSED!
  ;FOR WHEN I ACTUALLY HAVE STUFF TO PUT IN HERE
  ;All races are going to be integrated into the SCLItemDatabase
  ;Searching for races directly will now return results
  ;/RaceData
  JI_VB_NPCActor = JIntMap.object()

  ;ArgonianRace
  JFormDB.setInt(Game.GetFormFromFile(0x00013740, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00013740, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)
  ;ArgonianRaceVampire
  JFormDB.setInt(Game.GetFormFromFile(0x0008883A, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x0008883A, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)

  ;BretonRace
  JFormDB.setInt(Game.GetFormFromFile(0x00013741, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00013741, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)
  ;BretonRaceVampire
  JFormDB.setInt(Game.GetFormFromFile(0x0005553C, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x0005553C, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)

  ;DarkElfRace
  JFormDB.setInt(Game.GetFormFromFile(0x00013742, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00013742, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)
  ;DarkElfRaceVampire
  JFormDB.setInt(Game.GetFormFromFile(0x0008883D, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x0008883D, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)

  ;ElderRace
  JFormDB.setInt(Game.GetFormFromFile(0x00067CD8, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00067CD8, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)
  ;ElderRaceVampire
  JFormDB.setInt(Game.GetFormFromFile(0x000A82BA, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x000A82BA, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)

  ;ImperialRace
  JFormDB.setInt(Game.GetFormFromFile(0x00013744, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00013744, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)
  ;ImperialRaceVampire
  JFormDB.setInt(Game.GetFormFromFile(0x00088844, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00088844, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)

  ;KhajiitRace
  JFormDB.setInt(Game.GetFormFromFile(0x00013745, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00013745, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)
  ;KhajiitRaceVampire
  JFormDB.setInt(Game.GetFormFromFile(0x00088845, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00088845, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)

  ;NordRace
  JFormDB.setInt(Game.GetFormFromFile(0x00013746, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00013746, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)
  ;NordRaceVampire
  JFormDB.setInt(Game.GetFormFromFile(0x00088794, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00088794, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)

  ;OrcRace
  JFormDB.setInt(Game.GetFormFromFile(0x00013747, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00013747, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)
  ;OrcRaceVampire
  JFormDB.setInt(Game.GetFormFromFile(0x000A82B9, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x000A82B9, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)

  ;RedguardRace
  JFormDB.setInt(Game.GetFormFromFile(0x00013748, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00013748, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)
  ;RedguardRaceVampire
  JFormDB.setInt(Game.GetFormFromFile(0x00088846, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00088846, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)

  ;WoodElfRace
  JFormDB.setInt(Game.GetFormFromFile(0x00013749, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00013749, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)
  ;WoodElfRaceVampire
  JFormDB.setInt(Game.GetFormFromFile(0x00088884, "Skyrim.esm") as Race, ".SCLRaceList.STValidRace", 1)
  JFormDB.setObj(Game.GetFormFromFile(0x00088884, "Skyrim.esm") as Race, ".SCLRaceList.VBEquipment1", JI_VB_NPCActor)/;
EndFunction

String[] Function setupInstalledMods()
  {Searches for specific mods and changes database based on whats there
  Returns string array of mods added or removed}
  Int JA_ModsChanged = JValue.retain(JArray.object())
  Int JFD_Items = JDB.solveObj(".SCLItemDatabase")
;Dawnguard ---------------------------------------------------------------------
  If SCLibrary.isModInstalled("Dawnguard.esm") && !Dawnguard_Initialized
    setupDawnguard(JFD_Items)
    Dawnguard_Initialized = True
    JArray.addStr(JA_ModsChanged, "Added Dawnguard.esm")
  ElseIf !SCLibrary.isModInstalled("Dawnguard.esm") && Dawnguard_Initialized
    removeDawnguard(JFD_Items)
    Dawnguard_Initialized = False
    JArray.addStr(JA_ModsChanged, "Removed Dawnguard.esm")
  EndIf

;HearthFire --------------------------------------------------------------------
  If SCLibrary.isModInstalled("HearthFires.esm") && !HearthFires_Initialized
    setupHearthfires(JFD_Items)
    HearthFires_Initialized = True
    JArray.addStr(JA_ModsChanged, "Added HearthFires.esm")
  ElseIf !SCLibrary.isModInstalled("HearthFires.esm") && HearthFires_Initialized
    removeHearthfires(JFD_Items)
    HearthFires_Initialized = False
    JArray.addStr(JA_ModsChanged, "Removed HearthFires.esm")
  EndIf

;Dragonborn --------------------------------------------------------------------
  If SCLibrary.isModInstalled("Dragonborn.esm") && !Dragonborn_Initialized
    setupDragonborn(JFD_Items)
    Dragonborn_Initialized = True
    JArray.addStr(JA_ModsChanged, "Added Dragonborn.esm")
  ElseIf !SCLibrary.isModInstalled("Dragonborn.esm") && Dragonborn_Initialized
    removeDragonborn(JFD_Items)
    Dragonborn_Initialized = False
    JArray.addStr(JA_ModsChanged, "Removed Dragonborn.esm")
  EndIf

;*******************************************************************************
  String[] Results = Utility.CreateStringArray(JArray.count(JA_ModsChanged), "")
  JArray.writeToStringPArray(JA_ModsChanged, Results)
  JValue.release(JA_ModsChanged)
  Return Results
EndFunction

Function setupDawnguard(Int JFD_Items)
  ;DLC1RedwaterDenSkooma
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x0201391D, "Dawnguard.esm"), ".SCLItemDatabase.WeightModifier", 0.7)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x0201391D, "Dawnguard.esm"), ".SCLItemDatabase.Durability", 1.1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x0201391D, "Dawnguard.esm"), ".SCLItemDatabase.LiquidRatio", 1)

  ;DLC1BloodPotion
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02018EF3, "Dawnguard.esm"), ".SCLItemDatabase.WeightModifier", 0.7)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02018EF3, "Dawnguard.esm"), ".SCLItemDatabase.Durability", 0.8)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02018EF3, "Dawnguard.esm"), ".SCLItemDatabase.LiquidRatio", 1)

EndFunction

Function removeDawnguard(Int JFD_Items)
  ;DLC1RedwaterDenSkooma
  JFormMap.removeKey(JFD_Items, Game.GetFormFromFile(0x0201391D, "Dawnguard.esm"))
  ;DLC1BloodPotion
  JFormMap.removeKey(JFD_Items, Game.GetFormFromFile(0x02018EF3, "Dawnguard.esm"))
EndFunction

Function setupHearthfires(Int JFD_Items)
  ;BYOHFoodMilk
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02003534, "HearthFires.esm"), ".SCLItemDatabase.WeightModifier", 0.7)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02003534, "HearthFires.esm"), ".SCLItemDatabase.Durability", 1.1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02003534, "HearthFires.esm"), ".SCLItemDatabase.LiquidRatio", 0.95)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02003534, "HearthFires.esm"), ".SCLItemDatabase.IsDrink", 1)

  ;BYOHFoodWineBottle04, Argonian Bloodwine
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02003535, "HearthFires.esm"), ".SCLItemDatabase.WeightModifier", 0.7)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02003535, "HearthFires.esm"), ".SCLItemDatabase.Durability", 1.1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02003535, "HearthFires.esm"), ".SCLItemDatabase.LiquidRatio", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02003535, "HearthFires.esm"), ".SCLItemDatabase.IsDrink", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02003535, "HearthFires.esm"), ".SCLItemDatabase.Alcoholic", 1)


  ;BYOHFoodWineBottle03, Surilie Brothers Wine
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02003536, "HearthFires.esm"), ".SCLItemDatabase.WeightModifier", 0.7)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02003536, "HearthFires.esm"), ".SCLItemDatabase.Durability", 1.1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02003536, "HearthFires.esm"), ".SCLItemDatabase.LiquidRatio", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02003536, "HearthFires.esm"), ".SCLItemDatabase.IsDrink", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02003536, "HearthFires.esm"), ".SCLItemDatabase.Alcoholic", 1)

EndFunction

Function removeHearthfires(Int JFD_Items)
  ;BYOHFoodMilk
  JFormMap.removeKey(JFD_Items, Game.GetFormFromFile(0x02003534, "HearthFires.esm"))

  ;BYOHFoodWineBottle04, Argonian Bloodwine
  JFormMap.removeKey(JFD_Items, Game.GetFormFromFile(0x02003535, "HearthFires.esm"))

  ;BYOHFoodWineBottle03, Surilie Brothers Wine
  JFormMap.removeKey(JFD_Items, Game.GetFormFromFile(0x02003536, "HearthFires.esm"))
EndFunction

Function setupDragonborn(Int JFD_Items)
  ;DLC2Flin
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020207e5, "Dragonborn.esm"), ".SCLItemDatabase.WeightModifier", 0.7)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020207e5, "Dragonborn.esm"), ".SCLItemDatabase.Durability", 1.1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020207e5, "Dragonborn.esm"), ".SCLItemDatabase.LiquidRatio", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020207e5, "Dragonborn.esm"), ".SCLItemDatabase.IsDrink", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020207e5, "Dragonborn.esm"), ".SCLItemDatabase.Alcoholic", 1)

  ;DLC2Sujamma
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020207e6, "Dragonborn.esm"), ".SCLItemDatabase.WeightModifier", 0.7)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020207e6, "Dragonborn.esm"), ".SCLItemDatabase.Durability", 1.1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020207e6, "Dragonborn.esm"), ".SCLItemDatabase.LiquidRatio", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020207e6, "Dragonborn.esm"), ".SCLItemDatabase.IsDrink", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020207e6, "Dragonborn.esm"), ".SCLItemDatabase.Alcoholic", 1)


  ;DLC2Shein
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020248CC, "Dragonborn.esm"), ".SCLItemDatabase.WeightModifier", 0.7)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020248CC, "Dragonborn.esm"), ".SCLItemDatabase.Durability", 1.1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020248CC, "Dragonborn.esm"), ".SCLItemDatabase.LiquidRatio", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020248CC, "Dragonborn.esm"), ".SCLItemDatabase.IsDrink", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020248CC, "Dragonborn.esm"), ".SCLItemDatabase.Alcoholic", 1)


  ;DLC2Matze
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020248CE, "Dragonborn.esm"), ".SCLItemDatabase.WeightModifier", 0.7)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020248CE, "Dragonborn.esm"), ".SCLItemDatabase.Durability", 1.1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020248CE, "Dragonborn.esm"), ".SCLItemDatabase.LiquidRatio", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020248CE, "Dragonborn.esm"), ".SCLItemDatabase.IsDrink", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020248CE, "Dragonborn.esm"), ".SCLItemDatabase.Alcoholic", 1)


  ;DLC2RRF04Sujamma
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02024E0B, "Dragonborn.esm"), ".SCLItemDatabase.WeightModifier", 0.7)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02024E0B, "Dragonborn.esm"), ".SCLItemDatabase.Durability", 1.1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02024E0B, "Dragonborn.esm"), ".SCLItemDatabase.LiquidRatio", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02024E0B, "Dragonborn.esm"), ".SCLItemDatabase.IsDrink", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x02024E0B, "Dragonborn.esm"), ".SCLItemDatabase.Alcoholic", 1)


  ;DLC2RRFavor01EmberbrandWine
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020320DF, "Dragonborn.esm"), ".SCLItemDatabase.WeightModifier", 0.7)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020320DF, "Dragonborn.esm"), ".SCLItemDatabase.Durability", 1.1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020320DF, "Dragonborn.esm"), ".SCLItemDatabase.LiquidRatio", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020320DF, "Dragonborn.esm"), ".SCLItemDatabase.IsDrink", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x020320DF, "Dragonborn.esm"), ".SCLItemDatabase.Alcoholic", 1)


  ;DLC2FoodAshfireMead
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x0203572f, "Dragonborn.esm"), ".SCLItemDatabase.WeightModifier", 0.7)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x0203572f, "Dragonborn.esm"), ".SCLItemDatabase.Durability", 1.1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x0203572f, "Dragonborn.esm"), ".SCLItemDatabase.LiquidRatio", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x0203572f, "Dragonborn.esm"), ".SCLItemDatabase.IsDrink", 1)
  JFormDB.solveFltSetter(Game.GetFormFromFile(0x0203572f, "Dragonborn.esm"), ".SCLItemDatabase.Alcoholic", 1)


EndFunction

Function removeDragonborn(Int JFD_Items)
  ;DLC2Flin
  JFormMap.removeKey(JFD_Items, Game.GetFormFromFile(0x020207e5, "Dragonborn.esm"))

  ;DLC2Sujamma
  JFormMap.removeKey(JFD_Items, Game.GetFormFromFile(0x020207e6, "Dragonborn.esm"))

  ;DLC2Shein
  JFormMap.removeKey(JFD_Items, Game.GetFormFromFile(0x020248CC, "Dragonborn.esm"))

  ;DLC2Matze
  JFormMap.removeKey(JFD_Items, Game.GetFormFromFile(0x020248CE, "Dragonborn.esm"))

  ;DLC2RRF04Sujamma
  JFormMap.removeKey(JFD_Items, Game.GetFormFromFile(0x02024E0B, "Dragonborn.esm"))

  ;DLC2RRFavor01EmberbrandWine
  JFormMap.removeKey(JFD_Items, Game.GetFormFromFile(0x020320DF, "Dragonborn.esm"))

  ;DLC2FoodAshfireMead
  JFormMap.removeKey(JFD_Items, Game.GetFormFromFile(0x0203572f, "Dragonborn.esm"))
EndFunction
