--Utilities.lua

local _, KSR = ...

---Helper function to print debug messages
---@param message string
KSR.debugPrint = function(message)
    if KeystoneRouletteDB.debug then
        print((KSR.addon.title or "") .. WrapTextInColorCode(" debug: ", KSR.colors["PRIMARY"]) .. tostring(message))
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
