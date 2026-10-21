local TickLearning = {}
local INITIAL_WINDOW, ANCHORED_WINDOW, SETTLE_TIME = 0.45, 0.25, 0.20
local MAX_RECENT, ALIAS_WINDOW = 128, 0.01

function TickLearning.create(engine, api, isCurrent)
    local learning = {}
    local pending, blocked, recent = {}, setmetatable({}, { __mode = "k" }), {}
    local cursor, context = 0, "unreadable"
    local stats = { matched = 0, learned = 0, duplicates = 0, ambiguous = 0, swaps = 0, rejected = 0 }
    local function readable(value) return not api.isRestricted(value) end
    local function number(value, low, high)
        return readable(value) and type(value) == "number" and value == value and value >= low and value <= high
    end
    function learning.reset(clearCount)
        pending, blocked, recent, cursor = {}, setmetatable({}, { __mode = "k" }), {}, 0
        engine.clearSoloCandidates()
        if clearCount then stats.learned = 0 end
    end
    function learning.synchronize()
        local nextContext = type(api.learningContext) == "function" and api.learningContext() or "unreadable"
        if nextContext ~= "solo" and nextContext ~= "group" then nextContext = "unreadable" end
        if nextContext ~= context then learning.reset(); context = nextContext end
        return context
    end
    function learning.flush(now)
        if next(pending) == nil then return end
        if learning.synchronize() ~= "solo" or not number(now, 0, 1000000000) then return end
        for record, event in pairs(pending) do
            if now >= event.at + SETTLE_TIME then
                pending[record] = nil
                if isCurrent(event.targetKey, event.effectKey, record) and record.stacks == event.stacks then
                    local aligned, shift = true, 0
                    if record.applicationSource ~= "own_aura" then aligned, shift = engine.alignTick(event.targetKey, event.effectKey, event.at, event.index) end
                    if aligned then
                        record.expires = record.expires + shift
                        if record.applicationSource ~= "own_aura" and not record.learningAnchor then record.learningAnchor = { at = event.at, index = event.index } end
                        local ok, reason, count = engine.observeSoloTick(event.targetKey, event.effectKey,
                            { at = event.at, damage = event.amount, critical = false, distorted = false, source = "solo_heuristic" })
                        stats.lastReason = reason
                        if ok and reason == "learned" then stats.learned = stats.learned + count
                        elseif not ok then stats.rejected = stats.rejected + 1; stats.lastReason = reason end
                    end
                end
            end
        end
    end
    function learning.observe(targetKey, records, unit, action, flag, amount, school, now)
        learning.synchronize()
        learning.flush(now)
        if not readable(action) then stats.rejected = stats.rejected + 1; stats.lastReason = "unreadable_action"; return false end
        if action ~= "WOUND" then return false end
        if not number(amount, 0.001, 1000000000) or not number(school, 1, 127) or school % 1 ~= 0 or not number(now, 0, 1000000000) then
            stats.rejected = stats.rejected + 1; stats.lastReason = "unreadable_or_invalid_hit"; return false
        end
        local flagsReadable = readable(flag) and (flag == nil or type(flag) == "string" and #flag <= 32)
        local critical = flagsReadable and flag == "CRITICAL"
        for _, event in pairs(recent) do
            if event.targetKey == targetKey and event.unit ~= unit and math.abs(now - event.at) <= ALIAS_WINDOW
                and event.amount == amount and event.school == school and flagsReadable and event.flag == flag then
                stats.duplicates = stats.duplicates + 1; return false
            end
        end
        if flagsReadable then
            cursor = cursor % MAX_RECENT + 1
            recent[cursor] = { targetKey = targetKey, unit = unit, at = now, amount = amount, school = school, flag = flag }
        end
        local candidates = {}
        for key, record in pairs(records) do
            if record.descriptor.school == school then
                local reference = engine.tickReference(targetKey, key, now)
                if reference and not reference.used and reference.distance <= (reference.anchored and ANCHORED_WINDOW or INITIAL_WINDOW) then
                    candidates[#candidates + 1] = { key = key, record = record, reference = reference }
                end
            end
        end
        if #candidates > 1 then
            local fits, unknown = {}, false
            for _, candidate in ipairs(candidates) do
                local reference = candidate.reference
                if reference.confidence == "estimated" then unknown = true end
                local tolerance = critical and 2.3 or 1.3
                local low = critical and 1.3 or 0.7
                if amount >= reference.expected * low - 1 and amount <= reference.expected * tolerance + 1 then fits[#fits + 1] = candidate end
            end
            if not unknown and #fits == 1 then candidates = fits end
        end
        if #candidates ~= 1 then
            if #candidates > 1 then
                stats.ambiguous = stats.ambiguous + 1
                stats.lastReason = "ambiguous_tick"
                for _, candidate in ipairs(candidates) do
                    pending[candidate.record] = nil; blocked[candidate.record] = candidate.reference.index
                end
            end
            return false
        end
        local candidate = candidates[1]
        local record, reference = candidate.record, candidate.reference
        if amount > reference.soloMaximum then
            stats.rejected = stats.rejected + 1; stats.lastReason = "implausible_solo_damage"
            return false
        end
        if blocked[record] == reference.index then return false end
        record.tickSeen = true; stats.matched = stats.matched + 1
        if not flagsReadable or critical or flag ~= nil and flag ~= "" and flag ~= "NONE" and flag ~= "NORMAL" then
            pending[record] = nil; blocked[record] = reference.index
            stats.lastReason = not flagsReadable and "unreadable_hit_flags" or critical and "critical_not_learned" or "modified_hit_not_learned"
            return true
        end
        if context ~= "solo" then return true end
        local event = { targetKey = targetKey, effectKey = candidate.key, at = now, index = reference.index,
            amount = amount, error = math.abs(amount - reference.expected), stacks = record.stacks }
        local previous = pending[record]
        if previous and previous.index == event.index then
            if math.abs(event.error - previous.error) <= 1 then
                pending[record] = nil; blocked[record] = event.index; stats.ambiguous = stats.ambiguous + 1
            elseif event.error < previous.error then pending[record] = event; stats.swaps = stats.swaps + 1 end
        else pending[record] = event end
        return true
    end
    function learning.status()
        learning.synchronize()
        local result = { context = context, allowed = context == "solo", source = "solo_heuristic", pending = 0 }
        for key, value in pairs(stats) do result[key] = value end
        for _ in pairs(pending) do result.pending = result.pending + 1 end
        return result
    end
    return learning
end

local _, namespace = ...
if type(namespace) == "table" then namespace.TickLearning = TickLearning end
return TickLearning
