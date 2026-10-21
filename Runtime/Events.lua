local Events = {}
local EVENTS = {
    "PLAYER_ENTERING_WORLD", "PLAYER_TARGET_CHANGED", "UPDATE_MOUSEOVER_UNIT", "PLAYER_FOCUS_CHANGED",
    "NAME_PLATE_UNIT_ADDED", "NAME_PLATE_UNIT_REMOVED", "UNIT_AURA", "UNIT_PET",
    "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED", "UNIT_SPELLCAST_FAILED", "UNIT_SPELLCAST_INTERRUPTED",
    "SPELL_TEXT_UPDATE", "SPELL_DATA_LOAD_RESULT", "PLAYER_LOGOUT", "UNIT_HEALTH", "UNIT_MAXHEALTH", "GROUP_ROSTER_UPDATE",
}

function Events.create(tracking, api, options)
    local config, host, registered = options or {}, nil, {}
    local driver = {}
    local function readable(value) return not api.isRestricted(value) end
    function driver.dispatch(event, ...)
        if not readable(event) or type(event) ~= "string" then return false end
        if event == "PLAYER_ENTERING_WORLD" then
            tracking.resetWorld(); tracking.bind("target"); return tracking.scan("target")
        elseif event == "PLAYER_TARGET_CHANGED" then return tracking.targetChanged()
        elseif event == "UPDATE_MOUSEOVER_UNIT" then return tracking.scan("mouseover")
        elseif event == "PLAYER_FOCUS_CHANGED" then return tracking.scan("focus")
        elseif event == "NAME_PLATE_UNIT_ADDED" then return tracking.addUnit((...))
        elseif event == "NAME_PLATE_UNIT_REMOVED" then return tracking.unbind((...))
        elseif event == "UNIT_AURA" then return tracking.scan(...)
        elseif event == "GROUP_ROSTER_UPDATE" then tracking.learningContextChanged(); return true
        elseif event == "UNIT_SPELLCAST_SENT" then return tracking.sent(...)
        elseif event == "UNIT_SPELLCAST_SUCCEEDED" then return tracking.succeeded(...)
        elseif event == "UNIT_SPELLCAST_FAILED" or event == "UNIT_SPELLCAST_INTERRUPTED" then return tracking.cancel(...)
        elseif event == "UNIT_PET" then
            local unit = ...
            if readable(unit) and unit == "player" then tracking.resetPet(); return true end
        elseif event == "SPELL_TEXT_UPDATE" then return tracking.textUpdated((...))
        elseif event == "SPELL_DATA_LOAD_RESULT" then
            local id, loaded = ...
            if readable(loaded) and loaded == true then return tracking.textUpdated(id) end
        elseif event == "COMBAT_LOG_EVENT_UNFILTERED" and api.flavor == "classic" then return tracking.periodic()
        elseif event == "UNIT_COMBAT" and api.flavor == "forever" then return tracking.confirmCombat(...)
        elseif event == "PLAYER_LOGOUT" then return tracking.save(config.characterData)
        end
        return false
    end
    function driver.start()
        if host then return true end
        if api.flavor ~= "forever" and api.flavor ~= "classic" then return false, "unsupported_client" end
        local frame = api.frame()
        if api.isRestricted(frame) or (type(frame) ~= "table" and type(frame) ~= "userdata") then return false, "missing_event_frame" end
        local ok = pcall(function()
            frame:SetScript("OnEvent", function(_, event, ...)
                local success, reason = pcall(driver.dispatch, event, ...)
                if not success and config.onError then config.onError(reason) end
                if success and config.onEvent then
                    local ok, failure = pcall(config.onEvent, event, ...)
                    if not ok and config.onError then config.onError(failure) end
                end
            end)
        end)
        if not ok then return false, "event_frame_unavailable" end
        host = frame
        local function register(event)
            local success, result = pcall(frame.RegisterEvent, frame, event)
            registered[event] = success and readable(result) and result ~= false
        end
        for _, event in ipairs(EVENTS) do register(event) end
        if api.flavor == "classic" then
            register("COMBAT_LOG_EVENT_UNFILTERED")
        elseif api.flavor == "forever" then
            register("UNIT_COMBAT")
        end
        tracking.restore(config.characterData)
        return true
    end
    function driver.stop()
        if host then pcall(host.UnregisterAllEvents, host); pcall(host.SetScript, host, "OnEvent", nil) end
        host, registered = nil, {}
    end
    function driver.status()
        local supported = api.flavor == "classic" and registered.COMBAT_LOG_EVENT_UNFILTERED == true
            or api.flavor == "forever" and registered.UNIT_COMBAT == true
        local solo = api.flavor == "forever" and type(api.learningContext) == "function" and api.learningContext() == "solo"
        local result = { active = host ~= nil, events = {}, learningSupported = supported,
            learningAvailable = supported and (api.flavor == "classic" or solo) }
        for event, allowed in pairs(registered) do result.events[event] = allowed end
        return result
    end
    return driver
end

local _, namespace = ...
if type(namespace) == "table" then namespace.Events = Events end
return Events
