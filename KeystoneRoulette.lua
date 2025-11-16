--KeystoneRoulette.lua

local addonName, KSR = ...

---@class f:Frame
local f = CreateFrame("Frame")

function f:ADDON_LOADED(addon)
    if addon == "KeystoneRoulette" then
        KeystoneRouletteDB = KeystoneRouletteDB or CopyTable(KSR.addonDefaults)
        KSR.debugPrint(addonName .. " v" .. KSR.addon.version .. " is loaded.")
        KSR.InitOptions()
        -- Initialize LibKeystone if available
        if KSR.InitializeLibKeystone then
            KSR.InitializeLibKeystone()
        end
        -- Request keystones immediately if already in a party when addon loads
        if KSR.IsLibKeystoneAvailable() and IsInGroup() and not IsInRaid() then
            C_Timer.After(1, function()
                if IsInGroup() and not IsInRaid() then
                    KSR.libKeystone.Request("PARTY")
                    KSR.debugPrint("Addon load: Requested keystones from LibKeystone (PARTY)")
                end
            end)
        end
    end
end

function f:PLAYER_ENTERING_WORLD()
    -- Request keystones when entering world if already in a party
    if KSR.IsLibKeystoneAvailable() and IsInGroup() and not IsInRaid() then
        C_Timer.After(1, function()
            if IsInGroup() and not IsInRaid() then
                KSR.libKeystone.Request("PARTY")
                KSR.debugPrint("PLAYER_ENTERING_WORLD: Requested keystones from LibKeystone (PARTY)")
            end
        end)
    end
end

function f:GROUP_LEFT()
    -- Clear LibKeystone data when leaving group, then re-initialize player's own keystone
    if KSR.ClearLibKeystoneData then
        KSR.ClearLibKeystoneData()
        -- Re-initialize player's own keystone after clearing
        if KSR.InitializeLibKeystone then
            KSR.InitializeLibKeystone()
        end
    end
end

function f:GROUP_ROSTER_UPDATE()
    -- When group changes, request keystones from LibKeystone if in a party
    if KSR.IsLibKeystoneAvailable() and IsInGroup() and not IsInRaid() then
        -- Small delay to ensure group is fully updated
        C_Timer.After(1, function()
            if IsInGroup() and not IsInRaid() then
                KSR.libKeystone.Request("PARTY")
                KSR.debugPrint("GROUP_ROSTER_UPDATE: Requested keystones from LibKeystone (PARTY)")
            end
        end)
    end
end

function f:CHALLENGE_MODE_COMPLETED()
    -- Update player's own keystone when it changes
    if KSR.InitializeLibKeystone then
        KSR.InitializeLibKeystone()
    end
    -- Request keystones from party if in a group
    if KSR.IsLibKeystoneAvailable() and IsInGroup() and not IsInRaid() then
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
