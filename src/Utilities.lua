--Utilities.lua

local _, KSR = ...

---Helper function to print debug messages, handling strings and tables.
---@param message any The message or data to print
KSR.debugPrint = function(message)
    if KeystoneRouletteDB.debug then
        local prefix = (KSR.addon.title or "") .. WrapTextInColorCode(" debug: ", KSR.colors["PRIMARY"])

        if type(message) == "table" then
            -- If it's a table, iterate and print key-value pairs
            print(prefix .. " (table):")
            for k, v in pairs(message) do
                print(prefix .. string.format("  %s = %s", tostring(k), tostring(v)))
            end
        else
            -- Otherwise, print the message as a string
            print(prefix .. tostring(message))
        end
    end
end

---Helper function to set or hook script to a frame.
---@param frame frame frame to attach script to
---@param event string event name
---@param func function function to attach
KSR.setOrHookHandler = function(frame, event, func)
    if frame:GetScript(event) then
        frame:HookScript(event, func)
    else
        frame:SetScript(event, func)
    end
end
