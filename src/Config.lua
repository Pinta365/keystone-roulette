--Config.lua

local _, KSR = ...

--Register the Wago Analytics lib.
KSR.WagoAnalytics = LibStub("WagoAnalytics"):Register("b6mbVnKP")

--LibKeystone (primary library)
KSR.libKeystone = LibStub("LibKeystone", true) -- true = silent, returns nil if not found

--LibOpenRaid (fallback for party sync, optional - not packaged)
KSR.openRaidLib = LibStub("LibOpenRaid-1.0", true) -- true = silent, returns nil if not found

-- Unique table for LibKeystone registration
KSR.libKeystoneTable = {}

-- Storage for LibKeystone data
KSR.libKeystoneData = {}

-- Check if LibKeystone is available
KSR.IsLibKeystoneAvailable = function()
    return KSR.libKeystone ~= nil
end

-- Check if LibOpenRaid is available and functional (fallback for party sync)
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

-- Initialize LibKeystone (register callback and initialize player's own keystone data)
KSR.InitializeLibKeystone = function()
    if not KSR.IsLibKeystoneAvailable() then
        return
    end
    
    -- Register callback to receive keystone data (keep registered to receive updates)
    KSR.libKeystone.Register(KSR.libKeystoneTable, KSR.OnLibKeystoneData)
    KSR.debugPrint("InitializeLibKeystone: Registered LibKeystone callback")
    
    -- Initialize player's own keystone data
    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    
    -- Fallback to active keystone if owned is not available
    if not mapID or mapID == 0 or not level or level == 0 then
        local activeLevel, activeKeystoneInfo, isActive = C_ChallengeMode.GetActiveKeystoneInfo()
        if isActive and activeLevel and activeLevel > 0 then
            local activeMapID = C_ChallengeMode.GetActiveChallengeMapID()
            if activeMapID and activeMapID > 0 then
                mapID = activeMapID
                level = activeLevel
            end
        end
    end
    
    if mapID and mapID > 0 and level and level > 0 then
        local playerName = UnitName("player")
        local realm = GetRealmName()
        local fullName = playerName .. "-" .. realm
        
        KSR.libKeystoneData[fullName] = {
            challengeMapID = mapID,
            level = level
        }
        KSR.debugPrint("InitializeLibKeystone: Initialized own keystone - " .. fullName .. ": " .. mapID .. " +" .. level)
    else
        KSR.debugPrint("InitializeLibKeystone: Player has no keystone (mapID=" .. tostring(mapID) .. ", level=" .. tostring(level) .. ")")
    end
end

-- Clear LibKeystone data (call when leaving group)
KSR.ClearLibKeystoneData = function()
    KSR.libKeystoneData = {}
    KSR.debugPrint("ClearLibKeystoneData: Cleared LibKeystone data")
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
