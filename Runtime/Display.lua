local Display = {}
local INTERVAL, MAX_VIEWS = 0.1, 64

function Display.create(env, api, tracking, bindings, overlayFactory, addonName, diagnostic)
    local display, views, pool, units, states = {}, {}, {}, {}, {}
    local settings = { plateEnabled = true, plates = { fillStyle = "flat", opacity = 0.8 }, target = { fillStyle = "flat", opacity = 0.8 } }
    local targetEnabled, running, elapsed = false, false, 0
    local host = env.CreateFrame("Frame")
    local function token(unit)
        return not api.isRestricted(unit) and type(unit) == "string"
            and (unit == "target" or unit:match("^nameplate%d+$"))
    end
    local function health(unit)
        if type(env.UnitHealth) ~= "function" or type(env.UnitHealthMax) ~= "function" then return nil end
        local ok, current = pcall(env.UnitHealth, unit, false)
        local good, maximum = pcall(env.UnitHealthMax, unit)
        if not ok or not good then return nil end
        local currentHidden, maxHidden = api.isRestricted(current), api.isRestricted(maximum)
        local function valid(value)
            return type(value) == "number" and value == value and value >= 0 and value <= 1000000000000
        end
        return { current = current, maximum = maximum, healthReadable = not currentHidden and valid(current),
            maxReadable = not maxHidden and valid(maximum), maxRestricted = maxHidden }
    end
    local function refresh(unit)
        if unit == "target" and not targetEnabled or unit ~= "target" and settings.plateEnabled == false then
            if views[unit] then views[unit].hide("surface_disabled") end
            states[unit] = { visible = false, reason = "surface_disabled" }
            return
        end
        if type(env.UnitIsDeadOrGhost) == "function" then
            local ok, dead = pcall(env.UnitIsDeadOrGhost, unit)
            if ok and not api.isRestricted(dead) and dead == true then
                if views[unit] then views[unit].hide("dead_target") end
                states[unit] = { visible = false, reason = "dead_target" }
                return
            end
        end
        local forecast, trackingReason = tracking.snapshot(unit)
        local binding, bindingReason
        if unit == "target" then binding = bindings.target()
        else binding, bindingReason = bindings.nameplate(unit) end
        if not binding or not forecast or forecast.effectCount == 0 then
            if views[unit] then views[unit].hide("no_binding_or_forecast") end
            states[unit] = { visible = false, reason = not binding and (bindingReason or "missing_binding")
                or forecast and forecast.reason or trackingReason or "no_forecast" }
            return
        end
        if not views[unit] then
            views[unit] = table.remove(pool) or overlayFactory.create(env, api.isRestricted, addonName)
        end
        views[unit].configure(unit == "target" and settings.target or settings.plates)
        local ok, reason = views[unit].update(binding, forecast, health(unit), unit)
        states[unit] = views[unit].status()
        if ok == false then diagnostic.capture("display", reason) end
    end
    local function render(unit)
        local ok = diagnostic.run("render:" .. unit, function() refresh(unit) end)
        if not ok then
            if views[unit] then views[unit].hide("render_error") end
            states[unit] = { visible = false, reason = "render_error" }
        end
    end
    function display.refresh()
        if not running then return end
        for unit in pairs(units) do render(unit) end
    end
    function display.event(event, unit)
        if event == "PLAYER_ENTERING_WORLD" then
            for known in pairs(units) do if known ~= "target" then display.event("NAME_PLATE_UNIT_REMOVED", known) end end
        elseif event == "NAME_PLATE_UNIT_ADDED" and token(unit) then
            local count = 0
            for _ in pairs(units) do count = count + 1 end
            if count < MAX_VIEWS then units[unit] = true end
        elseif event == "NAME_PLATE_UNIT_REMOVED" and token(unit) then
            units[unit], states[unit] = nil, nil
            if views[unit] then views[unit].hide("removed"); pool[#pool + 1] = views[unit]; views[unit] = nil end
        end
        if not running then return end
        if token(unit) and units[unit] then
            render(unit)
        elseif event == "PLAYER_TARGET_CHANGED" then
            if targetEnabled then render("target") end
        elseif event == "PLAYER_ENTERING_WORLD" or event == "SPELL_DATA_LOAD_RESULT" or event == "SPELL_TEXT_UPDATE"
            or event == "UNIT_SPELLCAST_SUCCEEDED" and not api.isRestricted(unit) and (unit == "player" or unit == "pet") then
            display.refresh()
        end
    end
    function display.start()
        running = true
        if targetEnabled then units.target = true end
        host:SetScript("OnUpdate", function(_, delta)
            if api.isRestricted(delta) or type(delta) ~= "number" then return end
            elapsed = elapsed + delta
            if elapsed >= INTERVAL then elapsed = 0; display.refresh() end
        end)
        display.refresh()
    end
    function display.stop()
        running, elapsed = false, 0
        host:SetScript("OnUpdate", nil)
        for unit, view in pairs(views) do view.hide("paused"); states[unit] = view.status() end
    end
    function display.target(enabled)
        targetEnabled = enabled == true
        if targetEnabled then units.target = true
        else
            units.target = nil
            if views.target then views.target.hide("target_disabled"); states.target = views.target.status() end
        end
        display.refresh()
    end
    function display.style(style)
        if style ~= "flat" and style ~= "stripes" and style ~= "gradient" then return false end
        settings.plates.fillStyle, settings.target.fillStyle = style, style
        display.refresh(); return true
    end
    function display.configure(configuration)
        settings = configuration
        display.target(settings.targetEnabled)
        for unit, view in pairs(views) do
            view.configure(unit == "target" and settings.target or settings.plates)
            if unit ~= "target" and settings.plateEnabled == false then view.hide("surface_disabled") end
        end
        display.refresh()
    end
    function display.status()
        local result = { running = running, targetEnabled = targetEnabled, plateEnabled = settings.plateEnabled,
            style = settings.plates.fillStyle, views = {}, pooled = #pool }
        for unit, state in pairs(states) do result.views[unit] = state end
        return result
    end
    return display
end

local _, namespace = ...
if type(namespace) == "table" then namespace.Display = Display end
return Display
