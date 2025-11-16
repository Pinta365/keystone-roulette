--Keystone.lua

local _, KSR = ...

---Abbreviates a dungeon name using its map ID.
---@param challengeMapID number the challenge map ID of the dungeon
---@return string the abbreviated dungeon name
local function AbbreviateDungeonName(challengeMapID)
    local abbreviations = {
        --The War Within S1
        [501] = "SV",     -- The Stonevault
        [502] = "COT",    -- City of Threads
        [503] = "ARA",    -- Ara-Kara, City of Echoes
        [505] = "DB",     -- The Dawnbreaker
        [353] = "SOB",    -- Siege of Boralus
        [375] = "MOTS",   -- Mists of Tirna Scithe
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
        [542] = "ED",     --Eco-Dome Al'dani
        [378] = "HoA",    --Halls of Atonement
        [391] = "T1:SoW", --Tazavesh: Streets of Wonder 
        [392] = "T2:SG",  --Tazavesh: So'leah's Gambit 
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
        [227] = "KARA:L", -- Return to Karazhan: Lower
        [234] = "KARA:U", -- Return to Karazhan: Upper
        [239] = "SOT",    -- Seat of the Triumvirate
        [209] = "ARC",    -- The Arcway
        [207] = "VOTW",   -- Vault of the Wardens
    }
    return abbreviations[challengeMapID]
end

-- Helper function to normalize player name (extract name part before "-")
local function NormalizePlayerName(playerName)
    if not playerName then
        return nil
    end
    -- Extract name part (before "-")
    local namePart = ({strsplit("-", playerName)})[1]
    return namePart
end

-- Helper function to check if a player already exists in keystone data
local function PlayerExistsInData(keystoneData, playerName, challengeMapID, level)
    local normalizedName = NormalizePlayerName(playerName)
    if not normalizedName then
        return false
    end
    
    for existingName, existingInfo in pairs(keystoneData) do
        local existingNormalizedName = NormalizePlayerName(existingName)
        -- Check if name matches and keystone info matches (same player, same keystone)
        if existingNormalizedName == normalizedName and 
           existingInfo.challengeMapID == challengeMapID and 
           existingInfo.level == level then
            return true
        end
    end
    
    return false
end

-- LibKeystone callback handler
KSR.OnLibKeystoneData = function(keyLevel, keyMapID, playerRating, playerName, channel)
    KSR.debugPrint("OnLibKeystoneData: Received - " .. playerName .. ": " .. keyMapID .. " +" .. keyLevel .. " (channel: " .. channel .. ")")
    
    local fullName = playerName
    -- Add realm if not present
    if not string.find(fullName, "-") then
        local realm = GetRealmName()
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

    -- Get data from LibKeystone if available
    if KSR.IsLibKeystoneAvailable() then
        KSR.debugPrint("GetPartyKeystoneData: LibKeystone is available, checking stored data")
        
        local dataCount = 0
        if KSR.libKeystoneData then
            for _ in pairs(KSR.libKeystoneData) do
                dataCount = dataCount + 1
            end
        end
        
        if dataCount > 0 then
            for playerName, keystoneInfo in pairs(KSR.libKeystoneData) do
                keystoneData[playerName] = keystoneInfo
            end
            KSR.debugPrint("GetPartyKeystoneData: LibKeystone returned " .. dataCount .. " entries")
        else
            KSR.debugPrint("GetPartyKeystoneData: LibKeystone has no stored data yet")
        end
    end

    -- Also get data from LibOpenRaid if available (merge with LibKeystone data)
    if KSR.IsLibOpenRaidAvailable() then
        KSR.debugPrint("GetPartyKeystoneData: LibOpenRaid is available, merging data")
        if (IsInGroup() and not IsInRaid()) or GetNumSubgroupMembers() == 0 then
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

    if keystoneData then
        local keystoneArray = {}
        for unitName, keystoneInfo in pairs(keystoneData) do
            if keystoneInfo and keystoneInfo.challengeMapID and keystoneInfo.level then
                table.insert(keystoneArray, {
                    unitName = unitName,
                    challengeMapID = keystoneInfo.challengeMapID,
                    level = keystoneInfo.level
                })
            end
        end
        
        KSR.debugPrint("GetPartyKeystoneData: Converted to array, " .. #keystoneArray .. " keystones")
        
        table.sort(keystoneArray, function (t1, t2) return t1.level > t2.level end)
        
        local i = 0
        local playerName = UnitName("player")
        local playerRealm = GetRealmName()
        local playerFullName = playerName .. "-" .. playerRealm
        
        for _, entry in ipairs(keystoneArray) do
            local unitName = entry.unitName
            local keystoneInfo = {
                challengeMapID = entry.challengeMapID,
                level = entry.level
            }
            
            local name = C_ChallengeMode.GetMapUIInfo(keystoneInfo.challengeMapID)
            local abbrName = AbbreviateDungeonName(keystoneInfo.challengeMapID)

            local isPlayer = (unitName == playerName) or (unitName == playerFullName) or 
                            (string.find(unitName, "^" .. playerName .. "-") ~= nil)
            
            if (UnitInParty(unitName) or isPlayer) and keystoneInfo.level > 0 then
                if not name then
                    name = "Unknown dungeon"
                    KSR.debugPrint(WrapTextInColorCode("Undefined dungeon found!", KSR.colors["RED"]))
                    KSR.debugPrint(keystoneInfo)
                end

                if not abbrName then
                    abbrName = "???"
                    KSR.debugPrint(WrapTextInColorCode("Undefined dungeon abbreviation!", KSR.colors["RED"]))
                    KSR.debugPrint(keystoneInfo)
                end

                i = i + 1
                keys[i] = {
                    player = ({strsplit("-", unitName)})[1],
                    dungeon = name,
                    abbr = abbrName,
                    level = keystoneInfo.level
                }
                KSR.debugPrint("GetPartyKeystoneData: Added keystone " .. i .. " - " .. keys[i].player .. ": " .. keys[i].dungeon .. " +" .. keys[i].level)
            end
        end
    end
    
    KSR.debugPrint("GetPartyKeystoneData: Returning " .. #keys .. " keystones (merged from LibKeystone and LibOpenRaid)")
    return keys
end

---Chooses a random keystone from a list of keystones.
---@param keys table table containing keystone information
---@return table|nil randomly chosen keystone data, or nil if no keystones are found
KSR.ChooseRandomKeystone = function(keys)
    if #keys > 0 then
        local randomIndex = math.random(1, #keys)
        local chosenKey = keys[randomIndex]
        return chosenKey
    else
        return nil
    end
end

---Announces the chosen keystone to party chat and lists all available keystones.
---@param keys table table containing keystone information for all party members
---@param chosenKey table the keystone data that was randomly chosen
---@---@param dryrun boolean (optional) if true, performs a dry run and prints to console instead of party chat
KSR.AnnounceKeystone = function(keys, chosenKey, dryrun)
    local playerName = chosenKey.player
    local dungeonName = chosenKey.dungeon
    local keystoneLevel = chosenKey.level

    -- Build announcement string.
    local announcementParts = {}
    -- Add name
    table.insert(announcementParts, playerName)
    if not string.match(playerName, "s$") then
        table.insert(announcementParts, "'s")
    end

    -- Add Keystone
    table.insert(announcementParts, string.format(" %s +%d ", dungeonName, keystoneLevel))

    -- Add random funny phrase
    local phrases = {
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
    table.insert(announcementParts, phrases[math.random(1, #phrases)])

    local message = table.concat(announcementParts)

    -- Print all available keys in console
    local line = "----------------------------------------------------"
    print(WrapTextInColorCode(line, KSR.colors["YELLOW"]))
    print(WrapTextInColorCode("Keystone Roulette - Available Keys:", KSR.colors["YELLOW"]))
    print(WrapTextInColorCode(line, KSR.colors["YELLOW"]))
    for i, key in ipairs(keys) do
        local keyString = string.format("%d. %s - %s +%d", i, key.player, key.dungeon, key.level)
        print(WrapTextInColorCode(keyString, KSR.colors["PRIMARY"]))
    end
    print(WrapTextInColorCode(line, KSR.colors["YELLOW"]))

    -- Print keystone announcement in party chat or console if no party.
    local prefix = "Keystone Roulette: "
    message = prefix .. message

    if KeystoneRouletteDB.debug then
        print(message)
    else
        if dryrun or not IsInGroup() then
            print(message)
        else
            SendChatMessage(message, "PARTY")
        end
    end

    -- Build and print available keys for transparency. Abbreviated keystone names.
    local keyList = "Available keys were: "
    for i, key in ipairs(keys) do
        keyList = keyList .. string.format("%s+%d", key.abbr, key.level)
        if i < #keys then
            keyList = keyList .. ", "
        end
    end

    if KeystoneRouletteDB.debug then
        print(keyList)
    else
        if dryrun then
            print(keyList)
        elseif not IsInGroup() then
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
    else
        if not keys or #keys == 0 then
            if IsInGroup() then
                SendChatMessage("Keystone Roulette: No keystones found in the party!", "PARTY")
            else
                print(WrapTextInColorCode("Keystone Roulette: No keystones found in the party!", KSR.colors["YELLOW"]))
            end
        else
            if IsInGroup() then
                SendChatMessage("Keystone Roulette: An error occurred. Please try again.", "PARTY")
            else
                print(WrapTextInColorCode("Keystone Roulette: An error occurred. Please try again.", KSR.colors["RED"]))
            end
        end
    end
end


