--Config.lua

local _, KSR = ...

--Register the Wago Analytics lib.
KSR.WagoAnalytics = LibStub("WagoAnalytics"):Register("b6mbVnKP")

--OpenRaid Lib (may be nil if not available)
--KSR.openRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0", true) -- true = silent, returns nil if not found
-- Comment out the line above and uncomment the line below to disable LibOpenRaid while developing
KSR.openRaidLib = nil -- nil while development

-- Check if LibOpenRaid is available and functional
KSR.IsLibOpenRaidAvailable = function()
    if not KSR.openRaidLib then
        return false
    end
    
    -- Check if the library has the required method
    if not KSR.openRaidLib.GetAllKeystonesInfo then
        return false
    end
    
    -- Try to call it and see if it works (catch any errors)
    local success, result = pcall(function()
        return KSR.openRaidLib.GetAllKeystonesInfo()
    end)
    
    return success
end

--Addon information parsed from TOC
KSR.addon = {
    title = C_AddOns.GetAddOnMetadata("KeystoneRoulette", "Title"),
    version = C_AddOns.GetAddOnMetadata("KeystoneRoulette", "Version")
}

--Placeholder for settings category
KSR.settingsCategory = nil

--Default configuration
KSR.addonDefaults = {
    debug = false
}

--Helper color codes
KSR.colors = {
    PRIMARY = "ff45D388",
    WHITE = "ffFFFFFF",
    YELLOW = "ffFFFF00",
    RED = "ffFF0000",
}
