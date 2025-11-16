-- KeystoneGUI.lua

local _, KSR = ...

-- Create the main frame
local frame = CreateFrame("Frame", "KeystoneRouletteGUI", UIParent, "BackdropTemplate")
frame:SetFrameStrata("HIGH")
frame:Hide()
frame:SetSize(320, 280)
frame:SetPoint("TOP", 0, -300)
frame:EnableMouse(true)
frame:SetMovable(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true,
    tileSize = 32,
    edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 }
})
frame:HookScript("OnHide", function()
    if KSR.IsLibOpenRaidAvailable() then
        KSR.openRaidLib.UnregisterCallback(KSR, "KeystoneUpdate", "OnKeystoneUpdate")
    end
end)

-- Add a title text
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", 0, -15)
title:SetText("Keystone Roulette")

-- Create the roulette wheel texture
local rouletteWheel = frame:CreateTexture(nil, "BACKGROUND")
rouletteWheel:SetDrawLayer("BACKGROUND", 1)
rouletteWheel:SetTexture("Interface\\AddOns\\KeystoneRoulette\\Textures\\wheel.png")
rouletteWheel:SetSize(128, 128)
rouletteWheel:SetPoint("TOP", 0, -100)

-- Create the roulette frame texture
local rouletteFrame = frame:CreateTexture(nil, "BACKGROUND")
rouletteFrame:SetDrawLayer("BACKGROUND", 2)
rouletteFrame:SetTexture("Interface\\AddOns\\KeystoneRoulette\\Textures\\wheelframe.png")
rouletteFrame:SetSize(128, 147)
rouletteFrame:SetPoint("TOP", 0, -80)

-- Create a text object to display the winning keystone
local winningKeystoneText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
winningKeystoneText:SetPoint("TOP", rouletteFrame, "TOP", 0, 20)

local keystoneTexts = {}
-- Create a frame to hold the keystone list
local keystoneListFrame = CreateFrame("Frame", "KeystoneRouletteListFrame", frame)
keystoneListFrame:SetPoint("TOPLEFT", rouletteFrame, "TOPRIGHT", 15, 0)
keystoneListFrame:SetPoint("BOTTOMRIGHT", -15, 50)

-- Function to populate the keystone list
local function UpdateKeystoneList()
    local keys = KSR.GetPartyKeystoneData()
    local spacing = 5

    for i, key in ipairs(keys) do
        if not keystoneTexts[i] then
            keystoneTexts[i] = keystoneListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        end

        local keystoneText = keystoneTexts[i]

        if i == 1 then
            keystoneText:SetPoint("TOPLEFT", 0, -spacing)
        else
            keystoneText:SetPoint("TOP", keystoneTexts[i-1], "BOTTOM", 0, -spacing)
        end

        keystoneText:SetText(string.format("%s +%d", key.abbr, key.level))
        keystoneText:Show()
    end

    for i = #keys + 1, #keystoneTexts do
        keystoneTexts[i]:SetText()
        keystoneTexts[i]:Hide()
    end
end

-- Function to spin the roulette wheel and display the winning keystone
local function SpinRouletteWheel()
    winningKeystoneText:SetText("")
    rouletteWheel:SetRotation(0)
    local spinDuration = 2
    local spinAnimation = rouletteWheel:CreateAnimationGroup()
    local spin = spinAnimation:CreateAnimation("Rotation")
    spin:SetDuration(spinDuration)
    spin:SetDegrees(-360 * 4)
    spin:SetOrder(1)
    spinAnimation:Play()

    -- After timeout, select, display and announce the winning keystone
    C_Timer.After(spinDuration, function()
        local keys = KSR.GetPartyKeystoneData()
        local chosenKey = KSR.ChooseRandomKeystone(keys)
        if chosenKey then
            winningKeystoneText:SetText(string.format("%s - %s +%d", chosenKey.player, chosenKey.dungeon, chosenKey.level))
            KSR.AnnounceKeystone(keys, chosenKey)
        else
            winningKeystoneText:SetText("404 - Keystone not found")
        end
    end)
end

local rollButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
rollButton:SetPoint("BOTTOMLEFT", 15, 15)
rollButton:SetSize(140, 30)
rollButton:SetText("Roulette a Keystone")
rollButton:SetScript("OnClick", function()
    SpinRouletteWheel()
end)

local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
closeButton:SetPoint("BOTTOMRIGHT", -15, 15)
closeButton:SetSize(140, 30)
closeButton:SetText("Close")
closeButton:SetScript("OnClick", function()
    frame:Hide()
    winningKeystoneText:SetText("")
end)

KSR.OnKeystoneUpdate = function(unitName, keystoneInfo, _)
    if (UnitInParty(unitName) or unitName == UnitName("player")) and keystoneInfo.level > 0 then
        UpdateKeystoneList()
    end
end

-- Callback for custom sync updates
KSR.OnKeystoneSyncUpdate = function()
    if frame:IsShown() then
        UpdateKeystoneList()
    end
end

KSR.ShowKeystoneGUI = function()
    -- Register LibOpenRaid callback if available
    if KSR.IsLibOpenRaidAvailable() then
        KSR.openRaidLib.RegisterCallback(KSR, "KeystoneUpdate", "OnKeystoneUpdate")
    end
    
    -- Request keystones if using fallback sync
    if not KSR.IsLibOpenRaidAvailable() and KSR.GetSyncKeystoneData then
        KSR.GetSyncKeystoneData()
    end
    
    UpdateKeystoneList()
    frame:Show()
end