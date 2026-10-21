local Overlay = {}
local WHITE = "Interface\\Buttons\\WHITE8X8"
local ICON = "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8"
local ICONS = {
    skull = ICON, check = "Interface\\RaidFrame\\ReadyCheck-Ready",
}
local SCHOOLS = { [1] = { 1, 0.3, 0.3 }, [2] = { 1, 0.9, 0.45 }, [4] = { 1, 0.55, 0.15 },
    [8] = { 0.35, 1, 0.35 }, [16] = { 0.45, 0.8, 1 }, [32] = { 0.7, 0.35, 1 },
    [64] = { 1, 0.55, 1 }, [20] = { 0.75, 0.6, 1 } }
local PALETTE = { { 0.95, 0.3, 0.3 }, { 0.3, 0.75, 1 }, { 1, 0.8, 0.2 }, { 0.45, 1, 0.45 },
    { 0.85, 0.4, 1 }, { 1, 0.55, 0.15 }, { 0.3, 1, 0.9 }, { 1, 0.45, 0.75 } }
local FAMILY_COLORS = {
    ["druid/roots"] = 1, ["druid/swarm"] = 2, ["druid/lacerate"] = 3, ["druid/moonfire"] = 4, ["druid/rake"] = 5, ["druid/rip"] = 6,
    ["hunter/rend"] = 1, ["hunter/scorpid"] = 2, ["hunter/sting"] = 3, ["hunter/tendon"] = 4, ["hunter/web"] = 5, ["hunter/lacerating"] = 7,
    ["mage/fireball"] = 1, ["mage/frostfire"] = 2, ["mage/pyroblast"] = 3, ["mage/ignite"] = 4,
    ["priest/plague"] = 1, ["priest/holyfire"] = 2, ["priest/pain"] = 3,
    ["rogue/garrote"] = 1, ["rogue/rupture"] = 2, ["rogue/poison"] = 3, ["shaman/flameshock"] = 1,
    ["warlock/agony"] = 1, ["warlock/doom"] = 2, ["warlock/corruption"] = 3, ["warlock/immolate"] = 4, ["warlock/siphon"] = 5,
    ["warrior/rend"] = 1, ["warrior/wounds"] = 2,
}
local MAX_SEGMENTS = 32
local ICON_GATE_LENGTH = 10000
local STRIPE_PERIODS = { stripes = 16, stripes05 = 8 }
local STRIPE_SCROLL_RATE = 0.24
local APPLICATION_TIME_TOLERANCE = 0.1
local STRATA_ORDER = { BACKGROUND = 1, LOW = 2, MEDIUM = 3, HIGH = 4,
    DIALOG = 5, FULLSCREEN = 6, FULLSCREEN_DIALOG = 7, TOOLTIP = 8 }

function Overlay.defaultColor(effect)
    local index = FAMILY_COLORS[effect.familyKey]
    if index then return PALETTE[index] end
    local hash = 0
    for byte in (effect.familyKey or effect.effectKey or "unknown"):gmatch(".") do hash = (hash + byte:byte()) % #PALETTE end
    return PALETTE[hash + 1]
end

function Overlay.create(env, restricted, addonName, options)
    local config = options or {}
    local root = env.CreateFrame("Frame", nil, env.UIParent)
    root:Hide()
    local fillBounds = env.CreateFrame("Frame", nil, root)
    local outline = env.CreateFrame("Frame", nil, root)
    local topLayer = env.CreateFrame("Frame", nil, root); topLayer:SetAllPoints(root)
    local icon = env.CreateFrame("Frame", nil, env.UIParent)
    icon:SetSize(20, 20); icon:SetClipsChildren(true); icon:Hide()
    local gate = env.CreateFrame("StatusBar", nil, icon)
    gate:SetStatusBarTexture(WHITE); gate:SetStatusBarColor(0, 0, 0, 0)
    gate:SetPoint("RIGHT", icon, "RIGHT")
    local iconArt = env.CreateFrame("Frame", nil, gate)
    iconArt:SetSize(20, 20); iconArt:SetPoint("RIGHT", gate:GetStatusBarTexture(), "RIGHT")
    local picture = iconArt:CreateTexture(nil, "ARTWORK")
    picture:SetPoint("CENTER"); picture:SetTexture(ICON)
    local crossStroke = iconArt:CreateTexture(nil, "ARTWORK")
    crossStroke:SetPoint("CENTER"); crossStroke:SetTexture(WHITE); crossStroke:Hide()
    local label = topLayer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("CENTER"); label:Hide()
    local edges, segments = {}, {}
    local clock, activeEffects, flashRemaining, seenEffects = 0, false, 0, {}
    local stripePhase = 0
    local flash = topLayer:CreateTexture(nil, "OVERLAY")
    flash:SetAllPoints(outline); flash:SetColorTexture(1, 1, 1, 1); flash:SetAlpha(0)
    local spark = outline:CreateTexture(nil, "OVERLAY")
    spark:SetBlendMode("ADD")
    spark:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark"); spark:SetSize(14, 30); spark:SetPoint("CENTER", outline, "RIGHT"); spark:Hide()
    local effectClip = env.CreateFrame("Frame", nil, topLayer); effectClip:SetAllPoints(outline); effectClip:SetClipsChildren(true)
    local shine = effectClip:CreateTexture(nil, "OVERLAY")
    shine:SetBlendMode("ADD")
    shine:SetTexture("Interface\\CastingBar\\UI-CastingBar-Spark"); shine:SetSize(24, 20); shine:Hide()
    local glows = {}
    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local glow = outline:CreateTexture(nil, "BACKGROUND")
        glow:SetTexture(WHITE); glow:Hide()
        glows[#glows + 1] = { texture = glow, side = side }
    end
    local media = "Interface\\AddOns\\" .. addonName .. "\\Media\\"
    for _, side in ipairs({ "TOP", "BOTTOM", "LEFT", "RIGHT" }) do
        local edge = outline:CreateTexture(nil, "OVERLAY")
        local horizontal = side == "TOP" or side == "BOTTOM"
        edge:SetTexture(WHITE)
        if horizontal then
            edge:SetPoint(side .. "LEFT", outline, side .. "LEFT"); edge:SetPoint(side .. "RIGHT", outline, side .. "RIGHT"); edge:SetHeight(1)
        else
            edge:SetPoint("TOP" .. side, outline, "TOP" .. side); edge:SetPoint("BOTTOM" .. side, outline, "BOTTOM" .. side); edge:SetWidth(1)
        end
        edges[#edges + 1] = { texture = edge, horizontal = horizontal }
    end
    local masked, maskTargets = nil, { flash, shine, spark }
    for _, entry in ipairs(edges) do maskTargets[#maskTargets + 1] = entry.texture end
    for _, entry in ipairs(glows) do maskTargets[#maskTargets + 1] = entry.texture end
    local function trackMask(region)
        maskTargets[#maskTargets + 1] = region
        if masked then pcall(function() region:AddMaskTexture(masked) end) end
    end
    local function useMask(mask)
        if masked == mask then return end
        for _, region in ipairs(maskTargets) do
            if masked then pcall(function() region:RemoveMaskTexture(masked) end) end
            if mask then pcall(function() region:AddMaskTexture(mask) end) end
        end
        masked = mask
    end
    local status, curve, curveThreshold, curveMaximum = { visible = false, iconMode = "hidden" }, nil, nil, nil
    local overlay = {}
    local function finite(value, low, high)
        return not restricted(value) and type(value) == "number" and value == value and value >= low and value <= high
    end
    local function color(effect, index)
        if config.colorMode == "single" then return config.color or PALETTE[1] end
        if config.colorMode == "school" then return SCHOOLS[effect.school] or { 1, 1, 1 } end
        local custom = config.dotColors and config.dotColors[effect.familyKey]
        if type(custom) == "table" and finite(custom[1], 0, 1) and finite(custom[2], 0, 1) and finite(custom[3], 0, 1) then return custom end
        return Overlay.defaultColor(effect)
    end
    local function placePattern(entry)
        local period = STRIPE_PERIODS[config.fillStyle]
        local offset = activeEffects and config.scrollStripes and stripePhase * period or 0
        entry.canvas:ClearAllPoints()
        entry.canvas:SetPoint("TOPLEFT", root, "TOPLEFT", offset - period, 0)
        entry.canvas:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", offset, 0)
    end
    local function segment(index)
        if not segments[index] then
            local meter = env.CreateFrame("StatusBar", nil, fillBounds)
            meter:SetAllPoints(fillBounds); meter:SetStatusBarTexture(WHITE); meter:SetStatusBarColor(1, 1, 1, 0)
            local fill = env.CreateFrame("Frame", nil, root)
            fill:SetClipsChildren(true)
            local canvas = env.CreateFrame("Frame", nil, fill)
            local texture = canvas:CreateTexture(nil, "ARTWORK"); texture:SetAllPoints(canvas)
            local divider = topLayer:CreateTexture(nil, "OVERLAY")
            divider:SetColorTexture(0, 0, 0, 0.8); divider:SetWidth(1)
            divider:SetPoint("TOP", meter:GetStatusBarTexture(), "TOPRIGHT"); divider:SetPoint("BOTTOM", meter:GetStatusBarTexture(), "BOTTOMRIGHT")
            trackMask(texture); trackMask(divider)
            segments[index] = { meter = meter, fill = fill, canvas = canvas, texture = texture, divider = divider, shown = 0, desired = 0 }
        end
        return segments[index]
    end
    function overlay.hide(reason)
        root:Hide(); icon:Hide()
        root:SetScript("OnUpdate", nil); seenEffects = {}; flashRemaining = 0
        status = { visible = false, iconMode = "hidden", reason = reason }
    end
    function overlay.restartEffects()
        clock, stripePhase, flashRemaining, seenEffects = 0, 0, 0, {}
    end
    function overlay.update(binding, forecast, health, unit)
        if not binding or not forecast or not health or not finite(forecast.totalDamage, 0, 1000000000000)
            or forecast.totalDamage <= 0 or #forecast.effects == 0 then return overlay.hide("no_forecast") end
        if health.healthReadable and health.current == 0 then return overlay.hide("dead_target") end
        if not health.maxReadable and not health.maxRestricted then return overlay.hide("missing_health_max") end
        if health.maxReadable and not finite(health.maximum, 0.001, 1000000000000) then return overlay.hide("invalid_health_max") end
        local bar = binding.bar
        local drawnSegments = config.colorMode == "single" and 1 or math.min(#forecast.effects, MAX_SEGMENTS)
        icon:Hide()
        local ok, failure = pcall(function()
            useMask(binding.mask)
            activeEffects = unit == "target" or unit == "preview-target"
            root:SetParent(bar); root:ClearAllPoints()
            if finite(binding.verticalInset, 0, 20) then
                root:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, -binding.verticalInset)
                root:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, binding.verticalInset)
            else root:SetAllPoints(bar) end
            local fillInset = finite(binding.fillInset, 0, 4) and binding.fillInset or 0
            fillBounds:ClearAllPoints()
            if fillInset > 0 then
                fillBounds:SetPoint("TOPLEFT", root, "TOPLEFT", fillInset, -fillInset)
                fillBounds:SetPoint("BOTTOMRIGHT", root, "BOTTOMRIGHT", -fillInset, fillInset)
            else fillBounds:SetAllPoints(root) end
            root:SetFrameStrata(bar:GetFrameStrata()); root:SetFrameLevel(bar:GetFrameLevel() + 5)
            local cumulative = 0
            local count = drawnSegments
            topLayer:SetFrameLevel(root:GetFrameLevel() + count + 2)
            local currentEffects, fresh = {}, false
            for index, effect in ipairs(forecast.effects) do
                local key = effect.effectKey or effect.familyKey or "effect:" .. index
                local appliedAt = finite(effect.appliedAt, 0, 1000000000) and effect.appliedAt or 0
                local previous = seenEffects[key]
                if not previous or appliedAt > previous + APPLICATION_TIME_TOLERANCE then fresh = true end
                currentEffects[key] = previous and math.abs(appliedAt - previous) <= APPLICATION_TIME_TOLERANCE and previous or appliedAt
            end
            for index = 1, count do
                local current = segment(index)
                local effect = forecast.effects[index]
                if not finite(effect.damage, 0, 1000000000000) then error("Invalid forecast segment") end
                cumulative = cumulative + effect.damage
                if index == count then cumulative = forecast.totalDamage end
                current.desired = cumulative
                if fresh or not activeEffects or not config.smoothMotion or current.shown > cumulative then current.shown = cumulative end
                current.meter:SetMinMaxValues(0, health.maximum); current.meter:SetValue(current.shown)
                current.fill:ClearAllPoints()
                if index == 1 then current.fill:SetPoint("TOPLEFT", fillBounds, "TOPLEFT")
                else current.fill:SetPoint("TOPLEFT", segments[index - 1].meter:GetStatusBarTexture(), "TOPRIGHT") end
                current.fill:SetPoint("BOTTOMRIGHT", current.meter:GetStatusBarTexture(), "BOTTOMRIGHT")
                current.fill:SetFrameLevel(root:GetFrameLevel() + index)
                local striped = config.fillStyle == "stripes" or config.fillStyle == "stripes05"
                -- Keep native tiling intact; every segment clips the same moving pattern.
                if striped then placePattern(current)
                else current.canvas:ClearAllPoints(); current.canvas:SetAllPoints(current.fill) end
                current.canvas:SetFrameLevel(current.fill:GetFrameLevel() + 1)
                local path = striped and media .. (config.fillStyle == "stripes05" and "Stripes05" or "Stripes")
                    or config.fillStyle == "smooth" and "Interface\\TargetingFrame\\UI-StatusBar"
                    or config.fillStyle == "raid" and "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" or WHITE
                local texture = current.texture
                local wrap = striped and "REPEAT" or nil
                texture:SetTexture(path, wrap, wrap)
                texture:SetHorizTile(striped); texture:SetVertTile(striped)
                if not striped then texture:SetTexCoord(0, 1, 0, 1) end
                local rgb = color(effect, index)
                if type(texture.SetGradient) == "function" and type(env.CreateColor) == "function" then
                    if config.fillStyle == "gradient" then
                        texture:SetVertexColor(1, 1, 1, 1)
                        texture:SetGradient("HORIZONTAL", env.CreateColor(rgb[1], rgb[2], rgb[3], 0),
                            env.CreateColor(rgb[1], rgb[2], rgb[3], config.opacity or 0.8))
                    else
                        texture:SetGradient("HORIZONTAL", env.CreateColor(1, 1, 1, 1), env.CreateColor(1, 1, 1, 1))
                        texture:SetVertexColor(rgb[1], rgb[2], rgb[3], config.opacity or 0.8)
                    end
                else texture:SetVertexColor(rgb[1], rgb[2], rgb[3], config.opacity or 0.8) end
                current.meter:Show()
                current.fill:SetShown(config.showMarkers ~= false and config.fillStyle ~= "none")
                current.divider:SetShown(activeEffects and config.segmentDividers and config.showMarkers ~= false and config.fillStyle ~= "none" and index < count)
            end
            seenEffects = currentEffects
            if fresh and activeEffects and config.flashOnApply then flashRemaining = 0.55 end
            for index = count + 1, #segments do segments[index].meter:Hide(); segments[index].fill:Hide(); segments[index].divider:Hide() end
            outline:ClearAllPoints(); outline:SetPoint("TOPLEFT", root, "TOPLEFT")
            outline:SetPoint("BOTTOMRIGHT", segments[count].meter:GetStatusBarTexture(), "BOTTOMRIGHT", fillInset, -fillInset)
            outline:SetFrameLevel(root:GetFrameLevel() + count + 1)
            for _, edge in ipairs(edges) do
                local dashed = config.outlineStyle == "dashed" or config.dashed == true
                local file = dashed and media .. (edge.horizontal and "DashesH" or "DashesV") .. (config.dashLength or 4) or WHITE
                edge.texture:SetTexture(file, dashed and "REPEAT" or nil, dashed and "REPEAT" or nil); edge.texture:SetHorizTile(dashed and edge.horizontal or false)
                edge.texture:SetVertTile(dashed and not edge.horizontal or false)
                local rgb = config.outlineColor or { 1, 0.88, 0.56 }
                edge.texture:SetVertexColor(rgb[1], rgb[2], rgb[3], config.outlineOpacity or 0.9)
                if edge.horizontal then edge.texture:SetHeight(config.outlineSize or 1)
                else edge.texture:SetWidth(config.outlineSize or 1) end
            end
            outline:SetShown(config.showMarkers ~= false and config.outlineStyle ~= "none")
            local glowColor = config.outlineColor or { 1, 0.88, 0.56 }
            for _, entry in ipairs(glows) do
                local glow, side = entry.texture, entry.side
                glow:ClearAllPoints()
                local size = config.glowSize or 7
                if side == "TOP" then glow:SetPoint("BOTTOMLEFT", outline, "TOPLEFT"); glow:SetPoint("BOTTOMRIGHT", outline, "TOPRIGHT"); glow:SetHeight(size)
                elseif side == "BOTTOM" then glow:SetPoint("TOPLEFT", outline, "BOTTOMLEFT"); glow:SetPoint("TOPRIGHT", outline, "BOTTOMRIGHT"); glow:SetHeight(size)
                elseif side == "LEFT" then glow:SetPoint("TOPRIGHT", outline, "TOPLEFT"); glow:SetPoint("BOTTOMRIGHT", outline, "BOTTOMLEFT"); glow:SetWidth(size)
                else glow:SetPoint("TOPLEFT", outline, "TOPRIGHT"); glow:SetPoint("BOTTOMLEFT", outline, "BOTTOMRIGHT"); glow:SetWidth(size) end
                local alpha = 0.3 * (config.outlineOpacity or 0.9)
                if type(glow.SetGradient) == "function" and type(env.CreateColor) == "function" then
                    glow:SetVertexColor(1, 1, 1, 1)
                    local inside = env.CreateColor(glowColor[1], glowColor[2], glowColor[3], alpha)
                    local outside = env.CreateColor(glowColor[1], glowColor[2], glowColor[3], 0)
                    local reversed = side == "BOTTOM" or side == "LEFT"
                    glow:SetGradient((side == "TOP" or side == "BOTTOM") and "VERTICAL" or "HORIZONTAL", reversed and outside or inside, reversed and inside or outside)
                else glow:SetVertexColor(glowColor[1], glowColor[2], glowColor[3], alpha) end
                glow:SetShown(activeEffects and config.showGlow and config.showMarkers ~= false and config.outlineStyle ~= "none" and alpha > 0)
            end
            spark:SetShown(activeEffects and config.showSpark and config.showMarkers ~= false)
            if config.showLabel then
                local font = label:GetFont()
                if font then label:SetFont(font, config.labelSize or 11, "OUTLINE") end
                label:ClearAllPoints()
                if config.labelPosition == "left" then label:SetPoint("RIGHT", root, "LEFT", -5, 0)
                elseif config.labelPosition == "right" then label:SetPoint("RIGHT", root, "RIGHT", -4, 0)
                else label:SetPoint("CENTER", root, "CENTER") end
                local rgb = config.labelColor or { 1, 1, 1 }; label:SetTextColor(rgb[1], rgb[2], rgb[3])
                label:SetText(tostring(math.floor(forecast.totalDamage + 0.5))); label:Show()
            else label:Hide() end
            local iconHost, anchorLevel = binding.root, 0
            if activeEffects and binding.anchor then
                local candidate = binding.anchor
                for _ = 1, 2 do
                    local good, level = pcall(function() return candidate:GetFrameLevel() end)
                    if good and finite(level, 0, 1000000) then iconHost, anchorLevel = candidate, level; break end
                    local readable, parent = pcall(function() return candidate:GetParent() end)
                    if not readable or restricted(parent) or not parent then break end
                    candidate = parent
                end
            end
            icon:SetParent(iconHost); icon:ClearAllPoints()
            if activeEffects then
                icon:SetPoint("CENTER", binding.anchor or bar, "CENTER", config.iconX or 0, config.iconY or 0)
            elseif config.iconPosition == "above" then
                icon:SetPoint("BOTTOM", bar, "TOP", config.iconX or 0, 4 + (config.iconY or 0))
            elseif config.iconPosition == "right" then
                icon:SetPoint("LEFT", bar, "RIGHT", 4 + (config.iconX or 0), config.iconY or 0)
            else icon:SetPoint("RIGHT", binding.anchor or bar, "LEFT", -4 + (config.iconX or 0), config.iconY or 0) end
            icon:SetSize(config.iconSize or 20, config.iconSize or 20)
            gate:SetSize(ICON_GATE_LENGTH, config.iconSize or 20)
            local iconSize = config.iconSize or 20
            iconArt:SetSize(iconSize, iconSize)
            if config.iconKind == "cross" or config.iconKind == "diamond" then
                local rgb = config.iconKind == "cross" and config.crossColor or config.diamondColor
                rgb = rgb or { 1, 1, 1 }
                picture:SetTexture(WHITE)
                picture:SetVertexColor(rgb[1], rgb[2], rgb[3], 1)
                if config.iconKind == "cross" then
                    picture:SetSize(iconSize * 0.18, iconSize * 0.8)
                    crossStroke:SetSize(iconSize * 0.18, iconSize * 0.8)
                    if type(picture.SetRotation) == "function" then
                        picture:SetRotation(math.pi / 4); crossStroke:SetRotation(-math.pi / 4)
                    end
                    crossStroke:SetVertexColor(rgb[1], rgb[2], rgb[3], 1); crossStroke:Show()
                else
                    picture:SetSize(iconSize * 0.62, iconSize * 0.62)
                    if type(picture.SetRotation) == "function" then picture:SetRotation(math.pi / 4) end
                    crossStroke:Hide()
                end
            else
                picture:SetSize(iconSize, iconSize)
                picture:SetTexture(ICONS[config.iconKind] or ICON)
                picture:SetVertexColor(1, 1, 1, 1)
                if type(picture.SetRotation) == "function" then picture:SetRotation(0) end
                crossStroke:Hide()
            end
            local iconStrata = bar:GetFrameStrata()
            if activeEffects then
                local hostStrata = iconHost:GetFrameStrata()
                if not restricted(iconStrata) and not restricted(hostStrata) and STRATA_ORDER[iconStrata]
                    and STRATA_ORDER[hostStrata] and STRATA_ORDER[hostStrata] > STRATA_ORDER[iconStrata] then iconStrata = hostStrata end
            end
            icon:SetFrameStrata(iconStrata)
            icon:SetFrameLevel(math.max(topLayer:GetFrameLevel() + 2, anchorLevel + 5))
            gate:SetFrameLevel(icon:GetFrameLevel() + 1)
        end)
        if not ok then overlay.hide("native_widget_rejected"); return false, failure end
        root:Show(); icon:Hide()
        local width = 0
        local widthOK, barWidth = pcall(bar.GetWidth, bar)
        if widthOK and finite(barWidth, 1, 10000) then width = barWidth end
        if activeEffects then
            root:SetScript("OnUpdate", function(_, elapsed)
                if not finite(elapsed, 0, 10) then return end
                clock = clock + elapsed
                local speed = finite(config.stripeSpeed, 0.25, 3) and config.stripeSpeed or 1
                stripePhase = (stripePhase + elapsed * STRIPE_SCROLL_RATE * speed) % 1
                if config.smoothMotion then
                    for _, entry in ipairs(segments) do
                        if entry.meter:IsShown() then
                            entry.shown = entry.shown + (entry.desired - entry.shown) * math.min(1, elapsed * 10)
                            entry.meter:SetValue(entry.shown)
                        end
                    end
                end
                local iconAlpha = config.iconPulse and 0.75 + 0.25 * math.cos(clock * 4) or 1
                picture:SetAlpha(iconAlpha); crossStroke:SetAlpha(iconAlpha)
                outline:SetAlpha(config.pulseOutline and 0.8 + 0.2 * math.cos(clock * 3) or 1)
                flashRemaining = math.max(0, flashRemaining - elapsed)
                flash:SetAlpha(config.showMarkers ~= false and config.flashOnApply and flashRemaining or 0)
                if config.showShine and config.showMarkers ~= false and width > 0 then
                    local progress = clock % (config.shineInterval or 3)
                    shine:SetShown(progress < 0.8)
                    shine:ClearAllPoints(); shine:SetPoint("CENTER", root, "LEFT", width * progress / 0.8, 0)
                    shine:SetAlpha(0.25)
                else shine:Hide() end
                if config.scrollStripes and (config.fillStyle == "stripes" or config.fillStyle == "stripes05") then
                    for _, entry in ipairs(segments) do
                        if entry.meter:IsShown() then placePattern(entry) end
                    end
                end
            end)
        else
            root:SetScript("OnUpdate", nil); picture:SetAlpha(1); crossStroke:SetAlpha(1); outline:SetAlpha(1); flash:SetAlpha(0); shine:Hide()
        end
        status = { visible = true, source = binding.source, healthReadable = health.healthReadable,
            maxReadable = health.maxReadable, effects = math.min(#forecast.effects, MAX_SEGMENTS), segments = drawnSegments,
            damage = forecast.totalDamage, conservativeDamage = forecast.conservativeDamage, iconMode = "unavailable" }
        if config.showIcon == false then status.iconMode = "disabled"; return true end
        local threshold = forecast.conservativeDamage
        if not finite(threshold, 0, 1000000000000) then return true end
        if threshold <= 0 then status.iconMode = "estimate_only"; return true end
        if health.healthReadable then
            status.iconMode = "readable_health"
            if finite(health.current, 0.001, threshold) then
                gate:SetMinMaxValues(0, 1); gate:SetValue(1)
                icon:SetAlpha(1); icon:Show()
            end
        elseif restricted(health.current) then
            local success, failure = pcall(function()
                gate:SetMinMaxValues(0, health.current); gate:SetValue(threshold)
                icon:SetAlpha(1); icon:Show()
            end)
            if success then status.iconMode = "native_health_gate"; return true end
            if not restricted(failure) and type(failure) == "string" then status.nativeError = failure end
        end
        if not health.healthReadable and health.maxReadable and type(env.UnitHealthPercent) == "function" and env.C_CurveUtil
            and type(env.C_CurveUtil.CreateCurve) == "function" and env.Enum and env.Enum.LuaCurveType then
            -- Only public curve points; the native percent result is consumed by SetAlpha.
            local limit = math.min(1, math.floor(threshold) / health.maximum)
            if limit <= 0 then status.iconMode = "below_one_health"; return true end
            local success, failure = pcall(function()
                if not curve then curve = env.C_CurveUtil.CreateCurve(); curve:SetType(env.Enum.LuaCurveType.Linear) end
                if curveThreshold ~= limit or curveMaximum ~= health.maximum then
                    curve:ClearPoints(); curve:AddPoint(0, 0)
                    local epsilon = math.min(limit / 2, 0.25 / health.maximum)
                    curve:AddPoint(epsilon, 1); curve:AddPoint(limit, 1)
                    if limit < 1 then
                        local endPoint = math.min(1, limit + epsilon)
                        curve:AddPoint(endPoint, 0)
                        if endPoint < 1 then curve:AddPoint(1, 0) end
                    end
                    curveThreshold, curveMaximum = limit, health.maximum
                end
                local alpha = env.UnitHealthPercent(unit, false, curve)
                gate:SetMinMaxValues(0, 1); gate:SetValue(1)
                icon:SetAlpha(alpha); icon:Show()
            end)
            if success then status.iconMode = "native_health_curve"
            else
                icon:Hide(); status.iconMode = "curve_rejected"
                if not restricted(failure) and type(failure) == "string" then status.nativeError = failure end
            end
        end
        return true
    end
    function overlay.status()
        local copy = {}
        for key, value in pairs(status) do copy[key] = value end
        return copy
    end
    function overlay.configure(newOptions) config = newOptions or {} end
    return overlay
end

local _, namespace = ...
if type(namespace) == "table" then namespace.Overlay = Overlay end
return Overlay
