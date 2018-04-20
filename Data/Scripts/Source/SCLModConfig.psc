ScriptName SCLModConfig Extends SKI_ConfigBase
String DebugName = "[SCLMCM ]"
Int DMID = 5
Int ScriptVersion = 1
Function CheckSCLVersion()
  Int StoredVersion = JDB.solveInt(".SCLExtraData.VersionRecords.SCLMenu")
  Bool HasUpdated = False
  ;/If ScriptVersion >= 1 && StoredVersion < 3
    MCMInitialized = False
    Debug.Notification("Beginning update to version 1")
    ;Do stuff here
  EndIf/;
  JDB.solveIntSetter(".SCLExtraData.VersionRecords.SCLMenu", ScriptVersion, True)

  MCMInitialized = True
  If HasUpdated
    Debug.Notification("SCL Updated! Please check your settings.")
  EndIf
EndFunction

;*******************************************************************************
;Variables and Properties
;*******************************************************************************
SCLibrary Property SCLib Auto
SCLDatabase Property SCLData Auto
SCLSettings Property SCLSet Auto

Actor Property PlayerRef Auto

Actor _SelectedActor
Actor Property SelectedActor
  Actor Function Get()
    Return _SelectedActor
  EndFunction
  Function Set(Actor a_Actor)
    _SelectedActor = a_Actor
    SelectedData = SCLib.getTargetData(a_Actor, True)
    SelectedActorName = a_Actor.GetLeveledActorBase().GetName()
  EndFunction
EndProperty
Int Property SelectedData Auto
String Property SelectedActorName Auto

Int Property SelectedEquipmentTier Auto
Message Property SCL_MES_UIExtensions Auto
Message Property SCL_MES_Nioverride Auto

Bool Property MCMInitialized Auto
;Variables *********************************************************************
Bool Property TriggerVomit = False Auto
Bool Property TriggerVomitEverything = False Auto
Actor Property VomitTarget = None Auto
Bool Property SCLResetted = False Auto
;Events ************************************************************************
Event OnConfigInit()
  checkBaseDependencies()
EndEvent

Function initializeMCM()
  Pages = new String[4]
  Pages[0] = "$Actor Information"
  Pages[1] = "$Actor Perks"
  Pages[2] = "$Actor Records"
  Pages[3] = "$Settings"
  SCLib.startupAllQuests()
  MCMInitialized = True
  Int MenuEvent = ModEvent.Create("SCLMenuStart")
  ModEvent.Send(MenuEvent)
EndFunction

Event OnGameReload()
  Parent.OnGameReload()
  If SCLResetted
    JDB.solveObjSetter(".SCLExtraData.ReloadList", JValue.readFromFile(JContainers.userDirectory() + "SCLReloadList.json"), True)
    SCLResetted = False
  EndIf
  If MCMInitialized
    Notice("SCL Reloaded!")
    CheckSCLVersion()
    checkBaseDependencies()
    SCLData.setupInstalledMods()
    reloadMaintenence()
  EndIf
EndEvent

Event OnConfigClose()
  If TriggerVomit
    Notice("Starting vomit for " + SCLib.nameGet(VomitTarget))
    SCLib.vomitAll(VomitTarget, TriggerVomitEverything, TriggerVomitEverything)
    SCLib.quickUpdate(VomitTarget, True)
  EndIf
  TriggerVomit = False
  TriggerVomitEverything = False
  VomitTarget = None
EndEvent

Event OnPageReset(string a_page)
  If !MCMInitialized
    AddTextOptionST("StartMod_T", "Start SCL", "")
  ElseIf(a_page == "$Actor Information")
    SetCursorFillMode(LEFT_TO_RIGHT)
    AddMenuOptionST("SelectedActor_M", "$Actor", SelectedActorName);0
    If SelectedActor
      AddToggleOptionST("TriggerVomit_TOG", "$Induce Vomiting", TriggerVomit);2
      If VomitTarget
        AddTextOptionST("VomitTargetDisplay_T", "$Vomit Target", VomitTarget.GetLeveledActorBase().GetName());1

        If TriggerVomit && SCLSet.DebugEnable
          AddToggleOptionST("VomitEverything_TOG", "$Remove Everything", TriggerVomitEverything);3
        Else
          AddEmptyOption()
          TriggerVomitEverything = False
        EndIf
      Else
        AddEmptyOption()
        AddEmptyOption()
      EndIf
    EndIf
    SetCursorFillMode(TOP_TO_BOTTOM)
    If SelectedActor
      If SCLSet.DebugEnable
        AddSliderOptionST("EditBase_S", "$Base Capacity", JMap.getFlt(SelectedData, "STBase"), "{1} Units")  ;4
        AddSliderOptionST("EditStretch_S", "$Stretch", JMap.getFlt(SelectedData, "STStretch"), "Base x {1}")
        AddTextOptionST("AdjBaseDisplay_T", "$Adjusted Base", SCLib.getAdjBase(SelectedActor))
        AddSliderOptionST("EditDigestRate_S", "$Digestion Rate", JMap.getFlt(SelectedData, "STDigestionRate"), "{1} Units per Hour")
        AddSliderOptionST("EditGluttony_S", "$Gluttony", JMap.getFlt(SelectedData, "SCLGluttony"), "{0}")
      Else
        AddTextOptionST("DisplayBase_T", "$Base Capacity", SCLib.roundFlt(JMap.getFlt(SelectedData, "STBase"), 1))
        AddTextOptionST("DisplayStretch_T", "$Stretch", SCLib.roundFlt(JMap.getFlt(SelectedData, "STStretch"), 1))
        AddTextOptionST("AdjBaseDisplay_T", "$Adjusted Base", SCLib.getAdjBase(SelectedActor))
        AddTextOptionST("DisplayDigestRate_T", "$Base Digestion Rate", SCLib.roundFlt(JMap.getFlt(SelectedData, "STDigestionRate"), 1))
        AddTextOptionST("DisplayGluttony_T", "$Gluttony", JMap.getFlt(SelectedData, "SCLGluttony"))
      EndIf
      AddTextOptionST("DisplayFullness_T", "$Fullness", JMap.getFlt(SelectedData, "STFullness"))  ;12
      AddTextOptionST("DisplayMax_T", "$Max Capacity", SCLib.getMax(SelectedActor)) ;14

  		AddMenuOptionST("DisplayStomachContents_M", "$Show Stomach Contents", "") ;18
    Else
      AddTextOptionST("ChooseActorMessage_T", "$Choose an actor.", "")
    Endif
  ElseIf a_page == "$Actor Perks"
    SetCursorFillMode(LEFT_TO_RIGHT)
    AddMenuOptionST("SelectedActor_M", "$Actor", SelectedActorName);0
    AddEmptyOption()
    If SelectedActor
      addPerkOption(SelectedActor, "SCLRoomForMore") ;7
      addPerkOption(SelectedActor, "SCLStoredLimitUp") ;9
      addPerkOption(SelectedActor, "SCLHeavyBurden") ;11
      addPerkOption(SelectedActor, "SCLAllowOverflow") ;13
    Else
      AddTextOptionST("ChooseActorMessage_T", "$Choose an actor.", "")
    EndIf
  ElseIf a_page == "$Actor Records"
    SetCursorFillMode(TOP_TO_BOTTOM)
    AddMenuOptionST("SelectedActor_M", "$Actor", SelectedActorName);0
    If SelectedActor
      AddTextOptionST("DisplayTotalDigest_T", "$Total Digested Food", JMap.getFlt(SelectedData, "STTotalDigestedFood")) ;2
      AddTextOptionST("DisplayTotalTimesVomited", "$Total Times Vomited", JMap.getInt(SelectedData, "SCLAllowOverflowTracking")) ;4
      AddTextOptionST("DisplayHighestFullness", "$Highest Fullness Reached", JMap.getFlt(SelectedData, "SCLHighestFullness")) ; 6
    Else
      AddTextOptionST("ChooseActorMessage_T", "$Choose an actor.", "")
    EndIf
  ElseIf a_page == "$Settings"
    SetCursorFillMode(LEFT_TO_RIGHT)
    AddHeaderOption("$Digestion Settings")
    AddHeaderOption("")
    AddSliderOptionST("GlobalDigest_S", "$Global Digestion Rate", SCLSet.GlobalDigestMulti, "x{1}")
    AddSliderOptionST("UpdateRate_S", "$Update Rate", SCLSet.UpdateRate, "Every {1} Seconds")
    AddSliderOptionST("UpdateDelay_S", "$Update Delay", SCLSet.UpdateDelay, "Pause for {1} Seconds")
    AddEmptyOption()

    AddHeaderOption("Expand Settings") ;7
    AddHeaderOption("")
    AddSliderOptionST("DefaultExpandTimer_S", "$Global Expand Timer", SCLSet.DefaultExpandTimer, "Every {1} hours")
    AddSliderOptionST("DefaultExpandBonus_S", "$Global Expand Bonus", SCLSet.DefaultExpandBonus, "{1} units")

    AddHeaderOption("Inflation Settings");11
    AddHeaderOption("")
    AddMenuOptionST("BellyInflateMethod_M", "$Belly Method", SCLSet.InflateMethodArray[SCLSet.BellyInflateMethod])
    AddSliderOptionST("MinBelly_S", "$Belly Minimum Size", SCLSet.BellyMin, "{1}")
    AddSliderOptionST("MaxBelly_S", "$Belly Maximum Size", SCLSet.BellyMax, "{1}")
    AddSliderOptionST("MultiBelly_S", "$Belly Multiplier", SCLSet.BellyMulti, "x{1}")
    AddSliderOptionST("HighScaleBelly_S", "$High-Value Belly Scale", SCLSet.BellyHighScale, "{2}")
    AddSliderOptionST("CurveBelly_S", "$Belly Curve", SCLSet.BellyCurve, "{2}")
    AddSliderOptionST("IncBelly_S", "$Belly Increment", SCLSet.BellyIncr, "{1}") ;17
    AddSliderOptionST("DynEquipModifier_S", "$Dynamic Equipment Multiplier", SCLSet.DynEquipModifier, "x{2}")

    ;/If SCLSet.InflateMethodArray[SCLSet.BellyInflateMethod] == "Equipment"
      AddSliderOptionST("EquipmentTierSelect_S", "Select Tier", SelectedEquipmentTier, "Tier {0}") ;17
      AddSliderOptionST("EquipmentTierEdit_S", "Select Threshold", SCLSet.BEquipmentLevels[SelectedEquipmentTier], "Threshold = {0}")
      AddTextOptionST("ResetEquipmentTiers_T", "Reset All Thresholds", "")
      AddEmptyOption()
    EndIf/;

    AddHeaderOption("$Other Settings")
    AddHeaderOption("")
    AddSliderOptionST("PlayerMessagePOV_S", "$Message POV", SCLSet.PlayerMessagePOV, SCLib.addIntSuffix(SCLSet.PlayerMessagePOV))
    AddKeyMapOptionST("ActionKeyPick_KM", "$Choose Action Key", SCLSet.ActionKey)
    AddToggleOptionST("GodMode1_TOG", "$Enable God Mode", SCLSet.GodMode1)
    AddToggleOptionST("DebugEnable_TOG", "$Debug Mode", SCLSet.DebugEnable)
    If SCLSet.DebugEnable
      AddToggleOptionST("ShowDebugMessages_TOG", "Display Debug Messages", SCLSet.ShowDebugMessages)
      If SCLSet.ShowDebugMessages
        AddToggleOptionST("ShowDebugMessages01_TOG", "Show Message 01", SCLib.getDMEnable(1))
        AddToggleOptionST("ShowDebugMessages02_TOG", "Show Message 02", SCLib.getDMEnable(2))
        AddToggleOptionST("ShowDebugMessages03_TOG", "Show Message 03", SCLib.getDMEnable(3))
        AddToggleOptionST("ShowDebugMessages04_TOG", "Show Message 04", SCLib.getDMEnable(4))
        AddToggleOptionST("ShowDebugMessages05_TOG", "Show Message 05", SCLib.getDMEnable(5))
        AddToggleOptionST("ShowDebugMessages06_TOG", "Show Message 06", SCLib.getDMEnable(6))
      EndIf
    EndIf
  EndIf
EndEvent

;*******************************************************************************
;Options
;*******************************************************************************
State StartMod_T
  Event OnSelectST()
    SetTextOptionValueST("Please Close MCM")
    initializeMCM()
  EndEvent

  Event OnHighlightST()
    SetInfoText("Start Skyrim Capacity Limited")
  EndEvent
EndState

State SelectedActor_M
  Event OnMenuOpenST()
    If !SCLSet.LoadedActors
      SCLSet.LoadedActors = SCLib.getLoadedActors()
    EndIf
    Int NumActors = SCLSet.LoadedActors.length
    Int StartIndex = 0
    String[] ActorNames = Utility.CreateStringArray(NumActors, "")
    Int i = 0
    While i < NumActors
      Actor LoadedActor = SCLSet.LoadedActors[i] as Actor
      If LoadedActor
        If LoadedActor == SelectedActor
          StartIndex = i
        EndIf
        ActorNames[i] = SCLib.nameGet(LoadedActor)
      EndIf
      i += 1
    EndWhile
    SetMenuDialogOptions(ActorNames)
    SetMenuDialogStartIndex(StartIndex)
    SetMenuDialogDefaultIndex(0)
  EndEvent

  Event OnMenuAcceptST(int a_index)
    SelectedActor = SCLSet.LoadedActors[a_index] as Actor
    ForcePageReset()
  EndEvent

  Event OnDefaultST()
    SelectedActor = PlayerRef
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("Which actor?")
  EndEvent
EndState

State VomitTargetDisplay_T
  Event OnHighlightST()
    SetInfoText("Actor currently staged to vomit")
  EndEvent
EndState

State TriggerVomit_TOG
  Event OnSelectST()
    TriggerVomit = !TriggerVomit
    If TriggerVomit
      VomitTarget = SelectedActor
    Else
      VomitTarget = None
    EndIf
    ForcePageReset()
  EndEvent

  Event OnDefaultST()
    TriggerVomit = False
    VomitTarget = None
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    If TriggerVomit
      SetInfoText("Will induce vomiting for " + VomitTarget.GetLeveledActorBase().GetName())
    Else
      SetInfoText("Induce vomiting for the selected actor.")
    EndIf
  EndEvent
EndState

State VomitEverything_TOG
  Event OnSelectST()
    TriggerVomitEverything = !TriggerVomitEverything
    SetToggleOptionValueST(TriggerVomitEverything)
  EndEvent

  Event OnDefaultST()
    TriggerVomitEverything = False
    SetToggleOptionValueST(TriggerVomitEverything)
  EndEvent

  Event OnHighlightST()
    SetInfoText("Vomit everything in the stomach array, completely clean it out and return what it can.")
  EndEvent
EndState

State EditBase_S
	Event OnSliderOpenST()
		SetSliderDialogStartValue(JMap.getFlt(SelectedData, "STBase"))
		SetSliderDialogDefaultValue(JMap.getFlt(SelectedData, "STBase"))
		SetSliderDialogRange(1, 2000)
		SetSliderDialogInterval(1)
	EndEvent

	Event OnSliderAcceptST(Float a_value)
		JMap.setFlt(SelectedData, "STBase", a_value)
		SetSliderOptionValueST(a_value, "{0}")
    ForcePageReset()
	EndEvent

	Event OnDefaultST()
			JMap.setFlt(SelectedData, "STBase", 3)
			SetSliderOptionValueST(3, "{0}")
      ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("Set the actor's base stomach capacity")
	EndEvent
EndState

State DisplayBase_T
  Event OnHighlightST()
    SetInfoText("Actor's base stomach capacity")
  EndEvent
EndState

State EditStretch_S
	Event OnSliderOpenST()
		SetSliderDialogStartValue(JMap.getFlt(SelectedData, "STStretch"))
		SetSliderDialogDefaultValue(JMap.getFlt(SelectedData, "STStretch"))
		SetSliderDialogRange(1, 10)
		SetSliderDialogInterval(0.1)
	EndEvent

	Event OnSliderAcceptST(float a_value)
		JMap.setFlt(SelectedData, "STStretch", a_value)
		SetSliderOptionValueST(a_value, "Base x {1}")
    ForcePageReset()
	EndEvent

	Event OnDefaultST()
		JMap.setFlt(SelectedData, "STStretch", 1.5)
		SetSliderOptionValueST(1.5, "Base x {1}")
    ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("Set how much can the actor's stomach stretch beyond the base.")
	EndEvent
EndState

State DisplayStretch_T
  Event OnHighlightST()
    SetInfoText("How much can the actor's stomach stretch beyond the base.")
  EndEvent
EndState

State AdjBaseDisplay_T
  Event OnHighlightST()
    SetInfoText("Base capacity adjusted for scale")
  EndEvent
EndState

State EditDigestRate_S
	Event OnSliderOpenST()
		SetSliderDialogStartValue(JMap.getFlt(SelectedData, "STDigestionRate"))
		SetSliderDialogDefaultValue(JMap.getFlt(SelectedData, "STDigestionRate"))
		SetSliderDialogRange(0.1, 500)
		SetSliderDialogInterval(0.1)
	EndEvent

	Event OnSliderAcceptST(float a_value)
		JMap.setFlt(SelectedData, "STDigestionRate", a_value)
		SetSliderOptionValueST(a_value, "{1} Units per Hour")
	EndEvent

	Event OnDefaultST()
		JMap.setFlt(SelectedData, "STDigestionRate", 0.5)
		SetSliderOptionValueST(0.5, "{1} Units per Hour")
	EndEvent

	Event OnHighlightST()
		SetInfoText("Set how fast does the actor digest food?")
	EndEvent
EndState

State EditGluttony_S
	Event OnSliderOpenST()
		SetSliderDialogStartValue(JMap.getFlt(SelectedData, "SCLGluttony"))
		SetSliderDialogDefaultValue(JMap.getFlt(SelectedData, "SCLGluttony"))
		SetSliderDialogRange(1, 100)
		SetSliderDialogInterval(1)
	EndEvent

	Event OnSliderAcceptST(float a_value)
		JMap.setFlt(SelectedData, "SCLGluttony", a_value)
		SetSliderOptionValueST(a_value, "{0}")
	EndEvent

	Event OnDefaultST()
		JMap.setFlt(SelectedData, "SCLGluttony", 10)
		SetSliderOptionValueST(10, "{0}")
	EndEvent

	Event OnHighlightST()
		SetInfoText("Set how much the actor likes food.")
	EndEvent
EndState

State DisplayGluttony_T
  Event OnHighlightST()
    SetInfoText("How much the actor likes to eat.")
  EndEvent
EndState

State DisplayDigestRate_T
  Event OnHighlightST()
    SetInfoText("How fast does the actor digest food.")
  EndEvent
EndState

State DisplayFullness_T
  Event OnHighlightST()
    SetInfoText("Actor's current fullness.")
  EndEvent
EndState

State DisplayMax_T
  Event OnHighlightST()
    SetInfoText("Maximum amount of food that the actor can hold.")
  EndEvent
EndState

State DisplayTotalDigest_T
  Event OnHighlightST()
    SetInfoText("Total amount of food that the actor has digested.")
  EndEvent
EndState

State DisplayStomachContents_M
	Event OnMenuOpenST()
    Int JF_CompleteContents = SCLib.getCompleteContents(SelectedActor, SelectedData)
    Int NumEntries = JFormMap.count(JF_CompleteContents)
    String[] FoodEntries = Utility.CreateStringArray(NumEntries, "")
    Int i = 0
    While i < NumEntries
      Form ItemKey = JFormMap.getNthKey(JF_CompleteContents, i)
      Int JM_ItemEntry = JFormMap.getObj(JF_CompleteContents, ItemKey)
      Int ItemType = JMap.getInt(JM_ItemEntry, "ItemType")
      String ItemName = SCLib.nameGet(ItemKey)
      String ShortDesc = SCLib.getShortItemTypeDesc(ItemType)
      String DValue = SCLib.roundFlt(JMap.getFlt(JM_ItemEntry, "DigestValue"), 2)
      String ItemEntry
      If ItemKey as SCLBundle
        ItemEntry = ItemName + "x" + (ItemKey as SCLBundle).NumItems + ": " + ShortDesc + ", " + DValue
      Else
        ItemEntry = ItemName + ": " + ShortDesc + ", " + DValue
      EndIf
      FoodEntries[i] = ItemEntry
      i += 1
    EndWhile
    SetMenuDialogStartIndex(0)
    SetMenuDialogDefaultIndex(0)
    SetMenuDialogOptions(FoodEntries)
  EndEvent

	Event OnHighlightST()
		SetInfoText("Display contents of stomach")
	EndEvent
EndState

State SCLRoomForMore_TA
  Event OnSelectST()
    setPerkOption(SelectedActor, "SCLRoomForMore")
  EndEvent

  Event OnHighlightST()
    setPerkInfo(SelectedActor, "SCLRoomForMore", 1)
  EndEvent
EndState

State SCLRoomForMore_T
	Event OnSelectST()
    ShowMessage(SCLib.getPerkDescription("SCLRoomForMore", SCLib.getCurrentPerkLevel(SelectedActor, "SCLRoomForMore")), False, "OK", "")
	EndEvent

  Event OnHighlightST()
    setPerkInfo(SelectedActor, "SCLRoomForMore", 0)
	EndEvent
EndState

State SCLRoomForMore_TB
	Event OnSelectST()
    ShowMessage(SCLib.getPerkDescription("SCLRoomForMore", SCLib.getCurrentPerkLevel(SelectedActor, "SCLRoomForMore") - 1), False, "OK", "")
	EndEvent

  Event OnHighlightST()
    setPerkInfo(SelectedActor, "SCLRoomForMore", -1)
	EndEvent
EndState

State SCLStoredLimitUp_TA
  Event OnSelectST()
    setPerkOption(SelectedActor, "SCLStoredLimitUp")
  EndEvent

  Event OnHighlightST()
    setPerkInfo(SelectedActor, "SCLStoredLimitUp", 1)
  EndEvent
EndState

State SCLStoredLimitUp_T
	Event OnSelectST()
    ShowMessage(SCLib.getPerkDescription("SCLStoredLimitUp", SCLib.getCurrentPerkLevel(SelectedActor, "SCLStoredLimitUp")), False, "OK", "")
	EndEvent

  Event OnHighlightST()
    setPerkInfo(SelectedActor, "SCLStoredLimitUp", 0)
	EndEvent
EndState

State SCLStoredLimitUp_TB
	Event OnSelectST()
    ShowMessage(SCLib.getPerkDescription("SCLStoredLimitUp", SCLib.getCurrentPerkLevel(SelectedActor, "SCLStoredLimitUp") - 1), False, "OK", "")
	EndEvent

  Event OnHighlightST()
    setPerkInfo(SelectedActor, "SCLStoredLimitUp", -1)
	EndEvent
EndState

State SCLHeavyBurden_TA
  Event OnSelectST()
    setPerkOption(SelectedActor, "SCLHeavyBurden")
  EndEvent

  Event OnHighlightST()
    setPerkInfo(SelectedActor, "SCLHeavyBurden", 1)
  EndEvent
EndState

State SCLHeavyBurden_T
	Event OnSelectST()
    ShowMessage(SCLib.getPerkDescription("SCLHeavyBurden", SCLib.getCurrentPerkLevel(SelectedActor, "SCLHeavyBurden")), False, "OK", "")
	EndEvent

  Event OnHighlightST()
    setPerkInfo(SelectedActor, "SCLHeavyBurden", 0)
	EndEvent
EndState

State SCLHeavyBurden_TB
	Event OnSelectST()
    ShowMessage(SCLib.getPerkDescription("SCLHeavyBurden", SCLib.getCurrentPerkLevel(SelectedActor, "SCLHeavyBurden") - 1), False, "OK", "")
	EndEvent

  Event OnHighlightST()
    setPerkInfo(SelectedActor, "SCLHeavyBurden", -1)
	EndEvent
EndState

State SCLAllowOverflow_TA
  Event OnSelectST()
    setPerkOption(SelectedActor, "SCLAllowOverflow")
  EndEvent

  Event OnHighlightST()
    setPerkInfo(SelectedActor, "SCLAllowOverflow", 1)
  EndEvent
EndState

State SCLAllowOverflow_T
	Event OnSelectST()
    ShowMessage(SCLib.getPerkDescription("SCLAllowOverflow", SCLib.getCurrentPerkLevel(SelectedActor, "SCLAllowOverflow")), False, "OK", "")
	EndEvent

  Event OnHighlightST()
    setPerkInfo(SelectedActor, "SCLAllowOverflow", 0)
	EndEvent
EndState

State SCLAllowOverflow_TB
	Event OnSelectST()
    ShowMessage(SCLib.getPerkDescription("SCLAllowOverflow", SCLib.getCurrentPerkLevel(SelectedActor, "SCLAllowOverflow") - 1), False, "OK", "")
	EndEvent

  Event OnHighlightST()
    setPerkInfo(SelectedActor, "SCLAllowOverflow", -1)
	EndEvent
EndState

;Settings **********************************************************************
State GlobalDigest_S
	Event OnSliderOpenST()
		SetSliderDialogStartValue(SCLSet.GlobalDigestMulti)
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(0.1, 10)
		SetSliderDialogInterval(0.5)
	EndEvent

	Event OnSliderAcceptST(float a_value)
			SCLSet.GlobalDigestMulti = a_value
			SetSliderOptionValueST(SCLSet.GlobalDigestMulti, "x{1}")
	EndEvent

	Event OnDefaultST()
		SCLSet.GlobalDigestMulti = 1
		SetSliderOptionValueST(SCLSet.GlobalDigestMulti, "x{1}")
	EndEvent

	Event OnHighlightST()
		SetInfoText("Multiplies Digestion Rate for all actors")
	EndEvent
EndState

State UpdateRate_S
	Event OnSliderOpenST()
		SetSliderDialogStartValue(SCLSet.UpdateRate)
		SetSliderDialogDefaultValue(10.0)
		SetSliderDialogRange(0.5, 120)
		SetSliderDialogInterval(0.5)
	EndEvent

	Event OnSliderAcceptST(float a_value)
			SCLSet.UpdateRate = a_value
			SetSliderOptionValueST(SCLSet.UpdateRate, "Every {1} Seconds")
	EndEvent

	Event OnDefaultST()
		SCLSet.UpdateRate = 10
		SetSliderOptionValueST(SCLSet.UpdateRate, "Every {1} Seconds")
	EndEvent

	Event OnHighlightST()
		SetInfoText("How often will actor's stomachs update? (real world seconds)")
	EndEvent
EndState

State UpdateDelay_S
	Event OnSliderOpenST()
		SetSliderDialogStartValue(SCLSet.UpdateDelay)
		SetSliderDialogDefaultValue(0.5)
		SetSliderDialogRange(0.1, 10)
		SetSliderDialogInterval(0.1)
	EndEvent

	Event OnSliderAcceptST(float a_value)
			SCLSet.UpdateDelay = a_value
			SetSliderOptionValueST(SCLSet.UpdateDelay, "Pause for {1} Seconds")
	EndEvent

	Event OnDefaultST()
		SCLSet.UpdateDelay = 0.5
		SetSliderOptionValueST(0.5, "Pause for {1} Seconds")
	EndEvent

	Event OnHighlightST()
		SetInfoText("How long to wait in between updating individual actors")
	EndEvent
EndState

State DefaultExpandTimer_S
	Event OnSliderOpenST()
		SetSliderDialogStartValue(SCLSet.DefaultExpandTimer)
		SetSliderDialogDefaultValue(2.0)
		SetSliderDialogRange(0.5, 10)
		SetSliderDialogInterval(0.5)
	EndEvent

	Event OnSliderAcceptST(float a_value)
			SCLSet.DefaultExpandTimer = a_value
			SetSliderOptionValueST(a_value, "Every {1} hours")
	EndEvent

	Event OnDefaultST()
    SCLSet.DefaultExpandTimer = 2
    SetSliderOptionValueST(2, "Every {1} hours")
  EndEvent

	Event OnHighlightST()
		SetInfoText("Sets amount of time one must be overfull before their stomach expands")
	EndEvent
EndState

State DefaultExpandBonus_S
	Event OnSliderOpenST()
		SetSliderDialogStartValue(SCLSet.DefaultExpandBonus)
		SetSliderDialogDefaultValue(2.0)
		SetSliderDialogRange(0.0, 10)
		SetSliderDialogInterval(0.1)
	EndEvent

	Event OnSliderAcceptST(float a_value)
			SCLSet.DefaultExpandBonus = a_value
			SetSliderOptionValueST(a_value, "{1} units per expansion")
	EndEvent

	Event OnDefaultST()
    SCLSet.DefaultExpandBonus = 0.5
    SetSliderOptionValueST(0.5, "{1} units per expansion")
  EndEvent

	Event OnHighlightST()
		SetInfoText("Sets base capacity gain per expansion")
	EndEvent
EndState

State BellyInflateMethod_M
	Event OnMenuOpenST()
		SetMenuDialogOptions(SCLSet.InflateMethodArray)
		SetMenuDialogStartIndex(SCLSet.BellyInflateMethod)
		SetMenuDialogDefaultIndex(1)
	EndEvent

	Event OnMenuAcceptST(int a_index)
		SCLSet.BellyInflateMethod = a_index
    ForcePageReset()
	EndEvent

	Event OnDefaultST()
    SCLSet.BellyInflateMethod = 1
    ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("How should inflation be enabled? (RaceMenu/NetImmerse required for some methods)")
	EndEvent
EndState

State MinBelly_S
	Event OnSliderOpenST()
		SetSliderDialogStartValue(SCLSet.BellyMin)
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(0.1, 10)
		SetSliderDialogInterval(0.1)
	EndEvent

	Event OnSliderAcceptST(float a_value)
		SCLSet.BellyMin = a_value
    ForcePageReset()
	EndEvent

	Event OnDefaultST()
		SCLSet.BellyMin = 1
    ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("Minimum Belly Size")
	EndEvent
EndState

State MaxBelly_S
	Event OnSliderOpenST()
		SetSliderDialogStartValue(SCLSet.BellyMax)
		SetSliderDialogDefaultValue(10)
		SetSliderDialogRange(0.5, 1000)
		SetSliderDialogInterval(0.5)
	EndEvent

	Event OnSliderAcceptST(float a_value)
		SCLSet.BellyMax = a_value
    ForcePageReset()
	EndEvent

	Event OnDefaultST()
		SCLSet.BellyMax = 10
    ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("Maximum Belly Size")
	EndEvent
EndState

State MultiBelly_S
	Event OnSliderOpenST()
		SetSliderDialogStartValue(SCLSet.BellyMulti)
		SetSliderDialogDefaultValue(1.0)
		SetSliderDialogRange(0.1, 10)
		SetSliderDialogInterval(0.1)
	EndEvent

	Event OnSliderAcceptST(float a_value)
		SCLSet.BellyMulti = a_value
    SetSliderOptionValueST(SCLSet.BellyMulti, "x{1}")

	EndEvent

	Event OnDefaultST()
		SCLSet.BellyMulti = 1
    SetSliderOptionValueST(1, "x{1}")

	EndEvent

	Event OnHighlightST()
		SetInfoText("Belly Size Multiplier")
	EndEvent
EndState

State IncBelly_S
	Event OnSliderOpenST()
		SetSliderDialogStartValue(SCLSet.BellyIncr)
		SetSliderDialogDefaultValue(0.1)
		SetSliderDialogRange(0.1, 1)
		SetSliderDialogInterval(0.1)
	EndEvent

	Event OnSliderAcceptST(float a_value)
		SCLSet.BellyIncr = a_value
		SLIF_Main.updateActorList("Skyrim Capacity Limited", "NPC Belly", -1, -1, -1, "SCLimited.esp", -1, -1, -1, a_value)
		SetSliderOptionValueST(SCLSet.BellyIncr, "{1}")
	EndEvent

	Event OnDefaultST()
		SCLSet.BellyIncr = 0.1
		SLIF_Main.updateActorList("Skyrim Capacity Limited", "NPC Belly", -1, -1, -1, "SCLimited.esp", -1, -1, -1, 0.1)
		SetSliderOptionValueST(SCLSet.BellyIncr, "{1}")
	EndEvent

	Event OnHighlightST()
		SetInfoText("When stomach size increases, in what increments will it do so?")
	EndEvent
EndState

State HighScaleBelly_S
  Event OnSliderOpenST()
    SetSliderDialogStartValue(SCLSet.BellyHighScale)
    SetSliderDialogDefaultValue(0)
    SetSliderDialogRange(-0.5, 0)
    SetSliderDialogInterval(0.01)
  EndEvent

  Event OnSliderAcceptST(float a_value)
    SCLSet.BellyHighScale = a_value
    SetSliderOptionValueST(a_value, "{2}")
  EndEvent

  Event OnDefaultST()
    SCLSet.BellyHighScale = 0
    SetSliderOptionValueST(0, "{2}")
  EndEvent

  Event OnHighlightST()
    SetInfoText("Dampens scaling at higher body weights")
  EndEvent
EndState

State CurveBelly_S
  ;Thanks darkconsole!
  Event OnSliderOpenST()
    SetSliderDialogStartValue(SCLSet.BellyCurve)
    SetSliderDialogDefaultValue(1.75)
    SetSliderDialogRange(0.5, 2)
    SetSliderDialogInterval(0.05)
  EndEvent

  Event OnSliderAcceptST(float a_value)
    SCLSet.BellyCurve = a_value
    SetSliderOptionValueST(a_value, "{2}")
  EndEvent

  Event OnDefaultST()
    SCLSet.BellyCurve = 1.75
    SetSliderOptionValueST(1, "{2}")
  EndEvent

  Event OnHighlightST()
    SetInfoText("Dampens size at larger values to better simulate volume. The closer to 0, the more extreme the dampening. Set to 2 to remove dampening entirely.")
  EndEvent
EndState

State DynEquipModifier_S
  Event OnSliderOpenST()
    SetSliderDialogStartValue(SCLSet.DynEquipModifier)
    SetSliderDialogDefaultValue(0.7)
    SetSliderDialogRange(0, 5)
    SetSliderDialogInterval(0.05)
  EndEvent

  Event OnSliderAcceptST(float a_value)
    SCLSet.DynEquipModifier = a_value
    SetSliderOptionValueST(a_value, "x{2}")
  EndEvent

  Event OnDefaultST()
    SCLSet.DynEquipModifier = 0.7
    SetSliderOptionValueST(0.7, "x{2}")
  EndEvent

  Event OnHighlightST()
    SetInfoText("Modifies applied size of Dynamic Equipment.")
  EndEvent
EndState

;/State EquipmentTierSelect_S
  Event OnSliderOpenST()
    SetSliderDialogStartValue(SelectedEquipmentTier)
    SetSliderDialogDefaultValue(1)
    SetSliderDialogRange(1, SCLSet.BEquipmentLevels.length - 1)
    SetSliderDialogInterval(1)
  EndEvent

  Event OnSliderAcceptST(float a_value)
    SelectedEquipmentTier = a_Value as Int
    ForcePageReset()
  EndEvent

  Event OnDefaultST()
    SelectedEquipmentTier = 1
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("Choose tier to edit. This value is the point at which that level will be applied")
  EndEvent
EndState

State EquipmentTierEdit_S
  Event OnSliderOpenST()
    SetSliderDialogStartValue(SCLSet.BEquipmentLevels[SelectedEquipmentTier])
    SetSliderDialogDefaultValue(SCLSet.BEquipmentLevelsDefault[SelectedEquipmentTier])
    SetSliderDialogRange(0, 1000)
    SetSliderDialogInterval(1)
  EndEvent

  Event OnSliderAcceptST(float a_value)
    SCLSet.BEquipmentLevels[SelectedEquipmentTier] = a_value
    SCLib.sortFloatArray(SCLSet.BEquipmentLevels)
    ForcePageReset()
  EndEvent

  Event OnDefaultST()
    SCLSet.BEquipmentLevels[SelectedEquipmentTier] = SCLSet.BEquipmentLevelsDefault[SelectedEquipmentTier]
    SCLib.sortFloatArray(SCLSet.BEquipmentLevels)
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("Set Tier " + SelectedEquipmentTier + "Threshold. Warning: Tiers will be sorted after adjustment")
  EndEvent
EndState

State ResetEquipmentTiers_T
  Event OnSelectST()
    Int i = SCLSet.BEquipmentLevelsDefault.length
    While i
      i -= 1
      SCLSet.BEquipmentLevels[i] = SCLSet.BEquipmentLevelsDefault[i]
    EndWhile
    ShowMessage("Tiers sorted!", False, "OK")
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("Reset all thresholds to default values")
  EndEvent
EndState/;

;Other Settings

State PlayerMessagePOV_S
  Event OnSliderOpenST()
    SetSliderDialogStartValue(SCLSet.PlayerMessagePOV)
    SetSliderDialogDefaultValue(1)
    SetSliderDialogRange(-1, 3)
    SetSliderDialogInterval(1)
  EndEvent

  Event OnSliderAcceptST(float a_value)
    SCLSet.PlayerMessagePOV = a_value as Int
    SetSliderOptionValueST(SCLSet.PlayerMessagePOV, SCLib.AddIntSuffix(SCLSet.PlayerMessagePOV))
  EndEvent

  Event OnDefaultST()
    SCLSet.PlayerMessagePOV = 1
    SetSliderOptionValueST(1, SCLib.AddIntSuffix(1))
  EndEvent

  Event OnHighlightST()
    SetInfoText("Set which point of view messages are displayed in. Zero value will display any message available, prioritizing 3rd, then 1st, then 2nd. -1 will disable these messages.")

  EndEvent
EndState

State ActionKeyPick_KM
	Event OnKeyMapChangeST(int a_keyCode, string a_conflictControl, string a_conflictName)
		Bool Continue = True
		If a_conflictControl != ""
			String msg
			If a_conflictName != ""
				msg = a_conflictControl + ": This key is already registered to " + a_conflictName + ". Are sure you want to continue?"
			Else
				msg = a_conflictControl + ": This key is already registered. Are you sure you want to continue?"
			EndIf
			Continue = ShowMessage(msg, true, "Yes", "No")
		EndIf
		If Continue
			SCLSet.ActionKey = a_keyCode
			SetKeyMapOptionValueST(a_keyCode)
		EndIf
	EndEvent

  Event OnDefaultST()
    SCLSet.ActionKey = 0
    SetKeyMapOptionValueST(0)
  EndEvent

  Event OnHighlightST()
    SetInfoText("Set key for interacting with things")
  EndEvent
EndState

State GodMode1_TOG
	Event OnSelectST()
    SCLSet.GodMode1 = !SCLSet.GodMode1
    SetToggleOptionValueST(SCLSet.GodMode1)
	EndEvent

	Event OnDefaultST()
    SCLSet.GodMode1 = False
    SetToggleOptionValueST(False)
	EndEvent

	Event OnHighlightST()
		SetInfoText("Disables capacity limit. Also disables stomach stretching. Applies to everyone")
	EndEvent
EndState

State DebugEnable_TOG
	Event OnSelectST()
		SCLSet.DebugEnable = !SCLSet.DebugEnable
    ForcePageReset()
	EndEvent

	Event OnDefaultST()
    SCLSet.DebugEnable = False
    ForcePageReset()
	EndEvent

	Event OnHighlightST()
		SetInfoText("Allow debug functions in MCM. Also allows editing actor stats.")
	EndEvent
EndState

State ShowDebugMessages_TOG
  Event OnSelectST()
    SCLSet.ShowDebugMessages = !SCLSet.ShowDebugMessages
    ForcePageReset()
  EndEvent

  Event OnDefaultST()
    SCLSet.ShowDebugMessages = False
    ForcePageReset()
  EndEvent

  Event OnHighlightST()
    SetInfoText("Show debug notifications")
  EndEvent
EndState

State ShowDebugMessages01_TOG
  Event OnSelectST()
    SCLib.togDMEnable(1)
    SetToggleOptionValueST(SCLib.getDMEnable(1))
  EndEvent

  Event OnDefaultST()
    SCLib.setDMEnable(1, False)
    SetToggleOptionValueST(False)
  EndEvent

  Event OnHighlightST()
    SetInfoText("Show debug notifications ID 01 (Library)")
  EndEvent
EndState

State ShowDebugMessages02_TOG
  Event OnSelectST()
    SCLib.togDMEnable(2)
    SetToggleOptionValueST(SCLib.getDMEnable(2))
  EndEvent

  Event OnDefaultST()
    SCLib.setDMEnable(2, False)
    SetToggleOptionValueST(False)
  EndEvent

  Event OnHighlightST()
    SetInfoText("Show debug notifications ID 02")
  EndEvent
EndState

State ShowDebugMessages03_TOG
  Event OnSelectST()
    SCLib.togDMEnable(3)
    SetToggleOptionValueST(SCLib.getDMEnable(3))
  EndEvent

  Event OnDefaultST()
    SCLib.setDMEnable(3, False)
    SetToggleOptionValueST(False)
  EndEvent

  Event OnHighlightST()
    SetInfoText("Show debug notifications ID 03")
  EndEvent
EndState

State ShowDebugMessages04_TOG
  Event OnSelectST()
    SCLib.togDMEnable(4)
    SetToggleOptionValueST(SCLib.getDMEnable(4))
  EndEvent

  Event OnDefaultST()
    SCLib.setDMEnable(4, False)
    SetToggleOptionValueST(False)
  EndEvent

  Event OnHighlightST()
    SetInfoText("Show debug notifications ID 04")
  EndEvent
EndState

State ShowDebugMessages05_TOG
  Event OnSelectST()
    SCLib.togDMEnable(5)
    SetToggleOptionValueST(SCLib.getDMEnable(5))
  EndEvent

  Event OnDefaultST()
    SCLib.setDMEnable(5, False)
    SetToggleOptionValueST(False)
  EndEvent

  Event OnHighlightST()
    SetInfoText("Show debug notifications ID 05")
  EndEvent
EndState

State ShowDebugMessages06_TOG
  Event OnSelectST()
    SCLib.togDMEnable(6)
    SetToggleOptionValueST(SCLib.getDMEnable(6))
  EndEvent

  Event OnDefaultST()
    SCLib.setDMEnable(6, False)
    SetToggleOptionValueST(False)
  EndEvent

  Event OnHighlightST()
    SetInfoText("Show debug notifications ID 06")
  EndEvent
EndState
;*******************************************************************************
;Functions
;*******************************************************************************
Bool Function addPerkOption(Actor akTarget, String asPerkID)
  Int CurrentPerkValue = SCLib.getCurrentPerkLevel(akTarget, asPerkID)
  Int MaxValue = SCLib.getAbilityArray(asPerkID).Length - 1
  If CurrentPerkValue
    If CurrentPerkValue == MaxValue
      AddTextOptionST(asPerkID + "_TB", SCLib.getPerkName(asPerkID, CurrentPerkValue - 1), "Taken")
      AddTextOptionST(asPerkID + "_T", SCLib.getPerkName(asPerkID, CurrentPerkValue), "Taken")
    Else
      AddTextOptionST(asPerkID + "_T", SCLib.getPerkName(asPerkID, CurrentPerkValue), "Taken")
      If SCLSet.DebugEnable
        AddTextOptionST(asPerkID + "_TA", SCLib.getPerkName(asPerkID, CurrentPerkValue + 1), "Take Perk")
      Else
        AddTextOptionST(asPerkID + "_TA", "?????", "Take Perk")
      EndIf
    EndIf
  Else
    AddEmptyOption()
    If SCLSet.DebugEnable
      AddTextOptionST(asPerkID + "_TA", SCLib.getPerkName(asPerkID, CurrentPerkValue + 1), "Take Perk")
    Else
      AddTextOptionST(asPerkID + "_TA", "?????", "?????")
    EndIf
  EndIf
EndFunction


;/Bool Function addPerkOption(Actor akTarget, String asPerkID)
  Int CurrentPerkValue = SCLib.getCurrentPerkLevel(akTarget, asPerkID)
  Bool CanTake = SCLib.canTakePerk(akTarget, asPerkID, SCLSet.DebugEnable)
  If CurrentPerkValue || CanTake
    If CanTake
      AddTextOptionST(asPerkID + "_T", SCLib.getPerkName(asPerkID, CurrentPerkValue + 1), "Take")
    Else
      AddTextOptionST(asPerkID + "_T", SCLib.getPerkName(asPerkID, CurrentPerkValue), "Taken")
    EndIf

    Return True
  Else
    AddTextOptionST(asPerkID + "_T", "?????", "?????")
    Return False
  EndIf
EndFunction/;

Function setPerkOption(Actor akTarget, String asPerkID)
  If SCLib.canTakePerk(akTarget, asPerkID, SCLSet.DebugEnable)
    SCLib.takePerk(akTarget, asPerkID)
    ShowMessage("Perk " + SCLib.getPerkName(asPerkID, SCLib.getCurrentPerkLevel(akTarget, asPerkID)) + " taken! Some perk effects will not show until the menu is exited", False, "OK")
    ForcePageReset()
  Else
    ShowMessage(SCLib.getPerkRequirements(asPerkID, SCLib.getCurrentPerkLevel(akTarget, asPerkID) + 1), False, "OK")
  EndIf
EndFunction

Function setPerkInfo(Actor akTarget, String asPerkID, Int aiPerkLocation)
  Int CurrentPerkValue = SCLib.getCurrentPerkLevel(akTarget, asPerkID)
  If aiPerkLocation >= 1
    SetInfoText(SCLib.getPerkDescription(asPerkID, CurrentPerkValue + aiPerkLocation) + " Next Perk Requirements: " + SCLib.getPerkRequirements(asPerkID, CurrentPerkValue + aiPerkLocation))
  Else
    SetInfoText(SCLib.getPerkDescription(asPerkID, CurrentPerkValue + aiPerkLocation) + ", Requirements: " + SCLib.getPerkRequirements(asPerkID, CurrentPerkValue + aiPerkLocation))
  EndIf
EndFunction


;/Function setPerkInfo(Actor akTarget, String asPerkID)
  Int CurrentPerkValue = SCLib.getCurrentPerkLevel(akTarget, asPerkID)
  Bool CanTake = SCLib.canTakePerk(akTarget, asPerkID, SCLSet.DebugEnable)
  If CurrentPerkValue || CanTake
    If CanTake
      SetInfoText(SCLib.getPerkDescription(asPerkID, CurrentPerkValue + 1) + " " + SCLib.getPerkRequirements(asPerkID, CurrentPerkValue + 1))
    Else
      SetInfoText(SCLib.getPerkDescription(asPerkID, CurrentPerkValue) + " Next Perk Requirements: " + SCLib.getPerkRequirements(asPerkID, CurrentPerkValue + 1))
    EndIf
  Else
    SetInfoText(SCLib.getPerkRequirements(asPerkID, CurrentPerkValue + 1))
  EndIf
EndFunction/;

String Function GetCustomControl(int keyCode)
	If (keyCode == SCLSet.ActionKey)
		Return " SCL Action Key"
	Else
		Return ""
	EndIf
EndFunction

Function reloadMaintenence()
  Int JA_LoadMaintenence = JDB.solveObj(".SCLExtraData.ReloadList")
  Int i = 0
  Int ArrayCount = JArray.count(JA_LoadMaintenence)
  While i < ArrayCount
    Quest SCL_Quest = JArray.getForm(JA_LoadMaintenence, i) as Quest
    SCL_Quest.GetStage()
    i += 1
  EndWhile
EndFunction

Function checkBaseDependencies()
  Bool isJCValid = JContainers.APIVersion() == SCLib.JCReqAPI && JContainers.featureVersion() >= SCLib.JCReqFV
  If !isJCValid
    Debug.MessageBox("JContainers not found, or is installed incorrectly. Please reinstall with the most up to date version")
  EndIf
  If !SCLibrary.isModInstalled("UIExtensions.esp")
    If !SCLSet.HideUIEWarning
      If SCL_MES_UIExtensions.Show() == 1
        SCLSet.HideUIEWarning = True
      EndIf
    EndIf
    SCLSet.UIExtensionsInstalled = False
  Else
    SCLSet.UIExtensionsInstalled = True
    SCLSet.HideUIEWarning = False
  EndIf

  If !SCLibrary.isSKSEPluginInstalled("NiOverride")
    If !SCLSet.HideNiOverrideWarning
      If SCL_MES_Nioverride.Show() == 1
        SCLSet.HideNiOverrideWarning = True
      EndIf
    EndIf
    SCLSet.NiOverrideInstalled = False
  Else
    SCLSet.NiOverrideInstalled = True
    SCLSet.HideNiOverrideWarning = False
  EndIf
EndFunction

;/Mod Reset / Shutdown proceedure
1.)Player activates the "Reset Mod" Event
2.)SCLMenu saves the reload list to JSON
3.)Send reset event, mods that need reset maintenence sets variable in script saying so (SCLResetted = True)
4.)All used JDB data is deleted
5.)Shutdown Skyrim

If Reset
6.)On reload, SCLMenu retrieves reload list, performs reload maintenence
7.)Every mod that needs to do reset maintenence does so in the GetStage() block
  If SCLResetted == True
  Do stuff/;
Function resetMod()
  saveReloadList()
  sendResetEvent()
  Debug.MessageBox("Please close any open menus.")
  Utility.Wait(5)
  deleteAllData()
  ;Shutdown all quests
  SCLResetted = True
EndFunction

Function saveReloadList()
  Notice("Saving Reload List")
  JValue.writeToFile(JDB.solveObj(".SCLExtraData.ReloadList"), JContainers.userDirectory() + "SCLReloadList.json")
EndFunction

Function deleteAllData()
  JDB.setObj("SCLActorData", 0)
  JDB.setObj("SCLExtraData", 0)
  JDB.setObj("SCLItemDatabase", 0)
  JDB.setObj("SCLTrashList", 0)
EndFunction

Function sendResetEvent()
  Int ResetEvent = ModEvent.Create("SCLReset")
  ModEvent.Send(ResetEvent)
EndFunction

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Debug Functions
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Bool Function PlayerThought(Actor akTarget, String sMessage1 = "", String sMessage2 = "", String sMessage3 = "", Int iOverride = 0)
  {Use this to display player information. Returns whether the passed actor is
  the player.
  Make sure sMessage1 is 1st person, sMessage2 is 2nd person, sMessage3 is 3rd person
  Make sure at least one is filled: it will default to it regardless of setting
  Use iOverride to force a particular message}

  If akTarget == PlayerRef
    Int Setting = SCLSet.PlayerMessagePOV
    If Setting == -1
      Return True
    EndIf
    If (sMessage1 && Setting == 1) || iOverride == 1
      Debug.Notification(sMessage1)
    ElseIf (sMessage2 && Setting == 2) || iOverride == 2
      Debug.Notification(sMessage3)
    ElseIf (sMessage3 && Setting == 3) || iOverride == 3
      Debug.Notification(sMessage3)
    ElseIf sMessage3
      Debug.Notification(sMessage3)
    ElseIf sMessage1
      Debug.Notification(sMessage1)
    ElseIf sMessage2
      Debug.Notification(sMessage2)
    Else
      Issue("Empty player thought. Skipping...", 1)
    EndIf
    Return True
  Else
    Return False
  EndIf
EndFunction

Bool Function PlayerThoughtDB(Actor akTarget, String sKey, Int iOverride = 0, Actor[] akActors = None, Int aiActorIndex = -1)
  {Use this to display player information. Returns whether the passed actor is
  the player.
  Pulls message from database; make sure sKey is valid.
  Will add POV int to end of key, so omit it in the parameter}
  Return SCLib.ShowPlayerThoughtDB(akTarget, sKey, iOverride, akActors, aiActorIndex)
EndFunction

Function Popup(String sMessage)
  SCLib.ShowPopup(sMessage, DebugName)
EndFunction

Function Note(String sMessage)
  SCLib.ShowNote(sMessage, DebugName)
EndFunction

Function Notice(String sMessage, Int aiID = 0)
  Int ID
  If aiID > 0
    ID = aiID
  Else
    ID = DMID
  EndIf
  SCLib.showNotice(sMessage, ID, DebugName)
EndFunction

Function Issue(String sMessage, Int iSeverity = 0, Int aiID = 0, Bool bOverride = False)
  Int ID
  If aiID > 0
    ID = aiID
  Else
    ID = DMID
  EndIf
  SCLib.ShowIssue(sMessage, iSeverity, ID, bOverride, DebugName)
EndFunction
