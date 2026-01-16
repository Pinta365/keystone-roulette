--Keystone.lua

local _, KSR = ...

local ANNOUNCEMENT_PHRASES = {
    "has been chosen for a glorious adventure!",
    "has been deemed worthy by the dungeon gods!",
    "awaits your valiant efforts!",
    "is the next stop on your path to greatness!",
    "beckons you to face its challenges!",
    "has been selected by the titans themselves!",
    "will test your skills and teamwork!",
    "holds the key to untold riches and glory!",
    "is ready to be conquered!",
    "is where legends will be made!",
    "has been randomly selected for pain and suffering!",
    "is the lucky winner of this week's torture chamber!",
    "was chosen by a very sophisticated algorithm (a dice roll).",
    "is the next stop on this pain train.",
    "well who expected to go back here for the millionth time!",
    "needs your help champion!",
    "fast in, fast out!",
    "beckons! Answer the call!",
    "because 'fun' is subjective, right?",
    "is the next chapter in your epic saga!",
    "has been RNG'd into existence!",
    "is your destiny... or at least your next 30 minutes!",
    "awaits! May the affixes be ever in your favor!",
    "has been chosen! Time to prove you're not just a pretty transmog!",
    "is calling! Better answer before it calls someone else!",
    "has been selected! No refunds, no exchanges!",
    "is your next challenge! Remember: dying is just a minor inconvenience!",
    "has been picked! Let's hope your healer is awake!",
    "awaits your arrival! Bring snacks, it might take a while!",
    "has been chosen! May your interrupts be many and your deaths be few!",
    "is ready! Time to show those mobs who's boss!",
    "has been selected! Good luck, you're gonna need it!",
    "awaits! Don't forget to bring your A-game... and maybe a rez!",
    "has been picked! Time to make some memories (and possibly some mistakes)!",
    "is your next adventure! Let's make it count!",
    "has been chosen! May the odds be ever in your favor!",
    "has been selected! Remember: it's not about the destination, it's about the wipes along the way!",
    "is ready! Time to show Azeroth what you're made of!",
    "has been picked! Let's turn this into a success story!"
}

---Abbreviates a dungeon name using its map ID.
---@param challengeMapID number the challenge map ID of the dungeon
---@return string the abbreviated dungeon name
local function AbbreviateDungeonName(challengeMapID)
    local abbreviations = {
        --The War Within S1
        [501] = "SV",     -- The Stonevault
        [502] = "COT",    -- City of Threads
        [503] = "ARAK",   -- Ara-Kara, City of Echoes
        [505] = "DAWN",   -- The Dawnbreaker
        [353] = "SIEGE",  -- Siege of Boralus
        [375] = "MISTS",  -- Mists of Tirna Scithe
        [376] = "NW",     -- Necrotic Wake
        [507] = "GB",     -- Grim Batol

        --The War Within S2
        [499] = "PSF",    -- Priory of the Sacred Flame
        [500] = "ROOK",   -- The Rookery          
        [504] = "DFC",    -- Darkflame Cleft
        [506] = "BREW",   -- Cinderbrew Meadery
        [247] = "ML",     -- The MOTHERLODE!!
        [382] = "TOP",    -- Theater of Pain
        [370] = "WORK",   -- Operation: Mechagon - Workshop
        [525] = "FLOOD",  -- Operation: Floodgate

        -- The War Within S3, New IDs
        [542] = "EDA",    -- Eco-Dome Al'dani
        [378] = "HOA",    -- Halls of Atonement
        [391] = "STRT",   -- Tazavesh: Streets of Wonder 
        [392] = "GMBT",   -- Tazavesh: So'leah's Gambit 
        -- The War Within S3, Already added
        --Dawnbreaker (Season 1)
        --Ara-Kara, City of Echoes (Season 1)
        --Operation: Floodgate (Season 2)
        --Priory of Sacred Flame (Season 2)

        --Legion Remix
        [199] = "BRH",    -- Black Rook Hold
        [233] = "COEN",   -- Cathedral of Eternal Night
        [210] = "COS",    -- Court of Stars
        [198] = "DHT",    -- Darkheart Thicket
        [197] = "EOA",    -- Eye of Azshara
        [200] = "HOV",    -- Halls of Valor
        [208] = "MOS",    -- Maw of Souls
        [206] = "NL",     -- Neltharion's Lair
        [227] = "LOWR",   -- Return to Karazhan: Lower
        [234] = "UPPR",   -- Return to Karazhan: Upper
        [239] = "SEAT",   -- Seat of the Triumvirate
        [209] = "ARC",    -- The Arcway
        [207] = "VOTW",   -- Vault of the Wardens

        --Midnight Season 1
        [402] = "AA",     -- Algeth'ar Academy
        [558] = "MT",     -- Magisters' Terrace
        [560] = "MC",     -- Maisara Caverns
        [559] = "NPX",    -- Nexus-Point Xenas
        [556] = "POS",    -- Pit of Saron
                          -- Seat of the Triumvirate (already added in Legion Remix section)
        [161] = "SR",     -- Skyreach
        [557] = "WS",     -- Windrunner Spire

    }
    return abbreviations[challengeMapID]
end

local function NormalizePlayerName(playerName)
    if not playerName then
        return nil
    end
    local namePart = ({strsplit("-", playerName)})[1]
    return namePart
end

local function PlayerExistsInData(keystoneData, playerName, challengeMapID, level)
    local normalizedName = NormalizePlayerName(playerName)
    if not normalizedName then
        return false
    end
    
    for existingName, existingInfo in pairs(keystoneData) do
        local existingNormalizedName = NormalizePlayerName(existingName)
        if existingNormalizedName == normalizedName and 
           existingInfo.challengeMapID == challengeMapID and 
           existingInfo.level == level then
            return true
        end
    end
    
    return false
end

local function CountTableEntries(t)
    if not t then return 0 end
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

KSR.OnLibKeystoneData = function(keyLevel, keyMapID, playerRating, playerName, channel)
    if channel ~= "PARTY" then
        return
    end
    
    KSR.debugPrint("OnLibKeystoneData: Received - " .. playerName .. ": " .. keyMapID .. " +" .. keyLevel .. " (channel: " .. channel .. ")")
    
    local fullName = playerName
    if not string.find(fullName, "-") then
        local _, realm = KSR.GetPlayerInfo()
        fullName = fullName .. "-" .. realm
    end
    
    KSR.libKeystoneData[fullName] = {
        challengeMapID = keyMapID,
        level = keyLevel
    }
    
    if KSR.OnKeystoneSyncUpdate then
        KSR.OnKeystoneSyncUpdate()
    end
end

---Retrieves keystone data for all party members.
---@return table table containing keystone information for each party member with a keystone.
KSR.GetPartyKeystoneData = function()
    KSR.debugPrint("GetPartyKeystoneData: Called")
    local keys = {}
    local keystoneData = {}

    if KSR.IsLibKeystoneAvailable() then
        KSR.debugPrint("GetPartyKeystoneData: LibKeystone is available, checking stored data")
        
        local dataCount = CountTableEntries(KSR.libKeystoneData)
        
        if dataCount > 0 then
            for playerName, keystoneInfo in pairs(KSR.libKeystoneData) do
                keystoneData[playerName] = keystoneInfo
            end
            KSR.debugPrint("GetPartyKeystoneData: LibKeystone returned " .. dataCount .. " entries")
        else
            KSR.debugPrint("GetPartyKeystoneData: LibKeystone has no stored data yet")
        end
    end

    if KSR.IsLibOpenRaidAvailable() then
        KSR.debugPrint("GetPartyKeystoneData: LibOpenRaid is available, merging data")
        if KSR.IsInParty() or GetNumSubgroupMembers() == 0 then
            local success, result = pcall(function()
                return KSR.openRaidLib.GetAllKeystonesInfo()
            end)
            
            if success and result then
                local openRaidCount = 0
                for playerName, keystoneInfo in pairs(result) do
                    if not PlayerExistsInData(keystoneData, playerName, keystoneInfo.challengeMapID, keystoneInfo.level) then
                        keystoneData[playerName] = keystoneInfo
                        openRaidCount = openRaidCount + 1
                    else
                        KSR.debugPrint("GetPartyKeystoneData: Skipping duplicate from LibOpenRaid - " .. playerName .. " (already in LibKeystone data)")
                    end
                end
                KSR.debugPrint("GetPartyKeystoneData: LibOpenRaid added " .. openRaidCount .. " additional entries")
            else
                KSR.debugPrint(WrapTextInColorCode("LibOpenRaid failed", KSR.colors["YELLOW"]))
            end
        end
    end

    local keystoneArray = {}
    for unitName, keystoneInfo in pairs(keystoneData) do
        if keystoneInfo and keystoneInfo.challengeMapID and keystoneInfo.level and keystoneInfo.level > 0 then
            table.insert(keystoneArray, {
                unitName = unitName,
                challengeMapID = keystoneInfo.challengeMapID,
                level = keystoneInfo.level
            })
        end
    end
        
    if #keystoneArray == 0 then
        KSR.debugPrint("GetPartyKeystoneData: No valid keystones found after processing")
        return keys
    end
    
    KSR.debugPrint("GetPartyKeystoneData: Converted to array, " .. #keystoneArray .. " keystones")
    
    table.sort(keystoneArray, function (t1, t2) return t1.level > t2.level end)
    
    local i = 0
    local playerName, playerRealm, playerFullName = KSR.GetPlayerInfo()
    
    for _, entry in ipairs(keystoneArray) do
        local unitName = entry.unitName
        local challengeMapID = entry.challengeMapID
        local level = entry.level
        
        local name = C_ChallengeMode.GetMapUIInfo(challengeMapID)
        local abbrName = AbbreviateDungeonName(challengeMapID)

        local isPlayer = (unitName == playerName) or (unitName == playerFullName) or 
                        (string.find(unitName, "^" .. playerName .. "-") ~= nil)
        
        if UnitInParty(unitName) or isPlayer then
            if not name then
                name = "Unknown dungeon"
                KSR.debugPrint(WrapTextInColorCode("Undefined dungeon found! mapID=" .. tostring(challengeMapID), KSR.colors["RED"]))
            end

            if not abbrName then
                abbrName = "???"
                KSR.debugPrint(WrapTextInColorCode("Undefined dungeon abbreviation! mapID=" .. tostring(challengeMapID), KSR.colors["RED"]))
            end

            i = i + 1
            keys[i] = {
                player = ({strsplit("-", unitName)})[1],
                dungeon = name,
                abbr = abbrName,
                level = level
            }
            KSR.debugPrint("GetPartyKeystoneData: Added keystone " .. i .. " - " .. keys[i].player .. ": " .. keys[i].dungeon .. " +" .. keys[i].level)
        end
    end
    
    KSR.debugPrint("GetPartyKeystoneData: Returning " .. #keys .. " keystones (merged from LibKeystone and LibOpenRaid)")
    return keys
end

---Chooses a random keystone from a list of keystones.
---@param keys table table containing keystone information
---@return table|nil randomly chosen keystone data, or nil if no keystones are found
KSR.ChooseRandomKeystone = function(keys)
    if not keys or #keys == 0 then
        return nil
    end
    local randomIndex = math.random(1, #keys)
    return keys[randomIndex]
end

---Announces the chosen keystone to party chat and lists all available keystones.
---@param keys table table containing keystone information for all party members
---@param chosenKey table the keystone data that was randomly chosen
---@---@param dryrun boolean (optional) if true, performs a dry run and prints to console instead of party chat
KSR.AnnounceKeystone = function(keys, chosenKey, dryrun)
    local playerName = chosenKey.player
    local dungeonName = chosenKey.dungeon
    local keystoneLevel = chosenKey.level

    local announcementParts = {}
    table.insert(announcementParts, playerName)
    if not string.match(playerName, "s$") then
        table.insert(announcementParts, "'s")
    end

    table.insert(announcementParts, string.format(" %s +%d ", dungeonName, keystoneLevel))
    table.insert(announcementParts, ANNOUNCEMENT_PHRASES[math.random(1, #ANNOUNCEMENT_PHRASES)])

    local message = table.concat(announcementParts)
    local line = "----------------------------------------------------"
    print(WrapTextInColorCode(line, KSR.colors["YELLOW"]))
    print(WrapTextInColorCode("Keystone Roulette - Available Keys:", KSR.colors["YELLOW"]))
    print(WrapTextInColorCode(line, KSR.colors["YELLOW"]))
    for i, key in ipairs(keys) do
        local keyString = string.format("%d. %s - %s +%d", i, key.player, key.dungeon, key.level)
        print(WrapTextInColorCode(keyString, KSR.colors["PRIMARY"]))
    end
    print(WrapTextInColorCode(line, KSR.colors["YELLOW"]))

    local prefix = "Keystone Roulette: "
    message = prefix .. message

    if KeystoneRouletteDB.debug then
        print(message)
    else
        if dryrun or not KSR.IsInParty() then
            print(message)
        else
            SendChatMessage(message, "PARTY")
        end
    end

    local keyListParts = {"Available keys were: "}
    for i, key in ipairs(keys) do
        table.insert(keyListParts, string.format("%s+%d", key.abbr, key.level))
        if i < #keys then
            table.insert(keyListParts, ", ")
        end
    end
    local keyList = table.concat(keyListParts)

    if KeystoneRouletteDB.debug then
        print(keyList)
    else
        if dryrun then
            print(keyList)
        elseif not KSR.IsInParty() then
            print(keyList)
            print(WrapTextInColorCode("You should get some friends and form a party for this to be printed to everyone.", KSR.colors["YELLOW"]))
        else
            SendChatMessage(keyList, "PARTY")
        end
    end
end

---Performs the keystone roulette, choosing a random keystone and announcing it to the party.
---@param dryrun boolean (optional) if true, performs a dry run and prints to console instead of party chat
KSR.RouletteKeystone = function(dryrun)
    local keys = KSR.GetPartyKeystoneData()
    local chosenKey = KSR.ChooseRandomKeystone(keys)

    if chosenKey and keys then
        KSR.AnnounceKeystone(keys, chosenKey, dryrun)
        return
    end
    
    local errorMessage
    if not keys or #keys == 0 then
        errorMessage = "Keystone Roulette: No keystones found in the party!"
    else
        errorMessage = "Keystone Roulette: An error occurred. Please try again."
    end
    
    if KSR.IsInParty() then
        SendChatMessage(errorMessage, "PARTY")
    else
        local color = (not keys or #keys == 0) and KSR.colors["YELLOW"] or KSR.colors["RED"]
        print(WrapTextInColorCode(errorMessage, color))
    end
end

---Sends an emote showing the player peeking through the group's keystones.
KSR.PeekKeystones = function()
    local keys = KSR.GetPartyKeystoneData()
    
    if not keys or #keys == 0 then
        local errorMessage = "Keystone Roulette: No keystones found in the party!"
        if KSR.IsInParty() then
            SendChatMessage(errorMessage, "PARTY")
        else
            print(WrapTextInColorCode(errorMessage, KSR.colors["YELLOW"]))
        end
        return
    end
    
    -- Format keystones as "ABBR+LEVEL, ABBR+LEVEL and ABBR+LEVEL"
    local keystoneParts = {}
    for i, key in ipairs(keys) do
        table.insert(keystoneParts, string.format("%s+%d", key.abbr, key.level))
    end
    
    local keystoneList
    if #keystoneParts == 1 then
        keystoneList = keystoneParts[1]
    elseif #keystoneParts == 2 then
        keystoneList = keystoneParts[1] .. " and " .. keystoneParts[2]
    else
        local lastKey = table.remove(keystoneParts)
        keystoneList = table.concat(keystoneParts, ", ") .. " and " .. lastKey
    end
    
    local emoteMessage = string.format("peeks through the group's keystones and sees %s", keystoneList)
    
    SendChatMessage(emoteMessage, "EMOTE")
end


