--OptionsPanel.lua
---@diagnostic disable: undefined-doc-name

local addonName, KSR = ...

---@param parent optionsPanel
---@param displayText string Text associated to options item
---@param name string name of item
---@param x number x position
---@param y number y position
---@param w number width of button
---@param h number height of button
---@return Button|UIPanelButtonTemplate
local function createOptionButton(parent, displayText, name, x, y, w, h)
    local button = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    button:SetPoint("TOPLEFT", x, y)
    button:SetWidth(w)
    button:SetHeight(h)
    button.Text:SetText(displayText)
    return button
end

KSR.InitOptions = function()
    ---@class optionsPanel : Frame
    local optionsPanel = CreateFrame("Frame", "AddonOptionsPanel", InterfaceOptionsFramePanelContainer)
    optionsPanel.name = "Keystone Roulette"

    optionsPanel.optionsHeaderText = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
    optionsPanel.optionsHeaderText:SetPoint("TOPLEFT", 16, -10)
    optionsPanel.optionsHeaderText:SetText("Options for Keystone Roulette")

    optionsPanel.cmdHelpText = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    optionsPanel.cmdHelpText:SetPoint("TOPLEFT", 16, -30)
    optionsPanel.cmdHelpText:SetText("Run '/ksr help' for console commands")

    local rollButton = createOptionButton(optionsPanel, "Open Roulette GUI", "rollButton", 16, -80, 200, 25)
    KSR.setOrHookHandler(rollButton, "OnClick", function()
        KSR.ShowKeystoneGUI()
    end)

    local resetButton = createOptionButton(optionsPanel, "Reset to default settings", "resetButton", 16, -120, 200, 25)
    KSR.setOrHookHandler(resetButton, "OnClick", function()
        KeystoneRouletteDB = CopyTable(KSR.addonDefaults)
        print(WrapTextInColorCode(KSR.addon.title .. " is reset to default settings.", KSR.colors["PRIMARY"]))
    end)

    optionsPanel.versionInfo = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    optionsPanel.versionInfo:SetPoint("BOTTOMRIGHT", optionsPanel, -10, 10)
    optionsPanel.versionInfo:SetText(addonName .. " v" .. KSR.addon.version)

    local category, layout = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name);
    Settings.RegisterAddOnCategory(category);
    KSR.settingsCategory = category

    KSR.WagoAnalytics:IncrementCounter("OpenOptions")
end
