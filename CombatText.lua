-----------------------------------------------------------------------------------------------
-- Client Lua Script for FloatTextPanel
-- Copyright (c) NCsoft. All rights reserved
-----------------------------------------------------------------------------------------------

require "Window"
require "Spell"
require "CombatFloater"
require "GameLib"
require "Unit"

local CombatText = {}

-----------------------------------------------------------------------------------------------
--Initialize Variable
-----------------------------------------------------------------------------------------------

-- Convert a color object into a hex-encoded string using format "rrggbb"
local function Convert_CColor_To_String(c)
	return string.format("%02x%02x%02x", math.floor(c.r * 255 + 0.5), math.floor(c.g * 255 + 0.5), math.floor(c.b * 255 + 0.5))
end

-- Convert a hex-encoded string into a color object, string format is assumed to be "rrggbb"
local function Convert_String_To_CColor(hex)
	local r, g, b = 0, 0, 0 -- invalid strings will result in these values being returned
	local n = tonumber(hex, 16)
	if n then r = math.floor(n / 65536); g = math.floor(n / 256) % 256; b = n % 256 end
	return CColor.new(r / 255, g / 255, b / 255, 1)
end

function dec2hex(IN)
    local B,K,OUT,I,D=16,"0123456789ABCDEF","",0
    while IN>0 do
        I=I+1
        IN,D=math.floor(IN/B),math.mod(IN,B)+1
        OUT=string.sub(K,D,D)..OUT
    end
    return OUT
end
function dec2cc(dec)
	return Convert_String_To_CColor(dec2hex(dec))
end
local OutWndRef, InWndRef, tcolor

local settings = {
	general = {
	velocity = "1",
	moocolor = 0xf5a2ff,
	},
	odb = {
	fontscale = 1,
	fontstyle = "CRB_HeaderGigantic_O",
	color = tonumber("ffffff",16),
	alpha = 0.6,
	},
	odc = {
	fontscale = 1.25,
	fontstyle = "CRB_FloaterSmall",
	color = tonumber("ef8d00",16),
	alpha = 1,
	},
	ohb = {
	fontscale = 1,
	fontstyle = "CRB_HeaderGigantic_O",
	color = tonumber("7ad230",16),
	alpha = 0.6,
	},
	ohc = {
	fontscale = 1.25,
	fontstyle = "CRB_FloaterSmall",
	color = tonumber("00ff1c",16),
	alpha = 1.0,
	},
	moo = {
	fontscale = 1.25,
	fontstyle = "CRB_FloaterSmall",
	color = tonumber("f5a2ff",16),
	alpha = 1,
	},
	idb = {
	fontscale = 1,
	fontstyle = "CRB_HeaderGigantic_O",
	color = tonumber("ffc500",16),
	alpha = 0.6,
	},
	idc = {
	fontscale = 1.25,
	fontstyle = "CRB_FloaterSmall",
	color = tonumber("ff0066",16),
	alpha = 1.0,
	},
	ihb = {
	fontscale = 0.75,
	fontstyle = "CRB_HeaderGigantic_O",
	color = tonumber("99ff66",16),
	alpha = 0.6,
	},
	ihc = {
	fontscale = 1.25,
	fontstyle = "CRB_FloaterSmall",
	color = tonumber("33ff00",16),
	alpha = 1.0,
	},
}

local submenudict = {
	["DamageControlsBase"] = "Base Damage",
	["DamageControlsCrit"] = "Critical Damage",
	["HealControlsBase"] = "Base Heal",
	["HealControlsCrit"] = "Critical Heal",
	["MoOControls"] = "MoO Damage",
}
	
local knTestingVulnerable = -1

local function pairsByKeys(t, f)
	local a = {}
	for n in pairs(t) do
		table.insert(a, n)
	end
	table.sort(a, f)
	local i = 0
	local iterator = function()
		i = i + 1
		if a[i] == nil then
			return nil
		else
			return a[i], t[a[i]]
		end
	end
	return iterator
end

function CombatText:new(o)
	o = o or {}
	setmetatable(o, self)
	self.__index = self
	return o
end

function CombatText:Init()
	local bHasConfigureFunction = false
	local strConfigureButtonText = ""
	local tDependencies = {
		-- "UnitOrPackageName",
	}
	Apollo.RegisterAddon(self, bHasConfigureFunction, strConfigureButtonText, tDependencies)
end

function CombatText:OnLoad()

	self.xmlDoc = XmlDoc.CreateFromFile("CombatOptions.xml")
	self.xmlDoc:RegisterCallback("OnDocLoaded", self)
	
	Apollo.RegisterEventHandler("OptionsUpdated_Floaters", 					"OnOptionsUpdated", self)
	Apollo.RegisterEventHandler("LootedMoney", 								"OnLootedMoney", self)
	Apollo.RegisterEventHandler("SpellCastFailed", 							"OnSpellCastFailed", self)
	Apollo.RegisterEventHandler("DamageOrHealingDone",				 		"OnDamageOrHealing", self)
	Apollo.RegisterEventHandler("CombatMomentum", 							"OnCombatMomentum", self)
	Apollo.RegisterEventHandler("ExperienceGained", 						"OnExperienceGained", self)	-- UI_XPChanged ?
	Apollo.RegisterEventHandler("ElderPointsGained", 						"OnElderPointsGained", self)
	Apollo.RegisterEventHandler("UpdatePathXp", 							"OnPathExperienceGained", self)
	Apollo.RegisterEventHandler("AttackMissed", 							"OnMiss", self)
	Apollo.RegisterEventHandler("SubZoneChanged", 							"OnSubZoneChanged", self)
	Apollo.RegisterEventHandler("RealmBroadcastTierMedium", 				"OnRealmBroadcastTierMedium", self)
	Apollo.RegisterEventHandler("GenericError", 							"OnGenericError", self)
	Apollo.RegisterEventHandler("PrereqFailureMessage",					 	"OnPrereqFailed", self)
	Apollo.RegisterEventHandler("GenericFloater", 							"OnGenericFloater", self)
	Apollo.RegisterEventHandler("UnitEvaded", 								"OnUnitEvaded", self)
	Apollo.RegisterEventHandler("QuestShareFloater", 						"OnQuestShareFloater", self)
	Apollo.RegisterEventHandler("CountdownTick", 							"OnCountdownTick", self)
	Apollo.RegisterEventHandler("TradeSkillFloater",				 		"OnTradeSkillFloater", self)
	Apollo.RegisterEventHandler("FactionFloater", 							"OnFactionFloater", self)
	Apollo.RegisterEventHandler("CombatLogTransference", 					"OnCombatLogTransference", self)
	Apollo.RegisterEventHandler("CombatLogCCState", 						"OnCombatLogCCState", self)
	Apollo.RegisterEventHandler("ActionBarNonSpellShortcutAddFailed", 		"OnActionBarNonSpellShortcutAddFailed", self)
	Apollo.RegisterEventHandler("GenericEvent_GenericError",				"OnGenericError", self)

	-- set the max count of floater text
	CombatFloater.SetMaxFloaterCount(500)
	CombatFloater.SetMaxFloaterPerUnitCount(500)

	-- loading digit sprite sets
	Apollo.LoadSprites("UI\\SpriteDocs\\CRB_NumberFloaters.xml")
	Apollo.LoadSprites("UI\\SpriteDocs\\CRB_CritNumberFloaters.xml")

	self.iDigitSpriteSetNormal 		= CombatFloater.AddDigitSpriteSet("sprFloater_Normal")
	self.iDigitSpriteSetVulnerable 	= CombatFloater.AddDigitSpriteSet("sprFloater_Vulnerable")
	self.iDigitSpriteSetCritical 	= CombatFloater.AddDigitSpriteSet("sprFloater_Critical")
	self.iDigitSpriteSetHeal 		= CombatFloater.AddDigitSpriteSet("sprFloater_Heal")
	self.iDigitSpriteSetShields 	= CombatFloater.AddDigitSpriteSet("sprFloater_Shields")
	self.iDigitSpriteSetShieldsDown = CombatFloater.AddDigitSpriteSet("sprFloater_NormalNoShields")

	-- add bg sprite for text
	self.iFloaterBackerCritical 	= CombatFloater.AddTextBGSprite("sprFloater_BackerCritical")
	self.iFloaterBackerNormal 		= CombatFloater.AddTextBGSprite("sprFloater_BackerNormal")
	self.iFloaterBackerVulnerable 	= CombatFloater.AddTextBGSprite("sprFloater_BackerVulnerable")
	self.iFloaterBackerHeal 		= CombatFloater.AddTextBGSprite("sprFloater_BackerHeal")
	self.iFloaterBackerShieldsDown 	= CombatFloater.AddTextBGSprite("sprFloater_BackerNormalNoShields")

	-- float text queue for delayed text
	self.tDelayedFloatTextQueue = Queue:new()
	self.iTimerIndex = 1

	self.fLastDamageTime = GameLib.GetGameTime()
	self.fLastOffset = 0
	self.tTimerFloatText = {}

	self:OnOptionsUpdated()
end
-- adding in an options menu
function CombatText:OnDocLoaded()
	if self.xmlDoc ~= nil and self.xmlDoc:IsLoaded() then
	
		self.wndOptions = Apollo.LoadForm(self.xmlDoc, "OptionsDialogue", nil, self)
		self.wndOptions:Show(false, true)	
		local wndOptionsControls = self.wndOptions:FindChild("OptionsDialogueControls")

		self.tAddons ={}
		
		Apollo.RegisterSlashCommand("ct", "OnCombatText_OptionsOn", self)
		
		local wndOutgoingControls = Apollo.LoadForm(self.xmlDoc, "OutgoingControlsList", wndOptionsControls, self)
		RegisterOptions("Outgoing", wndOutgoingControls)
		OutWndRef = wndOutgoingControls
		
		local wndIncomingControls = Apollo.LoadForm(self.xmlDoc, "IncomingControlsList", wndOptionsControls, self)
		RegisterOptions("Incoming", wndIncomingControls)
		InWndRef = wndIncomingControls
		self:SetOptions()
	
		Apollo.RegisterEventHandler("CombatText_OpenOptions", "OnCombatText_OptionsOn", self)
		Apollo.RegisterEventHandler("CombatText_CloseOptions", "OnCombatText_OptionsOff", self)
	
		-- Do additional Addon initialization here
		Event_FireGenericEvent("CombatText_OptionsLoaded")

	end
end

function CombatText:SetOptions()
	local odb = OutWndRef:FindChild("DamageControlsBase")
	local odc = OutWndRef:FindChild("DamageControlsCrit")
	local moo = OutWndRef:FindChild("MoOControls") --MoOControlsBase
	local ohb = OutWndRef:FindChild("HealControlsBase")
	local ohc = OutWndRef:FindChild("HealControlsCrit")
	
	-- outgoing damage base
	odb:FindChild("FontScale"):FindChild("ScaleEditBox"):SetText(settings.odb.fontscale)
	odb:FindChild("FontStyle"):FindChild("DropDown"):SetText(settings.odb.fontstyle)
	odb:FindChild("Color"):FindChild("EditBox"):SetText(settings.odb.alpha)
	odb:FindChild("Color"):FindChild("SliderBar"):SetValue(settings.odb.alpha)
	odb:FindChild("Color"):FindChild("Swatch"):SetBGColor(dec2cc(settings.odb.color))

	-- outoing damage critical
	odc:FindChild("FontScale"):FindChild("ScaleEditBox"):SetText(settings.odc.fontscale)
	odc:FindChild("FontStyle"):FindChild("DropDown"):SetText(settings.odc.fontstyle)
	odc:FindChild("Color"):FindChild("EditBox"):SetText(settings.odc.alpha)
	odc:FindChild("Color"):FindChild("SliderBar"):SetValue(settings.odc.alpha)
	odc:FindChild("Color"):FindChild("Swatch"):SetBGColor(dec2cc(settings.odc.color))	

	
	-- moo damage
	moo:FindChild("FontScale"):FindChild("ScaleEditBox"):SetText(settings.moo.fontscale)
	moo:FindChild("FontStyle"):FindChild("DropDown"):SetText(settings.moo.fontstyle)
	moo:FindChild("Color"):FindChild("EditBox"):SetText(settings.moo.alpha)
	moo:FindChild("Color"):FindChild("SliderBar"):SetValue(settings.moo.alpha)
	moo:FindChild("Color"):FindChild("Swatch"):SetBGColor(dec2cc(settings.moo.color))	
	
	-- out goin heals base
	ohb:FindChild("FontScale"):FindChild("ScaleEditBox"):SetText(settings.ohb.fontscale)
	ohb:FindChild("FontStyle"):FindChild("DropDown"):SetText(settings.ohb.fontstyle)
	ohb:FindChild("Color"):FindChild("EditBox"):SetText(settings.ohb.alpha)
	ohb:FindChild("Color"):FindChild("SliderBar"):SetValue(settings.ohb.alpha)
	ohb:FindChild("Color"):FindChild("Swatch"):SetBGColor(dec2cc(settings.ohb.color))	
	
	-- outoing heals critical
	ohc:FindChild("FontScale"):FindChild("ScaleEditBox"):SetText(settings.ohc.fontscale)
	ohc:FindChild("FontStyle"):FindChild("DropDown"):SetText(settings.ohc.fontstyle)
	ohc:FindChild("Color"):FindChild("EditBox"):SetText(settings.ohc.alpha)
	ohc:FindChild("Color"):FindChild("SliderBar"):SetValue(settings.ohc.alpha)
	ohc:FindChild("Color"):FindChild("Swatch"):SetBGColor(dec2cc(settings.ohc.color))
	
	local idb = InWndRef:FindChild("DamageControlsBase")
	local idc = InWndRef:FindChild("DamageControlsCrit")
	local ihb = InWndRef:FindChild("HealControlsBase")
	local ihc = InWndRef:FindChild("HealControlsCrit")
	
	-- incoming damage base
	idb:FindChild("FontScale"):FindChild("ScaleEditBox"):SetText(settings.idb.fontscale)
	idb:FindChild("FontStyle"):FindChild("DropDown"):SetText(settings.idb.fontstyle)
	idb:FindChild("Color"):FindChild("EditBox"):SetText(settings.idb.alpha)
	idb:FindChild("Color"):FindChild("SliderBar"):SetValue(settings.idb.alpha)
	odb:FindChild("Color"):FindChild("Swatch"):SetBGColor(dec2cc(settings.idb.color))

	-- incomingdamage critical
	idc:FindChild("FontScale"):FindChild("ScaleEditBox"):SetText(settings.idc.fontscale)
	idc:FindChild("FontStyle"):FindChild("DropDown"):SetText(settings.idc.fontstyle)
	idc:FindChild("Color"):FindChild("EditBox"):SetText(settings.idc.alpha)
	idc:FindChild("Color"):FindChild("SliderBar"):SetValue(settings.idc.alpha)
	idc:FindChild("Color"):FindChild("Swatch"):SetBGColor(dec2cc(settings.idc.color))	
	
	-- incoming heals base
	ihb:FindChild("FontScale"):FindChild("ScaleEditBox"):SetText(settings.ihb.fontscale)
	ihb:FindChild("FontStyle"):FindChild("DropDown"):SetText(settings.ihb.fontstyle)
	ihb:FindChild("Color"):FindChild("EditBox"):SetText(settings.ihb.alpha)
	ihb:FindChild("Color"):FindChild("SliderBar"):SetValue(settings.ihb.alpha)
	ihb:FindChild("Color"):FindChild("Swatch"):SetBGColor(dec2cc(settings.ihb.color))	
	
	-- incomingheals critical
	ihc:FindChild("FontScale"):FindChild("ScaleEditBox"):SetText(settings.ihc.fontscale)
	ihc:FindChild("FontStyle"):FindChild("DropDown"):SetText(settings.ihc.fontstyle)
	ihc:FindChild("Color"):FindChild("EditBox"):SetText(settings.ihc.alpha)
	ihc:FindChild("Color"):FindChild("SliderBar"):SetValue(settings.ihc.alpha)
	ihc:FindChild("Color"):FindChild("Swatch"):SetBGColor(dec2cc(settings.ihc.color))	
end

function CombatText:OnOptionsUpdated()
	if g_InterfaceOptions and g_InterfaceOptions.Carbine.bSpellErrorMessages ~= nil then
		self.bSpellErrorMessages = g_InterfaceOptions.Carbine.bSpellErrorMessages
	else
		self.bSpellErrorMessages = true
	end
end

-- on SlashCommand "/ct"
function CombatText:OnCombatText_OptionsOn()
	self.wndOptions:Invoke() -- show the window
	self:OnOptionsHomeClick()
end

function CombatText:OnCombatText_OptionsOff()
	self.wndOptions:Show(false)
end


function RegisterOptions(name, wndControls, bSingleTier)
	--Apollo.GetAddon("CandyUI_Options").tAddons[name] = wndControls
	local tData = {}
	tData.bSingleTier = bSingleTier
	
	wndControls:SetData(tData)
	wndControls:Show(false, true)
	
	for _, wndCurr in pairs(wndControls:GetChildren()) do
		wndCurr:Show(false, true)
	end
	
	--Apollo.GetAddon("CombatText").tAddons[name] = wndControls
	Apollo.GetAddon("CombatText").tAddons[name] = wndControls
	
	return true
end

function CombatText:OnCloseButtonClick( wndHandler, wndControl, eMouseButton )
	self.wndOptions:Close()
end

---------------------------------------------------------------------------------------------------
-- OptionsListItem Functions
---------------------------------------------------------------------------------------------------
function CombatText:HideAllOptions()
	for name, wndCurr in pairs(self.tAddons) do
		wndCurr:Show(false, true)
	end
end

function CombatText:GetDefaultTextOption()
	local tTextOption =
	{
		strFontFace 				= "CRB_FloaterLarge",
		fDuration 					= 2,
		fScale 						= 0.9,
		fExpand 					= 1,
		fVibrate 					= 0,
		fSpinAroundRadius 			= 0,
		fFadeInDuration 			= 0,
		fFadeOutDuration 			= 0,
		fVelocityDirection 			= 0,
		fVelocityMagnitude 			= 0,
		fAccelDirection 			= 0,
		fAccelMagnitude 			= 0,
		fEndHoldDuration 			= 0,
		eLocation 					= CombatFloater.CodeEnumFloaterLocation.Top,
		fOffsetDirection 			= 0,
		fOffset 					= -0.5,
		eCollisionMode 				= CombatFloater.CodeEnumFloaterCollisionMode.Horizontal,
		fExpandCollisionBoxWidth 	= 1,
		fExpandCollisionBoxHeight 	= 1,
		nColor 						= 0xFFFFFF,
		iUseDigitSpriteSet 			= nil,
		bUseScreenPos 				= false,
		bShowOnTop 					= false,
		fRotation 					= 0,
		fDelay 						= 0, 
		nDigitSpriteSpacing 		= 0,
	}
	return tTextOption
end

---------------------------------------------------------------------------------------------------
function CombatText:OnSpellCastFailed( eMessageType, eCastResult, unitTarget, unitSource, strMessage )
	if unitTarget == nil or not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return
	end

	-- modify the text to be shown
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.bUseScreenPos = true
	tTextOption.fOffset = -80
	tTextOption.nColor = 0xFFFFFF
	tTextOption.strFontFace = "CRB_Interface16_BO"
	tTextOption.bShowOnTop = true
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,		fScale = 1.5,	fAlpha = 0.8,},
		[2] = {fTime = 0.1,		fScale = 1,	fAlpha = 0.8,},
		[3] = {fTime = 1.1,		fScale = 1,	fAlpha = 0.8,	fVelocityDirection = 0,},
		[4] = {fTime = 1.3,		fScale = 1,	fAlpha = 0.0,	fVelocityDirection = 0,},
	}

	if self.bSpellErrorMessages then -- This is set by interface options
		self:RequestShowTextFloater(LuaEnumMessageType.SpellCastError, unitSource, strMessage, tTextOption)
	end
end

---------------------------------------------------------------------------------------------------
function CombatText:OnSubZoneChanged(idZone, strZoneName)
	-- if you're in a taxi, don't show zone change
	if GameLib.GetPlayerTaxiUnit() then
		return
	end

	local tTextOption = self:GetDefaultTextOption()
	tTextOption.bUseScreenPos = true
	tTextOption.fOffset = -280
	tTextOption.nColor = 0x80ffff
	tTextOption.strFontFace = "CRB_HeaderGigantic_O"
	tTextOption.bShowOnTop = true
	tTextOption.arFrames=
	{
		[1] = {fTime = 0,	fAlpha = 0,		fScale = .8,},
		[2] = {fTime = 0.6, fAlpha = 1.0,},
		[3] = {fTime = 4.6,	fAlpha = 1.0,},
		[4] = {fTime = 5.2, fAlpha = 0,},
	}

	self:RequestShowTextFloater( LuaEnumMessageType.ZoneName, GameLib.GetControlledUnit(), strZoneName, tTextOption )
end

---------------------------------------------------------------------------------------------------
function CombatText:OnRealmBroadcastTierMedium(strMessage)
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.bUseScreenPos = true
	tTextOption.fOffset = -180
	tTextOption.nColor = 0x80ffff
	tTextOption.strFontFace = "CRB_HeaderGigantic_O"
	tTextOption.bShowOnTop = true
	tTextOption.arFrames=
	{
		[1] = {fTime = 0,	fAlpha = 0,		fScale = .8,},
		[2] = {fTime = 0.6, fAlpha = 1.0,},
		[3] = {fTime = 4.6,	fAlpha = 1.0,},
		[4] = {fTime = 5.2, fAlpha = 0,},
	}

	self:RequestShowTextFloater( LuaEnumMessageType.RealmBroadcastTierMedium, GameLib.GetControlledUnit(), strMessage, tTextOption )
end

---------------------------------------------------------------------------------------------------
function CombatText:OnActionBarNonSpellShortcutAddFailed()
	local strMessage = Apollo.GetString("FloatText_ActionBarAddFail")
	self:OnSpellCastFailed( LuaEnumMessageType.GenericPlayerInvokedError, nil, GameLib.GetControlledUnit(), GameLib.GetControlledUnit(), strMessage )
end

---------------------------------------------------------------------------------------------------
function CombatText:OnGenericError(eError, strMessage)
	local arExciseListItem =  -- index is enums to respond to, value is optional (UNLOCALIZED) replacement string (otherwise the passed string is used)
	{
		[GameLib.CodeEnumGenericError.DbFailure] 						= "",
		[GameLib.CodeEnumGenericError.Item_BadId] 						= "",
		[GameLib.CodeEnumGenericError.Vendor_StackSize] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_SoldOut] 					= "",
		[GameLib.CodeEnumGenericError.Vendor_UnknownItem] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_FailedPreReq] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_NotAVendor] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_TooFar] 					= "",
		[GameLib.CodeEnumGenericError.Vendor_BadItemRec] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_NotEnoughToFillQuantity] 	= "",
		[GameLib.CodeEnumGenericError.Vendor_NotEnoughCash] 			= "",
		[GameLib.CodeEnumGenericError.Vendor_UniqueConstraint] 			= "",
		[GameLib.CodeEnumGenericError.Vendor_ItemLocked] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_IWontBuyThat] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_NoQuantity] 				= "",
		[GameLib.CodeEnumGenericError.Vendor_BagIsNotEmpty] 			= "",
		[GameLib.CodeEnumGenericError.Vendor_CuratorOnlyBuysRelics] 	= "",
		[GameLib.CodeEnumGenericError.Vendor_CannotBuyRelics] 			= "",
		[GameLib.CodeEnumGenericError.Vendor_NoBuyer] 					= "",
		[GameLib.CodeEnumGenericError.Vendor_NoVendor] 					= "",
		[GameLib.CodeEnumGenericError.Vendor_Buyer_NoActionCC] 			= "",
		[GameLib.CodeEnumGenericError.Vendor_Vendor_NoActionCC] 		= "",
		[GameLib.CodeEnumGenericError.Vendor_Vendor_Disposition] 		= "",
	}

	if arExciseListItem[eError] then -- list of errors we don't want to show floaters for
		return
	end

	self:OnSpellCastFailed( LuaEnumMessageType.GenericPlayerInvokedError, nil, GameLib.GetControlledUnit(), GameLib.GetControlledUnit(), strMessage )
end

---------------------------------------------------------------------------------------------------
function CombatText:OnPrereqFailed(strMessage)
	self:OnGenericError(nil, strMessage)
end

---------------------------------------------------------------------------------------------------
function CombatText:OnGenericFloater(unitTarget, strMessage)
	-- modify the text to be shown
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fDuration = 2
	tTextOption.bUseScreenPos = true
	tTextOption.fOffset = 0
	tTextOption.nColor = 0x00FFFF
	tTextOption.strFontFace = "CRB_HeaderLarge_O"
	tTextOption.bShowOnTop = true

	CombatFloater.ShowTextFloater( unitTarget, strMessage, tTextOption )
end

function CombatText:OnUnitEvaded(unitSource, unitTarget, eReason, strMessage)
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 1.0
	tTextOption.fDuration = 2
	tTextOption.nColor = 0xbaeffb
	tTextOption.strFontFace = "CRB_FloaterSmall"
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
	tTextOption.fOffset = -0.8
	tTextOption.fOffsetDirection = 0

	tTextOption.arFrames =
	{
		[1] = {fTime = 0,		fScale = 2.0,	fAlpha = 1.0,	nColor = 0xFFFFFF,},
		[2] = {fTime = 0.15,	fScale = 0.9,	fAlpha = 1.0,},
		[3] = {fTime = 1.1,		fScale = 0.9,	fAlpha = 1.0,	fVelocityDirection = 0,	fVelocityMagnitude = 5,},
		[4] = {fTime = 1.3,						fAlpha = 0.0,	fVelocityDirection = 0,},
	}

	CombatFloater.ShowTextFloater( unitSource, strMessage, tTextOption )
end

---------------------------------------------------------------------------------------------------
function CombatText:OnAlertTitle(strMessage)
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fDuration = 2
	tTextOption.fFadeInDuration = 0.2
	tTextOption.fFadeOutDuration = 0.5
	tTextOption.fVelocityMagnitude = 0.2
	tTextOption.fOffset = 0.2
	tTextOption.nColor = 0xFFFF00
	tTextOption.strFontFace = "CRB_HeaderLarge_O"
	tTextOption.bShowOnTop = true
	tTextOption.fScale = 1
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Top

	CombatFloater.ShowTextFloater( GameLib.GetControlledUnit(), strMessage, tTextOption )
end

---------------------------------------------------------------------------------------------------
function CombatText:OnQuestShareFloater(unitTarget, strMessage)
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fDuration = 2
	tTextOption.fFadeInDuration = 0.2
	tTextOption.fFadeOutDuration = 0.5
	tTextOption.fVelocityMagnitude = 0.2
	tTextOption.fOffset = 0.2
	tTextOption.nColor = 0xFFFF00
	tTextOption.strFontFace = "CRB_HeaderLarge_O"
	tTextOption.bShowOnTop = true
	tTextOption.fScale = 1
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Top

	CombatFloater.ShowTextFloater( unitTarget, strMessage, tTextOption )
end

---------------------------------------------------------------------------------------------------
function CombatText:OnCountdownTick(strMessage)
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fDuration = 1
	tTextOption.fFadeInDuration = 0.2
	tTextOption.fFadeOutDuration = 0.2
	tTextOption.fVelocityMagnitude = 0.2
	tTextOption.fOffset = 0.2
	tTextOption.nColor = 0x00FF00
	tTextOption.strFontFace = "CRB_HeaderLarge_O"
	tTextOption.bShowOnTop = true
	tTextOption.fScale = 1
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Top

	CombatFloater.ShowTextFloater( GameLib.GetControlledUnit(), strMessage, tTextOption )
end

---------------------------------------------------------------------------------------------------
function CombatText:OnDeath()
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fDuration = 2
	tTextOption.fFadeOutDuration = 1.5
	tTextOption.fScale = 1.2
	tTextOption.nColor = 0xFFFFFF
	tTextOption.strFontFace = "CRB_HeaderLarge_O"
	tTextOption.bShowOnTop = true
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Top
	tTextOption.fOffset = 1

	CombatFloater.ShowTextFloater( GameLib.GetControlledUnit(), Apollo.GetString("Player_Incapacitated"), tTextOption )
end

---------------------------------------------------------------------------------------------------
function CombatText:OnCombatLogTransference(tEventArgs)
	local bCritical = tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical
	if tEventArgs.unitCaster == GameLib.GetControlledUnit() then -- Target does the transference to the source
		self:OnDamageOrHealing( tEventArgs.unitCaster, tEventArgs.unitTarget, tEventArgs.eDamageType, math.abs(tEventArgs.nDamageAmount), math.abs(tEventArgs.nShield), math.abs(tEventArgs.nAbsorption), bCritical )
	else -- creature taking damage
		self:OnPlayerDamageOrHealing( tEventArgs.unitTarget, tEventArgs.eDamageType, math.abs(tEventArgs.nDamageAmount), math.abs(tEventArgs.nShield), math.abs(tEventArgs.nAbsorption), bCritical )
	end

	-- healing data is stored in a table where each subtable contains a different vital that was healed
	-- units in caster's group can get healed
	for idx, tHeal in ipairs(tEventArgs.tHealData) do
		if tHeal.unitHealed == GameLib.GetPlayerUnit() then -- source recieves the transference from the taker
			self:OnPlayerDamageOrHealing(tEventArgs.unitCaster, GameLib.CodeEnumDamageType.Heal, math.abs(tHeal.nHealAmount), 0, 0, bCritical )
		else
			self:OnDamageOrHealing(tEventArgs.unitCaster, tHeal.unitHealed, tEventArgs.eDamageType, math.abs(tHeal.nHealAmount), 0, 0, bCritical )
		end
	end
end

---------------------------------------------------------------------------------------------------
function CombatText:OnCombatMomentum( eMomentumType, nCount, strText )
	-- Passes: type enum, player's total count for that bonus type, string combines these things (ie. "3 Evade")
	local arMomentumStrings =
	{
		[CombatFloater.CodeEnumCombatMomentum.Impulse] 				= "FloatText_Impulse",
		[CombatFloater.CodeEnumCombatMomentum.KillingPerformance] 	= "FloatText_KillPerformance",
		[CombatFloater.CodeEnumCombatMomentum.KillChain] 			= "FloatText_KillChain",
		[CombatFloater.CodeEnumCombatMomentum.Evade] 				= "FloatText_Evade",
		[CombatFloater.CodeEnumCombatMomentum.Interrupt] 			= "FloatText_Interrupt",
		[CombatFloater.CodeEnumCombatMomentum.CCBreak] 				= "FloatText_StateBreak",
	}

	if not Apollo.GetConsoleVariable("ui.showCombatFloater") or arMomentumStrings[eMomentumType] == nil  then
		return
	end

	local nBaseColor = 0x7eff8f
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 0.8
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Back
	tTextOption.fOffset = 2.0
	tTextOption.fOffsetDirection = 90
	tTextOption.strFontFace = "CRB_FloaterSmall"
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,		nColor = 0xFFFFFF,		fAlpha = 0,		fVelocityDirection = 90,	fVelocityMagnitude = 5,		fScale = 0.8},
		[2] = {fTime = 0.15,							fAlpha = 1.0,	fVelocityDirection = 90,	fVelocityMagnitude = .2,},
		[3] = {fTime = 0.5,		nColor = nBaseColor,},
		[4] = {fTime = 1.0,		nColor = nBaseColor,},
		[5] = {fTime = 1.1,		nColor = 0xFFFFFF,		fAlpha = 1.0,	fVelocityDirection 	= 90,	fVelocityMagnitude 	= 5,},
		[6] = {fTime = 1.3,		nColor 	= nBaseColor,	fAlpha 	= 0.0,},
	}

	local unitToAttachTo = GameLib.GetControlledUnit()
	local strMessage = String_GetWeaselString(Apollo.GetString(arMomentumStrings[eMomentumType]), nCount)
	if eMomentumType == CombatFloater.CodeEnumCombatMomentum.KillChain and nCount == 2 then
		strMessage = Apollo.GetString("FloatText_DoubleKill")
		tTextOption.strFontFace = "CRB_FloaterMedium"
	elseif eMomentumType == CombatFloater.CodeEnumCombatMomentum.KillChain and nCount == 3 then
		strMessage = Apollo.GetString("FloatText_TripleKill")
		tTextOption.strFontFace = "CRB_FloaterMedium"
	elseif eMomentumType == CombatFloater.CodeEnumCombatMomentum.KillChain and nCount == 5 then
		strMessage = Apollo.GetString("FloatText_PentaKill")
		tTextOption.strFontFace = "CRB_FloaterHuge"
	elseif eMomentumType == CombatFloater.CodeEnumCombatMomentum.KillChain and nCount > 5 then
		tTextOption.strFontFace = "CRB_FloaterHuge"
	end

	CombatFloater.ShowTextFloater(unitToAttachTo, strMessage, tTextOption)
end

function CombatText:OnExperienceGained(eReason, unitTarget, strText, fDelay, nAmount)
	if not Apollo.GetConsoleVariable("ui.showCombatFloater") or nAmount < 0 then
		return
	end

	local strFormatted = ""
	local eMessageType = LuaEnumMessageType.XPAwarded
	local unitToAttachTo = GameLib.GetControlledUnit() -- unitTarget potentially nil

	local tContent = {}
	tContent.eType = LuaEnumMessageType.XPAwarded
	tContent.nNormal = 0
	tContent.nRested = 0

	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 0.8
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Back
	tTextOption.fOffset = 4.0 -- GOTCHA: Different
	tTextOption.fOffsetDirection = 90
	tTextOption.strFontFace = "CRB_FloaterSmall"
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,			fAlpha = 0,		fVelocityDirection = 90,	fVelocityMagnitude = 5,		fScale = 0.8},
		[2] = {fTime = 0.15,		fAlpha = 1.0,	fVelocityDirection = 90,	fVelocityMagnitude = .2,},
		[3] = {fTime = 0.5,	},
		[4] = {fTime = 1.0,	},
		[5] = {fTime = 1.1,			fAlpha = 1.0,	fVelocityDirection 	= 90,	fVelocityMagnitude 	= 5,},
		[6] = {fTime = 1.3,			fAlpha 	= 0.0,},
	}

	-- GOTCHA: UpdateOrAddXpFloater will stomp on these text formats anyways (TODO REFACTOR)
	if eReason == CombatFloater.CodeEnumExpReason.KillPerformance or eReason == CombatFloater.CodeEnumExpReason.MultiKill or eReason == CombatFloater.CodeEnumExpReason.KillingSpree then
		return -- should not be delivered via the XP event
	elseif eReason == CombatFloater.CodeEnumExpReason.Rested then
		tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
		strFormatted = String_GetWeaselString(Apollo.GetString("FloatText_RestXPGained"), nAmount)
		tContent.nRested = nAmount
	else
		tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
		strFormatted = String_GetWeaselString(Apollo.GetString("FloatText_XPGained"), nAmount)
		tContent.nNormal = nAmount
	end

	self:RequestShowTextFloater(eMessageType, unitToAttachTo, strFormatted, tTextOption, fDelay, tContent)
end

function CombatText:OnElderPointsGained(nAmount, nRested)
	if not Apollo.GetConsoleVariable("ui.showCombatFloater") or nAmount < 0 then
		return
	end

	local tContent = {}
	tContent.eType = LuaEnumMessageType.XPAwarded
	tContent.nNormal = nAmount
	tContent.nRested = 0

	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 0.8
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Back
	tTextOption.fOffset = 4.0 -- GOTCHA: Different
	tTextOption.fOffsetDirection = 90
	tTextOption.strFontFace = "CRB_FloaterSmall"
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,			fAlpha = 0,		fVelocityDirection = 90,	fVelocityMagnitude = 5,		fScale = 0.8},
		[2] = {fTime = 0.15,		fAlpha = 1.0,	fVelocityDirection = 90,	fVelocityMagnitude = .2,},
		[3] = {fTime = 0.5,	},
		[4] = {fTime = 1.0,	},
		[5] = {fTime = 1.1,			fAlpha = 1.0,	fVelocityDirection 	= 90,	fVelocityMagnitude 	= 5,},
		[6] = {fTime = 1.3,			fAlpha 	= 0.0,},
	}

	local eMessageType = LuaEnumMessageType.XPAwarded
	local unitToAttachTo = GameLib.GetControlledUnit()
	-- Base EP Floater
	local strFormatted = String_GetWeaselString(Apollo.GetString("FloatText_EPGained"), nAmount)
	self:RequestShowTextFloater(eMessageType, unitToAttachTo, strFormatted, tTextOption, 0, tContent)
	-- Rested EP Floater
	strFormatted = String_GetWeaselString(Apollo.GetString("FloatText_RestEPGained"), nRested)
	self:RequestShowTextFloater(eMessageType, unitToAttachTo, strFormatted, tTextOption, 0, tContent)
end

function CombatText:OnPathExperienceGained( nAmount, strText )
	if not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return
	end

	local eMessageType = LuaEnumMessageType.PathXp
	local unitToAttachTo = GameLib.GetControlledUnit()
	local strFormatted = String_GetWeaselString(Apollo.GetString("FloatText_PathXP"), nAmount)

	local tContent =
	{
		eType = LuaEnumMessageType.PathXp,
		nAmount = nAmount,
	}

	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 0.8
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Back
	tTextOption.fOffset = 4.0 -- GOTCHA: Different
	tTextOption.fOffsetDirection = 90
	tTextOption.strFontFace = "CRB_FloaterSmall"
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,			fAlpha = 0,		fVelocityDirection = 90,	fVelocityMagnitude = 5,		fScale = 0.8},
		[2] = {fTime = 0.15,		fAlpha = 1.0,	fVelocityDirection = 90,	fVelocityMagnitude = .2,},
		[3] = {fTime = 0.5,	},
		[4] = {fTime = 1.0,	},
		[5] = {fTime = 1.1,			fAlpha = 1.0,	fVelocityDirection 	= 90,	fVelocityMagnitude 	= 5,},
		[6] = {fTime = 1.3,			fAlpha 	= 0.0,},
	}

	local unitToAttachTo = GameLib.GetControlledUnit() -- make unitToAttachTo to controlled unit because with the message system,
	self:RequestShowTextFloater( eMessageType, unitToAttachTo, strFormatted, tTextOption, 0, tContent )
end

---------------------------------------------------------------------------------------------------
function CombatText:OnFactionFloater(unitTarget, strMessage, nAmount, strFactionName, idFaction) -- Reputation Floater
	if not Apollo.GetConsoleVariable("ui.showCombatFloater") or strFactionName == nil or nAmount < 1 then
		return
	end

	local eMessageType = LuaEnumMessageType.ReputationIncrease
	local unitToAttachTo = unitTarget or GameLib.GetControlledUnit()
	local strFormatted = String_GetWeaselString(Apollo.GetString("FloatText_Rep"), nAmount, strFactionName)

	local tContent = {}
	tContent.eType = LuaEnumMessageType.ReputationIncrease
	tContent.nAmount = nAmount
	tContent.idFaction = idFaction
	tContent.strName = strFactionName

	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 0.8
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Back
	tTextOption.fOffset = 5.0 -- GOTCHA: Extra Different
	tTextOption.fOffsetDirection = 90
	tTextOption.strFontFace = "CRB_FloaterSmall"
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,			fAlpha = 0,		fVelocityDirection = 90,	fVelocityMagnitude = 5,		fScale = 0.8},
		[2] = {fTime = 0.15,		fAlpha = 1.0,	fVelocityDirection = 90,	fVelocityMagnitude = .2,},
		[3] = {fTime = 0.5,	},
		[4] = {fTime = 1.0,	},
		[5] = {fTime = 1.1,			fAlpha = 1.0,	fVelocityDirection 	= 90,	fVelocityMagnitude 	= 5,},
		[6] = {fTime = 1.3,			fAlpha 	= 0.0,},
	}

	self:RequestShowTextFloater(eMessageType, GameLib.GetControlledUnit(), strFormatted, tTextOption, 0, tContent)
end

---------------------------------------------------------------------------------------------------
function CombatText:OnLootedMoney(monLooted) -- karCurrencyTypeToString filters to most alternate currencies but Money. Money displays in LootNotificationWindow.
	if not monLooted then
		return
	end

	local arCurrencyTypeToString =
	{
		[Money.CodeEnumCurrencyType.Renown] 			= "CRB_Renown",
		[Money.CodeEnumCurrencyType.ElderGems] 			= "CRB_Elder_Gems",
		[Money.CodeEnumCurrencyType.Prestige] 			= "CRB_Prestige",
		[Money.CodeEnumCurrencyType.CraftingVouchers]	= "CRB_Crafting_Vouchers",
	}

	local strCurrencyType = arCurrencyTypeToString[monLooted:GetMoneyType()] or ""
	if strCurrencyType == "" then
		return
	else
		strCurrencyType = Apollo.GetString(strCurrencyType)
	end

	-- TODO
	local eMessageType = LuaEnumMessageType.AlternateCurrency
	local strFormatted = String_GetWeaselString(Apollo.GetString("FloatText_AlternateMoney"), monLooted:GetAmount(), strCurrencyType)

	local tTextOption = self:GetDefaultTextOption()
	tTextOption.fScale = 1.0
	tTextOption.fDuration = 2
	tTextOption.strFontFace = "CRB_FloaterSmall"
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Bottom
	tTextOption.fOffset = -1
	tTextOption.fOffsetDirection = 0
	tTextOption.arFrames =
	{
		[1] = {fScale = 0.8,	fTime = 0,		fAlpha = 0.0,	fVelocityDirection = 0,		fVelocityMagnitude = 0,	},
		[2] = {fScale = 0.8,	fTime = 0.1,	fAlpha = 1.0,	fVelocityDirection = 0,		fVelocityMagnitude = 0,	},
		[3] = {fScale = 0.8,	fTime = 0.5,	fAlpha = 1.0,														},
		[4] = {					fTime = 1,		fAlpha = 1.0,	fVelocityDirection = 180,	fVelocityMagnitude = 3,	},
		[5] = {					fTime = 1.5,	fAlpha = 0.0,	fVelocityDirection = 180,							},
	}

	local tContent =
	{
		eType = LuaEnumMessageType.AlternateCurrency,
		nAmount = monLooted:GetAmount(),
	}

	self:RequestShowTextFloater(eMessageType, GameLib.GetControlledUnit(), strFormatted, tTextOption, 0, tContent)
end

---------------------------------------------------------------------------------------------------
function CombatText:OnTradeSkillFloater(unitTarget, strMessage)
	if not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return
	end

	local eMessageType = LuaEnumMessageType.TradeskillXp
	local tTextOption = self:GetDefaultTextOption()
	local unitToAttachTo = GameLib.GetControlledUnit()

	-- XP Defaults
	tTextOption.fScale = 1.0
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Horizontal
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Top
	tTextOption.fOffset = -0.3
	tTextOption.fOffsetDirection = 0

	tTextOption.nColor = 0xffff80
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical --Horizontal  --IgnoreCollision
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Top
	tTextOption.fOffset = -0.3
	tTextOption.fOffsetDirection = 0

	-- scale and movement
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,	fScale = 1.0,	fAlpha = 0.0,},
		[2] = {fTime = 0.1,	fScale = 0.7,	fAlpha = 0.8,},
		[3] = {fTime = 0.9,	fScale = 0.7,	fAlpha = 0.8,	fVelocityDirection = 0,},
		[4] = {fTime = 1.0,	fScale = 1.0,	fAlpha = 0.0,	fVelocityDirection = 0,},
	}


	local unitToAttachTo = GameLib.GetControlledUnit()
	self:RequestShowTextFloater( eMessageType, unitToAttachTo, strMessage, tTextOption, 0 )
end

---------------------------------------------------------------------------------------------------
function CombatText:OnMiss( unitCaster, unitTarget, eMissType )
	if unitTarget == nil or not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return
	end

	-- modify the text to be shown
	local tTextOption = self:GetDefaultTextOption()
	if GameLib.IsControlledUnit( unitTarget ) or unitTarget:GetType() == "Mount" then -- if the target unit is player's char
		tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Horizontal --Vertical--Horizontal  --IgnoreCollision
		tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
		tTextOption.nColor = 0xbaeffb
		tTextOption.fOffset = -0.6
		tTextOption.fOffsetDirection = 0
		tTextOption.arFrames =
		{
			[1] = {fScale = 1.0,	fTime = 0,						fVelocityDirection = 0,		fVelocityMagnitude = 0,},
			[2] = {fScale = 0.6,	fTime = 0.05,	fAlpha = 1.0,},
			[3] = {fScale = 0.6,	fTime = .2,		fAlpha = 1.0,	fVelocityDirection = 180,	fVelocityMagnitude = 3,},
			[4] = {fScale = 0.6,	fTime = .45,	fAlpha = 0.2,	fVelocityDirection = 180,},
		}
	else

		tTextOption.fScale = 1.0
		tTextOption.fDuration = 2
		tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision --Horizontal
		tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
		tTextOption.fOffset = -0.8
		tTextOption.fOffsetDirection = 0
		tTextOption.arFrames =
		{
			[1] = {fScale = 1.1,	fTime = 0,		fAlpha = 1.0,	nColor = 0xb0b0b0,},
			[2] = {fScale = 0.7,	fTime = 0.1,	fAlpha = 1.0,},
			[3] = {					fTime = 0.3,	},
			[4] = {fScale = 0.7,	fTime = 0.8,	fAlpha = 1.0,},
			[5] = {					fTime = 0.9,	fAlpha = 0.0,},
		}
	end

	-- display the text
	local strText = (eMissType == GameLib.CodeEnumMissType.Dodge) and Apollo.GetString("CRB_Dodged") or Apollo.GetString("CRB_Blocked")
	CombatFloater.ShowTextFloater( unitTarget, strText, tTextOption )
end

---------------------------------------------------------------------------------------------------
function CombatText:OnDamageOrHealing( unitCaster, unitTarget, eDamageType, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical )
	if unitTarget == nil or not Apollo.GetConsoleVariable("ui.showCombatFloater") or nDamage == nil then
		return
	end


	if GameLib.IsControlledUnit(unitTarget) or unitTarget == GameLib.GetPlayerMountUnit() or GameLib.IsControlledUnit(unitTarget:GetUnitOwner()) then
		self:OnPlayerDamageOrHealing( unitTarget, eDamageType, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical )
		return
	end

	-- NOTE: This needs to be changed if we're ever planning to display shield and normal damage in different formats.
	-- NOTE: Right now, we're just telling the player the amount of damage they did and not the specific type to keep things neat
	local nTotalDamage = nDamage
	if type(nShieldDamaged) == "number" and nShieldDamaged > 0 then
		nTotalDamage = nDamage + nShieldDamaged
	end

	local tTextOption = self:GetDefaultTextOption()
	local tTextOptionAbsorb = self:GetDefaultTextOption()

	if type(nAbsorptionAmount) == "number" and nAbsorptionAmount > 0 then --absorption is its own separate type
		tTextOptionAbsorb.fScale = 1.0
		tTextOptionAbsorb.fDuration = 2
		tTextOptionAbsorb.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.IgnoreCollision --Horizontal
		tTextOptionAbsorb.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
		tTextOptionAbsorb.fOffset = -0.8
		tTextOptionAbsorb.fOffsetDirection = 0
		tTextOptionAbsorb.arFrames={}

		tTextOptionAbsorb.arFrames =
		{
			[1] = {fScale = 1,	fTime = 0,		fAlpha = 1.0,	nColor = 0xb0b0b0,},
			[2] = {fScale = 0.7,	fTime = 0.1,	fAlpha = 1.0,},
			[3] = {					fTime = 0.3,	},
			[4] = {fScale = 0.7,	fTime = 0.8,	fAlpha = 1.0,},
			[5] = {					fTime = 0.9,	fAlpha = 0.0,},
		}
	end

	local bHeal = eDamageType == GameLib.CodeEnumDamageType.Heal or eDamageType == GameLib.CodeEnumDamageType.HealShields
	local nBaseColor = 0xCC6600--settings.odb.color--0xCC6600--settings.odb.color --0xfffb93
	local fMaxSize = 1
	local nOffsetDirection = 150
	local fMaxDuration = 0.7
	local alpha = 1.0
	local flashsize = 1

	if eDamageType == GameLib.CodeEnumDamageType.Heal then -- healing
		nBaseColor = settings.ohb.color
		fMaxSize = settings.ohb.fontscale
		tTextOption.strFontFace = settings.ohb.fontstyle
		alpha = settings.ohb.alpha
		if bCritical then
			nBaseColor = settings.ohc.color
			fMaxSize = settings.ohc.fontscale
			tTextOption.strFontFace = settings.ohc.fontstyle
			alpha = settings.ohc.alpha
			flashsize = 1.25
		end
	
	elseif eDamageType == GameLib.CodeEnumDamageType.HealShields then
		nBaseColor = bCritical and 0xc9fffb or 0x6afff3
		fMaxSize = bCritical and 0.9 or 0.7
	elseif (unitTarget:IsInCCState(Unit.CodeEnumCCState.Vulnerability) or eDamageType == knTestingVulnerable ) then --MoO Damage
		nBaseColor = settings.moo.color
		fMaxSize = settings.moo.fontscale 
		tTextOption.strFontFace = settings.moo.fontstyle
		alpha = settings.moo.alpha
		flashsize = 1.25
	else --normal damage done
		nBaseColor = settings.odb.color
		fMaxSize = settings.odb.fontscale 
		tTextOption.strFontFace = settings.odb.fontstyle
		alpha = settings.odb.alpha
		flashsize = 1
		if bCritical then
			nBaseColor = settings.odc.color
			fMaxSize = settings.odb.fontscale 
			tTextOption.strFontFace = settings.odb.fontstyle
			alpha = settings.odc.alpha
			flashsize = 1.25
		end
	end
	
	--[[
	if not bHeal and bCritical == true then -- Crit not vuln
		nBaseColor = settings.odc.color --0xfffb93--0xCC6600 --settings.odc.color
		fMaxSize = settings.odc.fontscale
		tTextOption.strFontFace = settings.odc.fontstyle
		alpha = settings.odc.alpha
		flashsize = 1.5
	elseif not bHeal and (unitTarget:IsInCCState( Unit.CodeEnumCCState.Vulnerability ) or eDamageType == knTestingVulnerable ) then -- vuln not crit
		nBaseColor = 0xf5a2ff --settings.general.moocolor --0xf5a2ff
	else -- normal damage
		if eDamageType == GameLib.CodeEnumDamageType.Heal then -- healing params
			nBaseColor = bCritical and 0xcdffa0 or 0xb0ff6a
			fMaxSize = bCritical and 0.9 or 0.7
			alpha = settings.ohb.alpha
			tTextOption.strFontFace = settings.ohb.fontstyle

		elseif eDamageType == GameLib.CodeEnumDamageType.HealShields then -- healing shields params
			nBaseColor = bCritical and 0xc9fffb or 0x6afff3
			fMaxSize = bCritical and 0.9 or 0.7

		else -- regular target damage params
			nBaseColor = settings.odb.color --0xfffb93 --settings.ohb.color
			tTextOption.strFontFace = settings.odb.fontstyle
			alpha = settings.odb.alpha
			flashsize = 1
		end
	end
	]]

	-- determine offset direction; re-randomize if too close to the last
	local nOffset = math.random(0, 0)
	if nOffset <= (self.fLastOffset + 75) and nOffset >= (self.fLastOffset - 75) then
		nOffset = math.random(0, 0)
	end
	self.fLastOffset = nOffset
	-- set offset
	tTextOption.fOffsetDirection = nOffset
	tTextOption.fOffset = math.random(10, 30)/100
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Horizontal
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Top

	-- scale and movement
	-- different stages
	--[[
	tTextOption.arFrames =
	{
		[1] = {fScale = (fMaxSize) * 1.75,	fTime = 0,									nColor = nBaseColor,},
		[2] = {fScale = fMaxSize,			fTime = .15,			fAlpha = alpha,},		--nColor = nBaseColor,},
		[3] = {fScale = fMaxSize,			fTime = .3,									nColor = nBaseColor,},
		[4] = {fScale = fMaxSize,			fTime = .5,				fAlpha = alpha,},
		[5] = {								fTime = fMaxDuration,	fAlpha = 0.0,},
	}
	]]
	nStallTime = .4
	tTextOption.arFrames =
	{
	[1] = {fScale = fMaxSize * flashsize,			fTime = 0,						fAlpha = alpha,		nColor = nBaseColor,	fVelocityDirection = 0,		fVelocityMagnitude = 0,},
	[2] = {fScale = fMaxSize * flashsize,			fTime = 0.1,										nColor = nBaseColor,	fVelocityDirection = 0,		fVelocityMagnitude = .5,},
	[3] = {fScale = fMaxSize,						fTime = 0.3,					fAlpha = alpha,		nColor = nBaseColor,	fVelocityDirection = 0,		fVelocityMagnitude = 2,},
	[4] = {											fTime = 0.5 + nStallTime,		fAlpha = alpha*.75,							fVelocityDirection = 0,		fVelocityMagnitude = 5,},
	[5] = {											fTime = 0.0 + fMaxDuration,		fAlpha = 0.0,								fVelocityDirection = 0,		fVelocityMagnitude = 7,},
	}
	if not bHeal then
		self.fLastDamageTime = GameLib.GetGameTime()
	end

	if type(nAbsorptionAmount) == "number" and nAbsorptionAmount > 0 then -- secondary "if" so we don't see absorption and "0"
		CombatFloater.ShowTextFloater( unitTarget, String_GetWeaselString(Apollo.GetString("FloatText_Absorbed"), nAbsorptionAmount), tTextOptionAbsorb )

		if nTotalDamage > 0 then
			tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical
			if bHeal then
				CombatFloater.ShowTextFloater( unitTarget, String_GetWeaselString(Apollo.GetString("FloatText_PlusValue"), nTotalDamage), tTextOption )
			else
				CombatFloater.ShowTextFloater( unitTarget, nTotalDamage, tTextOption )
			end
		end
	elseif bHeal then
		CombatFloater.ShowTextFloater( unitTarget, String_GetWeaselString(Apollo.GetString("FloatText_PlusValue"), nTotalDamage), tTextOption ) -- we show "0" when there's no absorption
	else
		CombatFloater.ShowTextFloater( unitTarget, nTotalDamage, tTextOption )
	end
end

------------------------------------------------------------------
function CombatText:OnPlayerDamageOrHealing(unitPlayer, eDamageType, nDamage, nShieldDamaged, nAbsorptionAmount, bCritical)
	if unitPlayer == nil or not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return
	end

	-- If there is no damage, don't show a floater
	if nDamage == nil then
		return
	end

	local bShowFloater = true
	local tTextOption = self:GetDefaultTextOption()
	local tTextOptionAbsorb = self:GetDefaultTextOption()

	tTextOption.arFrames = {}
	tTextOptionAbsorb.arFrames = {}

	local nStallTime = .3

	if type(nAbsorptionAmount) == "number" and nAbsorptionAmount > 0 then --absorption is its own separate type
		tTextOptionAbsorb.nColor = 0xf8f3d7
		tTextOptionAbsorb.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Horizontal --Vertical--Horizontal  --IgnoreCollision
		tTextOptionAbsorb.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
		tTextOptionAbsorb.fOffset = -0.4
		tTextOptionAbsorb.fOffsetDirection = 0--125

		-- scale and movement
		tTextOptionAbsorb.arFrames =
		{
			[1] = {fScale = 1.1,	fTime = 0,									fVelocityDirection = 0,		fVelocityMagnitude = 0,},
			[2] = {fScale = 0.7,	fTime = 0.05,				fAlpha = 1.0,},
			[3] = {fScale = 0.7,	fTime = .2 + nStallTime,	fAlpha = 1.0,	fVelocityDirection = 180,	fVelocityMagnitude = 3,},
			[4] = {fScale = 0.7,	fTime = .45 + nStallTime,	fAlpha = 0.2,	fVelocityDirection = 180,},
		}
	end

	if type(nShieldDamaged) == "number" and nShieldDamaged > 0 then
		nDamage = nDamage + nShieldDamaged
	end

	local bHeal = eDamageType == GameLib.CodeEnumDamageType.Heal or eDamageType == GameLib.CodeEnumDamageType.HealShields
	local nBaseColor = settings.idb.color
	local nHighlightColor = settings.idb.color
	local flashsize = 1
	local alpha = 1
	local fMaxSize = settings.idb.fontscale
	local nOffsetDirection = 0
	local fOffsetAmount = -0.6
	local fMaxDuration = .55
	local eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Horizontal

	tTextOption.strFontFace = settings.odb.fontstyle
		
	if eDamageType == GameLib.CodeEnumDamageType.Heal then -- healing params
		nBaseColor = settings.ihb.color
		nHighlightColor = settings.ihb.color
		alpha = settings.ihb.alpha
		fOffsetAmount = -0.5

		if bCritical then
			fMaxSize = settings.ihc.fontscale
			nBaseColor = settings.ihc.color
			nHighlightColor = settings.ihc.color
			alpha = settings.ihc.alpha
			tTextOption.strFontFace = settings.ihc.fontstyle
			fMaxDuration = .75
		end

	elseif eDamageType == GameLib.CodeEnumDamageType.HealShields then -- healing shields params
		nBaseColor = 0x6afff3
		fOffsetAmount = -0.5
		nHighlightColor = 0x6afff3

		if bCritical then
			fMaxSize = 1.25
			nBaseColor = 0xa6fff8
			nHighlightColor = 0xFFFFFF
			fMaxDuration = .75
		end

	else -- regular old damage (player)
		fOffsetAmount = -0.5

		if bCritical then
			fMaxSize = settings.idc.fontscale
			nBaseColor = settings.idc.color
			nHighlightColor = settings.idc.color
			alpha = settings.idc.alpha
			tTextOption.strFontFace = settings.idc.fontstyle
			fMaxDuration = .75
		end
	end

	tTextOptionAbsorb.fOffset = fOffsetAmount
	tTextOption.eCollisionMode = eCollisionMode
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest

	-- scale and movement
	tTextOption.arFrames =
	{
		[1] = {fScale = fMaxSize * flashsize,	fTime = 0,					fAlpha = alpha,	nColor = nHighlightColor,	fVelocityDirection = 0,		fVelocityMagnitude = 0,},
		[2] = {fScale = fMaxSize * flashsize,	fTime = 0.05,				fAlpha = alpha,	nColor = nHighlightColor,	fVelocityDirection = 0,		fVelocityMagnitude = 0,},
		[3] = {fScale = fMaxSize,		fTime = 0.1,				fAlpha = alpha,	nColor = nBaseColor,},
		[4] = {							fTime = 0.3 + nStallTime,	fAlpha = alpha,								fVelocityDirection = 180,		fVelocityMagnitude = 3,},
		[5] = {							fTime = 0.65 + nStallTime,	fAlpha = 0.2,								fVelocityDirection = 180,},
	}

	if type(nAbsorptionAmount) == "number" and nAbsorptionAmount > 0 then -- secondary "if" so we don't see absorption and "0"
		CombatFloater.ShowTextFloater( unitPlayer, String_GetWeaselString(Apollo.GetString("FloatText_Absorbed"), nAbsorptionAmount), tTextOptionAbsorb )
	end

	if nDamage > 0 and bHeal then
		CombatFloater.ShowTextFloater( unitPlayer, String_GetWeaselString(Apollo.GetString("FloatText_PlusValue"), nDamage), tTextOption )
	elseif nDamage > 0 then
		CombatFloater.ShowTextFloater( unitPlayer, nDamage, tTextOption )
	end
end

------------------------------------------------------------------
function CombatText:OnCombatLogCCState(tEventArgs)
	if not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return
	end

	-- removal of a CC state does not display floater text
	if tEventArgs.bRemoved or tEventArgs.bHideFloater then
		return
	end

	local nOffsetState = tEventArgs.eState
	if tEventArgs.eResult == nil then
		return
	end -- totally invalid

	if GameLib.IsControlledUnit( tEventArgs.unitTarget ) then
		-- Route to the player function
		self:OnCombatLogCCStatePlayer(tEventArgs)
		return
	end

	local arCCFormat =  --Removing an entry from this table means no floater is shown for that state.
	{
		[Unit.CodeEnumCCState.Stun] 			= 0xffe691, -- stun
		[Unit.CodeEnumCCState.Sleep] 			= 0xffe691, -- sleep
		[Unit.CodeEnumCCState.Root] 			= 0xffe691, -- root
		[Unit.CodeEnumCCState.Disarm] 			= 0xffe691, -- disarm
		[Unit.CodeEnumCCState.Silence] 			= 0xffe691, -- silence
		[Unit.CodeEnumCCState.Polymorph] 		= 0xffe691, -- polymorph
		[Unit.CodeEnumCCState.Fear] 			= 0xffe691, -- fear
		[Unit.CodeEnumCCState.Hold] 			= 0xffe691, -- hold
		[Unit.CodeEnumCCState.Knockdown] 		= 0xffe691, -- knockdown
		[Unit.CodeEnumCCState.Disorient] 		= 0xffe691,
		[Unit.CodeEnumCCState.Disable] 			= 0xffe691,
		[Unit.CodeEnumCCState.Taunt] 			= 0xffe691,
		[Unit.CodeEnumCCState.DeTaunt] 			= 0xffe691,
		[Unit.CodeEnumCCState.Blind] 			= 0xffe691,
		[Unit.CodeEnumCCState.Knockback] 		= 0xffe691,
		[Unit.CodeEnumCCState.Pushback ] 		= 0xffe691,
		[Unit.CodeEnumCCState.Pull] 			= 0xffe691,
		[Unit.CodeEnumCCState.PositionSwitch] 	= 0xffe691,
		[Unit.CodeEnumCCState.Tether] 			= 0xffe691,
		[Unit.CodeEnumCCState.Snare] 			= 0xffe691,
		[Unit.CodeEnumCCState.Interrupt] 		= 0xffe691,
		[Unit.CodeEnumCCState.Daze] 			= 0xffe691,
		[Unit.CodeEnumCCState.Subdue] 			= 0xffe691,
	}

	local tTextOption = self:GetDefaultTextOption()
	local strMessage = ""

	tTextOption.fScale = 1.0
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Vertical --IgnoreCollision --Horizontal
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
	tTextOption.fOffset = -0.8
	tTextOption.fOffsetDirection = 0
	tTextOption.arFrames={}

	local bUseCCFormat = false -- use CC formatting vs. message formatting

	if tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Ok then -- CC applied
		strMessage = tEventArgs.strState
		if arCCFormat[nOffsetState] ~= nil then -- make sure it's one we want to show
			bUseCCFormat = true
		else
			return
		end
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_Immune then
		strMessage = Apollo.GetString("FloatText_Immune")
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_InfiniteInterruptArmor then
		strMessage = Apollo.GetString("FloatText_InfInterruptArmor")
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_InterruptArmorReduced then -- use with interruptArmorHit
		strMessage = String_GetWeaselString(Apollo.GetString("FloatText_InterruptArmor"), tEventArgs.nInterruptArmorHit)
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.DiminishingReturns_TriggerCap and tEventArgs.strTriggerCapCategory ~= nil then
		strMessage = Apollo.GetString("FloatText_CC_DiminishingReturns_TriggerCap").." "..tEventArgs.strTriggerCapCategory
	else -- all invalid messages
		return
	end

	if not bUseCCFormat then -- CC didn't take
		tTextOption.nColor = 0xb0b0b0

		tTextOption.arFrames =
		{
			[1] = {fScale = 1.0,	fTime = 0,		fAlpha = 0.0},
			[2] = {fScale = 0.7,	fTime = 0.1,	fAlpha = 0.8},
			[3] = {fScale = 0.7,	fTime = 0.9,	fAlpha = 0.8,	fVelocityDirection = 0},
			[4] = {fScale = 1.0,	fTime = 1.0,	fAlpha = 0.0,	fVelocityDirection = 0},
		}
	else -- CC applied
		tTextOption.arFrames =
		{
			[1] = {fScale = 2.0,	fTime = 0,		fAlpha = 1.0,	nColor = 0xFFFFFF,},
			[2] = {fScale = 0.7,	fTime = 0.15,	fAlpha = 1.0,},
			[3] = {					fTime = 0.5,					nColor = arCCFormat[nOffsetState],},
			[4] = {fScale = 0.7,	fTime = 1.1,	fAlpha = 1.0,										fVelocityDirection = 0,	fVelocityMagnitude = 5,},
			[5] = {					fTime = 1.3,	fAlpha = 0.0,										fVelocityDirection = 0,},
		}
	end

	CombatFloater.ShowTextFloater( tEventArgs.unitTarget, strMessage, tTextOption )
end

------------------------------------------------------------------
function CombatText:OnCombatLogCCStatePlayer(tEventArgs)
	if not Apollo.GetConsoleVariable("ui.showCombatFloater") then
		return
	end

	-- removal of a CC state does not display floater text
	if tEventArgs.bRemoved or tEventArgs.bHideFloater then
		return
	end

	local arCCFormatPlayer =
    --Removing an entry from this table means no floater is shown for that state.
	{
		[Unit.CodeEnumCCState.Stun] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Sleep] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Root] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Disarm] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Silence] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Polymorph] 		= 0xff2b2b,
		[Unit.CodeEnumCCState.Fear] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Hold] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Knockdown] 		= 0xff2b2b,
		[Unit.CodeEnumCCState.Disorient] 		= 0xff2b2b,
		[Unit.CodeEnumCCState.Disable] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Taunt] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.DeTaunt] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Blind] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Knockback] 		= 0xff2b2b,
		[Unit.CodeEnumCCState.Pushback] 		= 0xff2b2b,
		[Unit.CodeEnumCCState.Pull] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.PositionSwitch] 	= 0xff2b2b,
		[Unit.CodeEnumCCState.Tether] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Snare] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Interrupt] 		= 0xff2b2b,
		[Unit.CodeEnumCCState.Daze] 			= 0xff2b2b,
		[Unit.CodeEnumCCState.Subdue] 			= 0xff2b2b,
	}

	local nOffsetState = tEventArgs.eState

	local tTextOption = self:GetDefaultTextOption()
	local strMessage = ""

	tTextOption.fScale = 1.0
	tTextOption.fDuration = 2
	tTextOption.eCollisionMode = CombatFloater.CodeEnumFloaterCollisionMode.Horizontal
	tTextOption.eLocation = CombatFloater.CodeEnumFloaterLocation.Chest
	tTextOption.fOffset = -0.2
	tTextOption.fOffsetDirection = 0
	tTextOption.arFrames={}

	local bUseCCFormat = false -- use CC formatting vs. message formatting

	if tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Ok then -- CC applied
		strMessage = tEventArgs.strState
		if arCCFormatPlayer[nOffsetState] ~= nil then -- make sure it's one we want to show
			bUseCCFormat = true
		else
			return
		end
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_Immune then
		strMessage = Apollo.GetString("FloatText_Immune")
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_InfiniteInterruptArmor then
		strMessage = Apollo.GetString("FloatText_InfInterruptArmor")
	elseif tEventArgs.eResult == CombatFloater.CodeEnumCCStateApplyRulesResult.Target_InterruptArmorReduced then -- use with interruptArmorHit
		strMessage = String_GetWeaselString(Apollo.GetString("FloatText_InterruptArmor"), tEventArgs.nInterruptArmorHit)
	else -- all invalid messages
		return
	end

	if not bUseCCFormat then -- CC didn't take
		tTextOption.nColor = 0xd8f8f8
		tTextOption.arFrames =
		{
			[1] = {fScale = 1.0,	fTime = 0,		fAlpha = 0.0,},
			[2] = {fScale = 0.7,	fTime = 0.1,	fAlpha = 0.8,},
			[3] = {fScale = 0.7,	fTime = 0.9,	fAlpha = 0.8,	fVelocityDirection = 180,	fVelocityMagnitude = 3,},
			[4] = {fScale = 0.7,	fTime = 1.0,	fAlpha = 0.0,	fVelocityDirection = 180,},
		}
	else -- CC applied
		tTextOption.nColor = arCCFormatPlayer[nOffsetState]
		tTextOption.arFrames =
		{
			[1] = {fScale = 1.1,	fTime = 0,		nColor = 0xFFFFFF,},
			[2] = {fScale = 0.7,	fTime = 0.05,	nColor = arCCFormatPlayer[nOffsetState],	fAlpha = 1.0,},
			[3]	= {					fTime = 0.35,	nColor = 0xFFFFFF,},
			[4] = {					fTime = 0.7,	nColor = arCCFormatPlayer[nOffsetState],},
			[5] = {					fTime = 1.05,	nColor = 0xFFFFFF,},
			[6] = {fScale = 0.7,	fTime = 1.4,	nColor = arCCFormatPlayer[nOffsetState],	fAlpha = 1.0,	fVelocityDirection = 180,	fVelocityMagnitude = 3,},
			[7] = {fScale = 0.7,	fTime = 1.55,												fAlpha = 0.2,	fVelocityDirection = 180,},
		}
	end

	CombatFloater.ShowTextFloater( tEventArgs.unitTarget, strMessage, tTextOption )
end

------------------------------------------------------------------
-- send show text request to message manager with a delay in milliseconds
function CombatText:RequestShowTextFloater( eMessageType, unitTarget, strText, tTextOption, fDelay, tContent ) -- addtn'l parameters for XP/rep
	local tParams =
	{
		unitTarget 	= unitTarget,
		strText 	= strText,
		tTextOption = TableUtil:Copy( tTextOption ),
		tContent 	= tContent,
	}

	if not fDelay or fDelay == 0 then -- just display if no delay
		Event_FireGenericEvent("Float_RequestShowTextFloater", eMessageType, tParams, tContent )
	else
		tParams.nTime = os.time() + fDelay
		tParams.eMessageType = eMessageType

		-- insert the text in the delayed queue in order of how fast they'll need to be shown
		local nInsert = 0
		for key, value in pairs(self.tDelayedFloatTextQueue:GetItems()) do
			if value.nTime > tParams.nTime then
				nInsert = key
				break
			end
		end
		if nInsert > 0 then
			self.tDelayedFloatTextQueue:InsertAbsolute( nInsert, tParams )
		else
			self.tDelayedFloatTextQueue:Push( tParams )
		end
		self.iTimerIndex = self.iTimerIndex + 1
		if self.iTimerIndex > 9999999 then
			self.iTimerIndex = 1
		end
		self.tTimerFloatText[self.iTimerIndex] = ApolloTimer.Create(fDelay, false, "OnDelayedFloatTextTimer", self)-- create the timer to show the text
	end
end


--function CombatText:RequestShowTextFloater( eMessageType, unitTarget, strText, tTextOption, fDelay, tContent ) -- addtn'l parameters for XP/rep
--[[
function CombatText:OnCombatLogTransference(tEventArgs)
	local bCritical = tEventArgs.eCombatResult == GameLib.CodeEnumCombatResult.Critical
	if tEventArgs.unitCaster == GameLib.GetControlledUnit() then -- Target does the transference to the source
		self:OnDamageOrHealing( tEventArgs.unitCaster, tEventArgs.unitTarget, tEventArgs.eDamageType, math.abs(tEventArgs.nDamageAmount), math.abs(tEventArgs.nShield), math.abs(tEventArgs.nAbsorption), bCritical )
	else -- creature taking damage
		self:OnPlayerDamageOrHealing( tEventArgs.unitTarget, tEventArgs.eDamageType, math.abs(tEventArgs.nDamageAmount), math.abs(tEventArgs.nShield), math.abs(tEventArgs.nAbsorption), bCritical )
	end
]]
function CombatText:OnShowFloatersClick( wndHandler, wndControl, eMouseButton )
	-- modify the text to be shown
	local tTextOption = self:GetDefaultTextOption()
	tTextOption.bUseScreenPos = true
	tTextOption.fOffset = -80
	tTextOption.nColor = 0xFFFFFF
	tTextOption.strFontFace = "CRB_Interface16_BO"
	tTextOption.bShowOnTop = true
	tTextOption.arFrames =
	{
		[1] = {fTime = 0,		fScale = 1.5,	fAlpha = 0.8,},
		[2] = {fTime = 0.1,		fScale = 1,	fAlpha = 0.8,},
		[3] = {fTime = 1.1,		fScale = 1,	fAlpha = 0.8,	fVelocityDirection = 0,},
		[4] = {fTime = 1.3,		fScale = 1,	fAlpha = 0.0,	fVelocityDirection = 0,},
	}
	
	messagetype = LuaEnumMessageType.SpellCastError
	unitSource = GameLib.GetControlledUnit()
	strMessage = "test"
	if self.bSpellErrorMessages then -- This is set by interface options
		self:RequestShowTextFloater(LuaEnumMessageType.SpellCastError, unitSource, strMessage, tTextOption)
	end
	nDamage = 10
	CombatFloater.ShowTextFloater( unitSource , nDamage, tTextOption )
end

---------------------------------------------------------------------------------------------------
-- OptionsListItem Functions
---------------------------------------------------------------------------------------------------
function CombatText:OnOptionsHomeClick( wndHandler, wndControl, eMouseButton )
	self:HideAllOptions()
	self.wndOptions:FindChild("ListControls"):DestroyChildren()
	
	self.wndOptions:FindChild("GoHome"):SetText("Home")
	for name, wndControls in pairsByKeys(self.tAddons) do
		local wndButton = Apollo.LoadForm(self.xmlDoc, "OptionsListItem", self.wndOptions:FindChild("ListControls"), self)
		wndButton:SetText(name)
	end
	
	self.wndOptions:FindChild("ListControls"):ArrangeChildrenVert()
	self:SetOptions()
		
end

function CombatText:OnOptionsCatClick( wndHandler, wndControl, eMouseButton )	
	--Get addon name
	local strAddon = wndControl:GetText()
	--Get other arguments (stored as window data)
	local tData = self.tAddons[strAddon]:GetData()
	--Check if its a single tiered option
	local bSingleTier = tData.bSingleTier
	-- sets title
	--self.wndOptions:FindChild("GoHome"):SetText(strAddon)

	if bSingleTier then
	--If single tiered
	------------------
		--Hide all options
		self:HideAllOptions()
		--Show options page
		self.tAddons[strAddon]:Show(true)
		for _, wndCurr in pairs(self.tAddons[strAddon]:GetChildren()) do
			wndCurr:Show(true)
		end
	else
		--If multi tiered
	-----------------
		--Hide all options
		self:HideAllOptions()
		--Destroy Nav List children (buttons)
		self.wndOptions:FindChild("ListControls"):DestroyChildren()
		--Show addon options
		self.tAddons[strAddon]:Show(true)
		--Get children
		local arChildren = self.tAddons[strAddon]:GetChildren()
		--New table to sort by name
		local tChildrenList = {}
		for _, wndCurr in pairs(arChildren) do
			local strName = wndCurr:FindChild("Title"):GetText()
			
			local wndName = wndCurr:GetName()
			--Print (wndName)
			--Print (submenudict[wndName])
			--Print (strAddon.." "..submenudict[wndName])
			
			tChildrenList[wndName ] = wndCurr
		end
		--Add buttons
		for wndName, wndCurr in pairsByKeys(tChildrenList) do
			--Load button window
			local wndButton = Apollo.LoadForm(self.xmlDoc, "OptionsListItem", self.wndOptions:FindChild("ListControls"), self)
			--Change OnClick function
			wndButton:RemoveEventHandler("ButtonUp")
			wndButton:AddEventHandler("ButtonUp", "OnAddonCatClick")
			--Set Properties
			wndButton:SetText(submenudict[wndName])
			wndButton:SetName(wndName)
			wndButton:SetData(strAddon)
			wndCurr:FindChild("Title"):SetText(strAddon.." "..submenudict[wndName])
		end
		--Arrange Vertical
		self.wndOptions:FindChild("ListControls"):ArrangeChildrenVert()
	end
end

function CombatText:OnAddonCatClick( wndHandler, wndControl, eMouseButton )
	--Get Addon name
	local strAddon = wndControl:GetData()
	
	--Show the correct window, hide the rest.
	for _, wndCurr in pairs(self.tAddons[strAddon]:GetChildren()) do
		if wndCurr:GetName() == wndControl:GetName() then
			--wndCurr:FindChild("Title"):SetText("awesome")
			wndCurr:Show(true)
		else
			wndCurr:Show(false)
		end
		--[[
		if wndCurr:FindChild("Title"):GetText() == wndControl:GetText() then
			wndCurr:Show(true)
		else
			wndCurr:Show(false)
		end
		]]
	end
end

------------------------------------------------------------------
function CombatText:OnDelayedFloatTextTimer()
	local tParams = self.tDelayedFloatTextQueue:Pop()
	Event_FireGenericEvent("Float_RequestShowTextFloater", tParams.eMessageType, tParams, tParams.tContent) -- TODO: Event!!!!
end

---------------------------------------------------------------------------------------------------
-- Controls Functions
---------------------------------------------------------------------------------------------------
--%%%%%%%%%%%%%%%%%
-- Create Dropdown
--%%%%%%%%%%%%%%%%%
local function CreateDropdownMenu(self, wndDropdown, tOptions, strEventHandler)
	--wndDropdown needs to be the whole window object i.e. containing the label, button, and box
	local wndDropdownButton = wndDropdown:FindChild("Dropdown")
	local wndDropdownBox = wndDropdown:FindChild("DropdownBox")
	
	if #wndDropdownBox:FindChild("ScrollList"):GetChildren() > 0 then
		return
	end	
	for name, value in pairs(tOptions) do
		local currButton = Apollo.LoadForm(self.xmlDoc, "DropdownItem", wndDropdownBox:FindChild("ScrollList"), self)
		currButton:SetText(name)
		currButton:SetData(value)
		currButton:AddEventHandler("ButtonUp", strEventHandler)
	end
		
	wndDropdownBox:FindChild("ScrollList"):ArrangeChildrenVert()
	
end

---------------------------------
--		Dropdown Options
---------------------------------

local tFontStyleOptions = {
	["Courier"] = "Courier",
	["CRB_FloaterGigantic_O"] = "CRB_FloaterGigantic_O",
	["CRB_FloaterGigantic"] = "CRB_FloaterGigantic",
	["CRB_FloaterHuge"] = "CRB_FloaterHuge",
	["CRB_FloaterLarge"] = "CRB_FloaterLarge",
	["CRB_HeaderLarge"] = "CRB_HeaderLarge",
	["CRB_FloaterMedium"] = "CRB_FloaterMedium",
	["CRB_InterfaceLarge"] = "CRB_InterfaceLarge",
	["CRB_FloaterSmall"] = "CRB_FloaterSmall",	
	["Courier"] = "Courier",
	["CRB_HeaderGigantic_O"] = "CRB_HeaderGigantic_O",

}

---------------------------------
--		Outgoing Damage Controls Base
---------------------------------

function CombatText:OnScaleEditBoxReturn_odb( wndHandler, wndControl, strText )
	wndControl:GetParent():FindChild("ScaleEditBox"):SetText(strText)
	settings.odb.fontscale = tonumber(strText)
end


function CombatText:OnFontStyleClick_odb( wndHandler, wndControl, eMouseButton )
	CreateDropdownMenu(self, wndControl:GetParent(), tFontStyleOptions, "OnFontStyleItemClick_odb")
	wndControl:GetParent():FindChild("DropdownBox"):Show(true)
end

function CombatText:OnFontStyleItemClick_odb(wndHandler, wndControl, eMouseButton)
	settings.odb.fontstyle = wndControl:GetText()
	wndControl:GetParent():GetParent():GetParent():FindChild("DropDown"):SetText(wndControl:GetText())
	wndControl:GetParent():GetParent():Show(false)
end

function CombatText:HasColorPicker()
	if ColorPicker then
		return true
	end
	Print ("To change colors you need to have the ColorPicker add-on installed.")
	return false
end

function UpdateBarColor_odb()
	OutWndRef:FindChild("DamageControlsBase"):FindChild("Color"):FindChild("Swatch"):SetBGColor(tcolor)
	settings.odb.color = tonumber(Convert_CColor_To_String(tcolor),16)
end

function CombatText:OnColorClick_odb( wndHandler, wndControl, eMouseButton )
	tcolor = Convert_String_To_CColor(tostring(dec2hex(settings.odb.color)))
	if self:HasColorPicker() then
		ColorPicker.AdjustCColor(tcolor, false, UpdateBarColor_odb)
	end
end


function CombatText:OnOpacityChange_odb( wndHandler, wndControl, fNewValue, fOldValue )
	local value = round(fNewValue, 1)
	wndControl:GetParent():FindChild("EditBox"):SetText(value)
	settings.odb.alpha = value
end

---------------------------------
--		Outgoing Damage Controls Crit
---------------------------------

function CombatText:OnScaleEditBoxReturn_odc( wndHandler, wndControl, strText )
	wndControl:GetParent():FindChild("ScaleEditBox"):SetText(strText)
	settings.odc.fontscale = tonumber(strText)
end


function CombatText:OnFontStyleClick_odc( wndHandler, wndControl, eMouseButton )
	CreateDropdownMenu(self, wndControl:GetParent(), tFontStyleOptions, "OnFontStyleItemClick_odc")
	wndControl:GetParent():FindChild("DropdownBox"):Show(true)
end

function CombatText:OnFontStyleItemClick_odc(wndHandler, wndControl, eMouseButton)
	settings.odc.fontstyle = wndControl:GetText()
	wndControl:GetParent():GetParent():GetParent():FindChild("DropDown"):SetText(wndControl:GetText())
	wndControl:GetParent():GetParent():Show(false)
end

function CombatText:HasColorPicker()
	if ColorPicker then
		return true
	end
	Print ("To change colors you need to have the ColorPicker add-on installed.")
	return false
end

function UpdateBarColor_odc()
	OutWndRef:FindChild("DamageControlsCrit"):FindChild("Color"):FindChild("Swatch"):SetBGColor(tcolor)
	settings.odc.color = tonumber(Convert_CColor_To_String(tcolor),16)
end

function CombatText:OnColorClick_odc( wndHandler, wndControl, eMouseButton )
	tcolor = Convert_String_To_CColor(tostring(dec2hex(settings.odc.color)))
	if self:HasColorPicker() then
		ColorPicker.AdjustCColor(tcolor, false, UpdateBarColor_odc)
	end
end


function CombatText:OnOpacityChange_odc( wndHandler, wndControl, fNewValue, fOldValue )
	local value = round(fNewValue, 1)
	wndControl:GetParent():FindChild("EditBox"):SetText(value)
	settings.odc.alpha = value
end

---------------------------------
--		Moment of Oppurtunity Controls
---------------------------------

function CombatText:OnScaleEditBoxReturn_moo( wndHandler, wndControl, strText )
	wndControl:GetParent():FindChild("ScaleEditBox"):SetText(strText)
	settings.moo.fontscale = tonumber(strText)
end


function CombatText:OnFontStyleClick_moo( wndHandler, wndControl, eMouseButton )
	CreateDropdownMenu(self, wndControl:GetParent(), tFontStyleOptions, "OnFontStyleItemClick_moo")
	wndControl:GetParent():FindChild("DropdownBox"):Show(true)
end

function CombatText:OnFontStyleItemClick_moo(wndHandler, wndControl, eMouseButton)
	settings.moo.fontstyle = wndControl:GetText()
	wndControl:GetParent():GetParent():GetParent():FindChild("DropDown"):SetText(wndControl:GetText())
	wndControl:GetParent():GetParent():Show(false)
end

function CombatText:HasColorPicker()
	if ColorPicker then
		return true
	end
	Print ("To change colors you need to have the ColorPicker add-on installed.")
	return false
end

function UpdateBarColor_moo()
	OutWndRef:FindChild("MoOControls"):FindChild("Color"):FindChild("Swatch"):SetBGColor(tcolor)
	settings.moo.color = tonumber(Convert_CColor_To_String(tcolor),16)
end

function CombatText:OnColorClick_moo( wndHandler, wndControl, eMouseButton )
	tcolor = Convert_String_To_CColor(tostring(dec2hex(settings.moo.color)))
	if self:HasColorPicker() then
		ColorPicker.AdjustCColor(tcolor, false, UpdateBarColor_moo)
	end
end


function CombatText:OnOpacityChange_moo( wndHandler, wndControl, fNewValue, fOldValue )
	local value = round(fNewValue, 1)
	wndControl:GetParent():FindChild("EditBox"):SetText(value)
	settings.moo.alpha = value
end

---------------------------------
--		Outgoing Heal Controls Base
---------------------------------

function CombatText:OnScaleEditBoxReturn_ohb( wndHandler, wndControl, strText )
	wndControl:GetParent():FindChild("ScaleEditBox"):SetText(strText)
	settings.ohb.fontscale = tonumber(strText)
end


function CombatText:OnFontStyleClick_ohb( wndHandler, wndControl, eMouseButton )
	CreateDropdownMenu(self, wndControl:GetParent(), tFontStyleOptions, "OnFontStyleItemClick_ohb")
	wndControl:GetParent():FindChild("DropdownBox"):Show(true)
end

function CombatText:OnFontStyleItemClick_ohb(wndHandler, wndControl, eMouseButton)
	settings.ohb.fontstyle = wndControl:GetText()
	wndControl:GetParent():GetParent():GetParent():FindChild("DropDown"):SetText(wndControl:GetText())
	wndControl:GetParent():GetParent():Show(false)
end

function CombatText:HasColorPicker()
	if ColorPicker then
		return true
	end
	Print ("To change colors you need to have the ColorPicker add-on installed.")
	return false
end

function UpdateBarColor_ohb()
	OutWndRef:FindChild("HealControlsBase"):FindChild("Color"):FindChild("Swatch"):SetBGColor(tcolor)
	settings.ohb.color = tonumber(Convert_CColor_To_String(tcolor),16)
end

function CombatText:OnColorClick_ohb( wndHandler, wndControl, eMouseButton )
	tcolor = Convert_String_To_CColor(tostring(dec2hex(settings.ohb.color)))
	if self:HasColorPicker() then
		ColorPicker.AdjustCColor(tcolor, false, UpdateBarColor_ohb)
	end
end


function CombatText:OnOpacityChange_ohb( wndHandler, wndControl, fNewValue, fOldValue )
	local value = round(fNewValue, 1)
	wndControl:GetParent():FindChild("EditBox"):SetText(value)
	settings.ohb.alpha = value
end


---------------------------------
--		Outgoing Heal Controls Crit
---------------------------------

function CombatText:OnScaleEditBoxReturn_ohc( wndHandler, wndControl, strText )
	wndControl:GetParent():FindChild("ScaleEditBox"):SetText(strText)
	settings.ohc.fontscale = tonumber(strText)
end


function CombatText:OnFontStyleClick_ohc( wndHandler, wndControl, eMouseButton )
	CreateDropdownMenu(self, wndControl:GetParent(), tFontStyleOptions, "OnFontStyleItemClick_ohc")
	wndControl:GetParent():FindChild("DropdownBox"):Show(true)
end

function CombatText:OnFontStyleItemClick_ohc(wndHandler, wndControl, eMouseButton)
	settings.ohc.fontstyle = wndControl:GetText()
	wndControl:GetParent():GetParent():GetParent():FindChild("DropDown"):SetText(wndControl:GetText())
	wndControl:GetParent():GetParent():Show(false)
end

function CombatText:HasColorPicker()
	if ColorPicker then
		return true
	end
	Print ("To change colors you need to have the ColorPicker /ctadd-on installed.")
	return false
end

function UpdateBarColor_ohc()
	OutWndRef:FindChild("HealControlsCrit"):FindChild("Color"):FindChild("Swatch"):SetBGColor(tcolor)
	settings.ohc.color = tonumber(Convert_CColor_To_String(tcolor),16)
end

function CombatText:OnColorClick_ohc( wndHandler, wndControl, eMouseButton )
	tcolor = Convert_String_To_CColor(tostring(dec2hex(settings.ohc.color)))
	if self:HasColorPicker() then
		ColorPicker.AdjustCColor(tcolor, false, UpdateBarColor_ohc)
	end
end


function CombatText:OnOpacityChange_ohc( wndHandler, wndControl, fNewValue, fOldValue )
	local value = round(fNewValue, 1)
	wndControl:GetParent():FindChild("EditBox"):SetText(value)
	settings.ohc.alpha = value
end

---------------------------------
--		Incoming Damage Controls Base
---------------------------------

function CombatText:OnScaleEditBoxReturn_idb( wndHandler, wndControl, strText )
	wndControl:GetParent():FindChild("ScaleEditBox"):SetText(strText)
	settings.idb.fontscale = tonumber(strText)
end

function CombatText:OnFontStyleClick_idb( wndHandler, wndControl, eMouseButton )
	CreateDropdownMenu(self, wndControl:GetParent(), tFontStyleOptions, "OnFontStyleItemClick_idb")
	wndControl:GetParent():FindChild("DropdownBox"):Show(true)
end

function CombatText:OnFontStyleItemClick_idb(wndHandler, wndControl, eMouseButton)
	settings.idb.fontstyle = wndControl:GetText()
	wndControl:GetParent():GetParent():GetParent():FindChild("DropDown"):SetText(wndControl:GetText())
	wndControl:GetParent():GetParent():Show(false)
end

function CombatText:HasColorPicker()
	if ColorPicker then
		return true
	end
	Print ("To change colors you need to have the ColorPicker add-on installed.")
	return false
end

function UpdateBarColor_idb()
	InWndRef:FindChild("DamageControlsBase"):FindChild("Color"):FindChild("Swatch"):SetBGColor(tcolor)
	settings.idb.color = tonumber(Convert_CColor_To_String(tcolor),16)
end

function CombatText:OnColorClick_idb( wndHandler, wndControl, eMouseButton )
	tcolor = Convert_String_To_CColor(tostring(dec2hex(settings.idb.color)))
	if self:HasColorPicker() then
		ColorPicker.AdjustCColor(tcolor, false, UpdateBarColor_idb)
	end
end


function CombatText:OnOpacityChange_idb( wndHandler, wndControl, fNewValue, fOldValue )
	local value = round(fNewValue, 1)
	wndControl:GetParent():FindChild("EditBox"):SetText(value)
	settings.idb.alpha = value
end

---------------------------------
--		Outgoing Damage Controls Crit
---------------------------------

function CombatText:OnScaleEditBoxReturn_idc( wndHandler, wndControl, strText )
	wndControl:GetParent():FindChild("ScaleEditBox"):SetText(strText)
	settings.idc.fontscale = tonumber(strText)
end


function CombatText:OnFontStyleClick_idc( wndHandler, wndControl, eMouseButton )
	CreateDropdownMenu(self, wndControl:GetParent(), tFontStyleOptions, "OnFontStyleItemClick_idc")
	wndControl:GetParent():FindChild("DropdownBox"):Show(true)
end

function CombatText:OnFontStyleItemClick_idc(wndHandler, wndControl, eMouseButton)
	settings.idc.fontstyle = wndControl:GetText()
	wndControl:GetParent():GetParent():GetParent():FindChild("DropDown"):SetText(wndControl:GetText())
	wndControl:GetParent():GetParent():Show(false)
end

function CombatText:HasColorPicker()
	if ColorPicker then
		return true
	end
	Print ("To change colors you need to have the ColorPicker add-on installed.")
	return false
end

function UpdateBarColor_idc()
	InWndRef:FindChild("DamageControlsCrit"):FindChild("Color"):FindChild("Swatch"):SetBGColor(tcolor)
	settings.idc.color = tonumber(Convert_CColor_To_String(tcolor),16)
end

function CombatText:OnColorClick_idc( wndHandler, wndControl, eMouseButton )
	tcolor = Convert_String_To_CColor(tostring(dec2hex(settings.idc.color)))
	if self:HasColorPicker() then
		ColorPicker.AdjustCColor(tcolor, false, UpdateBarColor_idc)
	end
end


function CombatText:OnOpacityChange_idc( wndHandler, wndControl, fNewValue, fOldValue )
	local value = round(fNewValue, 1)
	wndControl:GetParent():FindChild("EditBox"):SetText(value)
	settings.idc.alpha = value
end

---------------------------------
--		Incoming Heal Controls Base
---------------------------------

function CombatText:OnScaleEditBoxReturn_ihb( wndHandler, wndControl, strText )
	wndControl:GetParent():FindChild("ScaleEditBox"):SetText(strText)
	settings.ihb.fontscale = tonumber(strText)
end


function CombatText:OnFontStyleClick_ihb( wndHandler, wndControl, eMouseButton )
	CreateDropdownMenu(self, wndControl:GetParent(), tFontStyleOptions, "OnFontStyleItemClick_ihb")
	wndControl:GetParent():FindChild("DropdownBox"):Show(true)
end

function CombatText:OnFontStyleItemClick_ihb(wndHandler, wndControl, eMouseButton)
	settings.ihb.fontstyle = wndControl:GetText()
	wndControl:GetParent():GetParent():GetParent():FindChild("DropDown"):SetText(wndControl:GetText())
	wndControl:GetParent():GetParent():Show(false)
end

function CombatText:HasColorPicker()
	if ColorPicker then
		return true
	end
	Print ("To change colors you need to have the ColorPicker add-on installed.")
	return false
end

function UpdateBarColor_ihb()
	InWndRef:FindChild("HealControlsBase"):FindChild("Color"):FindChild("Swatch"):SetBGColor(tcolor)
	settings.ihb.color = tonumber(Convert_CColor_To_String(tcolor),16)
end

function CombatText:OnColorClick_ihb( wndHandler, wndControl, eMouseButton )
	tcolor = Convert_String_To_CColor(tostring(dec2hex(settings.ihb.color)))
	if self:HasColorPicker() then
		ColorPicker.AdjustCColor(tcolor, false, UpdateBarColor_ihb)
	end
end


function CombatText:OnOpacityChange_ihb( wndHandler, wndControl, fNewValue, fOldValue )
	local value = round(fNewValue, 1)
	wndControl:GetParent():FindChild("EditBox"):SetText(value)
	settings.ihb.alpha = value
end


---------------------------------
--		Incoming Heal Controls Crit
---------------------------------

function CombatText:OnScaleEditBoxReturn_ihc( wndHandler, wndControl, strText )
	wndControl:GetParent():FindChild("ScaleEditBox"):SetText(strText)
	settings.ihc.fontscale = tonumber(strText)
end


function CombatText:OnFontStyleClick_ihc( wndHandler, wndControl, eMouseButton )
	CreateDropdownMenu(self, wndControl:GetParent(), tFontStyleOptions, "OnFontStyleItemClick_ihc")
	wndControl:GetParent():FindChild("DropdownBox"):Show(true)
end

function CombatText:OnFontStyleItemClick_ihc(wndHandler, wndControl, eMouseButton)
	settings.ihc.fontstyle = wndControl:GetText()
	wndControl:GetParent():GetParent():GetParent():FindChild("DropDown"):SetText(wndControl:GetText())
	wndControl:GetParent():GetParent():Show(false)
end

function CombatText:HasColorPicker()
	if ColorPicker then
		return true
	end
	Print ("To change colors you need to have the ColorPicker /ctadd-on installed.")
	return false
end

function UpdateBarColor_ihc()
	InWndRef:FindChild("HealControlsCrit"):FindChild("Color"):FindChild("Swatch"):SetBGColor(tcolor)
	settings.ihc.color = tonumber(Convert_CColor_To_String(tcolor),16)
end

function CombatText:OnColorClick_ihc( wndHandler, wndControl, eMouseButton )
	tcolor = Convert_String_To_CColor(tostring(dec2hex(settings.ihc.color)))
	if self:HasColorPicker() then
		ColorPicker.AdjustCColor(tcolor, false, UpdateBarColor_ihc)
	end
end


function CombatText:OnOpacityChange_ihc( wndHandler, wndControl, fNewValue, fOldValue )
	local value = round(fNewValue, 1)
	wndControl:GetParent():FindChild("EditBox"):SetText(value)
	settings.ihc.alpha = value
end

-- Save current settings for next time
function CombatText:OnSave(level)
	local profile = nil
	if level == GameLib.CodeEnumAddonSaveLevel.General then
		settings.odb.color = dec2hex(settings.odb.color)
		settings.odc.color = dec2hex(settings.odc.color)
		settings.ohb.color = dec2hex(settings.ohb.color)
		settings.ohc.color = dec2hex(settings.ohc.color)
		settings.idb.color = dec2hex(settings.idb.color)
		settings.idc.color = dec2hex(settings.idc.color)
		settings.ihb.color = dec2hex(settings.ihb.color)
		settings.ihc.color = dec2hex(settings.ihc.color)
		settings.moo.color = dec2hex(settings.moo.color)

		profile = {
			savedsettings = settings,
			}
	end
	return profile
end

-- Restore settings from profile created during previous use the addon on any character
function CombatText:OnRestore(level, profile)
	if profile and level == GameLib.CodeEnumAddonSaveLevel.General then
		if profile.savedsettings then settings = profile.savedsettings end
		settings.odb.color = tonumber(settings.odb.color,16)
		settings.odc.color = tonumber(settings.odc.color,16)
		settings.ohb.color = tonumber(settings.ohb.color,16)
		settings.ohc.color = tonumber(settings.ohc.color,16)
		settings.idb.color = tonumber(settings.idb.color,16)
		settings.idc.color = tonumber(settings.idc.color,16)
		settings.ihb.color = tonumber(settings.ihb.color,16)
		settings.ihc.color = tonumber(settings.ihc.color,16)
		settings.moo.color = tonumber(settings.moo.color,16)

	end
end

local CombatTextInst = CombatText:new()
CombatTextInst:Init()

