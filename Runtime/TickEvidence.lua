local Evidence = {}
local WINDOW, TRAVEL = 0.45, 1.5
local PROJECTILES = { ["mage/fireball"] = true, ["mage/frostfire"] = true,
    ["mage/pyroblast"] = true, ["hunter/sting"] = true }
local ESTIMATED_MODES = { fixed = true, ramp = true, finisher = true, delayed = true }
local AVOIDS = { MISS = true, RESIST = true, IMMUNE = true, EVADE = true, REFLECT = true, DODGE = true, PARRY = true, DEFLECT = true }
local LOOKBACK, HISTORY, MAX_RECENT = 0.25, 15, 128

function Evidence.create(api, sample)
    local evidence = {}
    local recent, cursor = {}, 0
    local stats = { inferred = 0, ambiguous = 0, rejected = 0, waitingBonus = 0, avoided = 0 }
    local function number(value)
        return not api.isRestricted(value) and type(value) == "number" and value == value
            and value >= 0 and value <= 1000000000
    end
    function evidence.canStartOnCast(cast)
        local d = cast.descriptor
        local context = type(api.learningContext) == "function" and api.learningContext()
        return api.flavor == "forever" and (context == "solo" or context == "group")
            and context == cast.contextAtSuccess and cast.successAt and cast.privateAuras and d
            and d.owner == "player" and (d.maxStacks or 1) == 1 and not PROJECTILES[d.familyKey]
            and ESTIMATED_MODES[d.mode] == true
    end
    function evidence.reset() recent, cursor = {}, 0 end
    function evidence.move(source, destination)
        for _, event in pairs(recent) do if event.targetKey == source then event.targetKey = destination end end
    end
    function evidence.forget(targetKey)
        for index, event in pairs(recent) do if event.targetKey == targetKey then recent[index] = nil end end
    end
    function evidence.avoided(cast)
        local d = cast.descriptor
        if not cast.successAt or not cast.privateAuras or not d or not PROJECTILES[d.familyKey] then return false end
        for _, event in pairs(recent) do
            if event.targetKey == cast.targetKey and event.school == d.school and event.at >= cast.sentAt
                and event.at >= cast.successAt - LOOKBACK and event.at <= cast.successAt + TRAVEL + WINDOW then return true end
        end
        return false
    end
    function evidence.match(pending, targetKey, action, flag, amount, school, now, existingTick)
        if api.flavor ~= "forever" or type(api.learningContext) ~= "function" or api.learningContext() ~= "solo" then return nil end
        if api.isRestricted(action) or type(action) ~= "string" or not number(school) or not number(now) then return nil end
        for index, event in pairs(recent) do if now - event.at > HISTORY then recent[index] = nil end end
        if AVOIDS[action] then
            cursor = cursor % MAX_RECENT + 1
            recent[cursor] = { targetKey = targetKey, school = school, at = now }
        end
        local casts = {}
        for id, cast in pairs(pending) do
            local d = cast.descriptor
            if cast.targetKey == targetKey and cast.successAt and cast.soloAtSuccess and cast.privateAuras and d
                and d.owner == "player" and d.school == school and (d.maxStacks or 1) == 1
                and ESTIMATED_MODES[d.mode] == true then
                if evidence.avoided(cast) then pending[id] = nil; stats.avoided = stats.avoided + 1
                else casts[#casts + 1] = { id = id, cast = cast } end
            end
        end
        if #casts == 0 then return nil end
        if AVOIDS[action] then
            for _, entry in ipairs(casts) do
                local cast = entry.cast
                if now >= cast.successAt and now - cast.successAt <= TRAVEL + WINDOW then
                    pending[entry.id] = nil; stats.avoided = stats.avoided + 1
                end
            end
            return nil
        end
        if action ~= "WOUND" or not number(amount) or amount <= 0 then return nil end
        local flagsReadable = not api.isRestricted(flag)
        local critical = flagsReadable and flag == "CRITICAL"
        local normal = flagsReadable and (flag == nil or flag == "" or flag == "NONE" or flag == "NORMAL")
        if flagsReadable and not normal and not critical then return nil end
        if existingTick(school, amount, now) then return nil end
        local matches = {}
        for _, entry in ipairs(casts) do
            local cast, d = entry.cast, entry.cast.descriptor
            local ticks = math.floor((d.duration + 0.000001) / d.interval)
            local elapsed, index = now - cast.successAt, nil
            local travel = PROJECTILES[d.familyKey] and TRAVEL or 0
            for i = 1, ticks >= 2 and ticks or 0 do
                local delay = elapsed - i * d.interval
                if delay >= -WINDOW and delay <= travel + WINDOW then index = i end
            end
            if index then
                local sum = 0
                for i = 1, ticks do sum = sum + (d.tickWeights and d.tickWeights[i] or 1) end
                local weight = d.tickWeights and d.tickWeights[index] or 1
                local base = d.totalDamage / sum
                local normalized = amount / weight
                local basic = math.max(base * 3, base + 1)
                local limit = math.max(basic, d.powerBudget or 0)
                local factor = normal and 1 or 2
                if normalized <= limit * factor and normalized >= math.max(0.001, base * 0.3 - 1) then
                    local previous, learned = cast.tickEvidence, sample("private:" .. d.learningKey)
                    local coherent = normal and previous and index == previous.index + 1
                        and math.abs(now - previous.at - d.interval) <= 0.25
                        and math.abs(normalized - previous.normalized) <= math.max(1, previous.normalized * 0.25)
                    local known = learned and learned.samples >= 2
                        and flagsReadable and math.abs(normalized / factor - learned.mean) <= math.max(1, learned.mean * 0.25)
                    local high = normalized > basic * factor
                    entry.index, entry.start = index, now - index * d.interval
                    entry.previous = coherent and previous or nil
                    entry.eligible = not high or coherent or known
                    entry.normalized, entry.critical = normalized, not normal
                    local key = d.effectKey
                    if not matches[key] or cast.successAt > matches[key].cast.successAt then matches[key] = entry end
                else stats.rejected = stats.rejected + 1 end
            end
        end
        local found, count
        count = 0
        for _, entry in pairs(matches) do found = entry; count = count + 1 end
        if count > 1 then stats.ambiguous = stats.ambiguous + 1; return nil end
        if not found then return nil end
        if not found.critical then
            found.cast.tickEvidence = { at = now, index = found.index, amount = amount, normalized = found.normalized }
        end
        if not found.eligible then stats.waitingBonus = stats.waitingBonus + 1; return nil end
        stats.inferred = stats.inferred + 1
        return found
    end
    function evidence.status()
        local result = {}; for key, value in pairs(stats) do result[key] = value end; return result
    end
    return evidence
end

local _, namespace = ...
if type(namespace) == "table" then namespace.TickEvidence = Evidence end
return Evidence
