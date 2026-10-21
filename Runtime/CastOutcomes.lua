local CastOutcomes = {}
local WINDOW, LOOKBACK, ALIAS_WINDOW = 0.4, 0.25, 0.01
local MAX_CASTS, MAX_RECENT = 64, 128
local HISTORY = 15
local TICK_WINDOW = 0.5
local AVOIDS = { MISS = true, RESIST = true, IMMUNE = true, EVADE = true, REFLECT = true, DODGE = true, PARRY = true, DEFLECT = true }
local MELEE = { DODGE = true, PARRY = true, DEFLECT = true }

function CastOutcomes.create(api, isCurrent, rollback, couldBeTick)
    local outcomes, casts, recent = {}, {}, {}
    local context, cursor, allowGroups = nil, 0, false
    local stats = { rolledBack = 0, confirmed = 0, ambiguous = 0, ignored = 0, duplicates = 0 }
    local function readable(value) return not api.isRestricted(value) end
    local function number(value, low, high)
        return readable(value) and type(value) == "number" and value == value and value >= low and value <= high
    end
    function outcomes.reset() casts, recent, cursor = {}, {}, 0 end
    function outcomes.configure(options) allowGroups = options.allowGroups == true end
    function outcomes.advance(now)
        local nextContext = type(api.learningContext) == "function" and api.learningContext() or "unreadable"
        if nextContext ~= "solo" and not (allowGroups and nextContext == "group") then nextContext = "unavailable" end
        if nextContext ~= context then outcomes.reset(); context = nextContext end
        for record, cast in pairs(casts) do
            if now - cast.at > WINDOW then casts[record] = nil end
        end
        for index, event in pairs(recent) do if now - event.at > HISTORY then recent[index] = nil end end
        return api.flavor == "forever" and (context == "solo" or allowGroups and context == "group")
    end
    local function matches(cast, event)
        local compatible = cast.targetKey == event.targetKey and cast.record.descriptor.school == event.school
            and not (MELEE[event.action] and event.school ~= 1)
            and event.at >= cast.sentAt and event.at >= cast.at - LOOKBACK and event.at <= cast.at + WINDOW
        if not compatible or event.action ~= "WOUND" then return compatible end
        if couldBeTick and couldBeTick(event.targetKey, event.school, event.at) then return false end
        for _, previous in pairs(cast.previous) do
            local detail, anchor = previous.descriptor, previous.learningAnchor
            local zero = anchor and anchor.at - anchor.index * detail.interval or previous.start
            local index = math.floor((event.at - zero) / detail.interval + 0.5)
            if detail.school == event.school and index >= 1 and index <= math.floor(detail.duration / detail.interval + 0.000001)
                and math.abs(event.at - zero - index * detail.interval) <= TICK_WINDOW then return false end
        end
        return true
    end
    local function resolve(cast, event, now)
        event.consumed = true
        if not isCurrent(cast.targetKey, cast.effectKey, cast.record) then casts[cast.record] = nil; return false end
        if event.action == "WOUND" then
            if cast.record.applicationSource ~= "cast_miss_checked" then casts[cast.record] = nil end
            stats.confirmed = stats.confirmed + 1; return true
        end
        casts[cast.record] = nil
        if rollback(cast, now) then stats.rolledBack = stats.rolledBack + 1; return true end
        return false
    end
    local function markDoubtful(candidates, event)
        if event.action == "WOUND" then return end
        for _, cast in ipairs(candidates) do
            if cast.record.applicationSource == "cast_miss_checked" then cast.record.doubtful = true end
        end
    end
    function outcomes.remember(cast, now)
        if not outcomes.advance(now) then return end
        local count = 0
        for _ in pairs(casts) do count = count + 1 end
        if count >= MAX_CASTS then stats.ignored = stats.ignored + 1; return end
        casts[cast.record] = cast
        local latest
        for _, event in pairs(recent) do
            if not event.consumed and matches(cast, event) and (not latest or event.at > latest.at or event.at == latest.at and event.serial > latest.serial) then
                latest = event
            end
        end
        if latest then
            local candidates = {}
            for _, candidate in pairs(casts) do if matches(candidate, latest) then candidates[#candidates + 1] = candidate end end
            if #candidates == 1 then resolve(cast, latest, now)
            else
                markDoubtful(candidates, latest)
                for _, candidate in ipairs(candidates) do casts[candidate.record] = nil end
                latest.consumed = true; stats.ambiguous = stats.ambiguous + 1
            end
        end
        if now - cast.at > WINDOW then casts[cast.record] = nil end
    end
    function outcomes.observe(targetKey, unit, action, amount, school, now)
        if not outcomes.advance(now) then return false end
        if not readable(action) or type(action) ~= "string" or not (AVOIDS[action] or action == "WOUND") then return false end
        if not number(school, 1, 127) or school % 1 ~= 0
            or action == "WOUND" and not number(amount, 0.001, 1000000000) then
            stats.ignored = stats.ignored + 1; return false
        end
        for _, event in pairs(recent) do
            if event.targetKey == targetKey and event.unit ~= unit and now - event.at <= ALIAS_WINDOW
                and event.action == action and event.school == school then stats.duplicates = stats.duplicates + 1; return false end
        end
        cursor = cursor + 1
        local event = { targetKey = targetKey, unit = unit, action = action, school = school, at = now, serial = cursor }
        recent[(cursor - 1) % MAX_RECENT + 1] = event
        local candidates = {}
        for _, cast in pairs(casts) do if matches(cast, event) then candidates[#candidates + 1] = cast end end
        if #candidates > 1 then
            markDoubtful(candidates, event)
            for _, cast in ipairs(candidates) do casts[cast.record] = nil end
            event.consumed = true; stats.ambiguous = stats.ambiguous + 1
            return false
        end
        if #candidates == 1 then return resolve(candidates[1], event, now) end
        return false
    end
    function outcomes.confirm(record)
        if casts[record] then casts[record] = nil; stats.confirmed = stats.confirmed + 1 end
    end
    function outcomes.pending(record) return casts[record] ~= nil end
    function outcomes.windowElapsed(record, now)
        return number(now, 0, 1000000000) and now > record.start + WINDOW
    end
    function outcomes.previousAura(targetKey, effectKey, instance, start)
        for record, cast in pairs(casts) do
            local previous = cast.previous[effectKey]
            if cast.targetKey == targetKey and previous and isCurrent(targetKey, cast.effectKey, record)
                and (not start or start < record.start)
                and (instance and instance == previous.instance or start and start == previous.start) then return true end
        end
        return false
    end
    function outcomes.removed(targetKey, instance)
        for _, cast in pairs(casts) do
            if cast.targetKey == targetKey then
                for key, previous in pairs(cast.previous) do if previous.instance == instance then cast.previous[key] = nil end end
            end
        end
    end
    function outcomes.move(source, destination)
        for _, cast in pairs(casts) do if cast.targetKey == source then cast.targetKey = destination end end
        for _, event in pairs(recent) do if event.targetKey == source then event.targetKey = destination end end
    end
    function outcomes.forget(targetKey, owner)
        for record, cast in pairs(casts) do
            if (not targetKey or cast.targetKey == targetKey) and (not owner or record.descriptor.owner == owner) then casts[record] = nil end
        end
        for index, event in pairs(recent) do if not targetKey or event.targetKey == targetKey then recent[index] = nil end end
    end
    function outcomes.status()
        local result = { available = api.flavor == "forever" and (context == "solo" or allowGroups and context == "group"), pending = 0 }
        for key, value in pairs(stats) do result[key] = value end
        for _ in pairs(casts) do result.pending = result.pending + 1 end
        return result
    end
    return outcomes
end

local _, namespace = ...
if type(namespace) == "table" then namespace.CastOutcomes = CastOutcomes end
return CastOutcomes
