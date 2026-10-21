local Description = {}
local NUMBER = "(%d+%.?%d*)"
local WORDS = "[a-z%s%(%)%-%.'%:]*"
local TIME = NUMBER .. "%s*([a-z%.]+)"
local LIMIT = 1000000000

local function seconds(amount, unit)
    amount = tonumber(amount)
    if not amount or amount <= 0 or amount > 600 then return nil end
    if unit:match("^sec") or unit:match("^sek") or unit:match("^seg") then return amount end
    if unit == "s" or unit == "s." then return amount end
    if unit:match("^min") and amount <= 10 then return amount * 60 end
end

local function normalize(text, locale)
    text = text:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""):gsub("|T.-|t", " ")
    text = text:gsub("\194\160", " "):gsub("\226\128\175", " ")
    text = text:gsub("\226\128\147", "-"):gsub("\226\128\148", "-")
    text = text:gsub("(%d)%s+(%d%d%d)(%f[^%d])", "%1%2%3")
    text = text:gsub("%d[%d%.,]*", function(literal)
        while literal:sub(-1) == "." or literal:sub(-1) == "," do literal = literal:sub(1, -2) end
        if locale == "deDE" or locale == "frFR" or locale == "esES" then return (literal:gsub("%.", ""):gsub(",", ".")) end
        return (literal:gsub(",", ""))
    end)
    text = text:gsub("Ä", "ae"):gsub("Ö", "oe"):gsub("Ü", "ue")
        :gsub("ä", "ae"):gsub("ö", "oe"):gsub("ü", "ue"):gsub("ß", "ss")
    for accent, plain in pairs({ ["é"] = "e", ["è"] = "e", ["ê"] = "e", ["ë"] = "e", ["É"] = "e", ["È"] = "e", ["Ê"] = "e",
        ["à"] = "a", ["â"] = "a", ["á"] = "a", ["À"] = "a", ["Á"] = "a", ["ù"] = "u", ["û"] = "u", ["ú"] = "u", ["Ú"] = "u",
        ["î"] = "i", ["ï"] = "i", ["í"] = "i", ["Í"] = "i", ["ô"] = "o", ["ó"] = "o", ["Ó"] = "o", ["ç"] = "c",
        ["ñ"] = "n", ["Ñ"] = "n" }) do text = text:gsub(accent, plain) end
    text = text:gsub("’", "'")
    text = text:lower():gsub("%s+", " ")
    if locale == "deDE" then
        text = text:gsub("zusaetzlich[enrs]*%s+", ""):gsub("lebenspunkten", "gesundheit"):gsub("lebenspunkte", "gesundheit")
            :gsub("im lauf von", "im verlauf von"):gsub("innerhalb von", "im verlauf von")
            :gsub("ueber einen zeitraum von", "im verlauf von"):gsub("dauert%s+", "haelt ")
    end
    return text
end

local function totalClause(text, locale, delayed)
    local hits, endings, problem = {}, {}, nil
    local function scan(pattern, durationFirst)
        for start, first, second, third, finish in text:gmatch("()" .. pattern .. "()") do
            local amount, duration, unit
            if durationFirst then duration, unit, amount = first, second, third
            else amount, duration, unit = first, second, third end
            local length = seconds(duration, unit)
            if length and not endings[finish] then
                local before = text:sub(math.max(1, start - 40), start - 1)
                if before:match("%d[%d%.]*%s+to%s*$") or before:match("%d[%d%.]*%s+bis%s*$")
                    or before:match("%d[%d%.]*%s+al%s*$") or before:match("%d[%d%.]*%s+a%s*$")
                    or before:match("[%+%-]%s*$") then
                    problem = "ranged_periodic_damage"
                end
                endings[finish] = true
                hits[#hits + 1] = { amount = tonumber(amount), duration = length }
            end
        end
    end
    if locale == "deDE" then
        for _, separator in ipairs({ "%s+insgesamt%s+", "%s*" }) do
            scan("im verlauf von " .. TIME .. separator .. NUMBER .. "%s*" .. WORDS .. "schaden", true)
        end
        for _, separator in ipairs({ "%s+lang%s*,?%s*", "%s+lang%s+zusaetzlich%s+", "%s+lang bluten und fuegt damit%s+" }) do
            scan(TIME .. separator .. NUMBER .. "%s*" .. WORDS .. "schaden", true)
        end
        scan("ueber%s+" .. TIME .. "%s*" .. NUMBER .. "%s*" .. WORDS .. "schaden", true)
        scan(NUMBER .. "%s*" .. WORDS .. "schaden%s+ueber%s+" .. TIME, false)
        scan(NUMBER .. "%s*" .. WORDS .. "schaden%s+im verlauf von%s+" .. TIME, false)
        if delayed then
            for _, prefix in ipairs({ "nach%s+", "nach ablauf von%s+" }) do
                scan(prefix .. TIME .. "%s*" .. NUMBER .. "%s*" .. WORDS .. "schaden", true)
            end
        end
    elseif locale == "frFR" then
        scan(NUMBER .. "%s*" .. WORDS .. "degats" .. WORDS .. "%s+en%s+" .. TIME, false)
        scan(NUMBER .. "%s*" .. WORDS .. "degats" .. WORDS .. "%s+pendant%s+" .. TIME, false)
    elseif locale == "esES" or locale == "esMX" then
        scan(NUMBER .. "%s*" .. WORDS .. "dano" .. WORDS .. "%s+durante%s+" .. TIME, false)
    else
        local connector = delayed and "after" or "over"
        scan(NUMBER .. "%s*" .. WORDS .. "damage%s+" .. connector .. "%s+" .. TIME, false)
    end
    if problem then return nil, nil, problem end
    if #hits > 1 then return nil, nil, "ambiguous_periodic_damage" end
    if #hits == 1 then return hits[1].amount, hits[1].duration end
end

local function tickClause(text, locale, allowHealth)
    local hits, endings, problem = {}, {}, nil
    local function scan(pattern, periodFirst)
        for start, first, second, third, finish in text:gmatch("()" .. pattern .. "()") do
            local amount, period, unit = first, second, third
            if periodFirst then period, unit, amount = first, second, third end
            local length = seconds(period, unit)
            if length and not endings[finish] then
                local before = text:sub(math.max(1, start - 40), start - 1)
                if before:match("%d[%d%.]*%s+to%s*$") or before:match("%d[%d%.]*%s+bis%s*$")
                    or before:match("%d[%d%.]*%s+al%s*$") or before:match("%d[%d%.]*%s+a%s*$")
                    or before:match("[%+%-]%s*$") then problem = "ranged_periodic_damage" end
                endings[finish] = true
                hits[#hits + 1] = { amount = tonumber(amount), interval = length }
            end
        end
    end
    if locale == "deDE" then
        scan("alle%s+" .. TIME .. "%s*" .. NUMBER .. "%s*" .. WORDS .. "schaden", true)
        scan(NUMBER .. "%s*" .. WORDS .. "schaden[^%d]-alle%s+" .. TIME, false)
        if allowHealth then
            scan("alle%s+" .. TIME .. "%s*" .. NUMBER .. "%s*" .. WORDS .. "gesundheit", true)
            scan(NUMBER .. "%s*" .. WORDS .. "gesundheit[^%d]-alle%s+" .. TIME, false)
        end
    elseif locale == "frFR" then
        scan(NUMBER .. "%s*" .. WORDS .. "degats" .. WORDS .. "%s+toutes?%s+les%s+" .. TIME, false)
    elseif locale == "esES" or locale == "esMX" then
        scan(NUMBER .. "%s*" .. WORDS .. "dano" .. WORDS .. "%s+cada%s+" .. TIME, false)
    else
        scan(NUMBER .. "%s*" .. WORDS .. "damage%s+every%s+" .. TIME, false)
        if allowHealth then scan(NUMBER .. "%s+health[^%d]-every%s+" .. TIME, false) end
    end
    if problem then return nil, nil, problem end
    if #hits > 1 then return nil, nil, "ambiguous_tick_damage" end
    if #hits == 1 then return hits[1].amount, hits[1].interval end
end

local function lifetime(text, locale)
    local length, problem
    local function accept(duration, unit)
        local value = seconds(duration, unit)
        if value and length and value ~= length then problem = "ambiguous_aura_duration" end
        if value then length = value end
    end
    local prefix = locale == "deDE" and "haelt%s+" or locale == "frFR" and "pendant%s+"
        or (locale == "esES" or locale == "esMX") and "durante%s+" or "lasts%s+"
    for duration, unit in text:gmatch(prefix .. TIME) do
        accept(duration, unit)
    end
    if locale == "deDE" then
        for duration, unit in text:gmatch("dauer:?%s+" .. TIME) do
            accept(duration, unit)
        end
    elseif locale == "frFR" then
        for duration, unit in text:gmatch("duree:?%s+" .. TIME) do accept(duration, unit) end
    elseif locale == "esES" or locale == "esMX" then
        for duration, unit in text:gmatch("duracion:?%s+" .. TIME) do accept(duration, unit) end
    end
    return length, problem
end

function Description.create(catalog, isRestricted)
    local parser = {}
    local unreadable = {}
    local cache, slots, nextSlot = {}, {}, 1
    local cacheFields = { "spellId", "class", "owner", "flavor", "name", "description", "locale", "comboPoints", "statsKey", "spellPower", "attackPower" }
    local function copyDescriptor(value)
        if not value then return nil end
        local result = {}
        for key, item in pairs(value) do result[key] = item end
        if value.tickWeights then
            result.tickWeights = {}
            for index, weight in ipairs(value.tickWeights) do result.tickWeights[index] = weight end
        end
        return result
    end
    local function read(input, field)
        local ok, value = pcall(function() return input[field] end)
        if not ok then return unreadable end
        if isRestricted then
            local checked, hidden = pcall(isRestricted, value)
            if not checked or hidden ~= false then return unreadable end
        end
        return value
    end

    local function describe(input)
        if isRestricted then
            local ok, hidden = pcall(isRestricted, input)
            if not ok or hidden ~= false then return nil, "restricted_input" end
        end
        if type(input) ~= "table" then return nil, "invalid_input" end
        local id, class, owner, flavor, name = read(input, "spellId"), read(input, "class"),
            read(input, "owner"), read(input, "flavor"), read(input, "name")
        local spell, reason = catalog.resolve(id, class, owner, flavor, name)
        if not spell then return nil, reason end
        if spell.damageModel == "observed" then return nil, "requires_observed_aura_damage" end
        local text, locale = read(input, "description"), read(input, "locale")
        if type(text) ~= "string" or #text == 0 or #text > 16384 then return nil, "unreadable_description" end
        if locale ~= "deDE" and locale ~= "enUS" and locale ~= "frFR" and locale ~= "esES" and locale ~= "esMX" then return nil, "unsupported_locale" end
        if text:find("$", 1, true) then return nil, "unresolved_description" end
        text = normalize(text, locale)
        if text:find("^coats a weapon") or text:find("^ueberzieht eine waffe") or text:find("^enduit une arme")
            or text:find("^impregna un arma") then return nil, "weapon_enchantment" end
        local combo = read(input, "comboPoints")
        if spell.mode == "finisher" then
            if type(combo) ~= "number" or combo ~= combo or combo % 1 ~= 0 or combo < 1 or combo > 5 then
                return nil, "requires_combo_points"
            end
            local pattern = locale == "deDE" and "(%d)%s+punkte?%s*:%s*"
                or locale == "frFR" and "(%d)%s+points?%s*:%s*"
                or (locale == "esES" or locale == "esMX") and "(%d)%s+puntos?%s*:%s*"
                or "(%d)%s+points?%s*:%s*"
            local start, stop
            for from, points, to in text:gmatch("()" .. pattern .. "()") do
                if tonumber(points) == combo then start = to end
                if start and tonumber(points) == combo + 1 then stop = from - 1; break end
            end
            if not start then return nil, "missing_combo_row" end
            text = text:sub(start, stop)
        end
        local amount, duration, problem = totalClause(text, locale, spell.mode == "delayed")
        if problem then return nil, problem end
        local interval = spell.interval
        local leech = spell.leech and (locale == "deDE" and (text:find("entzieht", 1, true) or text:find("uebertraegt", 1, true)) and text:find("ziel", 1, true)
            or locale == "enUS" and (text:find("transfers", 1, true) or text:find("drains", 1, true)) and text:find("target", 1, true)
            or locale == "frFR" and (text:find("draine", 1, true) or text:find("transfere", 1, true)) and text:find("cible", 1, true)
            or (locale == "esES" or locale == "esMX") and (text:find("drena", 1, true) or text:find("transfiere", 1, true)) and text:find("objetivo", 1, true))
        local perTick, tickPeriod, tickProblem = tickClause(text, locale, amount == nil and leech)
        if tickProblem then return nil, tickProblem end
        if amount and perTick then
            if spell.mode == "ramp" or spell.mode == "delayed" then return nil, "ambiguous_tick_schedule" end
            local expected = perTick * math.floor((duration + 0.000001) / tickPeriod)
            if math.abs(expected - amount) > 0.000001 then return nil, "inconsistent_periodic_damage" end
            interval = tickPeriod
        elseif not amount then
            if perTick then
                interval = tickPeriod
                local lifetimeProblem
                duration, lifetimeProblem = lifetime(text, locale)
                if lifetimeProblem then return nil, lifetimeProblem end
                duration = duration or (spell.duration > 0 and spell.duration or nil)
                if duration then amount = perTick * math.floor((duration + 0.000001) / interval) end
            end
        end
        if not amount or not duration then
            return nil, spell.mode == "triggered" and "requires_observed_aura_damage" or "missing_periodic_damage"
        end
        if spell.mode == "delayed" then interval = duration end
        if not interval or interval <= 0 then return nil, "requires_observed_tick_interval" end
        local ticks = math.floor((duration + 0.000001) / interval)
        if amount < 0 or amount > LIMIT or ticks < 1 or ticks > 300 then return nil, "invalid_periodic_damage" end
        local stats = read(input, "statsKey")
        if stats == nil then stats = "unverified" end
        if type(stats) ~= "string" or #stats < 1 or #stats > 64 then return nil, "unreadable_stat_key" end
        local result = {
            spellId = id, familyKey = spell.familyKey, effectKey = spell.familyKey .. ":" .. owner,
            owner = owner, class = class, kind = "aura", totalDamage = amount, duration = duration,
            interval = interval, school = spell.school, icon = spell.icon, mode = spell.mode,
            learningKey = id .. ":" .. owner .. ":cp" .. (spell.mode == "finisher" and combo or 0) .. ":" .. stats,
            exclusiveGroup = spell.replacementGroup, unknownRank = spell.unknownRank,
            maxStacks = spell.maxStacks,
            comboPoints = spell.mode == "finisher" and combo or nil,
        }
        if spell.mode == "ramp" then
            if ticks % 3 ~= 0 then return nil, "unsupported_ramp_schedule" end
            result.tickWeights = {}
            for index = 1, ticks do
                result.tickWeights[index] = index <= ticks / 3 and 0.5 or (index <= ticks * 2 / 3 and 1 or 1.5)
            end
        end
        local power = read(input, spell.school == 1 and "attackPower" or "spellPower")
        if type(power) == "number" and power == power and power >= 0 and power <= LIMIT then
            result.powerBudget = math.min(LIMIT, amount / ticks + power)
        end
        return result
    end

    function parser.describe(input)
        if isRestricted then
            local ok, hidden = pcall(isRestricted, input)
            if not ok or hidden ~= false then return nil, "restricted_input" end
        end
        if type(input) ~= "table" then return nil, "invalid_input" end
        local id, owner = read(input, "spellId"), read(input, "owner")
        if type(id) ~= "number" or id ~= id or id < 1 or id > 10000000 or id % 1 ~= 0
            or (owner ~= "player" and owner ~= "pet") then return describe(input) end
        local key, values = id .. ":" .. owner, {}
        for _, field in ipairs(cacheFields) do
            values[field] = read(input, field)
            if values[field] == unreadable then return describe(input) end
        end
        local previous, matches = cache[key], true
        if previous then
            for _, field in ipairs(cacheFields) do
                if previous.input[field] ~= values[field] then matches = false; break end
            end
            if matches then return copyDescriptor(previous.descriptor), previous.reason end
        end
        local result, reason = describe(input)
        if not previous then
            if slots[nextSlot] then cache[slots[nextSlot]] = nil end
            slots[nextSlot], nextSlot = key, nextSlot % 128 + 1
        end
        cache[key] = { input = values, descriptor = copyDescriptor(result), reason = reason }
        return result, reason
    end

    return parser
end

local _, namespace = ...
if type(namespace) == "table" then namespace.SpellDescription = Description end
return Description
