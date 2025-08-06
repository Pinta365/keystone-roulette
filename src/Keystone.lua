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
    }
    return abbreviations[challengeMapID]
end

---Retrieves keystone data for all party members.
---@return table table containing keystone information for each party member with a keystone.
KSR.GetPartyKeystoneData = function()
    local keys = {}
    local keystoneData = {}

    if (IsInGroup() and not IsInRaid()) or GetNumSubgroupMembers() == 0 then
        keystoneData = KSR.openRaidLib.GetAllKeystonesInfo()
    end

    if keystoneData then
        table.sort(keystoneData, function (t1, t2) return t1.level > t2.level end)
        local i = 0
        for unitName, keystoneInfo in pairs(keystoneData) do
            local name = C_ChallengeMode.GetMapUIInfo(keystoneInfo.challengeMapID)
            local abbrName = AbbreviateDungeonName(keystoneInfo.challengeMapID)

            if (UnitInParty(unitName) or unitName == UnitName("player")) and keystoneInfo.level > 0 then
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
            end
        end
    end
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
        "has been selected, but Old Brann got your back!",
        "fast in, fast out!",
        "beckons! Answer the call!",
        "because 'fun' is subjective, right?",
        "is the next chapter in your epic saga!"
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


