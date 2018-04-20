PapyrusUtil v3.3

1. Description
2. Examples
3. Requirements
4. Installing
5. Uninstalling
6. Updating
7. Compatibility & issues
8. Credits
9. Changelog



1. Description

SKSE plugin that allows you to save any amount of int, float, form and string values on any form or globally from papyrus scripts. Also supports lists of those data types. These values can be accessed from any mod allowing easy dynamic compatibility.

Some example functions:
Toggle fly cam and set fly cam speed - TFC.
Set menus on / off - TM.
Adds an additional package stack override on actors. See ActorUtil.psc
Replace any animations on selected objects. See ObjectUtil.psc
Print messages to console.
Get, set, save, or and load data to a custom external JSON file. See JsonUtil.psc

PapyrusUtil.psc - Version check & array related functions.
StorageUtil.psc - Store variables and lists of data on a form that can be pulled back out using the form and variable name as keys. See psc file for documentation.
JsonUtil.psc - Similar to StorageUtil.psc but saves data to custom external .json files instead of forms, letting them be customizable out of game and stored independent of a users save file.
ActorUtil.psc - Actor package override.
ObjectUtil.psc - Animation replacement.
MiscUtil.psc - Some misc commands.

2. Examples
See post or check the various script psc files for documentation and some examples

3. Requirements

SKSE 1.7.3 latest version: http://skse.silverlock.org/



4. Installing

Use mod manager or extract files manually.



5. Uninstalling

Remove the files you added in Installing step.



6. Updating

Just overwrite all files.



7. Compatibility & issues

Should be compatible with everything.



8. Credits

exiledviper - continued maintenance & refactoring of original plugin's source code
meh321 - original version and idea
SKSE team - for making this plugin possible
milzschnitte - for suggestions


9. Changelog

3.3 - 09/15/2016
Various fixes for various CTD and performance issues
JsonUtil New Functions:
	Added arbitrary path functions to allow custom JSON formatting
	JsonInFolder(string folder) to get array of JSON files that exist in a given folder
MiscUtil New Function:
	ScanCellNPCsByFaction() to search cell for actors within a given faction
PapyrusUtil New Function:
	GetScriptVersion() to get current installed script version, which might differ from GetVersion()'s DLL value depending on user's varied and/or bad mod installation. 
Fixes:
	Some fixes to JsonUtil file handling and missing values
	Many other fixes I can't specifically remember at the moment


3.2 - 01/04/2016
Many fixes for various CTD and performance issues
JsonUtil New Functions:
	Unload() - Unloads a file from memory that has been used by JsonUtil, optionally saving changes first
	IsPendingSave() - Checks if the given Json file has been modified since it was last loaded/saved
	IsGood() - Checks if the given Json file is currently loaded or not and has no errors
	GetErrors() - Returns a formatted string of any Json parsing errors, if any
	JsonInFolder() - Returns an array of all Json files in a given directory.
StorageUtil New Functions:
	CountObj<type>Prefix() - counts the number of keys that start with string on a specific object
	ClearObj<type>Prefix() - removes any values with keys that start with string on a specific object
MiscUtil New Functions:
	FilesInFolder() - Returns an array of all files, or with a given extensions, contained in a folder.
	ScallCellActors() - Get an array of nearby actors in a cell matching criteria. 
	ScanCellObjects() - Get an array of nearby objects of specific form type in a cell matching criteria. 
	WriteToFile() - Re-added after having removed in previous update.
	ReadFromFile() - Re-added after having removed in previous update.

3.1 - 09/01/2015
Fixed a bug causing CTD during save load for some users.
Added Count<type>Prefix() to StorageUtil and JsonUtil - counts the number of keys that start with string
Added Clear<type>Prefix() to StorageUtil - removes any values with keys that start with string
Added Pluck<type>() to StorageUtil - gets a value and returns it, then removes it from storage.
Added Shift<type>List() to StorageUtil - gets the first value of a list and then removes it from that list.
Added Pop<type>List() to StorageUtil - gets the last value of a list and then removes it from that list.

3.0 - 08/21/2015
REQUIRES SKSE 1.7.3
StorageUtil & JsonUtil Int/Float/String/FormListToArray()
Various new utility and array functions in PapyrusUtil.psc
Various other new functions I can't remember, mostly related to dealing with or returning arrays
Fixed various crash related bugs
Improved performance for many functions
REMOVED MiscUtil.WriteToFile(),ReadFromFile(),ExecuteBat() - Functions were largely unused, a security risk, and better accomplished by other means.

2.8 - 10/03/2014
Fixed critical bug causing StringListRemove to do exactly the opposite of what you want it to do
Fixed crash to desktop issue some users have experienced when plugin loads an external json files for reading
Added papyrus array initializing functions to PapyrusUtil.psc

2.7 - 09/09/2014
Added back package override saving.
Added AdjustInt/FloatValue() and Int/FloatListAdjust() functions to StorageUtil and JsonUtil, shortcut function for adjusting existing values +/- a given amount
Added a ClearAll() function to JsonUtil for emptying out an external json files contents.
Cleaned up various native functions to better check for proper arguments being passed to prevent potential crashes.

2.6 - 08/11/2014
Fixed bug causing crash/freeze when attempting to load a nonexistent external file.

2.5 - 08/08/2014
REQUIRES SKSE 1.7.1
Rewrite of plugin source code
Added new JsonUtil script
ListSlice() function for copying list into a Papyrus array
ListCopy() function for copying a Papyrus array into a list
ListResize() function for changing the length of list
Various other bug fixes and minor new functions
