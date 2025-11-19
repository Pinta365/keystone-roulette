--Config.lua

local _, KSR = ...

KSR.WagoAnalytics = LibStub("WagoAnalytics"):Register("b6mbVnKP")
KSR.libKeystone = LibStub("LibKeystone", true)
KSR.openRaidLib = LibStub("LibOpenRaid-1.0", true)

KSR.libKeystoneTable = {}
KSR.libKeystoneData = {}

KSR.IsLibKeystoneAvailable = function()
    return KSR.libKeystone ~= nil
end

KSR.IsLibOpenRaidAvailable = function()
    if not KSR.openRaidLib then
        return false
    end
    
    if not KSR.openRaidLib.GetAllKeystonesInfo then
        return false
    end
    
    local success, result = pcall(function()
        return KSR.openRaidLib.GetAllKeystonesInfo()
    end)
    
    return success
end

KSR.InitializeLibKeystone = function()
    if not KSR.IsLibKeystoneAvailable() then
        return
    end
    
    KSR.libKeystone.Register(KSR.libKeystoneTable, KSR.OnLibKeystoneData)
    KSR.debugPrint("InitializeLibKeystone: Registered LibKeystone callback")
    
    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    
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
        local _, _, fullName = KSR.GetPlayerInfo()
        
        KSR.libKeystoneData[fullName] = {
            challengeMapID = mapID,
            level = level
        }
        KSR.debugPrint("InitializeLibKeystone: Initialized own keystone - " .. fullName .. ": " .. mapID .. " +" .. level)
    else
        KSR.debugPrint("InitializeLibKeystone: Player has no keystone (mapID=" .. tostring(mapID) .. ", level=" .. tostring(level) .. ")")
    end
end

KSR.ClearLibKeystoneData = function()
    KSR.libKeystoneData = {}
    KSR.debugPrint("ClearLibKeystoneData: Cleared LibKeystone data")
end

KSR.addon = {
    title = C_AddOns.GetAddOnMetadata("KeystoneRoulette", "Title"),
    version = C_AddOns.GetAddOnMetadata("KeystoneRoulette", "Version")
}

KSR.settingsCategory = nil

KSR.addonDefaults = {
    debug = false
}

KSR.colors = {
    PRIMARY = "ff45D388",
    WHITE = "ffFFFFFF",
    YELLOW = "ffFFFF00",
    RED = "ffFF0000",
}

KSR.constants = {
    REQUEST_DELAY = 1.0,
    SPIN_DURATION = 2.0,
}

KSR.playerInfo = {
    name = nil,
    realm = nil,
    fullName = nil,
}

KSR.IsInParty = function()
    return IsInGroup() and not IsInRaid()
end

KSR.GetPlayerInfo = function()
    if not KSR.playerInfo.name then
        KSR.playerInfo.name = UnitName("player")
        KSR.playerInfo.realm = GetRealmName()
        KSR.playerInfo.fullName = KSR.playerInfo.name .. "-" .. KSR.playerInfo.realm
    end
    return KSR.playerInfo.name, KSR.playerInfo.realm, KSR.playerInfo.fullName
end

KSR.ClearPlayerInfo = function()
    KSR.playerInfo.name = nil
    KSR.playerInfo.realm = nil
    KSR.playerInfo.fullName = nil
end