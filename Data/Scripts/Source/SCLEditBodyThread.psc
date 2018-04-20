ScriptName SCLEditBodyThread Extends Quest Hidden

SCLibrary Property SCLib Auto
SCLSettings Property SCLSet Auto
String Property DebugName
  String Function Get()
    Return "[SCLEditBodyThread" + ThreadID + "] "
  EndFunction
EndProperty
Int DMID = 4
Bool thread_queued = False
Actor MyActor
Int TargetData
String Type
Float Value
String MethodOverride
Int SetOverride
String ShortModKey
String FullModKey

Int Property ThreadID Auto
Float Result
;Bool thread_ready = False

Float Function getResultEntry()
  ;thread_ready = False
  ;thread_queued = False
  Return Result
EndFunction

Function setThread(Actor akTarget, String asType, Float afValue, String asMethodOverride,Int aiSetOverride, String asShortModKey, String asFullModKey)
  ;Note("Thread being set.")
  thread_queued = True

  MyActor = akTarget
  TargetData = SCLib.getTargetData(MyActor)
  Type = asType
  Value = afValue
  MethodOverride = asMethodOverride
  SetOverride = aiSetOverride
  ShortModKey = asShortModKey
  FullModKey = asFullModKey
EndFunction

Bool Function queued()
  Return thread_queued
EndFunction

;/Bool Function isReady()
  Return thread_ready
EndFunction/;

Bool Function force_unlock()
  clear_thread_vars()
  thread_queued = False
  ;thread_ready = False
  Return True
EndFunction

Event OnEditBodyCall(Int aiID)
  If thread_queued && aiID == ThreadID
    ;Note("Edit body call recieved!")
    Int InflateEntry = JDB.solveObj(".SCLExtraData.SCL" + Type + "InflateData")
    ;/If InflateEntry
      Note("InflateEntry Found! = " + InflateEntry)
    Else
      Note("InflateEntry Not Found!")
    EndIf/;
    ;Note("Initial Value = " + Value)
    Float SizeValue = Value * JMap.getFlt(InflateEntry, "Multiplier", 1) * (((MyActor.GetLeveledActorBase().GetWeight() / 100) * JMap.getFlt(InflateEntry, "HighScale")) + 1)
    If SizeValue
      SizeValue /= MyActor.GetScale()  ;Should take into consideration bone scale as well.

      ;Float NodeScale = NetImmerse.GetNodeScale(MyActor, "NPC Root [Root]", False)
      ;Note("NodeScale = " + NodeScale)
      SizeValue /= NetImmerse.GetNodeScale(MyActor, "NPC Root [Root]", False)
      ;SizeValue /= NodeScale
    EndIf
    SizeValue = clampFlt(SizeValue, JMap.getFlt(InflateEntry, "Minimum", 1), JMap.getFlt(InflateEntry, "Maximum", 10))
    SizeValue = curveBoneValue(SizeValue, JMap.getFlt(InflateEntry, "Curve"))
    ;Note("Processed Value = " + SizeValue)
    String OldMethod = JMap.getStr(TargetData, "SCL" + Type + "InflateMethod")
    String NewMethod
    String DefaultMethod = SCLSet.InflateMethodArray[SCLSet.BellyInflateMethod]
    If MethodOverride
      NewMethod = MethodOverride
      JMap.setStr(TargetData, "SCL" + Type + "InflateMethod", NewMethod)
    ElseIf OldMethod == "Default"
      NewMethod = DefaultMethod
    ElseIf OldMethod
      NewMethod = OldMethod
    Else
      NewMethod = DefaultMethod
      JMap.setStr(TargetData, "SCL" + Type + "InflateMethod", "Default")
    EndIf
    If OldMethod == "Default" && NewMethod == DefaultMethod
      ;Pass
    ElseIf NewMethod != OldMethod
      purgeMethods()
    EndIf
    ;Note("Method = " + NewMethod)
    If NewMethod == "Disabled"
      Result = 0
    ElseIf NewMethod == "NiOverride"
      String Bone = convertTypeToBone(Type)
      setBoneScaleNiO(Bone, SizeValue)
    ElseIf NewMethod == "Sexlab Inflation Framework"
      String Bone = convertTypeToBone(Type)
      setBoneScaleSLIF(Bone, SizeValue)
    ElseIf NewMethod == "Equipment"
      Int OldSet = JMap.getInt(TargetData, "SCL" + Type + "EquipSet")
      Int NewSet
      If SetOverride > 0
        NewSet = SetOverride
      Else
        NewSet = OldSet
      EndIf
      If !NewSet
        NewSet = 1
      EndIf
      If NewSet != OldSet
        purgeEquipSets(InflateEntry)
        JMap.setInt(TargetData, "SCL" + Type + "EquipSet", NewSet)
      EndIf
      Int SizeTier = findEquipSize(InflateEntry, NewSet, SizeValue)
      ;Note("NewSet = " + NewSet + ", SizeTier = " + SizeTier)
      Armor NewArmor = JFormMap.getNthKey(JIntMap.getObj(JMap.getObj(InflateEntry, "EquipSetList"), NewSet), SizeTier) as Armor
      ;Armor NewArmor = getArmor(SizeTier, Set)
      If !MyActor.IsEquipped(NewArmor)
        MyActor.AddItem(NewArmor, 1, True)
        MyActor.EquipItem(NewArmor, True)
      EndIf
    ElseIf NewMethod == "Dynamic Equipment"
      ;Note("Method = Dynamic Equipment")
      Float AltSizeValue = SizeValue / 100
      ;Note("AltSizeValue = " + AltSizeValue)
      AltSizeValue *= JMap.getFlt(InflateEntry, "DynEquipMultiplier", 1)
      ;Note("Multipled AltSizeValue = " + AltSizeValue)
      Int OldSet = JMap.getInt(TargetData, "SCL" + Type + "DynEquipSet")
      Int NewSet
      If SetOverride > 0
        NewSet = SetOverride
        JMap.setInt(TargetData, "SCL" + Type + "DynEquipSet", NewSet)
        purgeDynEquipSets(InflateEntry)
      ElseIf OldSet > 0
        NewSet = OldSet
      Else
        NewSet = 1
        JMap.setInt(TargetData, "SCL" + Type + "DynEquipSet", NewSet)
        purgeDynEquipSets(InflateEntry)
      EndIf
      ;Note("NewSet = " + NewSet)
      Int JI_DynEquipSetList = JMap.getObj(InflateEntry, "DynEquipSetList")
      Int JM_DynEntry = JIntMap.getObj(JI_DynEquipSetList, NewSet)
      Armor NewArmor = JMap.getForm(JM_DynEntry, "DynEquipment") as Armor
      If NewArmor
        ;Note("New dynamic equipment found!")
        If !MyActor.IsEquipped(NewArmor)
          ;Note("Actor not wearing equipment! Adding...")
          MyActor.AddItem(NewArmor, 1, True)
          MyActor.EquipItem(NewArmor, False, True)
        EndIf
      Else
        ;Note("Armor not found!")
      EndIf
      Int JA_MorphList = JMap.getObj(JM_DynEntry, "MorphMap")
      Int i = JArray.count(JA_MorphList)
      ;Note("Setting Morph Array. Num Morphs = " + i)
      Int JA_MorphSet = JArray.object()
      While i
        i -= 1
        If AltSizeValue <= 0
          JArray.addFlt(JA_MorphSet, 0)
          ;Note("Null.")
        Else
          Float Threshold = JMap.getFlt(JArray.getObj(JA_MorphList, i), "MorphThreshold")
          If Threshold == -1
            JArray.addFLt(JA_MorphSet, AltSizeValue)
            ;Note(AltSizeValue)
            AltSizeValue = 0
          ElseIf Threshold > AltSizeValue
            JArray.addFlt(JA_MorphSet, Threshold - AltSizeValue)
            ;Note(Threshold - AltSizeValue)
            AltSizeValue = 0
          Else
            JArray.addFlt(JA_MorphSet, Threshold)
            ;Note(Threshold)
            AltSizeValue -= Threshold
          EndIf
        EndIf
      EndWhile
      Int j
      Int NumMorphs = JArray.count(JA_MorphSet)
      ;Note("Applying morphs. Num = " + NumMorphs)
      While i < NumMorphs
        NiOverride.SetBodyMorph(MyActor, JMap.getStr(JArray.getObj(JA_MorphList, j), "MorphName"), "SCL_DynMorphList" + Type + NewSet, JArray.getFlt(JA_MorphSet, i))
        i += 1
      EndWhile
      JValue.zeroLifetime(JA_MorphSet)
      Nioverride.UpdateModelWeight(MyActor)
    EndIf
    JMap.setFlt(TargetData, "VisualCurrentBellySize", SizeValue)
    Result = SizeValue
    clear_thread_vars()
    ;thread_ready = True
    thread_queued = False
  EndIf
EndEvent

Float Function clampFlt(Float afValue, Float afMin, Float afMax)
  If afValue < afMin
    afValue = afMin
  ElseIf afValue > afMax
    afValue = afMax
  EndIf
  Return afValue
EndFunction

Float Function curveBoneValue(Float afValue, Float afCurve)
  If afValue <= 1
    Return afValue
  EndIf

  If afCurve == 2
    Return afValue
  EndIf

  Return (Math.sqrt(Math.pow((afValue - 1), afCurve)) * (afCurve / 2)) + 1
EndFunction

Function setBoneScaleNiO(String asBone, Float fValue)
  {Increases belly size using NiOverride. Thanks darkconsole!
  Recommended to use esp/esm name for sShortModKey, actual mod title for sFullModKey
  Ex: "SCL.esp"
      "Skyrim Capacity Limited"}
  If asBone == "NPC Breasts"
    setBoneScaleNiO("NPC L Breast", fValue)
    setBoneScaleNiO("NPC R Breast", fValue)
    Return
  EndIf

  If asBone == "NPC Butt"
    setBoneScaleNiO("NPC L Butt", fValue)
    setBoneScaleNiO("NPC R Butt", fValue)
    Return
  EndIf

  If asBone == "NPC Testicles"
    asBone = "NPC GenitalsScrotum [GenScrot]"
  EndIf

  If !NetImmerse.HasNode(MyActor, asBone, False)
    Return
  EndIf
  Bool Gender = MyActor.GetLeveledActorBase().GetSex() as Bool

  If fValue != 1
    NiOverride.AddNodeTransformScale(MyActor, False, Gender, asBone, ShortModKey, fValue)
  Else
    NiOverride.RemoveNodeTransformScale(MyActor, False, Gender, asBone, ShortModKey)
  EndIf
  NiOverride.UpdateNodeTransform(MyActor, False, Gender, asBone)
EndFunction

Function setBoneScaleSLIF(String asBone, Float afValue)
  If asBone == "NPC Testicles"
    asBone = "NPC GenitalsScrotum [GenScrot]"
  EndIf

  If asBone == "NPC Breasts"
    setBoneScaleSLIF("NPC L Breast", afValue)
    setBoneScaleSLIF("NPC R Breast", afValue)
    Return
  EndIf
  If asBone == "NPC Butt"
    setBoneScaleSLIF("NPC L Butt", afValue)
    setBoneScaleSLIF("NPC R Butt", afValue)
    Return
  EndIf

  String sKey = SLIF_Main.ConvertToKey(asBone)
  SLIF_Main.inflate(MyActor, FullModKey, sKey, afValue, oldModName = ShortModKey)
EndFunction


Function purgeMethods()
  Bool Gender = MyActor.GetLeveledActorBase().GetSex() as Bool
  String Bone = convertTypeToBone(Type)

  If NiOverride.HasNodeTransformScale(MyActor, False, Gender, Bone, ShortModKey)
    NiOverride.RemoveNodeTransformScale(MyActor, False, Gender, Bone, ShortModKey)
  EndIf
  String sKey = SLIF_Main.ConvertToKey(Bone)
  If SLIF_Main.HasScale(MyActor, FullModKey, sKey)
    SLIF_Main.resetActor(MyActor, FullModKey, sKey)
  EndIf
  purgeEquipSets()
  purgeDynEquipSets()
EndFunction

String Function convertTypeToBone(String asType)
  If asType == "Belly"
    Return "NPC Belly"
  ElseIf asType == "Breasts"
    Return "NPC Breasts"
  ElseIf asType == "Butt"
    Return "NPC Butt"
  ElseIf asType == "Scrotum"
    Return "NPC Testicles"
  ElseIf asType == "Genitals"
    Return "NPC GenitalsBase [GenBase]"
  EndIf
EndFunction

Int Function findEquipSize(Int JM_InflateEntry, Int aiSet, Float fValue)
  {Binary Search Algorithm
  See https://en.wikipedia.org/wiki/Binary_search_algorithm}
  Int JI_EquipSetList = JMap.getObj(JM_InflateEntry, "EquipSetList")
  Int JF_Equips = JIntMap.getObj(JI_EquipSetList, aiSet)
  Int L = 0
  Int R = JFormMap.count(JF_Equips) - 1
  While L < R
    Int m = Math.floor((L + R) / 2)
    Float s = JFormMap.getFlt(JF_Equips, JFormMap.getNthKey(JF_Equips, m))
    If s < fValue
      L = m + 1
    ElseIf s > fValue
      R = m - 1
    ElseIf s == fValue
      Return m
    Endif
  EndWhile
  Return L
EndFunction

Function purgeEquipSets(Int JM_InflateEntry = 0)
  Int InflateEntry
  If JM_InflateEntry
    InflateEntry = JM_InflateEntry
  Else
    InflateEntry = JDB.solveObj(".SCLExtraData.SCL" + Type + "InflateData")
  EndIf
  Int JI_EquipSetList = JMap.getObj(InflateEntry, "EquipSetList")
  Int i = JIntMap.nextKey(JI_EquipSetList)
  While i
    Int JF_Equips = JIntMap.getObj(JI_EquipSetList, i)
    Armor ArmorKey = JFormMap.nextKey(JF_Equips) as Armor
    While ArmorKey
      If MyActor.IsEquipped(ArmorKey)
        MyActor.UnequipItem(ArmorKey, False, True)
        MyActor.RemoveItem(ArmorKey, 1, True)
      EndIf
      ArmorKey = JFormMap.nextKey(JF_Equips, ArmorKey) as Armor
    EndWhile
    i = JIntMap.nextKey(JI_EquipSetList, i)
  EndWhile
EndFunction

Function purgeDynEquipSets(Int JM_InflateEntry = 0)
  Int InflateEntry
  If JM_InflateEntry
    InflateEntry = JM_InflateEntry
  Else
    InflateEntry = JDB.solveObj(".SCLExtraData.SCL" + Type + "InflateData")
  EndIf
  Int JI_DynEquipSetList = JMap.getObj(InflateEntry, "DynEquipSetList")
  Int i = JIntMap.nextKey(JI_DynEquipSetList)
  While i
    Int DynEntry = JIntMap.getObj(JI_DynEquipSetList, i)
    NiOverride.ClearBodyMorphKeys(MyActor, "SCL_DynMorphList" + Type + i)
    Armor Mesh = JMap.getForm(DynEntry, "DynEquipment") as Armor
    If MyActor.IsEquipped(Mesh)
      MyActor.UnequipItem(Mesh, False, True)
      MyActor.RemoveItem(Mesh, 1, True)
    EndIf
    i = JIntMap.nextKey(JI_DynEquipSetList, i)
  EndWhile
  NiOverride.UpdateModelWeight(MyActor)
EndFunction


Function clear_thread_vars()
  MyActor = None
  Type = ""
  Value = 0
  MethodOverride = ""
  SetOverride = 0
  ShortModKey = ""
  FullModKey = ""
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
