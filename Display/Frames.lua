local Frames = {}

function Frames.create(env, restricted)
    local lookup = {}
    local settings = {}
    local function field(object, name)
        if restricted(object) or object == nil then return nil end
        local ok, value = pcall(function() return object[name] end)
        if ok and not restricted(value) then return value end
    end
    local function invoke(object, method, ...)
        local fn = field(object, method)
        if type(fn) ~= "function" then return nil end
        local ok, value = pcall(fn, object, ...)
        if ok and not restricted(value) then return value end
    end
    local function usable(bar)
        if not bar or restricted(bar) or invoke(bar, "IsForbidden") ~= false then return false end
        local alpha = invoke(bar, "GetAlpha")
        local effective = invoke(bar, "GetEffectiveAlpha")
        return invoke(bar, "GetObjectType") == "StatusBar" and invoke(bar, "IsVisible") ~= false
            and alpha ~= 0 and effective ~= 0 and invoke(bar, "GetOrientation") ~= "VERTICAL"
            and invoke(bar, "GetReverseFill") ~= true
    end
    local function descriptor(bar, root, anchor, source)
        if not usable(bar) then return nil end
        local mask, verticalInset
        if source == "Blizzard target" then
            local texture = invoke(bar, "GetStatusBarTexture")
            mask = invoke(texture, "GetMaskTexture", 1)
            local height = invoke(bar, "GetHeight")
            if type(height) == "number" and height > 0 and height < 100 then
                verticalInset = height / 6
            end
        end
        return { bar = bar, root = root or bar, anchor = anchor or bar, source = source,
            mask = mask, verticalInset = verticalInset,
            fillInset = source == "Ellesmere nameplate" and 1 or nil }
    end
    function lookup.resolve(path)
        if restricted(path) or type(path) ~= "string" or #path > 256 then return nil end
        path = path:match("^%s*(.-)%s*$"):gsub("^_G%.", "")
        if path == "" or path:find("[^%w_%.]") or path:find("%.%.") then return nil end
        local object = env
        for part in path:gmatch("[^%.]+") do
            if not part:match("^[%a_][%w_]*$") and not part:match("^%d+$") then return nil end
            object = field(object, tonumber(part) or part)
            if object == nil then return nil end
        end
        if invoke(object, "IsForbidden") ~= false then return nil end
        return object
    end
    function lookup.path(object)
        if not object or restricted(object) then return nil end
        local original = object
        local parts, seen = {}, {}
        for _ = 1, 8 do
            if seen[object] then break end; seen[object] = true
            local name = invoke(object, "GetName")
            if not name then
                for _, alias in ipairs({ "EllesmereUIUnitFrames_Target", "TargetFrame", "TargetFrameHealthBar", "TargetFramePortrait", "UIParent" }) do
                    if field(env, alias) == object then name = alias; break end
                end
            end
            if type(name) == "string" and name:match("^[%a_][%w_]*$") and not name:match("^DoTDamage") then
                local path = name
                for index = #parts, 1, -1 do path = path .. "." .. parts[index] end
                if lookup.resolve(path) == original then return path end
            end
            local parent = invoke(object, "GetParent")
            if not parent or restricted(parent) or type(parent) ~= "table" then break end
            local key, count
            count = 0
            for candidate, value in pairs(parent) do
                count = count + 1; if count > 128 then break end
                if not restricted(candidate) and not restricted(value) and value == object
                    and type(candidate) == "string" and candidate:match("^[%a_][%w_]*$") then key = candidate; break end
            end
            if not key then break end
            parts[#parts + 1] = key; object = parent
        end
        local queue, visited = {}, {}
        for _, name in ipairs({ "EllesmereUIUnitFrames_Target", "TargetFrame", "TargetFrameHealthBar", "TargetFramePortrait" }) do
            local root = field(env, name)
            if root then queue[#queue + 1] = { object = root, path = name, depth = 0 } end
        end
        for ancestor in pairs(seen) do
            local name = invoke(ancestor, "GetName")
            if type(name) == "string" and name ~= "UIParent" and lookup.resolve(name) == ancestor then
                queue[#queue + 1] = { object = ancestor, path = name, depth = 0 }
            end
        end
        local cursor = 1
        while cursor <= #queue and cursor <= 128 do
            local entry = queue[cursor]; cursor = cursor + 1
            if entry.object == original then return entry.path end
            if not visited[entry.object] and entry.depth < 4 and type(entry.object) == "table"
                and invoke(entry.object, "IsForbidden") == false then
                visited[entry.object] = true
                local keys, count = {}, 0
                for key, child in pairs(entry.object) do
                    count = count + 1; if count > 128 then break end
                    if not restricted(key) and type(key) == "string" and key:match("^[%a_][%w_]*$")
                        and not restricted(child) and invoke(child, "IsForbidden") == false then keys[#keys + 1] = key end
                end
                table.sort(keys)
                for _, key in ipairs(keys) do
                    if #queue >= 128 then break end
                    local path = entry.path .. "." .. key
                    if #path <= 256 then queue[#queue + 1] = { object = field(entry.object, key), path = path, depth = entry.depth + 1 } end
                end
            end
        end
    end
    function lookup.configure(configuration) settings = configuration.target or {} end
    local function automaticTarget()
        local external = env.EllesmereUIUnitFrames_Target
        if external then
            local portrait = field(external, "Portrait")
            local anchor = field(portrait, "backdrop") or portrait
            if invoke(anchor, "IsVisible") == false then anchor = nil end
            local attached = descriptor(field(external, "Health"), external, anchor, "Ellesmere target")
            if attached then return attached end
        end
        local root = env.TargetFrame
        local content = field(field(root, "TargetFrameContent"), "TargetFrameContentMain")
        return descriptor(field(field(content, "HealthBarsContainer"), "HealthBar") or field(content, "HealthBar") or env.TargetFrameHealthBar or field(root, "healthbar"),
            root, field(field(root, "TargetFrameContainer"), "Portrait") or env.TargetFramePortrait or field(root, "portrait"), "Blizzard target")
    end
    function lookup.target()
        local automatic = automaticTarget()
        local custom = lookup.resolve(settings.customHealthBar)
        local customUsable = usable(custom)
        local bar = customUsable and custom or automatic and automatic.bar
        local anchor = lookup.resolve(settings.customIconAnchor)
        if not bar then return nil end
        if automatic and not customUsable and not anchor then return automatic end
        local root = automatic and bar == automatic.bar and automatic.root or invoke(bar, "GetParent") or bar
        local result = descriptor(bar, root, anchor or automatic and automatic.anchor or bar,
            customUsable and settings.customHealthBar or automatic and automatic.source or "Target")
        if result and automatic and bar == automatic.bar then
            result.mask, result.verticalInset = automatic.mask, automatic.verticalInset
        end
        return result
    end
    function lookup.status()
        local binding = lookup.target()
        local bar = binding and binding.source or "Nicht gefunden"
        if settings.customHealthBar and settings.customHealthBar ~= "" and not usable(lookup.resolve(settings.customHealthBar)) then
            bar = "Ungültiger Pfad; " .. bar
        end
        local anchor = lookup.resolve(settings.customIconAnchor)
        local automaticPath = binding and lookup.path(binding.anchor)
        return { bar = bar, anchor = anchor and settings.customIconAnchor or automaticPath and ("Auto: " .. automaticPath)
            or binding and "Automatischer Anker" or "Nicht gefunden" }
    end
    function lookup.nameplate(unit)
        if restricted(unit) or type(unit) ~= "string" or not unit:match("^nameplate%d+$") then return nil end
        local api = env.C_NamePlate
        if not api or type(api.GetNamePlateForUnit) ~= "function" then return nil end
        local ok, root = pcall(api.GetNamePlateForUnit, unit)
        if not ok or restricted(root) or not root or invoke(root, "IsForbidden") ~= false then return nil end
        local custom = field(field(env.EllesmereNameplates_NS, "plates"), unit)
        if custom then
            if field(custom, "nameplate") ~= root or field(custom, "unit") ~= unit then return nil, "ellesmere_plate_recycled" end
            return descriptor(field(custom, "health"), custom, nil, "Ellesmere nameplate"), "ellesmere_health_unavailable"
        end
        local standard = field(root, "UnitFrame")
        for _, bar in ipairs({ field(standard, "healthBar") or false,
            field(field(standard, "HealthBarsContainer"), "healthBar") or false,
            field(standard, "HealthBar") or false, field(standard, "Health") or false }) do
            if usable(bar) then return descriptor(bar, root, bar, "Blizzard nameplate") end
        end
        local candidates, seen, visited = {}, {}, 0
        local function visit(frame, depth)
            if not frame or restricted(frame) or seen[frame] or depth > 3 or visited >= 64 then return end
            seen[frame], visited = true, visited + 1
            if invoke(frame, "IsForbidden") ~= false then return end
            local readableAssignment, assigned = pcall(function()
                local first, second = frame.unit, frame.displayedUnit
                if restricted(first) or restricted(second) then return false end
                return first or second
            end)
            if not readableAssignment or assigned == false then return end
            if assigned and assigned ~= unit then return end
            for _, name in ipairs({ "health", "healthBar", "Health", "HealthBar" }) do
                local bar = field(frame, name)
                if usable(bar) then candidates[#candidates + 1] = descriptor(bar, frame, bar, name == "health" and "Custom nameplate" or "Nameplate health") end
            end
            visit(field(frame, "UnitFrame"), depth + 1)
            local getChildren = field(frame, "GetChildren")
            if type(getChildren) == "function" then
                local children = { pcall(getChildren, frame) }
                if children[1] then for index = 2, math.min(#children, 66) do visit(children[index], depth + 1) end end
            end
        end
        visit(root, 0)
        local chosen
        for _, candidate in ipairs(candidates) do
            if chosen and chosen.bar ~= candidate.bar then return nil, "ambiguous_health_bars" end
            chosen = candidate
        end
        return chosen
    end
    function lookup.units()
        local result, found, visited, seen = {}, {}, 0, {}
        local api = env.C_NamePlate
        if not api or type(api.GetNamePlates) ~= "function" then return result end
        local ok, plates = pcall(api.GetNamePlates)
        if not ok or restricted(plates) or type(plates) ~= "table" then return result end
        local function collect(frame, depth)
            if not frame or restricted(frame) or depth > 3 or visited >= 256 or seen[frame] or invoke(frame, "IsForbidden") ~= false then return end
            seen[frame], visited = true, visited + 1
            local unit = field(frame, "namePlateUnitToken") or field(frame, "unit") or field(frame, "displayedUnit")
            if type(unit) == "string" and unit:match("^nameplate%d+$") and not found[unit] then
                found[unit] = true; result[#result + 1] = unit
            end
            if unit then return end
            collect(field(frame, "UnitFrame"), depth + 1)
            local getChildren = field(frame, "GetChildren")
            if type(getChildren) == "function" then
                local children = { pcall(getChildren, frame) }
                if children[1] then for index = 2, math.min(#children, 66) do collect(children[index], depth + 1) end end
            end
        end
        for index = 1, math.min(#plates, 64) do collect(plates[index], 0) end
        return result
    end
    return lookup
end

local _, namespace = ...
if type(namespace) == "table" then namespace.Frames = Frames end
return Frames
