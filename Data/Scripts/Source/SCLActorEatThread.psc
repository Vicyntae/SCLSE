ScriptName SCLActorEatThread Extends Quest Hidden

SCLibrary Property SCLib Auto
SCLSettings Property SCLSet Auto
Bool thread_queued = False
Actor MyActor
Int ActorData
Int MealType
Float Delay
Bool Anim
Int Property ThreadID Auto
Float Result
Bool thread_ready
String Property DebugName
  String Function Get()
    Return "[SCLEatThread" + ThreadID + ": " + MyActor.GetLeveledActorBase().GetName() + "] "
  EndFunction
EndProperty
Int DMID = 6
Float Function getResultEntry()
  thread_ready = False
  thread_queued = False
  Return Result
EndFunction

Function setThread(Actor akTarget, Int aiType, Float afDelay, Bool abDisplayAnim)
  thread_queued = True

  MyActor = akTarget
  ActorData = SCLib.getTargetData(akTarget)
  MealType = aiType
  Delay =  afDelay
  Anim = abDisplayAnim
EndFunction

Bool Function queued()
  return thread_queued
EndFunction

Bool Function isReady()
  Return thread_ready
EndFunction

Bool Function force_unlock()
  clear_thread_vars()
  thread_queued = False
  thread_ready = False
  Return True
EndFunction

Event OnActorEatCall(Int aiID)
  If thread_queued && aiID == ThreadID
    ;Notice("Actor eat call recieved.")
    If Delay > 0
      Utility.Wait(Delay)
    EndIf
    Float EatenAmount
    If MealType == 0
      Notice("Meal type potions recieved.")
      Int NumItems = MyActor.GetNumItems()
      Int i
      Int JA_Take = JArray.object()
      While i < NumItems
        Form Item = MyActor.GetNthForm(i)
        If Item as Potion
          If !(Item as Potion).isFood() || !(Item as Potion).IsPoison()
            MagicEffect[] Effects = (Item as Potion).getMagicEffects()
            Bool Taken
            If !Taken && MyActor.GetActorValuePercentage("Health") < 0.5
              Int HealthFind = Effects.Find(SCLSet.AlchRestoreHealth)
              If HealthFind >= 0
                JArray.addForm(JA_Take, Item)
                EatenAmount += 1
                Taken  = True
                Notice("Taking health potion " + Item.GetName())
              EndIf
            EndIf
            If !Taken && MyActor.GetActorValuePercentage("Stamina") < 0.25
              Int StaminaFind = Effects.Find(SCLSet.AlchRestoreStamina)
              If StaminaFind >= 0
                JArray.addForm(JA_Take, Item)
                EatenAmount += 1
                Taken = True
                Notice("Taking stamina potion " + Item.GetName())
              EndIf
            EndIf
            If !Taken && MyActor.GetActorValuePercentage("Magicka") < 0.25
              Int MagickaFind = Effects.Find(SCLSet.AlchRestoreMagicka)
              If MagickaFind >= 0
                JArray.addForm(JA_Take, Item)
                EatenAmount += 1
                Taken = True
                Notice("Taking magicka potion " + Item.GetName())
              EndIf
            EndIf
          EndIf
        EndIf
        i += 1
      EndWhile
      If !JValue.empty(JA_Take)
        If Anim
          MyActor.PlayIdle(SCLSet.IdleDrinkPotion)
        EndIf
        Int j = JArray.count(JA_Take)
        While j
          j -= 1
          MyActor.EquipItem(JArray.getForm(JA_Take, j))
        EndWhile
      EndIf
    ElseIf MealType < 0
      Notice("Meal type drink, size " + MealType)
      Int Insobriety = SCLib.getInsobValue(MyActor, ActorData)
      Float DrinkSize = SCLib.genMealValue(aiSeverity = Insobriety, aiType = MealType)
      Notice("Insobriety level = " + Insobriety + ", Drink Size = " + DrinkSize)
      Int JA_Take = JArray.object()
      Int i
      Int NumItems = MyActor.GetNumItems()
      While i < NumItems && DrinkSize > 0
        Form Item = MyActor.GetNthForm(i)
        If (Item as Potion).IsFood()
          Int JM_ItemEntry = SCLib.getItemDataEntry(Item)
          If JMap.getInt(JM_ItemEntry, "Alcoholic") >= 1
            Float DigestValue = SCLib.genDigestValue(Item)
            Notice("Drinking " + Item.GetName())
            DrinkSize -= DigestValue
            EatenAmount += DigestValue
            JArray.addForm(JA_Take, Item)
          EndIf
        EndIf
        i += 1
      EndWhile
      Location CurrentLoc = MyActor.GetCurrentLocation()
      If CurrentLoc.HasKeyword(SCLSet.LocTypeInn) || CurrentLoc.HasKeyword(SCLSet.LocTypeHabitationHasInn)
        Int Gold = MyActor.GetGoldAmount()
        Potion Ale = Game.GetFormFromFile(0x00034c5e, "Skyrim.esm") as Potion
        Float AleSize = SCLib.genDigestValue(Ale)
        Int Value = Math.Ceiling(Ale.GetGoldValue() * SCLib.getPriceFactor(MyActor))
        Int TakenGold
        Int d
        While DrinkSize > 0 && Gold > Value
          JArray.addForm(JA_Take, Ale)
          DrinkSize -= AleSize
          EatenAmount += AleSize
          Gold -= Value
          TakenGold += Value
          d += 1
        EndWhile
        Notice("Purchasing additional drinks from inn. Starting gold = " + Gold + ". Total gold spent = " + TakenGold + ", total drinks purchased = " + d)
        MyActor.RemoveItem(Game.GetFormFromFile(0x0000000f, "Skyrim.esm"), TakenGold)
      EndIf

      If !JValue.empty(JA_Take)
        If Anim
          MyActor.PlayIdle(SCLSet.IdleDrink)
        EndIf
        Int j = JArray.count(JA_Take)
        While j
          j -= 1
          MyActor.EquipItem(JArray.getForm(JA_Take, j))
        EndWhile
      EndIf
    ElseIf MealType > 0
      Int Gluttony = SCLib.getGlutValue(MyActor, ActorData)
      Float MealSize = SCLib.genMealValue(aiSeverity = Gluttony, aiType = MealType)
      Notice("Meal type food, size " + MealType + ", Gluttony level = " + Gluttony + ", Meal Size = " + MealSize)
      Int JA_Take = JArray.object()
      Int i
      Int NumItems = MyActor.GetNumItems()
      Int JA_Eaten = JArray.object()
      While i < NumItems && MealSize > 0
        Form Item = MyActor.GetNthForm(i)
        If (Item as Potion).IsFood()
          Int JM_ItemEntry = SCLib.getItemDataEntry(Item)
          If JMap.getInt(JM_ItemEntry, "IsNotFood") == 0 && JMap.getInt(JM_ItemEntry, "IsDrink") == 0
            Float DigestValue = SCLib.genDigestValue(Item)
            MealSize -= DigestValue
            EatenAmount += DigestValue
            JArray.addForm(JA_Take, Item)
            JArray.addStr(JA_Eaten, Item.GetName())
            ;Notice("Eating " + Item.GetName())
          EndIf
        EndIf
        i += 1
      EndWhile
      Location CurrentLoc = MyActor.GetCurrentLocation()
      If CurrentLoc.HasKeyword(SCLSet.LocTypeInn) || CurrentLoc.HasKeyword(SCLSet.LocTypeHabitationHasInn)
        Int Gold = MyActor.GetGoldAmount()
        Float BuyPriceFactor = SCLib.getPriceFactor(MyActor)
        Potion Bread = Game.GetFormFromFile(0x00065c97, "Skyrim.esm") as Potion
        Float BreadSize = SCLib.genDigestValue(Bread)
        Int BreadValue = Math.Ceiling(Bread.GetGoldValue() * BuyPriceFactor)

        Potion GreenApple = Game.GetFormFromFile(0x00064b2f, "Skyrim.esm") as Potion
        Float AppleSize = SCLib.genDigestValue(GreenApple)
        Int AppleValue = Math.Ceiling(GreenApple.GetGoldValue() * BuyPriceFactor)

        Potion GoatCheese = Game.GetFormFromFile(0x00064b31, "Skyrim.esm") as Potion
        Float CheeseSize = SCLib.genDigestValue(GoatCheese)
        Int CheeseValue = Math.Ceiling(GoatCheese.GetGoldValue() * BuyPriceFactor)
        Bool Eaten
        Int j
        Int k
        Int TakenGold
        While MealSize > 0 && Eaten
          Eaten = False
          If Gold > BreadValue
            JArray.addForm(JA_Take, Bread)
            MealSize -= BreadSize
            EatenAmount += BreadSize
            Gold -= BreadValue
            TakenGold += BreadValue
            JArray.addStr(JA_Eaten, Bread.GetName())

            Eaten = True
          EndIf

          If Gold > AppleValue
            JArray.addForm(JA_Take, GreenApple)
            MealSize -= AppleSize
            EatenAmount += AppleSize
            Gold -= AppleValue
            TakenGold += AppleValue
            JArray.addStr(JA_Eaten, GreenApple.GetName())
            Eaten = True
          EndIf

          If Gold > CheeseValue
            JArray.addForm(JA_Take, GoatCheese)
            MealSize -= CheeseSize
            EatenAmount += CheeseSize
            Gold -= CheeseValue
            TakenGold += CheeseValue
            JArray.addStr(JA_Eaten, GoatCheese.GetName())
            Eaten = True
          EndIf

          j += 1
          If Eaten
            k += 1
          EndIf
        EndWhile
        Int l = j
        Bool Bought
        While j && Bought
          Bought = False
          If Gold > BreadValue
            MyActor.AddItem(Bread, i)
            Gold -= BreadValue
            TakenGold += BreadValue
            Bought = True
          EndIf

          If Gold > AppleValue
            MyActor.AddItem(GreenApple, i)
            Gold -= AppleValue
            TakenGold += AppleValue
            Bought = True
          EndIf

          If Gold > CheeseValue
            MyActor.AddItem(GoatCheese, i)
            Gold -= CheeseValue
            TakenGold += CheeseValue
            Bought = True
          EndIf
          j -= 1
          If Bought
            k += 1
          EndIf
        EndWhile
        Notice("Purchasing addtional food from inn. Starting gold = " + Gold + ", Total gold spent = " + TakenGold + ", Total food bought for now = " + l + ", Total meals bought = " + k)
        MyActor.RemoveItem(Game.GetFormFromFile(0x0000000f, "Skyrim.esm"), TakenGold)
      EndIf
      If !JValue.empty(JA_Take)
        If Anim
          MyActor.PlayIdle(SCLSet.IdleEatSoup)
        EndIf
        Int j = JArray.count(JA_Take)
        While j
          j -= 1
          MyActor.EquipItem(JArray.getForm(JA_Take, j))
        EndWhile
      EndIf
      String[] Eaten = Utility.CreateStringArray(JArray.count(JA_Eaten), "")
      JArray.writeToStringPArray(JA_Eaten, Eaten)
      Notice("Items Eaten: " + Eaten)
    EndIf
    Result = EatenAmount
    clear_thread_vars()
    thread_ready = True
  EndIf
EndEvent


String Function nameGet(Form akTarget)
  If akTarget as SCLBundle
    Return (akTarget as SCLBundle).ItemForm.GetName()
  ElseIf akTarget as Actor
    Return (akTarget as Actor).GetLeveledActorBase().GetName()
  ElseIf akTarget as ObjectReference
    Return (akTarget as ObjectReference).GetBaseObject().GetName()
  Else
    Return akTarget.GetName()
  EndIf
EndFunction

Int Function getContents(Actor akTarget, Int aiItemType, Int aiTargetData = 0)
  {New setup: a JFormMap for each item type}
  Int TargetData = getData(akTarget, aiTargetData)
  Int JF_Return = JMap.getObj(TargetData, "Contents" + aiItemType)
  If !JF_Return
    JF_Return = JFormMap.object()
    JMap.setObj(TargetData, "Contents" + aiItemType, JF_Return)
  EndIf
  Return JF_Return
EndFunction

Int Function getData(Actor akTarget, Int aiTargetData = 0)
  {Convenience function, gets ActorData if needed}
  Int TargetData
  If aiTargetData
    TargetData = aiTargetData
  Else
    TargetData = SCLib.getTargetData(akTarget)
  EndIf
  Return TargetData
EndFunction

Int Function findObjBundle(Int JF_ContentsMap, Form akBaseObject)
  {Searches through all items in an actor's content array, returns the ItemEntry ID}
  Form SearchRef = JFormMap.nextKey(JF_ContentsMap)
  While SearchRef
    If SearchRef as ObjectReference
      If SearchRef as SCLBundle
        Form SearchForm = (SearchRef as SCLBundle).ItemForm
        If SearchForm == akBaseObject
          Return JFormMap.getObj(JF_ContentsMap, SearchRef)
        EndIf
      EndIf
    EndIf
    SearchRef = JFormMap.nextKey(JF_ContentsMap, SearchRef)
  EndWhile
  Return 0
EndFunction

Function moveToHoldingCell(ObjectReference akRef)
  ;akRef.DisableNoWait()
  akRef.MoveTo(SCLSet.SCL_HoldingCell)
  ;akRef.EnableNoWait()
EndFunction

Function clear_thread_vars()
  MyActor = None
  ActorData = 0
  MealType = 0
  Anim = False
  Delay = 0
EndFunction

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Debug Functions
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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
