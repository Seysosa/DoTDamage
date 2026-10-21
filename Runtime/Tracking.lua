local Tracking = {}
local _, namespace = ...
local CAST_LIFETIME = 15
local MAX_PENDING = 64
local AURA_START_TOLERANCE = 0.5
local OBSERVATION_GRACE = 0.75
local CLOCK_EPSILON = 0.000001

function Tracking.create(engine, parser, api)
    local tracking = {}
    local bindings, records, pending, scans = {}, {}, {}, {}
    local status = { casts = 0, auras = 0, removals = 0, rejected = 0, learned = 0, rejectionReasons = {} }
    local waitMode, confirmedOnly, castEstimates = "off", true, false
    local scanRevision = 0
    local evidence = namespace.TickEvidence.create(api, function(key) return engine.learningSample(key) end)
    local function privateAuras(targetKey)
        local latest
        for unit, key in pairs(bindings) do
            local scan = scans[unit]
            if key == targetKey and scan and (not latest or scan.revision > latest.revision) then latest = scan end
        end
        return latest and (latest.reason == "aura_api_error" or latest.reason == "restricted_aura_result" or latest.reason == "auras_private") or false
    end
    local learning = namespace.TickLearning.create(engine, api, function(targetKey, effectKey, record)
        return records[targetKey] and records[targetKey][effectKey] == record
    end)
    local outcomes = namespace.CastOutcomes.create(api, function(targetKey, effectKey, record)
        return records[targetKey] and records[targetKey][effectKey] == record
    end, function(cast, now)
        local permitted = {}
        for key in pairs(cast.previous) do permitted[key] = true end
        local ok, restored = engine.rollback(cast.receipt, cast.targetKey, now, permitted)
        if not ok then return false end
        local target = records[cast.targetKey]
        target[cast.effectKey] = nil
        for key in pairs(restored) do target[key] = cast.previous[key] end
        status.removals = status.removals + 1
        return true
    end, function(targetKey, school, at)
        for key, record in pairs(records[targetKey] or {}) do
            if record.descriptor.school == school then
                local reference = engine.tickReference(targetKey, key, at)
                if reference and reference.distance <= 0.5 then return true end
            end
        end
        return false
    end)
    local function readable(value) return not api.isRestricted(value) end
    local function string(value, maximum)
        return readable(value) and type(value) == "string" and #value > 0 and #value <= maximum
    end
    local function own(unit)
        if not string(unit, 24) then return nil end
        return unit == "player" and "player" or (unit == "pet" and "pet" or nil)
    end
    local function reject(reason)
        status.rejected = status.rejected + 1
        status.lastReason = reason
        status.rejectionReasons[reason] = (status.rejectionReasons[reason] or 0) + 1
        return false, reason
    end
    local function effects(targetKey)
        records[targetKey] = records[targetKey] or {}
        return records[targetKey]
    end
    local function remove(targetKey, effectKey)
        engine.remove(targetKey, effectKey)
        if records[targetKey] then records[targetKey][effectKey] = nil end
        status.removals = status.removals + 1
    end
    function tracking.configure(options)
        waitMode = options.waitFirstTick or "off"
        castEstimates = options.castEstimates == true
        outcomes.configure({ allowGroups = castEstimates })
        local nextMode = options.confirmedOnly ~= false
        if nextMode ~= confirmedOnly then
            outcomes.reset(); pending = {}
            if nextMode then
                for targetKey, target in pairs(records) do
                    for key, record in pairs(target) do if record.applicationSource ~= "own_aura" then remove(targetKey, key) end end
                end
            end
            confirmedOnly = nextMode
            if nextMode and type(api.scan) == "function" and type(api.removed) == "function" then
                for unit in pairs(bindings) do tracking.scan(unit) end
            end
        end
    end
    local function install(targetKey, descriptor, start, stacks, instance, cast, timedAura, source)
        local copy = {}
        for name, value in pairs(descriptor) do copy[name] = value end
        descriptor = copy
        if descriptor.maxStacks then stacks = math.min(stacks or 1, descriptor.maxStacks) end
        descriptor.targetKey, descriptor.appliedAt, descriptor.stacks = targetKey, start, stacks or 1
        local ok, reason, receipt = engine.apply(descriptor, cast ~= nil)
        if not ok then return reject(reason) end
        local target = effects(targetKey)
        local previous = {}
        if target[descriptor.effectKey] then previous[descriptor.effectKey] = target[descriptor.effectKey] end
        if descriptor.exclusiveGroup then
            for key, record in pairs(target) do
                if key ~= descriptor.effectKey and record.descriptor.owner == descriptor.owner
                    and record.descriptor.exclusiveGroup == descriptor.exclusiveGroup then
                    previous[key] = record; target[key] = nil
                end
            end
        end
        target[descriptor.effectKey] = { descriptor = descriptor, start = start, expires = start + descriptor.duration, baseExpires = start + descriptor.duration,
            stacks = stacks or 1, instance = instance, confirmed = instance ~= nil,
            applicationSource = source or (timedAura and "own_aura" or "cast_estimate"),
            applicationContext = cast and cast.contextAtSuccess }
        if cast then
            outcomes.remember({ targetKey = targetKey, effectKey = descriptor.effectKey, record = target[descriptor.effectKey],
                at = start, sentAt = cast.sentAt, previous = previous, receipt = receipt }, api.now())
        end
        return true
    end
    local function applyCast(cast, start)
        local descriptor = cast.descriptor
        local existing = records[cast.targetKey] and records[cast.targetKey][descriptor.effectKey]
        if existing and existing.confirmed and existing ~= cast.previousAtSend
            and existing.descriptor.spellId == cast.spellId and existing.start >= cast.sentAt then return true end
        return install(cast.targetKey, descriptor, start, 1, nil, cast)
    end
    local function confirmedCast(cast, record)
        return record and record.applicationSource == "own_aura" and record ~= cast.previousAtSend
            and record.descriptor.owner == cast.owner and record.descriptor.spellId == cast.spellId
            and record.start >= cast.sentAt - CLOCK_EPSILON
    end
    local function confirmPending(targetKey, record)
        for id, cast in pairs(pending) do
            if cast.targetKey == targetKey and cast.successAt and confirmedCast(cast, record) then pending[id] = nil end
        end
    end
    local function rescanTarget(targetKey)
        if type(api.scan) ~= "function" or type(api.removed) ~= "function" then return end
        for unit, key in pairs(bindings) do if key == targetKey then tracking.scan(unit) end end
    end
    local function startCastEstimates()
        if not castEstimates or not confirmedOnly then return end
        local ready = {}
        for id, cast in pairs(pending) do
            if evidence.avoided(cast) then pending[id] = nil
            elseif evidence.canStartOnCast(cast) then ready[#ready + 1] = { id = id, cast = cast } end
        end
        table.sort(ready, function(a, b) return a.cast.successAt < b.cast.successAt end)
        for _, entry in ipairs(ready) do
            local cast, id = entry.cast, entry.id
            if pending[id] == cast then
                local d = cast.descriptor
                local old = records[cast.targetKey] and records[cast.targetKey][d.effectKey]
                if not old or old.start <= cast.successAt then
                    local copy = {}; for name, value in pairs(d) do copy[name] = value end
                    copy.learningKey, copy.soloDamageLimit = "private:" .. d.learningKey, d.powerBudget
                    copy.liveSoloEstimate = true
                    local attempt = {}; for name, value in pairs(cast) do attempt[name] = value end
                    attempt.descriptor = copy
                    pending[id] = nil
                    install(cast.targetKey, copy, cast.successAt, 1, nil, attempt, false, "cast_miss_checked")
                    local current = records[cast.targetKey] and records[cast.targetKey][d.effectKey]
                    status.lastReason = current and current.applicationSource == "cast_miss_checked"
                        and "cast_estimate_with_miss_check" or "cast_cancelled_by_miss"
                else pending[id] = nil end
            end
        end
    end
    function tracking.advance()
        local now = api.now()
        if not now then return false end
        outcomes.advance(now)
        learning.flush(now)
        engine.advance(now)
        for id, cast in pairs(pending) do if now - (cast.successAt or cast.sentAt) > CAST_LIFETIME then pending[id] = nil end end
        for targetKey, target in pairs(records) do
            for key, record in pairs(target) do
                if now > record.expires + OBSERVATION_GRACE then target[key] = nil end
            end
            if next(target) == nil then records[targetKey] = nil end
        end
        return true
    end
    function tracking.bind(unit)
        if not string(unit, 24) then return false end
        local previous, key = bindings[unit], api.identity(unit)
        if previous and key and key ~= previous and (previous:match("^target:")
            or previous:match("^plate:") and key:match("^guid:")) then
            local old = records[previous]
            if old then
                for effectKey, record in pairs(old) do
                    local current = records[key] and records[key][effectKey]
                    if not current or current.start < record.start then
                        if engine.moveEffect(previous, key, effectKey) then
                            for otherKey, other in pairs(effects(key)) do
                                if otherKey ~= effectKey and record.descriptor.exclusiveGroup
                                    and other.descriptor.exclusiveGroup == record.descriptor.exclusiveGroup
                                    and other.descriptor.owner == record.descriptor.owner then effects(key)[otherKey] = nil end
                            end
                            effects(key)[effectKey] = record
                            record.descriptor.targetKey = key
                        end
                    end
                end
                engine.forgetTarget(previous); records[previous] = nil
            end
            outcomes.move(previous, key)
            evidence.move(previous, key)
            for _, cast in pairs(pending) do if cast.targetKey == previous then cast.targetKey = key end end
            for alias, bound in pairs(bindings) do if bound == previous then bindings[alias] = key end end
        end
        bindings[unit] = key
        if not key then return false end
        return true
    end
    function tracking.targetChanged()
        local retired = api.targetChanged and api.targetChanged()
        bindings.target = nil
        if retired then
            outcomes.forget(retired)
            evidence.forget(retired)
            engine.forgetTarget(retired); records[retired] = nil
            for id, cast in pairs(pending) do if cast.targetKey == retired then pending[id] = nil end end
        end
        return tracking.scan("target")
    end
    function tracking.unbind(unit)
        if not string(unit, 24) then return false end
        local key = bindings[unit]
        bindings[unit] = nil
        scans[unit] = nil
        api.release(unit)
        if key and key:match("^plate:") then
            outcomes.forget(key)
            evidence.forget(key)
            engine.forgetTarget(key); records[key] = nil
            for id, cast in pairs(pending) do if cast.targetKey == key then pending[id] = nil end end
        end
        return true
    end
    function tracking.addUnit(unit)
        if not string(unit, 24) then return false end
        if bindings[unit] then tracking.unbind(unit) end
        return tracking.scan(unit)
    end
    function tracking.sent(unit, targetName, castId, spellId)
        tracking.advance()
        local owner = own(unit)
        if not owner or not string(castId, 120) then return reject("unreadable_or_foreign_cast") end
        local targetKey, reason = api.castTarget(targetName, bindings, owner)
        local now = api.now()
        if not targetKey or not now then return reject(reason or "unreadable_clock") end
        local count = 0
        for _ in pairs(pending) do count = count + 1 end
        if count >= MAX_PENDING and not pending[castId] then return reject("pending_limit") end
        local combo = api.combo()
        local request = api.spell(spellId, owner, combo)
        if not readable(spellId) or type(spellId) ~= "number" or spellId ~= spellId
            or spellId < 1 or spellId % 1 ~= 0 then return reject("unreadable_spell") end
        local descriptor, failure
        if request then descriptor, failure = parser.describe(request) end
        if request and not descriptor then return reject(failure) end
        pending[castId] = { descriptor = descriptor, targetKey = targetKey, sentAt = now,
            owner = owner, spellId = spellId, combo = combo,
            previousAtSend = descriptor and records[targetKey] and records[targetKey][descriptor.effectKey] }
        if reason == "current_target_fallback" then status.lastReason = reason end
        return true
    end
    function tracking.cancel(unit, castId)
        if not own(unit) or not string(castId, 120) then return false end
        pending[castId] = nil
        return true
    end
    function tracking.succeeded(unit, castId, spellId)
        tracking.advance()
        local owner = own(unit)
        if not owner or not string(castId, 120) or not readable(spellId) then return reject("unreadable_or_foreign_cast") end
        local cast = pending[castId]
        if not cast or cast.owner ~= owner or cast.spellId ~= spellId then
            return reject("uncorrelated_cast")
        end
        if cast.successAt then return false, "duplicate_cast_success" end
        local now = api.now()
        if not now then return reject("unreadable_clock") end
        status.casts = status.casts + 1
        cast.successAt = now
        cast.contextAtSuccess = type(api.learningContext) == "function" and api.learningContext() or "unreadable"
        cast.soloAtSuccess = type(api.learningContext) == "function" and api.learningContext() == "solo"
        if not cast.descriptor then
            local request = api.spell(spellId, owner, cast.combo)
            if request then cast.descriptor = parser.describe(request) end
        end
        if not cast.descriptor then
            status.lastReason = "deferred_spell_data"
            return false, "deferred_spell_data"
        end
        if confirmedOnly then
            local existing = records[cast.targetKey] and records[cast.targetKey][cast.descriptor.effectKey]
            if confirmedCast(cast, existing) then pending[castId] = nil
            else rescanTarget(cast.targetKey) end
            cast.privateAuras = privateAuras(cast.targetKey)
            startCastEstimates()
            if not pending[castId] then
                local current = records[cast.targetKey] and records[cast.targetKey][cast.descriptor.effectKey]
                status.lastReason = current and current.applicationSource == "own_aura" and "own_aura_confirmed"
                    or current and current.applicationSource == "cast_miss_checked" and "cast_estimate_with_miss_check" or "cast_cancelled_by_miss"
                return true, status.lastReason
            end
            status.lastReason = pending[castId] and "waiting_own_aura" or "own_aura_confirmed"
            return true, status.lastReason
        end
        pending[castId] = nil
        return applyCast(cast, now)
    end
    function tracking.textUpdated(spellId)
        tracking.advance()
        if not readable(spellId) or type(spellId) ~= "number" then return false end
        local changed = false
        local retry = {}
        for id, cast in pairs(pending) do
            if cast.spellId == spellId and cast.successAt then
                local request = api.spell(spellId, cast.owner, cast.combo)
                local descriptor = request and parser.describe(request)
                if descriptor then
                    local existing = records[cast.targetKey] and records[cast.targetKey][descriptor.effectKey]
                    if confirmedOnly then
                        cast.descriptor = descriptor
                        if confirmedCast(cast, existing) then pending[id] = nil; changed = true
                        else retry[cast.targetKey] = true end
                    elseif not existing or existing.start <= cast.successAt then
                        cast.descriptor = descriptor
                        changed = applyCast(cast, cast.successAt) or changed
                    end
                    if not confirmedOnly then pending[id] = nil end
                end
            end
        end
        for _, key in pairs(bindings) do retry[key] = true end
        for key in pairs(retry) do rescanTarget(key) end
        startCastEstimates()
        return changed
    end
    function tracking.scan(unit, update)
        tracking.advance()
        if not tracking.bind(unit) then
            if string(unit, 24) then scans[unit] = nil end
            return false
        end
        local key = bindings[unit]
        local target = effects(key)
        for _, id in ipairs(api.removed(update)) do
            outcomes.removed(key, id)
            for effectKey, record in pairs(target) do
                if record.instance == id then remove(key, effectKey) end
            end
        end
        local scan = api.scan(unit)
        scans[unit] = scan.audit
        local active = {}
        local now = api.now()
        if not now then return reject("unreadable_clock") end
        scanRevision = scanRevision + 1
        if scans[unit] then scans[unit].at, scans[unit].revision = now, scanRevision end
        for _, cast in pairs(pending) do if cast.targetKey == key and cast.successAt then cast.privateAuras = privateAuras(key) end end
        for _, aura in ipairs(scan.items) do
            local descriptor, prior, failure
            for _, record in pairs(target) do
                if record.descriptor.spellId == aura.spellId
                    and (record.descriptor.owner == aura.owner or aura.owner == "player_or_pet") then
                    prior = record
                    break
                end
            end
            local owner = aura.owner == "player_or_pet" and (prior and prior.descriptor.owner or "player") or aura.owner
            local combo, model
            local auraStart = aura.expiration and aura.duration and aura.expiration - aura.duration
            if prior and prior.descriptor.mode == "finisher" then
                local sameClock = not auraStart or math.abs(auraStart - prior.start) <= CLOCK_EPSILON
                local sameNative = prior.instance == aura.instanceId and sameClock
                local sameCast = prior.applicationSource == "cast_miss_checked" and auraStart
                    and math.abs(auraStart - prior.start) <= AURA_START_TOLERANCE
                if sameNative or sameCast then model, combo = prior.descriptor, prior.descriptor.comboPoints end
            end
            if not model and auraStart then
                local latest, ambiguous
                for _, cast in pairs(pending) do
                    if cast.targetKey == key and cast.spellId == aura.spellId and cast.owner == owner and cast.combo
                        and math.abs((cast.successAt or cast.sentAt) - auraStart) <= AURA_START_TOLERANCE then
                        if not latest or cast.sentAt > latest.sentAt then latest, ambiguous = cast, false
                        elseif cast.sentAt == latest.sentAt and cast.combo ~= latest.combo then ambiguous = true end
                    end
                end
                if latest and not ambiguous then combo = latest.combo end
            end
            local request = api.spell(aura.spellId, owner, combo)
            if request then
                descriptor, failure = parser.describe(request)
                if not descriptor and failure == "unknown_spell" and aura.owner == "player_or_pet" and owner == "player" then
                    local petRequest = api.spell(aura.spellId, "pet")
                    if petRequest then descriptor, failure = parser.describe(petRequest) end
                end
                if not descriptor and prior then remove(key, prior.descriptor.effectKey) end
            elseif model then descriptor = model
            elseif prior and prior.descriptor.mode ~= "finisher" then descriptor = prior.descriptor end
            if failure then status.lastAuraReason = failure end
            if scans[unit] then
                for _, sample in ipairs(scans[unit].samples) do
                    if sample.instanceId == aura.instanceId then
                        sample.model = descriptor and descriptor.familyKey or failure or "unavailable_spell_data"
                        sample.clock = aura.duration and aura.expiration and "readable" or "unreadable_aura_clock"
                        if failure and request then sample.description = request.description end
                        break
                    end
                end
            end
            if descriptor then
                local effectKey = descriptor.effectKey
                active[effectKey] = true
                local existing = target[effectKey]
                local timedAura = aura.expiration ~= nil and aura.duration ~= nil
                if confirmedOnly and existing and not timedAura and existing.instance ~= aura.instanceId then
                    remove(key, effectKey); existing = nil
                end
                local start = timedAura and aura.expiration - aura.duration
                    or (not confirmedOnly and existing and existing.start)
                if confirmedOnly and existing and timedAura and aura.expiration <= now
                    and (existing.instance == aura.instanceId or start >= existing.start - CLOCK_EPSILON) then
                    remove(key, effectKey); existing = nil
                end
                local stacks = aura.stacks and math.max(1, aura.stacks) or (existing and existing.stacks or 1)
                if descriptor.maxStacks then stacks = math.min(stacks, descriptor.maxStacks) end
                local expires = start and (aura.expiration or start + descriptor.duration)
                local previousAura = outcomes.previousAura(key, effectKey, aura.instanceId, start)
                local incompleteOutcome = existing and outcomes.pending(existing) and not (aura.expiration and aura.duration)
                local tolerance = confirmedOnly and CLOCK_EPSILON or AURA_START_TOLERANCE
                if not previousAura and not incompleteOutcome and start and start >= 0 and start <= now + CLOCK_EPSILON
                    and expires > now and (not existing or start >= existing.start - tolerance) then
                    local copy = {}
                    for name, value in pairs(descriptor) do copy[name] = value end
                    copy.damageDuration = descriptor.damageDuration or descriptor.duration
                    if aura.duration then copy.duration = aura.duration end
                    if descriptor.mode == "delayed" then copy.interval, copy.damageDuration = copy.duration, copy.duration end
                    local sameModel = existing and existing.descriptor.learningKey == copy.learningKey
                        and existing.descriptor.totalDamage == copy.totalDamage and existing.descriptor.interval == copy.interval
                        and (existing.descriptor.damageDuration or existing.descriptor.duration) == copy.damageDuration
                    if existing and aura.expiration and aura.duration then outcomes.confirm(existing) end
                    local sameApplication = existing and existing.start == start and existing.baseExpires == expires
                        and (not timedAura or existing.applicationSource == "own_aura" and existing.instance == aura.instanceId)
                    if sameApplication and sameModel then
                        existing.instance, existing.confirmed = aura.instanceId, true
                        if timedAura then existing.applicationSource = "own_aura" end
                        if existing.stacks ~= stacks then
                            if engine.setStacks(key, effectKey, stacks) then existing.stacks = stacks end
                        end
                    else
                        local installed = install(key, copy, start, stacks, aura.instanceId, nil, timedAura)
                        if installed and sameApplication then target[effectKey].tickSeen = existing.tickSeen
                        elseif not installed and existing then remove(key, effectKey) end
                    end
                    if confirmedOnly and target[effectKey] then confirmPending(key, target[effectKey]) end
                    status.auras = status.auras + 1
                elseif confirmedOnly and existing and not timedAura and existing.instance == aura.instanceId and aura.stacks then
                    if engine.setStacks(key, effectKey, stacks) then existing.stacks = stacks end
                end
            end
        end
        if scan.complete then
            for effectKey, record in pairs(target) do
                if not active[effectKey] then
                    if record.confirmed or record.applicationSource == "solo_tick_estimate" or record.applicationSource == "cast_miss_checked" then remove(key, effectKey) end
                end
            end
        end
        startCastEstimates()
        return true
    end
    function tracking.periodic()
        local observation = api.periodic()
        if not observation then return false end
        local target = records[observation.targetKey]
        if not target then return false end
        for effectKey, record in pairs(target) do
            if record.descriptor.spellId == observation.spellId and record.descriptor.owner == observation.owner then
                local ok, reason = engine.observeTick(observation.targetKey, effectKey, observation)
                if ok then record.tickSeen = true end
                if ok and reason == "learned" then status.learned = status.learned + 1 end
                return ok
            end
        end
        return false
    end
    function tracking.confirmCombat(unit, action, flag, amount, school)
        if api.flavor ~= "forever" then return false end
        if not string(unit, 24) then status.unreadableCombatUnits = (status.unreadableCombatUnits or 0) + 1; return false end
        if not tracking.bind(unit) then return false end
        local now = api.now(); if not now then return false end
        if confirmedOnly then
            local targetKey = bindings[unit]
            local inferred = evidence.match(pending, targetKey, action, flag, amount, school, now, function(hitSchool, damage, at)
                for key, record in pairs(records[targetKey] or {}) do
                    if record.descriptor.school == hitSchool then
                        local ref = engine.tickReference(targetKey, key, at)
                        if ref and ref.distance <= 0.45 and damage <= ref.soloMaximum then return true end
                        if math.abs(at - record.expires) <= 0.45 then return true end
                    end
                end
                return false
            end)
            if inferred then
                local d, cast = inferred.cast.descriptor, inferred.cast
                local existing = records[targetKey] and records[targetKey][d.effectKey]
                if not existing or existing.applicationSource ~= "own_aura" and inferred.start > existing.start + CLOCK_EPSILON then
                    local copy = {}; for name, value in pairs(d) do copy[name] = value end
                    copy.learningKey, copy.soloDamageLimit = "private:" .. d.learningKey, d.powerBudget
                    if install(targetKey, copy, inferred.start, 1) then
                        local record = records[targetKey][d.effectKey]
                        record.applicationSource, record.tickSeen = "solo_tick_estimate", true
                        if inferred.previous then
                            engine.observeSoloTick(targetKey, d.effectKey, { at = inferred.previous.at,
                                damage = inferred.previous.amount, critical = false, distorted = false, source = "solo_heuristic" })
                        end
                        pending[inferred.id] = nil
                        for id, old in pairs(pending) do
                            if old.targetKey == targetKey and old.descriptor and old.descriptor.effectKey == d.effectKey
                                and old.successAt and old.successAt <= cast.successAt then pending[id] = nil end
                        end
                        status.lastReason = "solo_tick_estimate"
                    end
                end
            end
        end
        local outcome = outcomes.observe(bindings[unit], unit, action, amount, school, now)
        local tick = learning.observe(bindings[unit], records[bindings[unit]] or {}, unit, action, flag, amount, school, now)
        return outcome or tick
    end
    function tracking.learningContextChanged()
        learning.synchronize()
        local context = type(api.learningContext) == "function" and api.learningContext() or "unreadable"
        for targetKey, target in pairs(records) do
            for key, record in pairs(target) do
                if record.applicationSource == "cast_miss_checked" and context ~= record.applicationContext then remove(targetKey, key) end
            end
        end
        if type(api.learningContext) ~= "function" or api.learningContext() ~= "solo" then
            for targetKey, target in pairs(records) do
                for key, record in pairs(target) do if record.applicationSource == "solo_tick_estimate" then remove(targetKey, key) end end
            end
            for _, cast in pairs(pending) do cast.tickEvidence, cast.soloAtSuccess = nil, false end
        end
        local now = api.now(); if now then outcomes.advance(now) end
    end
    function tracking.snapshot(unit)
        tracking.advance()
        if not tracking.bind(unit) then return nil, "unbound_unit" end
        local answer, reason = engine.snapshot(bindings[unit], api.now())
        if answer then
            local trackedCount = answer.effectCount
            local visible, total, guarded = {}, 0, 0
            for _, effect in ipairs(answer.effects) do
                local record = records[bindings[unit]] and records[bindings[unit]][effect.effectKey]
                if record then
                    local detail = record.descriptor
                    effect.familyKey, effect.spellId, effect.school, effect.icon = detail.familyKey, detail.spellId, detail.school, detail.icon
                    effect.appliedAt = record.start
                    effect.applicationSource = record.applicationSource
                    effect.tooltipTotalDamage, effect.duration, effect.tickInterval = detail.totalDamage, detail.duration, detail.interval
                    effect.tooltipDuration = detail.damageDuration or detail.duration
                end
                local castBased = record and record.applicationSource == "cast_miss_checked"
                local knownDamage = effect.confidence ~= "estimated"
                local inferred = record and record.applicationSource == "solo_tick_estimate"
                local solo = not inferred or type(api.learningContext) == "function" and api.learningContext() == "solo"
                if castBased then
                    solo = type(api.learningContext) == "function" and api.learningContext() == record.applicationContext
                    effect.confidence = "cast_estimated"
                    if not outcomes.windowElapsed(record, api.now()) then effect.conservativeDamage = 0 end
                end
                if inferred then effect.confidence = "solo_inferred" end
                local eligible = solo and (not confirmedOnly or record and (record.applicationSource == "own_aura" or inferred or castBased))
                if eligible and (not record or not record.doubtful or record.tickSeen)
                    and (waitMode == "off" or record and record.tickSeen or waitMode == "unsure" and knownDamage) then
                    visible[#visible + 1] = effect; total = total + effect.damage; guarded = guarded + effect.conservativeDamage
                end
            end
            answer.effects, answer.effectCount, answer.totalDamage, answer.conservativeDamage = visible, #visible, total, guarded
            answer.waitingEffects = trackedCount - #visible
            answer.waitingApplications = 0
            for _, cast in pairs(pending) do
                if cast.targetKey == bindings[unit] and cast.successAt then answer.waitingApplications = answer.waitingApplications + 1 end
            end
            if #visible == 0 then answer.reason = answer.waitingEffects > 0 and "waiting_first_tick"
                or confirmedOnly and answer.waitingApplications > 0 and "waiting_own_aura" or "no_active_dots" end
        end
        return answer, reason
    end
    function tracking.resetWorld()
        outcomes.reset()
        evidence.reset()
        learning.reset()
        for key in pairs(records) do engine.forgetTarget(key) end
        bindings, records, pending, scans = {}, {}, {}, {}
        api.reset()
    end
    function tracking.resetPet()
        outcomes.forget(nil, "pet")
        for targetKey, target in pairs(records) do
            for effectKey, record in pairs(target) do
                if record.descriptor.owner == "pet" then remove(targetKey, effectKey) end
            end
        end
        for id, cast in pairs(pending) do if cast.owner == "pet" then pending[id] = nil end end
    end
    function tracking.save(character)
        if not readable(character) or type(character) ~= "table" then return false end
        character.forecastLearning = engine.exportLearning()
        return true
    end
    function tracking.resetLearning()
        learning.reset(true); engine.resetLearning(); status.learned = 0
    end
    function tracking.restore(character)
        if not readable(character) or type(character) ~= "table" then return false end
        local ok, data = pcall(function() return character.forecastLearning end)
        if not ok or not readable(data) or data == nil then return false end
        return engine.importLearning(data)
    end
    function tracking.status()
        local result = {}
        for name, value in pairs(status) do result[name] = value end
        result.targets, result.effects, result.pendingCasts, result.pendingApplications = 0, 0, 0, 0
        for _, target in pairs(records) do
            result.targets = result.targets + 1
            for _ in pairs(target) do result.effects = result.effects + 1 end
        end
        for _, cast in pairs(pending) do
            result.pendingCasts = result.pendingCasts + 1
            if cast.successAt then result.pendingApplications = result.pendingApplications + 1 end
        end
        result.confirmedOnly = confirmedOnly
        result.inferredEffects = 0
        result.castEstimatedEffects = 0
        for _, target in pairs(records) do
            for _, record in pairs(target) do
                if record.applicationSource == "solo_tick_estimate" then result.inferredEffects = result.inferredEffects + 1 end
                if record.applicationSource == "cast_miss_checked" then result.castEstimatedEffects = result.castEstimatedEffects + 1 end
            end
        end
        local solo = learning.status()
        result.learning = solo
        result.outcomes = outcomes.status()
        result.tickEvidence = evidence.status()
        result.learned = result.learned + solo.learned
        result.learningAllowed = api.flavor == "classic" or solo.allowed
        result.learningSource = api.flavor == "classic" and "attributed_periodic_events" or "solo_heuristic"
        return result
    end
    function tracking.auraStatus(unit) return scans[unit] end
    return tracking
end

if type(namespace) == "table" then namespace.Tracking = Tracking end
return Tracking
