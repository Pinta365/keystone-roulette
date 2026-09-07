--SlashCommand.lua

local addonName, KSR = ...

SLASH_KeystoneRoulette_CMD1 = '/ksr'

---Extracts and strips a key level range token from the arguments.
---Accepts "+10" (10 and above) or "+10-15" (10 through 15). A lower bound of
---0 means unbounded, so "+0-15" reads as "15 and below".
---@param args string the lowercased argument string
---@return string the arguments with the range token removed
---@return number|nil the lowest key level requested, if any
---@return number|nil the highest key level requested, if any
local function ExtractLevelRange(args)
    local min, max = string.match(args, "%+(%d+)%-(%d+)")

    if min then
        args = string.gsub(args, "%+%d+%-%d+", "")
    else
        min = string.match(args, "%+(%d+)")
        if min then
            args = string.gsub(args, "%+%d+", "")
        end
    end

    args = string.gsub(args, "%s+", " ")
    args = strtrim(args)

    if not min then
        return args, nil, nil
    end

    min, max = tonumber(min), tonumber(max)

    if max and min > max then
        min, max = max, min
    end

    if min == 0 then
        min = nil
    end

    return args, min, max
end

---@param args string arguments following the slash command
SlashCmdList["KeystoneRoulette_CMD"] = function(args)
    local lowercaseArgs, minLevel, maxLevel = ExtractLevelRange(string.lower(args))
    local line = "----------------------------------------------------------------------"

    if lowercaseArgs == "help" or lowercaseArgs == "info" or lowercaseArgs == "?" then
        print(WrapTextInColorCode(line, KSR.colors["YELLOW"]))
        print(KSR.addon.title .. " v" .. KSR.addon.version)
        if KeystoneRouletteDB.debug then
            print(WrapTextInColorCode(" (debug mode active)", KSR.colors["RED"]))
        end
        print(WrapTextInColorCode(line, KSR.colors["YELLOW"]))

        print("Usage:")
        print("  " .. WrapTextInColorCode("/ksr", KSR.colors["YELLOW"]) .. " - Show roulette panel")
        print("  " .. WrapTextInColorCode("/ksr options", KSR.colors["YELLOW"]) .. " - Show options panel")
        print("  " .. WrapTextInColorCode("/ksr roll", KSR.colors["YELLOW"]) ..
                " or " .. WrapTextInColorCode("/ksr roulette", KSR.colors["YELLOW"]) .. " - Roulette for what key to run")
        print("  " .. WrapTextInColorCode("/ksr roll dry", KSR.colors["YELLOW"]) ..
                " or " .. WrapTextInColorCode("/ksr roulette dry", KSR.colors["YELLOW"]) .. " - Simulate a roulette for what key to run")
        print("  " .. WrapTextInColorCode("/ksr peek", KSR.colors["YELLOW"]) ..
                " or " .. WrapTextInColorCode("/ksr open", KSR.colors["YELLOW"]) .. " - Emote showing group's keystones")
        print("  " .. WrapTextInColorCode("/ksr startvote [seconds]", KSR.colors["YELLOW"]) .. " - Start a party vote for which key to run (default 20s)")
        print("  " .. WrapTextInColorCode("/ksr help", KSR.colors["YELLOW"]) .. " - Show this help info")
        print("  " .. WrapTextInColorCode("/ksr debug", KSR.colors["YELLOW"]) .. " - Toggles debug mode")
        print("  " .. WrapTextInColorCode("/ksr reset", KSR.colors["YELLOW"]) .. " - Reset to default settings and reload UI")
        print(WrapTextInColorCode(line, KSR.colors["YELLOW"]))
        print("Key level range (optional, works on roll and vote):")
        print("  " .. WrapTextInColorCode("/ksr roll +10", KSR.colors["YELLOW"]) .. " - Only keys +10 and above")
        print("  " .. WrapTextInColorCode("/ksr roll +10-15", KSR.colors["YELLOW"]) .. " - Only keys +10 through +15")
        print("  " .. WrapTextInColorCode("/ksr roll +0-15", KSR.colors["YELLOW"]) .. " - Only keys +15 and below")
        print("  " .. WrapTextInColorCode("/ksr vote 30 +10-15", KSR.colors["YELLOW"]) .. " - 30s vote, keys +10 through +15")
        print(WrapTextInColorCode(line, KSR.colors["YELLOW"]))
    elseif lowercaseArgs == "reset" then
        KSR.WagoAnalytics:IncrementCounter("CmdReset")
        KeystoneRouletteDB = CopyTable(KSR.addonDefaults)
        ReloadUI()
    elseif lowercaseArgs == "debug" then
        KSR.WagoAnalytics:IncrementCounter("CmdDebug")
        KeystoneRouletteDB.debug = not KeystoneRouletteDB.debug
        if KeystoneRouletteDB.debug then
            print(WrapTextInColorCode(KSR.addon.title .. " debug mode enabled.", KSR.colors["PRIMARY"]))
        else
            print(WrapTextInColorCode(KSR.addon.title .. " debug mode disabled.", KSR.colors["PRIMARY"]))
        end
    elseif lowercaseArgs == "roll"  or lowercaseArgs == "roulette" then
        KSR.WagoAnalytics:IncrementCounter("CmdRoulette")
        KSR.RouletteKeystone(false, minLevel, maxLevel)
    elseif lowercaseArgs == "roll dry"  or lowercaseArgs == "roulette dry" then
        KSR.WagoAnalytics:IncrementCounter("CmdRouletteDry")
        KSR.RouletteKeystone(true, minLevel, maxLevel)
    elseif lowercaseArgs == "peek" or lowercaseArgs == "open" then
        KSR.WagoAnalytics:IncrementCounter("CmdPeek")
        KSR.PeekKeystones()
    elseif lowercaseArgs == "startvote" or lowercaseArgs == "vote" or
           string.match(lowercaseArgs, "^startvote %d+$") or string.match(lowercaseArgs, "^vote %d+$") then
        KSR.WagoAnalytics:IncrementCounter("CmdStartVote")
        local customDuration = tonumber(string.match(lowercaseArgs, "%d+"))
        KSR.StartVote(customDuration, nil, minLevel, maxLevel)
    elseif string.sub(lowercaseArgs, 1, 3) == "opt" then
        Settings.OpenToCategory(KSR.settingsCategory.ID)
    else
        KSR.ShowKeystoneGUI()
    end
end
