-- KeystoneGUI.lua

local _, KSR = ...

local BUTTON_WIDTH = 165
local BUTTON_HEIGHT = 30
local EDGE_MARGIN = 15

local frame = CreateFrame("Frame", "KeystoneRouletteGUI", UIParent, "BackdropTemplate")
frame:SetFrameStrata("HIGH")
frame:Hide()
frame:SetSize(380, 360)
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

local rouletteFrame = frame:CreateTexture(nil, "BACKGROUND")
rouletteFrame:SetDrawLayer("BACKGROUND", 2)
rouletteFrame:SetTexture("Interface\\AddOns\\KeystoneRoulette\\Textures\\wheelframe.png")
rouletteFrame:SetSize(128, 147)
rouletteFrame:SetPoint("TOP", 0, -68)

local rouletteWheel = frame:CreateTexture(nil, "BACKGROUND")
rouletteWheel:SetDrawLayer("BACKGROUND", 1)
rouletteWheel:SetTexture("Interface\\AddOns\\KeystoneRoulette\\Textures\\wheel.png")
rouletteWheel:SetSize(128, 128)
rouletteWheel:SetPoint("TOP", rouletteFrame, "TOP", 0, -20)

local winningKeystoneText = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
winningKeystoneText:SetPoint("TOP", rouletteFrame, "TOP", 0, 20)
winningKeystoneText:SetWidth(340)
winningKeystoneText:SetWordWrap(false)

local keystoneTexts = {}
local keystoneListFrame = CreateFrame("Frame", "KeystoneRouletteListFrame", frame)
keystoneListFrame:SetPoint("TOPLEFT", rouletteFrame, "TOPRIGHT", 15, 0)
keystoneListFrame:SetPoint("BOTTOMRIGHT", -EDGE_MARGIN, 138)

---Creates one of the key level range input boxes.
---@param labelText string the caption shown to the left of the box
---@param anchorTo table the region the label is anchored to the right of
---@param anchorGap number horizontal gap between the anchor and the label
---@return table editBox the created edit box
local function createRangeBox(labelText, anchorTo, anchorGap)
    local label = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", anchorTo, "RIGHT", anchorGap, 0)
    label:SetText(labelText)

    local editBox = CreateFrame("EditBox", nil, frame, "InputBoxTemplate")
    editBox:SetPoint("LEFT", label, "RIGHT", 10, 0)
    editBox:SetSize(32, 20)
    editBox:SetAutoFocus(false)
    editBox:SetNumeric(true)
    editBox:SetMaxLetters(2)
    editBox:SetJustifyH("CENTER")
    editBox:SetScript("OnEscapePressed", editBox.ClearFocus)
    editBox:SetScript("OnEnterPressed", editBox.ClearFocus)

    return editBox
end

local rangeLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
rangeLabel:SetPoint("BOTTOMLEFT", EDGE_MARGIN + 3, 110)
rangeLabel:SetText("Key level")

local minBox = createRangeBox("min", rangeLabel, 16)
local maxBox = createRangeBox("max", minBox, 14)

local rangeHint = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
rangeHint:SetPoint("TOPLEFT", rangeLabel, "BOTTOMLEFT", 0, -6)
rangeHint:SetText("Leave blank to include every key")

---Reads the key level range currently entered in the GUI.
---Blank or zero means unbounded, and reversed bounds are swapped so the
---range always reads low to high.
---@return number|nil minLevel the lowest key level to include
---@return number|nil maxLevel the highest key level to include
local function GetSelectedRange()
    local minLevel = tonumber(minBox:GetText())
    local maxLevel = tonumber(maxBox:GetText())

    if minLevel == 0 then
        minLevel = nil
    end

    if maxLevel == 0 then
        maxLevel = nil
    end

    if minLevel and maxLevel and minLevel > maxLevel then
        minLevel, maxLevel = maxLevel, minLevel
    end

    return minLevel, maxLevel
end

local function UpdateKeystoneList()
    local keys = KSR.GetPartyKeystoneData()
    local minLevel, maxLevel = GetSelectedRange()
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

        -- Dim the keys the current range would exclude so the effect is visible.
        local inRange = (not minLevel or key.level >= minLevel) and (not maxLevel or key.level <= maxLevel)
        if inRange then
            keystoneText:SetTextColor(NORMAL_FONT_COLOR:GetRGB())
        else
            keystoneText:SetTextColor(DISABLED_FONT_COLOR:GetRGB())
        end

        keystoneText:Show()
    end

    for i = #keys + 1, #keystoneTexts do
        keystoneTexts[i]:SetText()
        keystoneTexts[i]:Hide()
    end
end

minBox:SetScript("OnTextChanged", UpdateKeystoneList)
maxBox:SetScript("OnTextChanged", UpdateKeystoneList)

frame:HookScript("OnHide", function()
    minBox:ClearFocus()
    maxBox:ClearFocus()
    minBox:SetText("")
    maxBox:SetText("")
end)

local function SpinRouletteWheel()
    local minLevel, maxLevel = GetSelectedRange()

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
        local allKeys = KSR.GetPartyKeystoneData()
        local keys = KSR.FilterKeysByLevel(allKeys, minLevel, maxLevel)
        local chosenKey = KSR.ChooseRandomKeystone(keys)

        if chosenKey then
            winningKeystoneText:SetText(string.format("%s - %s +%d", chosenKey.player, chosenKey.dungeon, chosenKey.level))
            KSR.AnnounceKeystone(keys, chosenKey, false, minLevel, maxLevel)
            return
        end

        if KSR.DescribeLevelRange(minLevel, maxLevel) and allKeys and #allKeys > 0 then
            winningKeystoneText:SetText("No keys in range")
        else
            winningKeystoneText:SetText("404 - Keystone not found")
        end

        print(WrapTextInColorCode(KSR.BuildNoKeysMessage(allKeys, minLevel, maxLevel), KSR.colors["YELLOW"]))
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
rollButton:SetPoint("BOTTOMLEFT", EDGE_MARGIN, 50)
rollButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
rollButton:SetText("Roulette a Keystone")
rollButton:SetScript("OnClick", function()
    SpinRouletteWheel()
end)
setTooltip(rollButton, "Roulette a Keystone", "Randomly selects one of the party's available keystones and announces the result to party chat. Respects the key level range above.")

local voteButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
voteButton:SetPoint("BOTTOMRIGHT", -EDGE_MARGIN, 50)
voteButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
voteButton:SetText("Start Vote")
voteButton:SetScript("OnClick", function()
    local minLevel, maxLevel = GetSelectedRange()
    winningKeystoneText:SetText("")
    KSR.StartVote(nil, function(winnerKey)
        winningKeystoneText:SetText(string.format("%s - %s +%d", winnerKey.player, winnerKey.dungeon, winnerKey.level))
    end, minLevel, maxLevel)
end)
setTooltip(voteButton, "Start Vote", "Opens a vote in party chat. Party members type a keystone abbreviation to cast their vote. The winner is announced after 20 seconds. Respects the key level range above.")

local peekButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
peekButton:SetPoint("BOTTOMLEFT", EDGE_MARGIN, 15)
peekButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
peekButton:SetText("Peek")
peekButton:SetScript("OnClick", function()
    KSR.PeekKeystones()
end)
setTooltip(peekButton, "Peek", "Sends an emote to party chat revealing all available keystones in the group. Never filtered by the key level range.")

local closeButton = CreateFrame("Button", nil, frame, "UIPanelButtonTemplate")
closeButton:SetPoint("BOTTOMRIGHT", -EDGE_MARGIN, 15)
closeButton:SetSize(BUTTON_WIDTH, BUTTON_HEIGHT)
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
        KSR.libKeystone.Request("PARTY")
        KSR.debugPrint("ShowKeystoneGUI: Requested keystones from LibKeystone (PARTY)")
    end

    if KSR.IsLibOpenRaidAvailable() then
        KSR.openRaidLib.RegisterCallback(KSR, "KeystoneUpdate", "OnKeystoneUpdate")
    end

    UpdateKeystoneList()
    frame:Show()
end
