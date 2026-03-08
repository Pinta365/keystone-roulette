-- KeystoneGUI.lua

local _, KSR = ...

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

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOP", 0, -15)
title:SetText("Keystone Roulette")

local rouletteWheel = frame:CreateTexture(nil, "BACKGROUND")
rouletteWheel:SetDrawLayer("BACKGROUND", 1)
rouletteWheel:SetTexture("Interface\\AddOns\\KeystoneRoulette\\Textures\\wheel.png")
rouletteWheel:SetSize(128, 128)
rouletteWheel:SetPoint("TOP", 0, -100)

local rouletteFrame = frame:CreateTexture(nil, "BACKGROUND")
rouletteFrame:SetDrawLayer("BACKGROUND", 2)
rouletteFrame:SetTexture("Interface\\AddOns\\KeystoneRoulette\\Textures\\wheelframe.png")
rouletteFrame:SetSize(128, 147)
rouletteFrame:SetPoint("TOP", 0, -80)

local winningKeystoneText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
winningKeystoneText:SetPoint("TOP", rouletteFrame, "TOP", 0, 20)

local keystoneTexts = {}
local keystoneListFrame = CreateFrame("Frame", "KeystoneRouletteListFrame", frame)
keystoneListFrame:SetPoint("TOPLEFT", rouletteFrame, "TOPRIGHT", 10, 0)
keystoneListFrame:SetPoint("BOTTOMRIGHT", -15, 50)

local function UpdateKeystoneList()
    local keys = KSR.GetPartyKeystoneData()
    local spacing = 5

    for i, key in ipairs(keys) do
        if not keystoneTexts[i] then
            keystoneTexts[i] = keystoneListFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            keystoneTexts[i]:SetJustifyH("RIGHT")
        end

        local keystoneText = keystoneTexts[i]

        if i == 1 then
            keystoneText:SetPoint("TOPRIGHT", 0, -spacing)
        else
            keystoneText:SetPoint("TOPRIGHT", keystoneTexts[i-1], "BOTTOMRIGHT", 0, -spacing)
        end

        keystoneText:SetText(string.format("%s +%d", key.abbr, key.level))
        keystoneText:Show()
    end

    for i = #keys + 1, #keystoneTexts do
        keystoneTexts[i]:SetText()
        keystoneTexts[i]:Hide()
    end
end

local function SpinRouletteWheel()
    winningKeystoneText:SetText("")
    rouletteWheel:SetRotation(0)
    local spinDuration = KSR.constants.SPIN_DURATION
    local spinAnimation = rouletteWheel:CreateAnimationGroup()
    local spin = spinAnimation:CreateAnimation("Rotation")
    spin:SetDuration(spinDuration)
    spin:SetDegrees(-360 * 4)
    spin:SetOrder(1)
    spinAnimation:Play()

    C_Timer.After(KSR.constants.SPIN_DURATION, function()
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

local function setTooltip(button, title, description)
    button:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText(title, 1, 1, 1)
        GameTooltip:AddLine(description, nil, nil, nil, true)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local rollButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
rollButton:SetPoint("BOTTOMLEFT", 15, 15)
rollButton:SetSize(140, 30)
rollButton:SetText("Roulette a Keystone")
rollButton:SetScript("OnClick", function()
    SpinRouletteWheel()
end)
setTooltip(rollButton, "Roulette a Keystone", "Randomly selects one of the party's available keystones and announces the result to party chat.")

local voteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
voteButton:SetPoint("BOTTOMLEFT", rollButton, "TOPLEFT", 0, 5)
voteButton:SetSize(90, 30)
voteButton:SetText("Start Vote")
voteButton:SetScript("OnClick", function()
    winningKeystoneText:SetText("")
    KSR.StartVote(nil, function(winnerKey)
        winningKeystoneText:SetText(string.format("%s - %s +%d", winnerKey.player, winnerKey.dungeon, winnerKey.level))
    end)
end)
setTooltip(voteButton, "Start Vote", "Opens a vote in party chat. Party members type a keystone abbreviation to cast their vote. The winner is announced after 20 seconds.")

local peekButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
peekButton:SetPoint("BOTTOMLEFT", voteButton, "TOPLEFT", 0, 5)
peekButton:SetSize(80, 30)
peekButton:SetText("Peek")
peekButton:SetScript("OnClick", function()
    KSR.PeekKeystones()
end)
setTooltip(peekButton, "Peek", "Sends an emote to party chat revealing all available keystones in the group.")

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

KSR.OnKeystoneSyncUpdate = function()
    if frame:IsShown() then
        UpdateKeystoneList()
    end
end

KSR.ShowKeystoneGUI = function()
    if KSR.IsLibKeystoneAvailable() then
        if KSR.IsInParty() then
            KSR.libKeystone.Request("PARTY")
            KSR.debugPrint("ShowKeystoneGUI: Requested keystones from LibKeystone (PARTY)")
        end
    end

    if KSR.IsLibOpenRaidAvailable() then
        KSR.openRaidLib.RegisterCallback(KSR, "KeystoneUpdate", "OnKeystoneUpdate")
    end
    
    UpdateKeystoneList()
    frame:Show()
end