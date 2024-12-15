--Config.lua

local _, KSR = ...

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
}
