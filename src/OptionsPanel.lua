--OptionsPanel.lua
---@diagnostic disable: undefined-doc-name

local addonName, KSR = ...

---Helper function to create option button.
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
    ---@diagnostic disable-next-line: undefined-field
    button.Text:SetText(displayText)
    return button
end

---Create the options panel
KSR.InitOptions = function()
    ---@class optionsPanel : Frame
    local optionsPanel = CreateFrame("Frame", "AddonOptionsPanel", InterfaceOptionsFramePanelContainer)
    optionsPanel.name = "Keystone Roulette"

    -- Create a toggle for the "Debug" option.
    --local debugCheckbox = createOptionCheckButton(optionsPanel, "Debug mode (developer mode)", "ToggleDebugCheckbox", 16, -16)
    --KSR.setOrHookHandler(debugCheckbox, "OnClick", function(self)
    --    KeystoneRouletteDB.debug = self:GetChecked()
    --end)
    --debugCheckbox:SetChecked(KeystoneRouletteDB.debug)

     -- Loot options
    
     optionsPanel.lootHeader = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightMedium")
     optionsPanel.lootHeader:SetPoint("TOPLEFT", 16, -10)
     optionsPanel.lootHeader:SetText("Options for Keystone Roulette")

    -- Button for resetting to default settings.
    local rollButton = createOptionButton(optionsPanel, "Roulette keystone in party", "rollButton", 16, -80, 200, 25)
    KSR.setOrHookHandler(rollButton, "OnClick", function()
        KSR.RouletteKeystone()    
    end)

     -- Button for resetting to default settings.
     local resetButton = createOptionButton(optionsPanel, "Reset to default settings", "resetButton", 16, -120, 200, 25)
     KSR.setOrHookHandler(resetButton, "OnClick", function()
        KeystoneRouletteDB = CopyTable(KSR.addonDefaults)
        --debugCheckbox:SetChecked(KeystoneRouletteDB.debug)

        print(WrapTextInColorCode(KSR.addon.title .. " is reset to default settings.", KSR.colors["PRIMARY"]))
     end)

     optionsPanel.versionInfo = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
     optionsPanel.versionInfo:SetPoint("BOTTOMRIGHT", optionsPanel, -10, 10)
     optionsPanel.versionInfo:SetText(addonName .. " v" .. KSR.addon.version)
    --Add panel to interface
    local category, layout = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name);
    Settings.RegisterAddOnCategory(category);
    KSR.settingsCategory = category
end
