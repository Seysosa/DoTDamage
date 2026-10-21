local Forecast = {}

local EPSILON = 0.000001
local MAX_TICKS = 300
local MAX_TARGETS = 256
local MAX_EFFECTS = 32
local MAX_LEARNING = 512
local MAX_VALUE = 1000000000
local INACCESSIBLE = {}
local OBSERVATION_GRACE = 0.25
local SOLO_DAMAGE_MULTIPLIER = 3
local SOLO_ROUNDING_ALLOWANCE = 1

function Forecast.create(options)
    options = options or {}
    local targets, learned, soloCandidates = {}, {}, {}
    local soloCandidateCount = 0
    local targetCount, learnedCount = 0, 0
    local engine = {}
    local applications = setmetatable({}, { __mode = "k" })
    local restricted = options.isRestricted

    local function accessible(value)
        if restricted == nil then return true end
        local ok, hidden = pcall(restricted, value)
        return ok and hidden == false
    end

    local function number(value, low, high)
        if not accessible(value) or type(value) ~= "number" then return nil end
        if value ~= value or value < low or value > high then return nil end
        return value
    end

    local function key(value)
        if not accessible(value) or type(value) ~= "string" then return nil end
        if #value < 1 or #value > 160 then return nil end
        return value
    end

    local function read(object, name)
        if not accessible(object) or type(object) ~= "table" then return INACCESSIBLE end
        local ok, value = pcall(function() return object[name] end)
        if ok and accessible(value) then return value end
        return INACCESSIBLE
    end

    local function flag(object, name, fallback)
        local value = read(object, name)
        if value == nil then return fallback end
        if type(value) == "boolean" then return value end
        return nil
    end

    local margin = number(options.safetyFraction, 0, 0.5) or 0.05
    local matchWindow = number(options.tickWindow, 0.01, 2) or 0.5
    local allowPets = options.allowPets ~= false

    local function dropTarget(targetKey)
        if targets[targetKey] then
            targets[targetKey] = nil
            targetCount = targetCount - 1
        end
    end

    local function expire(now)
        for targetKey, target in pairs(targets) do
            for effectKey, effect in pairs(target.effects) do
                if effect.expiresAt + matchWindow + OBSERVATION_GRACE <= now then
                    target.effects[effectKey] = nil
                    target.count = target.count - 1
                end
            end
            if target.count == 0 then dropTarget(targetKey) end
        end
    end

    local function tickIndex(effect, now)
        return math.max(effect.lastTick + 1,
            math.floor((now - effect.startAt - (effect.phase or 0) + EPSILON) / effect.interval) + 1, 1)
    end

    local function soloLimit(effect)
        if effect.tickDamage <= 0 then return 0 end
        return math.max(effect.tickDamage * SOLO_DAMAGE_MULTIPLIER, effect.tickDamage + SOLO_ROUNDING_ALLOWANCE, effect.soloDamageLimit or 0)
    end

    local function estimate(effect)
        local sample = learned[effect.learningKey] or learned["solo:" .. effect.learningKey]
        if sample and sample.source == "solo_heuristic" and sample.mean > soloLimit(effect) then sample = nil end
        local conservative = effect.tickDamage * (1 - margin)
        if sample then
            local spread = sample.samples > 1 and math.sqrt(sample.m2 / (sample.samples - 1)) or 0
            conservative = math.max(0, sample.mean * (1 - margin) - spread)
        end
        if effect.liveSoloEstimate and effect.soloTickDamage then
            return effect.soloTickDamage, math.min(effect.soloTickDamage * (1 - margin), conservative), "solo_current_tick"
        end
        if not sample then return effect.tickDamage, conservative, "estimated" end
        return sample.mean, conservative, sample.source == "solo_heuristic" and "solo_heuristic" or "learned"
    end

    function engine.apply(input, reversible)
        local targetKey = key(read(input, "targetKey"))
        local effectKey = key(read(input, "effectKey"))
        local learningKey = key(read(input, "learningKey"))
        local owner = key(read(input, "owner"))
        local appliedAt = number(read(input, "appliedAt"), 0, MAX_VALUE)
        local duration = number(read(input, "duration"), 0.001, 600)
        local damageDuration = number(read(input, "damageDuration") or duration, 0.001, 600)
        local interval = number(read(input, "interval"), 0.001, 600)
        local damage = number(read(input, "totalDamage"), 0, MAX_VALUE)
        local stacks = number(read(input, "stacks") or 1, 1, 100)
        local maxStacks = number(read(input, "maxStacks") or 100, 1, 100)
        local group = read(input, "exclusiveGroup")
        if group ~= nil then group = key(group); if not group then return false, "invalid_group" end end
        if not targetKey or not effectKey or not learningKey or not appliedAt
            or not duration or not damageDuration or not interval or not damage or not stacks or stacks % 1 ~= 0
            or not maxStacks or maxStacks % 1 ~= 0 then
            return false, "invalid_effect"
        end
        if owner ~= "player" and not (owner == "pet" and allowPets) then return false, "foreign_effect" end
        if read(input, "kind") ~= "aura" then return false, "not_passive_aura" end
        local count = math.floor((duration + EPSILON) / interval)
        local damageCount = math.floor((damageDuration + EPSILON) / interval)
        if count < 1 or count > MAX_TICKS or damageCount < 1 or damageCount > MAX_TICKS then return false, "invalid_tick_count" end
        local weights, prefix = {}, { [0] = 0 }
        local provided = read(input, "tickWeights")
        for index = 1, math.max(count, damageCount) do
            local weight = provided == nil and 1 or number(read(provided, index), 0, 100)
            if not weight then return false, "invalid_tick_weights" end
            weights[index], prefix[index] = weight, prefix[index - 1] + weight
        end
        if prefix[count] <= 0 or prefix[damageCount] <= 0 then return false, "empty_tick_weights" end
        local target = targets[targetKey]
        if not target then
            if targetCount >= MAX_TARGETS then return false, "target_limit" end
            target = { effects = {}, count = 0 }
        end
        local removable = 0
        if group then
            for storedKey, effect in pairs(target.effects) do
                if storedKey ~= effectKey and effect.group == group and effect.owner == owner then
                    if effect.startAt > appliedAt + EPSILON then return false, "stale_group_effect" end
                    removable = removable + 1
                end
            end
        end
        local replacing = target.effects[effectKey] ~= nil
        if target.count - removable + (replacing and 0 or 1) > MAX_EFFECTS then return false, "effect_limit" end
        if not targets[targetKey] then
            targets[targetKey] = target
            targetCount = targetCount + 1
        end
        local displaced = {}
        if reversible == true and target.effects[effectKey] then displaced[effectKey] = target.effects[effectKey] end
        if group then
            for storedKey, effect in pairs(target.effects) do
                if storedKey ~= effectKey and effect.group == group and effect.owner == owner then
                    if reversible == true then displaced[storedKey] = effect end
                    target.effects[storedKey] = nil
                    target.count = target.count - 1
                end
            end
        end
        target.effects[effectKey] = {
            key = effectKey, owner = owner, group = group, learningKey = learningKey,
            startAt = appliedAt, expiresAt = appliedAt + duration, interval = interval,
            tickDamage = damage / prefix[damageCount], stacks = math.min(stacks, maxStacks), maxStacks = maxStacks, ticks = count,
            weights = weights, prefix = prefix, lastTick = 0, observed = {},
            soloDamageLimit = number(read(input, "soloDamageLimit"), 0, MAX_VALUE),
            liveSoloEstimate = flag(input, "liveSoloEstimate", false),
        }
        if not replacing then target.count = target.count + 1 end
        local receipt
        if reversible == true then
            receipt = {}
            applications[receipt] = { current = target.effects[effectKey], displaced = displaced }
        end
        return true, nil, receipt
    end

    function engine.rollback(receipt, targetKey, now, permitted)
        if not accessible(receipt) or type(receipt) ~= "table" then return false end
        if permitted ~= nil and (not accessible(permitted) or type(permitted) ~= "table") then return false end
        targetKey, now = key(targetKey), number(now, 0, MAX_VALUE)
        local application = applications[receipt]
        local target = targetKey and targets[targetKey]
        if not application or not target or not now or target.effects[application.current.key] ~= application.current then return false end
        applications[receipt] = nil
        target.effects[application.current.key] = nil; target.count = target.count - 1
        local restored = {}
        for effectKey, effect in pairs(application.displaced) do
            local conflict = target.effects[effectKey] ~= nil
            if effect.group then
                for _, current in pairs(target.effects) do
                    if current.group == effect.group and current.owner == effect.owner then conflict = true; break end
                end
            end
            if not conflict and effect.expiresAt > now and target.count < MAX_EFFECTS and (permitted == nil or read(permitted, effectKey) == true) then
                target.effects[effectKey] = effect; target.count = target.count + 1
                restored[effectKey] = true
            end
        end
        if target.count == 0 then dropTarget(targetKey) end
        return true, restored
    end

    function engine.moveEffect(sourceKey, targetKey, effectKey)
        sourceKey, targetKey, effectKey = key(sourceKey), key(targetKey), key(effectKey)
        local source, target = sourceKey and targets[sourceKey], targetKey and targets[targetKey]
        local effect = source and effectKey and source.effects[effectKey]
        if not effect or not targetKey or sourceKey == targetKey then return false end
        if not target then
            if targetCount >= MAX_TARGETS then return false end
            target = { effects = {}, count = 0 }
        end
        local current = target.effects[effectKey]
        if current and current.startAt >= effect.startAt then return false end
        local removable = 0
        if effect.group then
            for storedKey, stored in pairs(target.effects) do
                if storedKey ~= effectKey and stored.owner == effect.owner and stored.group == effect.group then
                    if stored.startAt >= effect.startAt then return false end
                    removable = removable + 1
                end
            end
        end
        if target.count - removable + (current and 0 or 1) > MAX_EFFECTS then return false end
        if not targets[targetKey] then targets[targetKey] = target; targetCount = targetCount + 1 end
        if effect.group then
            for storedKey, stored in pairs(target.effects) do
                if storedKey ~= effectKey and stored.owner == effect.owner and stored.group == effect.group then
                    target.effects[storedKey] = nil; target.count = target.count - 1
                end
            end
        end
        if not target.effects[effectKey] then target.count = target.count + 1 end
        target.effects[effectKey] = effect
        source.effects[effectKey] = nil; source.count = source.count - 1
        if source.count == 0 then dropTarget(sourceKey) end
        return true
    end

    function engine.remove(targetKey, effectKey)
        targetKey, effectKey = key(targetKey), key(effectKey)
        local target = targetKey and targets[targetKey]
        if not target or not effectKey or not target.effects[effectKey] then return false end
        target.effects[effectKey] = nil
        target.count = target.count - 1
        if target.count == 0 then dropTarget(targetKey) end
        return true
    end

    function engine.setStacks(targetKey, effectKey, stacks)
        targetKey, effectKey = key(targetKey), key(effectKey)
        stacks = number(stacks, 1, 100)
        local target = targetKey and targets[targetKey]
        local effect = target and effectKey and target.effects[effectKey]
        if not effect or not stacks or stacks % 1 ~= 0 then return false end
        effect.stacks = math.min(stacks, effect.maxStacks)
        return true
    end

    function engine.clearGroup(targetKey, group, owner)
        targetKey, group, owner = key(targetKey), key(group), key(owner or "player")
        local target = targetKey and targets[targetKey]
        if not target or not group or not owner then return 0 end
        local removed = 0
        for effectKey, effect in pairs(target.effects) do
            if effect.group == group and effect.owner == owner then
                target.effects[effectKey] = nil
                target.count = target.count - 1
                removed = removed + 1
            end
        end
        if target.count == 0 then dropTarget(targetKey) end
        return removed
    end

    function engine.forgetTarget(targetKey)
        targetKey = key(targetKey)
        if not targetKey or not targets[targetKey] then return false end
        dropTarget(targetKey)
        return true
    end

    function engine.advance(now)
        now = number(now, 0, MAX_VALUE)
        if not now then return false, "invalid_time" end
        expire(now)
        return true
    end

    function engine.reconcile(targetKey, active, complete)
        targetKey = key(targetKey)
        if not targetKey or not accessible(active) or type(active) ~= "table" or not accessible(complete)
            or complete ~= true then return false, "incomplete_snapshot" end
        local target = targets[targetKey]
        if not target then return true end
        local removals = {}
        for effectKey in pairs(target.effects) do
            local ok, value = pcall(function() return active[effectKey] end)
            if not ok or not accessible(value) then return false, "restricted_snapshot" end
            if value ~= nil and type(value) ~= "boolean" then return false, "invalid_snapshot" end
            if value ~= true then removals[#removals + 1] = effectKey end
        end
        for _, effectKey in ipairs(removals) do engine.remove(targetKey, effectKey) end
        return true
    end

    function engine.observeTick(targetKey, effectKey, observation)
        targetKey, effectKey = key(targetKey), key(effectKey)
        local target = targetKey and targets[targetKey]
        local effect = target and effectKey and target.effects[effectKey]
        if not effect then return false, "unknown_effect" end
        if flag(observation, "ownershipConfirmed", false) ~= true then return false, "unconfirmed_owner" end
        local at = number(read(observation, "at"), 0, MAX_VALUE)
        local damage = number(read(observation, "damage"), 0, MAX_VALUE)
        local critical = flag(observation, "critical", false)
        local distorted = flag(observation, "distorted", false)
        if not at or not damage or critical == nil or distorted == nil then return false, "invalid_observation" end
        local tickZero = effect.startAt + (effect.phase or 0)
        local index = math.floor((at - tickZero) / effect.interval + 0.5)
        if index < 1 or index > effect.ticks
            or math.abs(at - tickZero - index * effect.interval) > matchWindow
            or at > effect.expiresAt + matchWindow then return false, "outside_tick_window" end
        if effect.observed[index] then return false, "duplicate_tick" end
        effect.observed[index] = true
        effect.lastTick = math.max(index, effect.lastTick)
        if critical or distorted or damage <= 0 or effect.weights[index] <= 0 then return true, "not_learned" end
        local normalized = damage / (effect.stacks * effect.weights[index])
        if normalized > MAX_VALUE then return true, "not_learned" end
        local sample = learned[effect.learningKey]
        if not sample then
            if learnedCount >= MAX_LEARNING then return true, "learning_limit" end
            sample = { samples = 0, mean = 0, m2 = 0, source = "attributed" }
            learned[effect.learningKey], learnedCount = sample, learnedCount + 1
        end
        if sample.samples >= 10000 then return true, "sample_limit" end
        sample.samples = sample.samples + 1
        local difference = normalized - sample.mean
        sample.mean = sample.mean + difference / sample.samples
        sample.m2 = sample.m2 + difference * (normalized - sample.mean)
        return true, "learned"
    end

    function engine.tickReference(targetKey, effectKey, at)
        targetKey, effectKey, at = key(targetKey), key(effectKey), number(at, 0, MAX_VALUE)
        local target = targetKey and targets[targetKey]
        local effect = target and effectKey and target.effects[effectKey]
        if not effect or not at then return nil end
        local tickZero = effect.startAt + (effect.phase or 0)
        local index = math.floor((at - tickZero) / effect.interval + 0.5)
        if index < 1 or index > effect.ticks or at > effect.expiresAt + matchWindow then return nil end
        local average, _, confidence = estimate(effect)
        return { index = index, distance = math.abs(at - tickZero - index * effect.interval),
            expected = average * effect.stacks * effect.weights[index], interval = effect.interval,
            soloMaximum = soloLimit(effect) * effect.stacks * effect.weights[index],
            confidence = confidence, used = effect.observed[index] == true, anchored = effect.phase ~= nil }
    end

    function engine.alignTick(targetKey, effectKey, at, index)
        targetKey, effectKey, at = key(targetKey), key(effectKey), number(at, 0, MAX_VALUE)
        index = number(index, 1, MAX_TICKS)
        local target = targetKey and targets[targetKey]
        local effect = target and effectKey and target.effects[effectKey]
        if not effect or not at or not index or index % 1 ~= 0 or index > effect.ticks then return false end
        if effect.phase ~= nil then return true, 0 end
        local phase = at - effect.startAt - index * effect.interval
        if math.abs(phase) > matchWindow then return false end
        effect.phase, effect.expiresAt = phase, effect.expiresAt + phase
        return true, phase
    end

    function engine.clearSoloCandidates() soloCandidates, soloCandidateCount = {}, 0 end

    function engine.learningSample(learningKey)
        learningKey = key(learningKey)
        local value = learningKey and learned["solo:" .. learningKey]
        if value then return { mean = value.mean, samples = value.samples } end
    end
    function engine.observeSoloTick(targetKey, effectKey, observation)
        targetKey, effectKey = key(targetKey), key(effectKey)
        local target = targetKey and targets[targetKey]
        local effect = target and effectKey and target.effects[effectKey]
        if not effect then return false, "unknown_effect" end
        if read(observation, "source") ~= "solo_heuristic" then return false, "invalid_learning_source" end
        local at, damage = number(read(observation, "at"), 0, MAX_VALUE), number(read(observation, "damage"), 0.001, MAX_VALUE)
        if not at or not damage or flag(observation, "critical", true) ~= false
            or flag(observation, "distorted", true) ~= false then return false, "invalid_solo_observation" end
        local reference = engine.tickReference(targetKey, effectKey, at)
        if not reference or reference.distance > matchWindow then return false, "outside_tick_window" end
        if reference.used then return false, "duplicate_tick" end
        local index = reference.index
        if effect.weights[index] <= 0 then return false, "zero_tick_weight" end
        local normalized = damage / (effect.stacks * effect.weights[index])
        if normalized > MAX_VALUE then return false, "invalid_tick_damage" end
        if normalized > soloLimit(effect) then return false, "implausible_solo_damage" end
        if effect.liveSoloEstimate then effect.soloTickDamage = normalized end
        local id = key("solo:" .. effect.learningKey)
        if not id then return false, "learning_key_limit" end
        effect.observed[index], effect.lastTick = true, math.max(index, effect.lastTick)
        local sample = learned[id]
        local previous = soloCandidates[id]
        if not sample or math.abs(normalized - sample.mean) > math.max(1, sample.mean * 0.25) then
            local coherent = previous and at > previous.at and at - previous.at <= math.max(30, effect.interval * 3)
                and (previous.effect ~= effect or index == previous.index + 1)
                and math.abs(normalized - previous.value) <= math.max(1, previous.value * 0.25)
            if not coherent then
                if not previous and soloCandidateCount >= MAX_LEARNING then return true, "candidate_limit" end
                if not previous then soloCandidateCount = soloCandidateCount + 1 end
                soloCandidates[id] = { value = normalized, at = at, index = index, effect = effect }
                return true, "solo_candidate"
            end
            if not sample and learnedCount >= MAX_LEARNING then return true, "learning_limit" end
            local mean = (previous.value + normalized) / 2
            if not sample then learnedCount = learnedCount + 1 end
            learned[id] = { samples = 2, mean = mean, m2 = (previous.value - mean)^2 + (normalized - mean)^2, source = "solo_heuristic" }
            soloCandidates[id] = nil; soloCandidateCount = soloCandidateCount - 1
            return true, "learned", 2
        end
        if previous then soloCandidates[id] = nil; soloCandidateCount = soloCandidateCount - 1 end
        if sample.samples >= 10000 then return true, "sample_limit" end
        sample.samples = sample.samples + 1
        local difference = normalized - sample.mean
        sample.mean = sample.mean + difference / sample.samples
        sample.m2 = sample.m2 + difference * (normalized - sample.mean)
        return true, "learned", 1
    end

    function engine.snapshot(targetKey, now)
        targetKey = key(targetKey)
        now = number(now, 0, MAX_VALUE)
        if not targetKey or not now then return nil, "invalid_query" end
        expire(now)
        local answer = { totalDamage = 0, conservativeDamage = 0, effects = {}, effectCount = 0 }
        local target = targets[targetKey]
        if not target then return answer end
        local order = {}
        for effectKey in pairs(target.effects) do order[#order + 1] = effectKey end
        table.sort(order)
        for _, effectKey in ipairs(order) do
            local effect = target.effects[effectKey]
            local nextIndex = tickIndex(effect, now)
            if nextIndex <= effect.ticks then
                local weight = effect.prefix[effect.ticks] - effect.prefix[nextIndex - 1]
                local average, conservative, confidence = estimate(effect)
                local remaining = average * effect.stacks * weight
                local guarded = conservative * effect.stacks * weight
                answer.effects[#answer.effects + 1] = {
                    effectKey = effectKey, learningKey = effect.learningKey, owner = effect.owner,
                    ticksRemaining = effect.ticks - nextIndex + 1, damage = remaining,
                    conservativeDamage = guarded, confidence = confidence, stacks = effect.stacks,
                    nextTickAt = effect.startAt + (effect.phase or 0) + nextIndex * effect.interval, expiresAt = effect.expiresAt,
                }
                answer.totalDamage = answer.totalDamage + remaining
                answer.conservativeDamage = answer.conservativeDamage + guarded
                answer.effectCount = answer.effectCount + 1
            end
        end
        return answer
    end

    function engine.classify(targetKey, now, health)
        local answer, reason = engine.snapshot(targetKey, now)
        if not answer then return nil, reason end
        health = number(health, 0, MAX_VALUE)
        if not health then answer.outcome = "unknown"; return answer end
        if health == 0 then answer.outcome = "dead"; return answer end
        answer.outcome = answer.conservativeDamage >= health and "lethal" or "survives"
        answer.remainingHealth = math.max(0, health - answer.totalDamage)
        return answer
    end

    function engine.exportLearning()
        local result = { schema = 1, entries = {} }
        for learningKey, sample in pairs(learned) do
            result.entries[learningKey] = { samples = sample.samples, mean = sample.mean, m2 = sample.m2, source = sample.source }
        end
        return result
    end

    function engine.importLearning(saved)
        if read(saved, "schema") ~= 1 then return false, "invalid_schema" end
        local entries = read(saved, "entries")
        if not accessible(entries) or type(entries) ~= "table" then return false, "invalid_learning" end
        local replacement, count = {}, 0
        local ok = pcall(function()
            for learningKey, sample in pairs(entries) do
                if count >= MAX_LEARNING then error("limit") end
                local id = key(learningKey)
                local samples = number(read(sample, "samples"), 1, 10000)
                local mean = number(read(sample, "mean"), 0, MAX_VALUE)
                local m2 = number(read(sample, "m2"), 0, 10000 * MAX_VALUE * MAX_VALUE)
                local source = read(sample, "source")
                if not id or not samples or samples % 1 ~= 0 or not mean or not m2 then error("invalid") end
                if source ~= nil and source ~= "attributed" and source ~= "solo_heuristic" then error("invalid_source") end
                if source == "solo_heuristic" and id:sub(1, 5) ~= "solo:" then error("invalid_source_key") end
                if source == "solo_heuristic" and samples < 2 then error("insufficient_solo_evidence") end
                if id:sub(1, 5) == "solo:" and source ~= "solo_heuristic" then error("invalid_source_key") end
                replacement[id] = { samples = samples, mean = mean, m2 = m2, source = source or "attributed" }
                count = count + 1
            end
        end)
        if not ok then return false, "invalid_learning" end
        learned, learnedCount = replacement, count
        engine.clearSoloCandidates()
        return true
    end

    function engine.resetLearning()
        learned, learnedCount = {}, 0
        engine.clearSoloCandidates()
    end

    return engine
end

local _, namespace = ...
if type(namespace) == "table" then namespace.Forecast = Forecast end
return Forecast
