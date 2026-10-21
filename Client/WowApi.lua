local WowApi = {}
local MAX_AURAS = 80
local BAD = {}

function WowApi.create(environment, options)
    local env, config = environment or _G, options or {}
    local frames, units, serial = {}, {}, 0
    local api = {}
    function api.isRestricted(value)
        if type(env.issecretvalue) ~= "function" then return false end
        local ok, hidden = pcall(env.issecretvalue, value)
        return not ok or hidden ~= false
    end
    local function field(object, name)
        if api.isRestricted(object) or type(object) ~= "table" then return BAD end
        local ok, value = pcall(function() return object[name] end)
        if ok and not api.isRestricted(value) then return value end
        return BAD
    end
    local function call(fn, ...)
        if type(fn) ~= "function" then return BAD end
        local ok, value = pcall(fn, ...)
        if ok and not api.isRestricted(value) then return value end
        return BAD
    end
    local function number(value, low, high)
        if api.isRestricted(value) or type(value) ~= "number" or value ~= value
            or value < low or value > high then return nil end
        return value
    end
    local function token(value)
        if api.isRestricted(value) or type(value) ~= "string" or #value > 24 then return nil end
        if value == "target" or value == "focus" or value == "mouseover" or value == "pettarget"
            or value:match("^nameplate%d+$") then return value end
    end
    local function text(value, maximum)
        if api.isRestricted(value) or type(value) ~= "string" or #value < 1 or #value > maximum then return nil end
        return value
    end
    local spellApi, auraApi, plateApi = env.C_Spell or {}, env.C_UnitAuras or {}, env.C_NamePlate or {}
    local interface
    if type(env.GetBuildInfo) == "function" then
        local ok, _, _, _, version = pcall(env.GetBuildInfo)
        if ok then interface = number(version, 1, 1000000) end
    end
    api.flavor = config.flavor or (interface == 16001 and "forever" or
        (interface and interface >= 11500 and interface < 11600 and "classic" or "unsupported"))

    function api.now() return number(call(env.GetTime), 0, 1000000000) end
    function api.learningContext()
        local grouped = call(env.IsInGroup)
        if grouped ~= true and grouped ~= false then return "unreadable" end
        if grouped then return "group" end
        local instanceCategory = number(env.LE_PARTY_CATEGORY_INSTANCE, 1, 10)
            or number(field(field(env.Enum, "PartyCategory"), "Instance"), 1, 10)
        if instanceCategory then
            local instance = call(env.IsInGroup, instanceCategory)
            if instance == true then return "group" end
            if instance ~= false then return "unreadable" end
        end
        if type(env.IsInRaid) == "function" then
            local raid = call(env.IsInRaid)
            if raid == true then return "group" end
            if raid ~= false then return "unreadable" end
        end
        return "solo"
    end
    function api.enemy(unit)
        unit = token(unit)
        return unit ~= nil and call(env.UnitCanAttack, "player", unit) == true
    end
    function api.identity(unit)
        unit = token(unit)
        if not unit or not api.enemy(unit) then return nil end
        local guid = text(call(env.UnitGUID, unit), 120)
        local frame = call(plateApi.GetNamePlateForUnit, unit)
        local frameOK = frame ~= BAD and (type(frame) == "table" or type(frame) == "userdata")
        if not guid and not frameOK and not unit:match("^nameplate%d+$") then
            for known, record in pairs(units) do
                if known:match("^nameplate%d+$") and record.frame and call(env.UnitIsUnit, unit, known) == true then
                    frame, frameOK = record.frame, true
                    break
                end
            end
        end
        if guid then
            if frameOK then frames[frame] = "guid:" .. guid end
            units[unit] = { key = "guid:" .. guid, frame = frameOK and frame or nil }
            return units[unit].key
        end
        if frameOK then
            if not frames[frame] then serial = serial + 1; frames[frame] = "plate:" .. serial end
            units[unit] = { key = frames[frame], frame = frame }
            return frames[frame]
        end
        if unit == "target" then
            local previous = units.target
            if not previous then
                serial = serial + 1; previous = { key = "target:" .. serial }
            end
            units.target = { key = previous.key }
            return previous.key
        end
        return nil
    end
    function api.targetChanged()
        local previous = units.target
        units.target = nil
        return previous and previous.key:match("^target:") and previous.key or nil
    end
    function api.release(unit)
        unit = token(unit)
        local record = unit and units[unit]
        if record and record.frame then frames[record.frame] = nil end
        if unit then units[unit] = nil end
    end
    function api.reset() frames, units = {}, {} end
    function api.castTarget(targetName, knownUnits, owner)
        targetName = text(targetName, 160)
        local currentUnit = owner == "pet" and "pettarget" or "target"
        if not targetName then
            local current = api.identity(currentUnit)
            return current, current and "current_target_fallback" or "unreadable_cast_target"
        end
        local candidates = { target = true, focus = true, mouseover = true, pettarget = true }
        for unit in pairs(knownUnits) do candidates[unit] = true end
        local selected
        for unit in pairs(candidates) do
            local name = text(call(env.UnitName, unit), 160)
            if name == targetName then
                local identity = api.identity(unit)
                if identity then
                    if selected and selected ~= identity then
                        if text(call(env.UnitName, currentUnit), 160) == targetName then return api.identity(currentUnit) end
                        return nil, "ambiguous_cast_target"
                    end
                    selected = identity
                end
            end
        end
        return selected, selected and nil or "unknown_cast_target"
    end
    local powerCache = { at = -1 }
    local function powers()
        local now = api.now() or 0
        if now < powerCache.at or now - powerCache.at >= 0.25 then
            powerCache.at = now
            if type(env.GetSpellBonusDamage) == "function" then
                local maximum, minimum, fingerprint, complete = 0, nil, 0, true
                for school = 2, 7 do
                    local value = number(call(env.GetSpellBonusDamage, school), 0, 1000000000)
                    if value then
                        maximum, minimum = math.max(maximum, value), math.min(minimum or value, value)
                        local encoded = tostring(value)
                        for index = 1, #encoded do
                            fingerprint = (fingerprint * 31 + encoded:byte(index)) % 2147483647
                        end
                        fingerprint = (fingerprint * 31 + school) % 2147483647
                    else complete = false end
                end
                if complete then
                    powerCache.spell, powerCache.spellAt = maximum, now
                    powerCache.schoolFingerprint = minimum ~= maximum and string.format("%08x", fingerprint) or nil
                end
            end
            if type(env.UnitAttackPower) == "function" then
                local ok, base, positive, negative = pcall(env.UnitAttackPower, "player")
                if ok then
                    base, positive, negative = number(base, 0, 1000000000), number(positive, -1000000000, 1000000000), number(negative, -1000000000, 1000000000)
                    if base and positive and negative then
                        powerCache.attack, powerCache.attackAt = math.max(0, math.min(1000000000, base + positive + negative)), now
                    end
                end
            end
        end
        local freshSpell = powerCache.spellAt and now - powerCache.spellAt <= 30
        return freshSpell and powerCache.spell or nil,
            powerCache.attackAt and now - powerCache.attackAt <= 30 and powerCache.attack or nil,
            freshSpell and powerCache.schoolFingerprint or nil
    end
    function api.spell(id, owner, combo)
        id = number(id, 1, 10000000)
        if not id or id % 1 ~= 0 or (owner ~= "player" and owner ~= "pet") then return nil end
        local class
        if type(env.UnitClass) == "function" then
            local ok, _, value = pcall(env.UnitClass, "player")
            if ok then class = text(value, 20) end
        end
        local description = text(call(spellApi.GetSpellDescription, id), 16384) or text(call(env.GetSpellDescription, id), 16384)
        local info = call(spellApi.GetSpellInfo, id)
        local name = text(field(info, "name"), 160) or text(call(spellApi.GetSpellName, id), 160) or text(call(env.GetSpellInfo, id), 160)
        local locale = text(call(env.GetLocale), 8)
        if not description then call(spellApi.RequestLoadSpellData, id) end
        if not class or not description or not locale then return nil end
        local hash = 0
        for index = 1, #description do hash = (hash * 31 + description:byte(index)) % 2147483647 end
        local spellPower, attackPower, schoolFingerprint = powers()
        local statsKey = "description:" .. hash
        if spellPower ~= nil or attackPower ~= nil then
            statsKey = statsKey .. ":power:" .. tostring(spellPower or "?") .. ":" .. tostring(attackPower or "?")
        end
        if schoolFingerprint then statsKey = statsKey .. ":s:" .. schoolFingerprint end
        return { spellId = id, class = class, owner = owner, flavor = api.flavor, locale = locale,
            name = name, description = description, spellPower = spellPower, attackPower = attackPower,
            comboPoints = combo, statsKey = statsKey }
    end
    function api.combo()
        return number(call(env.UnitPower, "player", 4), 0, 5)
    end
    local function auraOwner(raw)
        local source = field(raw, "sourceUnit")
        if source == "player" or source == "pet" then return source, "source_unit" end
        if source ~= BAD and type(source) == "string" then
            if #source <= 24 then
                for _, owner in ipairs({ "player", "pet" }) do
                    if call(env.UnitIsUnit, source, owner) == true then return owner, "unit_alias" end
                end
            end
            return nil, "foreign_source"
        end
        if field(raw, "isFromPlayerOrPlayerPet") == true then return "player_or_pet", "own_aura_flag" end
        return nil, "unreadable_source"
    end
    function api.scan(unit)
        unit = token(unit)
        local result = { items = {}, complete = false, audit = { unit = unit, seen = 0, own = 0,
            foreign = 0, unreadableSource = 0, unreadableIdentity = 0, unreadableClock = 0, samples = {}, rejectedSamples = {} } }
        local modern = type(auraApi.GetUnitAuras) == "function"
        if not unit or not api.enemy(unit) or not modern and type(auraApi.GetAuraDataByIndex) ~= "function" then
            result.audit.reason = "unavailable_unit_or_aura_api"; return result
        end
        local complete = true
        result.audit.api = modern and "GetUnitAuras" or "GetAuraDataByIndex"
        if call(env.C_Secrets and env.C_Secrets.ShouldAurasBeSecret) == true then
            result.audit.reason = "auras_private"; return result
        end
        local function query(fn, ...)
            local ok, value = pcall(fn, ...)
            if not ok then
                result.audit.reason = "aura_api_error"
                result.audit.apiError = text(value, 1024) or "unreadable_api_error"
                return BAD
            end
            if api.isRestricted(value) then
                result.audit.reason = "restricted_aura_result"
                return BAD
            end
            return value
        end
        local list
        if modern then
            list = query(auraApi.GetUnitAuras, unit, "HARMFUL", MAX_AURAS + 1)
            if list == BAD or type(list) ~= "table" then
                result.audit.reason = result.audit.reason or "invalid_aura_list"
                return result
            end
        end
        local function observe(raw)
            local audit = result.audit
            audit.seen = audit.seen + 1
            local owner, evidence = auraOwner(raw)
            if evidence == "unreadable_source" then complete = false; audit.unreadableSource = audit.unreadableSource + 1 end
            if evidence == "foreign_source" then audit.foreign = audit.foreign + 1 end
            if not owner and #audit.rejectedSamples < 4 then
                audit.rejectedSamples[#audit.rejectedSamples + 1] = {
                    spellId = number(field(raw, "spellId"), 1, 10000000), reason = evidence }
            end
            if owner then
                audit.own = audit.own + 1
                local id = number(field(raw, "spellId"), 1, 10000000)
                local instance = number(field(raw, "auraInstanceID"), 1, 1000000000)
                if not id or not instance or id % 1 ~= 0 or instance % 1 ~= 0 then
                    complete = false; audit.unreadableIdentity = audit.unreadableIdentity + 1
                else
                    local item = { spellId = id, instanceId = instance, owner = owner, ownershipEvidence = evidence,
                        duration = number(field(raw, "duration"), 0.001, 600),
                        expiration = number(field(raw, "expirationTime"), 0.001, 1000000000),
                        stacks = number(field(raw, "applications"), 0, 100) }
                    result.items[#result.items + 1] = item
                    if not item.duration or not item.expiration then audit.unreadableClock = audit.unreadableClock + 1 end
                    if #audit.samples < 8 then
                        audit.samples[#audit.samples + 1] = { spellId = id, instanceId = instance, owner = owner,
                            evidence = evidence, duration = item.duration, expiration = item.expiration }
                    end
                end
            end
        end
        for index = 1, MAX_AURAS + 1 do
            local raw
            if modern then raw = field(list, index)
            else raw = query(auraApi.GetAuraDataByIndex, unit, index, "HARMFUL") end
            if raw == nil then result.complete = complete; break end
            if index > MAX_AURAS then result.audit.reason = "aura_limit"; break end
            if raw == BAD or type(raw) ~= "table" then
                complete = false
                result.audit.unreadableAuras = (result.audit.unreadableAuras or 0) + 1
                if not modern and result.audit.reason == "aura_api_error" then break end
            else observe(raw) end
        end
        result.audit.complete = result.complete
        return result
    end
    function api.removed(update)
        local list = field(update, "removedAuraInstanceIDs")
        local result = {}
        if type(list) ~= "table" or list == BAD then return result end
        for index = 1, MAX_AURAS do
            local value = field(list, index)
            if value == nil then break end
            local id = number(value, 1, 1000000000)
            if id and id % 1 == 0 then result[#result + 1] = id end
        end
        return result
    end
    function api.periodic()
        if api.flavor ~= "classic" or type(env.CombatLogGetCurrentEventInfo) ~= "function" then return nil end
        local values = { pcall(env.CombatLogGetCurrentEventInfo) }
        if values[1] ~= true then return nil end
        for index = 2, 23 do if api.isRestricted(values[index]) then return nil end end
        if values[3] ~= "SPELL_PERIODIC_DAMAGE" then return nil end
        local source, destination = text(values[5], 120), text(values[9], 120)
        local owner
        for _, unit in ipairs({ "player", "pet" }) do
            local guid = text(call(env.UnitGUID, unit), 120)
            if guid and source == guid then owner = unit end
        end
        local id, amount = number(values[13], 1, 10000000), number(values[16], 0, 1000000000)
        if not owner or not destination or not id or not amount then return nil end
        local critical = values[22]
        if critical ~= nil and type(critical) ~= "boolean" then return nil end
        local distorted = false
        for _, index in ipairs({ 19, 20, 21 }) do
            local value = number(values[index] or 0, 0, 1000000000)
            if not value then return nil end
            if value > 0 then distorted = true end
        end
        return { targetKey = "guid:" .. destination, spellId = id, owner = owner, at = api.now(),
            damage = amount, critical = critical or false, distorted = distorted, ownershipConfirmed = true }
    end
    function api.frame() return call(env.CreateFrame, "Frame") end
    return api
end

local _, namespace = ...
if type(namespace) == "table" then namespace.WowApi = WowApi end
return WowApi
