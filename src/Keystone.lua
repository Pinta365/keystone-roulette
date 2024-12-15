--Keystone.lua

local _, KSR = ...

---Retrieves keystone data for all party members.
---@return table table containing keystone information for each party member with a keystone.
KSR.GetKeystoneData = function()
    local keys = {}
    local openRaidLib = LibStub:GetLibrary("LibOpenRaid-1.0")
    if openRaidLib then
        local keystoneData = openRaidLib.GetAllKeystonesInfo()
        if keystoneData then
            table.sort(keystoneData, function (t1, t2) return t1.level > t2.level end)

            local i = 0
            for unitName, keystoneInfo in pairs(keystoneData) do
                local name = C_ChallengeMode.GetMapUIInfo(keystoneInfo.challengeMapID) or ""

                if  (UnitInParty(unitName) or unitName == UnitName("player")) and keystoneInfo.level > 0 then
                    i = i + 1
                    keys[i] = {
                        player = ({strsplit("-", unitName)})[1],
                        dungeon = name,
                        level = keystoneInfo.level
                    }
                end
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
KSR.AnnounceKeystone = function(keys, chosenKey)
    if chosenKey then
        local playerName = chosenKey.player
        local dungeonName = chosenKey.dungeon
        local keystoneLevel = chosenKey.level

        local announcementParts = {}
        table.insert(announcementParts, playerName)
        if not string.match(playerName, "s$") then
            table.insert(announcementParts, "'s")
        end
        table.insert(announcementParts, string.format(" %s +%d ", dungeonName, keystoneLevel))

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
        }
        table.insert(announcementParts, phrases[math.random(1, #phrases)])

        local message = table.concat(announcementParts)

        -- Add a prefix to indicate it's a roulette result
        local prefix = "Keystone Roulette: "
        message = prefix .. message 

        if KeystoneRouletteDB.debug then
            print(message)
        else
            SendChatMessage(message, "PARTY")
        end

        -- List all available keys
        local keyList = "Available keys were: "
        for i, key in ipairs(keys) do
            keyList = keyList .. string.format("%s (%s +%d)", key.player, key.dungeon, key.level)
            if i < #keys then
                keyList = keyList .. ", "
            end
        end

        if KeystoneRouletteDB.debug then
            print(keyList)
        else
            SendChatMessage(keyList, "PARTY")
        end

    else
        SendChatMessage("Keystone Roulette: No keystones found in the party!", "PARTY")
    end
end

---Performs the keystone roulette, choosing a random keystone and announcing it to the party.
KSR.RouletteKeystone = function()
    local keys = KSR.GetKeystoneData()
    local chosenKey = KSR.ChooseRandomKeystone(keys)

    if chosenKey and keys then
        KSR.AnnounceKeystone(keys, chosenKey)
    else
        if not keys or #keys == 0 then
            SendChatMessage("Keystone Roulette: No keystones found in the party!", "PARTY")
        else
            SendChatMessage("Keystone Roulette: An error occurred. Please try again.", "PARTY")
        end
    end
end

