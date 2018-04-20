ScriptName SCLibrary Extends Quest
{What should this extend? are we moving away from it being a quest due to the Property bug?}
;*******************************************************************************
;Variables and Properties
;*******************************************************************************
SCLSettings Property SCLSet Auto
String ScriptID = "SCLib"
String Property DebugName
  String Function Get()
    Return "[" + ScriptID + "] "
  EndFunction
EndProperty
Int DMID = 1  ;Debug message ID
Int Property JCReqAPI = 3 Auto
Int Property JCReqFV = 3 Auto


;Others ************************************************************************
Actor Property PlayerRef Auto
Keyword Property ActorTypeNPC Auto

;Variables *********************************************************************
String ShortModKey = "SCL.esp"
String FullModKey = "Skyrim Capacity Limited"
Int Property JA_Description Auto
Int Property JA_OptionList1 Auto
Int Property JA_OptionList2 Auto
Int Property JA_OptionList3 Auto
Bool GenerateLock

Function addLibraryScript(Lib_SC akLibrary) Global
  {Keeps track of all library scripts added by other mods, and allows certain functions to input into SCL Functions}
  Int JA_LibraryList = JDB.solveObj(".SCLExtraData.LibraryList")
  If !JA_LibraryList
    SCLDatabase Data = SCLibrary.getSCLDatabase()
    Data.setupLibraryList()
    JA_LibraryList = JDB.solveObj(".SCLExtraData.LibraryList")
  EndIf
  Int i = JArray.findForm(JA_LibraryList, akLibrary)
  If i == -1
    JArray.addForm(JA_LibraryList, akLibrary)
  EndIf
EndFunction

Function removeLibraryScript(Lib_SC akLibrary) Global
  Int JA_LibraryList = JDB.solveObj(".SCLExtraData.LibraryList")
  If !JA_LibraryList
    Return
  EndIf
  Int i = JArray.findForm(JA_LibraryList, akLibrary)
  If i != -1
    JArray.eraseIndex(JA_LibraryList, i)
  EndIf
EndFunction

;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
;Global Utilities
;+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
Function startupAllQuests()
  ;Initializes all updating quests
  getSCLMonitorCycle().Start()
  getSCLMonitorManager().Start()
  ;SCL_MonitorManagerQuest.Start()
  ;SCL_MonitorCycleQuest.Start()
EndFunction

Function stopAllQuests()
  SCLSet.SCL_MonitorManagerQuest.Stop()
  SCLSet.SCL_MonitorCycleQuest.Stop()
EndFunction

Int Function getActorData(Actor akTarget) Global
  {Global version of getTargetData
  Will not generate profiles
  Data now stored under ActorBase for unique actors
  Function will generate new actor profile if no data found && abGenProfile == True
  Player data still stored under actor}
  Form Target
  If akTarget == Game.GetPlayer()
    Target = Game.GetPlayer()
  ElseIf akTarget.GetLeveledActorBase().IsUnique()
    Target = akTarget.GetActorBase()
  Else
    Target = akTarget
  EndIf
  Int Data = JFormDB.findEntry("SCLActorData", Target)
  Return Data
EndFunction

;-------------------------------------------------------------------------------
;Get Scripts
;-------------------------------------------------------------------------------
SCLibrary Function getSCLibrary() Global
  Return Game.GetFormFromFile(0x02000D62, "SCL.esp") as SCLibrary
EndFunction

SCLDatabase Function getSCLDatabase() Global
  Return Game.GetFormFromFile(0x02002852, "SCL.esp") as SCLDatabase
EndFunction

SCLModConfig Function getSCLModConfig() Global
  Return Game.GetFormFromFile(0x02000D63, "SCL.esp") as SCLModConfig
EndFunction

SCLTrashHandler Function getSCLTrashHandler() Global
  Return Game.GetFormFromFile(0x020038AF, "SCL.esp") as SCLTrashHandler
EndFunction

;/SCLPersistence Function getSCLPersistence() Global
  Return Game.GetFormFromFile(0x0200CA96, "SCL.esp") as SCLPersistence
EndFunction/;

SCLMonitorFinder Function getSCLMonitorFinder() Global
  Return Game.GetFormFromFile(0x02000d65, "SCL.esp") as SCLMonitorFinder
EndFunction

SCLMonitorManager Function getSCLMonitorManager() Global
  Return Game.GetFormFromFile(0x02000d64, "SCL.esp") as SCLMonitorManager
EndFunction

SCLMonitorCycle Function getSCLMonitorCycle() Global
  Return Game.GetFormFromFile(0x0200332F, "SCL.esp") as SCLMonitorCycle
EndFunction

SCLSettings Function getSCLSettings() Global
  Return Game.GetFormFromFile(0x0200B50C, "SCL.esp") as SCLSettings
EndFunction
;-------------------------------------------------------------------------------
;Trash
;-------------------------------------------------------------------------------

Function addToObjectTrashList(ObjectReference akReference, Float afTime) Global
  {Items added using this function will be deleted after afTime in-game hours
  OR immediately if the limit is reached (default 15)
  Using this function will make sure that the script is updating}
  SCLTrashHandler SCLTrash = SCLibrary.getSCLTrashHandler()
  JFormMap.setFlt(SCLTrash.JF_ObjectTrash, akReference, afTime)
EndFunction

Function removeFromObjectTrashList(ObjectReference akReference) Global
  Int JF_ObjectTrash = JDB.solveObj(".SCLTrashList.ObjectTrash")
  If JFormMap.hasKey(JF_ObjectTrash, akReference)
    JFormMap.removeKey(JF_ObjectTrash, akReference)
  EndIf
EndFunction

Float Function remainingObjectTrashTime(ObjectReference akReference) Global
  {Returns -1 if the object isn't there}
  Int JF_ObjectTrash = JDB.solveObj(".SCLTrashList.ObjectTrash")
  If JFormMap.hasKey(JF_ObjectTrash, akReference)
    Return JFormMap.getFlt(JF_ObjectTrash, akReference)
  Else
    Return -1
  EndIf
EndFunction

Bool Function isInObjectTrashList(ObjectReference akReference) Global
  Int JF_ObjectTrash = JDB.solveObj(".SCLTrashList.ObjectTrash")
  Return JFormMap.hasKey(JF_ObjectTrash, akReference)
EndFunction

Function addToActorTrashList(Actor akTarget, Float afTime) Global
  {Actors added using this function will have their ActorData deleted from SCLActorData after afTime in-game hours
  or immediately if the limit is reached (default 50)
  Using this function will make sure that the script is updating}
  SCLTrashHandler SCLTrash = SCLibrary.getSCLTrashHandler()
  JFormMap.setFlt(SCLTrash.JF_ActorTrash, akTarget, afTime)
EndFunction

Function removeFromActorTrashList(Actor akTarget) Global
  Int JF_ActorTrash = JDB.solveObj(".SCLTrashList.ActorTrash")
  If JFormMap.hasKey(JF_ActorTrash, akTarget)
    JFormMap.removeKey(JF_ActorTrash, akTarget)
  EndIf
EndFunction

Float Function remainingActorTrashTime(Actor akTarget) Global
  {Returns -1 if the object isn't there}
  Int JF_ActorTrash = JDB.solveObj(".SCLTrashList.ActorTrash")
  If JFormMap.hasKey(JF_ActorTrash, akTarget)
    Return JFormMap.getFlt(JF_ActorTrash, akTarget)
  Else
    Return -1
  EndIf
EndFunction

Bool Function isInActorTrashList(Actor akTarget) Global
  Int JF_ActorTrash = JDB.solveObj(".SCLTrashList.ActorTrash")
  Return JFormMap.hasKey(JF_ActorTrash, akTarget)
EndFunction

;/;Persistence
Function addToPersist(ObjectReference akRef, Float afTime = -1.0) Global
  SCLPersistence SCLPersist = SCLibrary.getSCLPersistence()
  JFormMap.setFlt(SCLPersist.JF_Persist, akRef, afTime)
EndFunction

Function removeFromPersist(ObjectReference akRef) Global
  Int JF_Persist = JDB.solveObj(".SCLTrashList.PersistList")
  If JFormMap.hasKey(JF_Persist, akRef)
    JFormMap.removeKey(JF_Persist, akRef)
  EndIf
EndFunction

Bool Function isPersistent(ObjectReference akRef) Global
  Int JF_Persist = JDB.solveObj(".SCLTrashList.PersistList")
  Return JFormMap.hasKey(JF_Persist, akRef)
EndFunction/;

;-------------------------------------------------------------------------------
;Search
;-------------------------------------------------------------------------------
Int Function addSearchKeyword(Keyword kwSearch) Global
  {Adds Keyword to item search list, returns the Keyword entry in the SCLItemDatabase}
  FormList KeywordFormlist = Game.GetFormFromFile(0x0200285F, "SCL.esp") as Formlist
  If !KeywordFormlist.HasForm(kwSearch)
    KeywordFormlist.AddForm(kwSearch)
  EndIf
  Int JM_KeywordEntry = JMap.object()
  JFormDB.setEntry("SCLItemDatabase", kwSearch, JM_KeywordEntry)
  Return JM_KeywordEntry
EndFunction

Int Function AddSearchFormlist(Formlist flSearch) Global
  {Adds formlist to item search list, returns the formlist entry in the SCLItemDatabase}
  FormList FormlistList = Game.GetFormFromFile(0x0200285E, "SCL.esp") as Formlist
  If !FormlistList.HasForm(flSearch)
    FormlistList.AddForm(flSearch)
  EndIf
  Int JM_FormlistEntry = JMap.object()
  JFormDB.setEntry("SCLItemDatabase", flSearch, JM_FormlistEntry)
  Return JM_FormlistEntry
EndFunction
;-------------------------------------------------------------------------------
;Messages
;-------------------------------------------------------------------------------
Function addMessage(String asKey, String asMessage) Global
  {Adds string to array that can be pulled from using getMessage
  use asKey to categorize them, and they'll be pulled from at random}
  Int JM_Mess = JDB.solveObj(".SCLExtraData.Messages")
  If !JM_Mess
    SCLDatabase Data = SCLibrary.getSCLDatabase()
    Data.setupMessages()
    JM_Mess = JDB.solveObj(".SCLExtraData.Messages")
  EndIf
  Int JA_MessageList = JMap.getObj(JM_Mess, asKey)
  If !JA_MessageList
    JA_MessageList = JArray.object()
    JMap.setObj(JM_Mess, asKey, JA_MessageList)
  EndIf
  Int i = JArray.findStr(JA_MessageList, asMessage)
  If i == -1
    JArray.addStr(JA_MessageList, asMessage)
  EndIf
EndFunction

String Function getMessage(String asKey, Int aiIndex = -1, Bool abTagReplace = True, Actor[] akActors = None, Int aiActorIndex = -1)
  ;Retrieves the specified message type from the database. Will also perform tag replacement.
  Int JA_MessageList = JDB.solveObj(".SCLExtraData.Messages." + asKey)
  Int i
  If aiIndex != -1
    i = aiIndex
  Else
    i = Utility.RandomInt(0, JArray.count(JA_MessageList) - 1)
  EndIf

  String ReturnMessage = JArray.getStr(JA_MessageList, i)
  If abTagReplace
    ReturnMessage = replaceTags(ReturnMessage, akActors)
  EndIf
  Return ReturnMessage
EndFunction

Actor Function getTeammate(Int aiIndex = -1)
  {Returns random teammate from list. use aiIndex to call a specific index
  Returns None if no teammate or invalid index
  If only one teammate, will always return that}
  Int NumTeammates = SCLSet.TeammatesList.Length
  If NumTeammates > 0
    Int i
    If NumTeammates > 1
      If aiIndex
        i = aiIndex
      Else
        i = Utility.RandomInt(0, NumTeammates - 1)
      EndIf
    Else
      i = 0
    EndIf
    Actor Teammate = SCLSet.TeammatesList[i] as Actor
    If Teammate
      Return Teammate
    EndIf
  EndIf
  Return None
EndFunction

String Function replaceTags(String asMessage, Actor[] akActors = None, Int aiActorIndex = -1) ;Consider making a global?
  {Replaces tokens in strings and replaces them
  Adapted from post by jbezorg
  https://www.creationkit.com/index.php?title=Talk:StringUtil_Script}
  Int iStart = 0
  Int iEnd = 0
  String sReturn = ""
  String sOperator = ""
  iEnd = StringUtil.Find(asMessage, "%", iStart)
  If iEnd == -1
    Return asMessage
  Else
    While (iEnd != -1)
      sOperator = StringUtil.getNthChar(asMessage, iEnd + 1)
      If sOperator == "%"
        sReturn += StringUtil.Substring(asMessage, iStart, iEnd) + "%"
      ElseIf sOperator == "p"
        sReturn += StringUtil.Substring(asMessage, iStart, iEnd) + nameGet(PlayerRef)
      ElseIf sOperator == "t"
        String TagReplace
        Int NumTeammates = SCLSet.TeammatesList.Length
        If NumTeammates == 0
          TagReplace = "they"
        ElseIf NumTeammates > 1
          Int t = Utility.RandomInt(0, NumTeammates - 1)
          Actor Teammate = SCLSet.TeammatesList[t] as Actor
          If Teammate
            TagReplace = nameGet(Teammate)
          Else
            TagReplace = "they"
          EndIf
        Else
          Actor Teammate = SCLSet.TeammatesList[0] as Actor
          If Teammate
            TagReplace = nameGet(Teammate)
          Else
            TagReplace = "they"
          EndIf
        EndIf
        sReturn += StringUtil.Substring(asMessage, iStart, iEnd) + TagReplace
      ElseIf sOperator == "a"
        If akActors
          Int i
          If aiActorIndex >= 0
            i = aiActorIndex
          Else
            i = Utility.RandomInt(0, akActors.length - 1)
          EndIf
          sReturn += StringUtil.Substring(asMessage, iStart, iEnd) + nameGet(akActors[i])
        EndIf
      ;ElseIf sOperator == "whatever"
      Else
        Issue("Improper format submitted to replaceTags: " + asMessage)
        Return asMessage
      EndIf
      iStart = iEnd + 2
      iEnd = StringUtil.find(asMessage, "%", iStart)
    EndWhile

    sReturn += StringUtil.Substring(asMessage, iStart)
  EndIf
  Return sReturn
EndFunction

Function getTeammates()
  Actor[] teamMates = new Actor[16]
  int numFound = 0
  Cell c = playerRef.getparentCell()
  int num = (c.GetNumRefs(62)) as Int
  while num && numFound<16
    num -= 1
    Actor a = c.GetNthRef(num, 62) as Actor
    if a && a.isPlayerTeamMate()
      teamMates[numFound] = a
      numFound += 1
    endIf
  endWhile
EndFunction
;-------------------------------------------------------------------------------
;Reload List
;-------------------------------------------------------------------------------
Function addToReloadList(Quest akQuest) Global
  {Quests added to this list will have GetStage() executed on them on every game reload
  Use this for any maintenence functions, and return Parent.GetStage()}
  Int JA_LoadMaintenence = JDB.solveObj(".SCLExtraData.ReloadList")
  If !JA_LoadMaintenence
    SCLDatabase Data = SCLibrary.getSCLDatabase()
    Data.setupReloadSystems()
    JA_LoadMaintenence = JDB.solveObj(".SCLExtraData.ReloadList")
  EndIf
  Int i = JArray.findForm(JA_LoadMaintenence, akQuest)
  If i == -1
    JArray.addForm(JA_LoadMaintenence, akQuest)
  EndIf
EndFunction

Function removeFromReloadList(Quest akQuest) Global
  Int JA_LoadMaintenence = JDB.solveObj(".SCLExtraData.ReloadList")
  If !JA_LoadMaintenence
    Return
  EndIf
  Int i = JArray.findForm(JA_LoadMaintenence, akQuest)
  If i != -1
    JArray.eraseIndex(JA_LoadMaintenence, i)
  EndIf
EndFunction

;-------------------------------------------------------------------------------
;Perks
;-------------------------------------------------------------------------------
Int Function addPerkID(String asPerkID, Int JA_Desc, Int JA_Reqs) Global
  {Adds information regarding a perk to a JMap}
  Int JM_PerkIDs = JDB.solveObj(".SCLExtraData.PerkIDList")
  If !JM_PerkIDs
    SCLDatabase Data = SCLibrary.getSCLDatabase()
    Data.setupPerksList()
    JM_PerkIDs = JDB.solveObj(".SCLExtraData.PerkIDList")
  EndIf
  Int JM_PerkEntry
  If !JMap.hasKey(JM_PerkIDs, asPerkID)
    JM_PerkEntry = JMap.object()
    JMap.setObj(JM_PerkEntry, "PerkDescriptions", JA_Desc)
    JMap.setObj(JM_PerkEntry, "PerkRequirements", JA_Reqs)
    JMap.setObj(JM_PerkIDs, asPerkID, JM_PerkEntry)
  Else
    JM_PerkEntry = JMap.getObj(JM_PerkIDs, asPerkID)
  EndIf
  Return JM_PerkEntry
EndFunction

Function removePerkID(String asPerkID) Global
  Int JM_PerkIDs = JDB.solveObj(".SCLExtraData.PerkIDList")
  If !JM_PerkIDs
    Return
  EndIf
  If JMap.hasKey(JM_PerkIDs, asPerkID)
    JMap.removeKey(JM_PerkIDs, asPerkID)
  EndIf
EndFunction
;-------------------------------------------------------------------------------
;Menus
;-------------------------------------------------------------------------------
Function addActorMainMenu(Int aiMenuID, String asMenuName, Bool abSetEnabled) Global
  {Registers a menu to a slot so that it can be seen by getPreviousActorMainMenu and getNextActorMainMenu
  Will send out ModEvent "SCLActorMainMenuOpen" + aiMenuID whenever a menu is called}
  Int JM_MenuEntry = JMap.object()
  JMap.setStr(JM_MenuEntry, "MenuName", asMenuName)
  If abSetEnabled
    JMap.setInt(JM_MenuEntry, "MenuOn", 1)
  Else
    JMap.setInt(JM_MenuEntry, "MenuOn", 0)
  EndIf
  Int JI_Actor = JDB.solveObj(".SCLExtraData.ActorMainMenus")
  If !JI_Actor
    SCLDatabase Data = SCLibrary.getSCLDatabase()
    Data.setupActorMainMenus()
    JI_Actor = JDB.solveObj(".SCLExtraData.ActorMainMenus")
  EndIf
  JIntMap.setObj(JI_Actor, aiMenuID, JM_MenuEntry)
EndFunction

Function removeActorMainMenu(Int aiMenuID) Global
  Int JI_Actor = JDB.solveObj(".SCLExtraData.ActorMainMenus")
  If !JI_Actor
    Return
  EndIf
  JIntMap.removeKey(JI_Actor, aiMenuID)
EndFunction

;-------------------------------------------------------------------------------
;Item Types
;-------------------------------------------------------------------------------
Function addItemType(Int aiItemType, String asShort, String asFull, String asContentsKey, Bool abVomitType) Global
  {Allows system to recognize this item type
  Will not allow itemtype 0
  Will send out ModEvent "SCLProcessEvent" + aiItemType on updates
  asContentsKey will specify where the fullness value for that itemtype is stored.
  abVomitType will allow this item type to be vomited whenever a valid event occurs}
  If aiItemType == 0
    Return
  EndIf
  Int JM_ItemType = JMap.object()
  JMap.setStr(JM_ItemType, "STShortDescription", asShort)
  JMap.setStr(JM_ItemType, "STFullDescription", asFull)
  If abVomitType
    JMap.setInt(JM_ItemType, "STisVomitType", 1)
  Else
    JMap.setInt(JM_ItemType, "STisVomitType", 0)
  EndIf
  JMap.setStr(JM_ItemType, "ContentsKey", asContentsKey)
  Int JI_Items = JDB.solveObj(".SCLExtraData.ItemTypeMap")
  If !JI_Items
    SCLDatabase Data = SCLibrary.getSCLDatabase()
    Data.setupItemTypes()
    JI_Items = JDB.solveObj(".SCLExtraData.ItemTypeMap")
  EndIf
  JIntMap.setObj(JI_Items, aiItemType, JM_ItemType)
EndFunction

Function removeItemType(Int aiItemType) Global
  Int JI_Item = JDB.solveObj(".SCLExtraData.ItemTypeMap")
  If !JI_Item
    Return
  EndIf
  JIntMap.removeKey(JI_Item, aiItemType)
EndFunction

Int Function getItemTypeEntry(Int aiItemType)
  Int JI_Item = JDB.solveObj(".SCLExtraData.ItemTypeMap")
  Return JIntMap.getObj(JI_Item, aiItemType)
EndFunction

;-------------------------------------------------------------------------------
;Values
;-------------------------------------------------------------------------------
Function addBellyValue(String asKey) Global
  {Adds key that contains float value that goes towards belly size}
  Int JA_Belly = JDB.solveObj(".SCLExtraData.BellyValueList")
  If !JA_Belly
    SCLDatabase Data = SCLibrary.getSCLDatabase()
    Data.setupBellyValues()
    JA_Belly = JDB.solveObj(".SCLExtraData.BellyValueList")
  EndIf
  Int i = JArray.findStr(JA_Belly, asKey)
  If i == -1
    JArray.addStr(JA_Belly, asKey)
  EndIf
EndFunction

Function removeBellyValue(String asKey) Global
  Int JA_Belly = JDB.solveObj(".SCLExtraData.BellyValueList")
  If !JA_Belly
    Return
  EndIf
  Int i = JArray.findStr(JA_Belly, asKey)
  If i != -1
    JArray.eraseIndex(JA_Belly, i)
  EndIf
EndFunction

Function addTotalValue(String asKey, Int aiContainer) Global
  {Adds array of values that is iterated through to produce an actor's "total" weight
  Best to just use whatever array you iterate through to get a bodypart's size
  Like the belly value array above this function}
  Int JM_Total = JDB.solveObj(".SCLExtraData.TotalValuesList")
  If !JM_Total
    SCLDatabase Data = SCLibrary.getSCLDatabase()
    Data.setupTotalValues()
    JM_Total = JDB.solveObj(".SCLExtraData.TotalValuesList")
  EndIf
  JMap.setObj(JM_Total, asKey, aiContainer)
EndFunction

Function removeTotalValue(String asKey) Global
  Int JM_Total = JDB.solveObj(".SCLExtraData.TotalValuesList")
  If !JM_Total
    Return
  EndIf
  JMap.removeKey(JM_Total, asKey)
EndFunction

;*******************************************************************************
;DynMorphList
;*******************************************************************************
Function addDynMorph(Int aiID, String asType, Armor akDynEquip, Int JM_MorphList) Global
  Int JM_DynEquip = JDB.solveObj(".SCLExtraData.DynMorphList")
  If !JM_DynEquip
    SCLDatabase Data = SCLibrary.getSCLDatabase()
    Data.setDatabase()
    JM_DynEquip = JDB.solveObj(".SCLExtraData.DynMorphList")
  EndIf
  Int JI_DynMap = JMap.getObj(JM_DynEquip, asType)
  If !JI_DynMap
    JI_DynMap = JIntMap.object()
    JMap.setObj(JM_DynEquip, asType, JI_DynMap)
  EndIf
  Int JM_DynEntry = JMap.object()
  JMap.setForm(JM_DynEntry, "DynEquipment", akDynEquip)
  JMap.setObj(JM_DynEntry, "MorphMap", JM_MorphList)
  JIntMap.setObj(JI_DynMap, aiID, JM_DynEntry)
EndFunction

Function removeDynMorph(Int aiID, String asType) Global
  Int JM_DynEquip = JDB.solveObj(".SCLExtraData.DynMorphList")
  If !JM_DynEquip
    Return
  EndIf
  Int JI_DynMap = JMap.getObj(JM_DynEquip, asType)
  If !JI_DynMap
    Return
  EndIf
  JIntMap.removeKey(JI_DynMap, aiID)
EndFunction

;Utilities +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
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

String Function addIntSuffix(Int aiVal)
  {Adds suffix to the end of the number (i.e. 1st, 23rd, etc.)}
  Int NumberLength = StringUtil.GetLength(aiVal as String)
  Int NextLast = StringUtil.GetNthChar(aiVal as String, NumberLength - 2) as Int
  If NextLast == 1
    Return aiVal + "th"
  Else
    Int Last = StringUtil.GetNthChar(aiVal as String, NumberLength - 1) as Int
    If Last == 1
      Return aiVal + "st"
    ElseIf Last == 2
      Return aiVal + "nd"
    ElseIf Last == 3
      Return aiVal + "rd"
    EndIf
  EndIf
EndFunction

String Function roundFlt(Float afVal, Int aiSigFig)
  {Cuts off decimal places for presentation}
  String sVal = afVal as Float
  Return Stringutil.Substring(sVal, 0, Stringutil.Find(sVal, ".") + aiSigFig + 1)
EndFunction

Function JA_eraseIndices(Int JA_Source, Int JA_Remove)
  {Erases values from the source array. JA_Remove is list of indices to remove
  Can't remove values in normal loops, tends to mess up ordering
  If it's a large array, recommended that JA_Remove is retained before running this,
  and released after}
  Int i = JArray.count(JA_Remove)
  While i
    i -= 1
    JArray.eraseIndex(JA_Source, JArray.getInt(JA_Remove, i))
  EndWhile
EndFunction

Function JF_eraseKeys(Int JF_Source, Int JA_Remove)
  Int i = JArray.count(JA_Remove)
  While i
    i -= 1
    JFormMap.removeKey(JF_Source, JArray.getForm(JA_Remove, i))
  EndWhile
EndFunction


;Array functions ***************************************************************
bool function ArrayAddForm(Form[] myArray, Form myForm)
;Adds a form to the first available element in the array.

	;-----------\
	;Description \	Author: Chesko
	;----------------------------------------------------------------
	;Adds a form to the first available element in the array.

	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		false		=		Error (array full)
	;		true		=		Success

	int i = 0
	;notification("myArray.Length = " + myArray.Length)
	while i < myArray.Length
		if myArray[i] == none
			myArray[i] = myForm
			;notification("Adding " + myForm + " to the array.")
			return true
		else
			i += 1
		endif
	endWhile

	return false

endFunction

bool function ArrayAddRef(ObjectReference[] myArray, ObjectReference myForm)
;Adds a form to the first available element in the array.

	;-----------\
	;Description \	Author: Chesko
	;----------------------------------------------------------------
	;Adds a form to the first available element in the array.

	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		false		=		Error (array full)
	;		true		=		Success

	int i = 0
	;notification("myArray.Length = " + myArray.Length)
	while i < myArray.Length
		if myArray[i] == none
			myArray[i] = myForm
			;notification("Adding " + myForm + " to the array.")
			return true
		else
			i += 1
		endif
	endWhile

	return false

endFunction

bool function ArrayRemoveForm(Form[] myArray, Form myForm, bool bSort = false)
;Removes a form from the array, if found. Sorts the array using ArraySort() if bSort is true.

	;-----------\
	;Description \	Author: Chesko
	;----------------------------------------------------------------
	;Removes a form from the array, if found. Sorts the array using ArraySort() if bSort is true.

	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		false		=		Error (Form not found)
	;		true		=		Success

	int i = 0
	while i < myArray.Length
		if myArray[i] == myForm
			myArray[i] = none
			;notification("Removing element " + i)
			if bSort == true
				ArraySort(myArray)
			endif
			return true
		else
			i += 1
		endif
	endWhile

	return false

endFunction

bool function ArrayRemoveRef(ObjectReference[] myArray, ObjectReference myRef, bool bSort = false)
;Removes a ObjectReference from the array, if found. Sorts the array using ArraySort() if bSort is true.

	;-----------\
	;Description \	Author: Chesko
	;----------------------------------------------------------------
	;Removes a ObjectReference from the array, if found. Sorts the array using ArraySort() if bSort is true.

	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		false		=		Error (Form not found)
	;		true		=		Success

	int i = 0
	while i < myArray.Length
		if myArray[i] == myRef
			myArray[i] = none
			;notification("Removing element " + i)
			if bSort == true
				ArrayRefSort(myArray)
			endif
			return true
		else
			i += 1
		endif
	endWhile

	return false

endFunction

bool function ArraySort(Form[] myArray, int i = 0)
;Removes blank elements by shifting all elements down.


	 ;-----------\
	 ;Description \  Author: Chesko
	 ;----------------------------------------------------------------
	 ;Removes blank elements by shifting all elements down.
	 ;Optionally starts sorting from element i.

	 ;-------------\
	 ;Return Values \
	 ;----------------------------------------------------------------
	 ;		   false		   =			   No sorting required
	 ;		   true			=			   Success

	 bool bFirstNoneFound = false
	 int iFirstNonePos = i
	 while i < myArray.Length
		  if myArray[i] == none
			   if bFirstNoneFound == false
					bFirstNoneFound = true
					iFirstNonePos = i
					i += 1
			   else
					i += 1
			   endif
		  else
			   if bFirstNoneFound == true
			   ;check to see if it's a couple of blank entries in a row
					if !(myArray[i] == none)
						 ;notification("Moving element " + i + " to index " + iFirstNonePos)
						 myArray[iFirstNonePos] = myArray[i]
						 myArray[i] = none

						 ;Call this function recursively until it returns
						 ArraySort(myArray, iFirstNonePos + 1)
						 return true
					else
						 i += 1
					endif
			   else
					i += 1
			   endif
		  endif
	 endWhile

	 return false

endFunction

bool function ArrayRefSort(ObjectReference[] myArray, int i = 0)
;Removes blank elements by shifting all elements down.


	 ;-----------\
	 ;Description \  Author: Chesko
	 ;----------------------------------------------------------------
	 ;Removes blank elements by shifting all elements down.
	 ;Optionally starts sorting from element i.

	 ;-------------\
	 ;Return Values \
	 ;----------------------------------------------------------------
	 ;		   false		   =			   No sorting required
	 ;		   true			=			   Success

	 bool bFirstNoneFound = false
	 int iFirstNonePos = i
	 while i < myArray.Length
		  if myArray[i] == none
			   if bFirstNoneFound == false
					bFirstNoneFound = true
					iFirstNonePos = i
					i += 1
			   else
					i += 1
			   endif
		  else
			   if bFirstNoneFound == true
			   ;check to see if it's a couple of blank entries in a row
					if !(myArray[i] == none)
						 ;notification("Moving element " + i + " to index " + iFirstNonePos)
						 myArray[iFirstNonePos] = myArray[i]
						 myArray[i] = none

						 ;Call this function recursively until it returns
						 ArrayRefSort(myArray, iFirstNonePos + 1)
						 return true
					else
						 i += 1
					endif
			   else
					i += 1
			   endif
		  endif
	 endWhile

	 return false

endFunction

function ArrayClear(Form[] myArray)
;Deletes the contents of this array.

	;-----------\
	;Description \	Author: Chesko
	;----------------------------------------------------------------
	;Deletes the contents of this array.

	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		none

	int i = 0
	while i < myArray.Length
		myArray[i] = none
		i += 1
	endWhile

endFunction


int function ArrayCount(Form[] myArray)
;Counts the number of indices in this array that do not have a "none" type.

        ;-----------\
	;Description \	Author: Chesko
	;----------------------------------------------------------------
	;Counts the number of indices in this array that do not have a "none" type.

	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		int myCount = number of indicies that are not "none"

	int i = 0
	int myCount = 0
	while i < myArray.Length
		if myArray[i] != none
			myCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile

	;notification("MyCount = " + myCount)

	return myCount

endFunction


int function ArrayHasForm(Form[] myArray, Form myForm)
;Attempts to find the given form in the given array, and returns the index of the form if found.

	;-----------\
	;Description \	Author: Chesko
	;----------------------------------------------------------------
	;Attempts to find the given form in the given array, and returns the index of the form if found.

	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		-1		  =		Form not found
	;		int i		  =		Location of the form

	int i = 0

	while i < myArray.Length
		if myArray[i] == myForm
			return i
		else
			i += 1
		endif
	endWhile

	return -1

endFunction


int function ArrayCountForm(Form[] myArray, Form myForm)
;Attempts to count the number of times the given form appears in this array.

	;-----------\
	;Description \
	;----------------------------------------------------------------
	;Attempts to count the number of times the given form appears in this array.

	;-------------\
	;Return Values \
	;----------------------------------------------------------------
	;		0					= 		Form not found
	;		int i		 		=		Number of times form appears in array

	int i = 0
	int iCount = 0

	while i < myArray.Length
		if myArray[i] == myForm
			iCount += 1
			i += 1
		else
			i += 1
		endif
	endWhile

	return iCount

endFunction

;*******************************************************************************

Float Function clampFlt(Float afValue, Float afMin, Float afMax)
  If afValue < afMin
    afValue = afMin
  ElseIf afValue > afMax
    afValue = afMax
  EndIf
  Return afValue
EndFunction

Int Function getTargetData(Actor akTarget, Bool abGenProfile = False)
  {Data now stored under ActorBase for unique actors
  Function will generate new actor profile if no data found && abGenProfile == True
  Player data still stored under actor}
  Form Target
  If akTarget.GetLeveledActorBase().IsUnique()
    Target = akTarget.GetActorBase()
  Else
    Target = akTarget
  EndIf
  If Target
    Int Data = JFormDB.findEntry("SCLActorData", Target)
    If !Data && abGenProfile
      Bool Basic = False
      If Target == PlayerRef || akTarget.IsInFaction(SCLSet.PotentialFollowerFaction)
        Basic = True
      EndIf
      Data = generateActorProfile(Target, Basic)
    EndIf
    Return Data
  Else
    Return 0
  EndIf
EndFunction

Int Function getData(Actor akTarget, Int aiTargetData = 0)
  {Convenience function, gets ActorData if needed}
  Int TargetData
  If aiTargetData
    TargetData = aiTargetData
  Else
    TargetData = getTargetData(akTarget)
  EndIf
  Return TargetData
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

Float Function getExpandTimer(Actor akTarget, Int aiTargetData = 0)
  {Returns length of time (in-game hours) until next expand event happens}
  Int TargetData = getData(akTarget, aiTargetData)
  Return SCLSet.DefaultExpandTimer * JMap.getFlt(TargetData, "SCLExpandTimerBonus", 1)
EndFunction

Float Function giveExpandBonus(Actor akTarget, Int aiMultiply = 1, Int aiTargetData = 0)
  {Gives the actor additional base capacity, augmented by buffs}
  Int TargetData = getData(akTarget, aiTargetData)
  Int OverfullTier = getCurrentOverfull(akTarget, TargetData)
  Float Bonus = SCLSet.DefaultExpandBonus * JMap.getFlt(TargetData, "SCLExpandBonusMulti", 1)
  If OverfullTier > 1
    Bonus *= ((OverfullTier - 1) * 0.1) + 1
  EndIf
  Bonus *= aiMultiply
  Notice("Adding expand bonus of " + Bonus + " to " + nameGet(akTarget))
  JMap.setFlt(TargetData, "STBase", JMap.getFlt(TargetData, "STBase") + Bonus)
  Return Bonus
EndFunction

Float Function getMax(Actor akTarget, Int aiTargetData = 0)
  Int TargetData = getData(akTarget, aiTargetData)
  Return getAdjBase(akTarget, TargetData) * JMap.getFlt(TargetData, "STStretch")
EndFunction

Float Function getAdjBase(Actor akTarget, Int aiTargetData = 0)
  Int TargetData = getData(akTarget, aiTargetData)
  Return JMap.getFlt(TargetData, "STBase") * akTarget.GetScale() * NetImmerse.GetNodeScale(akTarget, "NPC Root [Root]", False) * SCLSet.AdjBaseMulti
EndFunction

Int Function countItemTypes(Actor akTarget, Int aiItemType, Bool abCountForms = False)
  {Will normally just count same forms as 1, use abCountForms to count forms in bundles}
  Int JF_ST_Contents = getContents(akTarget, aiItemType)
  If !abCountForms
    Return JValue.count(JF_ST_Contents)
  Else
    Form ItemKey = JFormMap.nextKey(JF_ST_Contents)
    Int Num
    While ItemKey
      If ItemKey as ObjectReference
        If ItemKey as SCLBundle
          Num += (ItemKey as SCLBundle).NumItems
        Else
          Num += 1
        EndIf
      EndIf
      ItemKey = JFormMap.nextKey(JF_ST_Contents, ItemKey)
    EndWhile
    Return Num
  EndIf
EndFunction

Int Function countAllItems(Actor akTarget, Bool abCountForms = False)
  {Counts all item types registered in JI_ItemTypes}
  Int i = JIntMap.nextKey(SCLSet.JI_ItemTypes)
  Int Total
  While i
    Total += countItemTypes(akTarget, i, abCountForms)
    i = JIntMap.nextKey(SCLSet.JI_ItemTypes, i)
  EndWhile
  Return Total
EndFunction

Int Function getCompleteContents(Actor akTarget, Int aiTargetData = 0)
  {Returns a JFormMap with all items in the actor's stomach in it.}
  Int TargetData
  If aiTargetData
    TargetData = aiTargetData
  Else
    TargetData = getTargetData(akTarget)
  EndIf
  Int JF_Return = JFormMap.object()
  Int i = JIntMap.nextKey(SCLSet.JI_ItemTypes)
  While i
    Int JF_ContentsMap = getContents(akTarget, i, TargetData)
    If !JValue.empty(JF_ContentsMap)
      JFormMap.addPairs(JF_Return, JF_ContentsMap, False)
    EndIf
    i = JIntMap.nextKey(SCLSet.JI_ItemTypes, i)
  EndWhile
  Return JF_Return
EndFunction

Float Function getTotalCombined(Actor akTarget, Int aiTargetData = 0)
  Int TargetData = getData(akTarget, aiTargetData)
  Float TotalWeight
  String TotalKey = JMap.nextKey(SCLSet.JM_TotalValueList)
  While TotalKey
    Int JA_ValueList = JMap.getObj(SCLSet.JM_TotalValueList, TotalKey)
    Int j = JArray.count(JA_ValueList)
    While j
      j -= 1
      TotalWeight += JMap.getFlt(TargetData, JArray.getStr(JA_ValueList, j))
    EndWhile
    TotalKey = JMap.nextKey(SCLSet.JM_TotalValueList, TotalKey)
  EndWhile
  Return TotalWeight
EndFunction

Float Function getTotalBelly(Actor akTarget, Int aiTargetData = 0)
  Int TargetData = getData(akTarget, aiTargetData)
  Int i = JArray.count(SCLSet.JA_BellyValuesList)
  Float TotalWeight
  While i
    i -= 1
    TotalWeight += JMap.getFlt(TargetData, JArray.getStr(SCLSet.JA_BellyValuesList, i))
  EndWhile
  Return TotalWeight
EndFunction

Int Function getItemDataEntry(Form akItem)
  {TODO: Look overthis again}

  If akItem as SCLBundle
    akItem = (akItem as SCLBundle).ItemForm
  EndIf

  ;Search formlists for the item
  Int f = SCLSet.SCL_ItemFormlistSearch.GetSize()
  While f
    f -= 1
    FormList flSearch = SCLSet.SCL_ItemFormlistSearch.GetAt(f) as Formlist
    If flSearch.HasForm(akItem)
      Return JFormDB.findEntry("SCLItemDatabase", flSearch)
    Endif
  EndWhile

  ;Search for the item directly
  Int JM_DB_ItemEntry = JFormDB.findEntry("SCLItemDatabase", akItem)
  If JM_DB_ItemEntry != 0
    Return JM_DB_ItemEntry
  EndIf

  ;Search for the base item directly
  If akItem as ObjectReference
    JM_DB_ItemEntry = JFormDB.findEntry("SCLItemDatabase", (akItem as ObjectReference).GetBaseObject())
    If JM_DB_ItemEntry != 0
      Return JM_DB_ItemEntry
    EndIf
  EndIf

  If akItem as Actor
    ;Search for actorbase entry
    ActorBase SearchBase = (akItem as Actor).GetLeveledActorBase()
    JM_DB_ItemEntry = JFormDB.findEntry("SCLItemDatabase", SearchBase)
    If JM_DB_ItemEntry != 0
      Return JM_DB_ItemEntry
    EndIf

    ;Search for race entry
    Race SearchRace = SearchBase.GetRace()
    JM_DB_ItemEntry = JFormDB.findEntry("SCLItemDatabase", SearchRace)
    If JM_DB_ItemEntry != 0
      Return JM_DB_ItemEntry
    EndIf
  EndIf

  ;Search Keywords
  Int j = SCLSet.SCL_ItemKeywordSearch.GetSize()
  While j
    j -= 1
    Keyword kwSearch = SCLSet.SCL_ItemKeywordSearch.GetAt(j) as Keyword
    If akItem.HasKeyword(kwSearch)
      Return JFormDB.findEntry("SCLItemDatabase", kwSearch)
    EndIf
  EndWhile
  Return 0
EndFunction

;/Int Function findEquipSize(Float fValue)
  {Binary Search Algorithm
  See https://en.wikipedia.org/wiki/Binary_search_algorithm}
  Int L = 0
  Int R = SCLSet.BEquipmentLevels.length - 1
  While L < R
    Int m = Math.floor((L + R) / 2)
    Float s = SCLSet.BEquipmentLevels[m]
    If s < fValue
      L = m + 1
    ElseIf s > fValue
      R = m - 1
    ElseIf s == fValue
      Return m
    Endif
  EndWhile
  Return L
EndFunction/;

String Function getShortItemTypeDesc(Int aiItemType)
  Return JMap.getStr(JIntMap.getObj(SCLSet.JI_ItemTypes, aiItemType), "STShortDescription")
EndFunction

String Function getFullItemTypeDesc(Int aiItemType)
  Return JMap.getStr(JIntMap.getObj(SCLSet.JI_ItemTypes, aiItemType), "STFullDescription")
EndFunction

;Color Functions
Int Function genRedSpectrum(Float afPercent)
  {Returns hex code that transitions from white to red as it approaches 1 (then goes towards black)}
  Int Hex = Math.Ceiling(0xFF * afPercent)
  Int Remainder = 0
  If Hex > 0xFF
    Remainder = Hex - 0xFF
    Hex = 0xFF
  EndIf
  Return 0xFFFFFF - (0xFF * Hex) - Hex - (Remainder * 0xFF00)
EndFunction

Int Function genGreenSpectrum(Float afPercent)
  {Returns hex code that transitions from white to blue as it approaches 1 (then goes towards black)}
  Int Hex = Math.Ceiling(0xFF * afPercent)
  Int Remainder = 0
  If Hex > 0xFF
    Remainder = Hex - 0xFF
    Hex = 0xFF
  EndIf
  Return 0xFFFFFF - (0xFF00 * Hex) - Hex - (Remainder * 0xFF)
EndFunction

Int Function genBlueSpectrum(Float afPercent)
  {Returns hex code that transitions from white to green as it approaches 1 (then goes towards black)}
  Int Hex = Math.Ceiling(0xFF * afPercent)
  Int Remainder = 0
  If Hex > 0xFF
    Remainder = Hex - 0xFF
    Hex = 0xFF
  EndIf
  Return 0xFFFFFF - (0xFF00 * Hex) - (0xFF * Hex) - Remainder
EndFunction


Bool Function addToTrackingList(Actor akTarget, Bool abOverride = False)
  {Inserts actor into tracking list, overriding a non-unique NPC if needed
  use abOverride and it'll override unique NPCs as well}
  Return False
EndFunction

Float Function genDigestValue(Form akItem, Bool abMod1 = False, Bool abMod2 = False)
  Int JM_DB_ItemEntry = getItemDataEntry(akItem)
  Float Value
  If JM_DB_ItemEntry && JMap.hasKey(JM_DB_ItemEntry, "WeightOverride")
    Value = JMap.getFlt(JM_DB_ItemEntry, "WeightOverride")
  Else
    Value = akItem.GetWeight()
  EndIf

  If JM_DB_ItemEntry && JMap.hasKey(JM_DB_ItemEntry, "WeightModifier")
    Value *= JMap.getFlt(JM_DB_ItemEntry, "WeightModifier", 1)
  EndIf

  If Value > 0
    Return Value
  Else
    Return 0.1
  EndIf
EndFunction

Float Function getOverfullPercent(Actor akTarget, Int aiTargetData = 0)
  Int TargetData
  If aiTargetData
    TargetData = aiTargetData
  Else
    TargetData = getTargetData(akTarget)
  EndIf
  Float Fullness = JMap.getFlt(TargetData, "STFullness")
  Float Base = getAdjBase(akTarget, TargetData)
  If Fullness > Base
    Float Percent = Fullness - Base / getMax(akTarget, TargetData) - Base
    Return Percent
  Else
    Return 0
  EndIf
EndFunction

Int Function getOverfullTier(Float afValue, Float afFullness)
  Int Tier
  If afValue > 1
    Tier = 6
  ElseIf afValue > 0.8
    Tier = 5
  ElseIf afValue > 0.6
    Tier = 4
  ElseIf afValue > 0.4
    Tier = 3
  ElseIf afValue > 0.2
    Tier = 2
  ElseIf afValue
    Tier = 1
  Else
    Tier = 0
  EndIf
  If afValue
    Int AddAmount = Math.Floor(afFullness / 100) ;Right now, it every 100 units per tier, maybe adjust this to be more extreme
    Tier += AddAmount
  EndIf
  Return Tier
EndFunction

Int Function getCurrentOverfull(Actor akTarget, Int aiTargetData = 0)
  Int TargetData
  If aiTargetData
    TargetData = aiTargetData
  Else
    TargetData = getTargetData(akTarget)
  EndIf
  Return JMap.getInt(TargetData, "SCLAppliedOverfullTier")
EndFunction

Float Function getHeavyPercent(Actor akTarget, Int aiTargetData = 0)
  Int TargetData
  If aiTargetData
    TargetData = aiTargetData
  Else
    TargetData = getTargetData(akTarget)
  EndIf
  Float HeavyPercent
  Float Fullness = JMap.getFlt(TargetData, "STFullness")  ;Replace this with total?
  Int PerkLevel = JMap.getInt(TargetData, "SCLHeavyBurden")
  Int MaxWeight = 150 * (PerkLevel + 1)
  Int BaseWeight = 100 * (PerkLevel + 1)
  If Fullness > BaseWeight
    HeavyPercent = (Fullness - BaseWeight) / (MaxWeight - BaseWeight)
  Else
    HeavyPercent = 0
  EndIf
  Return HeavyPercent
EndFunction

Int Function getHeavyTier(Float afValue)
  If afValue > 1
    Return 6
  ElseIf afValue > 0.8
    Return 5
  ElseIf afValue > 0.6
    Return 4
  ElseIf afValue > 0.4
    Return 3
  ElseIf afValue > 0.2
    Return 2
  ElseIf afValue
    Return 1
  Else
    Return 0
  EndIf
EndFunction

Int Function getCurrentHeavy(Actor akTarget, Int aiTargetData = 0)
  Int TargetData
  If aiTargetData
    TargetData = aiTargetData
  Else
    TargetData = getTargetData(akTarget)
  EndIf
  Return JMap.getInt(TargetData, "SCLAppliedHeavyTier")
EndFunction

Form[] Function getLoadedActors()
  Int i
  Int j
  Int NumAlias = SCLSet.SCL_MonitorManagerQuest.GetNumAliases()
  Form[] ReturnArray = Utility.CreateFormArray(NumAlias, None)
  While i < NumAlias
    ReferenceAlias LoadedAlias = SCLSet.SCL_MonitorManagerQuest.GetNthAlias(i) as ReferenceAlias
    Form loadActor = LoadedAlias.GetActorReference()
    If loadActor
      ReturnArray[j] = loadActor
      j += 1
    EndIf
    i += 1
  EndWhile
  Return ReturnArray
EndFunction

Function sortFloatArray (Float[] MyArray)
 {Sorts float array using bubble sort proceedure}
 ;Taken from https://www.creationkit.com/index.php?title=User:Sclerocephalus#A_short_function_for_sorting_arrays
Int Index1
Int Index2 = MyArray.Length - 1

	While (Index2 > 0)
		Index1 = 0
		While (Index1 < Index2)
			If (MyArray [Index1] > MyArray [Index1 + 1])
				Float SwapDummy = MyArray [Index1]
				MyArray [Index1] = MyArray [Index1 + 1]
				MyArray [Index1 + 1] = SwapDummy
			EndIf
			Index1 += 1
		EndWhile
		Index2 -= 1
	EndWhile
EndFunction

;/Bool Function canStoreItem(Actor akTarget, Form akItem, Int aiTargetData = 0)
  Int TargetData = getData(akTarget, aiTargetData)
  If countItemTypes(akTarget, 2) < getTotalPerkLevel(akTarget, "SCLStoredLimitUp", TargetData)  ;Perks will increase this through OnEffectStart/OnEffectFinish chains (maybe)
    Float DigestValue = genDigestValue(akItem)
    If JMap.getFlt(TargetData, "STFullness") + DigestValue < getMax(akTarget, TargetData) || SCLSet.GodMode1
      Return True
    EndIf
  EndIf
  Return False
EndFunction/;

Bool Function isInContainer(Form akItem)
  Int JM_DataEntry = getItemDataEntry(akItem)
  Return JMap.getInt(JM_DataEntry, "IsInContainer") as Bool
EndFunction

Bool Function isNotFood(Form akItem)
  Int JM_DataEntry = getItemDataEntry(akItem)
  Return JMap.getInt(JM_DataEntry, "IsNotFood") as Bool
EndFunction

Float Function getLiquidRatio(Form akItem)
  Int JM_DataEntry = getItemDataEntry(akItem)
  Float Ratio = JMap.getFlt(JM_DataEntry, "LiquidRatio")
  Ratio = clampFlt(Ratio, 0, 1)
  Return Ratio
EndFunction

Bool Function isModInstalled(String Mod) Global
	Return Game.GetModByName(Mod) != 255
EndFunction

Bool Function isSKSEPluginInstalled(String Plugin) Global
  If SKSE.GetPluginVersion(Plugin) == -1
    Return False
  Else
    Return True
  EndIf
EndFunction

Float Function modBase(Actor akTarget, Float aiMod, Int aiTargetData = 0) Global
  {Use this to change an actor's base capacity.}
  Int TargetData
  If aiTargetData
    TargetData = aiTargetData
  Else
    TargetData = SCLibrary.getActorData(akTarget)
  EndIf
  Float Base = JMap.getFlt(TargetData, "STBase")
  Base += aiMod
  If Base < 0.5
    Base = 0.5
  EndIf
  JMap.setFlt(TargetData, "STBase", Base)
EndFunction

;Debug Message Functions *******************************************************
Function togDMEnable(Int aiMessageID)
  If aiMessageID >= 0 && aiMessageID < 128
    SCLSet.DMEnableArray[aiMessageID] = !SCLSet.DMEnableArray[aiMessageID]
  EndIf
EndFunction

Function setDMEnable(Int aiMessageID, Bool abVal)
  If aiMessageID >= 0 && aiMessageID < 128
    SCLSet.DMEnableArray[aiMessageID] = abVal
  EndIf
EndFunction

Bool Function getDMEnable(INt aiMessageID)
  If aiMessageID >= 0 && aiMessageID < 128
    Return SCLSet.DMEnableArray[aiMessageID]
  EndIf
EndFunction

;Actor Profile Functions *******************************************************
Int Function generateActorProfile(Form akTarget, Bool abBasic = False)
  If GenerateLock
    While GenerateLock
      Utility.WaitMenuMode(0.5)
    EndWhile
  EndIf
  GenerateLock = True
  Int TargetData = createActorProfile(akTarget, abBasic = abBasic)
  GenerateLock = False
  Return TargetData
EndFunction

Int ScriptDataVersion = 1
Int Function createActorProfile(Form akTarget = None, Int JM_Container = 0, Bool abBasic = False)
  {Set akTarget and this will automatically link the actor to the profile.
  Set JM_Container to generate a profile within that container
  Use abBasic == False to generate a semi-randomized profile, or == True for a player-like basic profile}
  Int TargetData
  If akTarget
    TargetData = JMap.object()
    JFormDB.setEntry("SCLActorData", akTarget, TargetData)
  ElseIf(JM_Container) && JValue.isMap(JM_Container)
    TargetData = JM_Container
  Else
    Issue("No valid target given for createActorProfile function", 1)
  EndIf

  If !abBasic
    Int StomachChance = Utility.RandomInt()
    If StomachChance > 90
      Int RandomBase = Utility.RandomInt(25, 50)
      JMap.setFlt(TargetData, "STBase", RandomBase)
      JMap.setFlt(TargetData, "STStretch", 1.75)
      JMap.setInt(TargetData, "STStoredLimit", 2)
      JMap.setFlt(TargetData, "STDigestionRate", 1)
      JMap.setInt(TargetData, "STTier", 3)
      JMap.setInt(TargetData, "SCLGluttony", 15)
      JMap.setInt(TargetData, "SCLInsobriety", 5)
    ElseIf StomachChance > 50
      Int RandomBase = Utility.RandomInt(10, 15)
      JMap.setFlt(TargetData, "STBase", RandomBase)
      JMap.setInt(TargetData, "STStoredLimit", 1)
      JMap.setInt(TargetData, "STTier", 2)
      JMap.setFlt(TargetData, "STStretch", 1.6)
      JMap.setFlt(TargetData, "STDigestionRate", 0.5)
      JMap.setInt(TargetData, "SCLGluttony", 10)
      JMap.setInt(TargetData, "SCLInsobriety", 5)
    Else
      Int RandomBase = Utility.RandomInt(2, 5)
      JMap.setFlt(TargetData, "STBase", RandomBase)
      JMap.setInt(TargetData, "STStoredLimit", 0)
      JMap.setInt(TargetData, "STTier", 1)
      JMap.setFlt(TargetData, "STStretch", 1.5)
      JMap.setFlt(TargetData, "STDigestionRate", 0.2)
      JMap.setInt(TargetData, "SCLGluttony", 5)
      JMap.setInt(TargetData, "SCLInsobriety", 5)
    EndIf
  Else
    JMap.setFlt(TargetData, "STBase", 3)
    JMap.setInt(TargetData, "STStoredLimit", 0)
    JMap.setInt(TargetData, "STTier", 1)
    JMap.setFlt(TargetData, "STStretch", 1.5)
    JMap.setFlt(TargetData, "STDigestionRate", 0.2)
    JMap.setInt(TargetData, "SCLGluttony", 5)
    JMap.setInt(TargetData, "SCLInsobriety", 5)
    JMap.setInt(TargetData, "SCLBasicProfile", 1)
  EndIf
  JMap.setObj(TargetData, "Contents1", JFormMap.object())
  JMap.setObj(TargetData, "Contents2", JFormMap.object())
  JMap.setFlt(TargetData, "LastUpdateTime", Utility.GetCurrentGameTime())
  JMap.setFlt(TargetData, "STLastFullness", 0)
  JMap.setObj(TargetData, "SCLTrackingData", JMap.object())
  JMap.setInt(TargetData, "ActorDataVersion", ScriptDataVersion)
  JMap.setInt(TargetData, "SCLEnableUpdates", 1)  ;May not be necessary
  Return TargetData
EndFunction

;Item Functions ****************************************************************
;Recommended that updateSingleContents() is run whenever any of these are used
;It's not in the functions themselves incase you add in in multiple items at once
;and want to update only at the end.

Int Function addItem(Actor akTarget, ObjectReference akReference = None, Form akBaseObject = None, Int aiItemType, Float afDigestValueOverRide = -1.0, Int aiItemCount = 1, Bool abMoveNow = True)
  If (!akReference && !akBaseObject) || !aiItemType || !akTarget
    Return 0
  EndIf
  Int Future = SCLSet.ItemThreadManager.addItemAsync(akTarget, akReference, akBaseObject, aiItemType, afDigestValueOverRide, aiItemCount, abMoveNow)
  Int ReturnEntry
  While !ReturnEntry
    Utility.WaitMenuMode(0.1)
    ReturnEntry = SCLSet.ItemThreadManager.get_result(Future)
  EndWhile
  Return ReturnEntry
EndFunction

;/Bool addItemLocked = False
Int Function addItem(Actor akTarget, ObjectReference akReference = None, Form akBaseObject = None, Int aiItemType, Float afDigestValueOverRide = -1.0, Int aiItemCount = 1, Bool abMoveNow = True)
  ;Done: NEED TO WRITE CASE OF ADDING SCL BUNDLE
  ;Should be fine, just set afDigestValueOverRide to 0: Also rewrite to allow insertion into any type

  ;Noted: NEXT TIME IN CREATION KIT, LOOK UP GOLD POUCH SCRIPT

  {Adds an item into the actor's stomach array. Returns the item entry ID.
  Retrieve it using JArray.findObj(JA_ST_Contents, JM_ItemEntry)
  REMEMBER THAT THERE"S NOW A UNIQUE JFORMMAP FOR EACH ITEM TYPE, SO USE getContents()!
  Must have either akBaseObject or akReference filled. akReference will take precedence if both
  Every item will be ID'd via it's object reference
  If it only has a form, will go into a "pouch" with the same form objects
  Bundle will be the ObjectReference it's stored under; use findFormBundle() to search form bundles
  afDigestValueOverRide will only work if akReference is present; to change form bundles, use setFormDValue()
  aiItemCount only works for Forms
  abMoveNow will delay moving the item to the holding cell, in case it needs to be done manually}
  If addItemLocked
    While addItemLocked
      Utility.WaitMenuMode(1)
    EndWhile
  EndIf
  addItemLocked = True
  String n = nameGet(akTarget) + ": "
  Int JF_ST_Contents = getContents(akTarget, aiItemType)
  If !JF_ST_Contents
    Notice(n + "Contents not found!", 1)
  Else
    Notice(n + "Contents found!", 1)
  EndIf
  Int JM_ItemEntry
  If !akReference && !akBaseObject
    Issue("No valid item given for addItem. Returning...")
    Return -1
  ElseIf akReference as SCLBundle
    Form BundleForm = (akReference as SCLBundle).ItemForm
    JM_ItemEntry = findObjBundle(JF_ST_Contents, BundleForm)
    If !JM_ItemEntry
      JM_ItemEntry = JMap.object()
      Float DValue = genDigestValue(BundleForm)
      JMap.setFlt(JM_ItemEntry, "DigestValue", DValue * (akReference as SCLBundle).NumItems)  ;(IndvDVal x (NumItems - 1)) + ActiveDVal
      JMap.setFlt(JM_ItemEntry, "ActiveDVal", DValue)  ;AKA All items DValue + in process item
      JMap.setFlt(JM_ItemEntry, "IndvDVal", DValue)  ;For a single item, just the ActiveDVal
      If abMoveNow
        moveToHoldingCell(akReference)
      EndIf
    Else
      SCLBundle ItemBundle = JMap.getForm(JM_ItemEntry, "ItemReference") as SCLBundle
      ItemBundle.NumItems += (akReference as SCLBundle).NumItems
      Float DValue = JMap.getFlt(JM_ItemEntry, "ActiveDVal") + (JMap.getFlt(JM_ItemEntry, "IndvDVal") * (ItemBundle.NumItems - 1))
      Notice(n + "Recalculating DigestValue, DValue=" + DValue, 1)
      JMap.setFlt(JM_ItemEntry, "DigestValue", DValue)
    EndIf

  ElseIf akReference  ;Make new entry for akReference
    Notice(n + "akReference detected. Creating new entry...", 1)
    JM_ItemEntry = JMap.object()
    Float DValue
    If afDigestValueOverRide < 0
      DValue = genDigestValue(akReference)  ;Make sure to check base object in genDigestValue
    Else
      DValue = afDigestValueOverRide
    EndIf
    Notice(n + "Digest value for " + nameGet(akReference) + "=" + DValue, 1)
    JMap.setFlt(JM_ItemEntry, "ActiveDVal", DValue)
    JMap.setFlt(JM_ItemEntry, "DigestValue", DValue)
    JMap.setFlt(JM_ItemEntry, "IndvDVal", DValue)
    JMap.setForm(JM_ItemEntry, "ItemReference", akReference) ;Redundancy, just in case you only have the ItemEntry
    JMap.setInt(JM_ItemEntry, "ItemType", aiItemType) ;again, redundancy

    JFormMap.setObj(JF_ST_Contents, akReference, JM_ItemEntry)
    If abMoveNow
      Notice(n + "Moving ref to holding cell", 1)
      moveToHoldingCell(akReference)
    EndIf
    Notice(nameGet(akReference) + " added to " + nameGet(akTarget) + " as item type " + aiItemType, 1)
  Else
    ;Find previous entries
    Notice(n + "Form detected", 1)
    JM_ItemEntry = findObjBundle(JF_ST_Contents, akBaseObject)

    If !JM_ItemEntry  ;Make new entry
      Notice(n + "No entry detected. Creating new entry.")
      JM_ItemEntry = JMap.object()

      Float DValue = genDigestValue(akBaseObject)
      Notice(n + "Digest value for " + nameGet(akBaseObject) + "=" + DValue, 1)
      JMap.setFlt(JM_ItemEntry, "DigestValue", DValue * aiItemCount)  ;(IndvDVal x (NumItems - 1)) + ActiveDVal
      JMap.setFlt(JM_ItemEntry, "ActiveDVal", DValue)  ;AKA All items DValue + in process item
      JMap.setFlt(JM_ItemEntry, "IndvDVal", DValue)  ;For a single item, just the ActiveDVal

      Notice(n + "Placing SCLBundle at holding cell", 1)
      SCLBundle ItemBundle = SCLSet.SCL_HoldingCell.PlaceAtMe(SCLSet.SCL_ItemBundle) as SCLBundle
      If !ItemBundle
        Notice(n + "Placement failed", 1)
      Else
        Notice(n + "Placement succeeded", 1)
      EndIf
      JMap.setForm(JM_ItemEntry, "ItemReference", ItemBundle) ;Redundancy, just in case you only have the ItemEntry
      JMap.setInt(JM_ItemEntry, "ItemType", aiItemType) ;again, redundancy
      ItemBundle.ItemForm = akBaseObject
      ItemBundle.NumItems = aiItemCount
      ItemBundle.MyActor = akTarget
      Notice(n + "Setting data in SCLBundle: " + nameGet(ItemBundle.ItemForm) + ", " + ItemBundle.NumItems, 1)
      JFormMap.setObj(JF_ST_Contents, ItemBundle, JM_ItemEntry)

    Else ;Add to previous entry
      Notice(n + "Previous entry found! Adding...", 1)
      SCLBundle ItemBundle = JMap.getForm(JM_ItemEntry, "ItemReference") as SCLBundle
      ItemBundle.NumItems += aiItemCount

      Float DValue = updateDValue(JM_ItemEntry)
    EndIf
    Notice(nameGet(akBaseObject) + " added to " + nameGet(akTarget) + " as item type " + aiItemType)
  EndIf
  addItemLocked = False
  Return JM_ItemEntry
EndFunction/;

Bool Function removeItem(Actor akTarget, ObjectReference akReference = None, Form akBaseObject = None, Int aiItemType, Int aiItemCount = 1, Bool abDelete = False, Int aiTargetData = 0)
  {Removes an item from an actor's stomach.
  akBaseObject will remove an item from either a reference or an SCL Bundle, whichever is applicable.
  Will continue to do so as long as it finds items and aiItemCount > 0
  Putting in a SCLBundle will remove that entire bundle
  abDelete will delete any ObjectReference affected by this
  Suggested that you update the actor after this
  Returns whether the item was removed successfully}
  Int TargetData = getData(akTarget, aiTargetData)
  Int Contents = getContents(akTarget, aiItemType, TargetData)
  If !akReference && !akBaseObject
    Issue("No valid item given for removeItem. Returning...")
    Return False
  ElseIf akReference
    If JFormMap.removeKey(Contents, akReference)
      If akReference as SCLBundle || abDelete
        SCLibrary.addToObjectTrashList(akReference, 1)
        If akReference as Actor
          SCLibrary.addToActorTrashList(akReference as Actor, 1)
        EndIf
      EndIf
      Return True
    EndIf
  ElseIf akBaseObject
    Int Remaining = aiItemCount
    Int Removed
    SCLBundle Bundle = findFormBundle(Contents, akBaseObject)
    If Bundle
      Int Stored = Bundle.NumItems
      If Stored > Remaining
        Stored -= Remaining
        Removed += Remaining
        Remaining = 0
        Bundle.NumItems = Stored
        updateDValue(JFormMap.getObj(Contents, Bundle))
      ElseIf Stored <= Remaining
        Removed += Stored
        Remaining -= Stored
        JFormMap.removeKey(Contents, Bundle)
        SCLibrary.addToObjectTrashList(Bundle, 1)
      EndIf
    EndIf
    If Remaining
      Bool Done = False
      While Remaining && !Done
        ObjectReference Ref = findRefFromBase(Contents, akBaseObject)
        If Ref
          JFormMap.removeKey(Contents, Ref)
          If abDelete
            SCLibrary.addToObjectTrashList(Ref, 1)
            If akReference as Actor
              SCLibrary.addToActorTrashList(Ref as Actor, 1)
            EndIf
          EndIf
          Removed += 1
          Remaining -= 1
        Else
          Done = True
        EndIf
      EndWhile
    EndIf
    If Removed > 0
      Return True
    Else
      Return False
    EndIf
  EndIf
EndFunction

ObjectReference Function findRefFromBase(Int JF_Contents, Form akBaseObject)
  ObjectReference i = JFormMap.nextKey(JF_Contents) as ObjectReference
  While i
    If i.GetBaseObject() == akBaseObject
      Return i
    EndIf
    i = JFormMap.nextKey(JF_Contents, i) as ObjectReference
  EndWhile
  Return None
EndFunction

Function moveToHoldingCell(ObjectReference akRef)
  ;akRef.DisableNoWait()
  akRef.MoveTo(SCLSet.SCL_HoldingCell)
  ;akRef.EnableNoWait()
EndFunction

SCLBundle Function findFormBundle(Int JF_ContentsMap, Form akBaseObject)
  {Searches through all items in an actor's content array, returns bundle}
  Form SearchRef = JFormMap.nextKey(JF_ContentsMap)
  While SearchRef
    If SearchRef as ObjectReference
      If SearchRef as SCLBundle
        Form SearchForm = (SearchRef as SCLBundle).ItemForm
        If SearchForm == akBaseObject
          Return SearchRef as SCLBundle
        EndIf
      EndIf
    EndIf
    SearchRef = JFormMap.nextKey(JF_ContentsMap, SearchRef)
  EndWhile
  Return None
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

Function setFormDValue(Actor akTarget, Int aiItemType, Form akBaseObject, Float aiDigestValue)
  {Sets the IndvDVal of an item pouch (effectively changing the DValue of all of the items held within)}
  Int JF_ContentsMap = getContents(akTarget, aiItemType)
  Int JM_ItemEntry = findObjBundle(JF_ContentsMap, akBaseObject)
  JMap.setFlt(JM_ItemEntry, "IndvDVal", aiDigestValue)
  Float DValue = JMap.getFlt(JM_ItemEntry, "ActiveDVal") + (aiDigestValue * ((JMap.getForm(JM_ItemEntry, "ItemReference") as SCLBundle).NumItems - 1))
  JMap.setFlt(JM_ItemEntry, "DigestValue", DValue)
  updateSingleContents(akTarget, aiItemType)
EndFunction

Float Function updateDValue(Int JM_Entry)
  ObjectReference Ref = JMap.getForm(JM_Entry, "ItemReference") as ObjectReference
  Float DValue
  If Ref as SCLBundle
    DValue = JMap.getFlt(JM_Entry, "ActiveDVal") + (JMap.getFlt(JM_Entry, "IndvDVal") * ((Ref as SCLBundle).NumItems - 1))
  Else
    DValue = JMap.getFlt(JM_Entry, "ActiveDVal")
  EndIf
  JMap.setFlt(JM_Entry, "DigestValue", DValue)
  Return DValue
EndFunction


Function addMultiRefs(Actor akTarget, Int JA_RefArray, Int aiItemType)
  {Convenience function to add an array of ObjectReferences}
  Int i = JArray.count(JA_RefArray)
  While i > 0
    i -= 1
    ObjectReference Ref = JArray.getForm(JA_RefArray, i) as ObjectReference
    addItem(akTarget, Ref, aiItemType = aiItemType)
  EndWhile
EndFunction

;Update Functions **************************************************************
Function sendTakePerkMessage(Actor akTarget)
  If akTarget == PlayerRef
    Debug.Notification("You have stomach perks available")
  ElseIf akTarget.IsPlayerTeammate()
    Debug.Notification(nameGet(akTarget) + " has stomach perks available")
  EndIf
EndFunction

;IDEA: Tier perks, prevent actors from increasing their stomach size/other perks unless they take the tier perk

Function quickUpdate(Actor akTarget, Bool abEX = False, Bool abNoVomit = False)
  {Use abEX for a slower, but more complete, update}
  If !abEX
    updateFullness(akTarget, abNoVomit)
  Else
    updateFullnessEX(akTarget, abNoVomit)
  EndIf
  visualBellyUpdate(akTarget, getTotalBelly(akTarget))
  updateDamage(akTarget)
  Int QUpdate = ModEvent.Create("SCLQuickUpdate" + getTargetData(akTarget))
  ModEvent.Send(QUpdate)
EndFunction

Function updateDamage(Actor akTarget, Int aiTargetData = 0)
  ;Need to rethink how this is applied. Make sure that if the calculated tier is greater that max num of spells,
  ;it picks the highest one
  ;Also remember to add modifier based on current fullness (if > 100, add 1 tier)
  Int TargetData
  If aiTargetData
    TargetData = aiTargetData
  Else
    TargetData = getTargetData(akTarget)
  EndIf
  Float Fullness = JMap.getFlt(TargetData, "STFullness")

  Float Overfull = getOverfullPercent(akTarget, TargetData)
  Int OverfullTier = getOverfullTier(Overfull, Fullness)
  If OverfullTier > SCLSet.SCL_OverfullHealSpeedArray.length - 1  ;Just using this as a test marker, all spell arrays should be filled the same
    OverfullTier = SCLSet.SCL_OverfullHealSpeedArray.length - 1 ;Ensures that the overfull tier does not go above spells set
  EndIf
  Int CurrentOverfull = getCurrentOverfull(akTarget, TargetData)
  If OverfullTier != CurrentOverfull
    SCLSet.SCL_OverfullHealSpeedArray[OverfullTier].cast(akTarget) ;If it's tier 0, it casts the dispel effect and nothing else
    SCLSet.SCL_OverfullStaminaMagicArray[OverfullTier].cast(akTarget)

    JMap.setInt(TargetData, "SCLAppliedOverfullTier", OverfullTier)
  EndIf

  Float Heavy = getHeavyPercent(akTarget, TargetData)
  Int HeavyTier = getHeavyTier(Heavy)
  If HeavyTier > SCLSet.SCL_HeavySpeedArray.length - 1
    HeavyTier = SCLSet.SCL_HeavySpeedArray.length - 1
  EndIf
  Int CurrentHeavy = getCurrentHeavy(akTarget, TargetData)
  If HeavyTier != CurrentHeavy
    SCLSet.SCL_HeavySpeedArray[HeavyTier].cast(akTarget)
    ;Add more spell arrays here.

    JMap.setInt(TargetData, "SCLAppliedHeavyTier", HeavyTier)
  EndIf

  Int Storage = countItemTypes(akTarget, 2, TargetData)
  Int StorageMax = getTotalPerkLevel(akTarget, "SCLStoredLimitUp", TargetData)
  If Storage > StorageMax
    Int Level = ((Storage - StorageMax) / 2) + (StorageMax - 1)
    If Level > SCLSet.SCL_StoredDamageArray.length - 1
      Level = SCLSet.SCL_StoredDamageArray.length - 1
    EndIf
    Int CurrentStorageDamage = getCurrentStorageDamage(akTarget, TargetData)
    If Level != CurrentStorageDamage
      SCLSet.SCL_StoredDamageArray[Level].cast(akTarget)
      JMap.setInt(TargetData, "SCLAppliedStorageTier", Level)
    EndIf
  ElseIf getCurrentStorageDamage(akTarget, TargetData) != 0
    SCLSet.SCL_StoredDamageArray[0].cast(akTarget)
    JMap.setInt(TargetData, "SCLAppliedStorageTier", 0)
  EndIf
EndFunction

Int Function getCurrentStorageDamage(Actor akTarget, Int aiTargetData = 0)
  Int TargetData = getData(akTarget, aiTargetData)
  Return JMap.getInt(TargetData, "SCLAppliedStorageTier")
EndFunction

Function updateItemProcess(Actor akTarget, Float afTimePassed, Int aiTargetData = 0)
  {AKA Digest function}
  ;QUESTION: is this function really necessary? or can I just send a single mod event out each update?
  ;It's no longer necessary thanks to individual JFormMaps for each item type
  Int TargetData
  If aiTargetData
    TargetData = aiTargetData
  Else
    TargetData = getTargetData(akTarget)
  EndIf
  Int ItemType = JIntMap.nextKey(SCLSet.JI_ItemTypes)
  While ItemType
    Int JF_ItemList = getContents(akTarget, ItemType, TargetData)
    If !JValue.empty(JF_ItemList)
      Int ProcessEvent = ModEvent.Create("SCLProcessEvent" + ItemType)
      ModEvent.pushForm(ProcessEvent, akTarget)
      ModEvent.pushInt(ProcessEvent, TargetData)
      ModEvent.pushInt(ProcessEvent, JF_ItemList)
      ModEvent.PushFloat(ProcessEvent, afTimePassed)
      ModEvent.send(ProcessEvent)
    EndIf
    ItemType = JIntMap.nextKey(SCLSet.JI_ItemTypes, ItemType)
  EndWhile
  ;Notice("Processing completed for " + nameGet(akTarget))
EndFunction

Int Function clearInvalidContents(Int JF_ContentsMap, Form akBaseObject)
  {Clears out objects without ObjectReference keys
  Searches through all items in an actor's content array, returns the ItemEntry ID
  Also deletes non-ObjectReferences in the map}
  Form SearchRef = JFormMap.nextKey(JF_ContentsMap)
  Int JA_Remove
  While SearchRef
    If !SearchRef as ObjectReference
      If !JA_Remove
        JA_Remove = JArray.object()
      EndIf
      JArray.addForm(JA_Remove, SearchRef)
    EndIf
    SearchRef = JFormMap.nextKey(JF_ContentsMap, SearchRef)
  EndWhile
  JF_eraseKeys(JF_ContentsMap, JA_Remove)
EndFunction

Float Function updateFullness(Actor akTarget, Bool abNoVomit = False, Int aiTargetData = 0)
  {Checks each reported fullness, set "STFullness to it"}
  Int TargetData
  If aiTargetData
    TargetData = aiTargetData
  Else
    TargetData = getTargetData(akTarget)
  EndIf

  Int ItemType = JIntMap.nextKey(SCLSet.JI_ItemTypes)
  Float Total
  While ItemType
    String ContentsKey = getContentsKey(ItemType)
    If ContentsKey
      Total += JMap.getFlt(TargetData, getContentsKey(ItemType))
      ItemType = JIntMap.nextKey(SCLSet.JI_ItemTypes, ItemType)
    EndIf
  EndWhile
  ;Note("Final Fullness = " + Total)
  ;Notice("updateFullness for " + nameGet(akTarget) + " returned " + Total)
  If !abNoVomit
    Float Max = getMax(akTarget)
    If Total > Max && !akTarget.HasSpell(SCLSet.SCL_AllowOverflowAbilityArray[1]) && !SCLSet.GodMode1 && canVomit(akTarget)
      Float Delta = Total - Max
      vomitAmount(akTarget, Delta, True, 30, True, 20)
      Total = updateFullnessEX(akTarget, True, aiTargetData)
      JMap.setInt(TargetData, "SCLAllowOverflowTracking", JMap.getInt(TargetData, "SCLAllowOverflowTracking") + 1)
      addVomitDamage(akTarget)
      quickUpdate(akTarget)
    EndIf
  EndIf
  If Total < 0
    Issue("updateFullness return a total of less than 0. Setting to 0")
    Total = 0
  EndIf
  JMap.setFlt(TargetData, "STFullness", Total)
  If Total > JMap.getFlt(TargetData, "SCLHighestFullness")
    JMap.setFlt(TargetData, "SCLHighestFullness", Total)
  EndIf
  Return Total
EndFunction

Float Function updateFullnessEX(Actor akTarget, Bool abNoVomit = False, Int aiTargetData = 0)
  {Actually goes into each contents list and pulls each DigestValue
  For most updates, this should be integrated into the digest function}
  Int TargetData
  If aiTargetData
    TargetData = aiTargetData
  Else
    TargetData = getTargetData(akTarget)
  EndIf
  Int ItemType = JIntMap.nextKey(SCLSet.JI_ItemTypes)
  Float Total
  While ItemType
    Int JF_ItemList = JMap.getObj(TargetData, "Contents" + ItemType)
    String ContentsKey = getContentsKey(ItemType)
    If ContentsKey
      Float Fullness = getFullness(JF_ItemList)
      If Fullness < 0
        Issue("getFullness for ItemType " + ItemType + " returned less than 0. Setting to 0", 1)
        Fullness = 0
      EndIf
      Total += Fullness
      JMap.setFlt(TargetData, ContentsKey, Fullness)
    EndIf
    ItemType = JIntMap.nextKey(SCLSet.JI_ItemTypes, ItemType)
  EndWhile
  If !abNoVomit
    Float Max = getMax(akTarget)
    If Total > Max && !akTarget.HasSpell(SCLSet.SCL_AllowOverflowAbilityArray[1]) && !SCLSet.GodMode1 && canVomit(akTarget)
      Float Delta = Total - Max
      vomitAmount(akTarget, Delta, True, 30, True, 20)
      Total = updateFullnessEX(akTarget, True, aiTargetData)
      JMap.setInt(TargetData, "SCLAllowOverflowTracking", JMap.getInt(TargetData, "SCLAllowOverflowTracking") + 1)
      addVomitDamage(akTarget)
      quickUpdate(akTarget)

    EndIf
  Endif
  If Total < 0
    Issue("updateFullness return a total of less than 0. Setting to 0")
    Total = 0
  EndIf
  JMap.setFlt(TargetData, "STFullness", Total)
  If Total > JMap.getFlt(TargetData, "SCLHighestFullness")
    JMap.setFlt(TargetData, "SCLHighestFullness", Total)
  EndIf
  Return Total
EndFunction

Bool Function canVomit(Actor akTarget)
  Return !akTarget.HasMagicEffect(SCLSet.SCL_VomitDamageEffect)
  ;Return !akTarget.HasSpell(SCL_VomitDamageSpell)
EndFunction

Function addVomitDamage(Actor akTarget)
  SCLSet.SCL_VomitDamageSpell.cast(akTarget)
  ;/If akTarget.HasSpell(SCL_VomitDamageSpell)
    akTarget.RemoveSpell(SCL_VomitDamageSpell)
    Utility.Wait(0.1)
  EndIf
  akTarget.AddSpell(SCL_VomitDamageSpell, True)/;
EndFunction

String Function getContentsKey(Int aiItemType)
  {Returns where that item type's fullness is stored}
  Return JMap.getStr(JIntMap.getObj(SCLSet.JI_ItemTypes, aiItemType), "ContentsKey")
EndFunction

Float Function updateSingleContents(Actor akTarget, Int aiItemType)
  {Sets the individual content fullnefss
  Call this whenever a content's array is expected to change, IE digestion, or other events.
  Alternatively, use updateFullnessEX to update everything.}
  String ContentsKey = getContentsKey(aiItemType)
  If ContentsKey
    Float Fullness = getFullness(getContents(akTarget, aiItemType))
    Int JM_ItemsEntry = JIntMap.getObj(SCLSet.JI_ItemTypes, aiItemType)
    Notice("updateSingleContents for " + nameGet(akTarget) + " and " + aiItemType + " = " + Fullness)
    JMap.setFlt(getTargetData(akTarget), ContentsKey, Fullness)
    Return Fullness
  EndIf
  Return 0
EndFunction

Float Function getFullness(Int JF_ContentsMap)
  {Sums up the contents of a single contents map}
  If !JValue.empty(JF_ContentsMap)
    Return JValue.evalLuaFlt(JF_ContentsMap, "return jc.accumulateValues(jobject, function(a,b) return a + b end, '.DigestValue')", -1)
  Else
    Return 0
  EndIf
EndFunction

Int Function getEquipSet(Actor akTarget)
  Int i = SCLSet.SCL_EquipmentSetKeywords.GetSize()
  While i
    i -= 1
    If akTarget.WornHasKeyword(SCLSet.SCL_EquipmentSetKeywords.GetAt(i) as Keyword)
      Return i + 1
    EndIf
  EndWhile
  Return -1
EndFunction

;/Armor Function getCurrentEquipment(Actor akTarget)
  Int EquippedSet = getEquipSet(akTarget)
  If EquippedSet == -1
    Return None
  EndIf
  Armor[] Armors = getArmorArray(EquippedSet)
  Int i = Armors.length
  While i
    i -= 1
    If akTarget.IsEquipped(Armors[i])
      Return Armors[i]
    EndIf
  EndWhile
  Return None
EndFunction/;


;Inflation Functions ***********************************************************
Function queueEditBody(Actor akTarget, String asType, Float afValue, String asMethodOverride = "", Int aiEquipSetOverride = 0, String asShortModKey = "SCL.esp", String asFullModKey = "Skyrim Capacity Limited")
  If !akTarget || !asType
    Return
  EndIf
  SCLSet.EditBodyThreadManager.editBodyAsync(akTarget, asType, afValue, asMethodOverride, aiEquipSetOverride, asShortModKey, asFullModKey)

  ;/Int Future = SCLSet.EditBodyThreadManager.editBodyAsync(akTarget, asType, afValue, asMethodOverride, aiEquipSetOverride, asShortModKey, asFullModKey)
  Note("Edit Body queued. Future = " + Future)

  Float ReturnValue = -1
  While ReturnValue != -1
    Utility.Wait(0.1)
    ReturnValue = SCLSet.EditBodyThreadManager.get_result(Future)
  EndWhile
  Note("Response Found!")
  Return ReturnValue/;
EndFunction

Function visualBellyUpdate(Actor akTarget, Float afValue, String asMethodOverride = "", Int aiEquipSetOverride = 0, Int aiTargetData = 0)
  queueEditBody(akTarget, "Belly", afValue, asMethodOverride, aiEquipSetOverride)
EndFunction

;/Float Function visualBellyUpdate(Actor akTarget, Float afValue, String asMethodOverride = "", Int aiEquipSetOverride = 0, Int aiTargetData = 0)
  Int TargetData
  If aiTargetData
    TargetData = aiTargetData
  Else
    TargetData = getTargetData(akTarget)
  EndIf
  Notice("Updating " + nameGet(akTarget) + " visual belly size, initial inflate value = " + afValue)
  Float SizeValue = afValue * SCLSet.BellyMulti * (((akTarget.GetLeveledActorBase().GetWeight() / 100) * SCLSet.BellyHighScale) + 1)
  SizeValue /= akTarget.GetScale()
  SizeValue = clampFlt(SizeValue, SCLSet.BellyMin, SCLSet.BellyMax)
  SizeValue = curveBoneValue(SizeValue)
  Notice("Final inflate value = " + SizeValue)
  String Method
  If asMethodOverride
    Method = asMethodOverride
    JMap.setStr(TargetData, "VBInflateMethod", Method)
  Else
    Method = JMap.getStr(TargetData, "VBInflateMethod")
  EndIf
  If !Method
    Method = SCLSet.InflateMethodArray[SCLSet.BellyInflateMethod]
  EndIf
  Notice("Found inflate method = " + Method)
  If Method == "Disabled"
    removeAllDynEquip(akTarget, "Belly")
    resetAllBoneScaleMethods(akTarget, "NPC Belly", ShortModKey, FullModKey)
    Return 0
  ElseIf Method == "NiOverride"
    removeAllDynEquip(akTarget, "Belly")
    setBoneScaleNiO(akTarget, "NPC Belly", ShortModKey, FullModKey, SizeValue)
  ElseIf(Method == "Sexlab Inflation Framework")
    removeAllDynEquip(akTarget, "Belly")
    setBoneScaleSLIF(akTarget, "NPC Belly", ShortModKey, FullModKey, SizeValue)
  ElseIf Method == "Equipment"
    removeAllDynEquip(akTarget, "Belly")
    Int SizeTier = findEquipSize(SizeValue)
    Armor CurrentEquipment = getCurrentEquipment(akTarget)
    Int Set
    If aiEquipSetOverride > 0
      Set = aiEquipSetOverride
      JMap.setInt(TargetData, "VBEquipSet", Set)
    Else
      Set = JMap.getInt(TargetData, "VBEquipSet")
    EndIf
    Armor NewArmor = getArmor(SizeTier, Set)
    resetAllBoneScaleMethods(akTarget, "NPC Belly", ShortModKey, FullModKey)
    If NewArmor != CurrentEquipment
      akTarget.UnequipItem(CurrentEquipment, False, False)
      akTarget.RemoveItem(CurrentEquipment, 1, False)
      akTarget.AddItem(NewArmor, 1, False)
      aktarget.EquipItem(NewArmor, False, False)
    EndIf
  ElseIf Method == "Dynamic Equipment"  ;Right now, uses slot 48
    Float AltSizeValue = SizeValue / 100
    AltSizeValue *= SCLSet.DynEquipModifier
    Int NewSet
    Int OldSet
    If aiEquipSetOverride > 0
      NewSet = aiEquipSetOverride
      OldSet = JMap.getInt(TargetData, "VBEquipSet")
    Else
      NewSet = JMap.getInt(TargetData, "VBEquipSet")
      OldSet = NewSet
    EndIf
    If NewSet == 0
      NewSet = 1
      OldSet = -1
    EndIf
    Int JM_DynEntry = getDynEquipEntry(NewSet, "Belly")
    checkDynEquip(akTarget, NewSet, OldSet, "Belly")
    JMap.setInt(TargetData, "VBEquipSet", NewSet)
    Int JM_MorphList = JMap.getObj(JM_DynEntry, "MorphMap")
    String MorphName = JMap.nextKey(JM_MorphList)
    Int JA_MorphSet = JArray.object()
    While MorphName
      If AltSizeValue <= 0
        JArray.addFlt(JA_MorphSet, AltSizeValue)
      Else
        Float Threshold = JMap.getFlt(JM_MorphList, MorphName)
        If Threshold == -1
          JArray.addFlt(JA_MorphSet, AltSizeValue)
          AltSizeValue = 0
        ElseIf Threshold > AltSizeValue
          JArray.addFlt(JA_MorphSet, Threshold - AltSizeValue)
          AltSizeValue = 0
        Else
          JArray.addFlt(JA_MorphSet, Threshold)
          AltSizeValue -= Threshold
        EndIf
      EndIf
      MorphName = JMap.nextKey(JM_MorphList, MorphName)
    EndWhile
    Int i
    Int NumMorphs = JArray.count(JA_MorphSet)
    While i < NumMorphs
      NiOverride.SetBodyMorph(akTarget, JMap.getNthKey(JM_MorphList, i), ShortModKey, JArray.getFlt(JA_MorphSet, i))
      i += 1
    EndWhile
    JValue.zeroLifetime(JA_MorphSet)
    resetAllBoneScaleMethods(akTarget, "NPC Belly", ShortModKey, FullModKey)
    Nioverride.UpdateModelWeight(akTarget)
  EndIf
  JMap.setFlt(TargetData, "VisualCurrentBellySize", SizeValue)
  Return SizeValue
EndFunction/;

Int Function getDynEquipEntry(Int aiSet, String asType)
  Int JI_DynMap = JMap.getObj(SCLSet.JM_DynMorphList, asType)
  Return JIntMap.getObj(JI_DynMap, aiSet)
EndFunction

Armor Function getDynEquipSet(Int aiSet, String asType)
  Int JM_Entry = getDynEquipEntry(aiSet, asType)
  Return JMap.getForm(JM_Entry, "DynEquipment") as Armor
EndFunction

Function removeAllDynEquip(Actor akTarget, String asType)
  If akTarget.WornHasKeyword(SCLSet.SCL_DynEquip)
    Int JI_DynMap = JMap.getObj(SCLSet.JM_DynMorphList, asType)
    Int i = JIntMap.nextKey(JI_DynMap)
    While i
      Int JM_Entry = JIntMap.getObj(JI_DynMap, i)
      Armor DynEquip = JMap.getForm(JM_Entry, "DynEquipment") as Armor
      If akTarget.IsEquipped(DynEquip)
        akTarget.UnequipItem(DynEquip, False, True)
        akTarget.RemoveItem(DynEquip, 1, True)
      EndIf
      i = JIntMap.nextKey(JI_DynMap, i)
    EndWhile
  EndIf
  JMap.setInt(getTargetData(akTarget), "VBEquipSet", 0)
EndFunction

Function checkDynEquip(Actor akTarget, Int aiNewSet, Int aiOldSet, String asType)
  If aiNewSet != aiOldSet
    If aiOldSet == -1
      removeallDynEquip(akTarget, asType)
    Else
      If akTarget.WornHasKeyword(SCLSet.SCL_DynEquip)
        Armor WornEquip = getDynEquipSet(aiOldSet, asType)
        If akTarget.IsEquipped(WornEquip)
          akTarget.UnequipItem(WornEquip, false, True)
          akTarget.RemoveItem(WornEquip, 1, True)
        EndIf
      EndIf
    EndIf
    Armor NewEquip = getDynEquipSet(aiNewSet, asType)
    If !akTarget.IsEquipped(NewEquip)
      akTarget.addItem(NewEquip, 1, True)
      akTarget.EquipItem(NewEquip, False, True)
    EndIf
  EndIf
EndFunction

;//Armor[] Function getArmorArray(Int aiSet)
  If aiSet == 0
    Return SCLSet.BEquipmentArray00
  ElseIf aiSet == 1
    Return SCLSet.BEquipmentArray01
  ElseIf aiSet == 2
    Return SCLSet.BEquipmentArray02
  ElseIf aiSet == 3
    Return SCLSet.BEquipmentArray03
  ElseIf aiSet == 4
    Return SCLSet.BEquipmentArray04
  ElseIf aiSet == 5
    Return SCLSet.BEquipmentArray05
  Else
    Issue("Invalid set inputted into getArmorArray Function")
    Return None
  EndIf
EndFunction

Armor Function getArmor(Int aiSet, Int aiSize)
  Armor[] targetArmors = getArmorArray(aiSet)
  Return targetArmors[aiSize]
EndFunction

Float Function curveBoneValue(Float afValue)
  If afValue <= 1
    Return afValue
  EndIf

  Float Curve = SCLSet.BellyCurve
  If Curve == 2
    Return afValue
  EndIf

  Return (Math.sqrt(Math.pow((afValue - 1), Curve)) * (Curve / 2)) + 1
EndFunction

Function setBoneScaleSLIF(Actor akTarget, String asBone, String sShortModKey, String sFullModKey, Float fValue)
  If asBone == "NPC Testicles"
    asBone = "NPC GenitalsScrotum [GenScrot]"
  EndIf

  If asBone == "NPC Breasts"
    setBoneScaleSLIF(akTarget, "NPC L Breast", sShortModKey, sFullModKey, fValue)
    setBoneScaleSLIF(akTarget, "NPC R Breast", sShortModKey, sFullModKey, fValue)
    Return
  EndIf

  String sKey = SLIF_Main.ConvertToKey(asBone)
  SLIF_Main.inflate(akTarget, sFullModKey,  sKey, fValue, oldModName = sShortModKey)
EndFunction

Function setBoneScaleNiO(Actor akTarget, String sBone, String sShortModKey, String sFullModKey, Float fValue)
  {Increases belly size using NiOverride. Thanks darkconsole!
  Recommended to use esp/esm name for sShortModKey, actual mod title for sFullModKey
  Ex: "SCL.esp"
      "Skyrim Capacity Limited"}
  If sBone == "NPC Breasts"
    setBoneScaleNiO(akTarget, "NPC L Breast", sShortModKey, sFullModKey, fValue)
    setBoneScaleNiO(akTarget, "NPC R Breast", sShortModKey, sFullModKey, fValue)
    Return
  EndIf

  If sBone == "NPC Testicles"
    sBone = "NPC GenitalsScrotum [GenScrot]"
  EndIf

  If !NetImmerse.HasNode(akTarget, sBone, False)
    Return
  EndIf
  Bool Gender = akTarget.GetLeveledActorBase().GetSex() as Bool

  String sKey = SLIF_Main.ConvertToKey(sBone)
  If SLIF_Main.HasScale(akTarget, sFullModKey, sKey)
    SLIF_Main.resetActor(akTarget, sFullModKey, sKey)
  EndIf

  If fValue != 1
    NiOverride.AddNodeTransformScale(akTarget, False, Gender, sBone, sShortModKey, fValue)
  Else
    NiOverride.RemoveNodeTransformScale(akTarget, False, Gender, sBone, sShortModKey)
  EndIf
  NiOverride.UpdateNodeTransform(akTarget, False, Gender, "NPC Belly")
EndFunction

Function resetAllBoneScaleMethods(Actor akTarget, String asBone, String asShortModKey, String asFullModKey)
  {Also removes bodymorphs}
  Bool Gender = akTarget.GetLeveledActorBase().GetSex() as Bool
  If NiOverride.HasNodeTransformScale(akTarget, False, Gender, asBone, asShortModKey)
    NiOverride.RemoveNodeTransformScale(akTarget, False, Gender, asBone, asShortModKey)
  EndIf
  String sKey = SLIF_Main.ConvertToKey(asBone)
  If SLIF_Main.HasScale(akTarget, asFullModKey, sKey)
    SLIF_Main.resetActor(akTarget, asFullModKey, sKey)
  EndIf
EndFunction/;

;Perk Functions ****************************************************************
Spell[] Function getAbilityArray(String asPerkID)
  If asPerkID == "SCLRoomForMore"
    Return SCLSet.SCL_RoomForMoreAbilityArray
  ElseIf asPerkID == "SCLStoredLimitUp"
    Return SCLSet.SCL_StoredLimitUpAbilityArray
  ElseIf asPerkID == "SCLHeavyBurden"
    Return SCLSet.SCL_HeavyBurdenAbilityArray
  ElseIf asPerkID == "SCLAllowOverflow"
    Return SCLSet.SCL_AllowOverflowAbilityArray
  ElseIf asPerkID == "SCLEaterRank"
    Return SCLSet.SCL_EaterRankAbilityArray
  Else
    Spell[] ReturnArray
    Int LibList = SCLSet.JA_LibraryList
    Int i = JArray.count(LibList)
    While i && !ReturnArray
      i -= 1
      ReturnArray = (JArray.getForm(LibList, i) as Lib_SC).getAbilityArray(asPerkID)
    EndWhile
    If ReturnArray
      Return ReturnArray
    Else
      Issue("Invalid perk ID inputted into getAbilityArray function.", 1)
      Return None
    EndIf
  EndIf
EndFunction

Spell Function getPerkSpell(String asPerkID, Int aiPerkLevel)
  {Returns the actual spell representing a perk}
  Return getAbilityArray(asPerkID)[aiPerkLevel]
EndFunction

Int Function getPerkEntry(String asPerkID)
  Return JMap.getObj(SCLSet.JM_PerkIDs, asPerkID)
EndFunction

Int Function getCurrentPerkLevel(Actor akTarget, String asPerkID)
  {Returns the highest perk taken by an actor. If they haven't taken the perk, returns 0}
  Spell[] a = getAbilityArray(asPerkID)
  If !a
    Return -1
  EndIf
  Int i = a.length
  While i > 1 ;Dosen't check 0 index (should be left blank)
    i -= 1
    If akTarget.HasSpell(a[i])
      Return i
    EndIf
  EndWhile
  Return 0
EndFunction

Int Function getTotalPerkLevel(Actor akTarget, String asPerkID, Int aiTargetData = 0)
  {Gets the perk value given by all perks and buffs}
  Int TargetData = getData(akTarget, aiTargetData)
  Return JMap.getInt(TargetData, asPerkID)
EndFunction

Bool Function canTakePerk(Actor akTarget, String asPerkID, Bool abOverride = False, Int aiTargetData = 0)
  ;Rewrite this to place limits on the perks
  ;Notice("canTakePerk called for " + nameGet(akTarget) + " for perkID " + asPerkID)
  Int TargetData = getData(akTarget, aiTargetData)
  Int PerkLevel = getCurrentPerkLevel(akTarget, asPerkID)
  If abOverride && PerkLevel < getAbilityArray(asPerkID).Length - 1
    Return True
  ElseIf asPerkID == "SCLRoomForMore"
    Int aiPerkLevel = PerkLevel + 1
    Notice("SCLRoomForMore Level " + aiPerkLevel)
    Int Req
    If aiPerkLevel == 1
      Req = 10
    ElseIf aiPerkLevel == 2
      Req = 25
    ElseIf aiPerkLevel == 3
      Req = 45
    ElseIf aiPerkLevel == 4
      Req = 60
    ElseIf aiPerkLevel == 5
      Req = 90
    ElseIf aiPerkLevel >= 6
      Return False
    EndIf
    ;Notice("SCLRoomForMore Req = " + Req)
    Float DigestFood = JMap.getFlt(TargetData, "STTotalDigestedFood")
    If (DigestFood >= Req || abOverride)
      ;Notice("Returning true")
      Return True
    Else
      ;Notice("Returning false")
      Return False
    EndIf
  ElseIf asPerkID == "SCLStoredLimitUp"
    Int Req
    Int aiPerkLevel = PerkLevel + 1
    If aiPerkLevel == 1
      Req = 25
    ElseIf aiPerkLevel == 2
      Req == 50
    ElseIf aiPerkLevel == 3
      Req = 75
    ElseIf aiPerkLevel == 4
      Req = 115
    ElseIf aiPerkLevel == 5
      Req = 150
    EndIf
    If aiPerkLevel <= 5 && (abOverride || JMap.getFlt(TargetData, "STBase") >= Req)
      Return True
    Else
      Return False
    EndIf
  ElseIf asPerkID == "SCLHeavyBurden"
    Int aiPerkLevel = PerkLevel + 1

    Int MaxWeight = 150 * (PerkLevel + 1)
    Int Level = akTarget.GetLevel()
    If aiPerkLevel <= 5 && (abOverride || (akTarget.HasMagicEffect(SCLSet.SCL_HeavyBurdenReqTrackerEffect) && Level >= MaxWeight / 10))
      Return True
    Else
      Return False
    EndIf
  ElseIf asPerkID == "SCLAllowOverflow"
    If PerkLevel == 0 && (abOverride || JMap.getInt(TargetData, "SCLAllowOverflowTracking") >= 30)
      Return True
    Else
      Return False
    EndIf
  ElseIf asPerkID == "SCLEaterRank"
    Return True
  Else
    Bool CanTake
    Int LibList = SCLSet.JA_LibraryList
    Int i = JArray.count(LibList)
    While i && !CanTake
      i -= 1
      CanTake = (JArray.getForm(LibList, i) as Lib_SC).canTakePerk(akTarget, asPerkID, PerkLevel, abOverride, TargetData)
    EndWhile
    If CanTake
      Return True
    Else
      Issue("Invalid perk ID inputted into canTakePerk function.", 1)
      Return False
    EndIf
  EndIf
  Return False
EndFunction

Function takePerk(Actor akTarget, String asPerkID)
  Spell[] a = getAbilityArray(asPerkID)
  Int i = getCurrentPerkLevel(akTarget, asPerkID)

  If canTakePerk(akTarget, asPerkID, SCLSet.DebugEnable)
    akTarget.AddSpell(a[i + 1], True)
  Else
    Notice("Actor ineligible for perk")
  EndIf
EndFunction

Function takeUpPerks(Actor akTarget, String asPerkID, Int aiPerkLevel)
  {Takes perk level listed as well as all perk levels below it}
  Spell[] a = getAbilityArray(asPerkID)
  Int i
  If aiPerkLevel > a.Length - 1
    aiPerkLevel = a.Length - 1
  EndIf
  While i < aiPerkLevel
    i += 1
    If !akTarget.HasSpell(a[i])
      akTarget.AddSpell(a[i], True)
    EndIf
  EndWhile
EndFunction

String Function getPerkName(String asPerkID, Int aiPerkLevel = 1)
  Return getAbilityArray(asPerkID)[aiPerkLevel].GetName()
EndFunction

Bool Function canTakeAnyPerk(Actor akTarget)
  {Checks if actor can take any perk}
  String asPerkID = JMap.nextKey(SCLSet.JM_PerkIDs)
  While asPerkID
    If canTakePerk(akTarget, asPerkID)
      Return True
    EndIf
    asPerkID = JMap.nextKey(SCLSet.JM_PerkIDs, asPerkID)
  EndWhile
  Return False
EndFunction

String Function getPerkDescription(String asPerkID, Int aiPerkLevel = 0)
  Int JM_PerkEntry = getPerkEntry(asPerkID)
  Int JA_Desc = JMap.getObj(JM_PerkEntry, "PerkDescriptions")
  Return JArray.getStr(JA_Desc, aiPerkLevel)
EndFunction

String Function getPerkRequirements(String asPerkID, Int aiPerkLevel = 0)
  Int JM_PerkEntry = getPerkEntry(asPerkID)
  Int JA_Requirements = JMap.getObj(JM_PerkEntry, "PerkRequirements")
  Return JArray.getStr(JA_Requirements, aiPerkLevel)
EndFunction

;Vomit Functions ***************************************************************
Function vomitAll(Actor akTarget, Bool ReturnFood = False, Bool RemoveEverything = False)
  Notice("vomitAll beginning for " + nameGet(akTarget))
  ObjectReference VomitContainer = vomitPerform(akTarget, False)

  ;Remove all digesting items
  Int JF_DigestContents = getContents(akTarget, 1)
  Form ItemKey = JFormMap.nextKey(JF_DigestContents)
  While ItemKey
    If ItemKey as Actor ;Always return actors
      extractActor(akTarget, ItemKey as Actor, 1, VomitContainer)
    ElseIf ItemKey as ObjectReference && ReturnFood
      If ItemKey as SCLBundle ;Do we need to delete the SCL Bundle? or can we just move it into the container and erase it after it adds its contents?
        ;VomitContainer.AddItem(ItemKey as SCLBundle, 1, False)
        VomitContainer.AddItem((ItemKey as SCLBundle).ItemForm, (ItemKey as SCLBundle).NumItems, False)
        (ItemKey as ObjectReference).Delete()
      Else
        VomitContainer.AddItem(ItemKey as ObjectReference, 1, False)
      EndIf
    ;Else ;Form found as key
    EndIf
    ItemKey = JFormMap.nextKey(JF_DigestContents, ItemKey)
  EndWhile
  JValue.clear(JF_DigestContents)


  ;Remove stored items
  Int JF_StoredContents = getContents(akTarget, 2)
  ItemKey = JFormMap.nextKey(JF_StoredContents)
  While ItemKey
    If ItemKey as Actor
      extractActor(akTarget, ItemKey as Actor, 2, VomitContainer)
    ElseIf ItemKey as ObjectReference
      If ItemKey as SCLBundle
        ;VomitContainer.AddItem(ItemKey as SCLBundle, 1, False)
        VomitContainer.AddItem((ItemKey as SCLBundle).ItemForm, (ItemKey as SCLBundle).NumItems, False)
        (ItemKey as ObjectReference).Delete()
      Else
        VomitContainer.AddItem(ItemKey as ObjectReference, 1, False)
      EndIf
    EndIf
    ItemKey = JFormMap.nextKey(JF_StoredContents, ItemKey)
  EndWhile
  JValue.clear(JF_StoredContents)

  If RemoveEverything
    Int i = JIntMap.nextKey(SCLSet.JI_ItemTypes)
    While i
      Int JM_FoodTypes = JIntMap.getObj(SCLSet.JI_ItemTypes, i)
      If JMap.getInt(JM_FoodTypes, "STisVomitType") == 1
        Int JF_ContentsMap = getContents(akTarget, i)
        ItemKey = JFormMap.nextKey(JF_ContentsMap)
        While ItemKey
          If ItemKey as Actor
            extractActor(akTarget, ItemKey as Actor, i, VomitContainer)
          ElseIf ItemKey as ObjectReference
            If ItemKey as SCLBundle
              ;VomitContainer.AddItem(ItemKey as SCLBundle, 1, False)
              VomitContainer.AddItem((ItemKey as SCLBundle).ItemForm, (ItemKey as SCLBundle).NumItems, False)
              (ItemKey as ObjectReference).Delete()
            Else
              VomitContainer.AddItem(ItemKey as ObjectReference, 1, False)
            EndIf
          EndIf
          ItemKey = JFormMap.nextKey(JF_ContentsMap, ItemKey)
        EndWhile
        JFormMap.clear(JF_ContentsMap)
      EndIf
      i = JIntMap.nextKey(SCLSet.JI_ItemTypes, i)
    EndWhile
  EndIf
  sendVomitEvent(akTarget, 1, False)
  Notice("vomitAll completed for " + nameGet(aktarget))
EndFunction

Function vomitAmount(Actor akTarget, Float afRemoveAmount, Bool abRemoveStored = False, Int aiStoredRemoveChance = 0, Bool abRemoveOtherItems = False, Int aiOtherRemoveChance = 0)
  {Might not remove exactly the right amount
  Stored items removed will not count towards this}
  Notice("vomitAmount beginning for " + nameGet(akTarget))
  ObjectReference VomitContainer = vomitPerform(akTarget, False)

  ;Remove part of afRemoveAmount from each entry
  Int JF_DigestContents = getContents(akTarget, 1)
  Int JA_Remove = JArray.object()
  Int NumOfItems = JFormMap.count(JF_DigestContents)
  Float IndvRemoveAmount = afRemoveAmount / NumOfItems
  Float AmountRemoved
  Form ItemKey = JFormMap.nextKey(JF_DigestContents)
  While AmountRemoved < afRemoveAmount
    If !ItemKey ;If we reach the end, start back at the beginning
      ItemKey = JFormMap.nextKey(JF_DigestContents)
    EndIf
    If ItemKey as ObjectReference
      Int JM_ItemEntry = JFormMap.getObj(JF_DigestContents, ItemKey)
      If ItemKey as SCLBundle
        Float RemoveAmount = IndvRemoveAmount
        Bool Done ;If we finish off the item
        Float Indv = JMap.getFlt(JM_ItemEntry, "IndvDVal")
        Float Active = JMap.getFlt(JM_ItemEntry, "ActiveDVal")
        Int ItemNum = (ItemKey as SCLBundle).NumItems
        While RemoveAmount > 0 && !Done
          If Active > RemoveAmount ; Remove amount less that Active, ending loop
            Active -= RemoveAmount
            AmountRemoved += RemoveAmount
            RemoveAmount = 0
            JMap.setFlt(JM_ItemEntry, "ActiveDVal", Active)
            (ItemKey as SCLBundle).NumItems = ItemNum
            Float DValue = Active + (Indv * (ItemNum - 1))
            JMap.setFlt(JM_ItemEntry, "DigestValue", DValue)
          Else
            RemoveAmount -= Active
            If ItemNum > 1
              ItemNum -= 1
              Active = Indv
            Else
              Done = True
              AmountRemoved += Active
              JArray.addForm(JA_Remove, ItemKey)
            EndIf
            Active = 0
          EndIf
        EndWhile
      Else
        Float Active = JMap.getFlt(JM_ItemEntry, "ActiveDVal")
        If Active > IndvRemoveAmount
          Active -= IndvRemoveAmount
          AmountRemoved += IndvRemoveAmount
          JMap.setFlt(JM_ItemEntry, "DigestValue", Active)
          JMap.setFlt(JM_ItemEntry, "ActiveDVal", Active)
        Else
          AmountRemoved += Active ;Only add what was taken, not what was supposed to be taken
          JArray.addForm(JA_Remove, ItemKey)
        EndIf
      EndIf
      ItemKey = JFormMap.nextKey(JF_DigestContents, ItemKey)
    EndIf
  EndWhile
  JF_eraseKeys(JF_DigestContents, JA_Remove)
  JA_Remove = JValue.zeroLifetime(JA_Remove)

  ;Randomly remove stored items
  If abRemoveStored && aiStoredRemoveChance != 0
    JA_Remove = JArray.object()
    Int JF_StoredContents = getContents(akTarget, 2)
    ItemKey = JFormMap.nextKey(JF_StoredContents)
    While ItemKey
      If ItemKey as ObjectReference
        Int Chance = Utility.RandomInt()
        If Chance <= aiStoredRemoveChance
          If ItemKey as Actor
            extractActor(akTarget, ItemKey as Actor, 2, VomitContainer)
          ElseIf ItemKey as SCLBundle
            ;VomitContainer.AddItem(ItemKey as SCLBundle, 1, False)
            VomitContainer.AddItem((ItemKey as SCLBundle).ItemForm, (ItemKey as SCLBundle).NumItems, False)
            (ItemKey as ObjectReference).Delete()
          Else
            VomitContainer.AddItem(ItemKey as ObjectReference, 1, False)
          EndIf
          JArray.addForm(JA_Remove, ItemKey)
        EndIf
      EndIf
      ItemKey = JFormMap.nextKey(JF_StoredContents, ItemKey)
    EndWhile
    JF_eraseKeys(JF_StoredContents, JA_Remove)
  EndIf

  ;Randomly remove other items
  If abRemoveOtherItems && aiOtherRemoveChance != 0
    JA_Remove = JArray.object()
    Int i = JIntMap.nextKey(SCLSet.JI_ItemTypes)
    While i
      Int JM_FoodTypes = JIntMap.getObj(SCLSet.JI_ItemTypes, i)
      If JMap.getInt(JM_FoodTypes, "STisVomitType") == 1
        Int JF_ContentsMap = getContents(akTarget, i)
        ItemKey = JFormMap.nextKey(JF_ContentsMap)
        While ItemKey
          If ItemKey as ObjectReference
            Int Chance = Utility.RandomInt()
            If Chance <= aiOtherRemoveChance
              If ItemKey as Actor
                extractActor(akTarget, ItemKey as Actor, i, VomitContainer)
              ElseIf ItemKey as SCLBundle
                ;VomitContainer.AddItem(ItemKey as SCLBundle, 1, False)
                VomitContainer.AddItem((ItemKey as SCLBundle).ItemForm, (ItemKey as SCLBundle).NumItems, False)
                (ItemKey as ObjectReference).Delete()
              Else
                VomitContainer.AddItem(ItemKey as ObjectReference, 1, False)
              EndIf
              JArray.addForm(JA_Remove, ItemKey)
            EndIf
          EndIf
          ItemKey = JFormMap.nextKey(JF_ContentsMap, ItemKey)
        EndWhile
        JF_eraseKeys(JF_ContentsMap, JA_Remove)
      EndIf
      i = JIntMap.nextKey(SCLSet.JI_ItemTypes, i)
    EndWhile
  EndIf
  sendVomitEvent(akTarget, 2, False)
  Notice("vomitAmount completed for " + nameGet(aktarget))
EndFunction

Function vomitSpecificItem(Actor akTarget, Int aiItemType, ObjectReference akReference = None, Form akBaseObject = None, Int aiItemCount = 1, Bool abDestroyDigestItems = True)
  Notice("vomitSpecificItem beginning for " + nameGet(akTarget))
  If !akReference && !akBaseObject
    Return
  EndIf
  Int JM_FoodTypes = JIntMap.getObj(SCLSet.JI_ItemTypes, aiItemType)  ;Check and see if this item type can even be vomited
  If JMap.getInt(JM_FoodTypes, "STisVomitType") == 1
    Int JF_ContentsMap = getContents(akTarget, aiItemType)
    ObjectReference VomitContainer = vomitPerform(akTarget, False)
    If akReference
      If akReference as Actor
        extractActor(akTarget, akReference as Actor, aiItemType, VomitContainer)
      ElseIf akReference as SCLBundle
        If !abDestroyDigestItems || aiItemType != 1
          VomitContainer.addItem((akReference as SCLBundle).ItemForm, (akReference as SCLBundle).NumItems, False)
        EndIf
        akReference.Delete()
      Else
        If !abDestroyDigestItems || aiItemType != 1
          VomitContainer.AddItem(akReference as ObjectReference, 1, False)
        EndIf
        akReference.Delete()
      EndIf
      sendVomitEvent(akTarget, 3, False, akReference)
      JFormMap.removeKey(JF_ContentsMap, akReference)
    Else
      SCLBundle Bundle = findFormBundle(JF_ContentsMap, akBaseObject)
      If Bundle
        Bool bEmpty = False
        Int AddItems = Bundle.NumItems
        Bundle.NumItems -= aiItemCount
        If Bundle.NumItems > 0
          AddItems = aiItemCount
          bEmpty = True
        EndIf
        If !abDestroyDigestItems || aiItemType != 1
          VomitContainer.addItem(Bundle.ItemForm, AddItems, False)
        EndIf
        If bEmpty
          JFormMap.removeKey(JF_ContentsMap, Bundle)
          Bundle.Delete()
        Else
          Int JM_ItemEntry = JFormMap.getObj(JF_ContentsMap, Bundle)
          JMap.setFlt(JM_ItemEntry, "DigestValue", JMap.getFlt(JM_ItemEntry, "ActiveDVal") + (JMap.getFlt(JM_ItemEntry, "IndvDVal") * Bundle.NumItems))
        EndIf
        sendVomitEvent(akTarget, 3, False, Bundle)
      EndIf
    EndIf
  Else
    Issue("Invalid item type inputted into vomitSpecificItem: Not on vomit item list")
  EndIf
EndFunction

ObjectReference Function vomitPerform(Actor akTarget, Bool bLeveledRemains)
  {Just plays the vomit animation, optionally puts down a vomit pile with leveled items}
  If akTarget == PlayerRef
    Game.ForceThirdPerson()
    Game.DisablePlayerControls()
  EndIf
  Debug.SendAnimationEvent(akTarget, "shoutStart")
  Utility.Wait(1)
  Debug.SendAnimationEvent(akTarget, "shoutStop")
  If akTarget == PlayerRef
    Game.EnablePlayerControls()
  EndIf
  Return placeVomit(akTarget, bLeveledRemains)
EndFunction

Function sendVomitEvent(Actor akTarget, Int aiVomitType, Bool bLeveledRemains, Form akSpecificItem = None)
  Int E = ModEvent.Create("SCLVomitEvent")
  ModEvent.PushForm(E, akTarget)
  ModEvent.PushInt(E, aiVomitType)
  ModEvent.PushBool(E, bLeveledRemains)
  ModEvent.PushForm(E, akSpecificItem)
  ModEvent.Send(E)
EndFunction

Function removeTrackingSpells(Actor akTarget)
  {Will REMOVE spells listed in TrackingSpellList}
  Int i = SCLSet.TrackingSpellList.GetSize()
  While i
    i -= 1
    Spell CurrentSpell = SCLSet.TrackingSpellList.GetAt(i) as Spell
    If CurrentSpell
      akTarget.RemoveSpell(CurrentSpell)
    EndIf
  EndWhile
EndFunction

Function dispellTrackingSpells(Actor akTarget)
  {Will cast DISPEL spells listed in TrackingDispelList}
  Int i = SCLSet.TrackingDispelList.GetSize()
  While i
    i -= 1
    Spell CurrentSpell = SCLSet.TrackingDispelList.GetAt(i) as Spell
    If CurrentSpell
      CurrentSpell.Cast(akTarget)
    EndIf
  EndWhile
EndFunction

Function clearTrackingData(Actor akTarget)
  Int TargetData = getTargetData(akTarget)
  JMap.clear(JMap.getObj(TargetData, "SCLTrackingData"))
EndFunction

Function extractActor(Actor akSource, Actor akTarget, Int aiItemType, ObjectReference akPosition)
  Notice("Extracting " + nameGet(akTarget) + " to " + nameGet(akPosition))
  ;akTarget.DisableNoWait(False)
  akTarget.MoveTo(akPosition, 64.0 * Math.Sin(akPosition.GetAngleZ()), 64.0 *Math.Cos(akPosition.GetAngleZ()), (akPosition.GetHeight() + 20), False)
  clearTrackingData(akTarget)
  dispellTrackingSpells(akTarget)
  removeTrackingSpells(akTarget)
  ;akPosition.PushActorAway(akTarget, 0)
  sendActorRemoveEvent(akSource, akTarget, aiItemType)
  ;aktarget.EnableNoWait(False)
  Utility.Wait(1)
EndFunction

Function sendActorRemoveEvent(Actor akSource, Actor akActor, Int aiItemType)
  Int E = ModEvent.Create("SCLActorRemove")
  ModEvent.PushForm(E, akSource)
  ModEvent.PushForm(E, akActor)
  ModEvent.PushInt(E, aiItemType)
  ModEvent.Send(E)
EndFunction

ObjectReference Function placeVomit(ObjectReference akPosition, Bool abLeveled = False)
  ObjectReference Vomit
  If !abLeveled
    Vomit = akPosition.PlaceAtMe(SCLSet.SCL_VomitBase)
  Else
    Vomit = akPosition.PlaceAtMe(SCLSet.SCL_VomitLeveledBase)
  EndIf
  Vomit.MoveTo(akPosition, 64 * Math.Sin(akPosition.GetAngleZ()), 64 * Math.Cos(akPosition.GetAngleZ()), 0, False)
  Vomit.SetAngle(0, 0, 0)
  addToObjectTrashList(Vomit, 5)
  Return Vomit
EndFunction

;******************************************************************************
;AutoEat Functions
;*******************************************************************************
Float Function actorEat(Actor akTarget, Int aiType = 0, Float afDelay = 0.0, Bool abDisplayAnim = False)
  If !akTarget
    Return 0
  EndIf
  Int Future = SCLSet.ActorEatThreadManager.actorEatAsync(akTarget, aiType, afDelay, abDisplayAnim)
  Return SCLSet.ActorEatThreadManager.get_result(Future)
EndFunction

Int Function getGlutValue(Actor akTarget, Int aiTargetData = 0)
  Int TargetData = getData(akTarget, aiTargetData)
  Return JMap.getInt(TargetData, "SCLGluttony")
EndFunction

Int Function getInsobValue(Actor akTarget, Int aiTargetData = 0)
  Int TargetData = getData(akTarget, aiTargetData)
  Return JMap.getInt(TargetData, "SCLInsobriety")
EndFunction

Float Function genMealValue(Int aiSeverity = -1, Actor akTarget = None, Int aiType, Int aiTargetData = 0)
  {Generates meal value based on gluttony value and ai type}
  Int Severity
  If aiSeverity > 0
    Severity = aiSeverity
  ElseIf akTarget
    Severity = getGlutValue(akTarget, aiTargetData)
  Else
    Return 0
  EndIf

  If Severity <= 0
    Return 0
  ElseIf aiType > 0
    Return Math.pow(0.05 * Severity, 1.8) * Math.Pow(1.1 * aiType, 2)
  ElseIf aiType < 0
    aiType = Math.floor(Math.abs(aiType))
    Return Math.pow(0.05 * Severity, 1.8) * Math.Pow(1.1 * aiType, 2)
  EndIf
EndFunction

;/Gluttony a rising value starting at 0 (no desire to eat) and escalating upwards
Meal values should increase exponentially
Base value should result in light snacks == 0.3, meals == 1, Full meals == 2
Time should decrease as Gluttony rises/;
Float Function getGlutMin(Int aiGlutValue = -1, Actor akTarget = None, Int aiTargetData = 0)
  Int Gluttony
  If aiGlutValue > 0
    Gluttony = aiGlutValue
  ElseIf akTarget
    Gluttony = getGlutValue(akTarget, aiTargetData)
  Else
    Return 0
  EndIf
  If Gluttony > 50
    Return Math.pow(Gluttony - 50, 1.2)
  Else
    Return -1
  EndIf
EndFunction

Float Function getGlutTime(Int aiGlutValue = -1, Actor akTarget = None, Int aiTargetData = 0)
  Int Gluttony
  If aiGlutValue > 0
    Gluttony = aiGlutValue
  ElseIf akTarget
    Gluttony = getGlutValue(akTarget, aiTargetData)
  Else
    Return 0
  EndIf
  If Gluttony <= 0
    Return -1
  Else
    Return Math.pow(0.9, Gluttony/3) * 1000
  EndIf
EndFunction

Float Function getPriceFactor(Actor akTarget)
  Float Speech = akTarget.GetActorValue("Speechcraft")
  Float BaseFactor = (3.3 * (100 - Speech) + 2 * Speech) / 100
  Float Haggle
  If akTarget.HasPerk(SCLSet.Haggling80)
    Haggle = 0.77
  ElseIf akTarget.HasPerk(SCLSet.Haggling60)
    Haggle = 0.8
  ElseIf akTarget.HasPerk(SCLSet.Haggling40)
    Haggle = 0.83
  ElseIf akTarget.HasPerk(SCLSet.Haggling20)
    Haggle = 0.87
  ElseIf akTarget.HasPerk(SCLSet.Haggling00)
    Haggle = 0.91
  Else
    Haggle = 1
  EndIf
  Float Allure = 1
  If akTarget.HasPerk(SCLSet.Allure)
    Bool AllureChance = Utility.RandomInt(0, 1)
    If AllureChance
      Allure = 0.91
    EndIf
  EndIf

  Float BuyModifier = Haggle * Allure
  Return BuyModifier / BaseFactor
EndFunction
;Menu Functions ***************************************************************
Function setWMItems(Int aiPosition, String asLabel, String asText, Bool abEnabled = True, Int aiColorOverride = -1)
  {Adds an item to the UI extensions wheel menu. Look at dcc_sgo_QuestController for example}
  UIExtensions.SetMenuPropertyIndexString("UIWheelMenu", "optionLabelText", aiPosition, asLabel)
  UIExtensions.SetMenuPropertyIndexString("UIWheelMenu", "optionText", aiPosition, asText)
  UIExtensions.SetMenuPropertyIndexBool("UIWheelMenu", "optionEnabled", aiPosition, abEnabled)

  If aiColorOverride != -1
    UIExtensions.SetMenuPropertyIndexInt("UIWheelMenu", "optionTextColor", aiPosition, aiColorOverride)
  ElseIf !abEnabled
    UIExtensions.SetMenuPropertyIndexInt("UIWheelMenu", "optionTextColor", aiPosition, 0x555555)
  EndIf
EndFunction

Function openActorMainMenu(Actor akTarget, Int aiMenuNumber, Int aiMode)
  sendActorMainMenuOpenEvent(akTarget, aiMenuNumber, aiMode)
  Debug.Notification(getActorMainMenuName(aiMenuNumber))
EndFunction

Function openNextActorMainMenu(Actor akTarget, Int aiMenuNumber)
  {Finds next menu registered within 15 spaces, sends ModEvent with that menu
  Put in your mod's menu number
  Always goes for the default mode (0)
  Set abDefaultToSCL to false to have it fail if no menus found
  Defaults to Menu Number 0}
  Int NextMenuID = getNextActorMainMenu(aiMenuNumber)
  sendActorMainMenuOpenEvent(akTarget, NextMenuID)
  Debug.Notification(getActorMainMenuName(NextMenuID))
EndFunction

String Function getActorMainMenuName(Int aiMenuNumber)
  Return JMap.getStr(JIntMap.getObj(SCLSet.JI_WM_Actor, aiMenuNumber), "MenuName")
EndFunction

Function openPreviousActorMainMenu(Actor akTarget, Int aiMenuNumber)
  {Finds next menu registered within 15 spaces, sends ModEvent with that menu
  Put in your mod's menu number
  Always goes for the default mode (0)
  Set abDefaultToSCL to false to have it fail if no menus found
  Defaults to Menu Number 0}
  Int NextMenuID = getPreviousActorMainMenu(aiMenuNumber)
  sendActorMainMenuOpenEvent(akTarget, NextMenuID)
  Debug.Notification(getActorMainMenuName(NextMenuID))
EndFunction


Int Function getNextActorMainMenu(Int aiMenuNumber)
  {Finds next menu registered within 15 spaces. If not found, returns 0 (SCLMainMenu)}
  Int Limit = aiMenuNumber + 15
  Int MenuNumber = 0
  Bool Found = False
  While !Found && aiMenuNumber < Limit
    aiMenuNumber += 1
    Int JM_MenuEntry = JIntMap.getObj(SCLSet.JI_WM_Actor, aiMenuNumber)
    If JMap.getInt(JM_MenuEntry, "MenuOn")
      MenuNumber = aiMenuNumber
      Found = True
    Endif
  EndWhile
  If Found
    ;Notice("getNextActorMainMenu returned menu " + MenuNumber)
    Return MenuNumber
  Else
    ;Notice("getNextActorMainMenu failed to return a menu")
    Return 0
  EndIf
EndFunction

Function releaseTempContainers()
  JA_Description = JValue.release(JA_Description)
  JA_OptionList1 = JValue.release(JA_OptionList1)
  JA_OptionList2 = JValue.release(JA_OptionList2)
  JA_OptionList3 = JValue.release(JA_OptionList3)
EndFunction

Int Function getPreviousActorMainMenu(Int aiMenuNumber)
  {Finds previous menu registered within 15 spaces, returns its number
  Put in your mod's menu number}
  Int Limit = aiMenuNumber - 15
  Int MenuNumber = 0
  Bool Found = False
  While !Found && aiMenuNumber > Limit
    aiMenuNumber -= 1
    Int JM_MenuEntry = JIntMap.getObj(SCLSet.JI_WM_Actor, aiMenuNumber)
    If JMap.getInt(JM_MenuEntry, "MenuOn")
      MenuNumber = aiMenuNumber
      Found = True
    EndIf
  EndWhile
  If Found
    ;Notice("getPreviousActorMainMenu returned menu " + MenuNumber)
    Return MenuNumber
  Else
    ;Notice("getPreviousActorMainMenu failed to return a menu")
    Return 0
  EndIf
EndFunction

Function sendActorMainMenuOpenEvent(Actor akTarget, Int iMenuNumber, Int aiMode = 0)
  {Sends ModEvent to open a menu. Use aiMode to specify a particular mode, if it has one}
  Int MenuEvent = ModEvent.Create("SCLActorMainMenuOpen" + iMenuNumber)
  ModEvent.PushForm(MenuEvent, akTarget)
  ModEvent.PushInt(MenuEvent, aiMode)
  ModEvent.Send(MenuEvent)
EndFunction

;Actor Main Menu ***************************************************************
Function showActorMainMenu(Actor akTarget = None, Int aiMode = 0)
  If akTarget == None
    akTarget = Game.GetCurrentCrosshairRef() as Actor
  EndIf

  If akTarget == None
    akTarget == PlayerRef
  EndIf

  Notice("Showing Actor Main Menu for " + nameGet(akTarget))
  If !buildActorMainMenu(akTarget, aiMode)
    Return
  EndIf
  SCLibrary.getSCLModConfig().SelectedActor = akTarget
  Int Option = UIExtensions.OpenMenu("UIWheelMenu", akTarget)
  handleActorMainMenu(akTarget, Option, aiMode)
EndFunction

Bool Function buildActorMainMenu(Actor akTarget, Int aiMode = 0)
  UIWheelMenu WM_ActorMenu = UIExtensions.GetMenu("UIWheelMenu", True) as UIWheelMenu
  String ActorName = nameGet(akTarget)
  Int TargetData = getTargetData(akTarget, True)
  Bool AllowCommandFunctions = False
  If akTarget == PlayerRef || akTarget.IsPlayerTeammate() || SCLSet.DebugEnable
    AllowCommandFunctions = True
  EndIf
  setWMItems(0, "Show Stats", "View Stomach Statistics", True)
  String PreviousMenuName = getActorMainMenuName(getPreviousActorMainMenu(0))
  If PreviousMenuName
    setWMItems(1, PreviousMenuName, "Display previous menu", True)
  EndIf
  ;setWMItems(2, "Effects List", "Show stomach effects", True)
  setWMItems(3, "Force Vomit", "Force actor to vomit all items", AllowCommandFunctions)
  setWMItems(4, "Perks Menu", "Show and take perks", True)
  String NextMenuName = getActorMainMenuName(getNextActorMainMenu(0))
  If NextMenuName
    setWMItems(5, NextMenuName, "Display Next Menu", True)
  EndIf
  If AllowCommandFunctions
    setWMItems(6, "Stomach Contents", "View contents and vomit specific items", True)
  Else
    setWMItems(6, "Stomach Contents", "Show all items in stomach", True)
  EndIf
  setWMItems(7, "Add Items", "Transfer items to stomach", AllowCommandFunctions)
  Return True
EndFunction

Function handleActorMainMenu(Actor akTarget, Int aiOption, Int aiMode)
  If aiOption == 0
    showActorStatsMenu(akTarget)
  ElseIf aiOption == 1
    openPreviousActorMainMenu(akTarget, 0)
  ElseIf aiOption == 2
    ;showActorEffectsMenu(akTarget) ;Is this necessary with all effects being added through creation kit?
  ElseIf aiOption == 3
    vomitAll(akTarget, False, False)
    quickUpdate(akTarget, True)
  ElseIf aiOption == 4
    showPerksList(akTarget)
  ElseIf aiOption == 5
    openNextActorMainMenu(akTarget, 0)
  ElseIf aiOption == 6
    If akTarget == PlayerRef || akTarget.IsPlayerTeammate() || SCLSet.DebugEnable
      showContentsList(akTarget, 1)
    Else
      showContentsList(akTarget)
    EndIf
  ElseIf aiOption == 7
    openTransferMenu(akTarget)
  EndIf
EndFunction
;Transfer Menu *****************************************************************
Function openTransferMenu(Actor akTarget)
  {Places a container at the player's feet that, when items are added, are added to the target's stomach
  Will be deleted after 5 hours}
  Notice("Opening transfer menu for " + nameGet(akTarget))
  ;SCLTransferObject ST_TransferRef = PlayerRef.PlaceAtMe(SCLSet.SCL_TransferBase) as SCLTransferObject
  SCLTransferObject ST_TransferRef = SCLSet.SCL_TransferChest as SCLTransferObject
  ST_TransferRef.TransferTarget = akTarget
  ST_TransferRef.Destination = "Stomach"  ;Sets properties on the transfer object script before its opened
  ;addToObjectTrashList(ST_TransferRef, 5)
  quickUpdate(akTarget)
  ST_TransferRef.Activate(PlayerRef)
EndFunction

;Stats Menu ********************************************************************
Function showActorStatsMenu(Actor akTarget = None, Int aiMode = 0)
  If !akTarget
    akTarget = Game.GetCurrentCrosshairRef() as Actor
  EndIf

  If !akTarget
    akTarget == PlayerRef
  EndIf

  If !buildActorStatsMenu(akTarget)
    Debug.Notification("Invalid actor")
    sendActorMainMenuOpenEvent(akTarget, 0)
    Return
  EndIf

  UIExtensions.OpenMenu("UIListMenu", akTarget)
  Int Option = UIExtensions.GetMenuResultInt("UIListMenu")
  While Option != 0 && Option < JArray.count(JA_Description)
    Debug.Notification(JArray.getStr(JA_Description, Option))
    UIExtensions.OpenMenu("UIListMenu", akTarget)
    Option = UIExtensions.GetMenuResultInt("UIListMenu")
  EndWhile

  sendActorMainMenuOpenEvent(akTarget, 0)
EndFunction

Bool Function buildActorStatsMenu(Actor akTarget)
  UIListMenu LM_ST_Stats = UIExtensions.GetMenu("UIListMenu", True) as UIListMenu
  Int TargetData = getTargetData(akTarget)
  If !TargetData
    Notice("Actor does not have data! Cannot build stats menu!")
    Return False
  EndIf
  String TargetName = nameGet(akTarget)
  releaseTempContainers()
  JA_Description = JValue.retain(JArray.object())

  LM_ST_Stats.AddEntryItem("<< Return")
  JArray.addStr(JA_Description, "")

  LM_ST_Stats.AddEntryItem("Base Capacity = " + roundFlt(JMap.getFlt(TargetData, "STBase"), 2))
  JArray.addStr(JA_Description, "Amount that " + TargetName + " can hold without strain.")

  LM_ST_Stats.AddEntryItem("AdjBase Capacity = " + roundFlt(getAdjBase(akTarget), 2))
  JArray.addStr(JA_Description, "Amount that " + TargetName + " can hold without strain, adjusted based on their size.")

  LM_ST_Stats.AddEntryItem("Current Fullness = " + roundFlt(JMap.getFlt(TargetData, "STFullness"), 2))
  JArray.addStr(JA_Description, "Total weight of items in " + TargetName + "'s stomach.")

  LM_ST_Stats.AddEntryItem("Stomach Stretch = " + roundFlt(JMap.getFlt(TargetData, "STStretch"), 1))
  JArray.addStr(JA_Description, "Amount that " + TargetName + "'s stomach can stretch beyond its usual size.")

  LM_ST_Stats.AddEntryItem("Max Capacity = " + roundFlt(getMax(akTarget), 2))
  JArray.addStr(JA_Description, "Maximum amount " + TargetName + " can hold before being incapacitated. AdjBase x Stomach Stretch.")

  LM_ST_Stats.AddEntryItem("Digestion Rate = " + roundFlt(JMap.getFlt(TargetData, "STDigestionRate"), 2))
  JArray.addStr(JA_Description, "Units of food digested per in-game hour.")

  Int LibList = SCLSet.JA_LibraryList
  Int i = JArray.count(LibList)
  While i
    i -= 1
    Int JA_Entry = (JArray.getForm(LibList, i) as Lib_SC).addActorStatsMenuOptions(akTarget, JA_Description, JA_OptionList1, JA_OptionList2, JA_OptionList3, TargetData)
    Int j = JArray.count(JA_Entry)
    While j
      j -= 1
      LM_ST_Stats.AddEntryItem(JArray.getStr(JA_Entry, j))
    EndWhile
  EndWhile
  ;Int Rank = getCurrentPerkLevel(akTarget, "SCLEaterRank")
  ;LM_ST_Stats.AddEntryItem("Eater Rank = " + Rank)
  ;JArray.addStr(JA_Description, "How much of a gourmand that " + TargetName + " is")
  Return True
EndFunction

;Contents Menu *****************************************************************
Function showContentsList(Actor akTarget, Int aiMode = 0)
  If akTarget == None
    akTarget == Game.GetCurrentCrosshairRef() as Actor
  EndIf

  If akTarget == None
    akTarget == PlayerRef
  EndIf


  If !buildContentsList(akTarget)
    Debug.Notification("Actor's stomach is empty.")
    sendActorMainMenuOpenEvent(akTarget, 0)
    Return
  EndIf
  If aiMode == 1
    Debug.Notification("Choose item to look at.")
  EndIf
  UIExtensions.OpenMenu("UIListMenu", akTarget)
  Int Option = UIExtensions.GetMenuResultInt("UIListMenu")
  While Option != 0 && Option < JArray.count(JA_Description)
    Notice("Option " + Option + " chosen")
    If aiMode == 1
      Int Choice = SCLSet.SCL_ContentsMenuMessage.Show()
      If Choice == 0  ;Display info
        Debug.Notification(JArray.getStr(JA_Description, Option))
        UIExtensions.OpenMenu("UIListMenu", akTarget)
        Option = UIExtensions.GetMenuResultInt("UIListMenu")
      ElseIf Choice == 1 ;Vomit item
        Notice("Vomiting " + nameGet(JArray.getForm(JA_OptionList1, Option) as ObjectReference) + ", index " + Option + ", from " + nameGet(akTarget))
        vomitSpecificItem(akTarget, JArray.getInt(JA_OptionList2, Option), JArray.getForm(JA_OptionList1, Option) as ObjectReference)
        quickUpdate(akTarget, True)
        Return
      ElseIf Choice == 2  ;Switch from stored to digest
        Int ItemType = JArray.getInt(JA_OptionList2, Option)
        If ItemType == 2  ;Change to one
          ObjectReference Item = JArray.getForm(JA_OptionList1, Option) as ObjectReference
          If Item as SCLBundle
            Form CurrentForm = (Item as SCLBundle).ItemForm
            Int i
            Int NumItems = (Item as SCLBundle).NumItems
            If (CurrentForm as Potion || CurrentForm as Ingredient) && !isNotFood(CurrentForm)
              While i < NumItems
                akTarget.EquipItem(CurrentForm, False, False)
                i += 1
              EndWhile
              SCLibrary.addToObjectTrashList(Item, 2)
            Else
              addItem(akTarget, akBaseObject = CurrentForm, aiItemType = 1, aiItemCount = NumItems)
            EndIf
          Else
            Form Base = Item.GetBaseObject()
            If ((Base as Potion || Base as Ingredient) && !isNotFood(Base)) || (Item as Actor)
              addItem(akTarget, Item, aiItemType = 1)
            Else
              Debug.Notification("Item must be edible")
            EndIf
          EndIf
          Int JF_Stored = getContents(akTarget, 2)
          JFormMap.removeKey(JF_Stored, Item)
          quickUpdate(akTarget, True)
          buildContentsList(akTarget)
          UIExtensions.OpenMenu("UIListMenu", akTarget)
          Option = UIExtensions.GetMenuResultInt("UIListMenu")
        Else
          Debug.Notification("Item must be stored.")
        EndIf
      ;ElseIf Choice == 3
      EndIf
    Else
      Debug.Notification(JArray.getStr(JA_Description, Option))
      UIExtensions.OpenMenu("UIListMenu", akTarget)
      Option = UIExtensions.GetMenuResultInt("UIListMenu")
      ;/If buildContentsList(akTarget)
        Option = UIExtensions.OpenMenu("UIListMenu", akTarget)
      Else
        Option = 0
      EndIf/;
    EndIf
  EndWhile
  sendActorMainMenuOpenEvent(akTarget, 0)
  Return
EndFunction

Bool Function buildContentsList(Actor akTarget)
  UIListMenu LM_ST_Contents = UIExtensions.GetMenu("UIListMenu", True) as UIListMenu
  Int TargetData = getTargetData(akTarget)
  Int JF_CompleteContents = getCompleteContents(akTarget, TargetData)
  Bool HasSomething
  If !JValue.empty(JF_CompleteContents)
    releaseTempContainers()
    JA_Description = JValue.retain(JArray.object())
    JA_OptionList1 = JValue.retain(JArray.object())
    JA_OptionList2 = JValue.retain(JArray.object())
    ;JA_OptionList3 = JValue.retain(JArray.object())
    LM_ST_Contents.AddEntryItem("<< Return")
    JArray.addStr(JA_Description, "") ;Full item type description
    JArray.addForm(JA_OptionList1, None) ;Item ObjectReference
    JArray.addInt(JA_OptionList2, 0) ;Item Type
    ;JArray.addInt(JA_Optionlist3, -1) ;Item Index in JFormMap

    ObjectReference ItemKey = JFormMap.nextKey(JF_CompleteContents) as ObjectReference
    While ItemKey
      Int JM_ItemEntry = JFormMap.getObj(JF_CompleteContents, ItemKey)
      Int ItemType = JMap.getInt(JM_ItemEntry, "ItemType")
      String ItemName = nameGet(ItemKey)
      String ShortDesc = getShortItemTypeDesc(ItemType)
      String FullDesc = getFullItemTypeDesc(ItemType)
      String DValue = roundFlt(JMap.getFlt(JM_ItemEntry, "DigestValue"), 2)
      String ItemEntry
      If ItemKey as SCLBundle
        ItemEntry = ItemName + "x" + (ItemKey as SCLBundle).NumItems + ": " + ShortDesc + ", " + DValue
      Else
        ItemEntry = ItemName + ": " + ShortDesc + ", " + DValue
      EndIf
      LM_ST_Contents.AddEntryItem(ItemEntry)
      JArray.addStr(JA_Description, FullDesc)
      JArray.addForm(JA_OptionList1, ItemKey)
      JArray.addInt(JA_OptionList2, ItemType)
      ;JArray.addInt(JA_OptionList3, i)
      ItemKey = JFormMap.nextKey(JF_CompleteContents, ItemKey) as ObjectReference
    EndWhile
    HasSomething = True
  EndIf

  Int LibList = SCLSet.JA_LibraryList
  Int i = JArray.count(LibList)
  While i
    i -= 1
    Int JA_Entry = (JArray.getForm(LibList, i) as Lib_SC).addActorContentsMenuOptions(akTarget, JA_Description, JA_OptionList1, JA_OptionList2, JA_OptionList3, TargetData)
    Int j = JArray.count(JA_Entry)
    If j > 0
      While j
        j -= 1
        LM_ST_Contents.AddEntryItem(JArray.getStr(JA_Entry, j))
      EndWhile
      HasSomething = True
    EndIf
  EndWhile
  Return HasSomething
EndFunction

;Perks Menu ********************************************************************
Function showPerksList(Actor akTarget = None, Int aiMode = 0)
  If akTarget == None
    akTarget == Game.GetCurrentCrosshairRef() as Actor
  EndIf

  If akTarget == None
    akTarget == PlayerRef
  EndIf

  If !buildPerksMenu(akTarget)
    Debug.Notification("No perks available for " + nameGet(akTarget))
    sendActorMainMenuOpenEvent(akTarget, 0)
    Return
  EndIf

  UIExtensions.OpenMenu("UIListMenu", akTarget)
  Int Option = UIExtensions.GetMenuResultInt("UIListMenu")
  While Option != 0 && Option < JArray.count(JA_Description)
    Notice("Option " + Option + " selected!")
    Bool RebuildMenu = False
    String PerkID = JArray.getStr(JA_OptionList1, Option)
    If canTakePerk(akTarget, PerkID, SCLSet.DebugEnable)
      takePerk(akTarget, PerkID)
      Debug.Notification("Perk " + getPerkName(PerkID, JArray.getInt(JA_OptionList2, Option)) + " taken!")
      RebuildMenu = True
    Else
      Debug.Notification(JArray.getStr(JA_Description, Option))
    EndIf
    If RebuildMenu
      If buildPerksMenu(akTarget)
        UIExtensions.OpenMenu("UIListMenu", akTarget)
        Option = UIExtensions.GetMenuResultInt("UIListMenu")
      Else
        Option = 0
      Endif
    Else
      UIExtensions.OpenMenu("UIListMenu", akTarget)
      Option = UIExtensions.GetMenuResultInt("UIListMenu")
    Endif
  EndWhile
  sendActorMainMenuOpenEvent(akTarget, 0)
EndFunction

Bool Function buildPerksMenu(Actor akTarget)
  UIListMenu LM_ST_Perks = UIExtensions.GetMenu("UIListMenu", True) as UIListMenu
  Int TargetData = getTargetData(akTarget)
  If !TargetData
    Notice(nameGet(akTarget) + " has no data! Can't build perks menu!")
    Return False
  EndIf
  releaseTempContainers()
  JA_Description = JValue.retain(JArray.object())
  JA_OptionList1 = JValue.retain(JArray.object())
  JA_OptionList2 = JValue.retain(JArray.object())
  Int HasAvailablePerk = 0
  LM_ST_Perks.AddEntryItem("<< Return")
  JArray.addStr(JA_Description, "")
  JArray.addStr(JA_OptionList1, "")

  String sPerkID = JMap.nextKey(SCLSet.JM_PerkIDs)
  While sPerkID
    HasAvailablePerk += addPerkEntry(akTarget, LM_ST_Perks, sPerkID)
    sPerkID = JMap.nextKey(SCLSet.JM_PerkIDs, sPerkID)
  EndWhile
  Return HasAvailablePerk as Bool
EndFunction

Int Function addPerkEntry(Actor akTarget, UIListMenu akMenu, String asPerkID)
  Int CurrentPerkValue = getCurrentPerkLevel(akTarget, asPerkID)
  If canTakePerk(akTarget, asPerkID, SCLSet.DebugEnable)
    CurrentPerkValue += 1
  Endif
  If CurrentPerkValue
    akMenu.AddEntryItem(getPerkName(asPerkID, CurrentPerkValue))
    JArray.addStr(JA_Description, getPerkDescription(asPerkID, CurrentPerkValue))
    JArray.addStr(JA_OptionList1, asPerkID)
    JArray.addInt(JA_OptionList2, CurrentPerkValue)
    Return 1
  Else
    Return 0
  EndIf
EndFunction

;*******************************************************************************
;Command Console
;*******************************************************************************
Function processConsoleInput(Actor akTarget, String[] cmdList)
  If cmdList[0] == "SCX"
    Int TargetData = getTargetData(akTarget)
    If !TargetData
      Debug.Notification("Invalid Actor")
      Return
    EndIf
    If cmdList[1] == "help"
      If cmdList[2] == "get"
        Debug.Notification("Retrieves stat information about an actor")
        If cmdList[3] == "base"
          Debug.Notification("Base Stomach Capacity: Amount of food that the actor can eat before getting too full")
        ElseIf cmdList[3] == "adjbase"
          Debug.Notification("Adjusted Base Stomach Capacity: Base stomach capacity, adjusted for actor scale")
        ElseIf cmdList[3] == "stretch"
          Debug.Notification("Stomach Stretchability: Multiplier of base, determines maximum stomach capacity")
        ElseIf cmdList[3] == "digestrate"
          Debug.Notification("Digestion Rate: Determines how fast actor digests food")
        ElseIf cmdList[3] == "fullness"
          Debug.Notification("Stomach Fullness: How much food is currently in the actor's stomach")
        ElseIf cmdList[3] == "max"
          Debug.Notification("Stomach Max Capacity: The maximum amount of food this actor can hold before vomiting")
        ElseIf cmdList[3] == "SCLRoomForMore" || cmdList[3] == "SCLStoredLimitUp" || cmdList[3] == "SCLHeavyBurden" || cmdList[3] == "SCLAllowOverflow"
          Debug.Notification("Displays current perk level")
          Debug.Notification("Available 'get [perk]' Commands: description, requirements")
        Else
          Debug.Notification("Available 'get' Commands: 'base', 'adjbase', 'stretch', 'digestrate', 'fullness', 'max', " + JMap.allKeysPArray(SCLSet.JM_PerkIDs))
        EndIf
      ElseIf cmdList[2] == "take"
        Debug.Notification("Takes perk for actor")
        Debug.Notification("Available 'take' Commands: 'SCLRoomForMore', 'SCLStoredLimitUp', 'SCLHeavyBurden', 'SCLAllowOverflow'")
      ElseIf cmdList[2] == "set"
        Debug.Notification("Sets stat information for an actor")
        If !SCLSet.DebugEnable
          Debug.Notification("Debug Settings Not Enabled. Please set using 'settings debugenable'")
        ElseIf cmdList[3] == "base"
          Debug.Notification("Base Stomach Capacity: Amount of food that the actor can eat before getting too full")
        ElseIf cmdList[3] == "stretch"
          Debug.Notification("Stomach Stretchability: Multiplier of base, determines maximum stomach capacity")
        ElseIf cmdList[3] == "digestrate"
          Debug.Notification("Digestion Rate: Determines how fast actor digests food")
        Else
          Debug.Notification("Available 'set' Commands: 'base', 'stretch', 'digestrate'")
        EndIf
      ElseIf cmdList[2] == "settings"
        Debug.Notification("Allows one to view and edit settings.")
      ElseIf cmdList[2] == "name"
        Debug.Notification("Displays targeted actor name")
      ElseIf cmdList[2] == "help"
        Debug.Notification("Displays information about arguments and commands")
      Else
        Debug.Notification("Available 'help' commands: 'get', 'set', 'take', 'settings', 'name','help', ")
      EndIf

    ElseIf cmdList[1] == "take"
      If canTakePerk(akTarget, cmdList[2], SCLSet.DebugEnable)
        takePerk(akTarget, cmdList[2])
        Debug.Notification("Perk " + getPerkName(cmdList[2], getCurrentPerkLevel(akTarget, cmdList[2])) + " taken! Some perk effects will not show until the console is closed")
      ElseIf getPerkDescription(cmdList[2], getCurrentPerkLevel(akTarget, cmdList[2]))
        Debug.Notification("Actor cannot take perk")
        Debug.Notification(getPerkDescription(cmdList[2], getCurrentPerkLevel(akTarget, cmdList[2])))
        Debug.Notification(getPerkRequirements(cmdList[2], getCurrentPerkLevel(akTarget, cmdList[2])))
      Else
        Debug.Notification("Invalid Perk. Displaying help")
        String[] PerkNames = JMap.allKeysPArray(SCLSet.JM_PerkIDs)
        Debug.Notification("Available 'take' Commands: " + PerkNames)
      EndIf

    ElseIf cmdList[1] == "get"
      If cmdList[2] == "base"
        Debug.Notification("Base Stomach Capacity = " + JMap.getFlt(TargetData, "STBase"))
      ElseIf cmdList[2] == "adjbase"
        Debug.Notification("Adjusted Base Stomach Capacity = " + getAdjBase(akTarget, TargetData))
      ElseIf cmdList[2] == "stretch"
        Debug.Notification("Stomach Stretchability = " + JMap.getFlt(TargetData, "STStretch"))
      ElseIf cmdList[2] == "digestrate"
        Debug.Notification("Digestion Rate = " + JMap.getFlt(TargetData, "STDigestionRate"))
      ElseIf cmdList[2] == "fullness"
        Debug.Notification("Stomach Fullness = " + JMap.getFlt(TargetData, "STFullness"))
      ElseIf cmdList[2] == "max"
        Debug.Notification("Max Stomach Capacity = " + getMax(akTarget, TargetData))
      ElseIf JMap.hasKey(SCLSet.JM_PerkIDs, cmdList[2])
        If cmdList[3] == "requirements"
          Debug.Notification(getPerkRequirements(cmdList[2], getCurrentPerkLevel(akTarget, cmdList[2])))
        ElseIf cmdList[3] == "description"
          Debug.Notification(getPerkDescription(cmdList[2], getCurrentPerkLevel(akTarget, cmdList[2])))
        Else
          Debug.Notification(getPerkName(cmdList[2], getCurrentPerkLevel(akTarget, cmdList[2])))
        EndIf
      ;ElseIf cmdList[2] == ""
        ;Add more options here
      Else
        Debug.Notification("Invalid Command: Displaying help...")
        Debug.Notification("Available 'get' Commands: 'base', 'adjbase', 'stretch', 'digestrate', 'fullness', 'max', 'SCLRoomForMore', 'SCLStoredLimitUp', 'SCLHeavyBurden', 'SCLAllowOverflow'")
      EndIf
    ElseIf cmdList[1] == "set"
      If SCLSet.DebugEnable
        If cmdList[3] != ""
          If cmdList[2] == "base"
            JMap.setFlt(TargetData, "STBase", cmdList[3] as Float)
            Debug.Notification("Base Stomach Capacity = " + JMap.getFlt(TargetData, "STBase"))
          ElseIf cmdList[2] == "stretch"
            JMap.setFlt(TargetData, "STStretch", cmdList[3] as Float)
            Debug.Notification("Stomach Stretchability = " + JMap.getFlt(TargetData, "STStretch"))
          ElseIf cmdList[2] == "digestrate"
            JMap.setFlt(TargetData, "STDigestionRate", cmdList[3] as Float)
            Debug.Notification("Digestion Rate = " + JMap.getFlt(TargetData, "STDigestionRate"))
          Else
            Debug.Notification("Invalid Command: Displaying help...")
            Debug.Notification("Available 'set' Commands: 'base', 'stretch', 'digestrate'")
          EndIf
        Else
          Debug.Notification("No value inputted")
        Endif
      Else
        Debug.Notification("Debug mode not enabled.")
      EndIf
    ElseIf cmdList[1] == "settings"
      If cmdList[2] == "debugenable"
        SCLSet.DebugEnable = !SCLSet.DebugEnable
        Debug.Notification("Debug Mode: " + SCLSet.DebugEnable)
      Else
        Debug.MessageBox("Interface---> SCL_SET_ActionKey: DX code allowing you to interact with objects. Default 24 (O); SCL_SET_DebugEnable: Enables and disables debug options, such as setting stats. Default 0 (Off); SCL_SET_GodMode1: Disables maximum stomach limit. Default 0 (Off); SCL_SET_PlayerMessagePOV: Changes the point of view of player thoughts. Valid inputs are 0, 1, 2, and 3. Default 0 (Use whatever is available); SCL_SET_ShowDebugMessages: Displays log information in the notifications. Default 0 (Off)")
        Debug.MessageBox("Inflation---> SCL_SET_BellyInflateMethod: Sets how to inflate actor's abdomens. Valid inputs are 0 (Disabled), 1 (NiOverride), 2 (SLIF), 3 (Equipment (Unavailable)), 4 (Dynamic Equipment((Unavailable)). Default 0 (Disabled); SCL_SET_BellyMin: Smallest size to set abdomen. Default 1. SCL_SET_BellyMax: Largest size to set abdomen. Default 10. SCL_SET_BellyMulti: Multiplies size of abodmen within set limits. Default 1; SCL_SET_Incr: Sets increments for abdomen growth. Smaller values mean smoother growth. Default 0.1; SCL_SET_BellyHighScale: Dampens abdomen size at high actor weights. Negative values dampen. Recommended size is 5. Default 0; SCL_SET_BellyCurve: Dampens abdomen size at high values. Values closer to 0 dampen more. Default 1.75")
        Debug.MessageBox("Gameplay and Performance---> SCL_SET_AdjBaseMulti: Adjusts stomach capacity based on actor scale. This value multiplies this adjustment. Default 1; SCL_SET_DefaultExpandBonus: Sets base amount of expansion gain from being overfull. Default 0.5; SCL_SET_DefaultExpandTimer: Sets base amount of time one must stay overfull before bonus is granted. Default 2 in-game hours; SCL_SET_GlobalDigestMulti: Multiplies digestion timer values. Larger values mean faster digestion. Default 1; SCL_SET_UpdateRate: Determines how often all actors are updated. Default every 10 real-world seconds. SCL_SET_UpdateDelay: Determines wait between individual actor updates. Default 0.5 real-world seconds.")
      EndIf
    ElseIf cmdList[1] == "name"
      Debug.Notification("Targeted actor is " + akTarget.GetLeveledActorBase().GetName())
    Else
      Debug.Notification("Available commands: 'help', 'get', 'set', 'name', 'settings'")
    EndIf

    Utility.WaitMenuMode(0.1)
    String History = UI.GetString("Console","_global.Console.ConsoleInstance.CommandHistory.text")
    Int iHistory = StringUtil.GetLength(History) - 1
    Bool bRunning = True
    While iHistory > 0 && bRunning == True
      If StringUtil.AsOrd(StringUtil.GetNthChar(history,iHistory - 1))==13
        bRunning = False
      Else
        iHistory -= 1
      EndIf
    EndWhile
    UI.SetString("Console","_global.Console.ConsoleInstance.CommandHistory.text",StringUtil.Substring(History,0,iHistory))
  Else
    Return
  EndIf
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
  Return ShowPlayerThoughtDB(akTarget, sKey, iOverride, akActors, aiActorIndex)
EndFunction

Function Popup(String sMessage)
  ShowPopup(sMessage, DebugName)
EndFunction

Function Note(String sMessage)
  ShowNote(sMessage, DebugName)
EndFunction

Function Notice(String sMessage, Int aiID = 0)
  Int ID
  If aiID > 0
    ID = aiID
  Else
    ID = DMID
  EndIf
  showNotice(sMessage, ID, DebugName)
EndFunction

Function Issue(String sMessage, Int iSeverity = 0, Int aiID = 0, Bool bOverride = False)
  Int ID
  If aiID > 0
    ID = aiID
  Else
    ID = DMID
  EndIf
  ShowIssue(sMessage, iSeverity, ID, bOverride, DebugName)
EndFunction

Bool Function ShowPlayerThoughtDB(Actor akTarget, String sKey, Int iOverride = 0, Actor[] akActors = None, Int aiActorIndex = -1)
  {Use this to display player information. Returns whether the passed actor is
  the player.
  Pulls message from database; make sure sKey is valid.
  Will add POV int to end of key, so omit it in the parameter}
  If akTarget == PlayerRef
    Int Setting
    If iOverride != 0
      Setting = iOverride
    Else
      Setting = SCLSet.PlayerMessagePOV
    EndIf
    If Setting == -1
      Return True
    EndIf
    String sMessage = getMessage(sKey + Setting, -1, True, akActors, aiActorIndex)
    If sMessage
      Debug.Notification(sMessage)
    Else
      PlayerThought(akTarget, getMessage(sKey + 1, -1, True, akActors, aiActorIndex), getMessage(sKey + 2, -1, True, akActors, aiActorIndex),getMessage(sKey + 3, -1, True, akActors, aiActorIndex))
    EndIf
    Return True
  Else
    Return False
  EndIf
EndFunction

Function ShowPopup(String sMessage, String asDebugName)
  {Shows MessageBox, then waits for menu to be closed before continuing}
  Debug.MessageBox(asDebugName + sMessage)
  Halt()
EndFunction

Function Halt()
  {Wait for menu to be closed before continuing}
  While Utility.IsInMenuMode()
    Utility.Wait(0.5)
  EndWhile
EndFunction

Function ShowNote(String sMessage, String asDebugName)
  Debug.Notification(asDebugName + sMessage)
  Debug.Trace(asDebugName + sMessage)
EndFunction


Function ShowNotice(String sMessage, Int aiID = 0, String asDebugName)
  {Displays message in notifications and logs if globals are active}
  If SCLSet.ShowDebugMessages && getDMEnable(aiID)
    Debug.Notification(asDebugName + sMessage)
  EndIf
  Debug.Trace(asDebugName + sMessage)
EndFunction

Function ShowIssue(String sMessage, Int iSeverity = 0, Int aiID = 0, Bool bOverride = False, String asDebugName)
  {Displays a serious message in notifications and logs if globals are active
  Use bOverride to ignore globals}
  If bOverride || (SCLSet.ShowDebugMessages && getDMEnable(aiID))
    String Level
    If iSeverity == 0
      Level = "Info"
    ElseIf iSeverity == 1
      Level = "Warning"
    ElseIf iSeverity == 2
      Level = "Error"
    EndIf
    Debug.Notification(DebugName + Level + " " + sMessage)
  EndIf
  Debug.Trace(DebugName + sMessage, iSeverity)
EndFunction


;/String Function getPerkDescription(String asPerkID, Int aiPerkLevel = 0)
  {Returns basic perk description, since you can't pull descriptions from perks themselves}
  If asPerkID == "SCLRoomForMore"
    If aiPerkLevel == 0
      Return "Increases base capacity."
    ElseIf aiPerkLevel == 1
      Return "Increases base capacity by 2.5."
    ElseIf aiPerkLevel == 2 || aiPerkLevel == 3
      Return "Increases base capacity by 5."
    ElseIf aiPerkLevel == 4
      Return "Increases base capacity by 10."
    ElseIf aiPerkLevel == 4
      Return "Increases base capacity by 15."
    ElseIf aiPerkLevel >= 5
      Return "Increases base capacity by 10%."
    EndIf
  ElseIf asPerkID == "SCLStoredLimitUp"
    If aiPerkLevel == 0
      Return "Allows you to store items in your stomach."
    Else
      Return "Increases item storage by 2."
    EndIf
  ElseIf asPerkID == "SCLHeavyBurden"
    If aiPerkLevel == 0
      Return "Allows actor to move freely when their weight is high."
    ElseIf aiPerkLevel > 0
      Int BaseWeight = 100 * (aiPerkLevel + 1)
      Return "Allows actor to move freely when their weight exceeds " + BaseWeight + "."
    EndIf
  ElseIf asPerkID == "SCLAllowOverflow"
    Return "Allows actor to eat above the maximum without vomiting (other effects may apply)."
  Else
    String Desc
    Int LibList = SCLSet.JA_LibraryList
    Int i = JArray.count(LibList)
    While i && Desc != ""
      i -= 1
      Desc = (JArray.getForm(LibList, i) as Lib_SC).getPerkDescription(asPerkID, aiPerkLevel)
    EndWhile
    If Desc
      Return Desc
    Else
      Issue("Invalid perk ID inputted into getPerkDescription function.", 1)
      Return ""
    EndIf
  EndIf
EndFunction

String Function getPerkRequirements(String asPerkID, Int aiPerkLevel)
  {Returns description of what an actor needs to take a perk}
  If asPerkID == "SCLRoomForMore"
    If aiPerkLevel == 0
      Return "No Requirement"
    Elseif aiPerkLevel > 0
      Int Req
      If aiPerkLevel == 1
        Req = 10
      ElseIf aiPerkLevel == 2
        Req = 25
      ElseIf aiPerkLevel == 3
        Req = 45
      ElseIf aiPerkLevel == 4
        Req = 60
      ElseIf aiPerkLevel == 5
        Req = 90
      EndIf
      Return "Digest a total of " + Req + " food"
    EndIf
  ElseIf asPerkID == "SCLStoredLimitUp"
    If aiPerkLevel == 0
      Return "No Requirement"
    Elseif aiPerkLevel > 0
      Int Req
      If aiPerkLevel == 1
        Req = 25
      ElseIf aiPerkLevel == 2
        Req == 50
      ElseIf aiPerkLevel == 3
        Req = 75
      ElseIf aiPerkLevel == 4
        Req = 115
      ElseIf aiPerkLevel == 5
        Req = 150
      EndIf
      Return "Have a stomach capacity greater than " + Req + "."
    EndIf
  ElseIf asPerkID == "SCLHeavyBurden"
    If aiPerkLevel == 0
      Return "No Requirement"
    ElseIf aiPerkLevel > 0
      Int MaxWeight = 150 * (aiPerkLevel + 1)
      Return "Have " + MaxWeight + " units in your stomach at some point and reach level " + MaxWeight / 10 + "."
    EndIf
  ElseIf asPerkID == "SCLAllowOverflow"
    If aiPerkLevel == 0
      Return "No Requirement"
    Else
      Return "Requirements: Overeat and vomit at least 30 times, and reach level 30."
    EndIf
  Else
    String Reqs
    Int LibList = SCLSet.JA_LibraryList
    Int i = JArray.count(LibList)
    While i && !Reqs
      i -= 1
      Reqs = (JArray.getForm(LibList, i) as Lib_SC).getPerkRequirements(asPerkID, aiPerkLevel)
    EndWhile
    If Reqs
      Return Reqs
    Else
      Issue("Invalid perk ID inputted into getPerkRequirements function.", 1)
      Return ""
    EndIf
  EndIf
EndFunction/;
