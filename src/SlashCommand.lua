--SlashCommand.lua

local addonName, KSR = ...

SLASH_KeystoneRoulette_CMD1 = '/ksr'

---@param args string arguments following the slash command
SlashCmdList["KeystoneRoulette_CMD"] = function(args)
    local lowercaseArgs = string.lower(args)
    local line = "----------------------------------------------------------------------"

    if lowercaseArgs == "help" or lowercaseArgs == "info" or lowercaseArgs == "?" then
        print(WrapTextInColorCode(line, KSR.colors["YELLOW"]))
        print(KSR.addon.title .. " v" .. KSR.addon.version)
        if KeystoneRouletteDB.debug then
            print(WrapTextInColorCode(" (debug mode active)", KSR.colors["RED"]))
        end
        print(WrapTextInColorCode(line, KSR.colors["YELLOW"]))

        print("Usage:")
        print("  " .. WrapTextInColorCode("/ksr", KSR.colors["YELLOW"]) .. " - Show options panel")
        print("  " .. WrapTextInColorCode("/ksr roll", KSR.colors["YELLOW"]) ..
                " or " .. WrapTextInColorCode("/ksr roulette", KSR.colors["YELLOW"]) .. " - Roulette for what key to run")
        print("  " .. WrapTextInColorCode("/ksr roll dry", KSR.colors["YELLOW"]) ..
                " or " .. WrapTextInColorCode("/ksr roulette dry", KSR.colors["YELLOW"]) .. " - Simulate a roulette for what key to run")
        print("  " .. WrapTextInColorCode("/ksr help", KSR.colors["YELLOW"]) .. " - Show this help info")
        print("  " .. WrapTextInColorCode("/ksr debug", KSR.colors["YELLOW"]) .. " - Toggles debug mode")
        print("  " .. WrapTextInColorCode("/ksr reset", KSR.colors["YELLOW"]) .. " - Reset to default settings and reload UI")
        print(WrapTextInColorCode(line, KSR.colors["YELLOW"]))
    elseif lowercaseArgs == "reset" then
        -- Collect analytics.
        KSR.WagoAnalytics:IncrementCounter("CmdReset")
        --Reset to default settings.
        KeystoneRouletteDB = CopyTable(KSR.addonDefaults)
        ReloadUI()
    elseif lowercaseArgs == "debug" then
        -- Collect analytics.
        KSR.WagoAnalytics:IncrementCounter("CmdDebug")
        -- toggle KeystoneRouletteDB.debug
        KeystoneRouletteDB.debug = not KeystoneRouletteDB.debug
        if KeystoneRouletteDB.debug then
            print(WrapTextInColorCode(KSR.addon.title .. " debug mode enabled.", KSR.colors["PRIMARY"]))
        else
            print(WrapTextInColorCode(KSR.addon.title .. " debug mode disabled.", KSR.colors["PRIMARY"]))
        end
    elseif lowercaseArgs == "roll"  or lowercaseArgs == "roulette" then
        -- Collect analytics.
        KSR.WagoAnalytics:IncrementCounter("CmdRoulette")
        KSR.RouletteKeystone()
    elseif lowercaseArgs == "roll dry"  or lowercaseArgs == "roulette dry" then
        -- Collect analytics.
        KSR.WagoAnalytics:IncrementCounter("CmdRouletteDry")
        KSR.RouletteKeystone(true)
    else
        Settings.OpenToCategory(KSR.settingsCategory.ID)
    end
end
