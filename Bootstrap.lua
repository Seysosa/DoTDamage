local addonName, namespace = ...
local env = _G
local L = namespace.UILocale and namespace.UILocale.create(env) or function(text, ...)
    if select("#", ...) > 0 then return string.format(text, ...) end
    return text
end
local loader = env.CreateFrame("Frame")
loader:RegisterEvent("ADDON_LOADED")
local controller, diagnostic, ui, store, tracker, display, driver

local function say(message)
    local text = "|cff65d6a8DoTDamage:|r " .. message
    if env.DEFAULT_CHAT_FRAME then env.DEFAULT_CHAT_FRAME:AddMessage(text) elseif env.print then env.print(text) end
end

local function initialize()
    if type(namespace.Diagnostics) ~= "table" then say(L("Diagnostics module missing. Please install the complete addon.")); return end
    diagnostic = namespace.Diagnostics.create(env, addonName)
    env.DoTDamageReport = diagnostic.bind(env.DoTDamageReport)
    diagnostic.observeErrors()
    for _, name in ipairs({ "Forecast", "SpellFacts", "SpellCatalog", "SpellDescription", "WowApi", "TickLearning", "CastOutcomes", "TickEvidence", "Tracking", "Events", "Frames", "Overlay", "Display", "SettingsStore", "UITheme", "UILocale", "UITooltips", "FramePicker", "UIControls", "SettingsWindow" }) do
        if type(namespace[name]) ~= "table" then
            diagnostic.capture("startup", "Missing module: " .. name)
            say(L("Missing module: %s. Please install the complete addon.", name)); return
        end
    end
    local api = namespace.WowApi.create(env)
    store = namespace.SettingsStore.create(env, api.isRestricted)
    local character = store.character()
    local engine = namespace.Forecast.create({ isRestricted = api.isRestricted })
    local catalog = namespace.SpellCatalog.create(namespace.SpellFacts, api.isRestricted)
    local parser = namespace.SpellDescription.create(catalog, api.isRestricted)
    tracker = namespace.Tracking.create(engine, parser, api)
    local bindings = namespace.Frames.create(env, api.isRestricted)
    local picker = namespace.FramePicker.create(env, api.isRestricted, bindings)
    display = namespace.Display.create(env, api, tracker, bindings, namespace.Overlay, addonName, diagnostic)
    controller = {}
    driver = namespace.Events.create(tracker, api, {
        characterData = character,
        onError = function(reason) diagnostic.capture("event", reason) end,
        onEvent = function(event, unit)
            display.event(event, unit)
            if event == "PLAYER_ENTERING_WORLD" then controller.seed() end
        end,
    })
    function controller.run(label, callback, ...)
        local args, count = { ... }, select("#", ...)
        return diagnostic.run(label, function() return callback(unpack(args, 1, count)) end)
    end
    function controller.error(label, reason) diagnostic.capture(label, reason) end
    function controller.seed()
        for _, unit in ipairs(bindings.units()) do tracker.scan(unit); display.event("NAME_PLATE_UNIT_ADDED", unit) end
        tracker.scan("target")
    end
    local function configureTracking(options)
        tracker.configure({ confirmedOnly = true, castEstimates = api.flavor == "forever" and driver.status().learningSupported,
            waitFirstTick = options.waitFirstTick })
    end
    local function apply(options)
        bindings.configure(options)
        configureTracking(options)
        display.configure(options)
        if options.enabled then
            if display.status().running then return end
            local ok, reason = driver.start()
            if not ok then diagnostic.capture("startup", reason); say(L("Tracking cannot start: %s", reason)); return end
            configureTracking(options)
            display.start(); controller.seed()
        elseif display.status().running then
            tracker.save(character); driver.stop(); display.stop(); tracker.resetWorld()
        end
    end
    function controller.status()
        local tracking = tracker.status()
        local events = driver.status()
        local learningContext = not events.active and "disabled" or not events.learningSupported and "unavailable" or tracking.learning.context
        local aura = tracker.auraStatus("target")
        local targetAuraAccess = "unknown"
        if not api.enemy("target") then targetAuraAccess = "no_target"
        elseif aura then
            if aura.reason == "aura_api_error" or aura.reason == "restricted_aura_result" or aura.reason == "auras_private" then
                targetAuraAccess = "blocked"
            else
                local usable = aura.complete and (aura.unreadableClock or 0) == 0
                    and (aura.unreadableIdentity or 0) == 0 and (aura.unreadableSource or 0) == 0
                targetAuraAccess = usable and "readable" or "incomplete"
            end
        end
        return { client = api.flavor, running = display.status().running,
            casts = tracking.casts, auras = tracking.auras, rejected = tracking.rejected, learned = tracking.learned,
            confirmedOnly = tracking.confirmedOnly, pendingApplications = tracking.pendingApplications,
            inferredEffects = tracking.inferredEffects,
            castEstimatedEffects = tracking.castEstimatedEffects,
            targetAuraAccess = targetAuraAccess,
            learningAllowed = tracking.learningAllowed and events.learningAvailable, learningContext = learningContext, learningSource = tracking.learningSource,
            lastReason = tracking.lastReason, errors = #diagnostic.store().errors }
    end
    function controller.report() tracker.save(character); diagnostic.report() end
    function controller.resetLearning() tracker.resetLearning(); tracker.save(character) end
    function controller.frameStatus() return bindings.status() end
    function controller.pickFrame(key, callback)
        local ok, reason = picker.start(key, callback); if not ok then say(reason) end
        return ok, reason
    end
    function controller.stopPick() picker.stop() end
    local function families()
        local class
        if type(env.UnitClass) == "function" then
            local ok, _, token = pcall(env.UnitClass, "player")
            if ok and not api.isRestricted(token) then class = token end
        end
        local result = catalog.list(class, api.flavor)
        for index = #result, 1, -1 do
            local data = namespace.SpellFacts.families[result[index].familyKey]
            if data and data.damageModel == "observed" then table.remove(result, index) end
        end
        for _, entry in ipairs(result) do
            local data = namespace.SpellFacts.families[entry.familyKey]
            entry.name = data and data.names and data.names[1] or entry.familyKey
            if env.C_Spell and type(env.C_Spell.GetSpellInfo) == "function" then
                local ok, info = pcall(env.C_Spell.GetSpellInfo, entry.spellId)
                if ok and not api.isRestricted(info) and type(info) == "table" then
                    local name = info.name
                    if not api.isRestricted(name) and type(name) == "string" then entry.name = name end
                end
            end
        end
        table.sort(result, function(a, b) return a.name < b.name end)
        return result
    end
    diagnostic.setSnapshot(function()
        local version, build, date, interface
        if type(env.GetBuildInfo) == "function" then version, build, date, interface = env.GetBuildInfo() end
        local prediction = tracker.snapshot("target")
        if prediction then
            while #prediction.effects > 8 do table.remove(prediction.effects) end
            prediction.effectsTruncated = prediction.effectCount > #prediction.effects
        end
        return { version = version, build = build, buildDate = date, interface = interface, client = api.flavor,
            prediction = prediction, auraScan = tracker.auraStatus("target"), tracking = tracker.status(),
            events = driver.status(), display = display.status(), settings = store.snapshot() }
    end)
    ui = namespace.SettingsWindow.create(env, store, controller, {
        controls = namespace.UIControls, overlay = namespace.Overlay, restricted = api.isRestricted,
        addonName = addonName, families = families, theme = namespace.UITheme,
    })
    store.subscribe(apply)
    ui.register()
    apply(store.snapshot())
    store.refreshContext(true)
    function controller.open() ui.open() end
    function controller.command(message)
        local command = type(message) == "string" and message:match("^%s*(%S+)") or nil
        command = command and command:lower() or "options"
        if command == "options" or command == "config" or command == "demo" or command == "survives" or command == "lethal" then ui.open()
        elseif command == "target" then store.setRoot("targetEnabled", not store.snapshot().targetEnabled)
        elseif command == "flat" or command == "stripes" or command == "gradient" then
            store.setSurface("plates", "fillStyle", command); store.setSurface("target", "fillStyle", command)
        elseif command == "report" then controller.report(); say(L("Report collected. /reload saves SavedVariables/DoTDamage.lua."))
        else say(L("Settings: minimap button, Options → AddOns → DoTDamage or /dot. Report: /dot report.")) end
    end
    namespace.Controller = controller
    loader:RegisterEvent("PLAYER_LOGOUT")
    for _, event in ipairs({ "GROUP_ROSTER_UPDATE", "ZONE_CHANGED_NEW_AREA", "PLAYER_ENTERING_WORLD", "PLAYER_DIFFICULTY_CHANGED" }) do
        pcall(loader.RegisterEvent, loader, event)
    end
    say(L("Loaded. Open settings with the minimap button or /dot."))
end

loader:SetScript("OnEvent", function(_, event, loaded)
    if event == "PLAYER_LOGOUT" then
        if tracker and store then tracker.save(store.character()) end
        return
    end
    if event ~= "ADDON_LOADED" then if store then store.refreshContext() end; return end
    if type(env.issecretvalue) == "function" and env.issecretvalue(loaded) then return end
    if loaded ~= addonName then return end
    loader:UnregisterEvent("ADDON_LOADED")
    local ok = xpcall(initialize, function(reason)
        if diagnostic then diagnostic.capture("startup", reason) end
        return reason
    end)
    if not ok then say("Startfehler. Mit /dot report und /reload einen Bericht sichern.") end
end)

env.SLASH_DOTDAMAGE1, env.SLASH_DOTDAMAGE2 = "/dot", "/dotdamage"
env.SlashCmdList.DOTDAMAGE = function(message)
    if not controller or type(controller.command) ~= "function" then
        if diagnostic then diagnostic.report() end
        say("Laufzeit nicht verfügbar. Diagnose wird nach /reload gespeichert."); return
    end
    controller.run("command", function() controller.command(message) end)
end
