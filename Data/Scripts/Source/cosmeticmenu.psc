Scriptname CosmeticMenu extends RaceMenu

Function RegisterEvents()
	RegisterForModEvent("TTM_TintColorChange", "OnTintColorChange") ; Event sent when a tint changes color
	RegisterForModEvent("TTM_TintTextureChange", "OnTintTextureChange") ; Event sent when a tint changes texture

	; Overlay Management
	RegisterForModEvent("TTM_OverlayTextureChange", "OnOverlayTextureChange") ; Event sent when an overlay's texture changes
	RegisterForModEvent("TTM_OverlayColorChange", "OnOverlayColorChange") ; Event sent when an overlay's color changes
	RegisterForModEvent("TTM_OverlayGlowColorChange", "OnOverlayGlowColorChange") ; Event sent when an overlay's color changes
	RegisterForModEvent("TTM_ShadersInvalidated", "OnShadersInvalidated") ; Event sent when a tint changes

	; RaceSexMenu Data Transfer
	RegisterForModEvent("RSMDT_SendMenuName", "OnReceiveMenuName")
	RegisterForModEvent("RSMDT_SendRootName", "OnReceiveRootName")
	RegisterForModEvent("RSMDT_SendPaintRequest", "OnReceivePaintRequest")
	RegisterForModEvent("RSMDT_SendRestore", "OnReceiveRestore")
	; --------------------------------------------
EndFunction

Function OnStartup()

EndFunction

Event OnReceivePaintRequest(string eventName, string strArg, float numArg, Form formArg)
	LoadDefaults()
	SaveTints()
	UpdateColors()
	UpdateOverlays()
	parent.OnReceivePaintRequest(eventName, strArg, numArg, formArg)
EndEvent

Event OnGameReload()
	OnStartup()
	LoadDefaults()
EndEvent

Function UpdateTints()
	
EndFunction

Event On3DLoaded(ObjectReference akRef)

EndEvent

Event OnMenuOpen(string menuName)

EndEvent

Event OnMenuClose(string menuName)

EndEvent
