local Catalog = {}

function Catalog.create(facts, isRestricted)
    local byId, byName = {}, {}
    local catalog = {}
    for familyKey, family in pairs(facts.families) do
        byName[family.class] = byName[family.class] or {}
        for _, name in ipairs(family.names) do
            byName[family.class][name:lower()] = familyKey
        end
        for id in pairs(family.ranks) do byId[id] = familyKey end
    end

    local function readable(value)
        if isRestricted == nil then return true end
        local ok, hidden = pcall(isRestricted, value)
        return ok and hidden == false
    end

    function catalog.resolve(id, class, owner, flavor, name)
        if not readable(id) or not readable(class) or not readable(owner)
            or not readable(flavor) or not readable(name) then return nil, "restricted_spell" end
        if type(id) ~= "number" or id ~= id or id % 1 ~= 0 or id < 1 or id > 10000000
            or type(class) ~= "string" or type(owner) ~= "string"
            or (flavor ~= "forever" and flavor ~= "classic") then return nil, "invalid_spell" end
        if facts.excluded[id] then return nil, "excluded_spell" end
        local familyKey = byId[id]
        local fallback = familyKey == nil
        if not familyKey and type(name) == "string" and #name <= 160 then
            familyKey = byName[class] and byName[class][name:lower()]
        end
        local family = familyKey and facts.families[familyKey]
        if not family or family.class ~= class or family.owner ~= owner then return nil, "unknown_spell" end
        local versions = family.ranks[id]
        local rank = versions and versions[flavor]
        if versions and not rank then return nil, "unsupported_client_spell" end
        if fallback then
            local interval, school, icon
            for _, candidate in pairs(family.ranks) do
                local sameClient = candidate[flavor]
                if sameClient then
                    if interval and interval ~= sameClient.interval then return nil, "unknown_rank_interval" end
                    interval, school, icon = sameClient.interval, sameClient.school, sameClient.icon
                end
            end
            if not interval or interval <= 0 then return nil, "unknown_rank_interval" end
            rank = { interval = interval, duration = 0, school = school, icon = icon }
        end
        return {
            spellId = id, familyKey = familyKey, class = class, owner = owner, mode = family.mode,
            interval = rank.interval, duration = rank.duration, school = rank.school, icon = rank.icon,
            replacementGroup = family.replacementGroup, unknownRank = fallback,
            maxStacks = family.maxStacks or 1, damageModel = family.damageModel, leech = family.leech,
        }
    end

    function catalog.list(class, flavor)
        if not readable(class) or not readable(flavor) or type(class) ~= "string"
            or (flavor ~= "forever" and flavor ~= "classic") then return {} end
        local result = {}
        for familyKey, family in pairs(facts.families) do
            if family.class == class then
                local ids = {}
                for id, versions in pairs(family.ranks) do
                    if versions[flavor] then ids[#ids + 1] = id end
                end
                table.sort(ids)
                if #ids > 0 then
                    result[#result + 1] = { familyKey = familyKey, owner = family.owner, mode = family.mode,
                        spellId = ids[1], icon = family.ranks[ids[1]][flavor].icon, rankIds = ids }
                end
            end
        end
        table.sort(result, function(a, b) return a.familyKey < b.familyKey end)
        return result
    end

    return catalog
end

local _, namespace = ...
if type(namespace) == "table" then namespace.SpellCatalog = Catalog end
return Catalog
