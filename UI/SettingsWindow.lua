local SettingsWindow = {}
local PAGES = {
    { id = "appearance", name = "Appearance", description = "Style and placement for the selected display. Click a group to expand its settings." },
    { id = "advanced", name = "Advanced", description = "Choose when DoTs appear, adjust frame detection or collect a support report." },
    { id = "profiles", name = "Profiles", description = "Profiles are shared across the account. Selection, edits and learned damage belong to this character." },
}
local FILLS = { { id = "none", name = "None" }, { id = "flat", name = "Flat" }, { id = "smooth", name = "Health bar texture" },
    { id = "raid", name = "Raid bar texture" }, { id = "stripes", name = "Diagonal stripes" }, { id = "gradient", name = "Fade in from left" },
    { id = "stripes05", name = "Diagonal Stripes Reversed" } }
local MODES = { { id = "single", name = "One color (fill color)" }, { id = "school", name = "By spell school" }, { id = "each", name = "Different color per DoT" } }
local OUTLINES = { { id = "dashed", name = "Dashed" }, { id = "solid", name = "Solid" }, { id = "none", name = "No outline" } }
local ICONS = { { id = "skull", name = "Raid skull" }, { id = "cross", name = "X" }, { id = "check", name = "Green checkmark" }, { id = "diamond", name = "Diamond" } }
local POSITIONS = { { id = "right", name = "Right of the health bar" }, { id = "left", name = "Left of the health bar" }, { id = "above", name = "Above the health bar" } }
local TEXT_POSITIONS = { { id = "left", name = "Left of the bar" }, { id = "center", name = "Centered on the bar" }, { id = "right", name = "Inside the bar, right end" } }
local WAITS = { { id = "off", name = "None" }, { id = "unsure", name = "When damage is uncertain" }, { id = "always", name = "After first tick" } }
local TINTS = {
    { id = "purple", name = "Purple", rgb = { 0.7, 0.3, 1 } }, { id = "gold", name = "Gold", rgb = { 1, 0.85, 0.1 } },
    { id = "white", name = "White", rgb = { 1, 1, 1 } }, { id = "red", name = "Red", rgb = { 1, 0.2, 0.2 } },
    { id = "orange", name = "Orange", rgb = { 1, 0.55, 0.1 } }, { id = "green", name = "Green", rgb = { 0.3, 1, 0.3 } },
    { id = "cyan", name = "Cyan", rgb = { 0.2, 0.9, 1 } }, { id = "pink", name = "Pink", rgb = { 1, 0.45, 0.6 } },
    { id = "black", name = "Black", rgb = { 0, 0, 0 } }, { id = "blue", name = "Blue", rgb = { 0.2, 0.6, 1 } },
}

function SettingsWindow.create(env, store, controller, deps)
    local ui, window, launcher, scroll, content, title, note, info, surfaceButton, profileButton = {}
    local controls = deps.controls.create(env)
    local L, setText = controls.L, controls.setText
    local editor = store.editor()
    local surface = editor.surface
    local page = editor.page
    if page ~= "appearance" and page ~= "advanced" and page ~= "profiles" then page = "appearance" end
    local options, rows, tabButtons, resetKeys = store.snapshot(), {}, {}, {}
    local pageCache = {}
    local currentGroup, hint, profileNameInput, previewOverlay, previewBar, previewAnchor, previewStage, previewDetail, previewRows
    local targetMock, plateMock, targetBar, plateBar, previewContext, previewStatus, simulationButton, pageDescription
    local profileStatus, profileMessage = nil, ""
    local simulation, sample = nil, { health = 60, damage = 45 }
    local drawPreview
    local family, previewClock = nil, 0
    local resetButton
    local oldGroups = { ["Schadensleiste"] = "Damage bar", ["DoT-Farben"] = "DoT colors", ["Kill-Icon"] = "Kill icon",
        ["Leisteneffekte"] = "Bar effects", ["Schadenstext"] = "Damage text", ["Vorhersage und Diagnose"] = "Prediction",
        ["Prediction and diagnostics"] = "Prediction", ["Runtime controls"] = "Display controls",
        ["UI-Anbindung"] = "UI integration", ["Aktuelles Profil"] = "Account-wide appearance profiles", ["Neues Profil"] = "Save a separate profile",
        ["Profil verwalten"] = "Manage selected profile", ["Automatische Auswahl"] = "Automatic selection (this character)" }
    local migrated = {}
    for key, value in pairs(editor.groups) do
        for old, new in pairs(oldGroups) do
            local first, last = key:find(":" .. old .. ":", 1, true)
            if first then migrated[key:sub(1, first) .. new .. key:sub(last)] = value end
        end
    end
    for key, value in pairs(migrated) do if editor.groups[key] == nil then editor.groups[key] = value end end
    local function safe(label, callback) return function(...) return controller.run(label, callback, ...) end end
    local function message(text)
        text = L(text or "")
        if page == "profiles" then
            profileMessage = text or ""
            if profileStatus then profileStatus:SetText(profileMessage) end
        elseif hint then hint:SetText(text or "") end
    end
    local function result(fn, success)
        local ok, reason = fn()
        local text = L(ok and success or reason or "Action failed.")
        message(not ok and page == "profiles" and ("|cff9b201d" .. text .. "|r") or text); ui.refresh()
    end
    local function target() return surface == "target" end
    local function style() return options[surface] end
    local function applicable(key)
        local function marker() return style().showMarkers end
        local function fill() return style().showMarkers and style().fillStyle ~= "none" end
        local function outline() return style().showMarkers and style().outlineStyle ~= "none" end
        local function icon() return style().showIcon end
        local predicates = { colorMode = marker, fillStyle = marker, outlineStyle = marker,
            color = fill, opacity = fill, dotColors = fill, outlineColor = outline, outlineSize = outline,
            outlineOpacity = outline, dashLength = outline, iconKind = icon, iconPosition = icon,
            iconSize = icon, iconX = icon, iconY = icon, iconPulse = icon, showGlow = outline,
            glowSize = outline, pulseOutline = outline,
            segmentDividers = function() return fill() and style().colorMode ~= "single" end }
        return predicates[key]
    end
    local function profiles(includeCustom)
        local result = {}
        if includeCustom then result[#result + 1] = { id = "", name = "Custom (this character)", help = controls.tip("Profile custom") } end
        for _, entry in ipairs(store.profiles()) do
            result[#result + 1] = { id = entry.id, name = entry.builtin and L("%s (preset)", L(entry.name)) or entry.name, literal = true, builtin = entry.builtin,
                help = controls.tip(entry.builtin and "Profile preset" or "Profile own") }
        end
        return result
    end
    local function profileLabel()
        local id, dirty = store.selectedProfile(); local label = L("Custom")
        for _, item in ipairs(store.profiles()) do if item.id == id then label = item.builtin and L(item.name) or item.name end end
        return label .. (dirty and " *" or "")
    end
    local function add(row, visible, enabled)
        rows[#rows + 1] = { row = row, group = currentGroup, visible = visible, enabled = enabled }
        return row
    end
    local function heading(name, visible, expanded)
        local group = { name = name, visible = visible, default = expanded == true }
        local button = controls.heading(content, name, safe("group", function()
            local key = page .. ":" .. name .. ":" .. surface
            editor.groups[key] = not group.expanded; ui.refresh()
        end))
        group.button = button; rows[#rows + 1] = { row = button, heading = group }; currentGroup = group
        controls.help(button, name, controls.tip("section:" .. name))
    end
    local function getter(key, root) return function() return root and options[key] or style()[key] end end
    local function setter(key, root)
        return safe("option:" .. key, function(value)
            if root then store.setRoot(key, value, surface) else store.setSurface(surface, key, value) end
        end)
    end
    local function checkbox(key, name, root, visible, enabled, tooltip)
        local row = controls.check(content, name, 0, getter(key, root), setter(key, root))
        if not root then resetKeys[#resetKeys + 1] = key end
        controls.help(row, name, tooltip or "Adjust this option for the selected display.")
        controls.help(row.widget, name, tooltip or "Adjust this option for the selected display.")
        return add(row, visible, enabled or not root and applicable(key))
    end
    local function choice(key, name, values, root, visible, enabled, tooltip)
        local row = controls.choice(content, name, 0, values, getter(key, root), setter(key, root))
        if not root then resetKeys[#resetKeys + 1] = key end
        controls.help(row, name, tooltip or "Choose a value for the selected display. Changes are saved on this character.")
        controls.help(row.widget, name, tooltip or "Choose a value for the selected display. Changes are saved on this character.")
        return add(row, visible, enabled or not root and applicable(key))
    end
    local function slider(key, name, low, high, step, percent, visible, enabled)
        resetKeys[#resetKeys + 1] = key
        local units = { iconSize = "px", iconX = "px", iconY = "px", outlineSize = "px", shineInterval = "s", stripeSpeed = "x" }
        local row = controls.slider(content, name, 0, low, high, step, getter(key), setter(key), percent, false, units[key])
        controls.help(row, name, "Adjust this value. The preview updates immediately.")
        controls.help(row.widget, name, "Adjust this value. Use the number field for precise input.")
        return add(row, visible, enabled or applicable(key))
    end
    local function tint(key, name, visible)
        resetKeys[#resetKeys + 1] = key
        local entries = {}; for _, entry in ipairs(TINTS) do entries[#entries + 1] = entry end
        entries[#entries + 1] = { id = "custom", name = "Custom color..." }
        local get = function()
            local rgb = style()[key]
            for _, entry in ipairs(TINTS) do
                if math.abs(rgb[1] - entry.rgb[1]) < 0.001 and math.abs(rgb[2] - entry.rgb[2]) < 0.001 and math.abs(rgb[3] - entry.rgb[3]) < 0.001 then return entry.id end
            end
            return "custom"
        end
        local row
        local function pick(id)
            for _, entry in ipairs(TINTS) do if id == entry.id then store.setSurface(surface, key, entry.rgb); return end end
            local picker = env.ColorPickerFrame
            if not picker or type(picker.SetupColorPickerAndShow) ~= "function" then message("Der WoW-Farbwähler ist nicht verfügbar."); return end
            local before = style()[key]; local editing = surface
            picker:SetupColorPickerAndShow({ r = before[1], g = before[2], b = before[3], hasOpacity = false,
                swatchFunc = function() local r, g, b = picker:GetColorRGB(); store.setSurface(editing, key, { r, g, b }) end,
                cancelFunc = function() store.setSurface(editing, key, before) end })
        end
        row = controls.choice(content, name, 0, entries, get, safe("tint", pick))
        row.colorGetter = function() return style()[key] end
        controls.help(row, name, controls.tip(name))
        controls.help(row.widget, name, controls.tip(name))
        return add(row, visible, applicable(key))
    end
    local function action(name, caption, callback, visible, tooltip, enabled)
        local row = controls.row(content, name, 0)
        row.widget = controls.button(row, caption, 196, -3, 200, safe("action:" .. caption, callback))
        tooltip = controls.tip(caption) or tooltip
        if tooltip then controls.help(row, name, tooltip, true); controls.help(row.widget, name, tooltip, true) end
        return add(row, visible, enabled)
    end
    local function information(name, callback, visible, literal)
        local row = controls.row(content, name, 0)
        local label = controls.text(row, "", 196, 0, 200, "small")
        label:ClearAllPoints(); label:SetPoint("LEFT", 196, 0)
        row.refresh = function()
            local value = callback()
            label:SetText(literal and value or L(value))
            row:SetHeight(math.max(28, label:GetStringHeight() + 8, row.label:GetStringHeight() + 8))
        end
        if controls.tip(name) then controls.help(row, name, controls.tip(name)) end
        return add(row, visible)
    end
    local function confirm(actionId, callback)
        local armed
        return function()
            local now = env.GetTime(); local selected = store.selectedProfile() or "custom"
            if armed and armed.id == selected and now - armed.at < 5 then armed = nil; callback()
            else
                armed = { id = selected, at = now }
                message(L("Click %s again within 5s to confirm.", L(actionId))); ui.refresh()
            end
        end
    end
    local function framePath(key, caption)
        local row = controls.row(content, caption, 0)
        local edit = controls.edit(row, 196, -3, 142, 256)
        local syncing = false
        local function commit()
            local value = (edit:GetText() or ""):match("^%s*(.-)%s*$")
            if not syncing and value ~= options.target[key] then store.setSurface("target", key, value) end
        end
        edit:SetScript("OnEditFocusLost", safe("frame-path", commit))
        edit:SetScript("OnEnterPressed", safe("frame-path-enter", function(self) commit(); self:ClearFocus() end))
        edit:SetScript("OnEscapePressed", function(self) self:SetText(options.target[key]); self:ClearFocus() end)
        edit:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
        controls.help(edit, caption, "Enter a static frame path. Enter applies; Escape cancels. Empty uses automatic detection.")
        row.widget = edit
        controls.help(row, caption, controls.tip(caption))
        controls.button(row, "Pick", 344, -3, 52, safe("frame-pick", function()
            local ok, reason = controller.pickFrame(key, function(path)
                store.setSurface("target", key, path); message(L("Selected: %s", path))
            end)
            message(ok and "Left-click the frame to use it; right-click cancels." or reason)
        end))
        row.refresh = function() if not edit:HasFocus() then syncing = true; edit:SetText(options.target[key]); syncing = false end end
        return add(row, target)
    end
    local function frameStatus(kind)
        local status = controller.frameStatus()[kind]
        if kind == "anchor" then
            local path = status:match("^Auto: (.+)$")
            if path then return L("Auto: %s", path) end
            if options.target.customIconAnchor == status and status ~= "" then return status end
        else
            if options.target.customHealthBar == status and status ~= "" then return status end
            local fallback = status:match("^Ungültiger Pfad; (.+)$")
            if fallback then return L("Invalid path; %s", L(fallback)) end
        end
        return L(status)
    end
    local function buildAppearance()
        heading("General", nil, true)
        choice("uiLanguage", "Language", {
            { id = "auto", name = "Automatic (WoW client)" },
            { id = "deDE", name = "Deutsch", literal = true }, { id = "enUS", name = "English", literal = true },
            { id = "frFR", name = "Français", literal = true }, { id = "esES", name = "Español", literal = true },
        }, true)
        checkbox("plateEnabled", "Show on nameplates", true, nil, nil, "Show DoT forecasts on enemy nameplates. Target-frame display is independent.")
        checkbox("targetEnabled", "Show on target frame", true, nil, nil, "Show the forecast and kill icon on your selected enemy's target frame.")
        checkbox("launcher", "Minimap button", true, nil, nil, "Show the minimap settings button. You can always open settings with /dot.")
        checkbox("linkAppearance", "Link appearance", true, nil, nil, "Link colors, fill, outline and icon design. Sizes, positions and visibility stay separate.")
        heading("Damage bar", nil, false)
        checkbox("showMarkers", "Show damage bar")
        choice("colorMode", "Color mode", MODES)
        choice("fillStyle", "Fill texture", FILLS)
        tint("color", "Fill tint", function() return style().colorMode == "single" and style().fillStyle ~= "none" end)
        slider("opacity", "Fill opacity", 0, 1, 0.05, true, function() return style().fillStyle ~= "none" end)
        choice("outlineStyle", "Outline", OUTLINES)
        tint("outlineColor", "Outline tint", function() return style().outlineStyle ~= "none" end)
        local dashes = { { id = 1, name = "Fine dots (1px)" }, { id = 2, name = "Dots (2px)" },
            { id = 4, name = "Short dashes (4px)" }, { id = 8, name = "Dashes (8px)" }, { id = 16, name = "Long dashes (16px)" } }
        choice("dashLength", "Dash pattern", dashes, false, function() return style().outlineStyle == "dashed" end)
        slider("outlineSize", "Outline width", 1, 8, 1, false, function() return style().outlineStyle ~= "none" end)
        slider("outlineOpacity", "Outline opacity", 0, 1, 0.05, true, function() return style().outlineStyle ~= "none" end)
        checkbox("showGlow", "Outline glow", false, function() return target() and style().outlineStyle ~= "none" end, nil,
            "Add a soft glow in the outline colour. Disable this to keep only the thin outline.")
        slider("glowSize", "Glow size", 2, 16, 1, false, function() return target() and style().showGlow and style().outlineStyle ~= "none" end)
        heading("DoT colors", function() return style().colorMode == "each" end, true)
        resetKeys[#resetKeys + 1] = "dotColors"
        local families = deps.families()
        if #families == 0 then information("DoT colors", function() return "No target DoTs in this class catalog." end) end
        for _, item in ipairs(families) do
            local entry = item
            local values = { { id = "auto", name = "Automatic", rgb = deps.overlay.defaultColor(entry) } }
            for _, tint in ipairs(TINTS) do values[#values + 1] = tint end
            values[#values + 1] = { id = "custom", name = "Custom color..." }
            local get = function()
                local rgb = style().dotColors[entry.familyKey]
                if not rgb then return "auto" end
                for _, tint in ipairs(TINTS) do
                    if math.abs(rgb[1] - tint.rgb[1]) < 0.001 and math.abs(rgb[2] - tint.rgb[2]) < 0.001 and math.abs(rgb[3] - tint.rgb[3]) < 0.001 then return tint.id end
                end
                return "custom"
            end
            local set = safe("family-color", function(id)
                local editing, before = surface, style().dotColors[entry.familyKey]
                local function applyColor(rgb)
                    local map = store.snapshot()[editing].dotColors; map[entry.familyKey] = rgb
                    family = entry; store.setSurface(editing, "dotColors", map)
                end
                if id == "auto" then applyColor(nil); return end
                for _, tint in ipairs(TINTS) do if id == tint.id then applyColor(tint.rgb); return end end
                local picker = env.ColorPickerFrame
                if not picker or type(picker.SetupColorPickerAndShow) ~= "function" then message("WoW-Farbwähler nicht verfügbar."); return end
                local initial = before or deps.overlay.defaultColor(entry)
                picker:SetupColorPickerAndShow({ r = initial[1], g = initial[2], b = initial[3], hasOpacity = false,
                    swatchFunc = function() local r, g, b = picker:GetColorRGB(); applyColor({ r, g, b }) end,
                    cancelFunc = function() applyColor(before) end })
            end)
            local row = controls.choice(content, entry.owner == "pet" and L("%s (Pet)", entry.name) or entry.name, 0, values, get, set)
            local refresh = row.refresh
            row.refresh = function()
                refresh()
                row.label:SetText(entry.owner == "pet" and L("%s (Pet)", entry.name) or entry.name)
            end
            row.colorGetter = function() return style().dotColors[entry.familyKey] or deps.overlay.defaultColor(entry) end
            local icon = row:CreateTexture(nil, "ARTWORK"); icon:SetSize(22, 22); icon:SetPoint("LEFT", 6, 0); icon:SetTexture(entry.icon)
            row.label:ClearAllPoints(); row.label:SetPoint("LEFT", 34, 0); row.label:SetWidth(158)
            controls.help(row, entry.name, controls.tip("DoT colour"), true, true)
            controls.help(row.widget, entry.name, controls.tip("DoT colour"), true, true)
            add(row, nil, applicable("dotColors"))
        end
        action("DoT colors", "Automatic", function() store.setSurface(surface, "dotColors", {}) end)
        heading("Kill icon", nil, false)
        checkbox("showIcon", "Show kill icon")
        choice("iconKind", "Icon design", ICONS)
        tint("crossColor", "X color", function() return style().iconKind == "cross" end)
        tint("diamondColor", "Diamond color", function() return style().iconKind == "diamond" end)
        choice("iconPosition", "Position", POSITIONS, false, function() return not target() end)
        information("Anchor in use", function() return frameStatus("anchor") end, target, true)
        framePath("customIconAnchor", "Icon anchor")
        action("Automatic anchor", "Use portrait", function() store.setSurface("target", "customIconAnchor", "") end, target,
            "Use the detected enemy portrait. If no visible portrait exists, use the health bar. Your icon offsets still apply.")
        slider("iconSize", "Size", 12, 64, 1)
        slider("iconX", "Horizontal offset", -150, 150, 1)
        slider("iconY", "Vertical offset", -150, 150, 1)
        checkbox("iconPulse", "Pulse icon", false, target)
        heading("Bar effects", target, false)
        action("Try enabled effects", "Replay effects", function()
            simulation = nil
            previewOverlay.restartEffects(); drawPreview()
        end, target, "Replay enabled effects using the current forecast. Health, DoT damage and the selected scenario stay unchanged. A running tick simulation is paused. Saved settings and combat data are not changed.")
        checkbox("smoothMotion", "Smooth bar changes", false, target)
        checkbox("flashOnApply", "Flash on new DoT", false, target)
        checkbox("segmentDividers", "Segment dividers", false, target)
        local extra = controls.check(content, "More visual effects", 0, function() return editor.extraEffects end,
            safe("extra-effects", function(value) editor.extraEffects = value; ui.refresh() end))
        add(extra, target)
        local more = function() return target() and editor.extraEffects end
        checkbox("showSpark", "Edge spark", false, more)
        checkbox("pulseOutline", "Pulse outline", false, more)
        checkbox("showShine", "Shine sweep", false, more)
        slider("shineInterval", "Shine interval", 2, 10, 1, false, function() return more() and style().showShine end)
        checkbox("scrollStripes", "Animate stripes", false, function() return more() and (style().fillStyle == "stripes" or style().fillStyle == "stripes05") end)
        slider("stripeSpeed", "Stripe speed", 0.25, 3, 0.25, false,
            function() return more() and (style().fillStyle == "stripes" or style().fillStyle == "stripes05") end,
            function() return style().showMarkers and style().scrollStripes end)
        heading("Damage text", target, false)
        checkbox("showLabel", "Show damage text", false, target)
        choice("labelPosition", "Text position", TEXT_POSITIONS, false, function() return target() and style().showLabel end)
        slider("labelSize", "Text size", 8, 20, 1, false, function() return target() and style().showLabel end)
        tint("labelColor", "Text tint", function() return target() and style().showLabel end)
    end
    local function buildAdvanced()
        heading("Prediction", nil, true)
        information("Tracking status", function()
            local state = controller.status()
            if state.client == "unsupported" then return "This client is not supported." end
            if not state.running then return "Disabled." end
            if state.targetAuraAccess == "no_target" then return "Select an enemy." end
            if state.targetAuraAccess == "blocked" then
                if state.learningContext ~= "solo" and state.learningContext ~= "group" then return "Waiting for combat information." end
                return "Using damage estimates. Some spells need their first tick."
            end
            if state.targetAuraAccess == "readable" then return "Ready to track your DoTs." end
            if state.targetAuraAccess == "incomplete" then return "Waiting for readable DoT information." end
            return "Waiting for DoT information."
        end)
        choice("waitFirstTick", "Extra tick wait", WAITS, true, nil, nil,
            "None uses learned damage or the tooltip as soon as tracking can start. When damage is uncertain waits without learned values; After first tick always waits. Projectiles require an applied aura or a matching tick. Misses cancel matching estimates. The kill icon uses a safety margin and can appear later than the bar.")
        heading("Support", nil, false)
        action("Support report", "Create report", function() controller.report(); message("Report collected. /reload saves SavedVariables/DoTDamage.lua.") end)
        action("Learned damage", "Reset data", confirm("Reset data", function() controller.resetLearning(); message("Learned damage reset.") end))
        heading("UI integration", nil, false)
        framePath("customHealthBar", "Health bar path")
        information("Health bar in use", function() return target() and frameStatus("bar") or L("Automatic (supported UI)") end, nil, true)
    end
    local function buildProfiles()
        local function selected()
            local id = store.selectedProfile(); return id ~= nil and not id:match("^builtin:")
        end
        local function unsaved() local _, dirty = store.selectedProfile(); return selected() and dirty end
        heading("Account-wide appearance profiles", nil, true)
        local row = controls.choice(content, "Saved profiles", 0, function() return profiles(true) end,
            function() return store.selectedProfile() or "" end, safe("profile-select", function(id) result(function() return store.selectProfile(id) end, "Profile loaded; local edits retained.") end))
        add(row)
        information("Editing status", function()
            local id, dirty = store.selectedProfile()
            if id and id:match("^builtin:") then return "Built-in preset (read-only)" end
            if not id then return "Custom (not saved)" end
            return dirty and "Unsaved changes (*)" or "Matches saved profile"
        end)
        action("Update selected", "Save changes", function() result(store.saveProfile, "Changes saved.") end, nil, nil, unsaved)
        heading("Save a separate profile", nil, true)
        local inputRow = controls.row(content, "New name", 0)
        profileNameInput = controls.edit(inputRow, 196, -3, 200, 64)
        profileNameInput:SetText(editor.profileName or "")
        profileNameInput:SetScript("OnTextChanged", function(self) editor.profileName = self:GetText() end)
        controls.help(inputRow, "New name", controls.tip("New name")); controls.help(profileNameInput, "New name", controls.tip("New name"))
        inputRow.widget = profileNameInput; add(inputRow)
        action("Keep current look", "Create as new", function()
            result(function()
                local ok, reason = store.createProfile(profileNameInput:GetText())
                if ok then profileNameInput:SetText(""); editor.profileName = "" end
                return ok, reason
            end, "New profile created.")
        end)
        local statusRow = env.CreateFrame("Frame", nil, content); statusRow:SetSize(396, 28)
        profileStatus = controls.text(statusRow, profileMessage, 6, -6, 384, "small")
        statusRow.refresh = function() profileStatus:SetText(profileMessage); statusRow:SetHeight(math.max(28, profileStatus:GetStringHeight() + 12)) end
        add(statusRow, function() return profileMessage ~= "" end)
        heading("Manage selected profile", nil, false)
        action("Change name", "Rename", function() result(function() return store.renameProfile(profileNameInput:GetText()) end, "Profile renamed.") end, nil, nil, selected)
        action("Discard local edits", "Revert", confirm("Revert", function()
            result(function() return store.selectProfile(store.selectedProfile() or "", true) end, "Saved profile restored.")
        end), nil, nil, unsaved)
        action("Remove shared profile", "Delete", confirm("Delete", function() result(store.deleteProfile, "Profile deleted; current appearance retained.") end), nil, nil, selected)
        heading("Automatic selection (this character)", nil, false)
        checkbox("contextProfilesEnabled", "Use context profiles", true)
        for _, pair in ipairs({ { "solo", "Solo" }, { "group", "Group" }, { "dungeon", "Dungeon" }, { "raid", "Raid" } }) do
            local context = pair[1]
            local row = controls.choice(content, pair[2], 0, function()
                local list = profiles(false)
                for _, item in ipairs(list) do item.help = controls.tip("Context assignment") end
                table.insert(list, 1, { id = "", name = "Keep current profile", help = controls.tip("Keep current profile") }); return list
            end, function() return store.contextProfile(context) end, safe("context-profile", function(id) store.setContext(context, id) end))
            add(row, nil, function() return options.contextProfilesEnabled end)
        end
        information("Current context", function() local context = store.context(); return context:sub(1, 1):upper() .. context:sub(2) end)
    end
    local function fitPreviewPlate()
        local halfWidth, halfHeight = plateMock:GetWidth() / 2, plateMock:GetHeight() / 2
        local minX, maxX, minY, maxY = -halfWidth, halfWidth, -halfHeight, halfHeight
        local s = style()
        if s.showIcon then
            local left, right, bottom, top
            if s.iconPosition == "above" then
                left, right = s.iconX - s.iconSize / 2, s.iconX + s.iconSize / 2
                bottom = -halfHeight + plateBar:GetHeight() + 4 + s.iconY; top = bottom + s.iconSize
            else
                bottom = -halfHeight + plateBar:GetHeight() / 2 + s.iconY - s.iconSize / 2
                top = bottom + s.iconSize
                if s.iconPosition == "right" then left = halfWidth + 4 + s.iconX; right = left + s.iconSize
                else right = -halfWidth - 4 + s.iconX; left = right - s.iconSize end
            end
            minX, maxX = math.min(minX, left), math.max(maxX, right)
            minY, maxY = math.min(minY, bottom), math.max(maxY, top)
        end
        plateMock:SetScale(math.min(0.8, (previewStage:GetWidth() / 2 - 10) / math.max(-minX, maxX),
            (previewStage:GetHeight() / 2 - 10) / math.max(-minY, maxY)))
    end
    drawPreview = function()
        if not window or not window:IsShown() then return end
        previewBar = target() and targetBar or plateBar
        targetMock:SetShown(target()); plateMock:SetShown(not target())
        if not target() then fitPreviewPlate() end
        previewBar:SetValue(sample.health)
        previewOverlay.configure(style())
        local a = family and family.familyKey or "preview/shadow"
        local forecast = { totalDamage = sample.damage, conservativeDamage = sample.damage * 0.95, effectCount = 2,
            effects = { { familyKey = a, school = 32, damage = sample.damage * 0.6, appliedAt = 0 },
                { familyKey = "preview/fire", school = 4, damage = sample.damage * 0.4, appliedAt = 0 } } }
        local ok, reason = previewOverlay.update({ root = target() and targetMock or plateMock, bar = previewBar, anchor = target() and previewAnchor or previewBar, source = "UI preview" },
            forecast, { current = sample.health, maximum = 100, healthReadable = true, maxReadable = true }, target() and "preview-target" or "preview-plates")
        if ok == false then controller.error("preview", reason) end
        previewAnchor:SetShown(target())
        setText(previewContext, target() and "Target frame example" or "Nameplate example")
        if sample.health <= 0 then setText(previewStatus, "Enemy defeated"); setText(previewDetail, "Choose a scenario to try again.")
        elseif sample.damage <= 0 then setText(previewStatus, "No DoT damage"); setText(previewDetail, "No damage remains in this example.")
        elseif sample.damage * 0.95 >= sample.health then previewStatus:SetText("|cff66ff66" .. L("DoTs cover remaining HP") .. "|r"); setText(previewDetail, "Predicted lethal damage")
        elseif sample.damage >= sample.health then setText(previewStatus, "Close to lethal"); setText(previewDetail, "The safety margin needs more damage.")
        else
            setText(previewStatus, L("%g%% HP left", math.floor((sample.health - sample.damage) * 100 + 0.5) / 100))
            setText(previewDetail, sample.health - sample.damage <= sample.health * 0.1 and "Close, but more damage is needed." or "More damage needed")
        end
        setText(simulationButton, simulation and "Pause ticks" or "Play ticks")
        controls.help(simulationButton, simulation and "Pause ticks" or "Play ticks", controls.tip("Play ticks"), true)
        simulationButton:SetEnabled(simulation ~= nil or sample.health > 0 and sample.damage > 0)
        for _, row in ipairs(previewRows) do row.refresh() end
    end
    local function rebuild()
        controls.closeMenu()
        for _, item in ipairs(rows) do item.row:Hide() end
        if pageCache[page] then
            rows, resetKeys = pageCache[page].rows, pageCache[page].keys
            setText(title, page == "appearance" and "Appearance" or page == "advanced" and "Advanced" or "Profiles")
            scroll:SetVerticalScroll(0); return
        end
        rows, resetKeys, currentGroup = {}, {}, nil
        setText(title, page == "appearance" and "Appearance" or page == "advanced" and "Advanced" or "Profiles")
        if page == "appearance" then buildAppearance() elseif page == "advanced" then buildAdvanced() else buildProfiles() end
        pageCache[page] = { rows = rows, keys = resetKeys }
        scroll:SetVerticalScroll(0)
    end
    function ui.refresh()
        options = store.snapshot()
        if controls.refreshLocale() then
            profileMessage = ""
            if hint then hint:SetText("") end
        end
        if launcher then launcher:SetShown(options.launcher) end
        if not window or not window:IsShown() then return end
        setText(surfaceButton, target() and "Editing: Target frame" or "Editing: Nameplates")
        profileButton:SetText(L("Profile: %s", profileLabel()))
        for id, button in pairs(tabButtons) do button.setSelected(id == page) end
        for _, entry in ipairs(PAGES) do if entry.id == page then setText(title, entry.name); setText(pageDescription, entry.description) end end
        local inset = math.max(66, 44 + pageDescription:GetStringHeight())
        scroll:SetPoint("TOPLEFT", 8, -inset); scroll:SetHeight(466 - inset - 40)
        if resetButton then
            resetButton:SetShown(page ~= "profiles")
            controls.help(resetButton, "Reset this page", controls.tip(page == "appearance" and "Reset appearance" or "Reset advanced"), true)
        end
        local y = 0
        for _, item in ipairs(rows) do
            local visible
            if item.heading then
                local group = item.heading
                local key = page .. ":" .. group.name .. ":" .. surface
                local saved = editor.groups[key]
                group.expanded = saved == nil and group.default or saved == true
                group.shown = not group.visible or group.visible()
                setText(group.button, group.name); group.button.setExpanded(group.expanded)
                visible = group.shown
            else visible = (not item.visible or item.visible()) and (not item.group or item.group.shown and item.group.expanded) end
            item.row:SetShown(visible)
            if visible then
                item.row:ClearAllPoints(); item.row:SetPoint("TOPLEFT", 0, -y)
                if item.row.refresh then item.row.refresh() end
                if item.row.label then item.row:SetHeight(math.max(28, item.row:GetHeight(), item.row.label:GetStringHeight() + 8)) end
                y = y + item.row:GetHeight() + (item.heading and 4 or 0)
                item.row:SetAlpha((not item.enabled or item.enabled()) and 1 or 0.4)
                item.row.enabled = not item.enabled or item.enabled()
                item.row:EnableMouse(true)
                if item.row.widget then
                    if item.row.widget.SetEnabled then item.row.widget:SetEnabled(item.row.enabled) end
                    item.row.widget:EnableMouse(true)
                    if item.row.widget:GetObjectType() == "Slider" then item.row.widget:EnableMouseWheel(item.row.enabled) end
                    if item.row.input and item.row.input.SetEnabled then item.row.input:SetEnabled(item.row.enabled) end
                end
            end
        end
        content:SetHeight(math.max(scroll:GetHeight(), y + 8))
        local range = math.max(0, content:GetHeight() - scroll:GetHeight())
        scroll:SetVerticalScroll(math.min(scroll:GetVerticalScroll(), range))
        if scroll.ScrollBar then scroll.ScrollBar:SetShown(range > 0.5) end
        drawPreview()
    end
    local function createWindow()
        window = deps.theme.frame(env)
        window:SetPoint("CENTER"); window:SetMovable(true)
        local drag = env.CreateFrame("Frame", nil, window); drag:SetHeight(32)
        drag:EnableMouse(true); drag:RegisterForDrag("LeftButton")
        drag:SetScript("OnDragStart", function() window:StartMoving() end)
        drag:SetScript("OnDragStop", function()
            window:StopMovingOrSizing()
            local point, _, relative, x, y = window:GetPoint(1)
            if point == relative and type(x) == "number" and type(y) == "number" then editor.position = { point = point, x = x, y = y } end
        end)
        local position = editor.position
        if position then window:ClearAllPoints(); window:SetPoint(position.point, env.UIParent, position.point, position.x, position.y) end
        local close = window.CloseButton or env.CreateFrame("Button", nil, window, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -4, -4); close:SetScript("OnClick", function() window:Hide() end)
        controls.help(close, "Close window", controls.tip("Close window"))
        if env.UISpecialFrames then env.UISpecialFrames[#env.UISpecialFrames + 1] = "DoTDamageSettingsWindow" end
        surfaceButton = controls.button(window, "", 84, -42, 178, safe("surface", function()
            surface = target() and "plates" or "target"; editor.surface = surface
            if env.ColorPickerFrame and type(env.ColorPickerFrame.Hide) == "function" then env.ColorPickerFrame:Hide() end
            simulation = nil; family = nil; rebuild(); ui.refresh()
        end))
        profileButton = controls.button(window, "", 492, -42, 232, safe("quick-profile", function()
            controls.menu(profileButton, profiles(true), store.selectedProfile() or "", safe("quick-select", function(id) store.selectProfile(id) end))
        end))
        drag:SetPoint("TOPLEFT", 62, -10); drag:SetPoint("TOPRIGHT", profileButton, "TOPLEFT", -12, 32)
        controls.help(drag, "Move window", "Drag the title bar. The window position is saved. Press Escape to close.")
        controls.help(surfaceButton, "Display to edit", "Switch between enemy nameplates and the optional target frame. This selects the editor and preview.")
        controls.help(profileButton, "Select appearance profile", "Choose a saved profile. An asterisk marks unsaved changes. Use Profiles to create, save or manage profiles.")
        profileButton:SetFrameLevel(drag:GetFrameLevel() + 1)
        local profileFont = profileButton:GetFontString()
        if profileFont then
            profileFont:ClearAllPoints(); profileFont:SetPoint("LEFT", 8, 0); profileFont:SetPoint("RIGHT", -24, 0)
            profileFont:SetWordWrap(false); profileFont:SetJustifyH("LEFT")
        end
        local arrow = controls.text(profileButton, "v", 0, 0, nil, "small", deps.theme.colors.gold)
        arrow:ClearAllPoints(); arrow:SetPoint("RIGHT", -8, 0)
        local navigation = env.CreateFrame("Frame", nil, window)
        navigation:SetPoint("TOPLEFT", 16, -80); navigation:SetSize(402, 28)
        for index, entry in ipairs(PAGES) do
            local id = entry.id
            tabButtons[id] = controls.tab(navigation, entry.name, (index - 1) * 114, 0, safe("page", function()
                page = id; editor.page = id; rebuild(); message(""); ui.refresh()
            end))
            controls.help(tabButtons[id], entry.name, entry.description)
        end
        local paper = deps.theme.parchment(env, window)
        paper:SetPoint("TOPLEFT", 16, -116); paper:SetPoint("BOTTOMLEFT", 16, 18); paper:SetSize(440, 466)
        title = controls.text(paper, "", 14, -12, 412, "page")
        pageDescription = controls.text(paper, "", 14, -32, 412, "description", deps.theme.colors.muted)
        pageDescription:SetWordWrap(true)
        scroll = env.CreateFrame("ScrollFrame", "DoTDamageSettingsScroll", paper, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 8, -66); scroll:SetPoint("BOTTOMRIGHT", -30, 40); scroll:SetSize(402, 360)
        content = env.CreateFrame("Frame", nil, scroll); content:SetSize(402, 360); scroll:SetScrollChild(content)
        resetButton = controls.button(paper, "Reset page", 0, 0, 118, safe("reset-page", function()
            if page == "appearance" then store.resetFields(surface, resetKeys); editor.extraEffects = false
            elseif page == "advanced" then
                store.setRoot("confirmedOnly", true); store.setRoot("waitFirstTick", "off")
                if target() then store.setSurface("target", "customHealthBar", "") end
            end
            message("Page settings restored."); ui.refresh()
        end))
        resetButton:ClearAllPoints(); resetButton:SetPoint("BOTTOMRIGHT", -12, 10)
        controls.help(resetButton, "Reset this page", "Restore appearance fields for this display, or the tick-wait and manual health-bar path on Advanced. General switches, profiles and learned damage are preserved.")
        hint = controls.text(paper, "", 12, 0, 286, "small", deps.theme.colors.muted)
        hint:ClearAllPoints(); hint:SetPoint("BOTTOMLEFT", 12, 13)
        local pane = env.CreateFrame("Frame", nil, window, "BackdropTemplate")
        pane:SetPoint("TOPLEFT", 468, -116); pane:SetPoint("BOTTOMRIGHT", -16, 18); pane:SetSize(256, 466)
        deps.theme.box(pane, 0.05, 0.95)
        controls.text(pane, "Damage forecast", 12, -12, 218, "previewTitle", deps.theme.colors.gold)
        previewContext = controls.text(pane, "", 12, -34, 218, "small", deps.theme.colors.disabled)
        controls.button(pane, "Survives", 12, -60, 106, safe("survives", function() simulation = nil; sample.health, sample.damage = 60, 45; drawPreview() end))
        controls.button(pane, "Lethal", 124, -60, 106, safe("lethal", function() simulation = nil; sample.health, sample.damage = 60, 72; drawPreview() end))
        previewStage = env.CreateFrame("Frame", nil, pane, "BackdropTemplate")
        previewStage:SetPoint("TOPLEFT", 12, -94); previewStage:SetSize(218, 86); deps.theme.box(previewStage, 0.03)
        targetMock = env.CreateFrame("Frame", nil, previewStage); targetMock:SetAllPoints()
        previewAnchor = env.CreateFrame("Frame", nil, targetMock, "BackdropTemplate")
        previewAnchor:SetSize(44, 44); previewAnchor:SetPoint("RIGHT", -10, 0); deps.theme.box(previewAnchor, 0.08)
        local anchorText = controls.text(targetMock, "Icon anchor", 0, 0, nil, 11, deps.theme.colors.disabled)
        anchorText:ClearAllPoints(); anchorText:SetPoint("TOP", previewAnchor, "BOTTOM", 0, -3)
        targetBar = env.CreateFrame("StatusBar", nil, targetMock)
        targetBar:SetSize(144, 18); targetBar:SetPoint("RIGHT", previewAnchor, "LEFT", -7, -6)
        targetBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar"); targetBar:SetStatusBarColor(0.1, 0.8, 0.1); targetBar:SetMinMaxValues(0, 100)
        local targetBack = targetBar:CreateTexture(nil, "BACKGROUND"); targetBack:SetAllPoints(); targetBack:SetColorTexture(0.25, 0.08, 0.08, 1)
        local targetName = controls.text(targetMock, "Test enemy", 0, 0, nil, "small", deps.theme.colors.gold)
        targetName:ClearAllPoints(); targetName:SetPoint("BOTTOMLEFT", targetBar, "TOPLEFT", 0, 4)
        plateMock = env.CreateFrame("Frame", nil, previewStage); plateMock:SetSize(176, 44); plateMock:SetPoint("CENTER")
        plateBar = env.CreateFrame("StatusBar", nil, plateMock)
        plateBar:SetSize(176, 16); plateBar:SetPoint("BOTTOM"); plateBar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
        plateBar:SetStatusBarColor(0.1, 0.8, 0.1); plateBar:SetMinMaxValues(0, 100)
        local plateBack = plateBar:CreateTexture(nil, "BACKGROUND"); plateBack:SetAllPoints(); plateBack:SetColorTexture(0.1, 0.02, 0.02, 1)
        local plateName = controls.text(previewStage, "Test enemy", 0, 0, nil, "small", deps.theme.colors.white)
        plateName:ClearAllPoints(); plateName:SetPoint("BOTTOM", plateBar, "TOP", 0, 6)
        plateMock:SetScript("OnShow", function() plateName:Show() end)
        plateMock:SetScript("OnHide", function() plateName:Hide() end)
        previewBar = plateBar
        previewOverlay = deps.overlay.create(env, deps.restricted, deps.addonName)
        previewStatus = controls.text(pane, "", 12, -194, 218, "status", deps.theme.colors.white)
        previewDetail = controls.text(pane, "", 12, -232, 218, "small", deps.theme.colors.white)
        local sliderHost = env.CreateFrame("Frame", nil, pane); sliderHost:SetPoint("TOPLEFT", 8, -272); sliderHost:SetSize(226, 60)
        previewRows = {
            controls.slider(sliderHost, "Health", 0, 0, 100, 1, function() return sample.health end, safe("preview-health", function(v) simulation = nil; sample.health = v; drawPreview() end), false, true, "%"),
            controls.slider(sliderHost, "DoT damage", -30, 0, 100, 1, function() return sample.damage end, safe("preview-damage", function(v) simulation = nil; sample.damage = v; drawPreview() end), false, true, "%"),
        }
        simulationButton = controls.button(pane, "Play ticks", 12, -342, 218, safe("simulate", function()
            if simulation then simulation = nil
            elseif sample.health > 0 and sample.damage > 0 then simulation = { elapsed = 0, tick = sample.damage / 6, count = 6 } end
            drawPreview()
        end))
        controls.text(pane, "Style changes apply in game instantly.\n\nExamples use % of maximum HP.", 12, -380, 218, "body", deps.theme.colors.disabled)
        window:SetScript("OnHide", function()
            simulation = nil; controls.closeMenu(); controls.hideHelp(); previewOverlay.hide("preview_closed"); controller.stopPick()
            if env.ColorPickerFrame and type(env.ColorPickerFrame.Hide) == "function" then env.ColorPickerFrame:Hide() end
        end)
        window:SetScript("OnShow", function() rebuild(); ui.refresh() end)
        window:SetScript("OnUpdate", safe("editor-update", function(_, delta)
            previewClock = previewClock + delta
            if simulation then
                simulation.elapsed = simulation.elapsed + delta
                while simulation and simulation.elapsed >= 0.5 do
                    simulation.elapsed = simulation.elapsed - 0.5
                    local damage = math.min(sample.damage, simulation.tick)
                    sample.health, sample.damage = math.max(0, sample.health - damage), math.max(0, sample.damage - damage)
                    simulation.count = simulation.count - 1
                    if simulation.count <= 0 or sample.health <= 0 then simulation = nil end
                    drawPreview()
                end
            end
            if previewClock >= 1 then previewClock = 0; ui.refresh() end
        end))
        window:Hide()
    end

    function ui.open() if not window then createWindow() end; window:Show(); ui.refresh() end
    function ui.register()
        if env.Minimap then
            launcher = env.CreateFrame("Button", "DoTDamageLauncher", env.Minimap); launcher:SetSize(28, 28); launcher:SetPoint("BOTTOMRIGHT", -3, 3)
            launcher:SetNormalTexture(deps.theme.brandIcon)
            launcher:SetScript("OnClick", safe("launcher", ui.open)); controls.help(launcher, "DoTDamage", "Klicken: Einstellungen öffnen.")
        end
        local canvas = env.CreateFrame("Frame", nil, env.UIParent); canvas.name = "DoTDamage"; canvas:Hide()
        local title = controls.text(canvas, "DoTDamage", 16, -16, nil, 18, deps.theme.colors.gold)
        local text = controls.text(canvas, "Configure enemy nameplates and the optional target frame. Type /dot to open the editor.", 0, 0, nil, "body", deps.theme.colors.white)
        text:ClearAllPoints(); text:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
        local open = controls.button(canvas, "Open DoTDamage", 0, 0, 180, safe("options", ui.open))
        open:ClearAllPoints(); open:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -14)
        if env.Settings and type(env.Settings.RegisterCanvasLayoutCategory) == "function" then
            local ok, category = pcall(env.Settings.RegisterCanvasLayoutCategory, canvas, "DoTDamage")
            if ok then local good, reason = pcall(env.Settings.RegisterAddOnCategory, category); if not good then controller.error("category", reason) end end
        elseif env.InterfaceOptions_AddCategory then env.InterfaceOptions_AddCategory(canvas) end
        store.subscribe(ui.refresh); ui.refresh()
    end
    return ui
end
local _, namespace = ...
if type(namespace) == "table" then namespace.SettingsWindow = SettingsWindow end
return SettingsWindow
