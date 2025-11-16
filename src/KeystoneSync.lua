--KeystoneSync.lua
--Custom keystone sync fallback when LibOpenRaid is unavailable

local _, KSR = ...

-- Initialize AceComm
local AceComm = LibStub("AceComm-3.0")
local AceSerializer = LibStub("AceSerializer-3.0")
local LibDeflate = LibStub("LibDeflate")

-- Communication prefix
local COMM_PREFIX = "KSR_KS"
local COMM_VERSION = 1

-- Storage for keystone data (format compatible with LibOpenRaid)
KSR.keystoneSyncData = KSR.keystoneSyncData or {}

-- Request timeout (seconds)
local REQUEST_TIMEOUT = 5

-- Track pending requests
local pendingRequests = {}

-- Get player's keystone info
local function GetPlayerKeystone()
    -- Try the owned keystone API first (keystone in bags)
    local mapID = C_MythicPlus.GetOwnedKeystoneChallengeMapID()
    local level = C_MythicPlus.GetOwnedKeystoneLevel()
    
    KSR.debugPrint("GetPlayerKeystone: (Owned) mapID=" .. tostring(mapID) .. ", level=" .. tostring(level) .. " (type: " .. type(mapID) .. ", " .. type(level) .. ")")
    
    -- Fallback: If owned keystone is not available, try active keystone (set for dungeon run)
    -- This covers the case where you're inside a Mythic+ dungeon and the keystone is "active" 
    -- but not in your bags (it's been used/activated for the current run)
    if not mapID or mapID == 0 or not level or level == 0 then
        local activeLevel, activeKeystoneInfo, isActive = C_ChallengeMode.GetActiveKeystoneInfo()
        KSR.debugPrint("GetPlayerKeystone: (Active fallback) level=" .. tostring(activeLevel) .. ", keystoneInfo=" .. tostring(activeKeystoneInfo) .. ", isActive=" .. tostring(isActive))
        
        if isActive and activeLevel and activeLevel > 0 then
            local activeMapID = C_ChallengeMode.GetActiveChallengeMapID()
            KSR.debugPrint("GetPlayerKeystone: (Active fallback) activeMapID=" .. tostring(activeMapID))
            
            if activeMapID and activeMapID > 0 then
                mapID = activeMapID
                level = activeLevel
                KSR.debugPrint("GetPlayerKeystone: Using active keystone as fallback - " .. mapID .. " +" .. level)
            end
        end
    end
    
    -- Check that both are numbers and valid (mapID > 0, level > 0)
    if type(mapID) == "number" and type(level) == "number" and mapID > 0 and level > 0 then
        local keystone = {
            challengeMapID = mapID,
            level = level
        }
        KSR.debugPrint("GetPlayerKeystone: Valid keystone found - " .. mapID .. " +" .. level)
        return keystone
    end
    
    KSR.debugPrint("GetPlayerKeystone: No valid keystone (returning nil)")
    return nil
end

-- Send keystone data to a specific player
local function SendKeystoneToPlayer(target)
    local keystone = GetPlayerKeystone()
    if not keystone then
        KSR.debugPrint("SendKeystoneToPlayer: No keystone to send to " .. target)
        return
    end
    
    local playerName = UnitName("player")
    local data = {
        v = COMM_VERSION,
        player = playerName,
        keystone = keystone
    }
    
    local serialized = AceSerializer:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
    
    AceComm:SendCommMessage(COMM_PREFIX, encoded, "WHISPER", target)
    KSR.debugPrint("Sent keystone to " .. target)
end

-- Broadcast keystone request to party
local function RequestKeystones()
    if not IsInGroup() or IsInRaid() then
        return
    end
    
    local playerName = UnitName("player")
    local data = {
        v = COMM_VERSION,
        type = "REQUEST",
        from = playerName
    }
    
    local serialized = AceSerializer:Serialize(data)
    local compressed = LibDeflate:CompressDeflate(serialized)
    local encoded = LibDeflate:EncodeForWoWAddonChannel(compressed)
    
    AceComm:SendCommMessage(COMM_PREFIX, encoded, "PARTY")
    KSR.debugPrint("Requested keystones from party")
    
    -- Set timeout to clear pending request
    pendingRequests[playerName] = GetTime()
    C_Timer.After(REQUEST_TIMEOUT, function()
        if pendingRequests[playerName] then
            pendingRequests[playerName] = nil
            -- Trigger update after timeout
            if KSR.OnKeystoneSyncUpdate then
                KSR.OnKeystoneSyncUpdate()
            end
        end
    end)
end

-- Handle incoming comm messages
local function OnCommReceived(prefix, message, distribution, sender)
    if prefix ~= COMM_PREFIX then
        return
    end
    
    local decoded = LibDeflate:DecodeForWoWAddonChannel(message)
    if not decoded then
        KSR.debugPrint("Failed to decode message from " .. sender)
        return
    end
    
    local decompressed = LibDeflate:DecompressDeflate(decoded)
    if not decompressed then
        KSR.debugPrint("Failed to decompress message from " .. sender)
        return
    end
    
    local success, data = AceSerializer:Deserialize(decompressed)
    if not success or not data or not data.v then
        KSR.debugPrint("Failed to deserialize message from " .. sender)
        return
    end
    
    if data.v ~= COMM_VERSION then
        KSR.debugPrint("Version mismatch from " .. sender)
        return
    end
    
    -- Handle request
    if data.type == "REQUEST" then
        KSR.debugPrint("OnCommReceived: Received REQUEST from " .. sender)
        if sender ~= UnitName("player") then
            KSR.debugPrint("OnCommReceived: Sending keystone to " .. sender)
            SendKeystoneToPlayer(sender)
        else
            KSR.debugPrint("OnCommReceived: Ignoring request from self")
        end
        return
    end
    
    -- Handle keystone data
    if data.player and data.keystone then
        local fullName = data.player
        -- Add realm if not present
        if not string.find(fullName, "-") then
            local realm = GetRealmName()
            fullName = fullName .. "-" .. realm
        end
        
        -- Store keystone data (format compatible with LibOpenRaid)
        KSR.keystoneSyncData[fullName] = {
            challengeMapID = data.keystone.challengeMapID,
            level = data.keystone.level
        }
        
        KSR.debugPrint("Received keystone from " .. fullName)
        
        -- Trigger update callback
        if KSR.OnKeystoneSyncUpdate then
            KSR.OnKeystoneSyncUpdate()
        end
    end
end

-- Register comm handler
AceComm:RegisterComm(COMM_PREFIX, OnCommReceived)

-- Initialize sync data with player's own keystone
local function InitializeSync()
    KSR.debugPrint("InitializeSync: Starting initialization")
    local keystone = GetPlayerKeystone()
    if keystone then
        local playerName = UnitName("player")
        local realm = GetRealmName()
        local fullName = playerName .. "-" .. realm
        
        KSR.keystoneSyncData[fullName] = {
            challengeMapID = keystone.challengeMapID,
            level = keystone.level
        }
        KSR.debugPrint("InitializeSync: Stored own keystone - " .. fullName .. ": " .. keystone.challengeMapID .. " +" .. keystone.level)
    else
        KSR.debugPrint("InitializeSync: No keystone to store")
    end
end

-- Clean up keystone data for players no longer in party
local function CleanupStaleData()
    if not IsInGroup() or IsInRaid() then
        return
    end
    
    local partyMembers = {}
    local playerName = UnitName("player")
    local realm = GetRealmName()
    partyMembers[playerName .. "-" .. realm] = true
    
    -- Get all party member names using GetRosterInfo
    local numMembers = GetNumGroupMembers()
    for i = 1, numMembers do
        local name, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, realm = GetRosterInfo(i)
        if name then
            local fullName = realm and (name .. "-" .. realm) or (name .. "-" .. GetRealmName())
            partyMembers[fullName] = true
        end
    end
    
    -- Remove data for players not in party
    for name, _ in pairs(KSR.keystoneSyncData) do
        if not partyMembers[name] then
            KSR.keystoneSyncData[name] = nil
        end
    end
end

-- Get all keystone data (compatible with LibOpenRaid format)
KSR.GetSyncKeystoneData = function()
    KSR.debugPrint("GetSyncKeystoneData: Called")
    -- Clean up stale data first
    CleanupStaleData()
    
    -- Update player's own keystone
    local keystone = GetPlayerKeystone()
    local playerName = UnitName("player")
    local realm = GetRealmName()
    local fullName = playerName .. "-" .. realm
    
    if keystone then
        KSR.keystoneSyncData[fullName] = {
            challengeMapID = keystone.challengeMapID,
            level = keystone.level
        }
        KSR.debugPrint("GetSyncKeystoneData: Updated own keystone - " .. fullName .. ": " .. keystone.challengeMapID .. " +" .. keystone.level)
    else
        -- Remove player's keystone if they don't have one
        KSR.keystoneSyncData[fullName] = nil
        KSR.debugPrint("GetSyncKeystoneData: Removed own keystone (no keystone)")
    end
    
    -- Request keystones from party (only if in a party)
    if IsInGroup() and not IsInRaid() then
        KSR.debugPrint("GetSyncKeystoneData: In party, requesting keystones")
        RequestKeystones()
    else
        KSR.debugPrint("GetSyncKeystoneData: Not in party (solo or raid) - only own keystone will be included")
    end
    
    -- Log current sync data
    local count = 0
    for name, data in pairs(KSR.keystoneSyncData) do
        count = count + 1
        KSR.debugPrint("GetSyncKeystoneData: Sync data[" .. count .. "] - " .. name .. ": " .. data.challengeMapID .. " +" .. data.level)
    end
    if count == 0 then
        KSR.debugPrint("GetSyncKeystoneData: No keystones in sync data")
    end
    
    return KSR.keystoneSyncData
end

-- Clear sync data (call when leaving group)
KSR.ClearSyncData = function()
    KSR.keystoneSyncData = {}
    pendingRequests = {}
end

-- Initialize on load
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("GROUP_LEFT")
frame:RegisterEvent("GROUP_ROSTER_UPDATE")
frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        InitializeSync()
    elseif event == "GROUP_LEFT" then
        KSR.ClearSyncData()
    elseif event == "GROUP_ROSTER_UPDATE" then
        -- When group changes, request keystones if in a party
        if IsInGroup() and not IsInRaid() then
            -- Small delay to ensure group is fully updated
            C_Timer.After(0.5, function()
                if IsInGroup() and not IsInRaid() then
                    RequestKeystones()
                end
            end)
        end
    end
end)

-- Also update when keystone changes
local keystoneFrame = CreateFrame("Frame")
keystoneFrame:RegisterEvent("CHALLENGE_MODE_COMPLETED")
keystoneFrame:SetScript("OnEvent", function()
    InitializeSync()
    if IsInGroup() and not IsInRaid() then
        RequestKeystones()
    end
end)

