--KeystoneRoulette.lua

local addonName, KSR = ...

---@class f:Frame
local f = CreateFrame("Frame")

function f:ADDON_LOADED(addon)
    if addon == "KeystoneRoulette" then
        KeystoneRouletteDB = KeystoneRouletteDB or CopyTable(KSR.addonDefaults)
        KSR.debugPrint(addonName .. " v" .. KSR.addon.version .. " is loaded.")
        KSR.InitOptions()
    end
end

f:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

f:RegisterEvent("ADDON_LOADED")
