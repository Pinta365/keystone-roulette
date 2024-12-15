--SlashCommand.lua

local addonName, KSR = ...

SLASH_KeystoneRoulette_CMD1 = '/ksr'

---@param args string arguments following the slash command
SlashCmdList["KeystoneRoulette_CMD"] = function(args)
    local lowercaseArgs = string.lower(args)

    if lowercaseArgs == "help" or lowercaseArgs == "info" or lowercaseArgs == "?" then
        print(WrapTextInColorCode("-------------------------------------------------", KSR.colors["YELLOW"]))
        print(KSR.addon.title .. " v" .. KSR.addon.version)
        print(WrapTextInColorCode("-------------------------------------------------", KSR.colors["YELLOW"]))

        print("Usage:")
        print("  " .. WrapTextInColorCode("/ksr", KSR.colors["YELLOW"]) .. " - Show options panel")
        print("  " .. WrapTextInColorCode("/ksr roll", KSR.colors["YELLOW"]) .. " - Rolls for what key to run")
        print("  " .. WrapTextInColorCode("/ksr roulette", KSR.colors["YELLOW"]) .. " - Rolls for what key to run")
        print("  " .. WrapTextInColorCode("/ksr help", KSR.colors["YELLOW"]) .. " - Show this help info")
        print("  " .. WrapTextInColorCode("/ksr reset", KSR.colors["YELLOW"]) .. " - Reset to default settings and reload UI")
        print(WrapTextInColorCode("-------------------------------------------------", KSR.colors["YELLOW"]))
    elseif lowercaseArgs == "reset" then
        --Reset to default settings.
        KeystoneRouletteDB = CopyTable(KSR.addonDefaults)
        ReloadUI()
    elseif lowercaseArgs == "debug" then
        -- toggle KeystoneRouletteDB.debug
        KeystoneRouletteDB.debug = not KeystoneRouletteDB.debug
        if KeystoneRouletteDB.debug then
            print(WrapTextInColorCode(KSR.addon.title .. " debug mode enabled.", KSR.colors["PRIMARY"]))
        else
            print(WrapTextInColorCode(KSR.addon.title .. " debug mode disabled.", KSR.colors["PRIMARY"]))
        end
    elseif lowercaseArgs == "roll"  or lowercaseArgs == "roulette" then
        KSR.RouletteKeystone()
    else
        Settings.OpenToCategory(KSR.settingsCategory.ID)
    end
end
