ScriptName SCLMonitor Extends ReferenceAlias

Function CheckDataVersion()
EndFunction

String ScriptID = "SCLMonitor"
Int DMID = 2
String Property DebugName
  String Function Get()
    Return "[" + ScriptID + " " + GetID() + ": " + MyActorName + "] "
  EndFunction
EndProperty

SCLibrary Property SCLib Auto
SCLSettings Property SCLSet Auto
Actor _MyActor
Actor Property MyActor
  Actor Function Get()
    Return _MyActor
  EndFunction
  Function Set(Actor a_val)
    If a_val
      _MyActor = a_val
      ActorData = SCLib.getTargetData(a_val, True)
    Else
      _MyActor = None
      ActorData = 0
    EndIf
  EndFunction
EndProperty
Int Property ActorData Auto
Actor Property PlayerRef Auto
String Property MyActorName
  String Function Get()
    If MyActor
      Return MyActor.GetLeveledActorBase().GetName()
    Else
      Return ""
    EndIf
  EndFunction
EndProperty

Bool Property _Lock = False Auto
Function Lock()
  {Prevents multiple threads from running at the same time
  Does not keep track of which thread came first, will pass at first come
  Will break itself after 100 iterations}
  If _Lock
    Int i
    While _Lock && i < 100
      Utility.WaitMenuMode(0.5)
      i += 1
    EndWhile
  EndIf
  _Lock = True
EndFunction

Function Unlock()
  _Lock = False
EndFunction

Bool Property _EXLocked = False Auto
Bool Function LockEX()
  {Exclusionary lock, will toss out any function calls made after the first
  Make sure to return the function after recieving false
  If !LockEX()
    Return
  EndIf}
  If _EXLocked
    Return False
  EndIf
  _EXLocked = True
  Return True
EndFunction

Function UnlockEX()
  _EXLocked = False
EndFunction

Function Setup()
  Lock()
  Actor Target = GetActorReference()
  If Target
    MyActor = Target
  EndIf
  Notice("NPC Monitor Starting!")
  SCLibrary.removeFromActorTrashList(MyActor)
  RegisterForModEvent("SCLQuickUpdate" + ActorData, "OnQuickUpdate")
  RegisterForModEvent("SCLFullUpdate" + ActorData, "OnFullUpdate")
  RegisterForModEvent("SCLDigestFinishEvent", "OnDigestFinish")
  ;RegisterAllAnimEvents()
  Unlock()
EndFunction

Function ForceRefTo(ObjectReference akNewRef)
  ;Notice("ForceRefTo called, performing setup again.")
  If MyActor
    SCLib.quickUpdate(MyActor)
    If !MyActor.GetLeveledActorBase().IsUnique()
      SCLibrary.addToActorTrashList(MyActor, 15)
    Endif
  EndIf
  UnregisterForAllModEvents()
  ;UnregisterAllAnimEvents()
  processing = False
  DigestFinished = False
  Parent.ForceRefTo(akNewRef)
  Setup()
EndFunction

Function Clear()
  If MyActor
    SCLib.quickUpdate(MyActor)
    If !MyActor.GetLeveledActorBase().IsUnique()
      SCLibrary.addToActorTrashList(MyActor, 15)
    EndIf
  EndIf
  UnregisterForAllModEvents()
  ;UnregisterAllAnimEvents()
  processing = False
  DigestFinished = False
  Parent.Clear()
EndFunction

Function reloadMaintenence()
  If MyActor
    CheckDataVersion()
    RegisterForModEvent("SCLQuickUpdate" + ActorData, "OnQuickUpdate")
    RegisterForModEvent("SCLFullUpdate" + ActorData, "OnFullUpdate")
    RegisterForModEvent("SCLDigestFinishEvent", "OnDigestFinish")
  EndIf
EndFunction

Event OnFullUpdate(Float afTimePassed, Float afCurrentUpdateTime, Bool abDailyUpdate)
  fullActorUpdate(afTimePassed, afCurrentUpdateTime, abDailyUpdate)
EndEvent

Event OnQuickUpdate()
  Notice("quickUpdate received")
  Float Percent = SCLib.getOverfullPercent(MyActor)
  If Percent != 0
    Float ReactChance = Utility.RandomFloat()
    ReactChance *= Percent + 1
    If ReactChance >= 0.9
      Note("*Groaning Noise*")
      ;Play groaning topic
      PlayerThoughtDB(MyActor, "SCLOverfullMessage")
    EndIf
  EndIf
EndEvent

Event OnObjectEquipped(Form akBaseObject, ObjectReference akReference)
  If akBaseObject as Potion || akBaseObject as Ingredient
    If JMap.getInt(SCLib.getItemDataEntry(akBaseObject), "STIsNotFood") == 0
      ;Lock()
      Notice(akBaseObject.GetName() + " was eaten!")
      SCLib.addItem(MyActor, akReference, akBaseObject, 1)
      SCLib.updateSingleContents(MyActor, 1)
      SCLib.quickUpdate(MyActor)
      ;Unlock()
    EndIf
  EndIf
EndEvent

Event OnDying(Actor akKiller)
  Notice("Actor died!")
  SCLib.quickUpdate(MyActor)
  Processing = False
  DigestFinished = False
EndEvent

Event OnPackageStart(Package akNewPackage)
  If akNewPackage == SCLSet.Eat || akNewPackage.GetTemplate() == SCLSet.Eat
    Location CurrentLoc = MyActor.GetCurrentLocation()
    If CurrentLoc.HasKeyword(SCLSet.LocTypeInn) || CurrentLoc.HasKeyword(SCLSet.LocTypeHabitationHasInn)
      SCLib.actorEat(MyActor, 2, 1)
    Else
      SCLib.actorEat(MyActor, 1, 1)
    EndIf
  EndIf
EndEvent

Function sendProcessEvent(Float afTimePassed)
  Int ProcessEvent = ModEvent.Create("SCLProcessEvent")
  If ProcessEvent
    ModEvent.pushForm(ProcessEvent, MyActor)
    ModEvent.PushFloat(ProcessEvent, afTimePassed)
    ModEvent.send(ProcessEvent)
  EndIf
EndFunction


Event OnDigestFinish(Form akForm, Float afDigestedAmount)
  If akForm == MyActor && Processing == True
    Processing = False
    DigestFinished = True
  EndIf
EndEvent

Bool DigestFinished = False
Bool Processing = False
;Functions *********************************************************************
Function fullActorUpdate(Float afTimePassed, Float afCurrentUpdateTime, Bool abDailyUpdate)
  If !MyActor
    Return
  EndIf
  ;Note("Starting fullActorUpdate for " + MyActor.GetLeveledActorBase().GetName())
  ;Lock()
  sendProcessEvent(afTimePassed)
  Processing = True
  ;/Int ProcessEvent = ModEvent.Create("SCLProcessEvent")
  ModEvent.pushForm(ProcessEvent, MyActor)
  ModEvent.PushFloat(ProcessEvent, afTimePassed)
  ModEvent.send(ProcessEvent)
  Utility.Wait(2)/;
  ;/Bool Sent = False
  Int ItemType = JIntMap.nextKey(SCLSet.JI_ItemTypes)
  While ItemType
    Int JF_ItemList = SCLib.getContents(MyActor, ItemType, ActorData)
    If !JValue.empty(JF_ItemList)
      Int ProcessEvent = ModEvent.Create("SCLProcessEvent" + ItemType)
      ModEvent.pushForm(ProcessEvent, MyActor)
      ModEvent.pushInt(ProcessEvent, ActorData)
      ModEvent.pushInt(ProcessEvent, JF_ItemList)
      ModEvent.PushFloat(ProcessEvent, afTimePassed)
      ModEvent.send(ProcessEvent)
      Sent = True
    EndIf
    ItemType = JIntMap.nextKey(SCLSet.JI_ItemTypes, ItemType)
  EndWhile
  If Sent
    Utility.Wait(2)
  EndIf/;

  If !DigestFinished
    While !DigestFinished
      Utility.Wait(0.2)
    EndWhile
  EndIf
  DigestFinished = False
  Float Fullness = updateFullness()
  ;Note("Fullness after update = " + Fullness)
  Float Max = SCLib.getMax(MyActor)

  If Fullness < 0
    Issue("updateFullness return a total of less than 0. Setting to 0")
    Fullness = 0
  EndIf

  JMap.setFlt(ActorData, "STFullness", Fullness)
  If Fullness > JMap.getFlt(ActorData, "SCLHighestFullness")
    JMap.setFlt(ActorData, "SCLHighestFullness", Fullness)
  EndIf

  Float Base = SCLib.getAdjBase(MyActor, ActorData)

  If Fullness > Base
    Float Overfull = (Fullness - Base) / (Max - Base)

    Int OverfullTier
    If Overfull > 1
      OverfullTier = 6
    ElseIf Overfull > 0.8
      OverfullTier = 5
    ElseIf Overfull > 0.6
      OverfullTier = 4
    ElseIf Overfull > 0.4
      OverfullTier = 3
    ElseIf Overfull > 0.2
      OverfullTier = 2
    ElseIf Overfull
      OverfullTier = 1
    Else
      OverfullTier = 0
    EndIf

    If Overfull
      OverfullTier += Math.Floor(Fullness / 100) ;Right now, it every 100 units per tier, maybe adjust this to be more extreme
    EndIf

    If OverfullTier > SCLSet.SCL_OverfullHealSpeedArray.length - 1  ;Just using this as a test marker, all spell arrays should be filled the same
      OverfullTier = SCLSet.SCL_OverfullHealSpeedArray.length - 1 ;Ensures that the overfull tier does not go above spells set
    EndIf

    Int CurrentOverfull = JMap.getInt(ActorData, "SCLAppliedOverfullTier")
    If OverfullTier != CurrentOverfull
      SCLSet.SCL_OverfullHealSpeedArray[OverfullTier].cast(MyActor) ;If it's tier 0, it casts the dispel effect and nothing else
      SCLSet.SCL_OverfullStaminaMagicArray[OverfullTier].cast(MyActor)

      JMap.setInt(ActorData, "SCLAppliedOverfullTier", OverfullTier)
    EndIf
  ElseIf JMap.getInt(ActorData, "SCLAppliedOverfullTier")  != 0
    SCLSet.SCL_OverfullHealSpeedArray[0].cast(MyActor) ;If it's tier 0, it casts the dispel effect and nothing else
    JMap.setInt(ActorData, "SCLAppliedOverfullTier", 0)
  EndIf

  Int HeavyPerk = JMap.getInt(ActorData, "SCLHeavyBurden")
  Int BaseWeight = 100 * (HeavyPerk + 1)
  If Fullness > BaseWeight
    Int MaxWeight = 150 * (HeavyPerk + 1)
    Float HeavyPercent = (Fullness - BaseWeight) / (MaxWeight - BaseWeight)
    Int HeavyTier
    If HeavyPercent > 1
      HeavyTier = 6
    ElseIf HeavyPercent > 0.8
      HeavyTier = 5
    ElseIf HeavyPercent > 0.6
      HeavyTier = 4
    ElseIf HeavyPercent > 0.4
      HeavyTier = 3
    ElseIf HeavyPercent > 0.2
      HeavyTier = 2
    ElseIf HeavyPercent
      HeavyTier = 1
    Else
      HeavyTier = 0
    EndIf
    If HeavyTier > SCLSet.SCL_HeavySpeedArray.length - 1
      HeavyTier = SCLSet.SCL_HeavySpeedArray.length - 1
    EndIf

    Int CurrentHeavy = JMap.getInt(ActorData, "SCLAppliedHeavyTier")
    If HeavyTier != CurrentHeavy
      SCLSet.SCL_HeavySpeedArray[HeavyTier].cast(MyActor)
      ;Add more spell arrays here.

      JMap.setInt(ActorData, "SCLAppliedHeavyTier", HeavyTier)
    EndIf
  ElseIf JMap.getInt(ActorData, "SCLAppliedHeavyTier") != 0
    SCLSet.SCL_HeavySpeedArray[0].cast(MyActor)
    JMap.setInt(ActorData, "SCLAppliedHeavyTier", 0)
  EndIf

  Int Storage = SCLib.countItemTypes(MyActor, 2, ActorData)
  Int StorageMax = JMap.getInt(ActorData, "SCLStoredLimitUp")
  If Storage > StorageMax
    Int StorageTier = ((Storage - StorageMax) / 2) + (StorageMax - 1)
    If StorageTier > SCLSet.SCL_StoredDamageArray.length - 1
      StorageTier = SCLSet.SCL_StoredDamageArray.length - 1
    EndIf
    Int CurrentStorageDamage = JMap.getInt(ActorData, "SCLAppliedStorageTier")
    If StorageTier != CurrentStorageDamage

      SCLSet.SCL_StoredDamageArray[StorageTier].cast(MyActor)
      JMap.setInt(ActorData, "SCLAppliedStorageTier", StorageTier)
    EndIf
  ElseIf JMap.getInt(ActorData, "SCLAppliedStorageTier") != 0
    SCLSet.SCL_StoredDamageArray[0].cast(MyActor)
    JMap.setInt(ActorData, "SCLAppliedStorageTier", 0)
  EndIf
  checkAutoEat(Fullness, afCurrentUpdateTime)
  ;SCLib.updateItemProcess(MyActor, afTimePassed)
  ;Float CurrentFullness = SCLib.updateFullness(MyActor, ActorData)
  ;SCLib.updateDamage(MyActor)

  SCLib.visualBellyUpdate(MyActor, SCLib.getTotalBelly(MyActor))
  If abDailyUpdate
    Notice("Performing daily update")
    performDailyUpdate(MyActor)
  Endif
  ;/If Actor hasn't eaten in >8 hours, eat
  Actor eats more based on desire and fullness (will eat to certain fullness + x%)
  Will eat after fighting > 5 min
  Will eat after entering inn/tavern
  If fullness < desire Threshold, will eat
  -4 = uncontrollable drink
  -3 = heavy drink
  -2 = medium drink
  -1 = light drink
  0 = potions
  1 = light snack
  2 = light meal
  3 = Full meal
  4 = uncontrollable eat
  /;
  ;Unlock()
  ;Notice("Finished updating " + akTarget.GetLeveledActorBase().GetName())
EndFunction


Function checkAutoEat(Float afFullness, Float afCurrentUpdateTime)
  If MyActor != PlayerRef
    Float EatTimePassed = ((afCurrentUpdateTime - (JMap.getFlt(ActorData, "LastEatTime")))*24) ;In hours
    Float Glut = SCLib.getGlutMin(akTarget = MyActor, aiTargetData = ActorData)
    Float GlutTime = SCLib.getGlutTime(akTarget = MyActor, aiTargetData = ActorData)
    Int Gluttony = SCLib.getGlutValue(MyActor, ActorData)
    Float Eaten
    If EatTimePassed >= 8
      Notice("Meal not eaten in over 8 hours. Eating...")
      Eaten = SCLib.actorEat(MyActor, 3, 2, True)
      If Eaten
        JMap.setFlt(ActorData, "LastEatTime", afCurrentUpdateTime)
      EndIf
    ElseIf EatTimePassed >= 4
      Location CurrentLoc = MyActor.GetCurrentLocation()
      If CurrentLoc.HasKeyword(SCLSet.LocTypeInn) || CurrentLoc.HasKeyword(SCLSet.LocTypeHabitationHasInn)
        Notice("Meal not eaten in over 4 hours and actor is in tavern. Eating...")
        SCLib.actorEat(MyActor, -2, 60, True)
        Eaten = SClib.actorEat(MyActor, 2, 1, True)
        If Eaten
          JMap.setFlt(ActorData, "LastEatTime", afCurrentUpdateTime)
        EndIf
      EndIf
    ElseIf Gluttony > 50 && EatTimePassed >= GlutTime && afFullness < Glut
      Notice("Meal not eaten in over " + GlutTime + " hours and fullness below + " + Glut + ". Eating...")
      Eaten = SCLib.actorEat(MyActor, 1, 2, True)
    EndIf
    If Eaten == 0 && EatTimePassed >= 24
      If !PlayerThoughtDB(MyActor, "SCLStarvingMessage")
        SCLSet.SCL_AIFindFoodSpell01a.Cast(MyActor)
      EndIf
    EndIf
  EndIf
EndFunction
;/Event OnAnimationEvent(ObjectReference akSource, string asEventName)
  If akSource == MyActor
    Note("Idle Event " + asEventName + " Detected!")
  EndIf
EndEvent/;

Float Function updateFullness()
  {Checks each reported fullness, set "STFullness to it"}
  Int ItemType = JIntMap.nextKey(SCLSet.JI_ItemTypes)
  Float Total
  While ItemType
    String ContentsKey = SCLib.getContentsKey(ItemType)
    If ContentsKey
      Total += JMap.getFlt(ActorData, ContentsKey)
      ItemType = JIntMap.nextKey(SCLSet.JI_ItemTypes, ItemType)
    EndIf
  EndWhile
  ;Note("Final Fullness = " + Total)
  ;Notice("updateFullness for " + nameGet(MyActor) + " returned " + Total)
  Float Max = SCLib.getMax(MyActor, ActorData)
  If Total > Max && !MyActor.HasSpell(SCLSet.SCL_AllowOverflowAbilityArray[1]) && !SCLSet.GodMode1 && SCLib.canVomit(MyActor)
    Float Delta = Total - Max
    SCLib.vomitAmount(MyActor, Delta, True, 30, True, 20)
    Total = SCLib.updateFullnessEX(MyActor, True, ActorData)
    JMap.setInt(ActorData, "SCLAllowOverflowTracking", JMap.getInt(ActorData, "SCLAllowOverflowTracking") + 1)
    SCLib.addVomitDamage(MyActor)
  EndIf
  If Total < 0
    Issue("updateFullness return a total of less than 0. Setting to 0")
    Total = 0
  EndIf
  JMap.setFlt(ActorData, "STFullness", Total)
  If Total > JMap.getFlt(ActorData, "SCLHighestFullness")
    JMap.setFlt(ActorData, "SCLHighestFullness", Total)
  EndIf
  Return Total
EndFunction

Function performDailyUpdate(Actor akTarget)
  {Performs functions that should be done daily.}
  If akTarget.IsPlayerTeammate()
    If SCLib.canTakeAnyPerk(akTarget)
      SCLib.sendTakePerkMessage(akTarget)
    EndIf
  EndIf
EndFunction

;/Function RegisterAllAnimEvents()
  If MyActor
    Note("MyActor found! Registering animations!")
    RegisterForAnimationEvent(MyActor, "ChairEatingSoupStart")
    RegisterForAnimationEvent(MyActor, "IdleBarDrinkingStart")
    RegisterForAnimationEvent(MyActor, "IdleCannibalFeedCrouching_Loose")
    RegisterForAnimationEvent(MyActor, "IdleCannibalFeedStanding_Loose")
    RegisterForAnimationEvent(MyActor, "IdleDrink")
    RegisterForAnimationEvent(MyActor, "IdleDrinkPotion")
    RegisterForAnimationEvent(MyActor, "IdleEatSoup")
    RegisterForAnimationEvent(MyActor, "IdleMQ201Drink")
    RegisterForAnimationEvent(MyActor, "IdleSearchBody")
    RegisterForAnimationEvent(MyActor, "IdleSearchingChest")
    RegisterForAnimationEvent(MyActor, "IdleSearchingTable")
    RegisterForAnimationEvent(MyActor, "IdleTableDrinkAndMugEnterLoose")
    RegisterForAnimationEvent(MyActor, "IdleTableDrinkEnterLoose")
    RegisterForAnimationEvent(MyActor, "IdleTableMugEnterLoose")
    RegisterForAnimationEvent(MyActor, "IdleTablePassOutEnterLoose")
    RegisterForAnimationEvent(MyActor, "LooseFullBodyStagger")
    RegisterForAnimationEvent(MyActor, "VampireFeedingBedLeft_Loose")
    RegisterForAnimationEvent(MyActor, "VampireFeedingBedRight_Loose")
    RegisterForAnimationEvent(MyActor, "VampireFeedingBedRollLeft_Loose")
    RegisterForAnimationEvent(MyActor, "VampireFeedingBedRollRight_Loose")
  Else
    Note("MyActor not found! Unable to register animations!")
  EndIf
EndFunction

Function UnregisterAllAnimEvents()
  If MyActor
    Note("MyActor found! Unregistering animations!")
    UnregisterForAnimationEvent(MyActor, "ChairEatingSoupStart")
    UnregisterForAnimationEvent(MyActor, "IdleBarDrinkingStart")
    UnregisterForAnimationEvent(MyActor, "IdleCannibalFeedCrouching_Loose")
    UnregisterForAnimationEvent(MyActor, "IdleCannibalFeedStanding_Loose")
    UnregisterForAnimationEvent(MyActor, "IdleDrink")
    UnregisterForAnimationEvent(MyActor, "IdleDrinkPotion")
    UnregisterForAnimationEvent(MyActor, "IdleEatSoup")
    UnregisterForAnimationEvent(MyActor, "IdleMQ201Drink")
    UnregisterForAnimationEvent(MyActor, "IdleSearchBody")
    UnregisterForAnimationEvent(MyActor, "IdleSearchingChest")
    UnregisterForAnimationEvent(MyActor, "IdleSearchingTable")
    UnregisterForAnimationEvent(MyActor, "IdleTableDrinkAndMugEnterLoose")
    UnregisterForAnimationEvent(MyActor, "IdleTableDrinkEnterLoose")
    UnregisterForAnimationEvent(MyActor, "IdleTableMugEnterLoose")
    UnregisterForAnimationEvent(MyActor, "IdleTablePassOutEnterLoose")
    UnregisterForAnimationEvent(MyActor, "LooseFullBodyStagger")
    UnregisterForAnimationEvent(MyActor, "VampireFeedingBedLeft_Loose")
    UnregisterForAnimationEvent(MyActor, "VampireFeedingBedRight_Loose")
    UnregisterForAnimationEvent(MyActor, "VampireFeedingBedRollLeft_Loose")
    UnregisterForAnimationEvent(MyActor, "VampireFeedingBedRollRight_Loose")
  Else
    Note("MyActor not found! Unable to unregister animations!")
  EndIf
EndFunction/;



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
