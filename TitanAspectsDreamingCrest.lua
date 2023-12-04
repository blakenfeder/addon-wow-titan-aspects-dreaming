--[[
  TitanAspectsDramingCrest: A simple Display of current Aspect's Draming Crest value
  Author: Blakenfeder
--]]

-- Define addon base object
local TitanAspectsDramingCrest = {
  Const = {
    Id = "AspectsDramingCrest",
    Name = "TitanAspectsDramingCrest",
    DisplayName = "Titan Panel [Aspect's Draming Crest]",
    Version = "",
    Author = "",
  },
  CurrencyConst = {
    Id = 2709,
    Icon = "Interface\\Icons\\inv_10_gearupgrade_aspectsdreamingcrest",
    Name = "",
    Description = "",
    Color = "|cffffffff",
  },
  IsInitialized = false,
}
function TitanAspectsDramingCrest.GetCurrencyInfo()
  return C_CurrencyInfo.GetCurrencyInfo(TitanAspectsDramingCrest.CurrencyConst.Id)
end
function TitanAspectsDramingCrest.InitCurrencyConst()
  local info = TitanAspectsDramingCrest.GetCurrencyInfo()
  if (info) then
    TitanAspectsDramingCrest.CurrencyConst.Name = info.name
    TitanAspectsDramingCrest.CurrencyConst.Description = info.description
    
    local r, g, b, hex = GetItemQualityColor(info.quality)
    if (hex) then
      TitanAspectsDramingCrest.CurrencyConst.Color = '|c' .. hex
    end
  end
end
function TitanAspectsDramingCrest.Util_GetFormattedNumber(number)
  if number >= 1000 then
    return string.format("%d,%03d", number / 1000, number % 1000)
  else
    return string.format ("%d", number)
  end
end
function TitanAspectsDramingCrest.Util_WrapSingleLineOfText(text, lineLength)
  local wrappedText = ""
  local currentLine = ""
  for word in string.gmatch(text, "[^%s]+") do
      if string.len(currentLine) + string.len(word) > lineLength then
          wrappedText = wrappedText .. currentLine .. "\n"
          currentLine = word .. " "
      else
          currentLine = currentLine .. word .. " "
      end
  end
  wrappedText = wrappedText .. currentLine

  -- Return trimmed wrapped text
  return wrappedText:match("^%s*(.-)%s*$")
end
function TitanAspectsDramingCrest.Util_WrapText(text, lineLength)
  -- Variable to be returned
  local wrappedText = ""

  -- Wrap the text for each individual paragraph
  for paragraph in text:gmatch("[^\n]+") do
    wrappedText = wrappedText .. "\n" .. TitanAspectsDramingCrest.Util_WrapSingleLineOfText(paragraph, lineLength)
  end

  -- Return trimmed wrapped text
  return wrappedText:match("^%s*(.-)%s*$")
end

-- Load metadata
TitanAspectsDramingCrest.Const.Version = GetAddOnMetadata(TitanAspectsDramingCrest.Const.Name, "Version")
TitanAspectsDramingCrest.Const.Author = GetAddOnMetadata(TitanAspectsDramingCrest.Const.Name, "Author")

-- Text colors (AARRGGBB)
local BKFD_C_BURGUNDY = "|cff993300"
local BKFD_C_GRAY = "|cff999999"
local BKFD_C_GREEN = "|cff00ff00"
local BKFD_C_ORANGE = "|cffff8000"
local BKFD_C_RED = "|cffff0000"
local BKFD_C_WHITE = "|cffffffff"
local BKFD_C_YELLOW = "|cffffcc00"

-- Load Library references
local LT = LibStub("AceLocale-3.0"):GetLocale("Titan", true)
local L = LibStub("AceLocale-3.0"):GetLocale(TitanAspectsDramingCrest.Const.Id, true)

-- Currency update variables
local updateFrequency = 0.0
local currencyCount = 0.0
local currencyMaximum
local wasMaximumReached = false
local seasonalCount = 0.0
local isSeasonal = false
local currencyDiscovered = false

function TitanPanelAspectsDramingCrestButton_OnLoad(self)
  TitanAspectsDramingCrest.InitCurrencyConst()

  self.registry = {
    id = TitanAspectsDramingCrest.Const.Id,
    category = "Information",
    version = TitanAspectsDramingCrest.Const.Version,
    menuText = TitanAspectsDramingCrest.CurrencyConst.Name,
    buttonTextFunction = "TitanPanelAspectsDramingCrestButton_GetButtonText",
    tooltipTitle = TitanAspectsDramingCrest.CurrencyConst.Color .. TitanAspectsDramingCrest.CurrencyConst.Name,
    tooltipTextFunction = "TitanPanelAspectsDramingCrestButton_GetTooltipText",
    icon = TitanAspectsDramingCrest.CurrencyConst.Icon,
    iconWidth = 16,
    controlVariables = {
      ShowIcon = true,
      ShowLabelText = true,
    },
    savedVariables = {
      ShowIcon = 1,
      ShowLabelText = false,
      ShowColoredText = false,
    },
  };


  self:RegisterEvent("PLAYER_ENTERING_WORLD");
  self:RegisterEvent("PLAYER_LOGOUT");
end

function TitanPanelAspectsDramingCrestButton_GetButtonText(id)
  local currencyCountText
  if not currencyCount then
    currencyCountText = "0"
  else  
    currencyCountText = TitanAspectsDramingCrest.Util_GetFormattedNumber(currencyCount)
  end

  if (wasMaximumReached) then
    currencyCountText = BKFD_C_RED .. currencyCountText
  end

  return TitanAspectsDramingCrest.CurrencyConst.Name .. ": ", TitanUtils_GetHighlightText(currencyCountText)
end

function TitanPanelAspectsDramingCrestButton_GetTooltipText()
  local currencyDescription = TitanAspectsDramingCrest.Util_WrapText(TitanAspectsDramingCrest.CurrencyConst.Description, 36)


  if (not currencyDiscovered) then
    return
      currencyDescription .. "\r" ..
      " \r" ..
      TitanUtils_GetHighlightText(L["BKFD_TITAN_TOOLTIP_NOT_YET_DISCOVERED"])
  end

  -- Set which total value will be displayed
  local tooltipCurrencyCount = currencyCount
  local tooltipCurrencyCurrentCount = 0
  if (isSeasonal) then
    tooltipCurrencyCurrentCount = tooltipCurrencyCount
    tooltipCurrencyCount = seasonalCount
  end

  -- Set how the total value will be displayed
  local totalValue = string.format(
    "%s/%s",
    TitanAspectsDramingCrest.Util_GetFormattedNumber(tooltipCurrencyCount),
    TitanAspectsDramingCrest.Util_GetFormattedNumber(currencyMaximum)
  )
  if (not currencyMaximum or currencyMaximum == 0) then
    totalValue = string.format(
      "%s",
      TitanAspectsDramingCrest.Util_GetFormattedNumber(tooltipCurrencyCount)
    )
  elseif (wasMaximumReached) then
    totalValue = BKFD_C_RED .. totalValue
  end
  local seasonCurrentValue = TitanAspectsDramingCrest.Util_GetFormattedNumber(tooltipCurrencyCurrentCount)
  
  local totalLabel = L["BKFD_TITAN_TOOLTIP_COUNT_LABEL_TOTAL_MAXIMUM"]
  if (isSeasonal) then
    totalLabel = L["BKFD_TITAN_TOOLTIP_COUNT_LABEL_TOTAL_SEASONAL"]
  elseif (not currencyMaximum or currencyMaximum == 0) then
    totalLabel = L["BKFD_TITAN_TOOLTIP_COUNT_LABEL_TOTAL"]
  end

  if (isSeasonal and currencyMaximum and currencyMaximum > 0) then
    return
      currencyDescription .. "\r" ..
      " \r" ..
      L["BKFD_TITAN_TOOLTIP_COUNT_LABEL_TOTAL"]..TitanUtils_GetHighlightText(seasonCurrentValue) .. "\r" ..
      L["BKFD_TITAN_TOOLTIP_COUNT_LABEL_TOTAL_SEASONAL_MAXIMUM"] .. TitanUtils_GetHighlightText(totalValue)
  else
    return
      currencyDescription .. "\r" ..
      " \r" ..
      totalLabel .. TitanUtils_GetHighlightText(totalValue)
  end
end

function TitanPanelAspectsDramingCrestButton_OnUpdate(self, elapsed)
  updateFrequency = updateFrequency - elapsed;

  if updateFrequency <= 0 then
    updateFrequency = 1;

    local info = TitanAspectsDramingCrest.GetCurrencyInfo(TitanAspectsDramingCrest.CurrencyConst.Id)
    if (info) then
      currencyDiscovered = info.discovered
      currencyCount = tonumber(info.quantity)
      currencyMaximum = tonumber(info.maxQuantity)
      seasonalCount = tonumber(info.totalEarned)
      isSeasonal = info.useTotalEarnedForMaxQty

      wasMaximumReached =
          currencyMaximum and not(currencyMaximum == 0)
          and isSeasonal and seasonalCount
          and seasonalCount >= currencyMaximum
        or
          currencyMaximum and not(currencyMaximum == 0)
          and not isSeasonal and currencyCount
          and currencyCount >= currencyMaximum
    end

    TitanPanelButton_UpdateButton(TitanAspectsDramingCrest.Const.Id)
  end
end

function TitanPanelAspectsDramingCrestButton_OnEvent(self, event, ...)
  if (event == "PLAYER_ENTERING_WORLD") then
    if (not TitanAspectsDramingCrest.IsInitialized and DEFAULT_CHAT_FRAME) then
      DEFAULT_CHAT_FRAME:AddMessage(
        BKFD_C_YELLOW .. TitanAspectsDramingCrest.Const.DisplayName .. " " ..
        BKFD_C_GREEN .. TitanAspectsDramingCrest.Const.Version ..
        BKFD_C_YELLOW .. " by "..
        BKFD_C_ORANGE .. TitanAspectsDramingCrest.Const.Author)
      TitanPanelButton_UpdateButton(TitanAspectsDramingCrest.Const.Id)
      TitanAspectsDramingCrest.IsInitialized = true
    end
    return;
  end  
  if (event == "PLAYER_LOGOUT") then
    TitanAspectsDramingCrest.IsInitialized = false;
    return;
  end
end

function TitanPanelRightClickMenu_PrepareAspectsDramingCrestMenu()
  local id = TitanAspectsDramingCrest.Const.Id;

  TitanPanelRightClickMenu_AddTitle(TitanPlugins[id].menuText)
  
  TitanPanelRightClickMenu_AddToggleIcon(id)
  TitanPanelRightClickMenu_AddToggleLabelText(id)
  TitanPanelRightClickMenu_AddSpacer()
  TitanPanelRightClickMenu_AddCommand(LT["TITAN_PANEL_MENU_HIDE"], id, TITAN_PANEL_MENU_FUNC_HIDE)
end