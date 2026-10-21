local Store = {}

local function clone(value)
    if type(value) ~= "table" then return value end
    local copy = {}
    for key, item in pairs(value) do copy[key] = clone(item) end
    return copy
end

local DEFAULT_SURFACE = {
    showMarkers = true, showIcon = true, fillStyle = "flat", opacity = 0.8,
    colorMode = "each", color = { 0.68, 0.42, 0.92 }, dotColors = {},
    outlineStyle = "solid", outlineSize = 1, outlineOpacity = 0.9,
    outlineColor = { 1, 0.88, 0.56 }, iconKind = "skull", iconSize = 20,
    crossColor = { 1, 0.2, 0.2 }, diamondColor = { 0.2, 0.6, 1 },
    iconPosition = "left", iconX = -5, iconY = 0, showLabel = false, labelSize = 11,
    dashLength = 4, iconPulse = true, smoothMotion = true, flashOnApply = true, segmentDividers = true,
    showSpark = true, pulseOutline = true, showGlow = true, glowSize = 7,
    showShine = true, shineInterval = 3, scrollStripes = true, stripeSpeed = 1,
    labelPosition = "center", labelColor = { 1, 1, 1 }, customHealthBar = "", customIconAnchor = "",
}
local ENUMS = {
    fillStyle = { "none", "flat", "smooth", "raid", "stripes", "gradient", "stripes05" }, colorMode = { "each", "school", "single" },
    outlineStyle = { "none", "solid", "dashed" }, iconKind = { "skull", "cross", "check", "diamond" },
    iconPosition = { "left", "right", "above" },
    labelPosition = { "left", "center", "right" }, dashLength = { 1, 2, 4, 8, 16 },
}
local LIMITS = {
    opacity = { 0, 1 }, outlineSize = { 1, 8 }, outlineOpacity = { 0, 1 },
    iconSize = { 12, 64 }, iconX = { -150, 150 }, iconY = { -150, 150 }, labelSize = { 8, 20 },
    glowSize = { 2, 16 }, shineInterval = { 2, 10 }, stripeSpeed = { 0.25, 3 },
}
local ROOT_DEFAULTS = { enabled = true, confirmedOnly = true, targetEnabled = false, plateEnabled = true, launcher = true, linkAppearance = false,
    contextProfilesEnabled = false }
local LINKED = { fillStyle = true, opacity = true, colorMode = true, color = true, dotColors = true,
    outlineStyle = true, outlineSize = true, outlineOpacity = true, outlineColor = true, dashLength = true,
    iconKind = true, crossColor = true, diamondColor = true }
local PRESETS = {
    { id = "builtin:clean", name = "Clean", values = { fillStyle = "flat", colorMode = "each", opacity = 0.7,
        outlineColor = { 1, 1, 1 }, outlineOpacity = 0.85, iconPulse = false, flashOnApply = false,
        segmentDividers = false, showSpark = false, pulseOutline = false, showGlow = false,
        showShine = false, scrollStripes = false } },
    { id = "builtin:classic", name = "Classic", values = { fillStyle = "smooth", colorMode = "single", opacity = 0.65, color = { 1, 0.85, 0.1 }, outlineColor = { 1, 0.85, 0.1 }, outlineOpacity = 1 } },
    { id = "builtin:color", name = "Stripes", values = { fillStyle = "stripes", colorMode = "each", opacity = 0.75, outlineColor = { 1, 1, 1 }, outlineOpacity = 0.85 } },
}
local REMOVED_PRESETS = { ["builtin:beta05"] = true, ["builtin:school"] = true }
local FIRST_INSTALL_PROFILE = "builtin:clean"
local function presetSurface(preset)
    local surface = clone(DEFAULT_SURFACE)
    for key, value in pairs(preset.values) do surface[key] = clone(value) end
    return surface
end

function Store.create(env, restricted)
    local store, listeners = {}, {}
    local function plain(value) return not restricted(value) end
    local function field(value, key)
        if not plain(value) or type(value) ~= "table" then return nil end
        local ok, answer = pcall(function() return value[key] end)
        if ok and plain(answer) then return answer end
    end
    local function finite(value)
        return plain(value) and type(value) == "number" and value == value and math.abs(value) < math.huge
    end
    local function rgb(value, fallback)
        local result = {}
        for index = 1, 3 do
            local number = field(value, index)
            result[index] = finite(number) and math.max(0, math.min(1, number)) or fallback[index]
        end
        return result
    end
    local function colors(value)
        local result, count = {}, 0
        if not plain(value) or type(value) ~= "table" then return result end
        for key, color in pairs(value) do
            if count >= 64 then break end
            if plain(key) and type(key) == "string" and #key <= 128 and not key:find("[%c|]")
                and plain(color) and type(color) == "table" then
                result[key], count = rgb(color, DEFAULT_SURFACE.color), count + 1
            end
        end
        return result
    end
    local function sanitizeSurface(source)
        local result = {}
        for key, default in pairs(DEFAULT_SURFACE) do
            local value = field(source, key)
            if key == "dotColors" then result[key] = colors(value)
            elseif key == "color" or key == "outlineColor" or key == "labelColor" or key == "crossColor" or key == "diamondColor" then result[key] = rgb(value, default)
            elseif key == "customHealthBar" or key == "customIconAnchor" then
                result[key] = type(value) == "string" and #value <= 256 and not value:find("[%c|]") and value or ""
            elseif key == "iconKind" and value == "boss" then result[key] = "diamond"
            elseif ENUMS[key] then
                result[key] = default
                for _, allowed in ipairs(ENUMS[key]) do if value == allowed then result[key] = value; break end end
            elseif LIMITS[key] then
                local bounds = LIMITS[key]
                result[key] = finite(value) and math.max(bounds[1], math.min(bounds[2], value)) or default
            elseif type(value) == type(default) then result[key] = value
            else result[key] = default end
        end
        return result
    end
    local function sanitize(source)
        local result = { plates = sanitizeSurface(field(source, "plates")), target = sanitizeSurface(field(source, "target")) }
        for key, default in pairs(ROOT_DEFAULTS) do
            local value = field(source, key)
            if type(value) == "boolean" then result[key] = value else result[key] = default end
        end
        result.enabled = true
        result.confirmedOnly = true
        local wait = field(source, "waitFirstTick")
        result.waitFirstTick = (wait == "always" or wait == "unsure") and wait or "off"
        local language = field(source, "uiLanguage")
        result.uiLanguage = (language == "deDE" or language == "enUS" or language == "frFR" or language == "esES") and language or "auto"
        return result
    end
    local function profileName(value)
        if not plain(value) or type(value) ~= "string" then return nil end
        value = value:match("^%s*(.-)%s*$")
        if #value < 1 or #value > 64 or value:find("[%c|]") then return nil end
        return value
    end
    local character = env.DoTDamageState
    if not plain(character) or type(character) ~= "table" then character = {} end
    env.DoTDamageState = character
    local previousSettings = field(character, "settings")
    local firstInstall = previousSettings == nil
    character.settings = sanitize(previousSettings)
    character.schema = 3
    local current = character.settings
    local account = env.DoTDamageOptions
    if not plain(account) or type(account) ~= "table" then account = {} end
    env.DoTDamageOptions = account
    local profiles, count = {}, 0
    local saved = field(account, "profiles")
    if type(saved) == "table" then
        for id, profile in pairs(saved) do
            if count >= 32 then break end
            local name = profileName(field(profile, "name"))
            if plain(id) and type(id) == "string" and id:match("^user:%d+$") and #id <= 32 and name then
                local options = sanitize(field(profile, "settings"))
                profiles[id] = { name = name, settings = { plates = options.plates, target = options.target, linkAppearance = options.linkAppearance } }
                count = count + 1
            end
        end
    end
    account.schema, account.profiles = 1, profiles
    local serial = field(account, "serial")
    account.serial = finite(serial) and serial >= 0 and serial < 1000000000 and math.floor(serial) or 0
    local selected = field(character, "profileId")
    character.profileId = profiles[selected] and selected or nil
    for _, preset in ipairs(PRESETS) do if selected == preset.id then character.profileId = selected end end
    character.profileDirty = field(character, "profileDirty") == true or REMOVED_PRESETS[selected] == true
    local drafts = field(character, "profileDrafts")
    character.profileDrafts = {}
    local draftCount = 0
    if type(drafts) == "table" then
        for id, values in pairs(drafts) do
            if draftCount >= 36 then break end
            if plain(id) and type(id) == "string" and #id <= 40 then
                character.profileDrafts[id] = sanitize(values); draftCount = draftCount + 1
            end
        end
    end
    local contexts = field(character, "contextProfiles")
    character.contextProfiles = {}
    for _, context in ipairs({ "solo", "group", "dungeon", "raid" }) do
        local id = field(contexts, context)
        if type(id) == "string" and not REMOVED_PRESETS[id] then character.contextProfiles[context] = id end
    end
    local view = field(character, "editor")
    character.editor = { page = field(view, "page") or "appearance", surface = field(view, "surface") == "target" and "target" or "plates",
        extraEffects = field(view, "extraEffects") == true, groups = {} }
    local draftName = field(view, "profileName")
    character.editor.profileName = type(draftName) == "string" and #draftName <= 64 and draftName or ""
    local savedGroups = field(view, "groups")
    if type(savedGroups) == "table" then
        local count = 0
        for key, value in pairs(savedGroups) do
            if count >= 64 then break end
            if plain(key) and type(key) == "string" and #key <= 96 and type(value) == "boolean" then
                character.editor.groups[key] = value; count = count + 1
            end
        end
    end
    local position = field(view, "position")
    local point, x, y = field(position, "point"), field(position, "x"), field(position, "y")
    local anchors = { CENTER = true, TOPLEFT = true, TOPRIGHT = true, BOTTOMLEFT = true, BOTTOMRIGHT = true, LEFT = true, RIGHT = true, TOP = true, BOTTOM = true }
    if anchors[point] and finite(x) and finite(y) and math.abs(x) < 10000 and math.abs(y) < 10000 then
        character.editor.position = { point = point, x = x, y = y }
    end

    local function notify()
        for _, callback in ipairs(listeners) do callback(store.snapshot()) end
    end
    local function appearance()
        return { plates = clone(current.plates), target = clone(current.target), linkAppearance = current.linkAppearance }
    end
    function store.snapshot() return clone(current) end
    function store.character() return character end
    function store.subscribe(callback) listeners[#listeners + 1] = callback end
    function store.setRoot(key, value, source)
        if key == "confirmedOnly" and value ~= true then return false end
        if key == "uiLanguage" then
            if value ~= "auto" and value ~= "deDE" and value ~= "enUS" and value ~= "frFR" and value ~= "esES" then return false end
            current[key] = value; notify(); return true
        end
        if key == "waitFirstTick" then
            if value ~= "off" and value ~= "always" and value ~= "unsure" then return false end
            current[key] = value; notify(); return true
        end
        if ROOT_DEFAULTS[key] == nil or type(value) ~= "boolean" then return false end
        current[key] = value
        if key == "linkAppearance" then
            if value then
                source = source == "target" and "target" or "plates"
                local other = source == "target" and "plates" or "target"
                for linked in pairs(LINKED) do current[other][linked] = clone(current[source][linked]) end
            end
            character.profileDirty = true
        end
        notify()
        if key == "contextProfilesEnabled" then store.refreshContext(true) end
        return true
    end
    function store.setSurface(surface, key, value)
        if (surface ~= "plates" and surface ~= "target") or DEFAULT_SURFACE[key] == nil then return false end
        local candidate = clone(current[surface]); candidate[key] = value
        current[surface] = sanitizeSurface(candidate)
        if current.linkAppearance and LINKED[key] then current[surface == "plates" and "target" or "plates"][key] = clone(current[surface][key]) end
        character.profileDirty = true
        notify(); return true
    end
    function store.resetSurface(surface)
        if surface ~= "plates" and surface ~= "target" then return false end
        current[surface] = presetSurface(PRESETS[1])
        if current.linkAppearance then for key in pairs(LINKED) do current[surface == "plates" and "target" or "plates"][key] = clone(current[surface][key]) end end
        character.profileDirty = true; notify(); return true
    end
    function store.profiles()
        local result = {}
        for _, preset in ipairs(PRESETS) do result[#result + 1] = { id = preset.id, name = preset.name, builtin = true } end
        local custom = {}
        for id, profile in pairs(profiles) do custom[#custom + 1] = { id = id, name = profile.name } end
        table.sort(custom, function(a, b) return a.name:lower() < b.name:lower() end)
        for _, item in ipairs(custom) do result[#result + 1] = item end
        return result
    end
    function store.selectedProfile() return character.profileId, character.profileDirty end
    function store.selectProfile(id, discard)
        local options = profiles[id] and profiles[id].settings
        if not options then
            for _, preset in ipairs(PRESETS) do
                if preset.id == id then
                    if preset.plates then options = { plates = preset.plates, target = preset.target, linkAppearance = false }
                    else
                        local surface = presetSurface(preset)
                        options = { plates = surface, target = surface, linkAppearance = true }
                    end
                    break
                end
            end
        end
        if id == "" then options = character.profileDrafts.__custom or sanitize(nil) end
        if not options then return false, "Profil nicht gefunden." end
        local oldKey = character.profileId or "__custom"
        if character.profileDirty and not discard then character.profileDrafts[oldKey] = appearance() end
        local key = id ~= "" and id or "__custom"
        if discard then character.profileDrafts[key] = nil
        elseif character.profileDrafts[key] then options = character.profileDrafts[key] end
        current.plates, current.target, current.linkAppearance = sanitizeSurface(options.plates), sanitizeSurface(options.target), options.linkAppearance == true
        character.profileId = id ~= "" and id or nil
        character.profileDirty = not discard and character.profileDrafts[key] ~= nil
        notify(); return true
    end
    function store.createProfile(name)
        name = profileName(name)
        if not name then return false, "Profilname: 1–64 Bytes, ohne Steuerzeichen oder |." end
        for _, profile in ipairs(store.profiles()) do if profile.name:lower() == name:lower() then return false, "Dieser Name ist bereits vergeben." end end
        local size = 0
        for _ in pairs(profiles) do size = size + 1 end
        if size >= 32 then return false, "Maximal 32 eigene Profile." end
        local id
        repeat account.serial = account.serial + 1; id = "user:" .. account.serial until not profiles[id]
        if character.profileId then character.profileDrafts[character.profileId] = nil end
        profiles[id] = { name = name, settings = appearance() }
        character.profileId, character.profileDirty = id, false
        notify(); return true
    end
    function store.saveProfile()
        local profile = profiles[character.profileId]
        if not profile then return false, "Zuerst ein eigenes Profil anlegen. Vorlagen sind schreibgeschützt." end
        profile.settings = appearance(); character.profileDirty = false
        character.profileDrafts[character.profileId] = nil
        notify(); return true
    end
    function store.deleteProfile()
        if not profiles[character.profileId] then return false, "Vorlagen können nicht gelöscht werden." end
        profiles[character.profileId] = nil
        character.profileDrafts[character.profileId] = nil
        for context, id in pairs(character.contextProfiles) do if id == character.profileId then character.contextProfiles[context] = nil end end
        character.profileId, character.profileDirty = nil, true
        notify(); return true
    end
    function store.renameProfile(name)
        local id = character.profileId
        if not profiles[id] then return false, "Zuerst ein eigenes Profil auswählen." end
        name = profileName(name)
        if not name then return false, "Ungültiger Profilname." end
        for _, entry in ipairs(store.profiles()) do
            if entry.id ~= id and entry.name:lower() == name:lower() then return false, "Dieser Name ist bereits vergeben." end
        end
        profiles[id].name = name; notify(); return true
    end
    function store.editor() return character.editor end
    function store.context()
        local function query(fn, ...)
            if type(fn) ~= "function" then return nil end
            local ok, a, b = pcall(fn, ...)
            if ok and plain(a) and plain(b) then return a, b end
        end
        local inside, kind = query(env.IsInInstance)
        if inside and kind == "raid" then return "raid" end
        if inside and kind == "party" then return "dungeon" end
        if query(env.IsInRaid) == true then return "raid" end
        return query(env.IsInGroup) == true and "group" or "solo"
    end
    function store.setContext(context, id)
        if context ~= "solo" and context ~= "group" and context ~= "dungeon" and context ~= "raid" then return false end
        character.contextProfiles[context] = id ~= "" and id or nil
        store.refreshContext(true); notify(); return true
    end
    function store.contextProfile(context) return character.contextProfiles[context] or "" end
    function store.refreshContext(force)
        local context = store.context()
        if not force and context == character.runtimeContext then return false end
        character.runtimeContext = context
        local id = current.contextProfilesEnabled and character.contextProfiles[context]
        if id and id ~= character.profileId then return store.selectProfile(id) end
        return false
    end
    function store.resetFields(surface, keys)
        local defaults = presetSurface(PRESETS[1])
        for _, key in ipairs(keys) do
            if DEFAULT_SURFACE[key] ~= nil then store.setSurface(surface, key, clone(defaults[key])) end
        end
    end
    if firstInstall then
        current.targetEnabled = true
        store.selectProfile(character.profileId or FIRST_INSTALL_PROFILE, true)
    end
    return store
end

local _, namespace = ...
if type(namespace) == "table" then namespace.SettingsStore = Store end
return Store
