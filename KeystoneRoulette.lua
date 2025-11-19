--KeystoneRoulette.lua

local addonName, KSR = ...

---@class f:Frame
local f = CreateFrame("Frame")

function f:ADDON_LOADED(addon)
    if addon == "KeystoneRoulette" then
        KeystoneRouletteDB = KeystoneRouletteDB or CopyTable(KSR.addonDefaults)
        KSR.debugPrint(addonName .. " v" .. KSR.addon.version .. " is loaded.")
        KSR.InitOptions()
        if KSR.InitializeLibKeystone then
            KSR.InitializeLibKeystone()
        end
        if KSR.IsLibKeystoneAvailable() and KSR.IsInParty() then
            C_Timer.After(KSR.constants.REQUEST_DELAY, function()
                if KSR.IsInParty() then
                    KSR.libKeystone.Request("PARTY")
                    KSR.debugPrint("Addon load: Requested keystones from LibKeystone (PARTY)")
                end
            end)
        end
    end
end

function f:PLAYER_ENTERING_WORLD()
    KSR.ClearPlayerInfo()
    KSR.GetPlayerInfo()
    
    if KSR.IsLibKeystoneAvailable() and KSR.IsInParty() then
        C_Timer.After(KSR.constants.REQUEST_DELAY, function()
            if KSR.IsInParty() then
                KSR.libKeystone.Request("PARTY")
                KSR.debugPrint("PLAYER_ENTERING_WORLD: Requested keystones from LibKeystone (PARTY)")
            end
        end)
    end
end

function f:GROUP_LEFT()
    if KSR.ClearLibKeystoneData then
        KSR.ClearLibKeystoneData()
        if KSR.InitializeLibKeystone then
            KSR.InitializeLibKeystone()
        end
    end
end

function f:GROUP_ROSTER_UPDATE()
    if KSR.IsLibKeystoneAvailable() and KSR.IsInParty() then
        C_Timer.After(KSR.constants.REQUEST_DELAY, function()
            if KSR.IsInParty() then
                KSR.libKeystone.Request("PARTY")
                KSR.debugPrint("GROUP_ROSTER_UPDATE: Requested keystones from LibKeystone (PARTY)")
            end
        end)
    end
end

function f:CHALLENGE_MODE_COMPLETED()
    if KSR.InitializeLibKeystone then
        KSR.InitializeLibKeystone()
    end
    if KSR.IsLibKeystoneAvailable() and KSR.IsInParty() then
        KSR.libKeystone.Request("PARTY")
        KSR.debugPrint("CHALLENGE_MODE_COMPLETED: Requested keystones from LibKeystone (PARTY)")
    end
end

f:SetScript("OnEvent", function(self, event, ...)
    self[event](self, ...)
end)

f:RegisterEvent("ADDON_LOADED")
f:RegisterEvent("PLAYER_ENTERING_WORLD")
f:RegisterEvent("GROUP_LEFT")
f:RegisterEvent("GROUP_ROSTER_UPDATE")
f:RegisterEvent("CHALLENGE_MODE_COMPLETED")
