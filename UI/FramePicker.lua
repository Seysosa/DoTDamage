local _, namespace = ...
local FramePicker = {}
function FramePicker.create(env, restricted, bindings)
    local L = namespace.UILocale.create(env)
    local picker, listener, callback, fieldName, ready = {}, nil, nil, nil, 0
    local label, highlight, elapsed = nil, nil, 0
    function picker.stop()
        if listener then listener:UnregisterAllEvents(); listener:SetScript("OnUpdate", nil); listener:Hide() end
        if highlight then highlight:Hide() end
        callback = nil
    end
    local function invoke(object, method)
        if not object or restricted(object) then return nil end
        local ok, result = pcall(function() if type(object[method]) == "function" then return object[method](object) end end)
        if ok and not restricted(result) then return result end
    end
    local function finite(value) return not restricted(value) and type(value) == "number" and value == value and math.abs(value) < 10000000 end
    local function choose()
        local ok, focused = pcall(function()
            return type(env.GetMouseFoci) == "function" and env.GetMouseFoci() or { env.GetMouseFocus() }
        end)
        if not ok or restricted(focused) or type(focused) ~= "table" then return nil end
        local x, y
        if type(env.GetCursorPosition) == "function" then
            local good, a, b = pcall(env.GetCursorPosition)
            if good and finite(a) and finite(b) then x, y = a, b end
        end
        local best, seen, visited = nil, {}, 0
        local function visit(frame, depth)
            if not frame or restricted(frame) or depth > 4 or seen[frame] or visited >= 128 then return end
            seen[frame], visited = true, visited + 1
            if invoke(frame, "IsForbidden") ~= false or invoke(frame, "IsVisible") == false then return end
            local name = invoke(frame, "GetName")
            if type(name) == "string" and name:match("^DoTDamage") then return end
            local hit, area = invoke(frame, "IsMouseOver") == true, math.huge
            if x then
                local good, left, bottom, width, height = pcall(function() return frame:GetRect() end)
                local scale = invoke(frame, "GetEffectiveScale") or invoke(invoke(frame, "GetParent"), "GetEffectiveScale")
                if good and finite(left) and finite(bottom) and finite(width) and finite(height) and finite(scale)
                    and width > 0 and height > 0 and scale > 0 then
                    local mx, my = x / scale, y / scale
                    hit = mx >= left and mx <= left + width and my >= bottom and my <= bottom + height
                    area = width * height * scale * scale
                end
            end
            local kind = invoke(frame, "GetObjectType")
            local rank = (kind == "Texture" or kind == "FontString" or kind == "PlayerModel") and 1 or 0
            local eligible = fieldName == "customIconAnchor" or kind == "StatusBar"
            local improves = not best or area < best.area or area == best.area
                and (rank > best.rank or rank == best.rank and depth > best.depth)
            if eligible and (hit or not x and depth == 0) and improves then
                local path = bindings.path(frame)
                if path then best = { path = path, frame = frame, area = area, depth = depth, rank = rank } end
            end
            for _, key in ipairs({ "Portrait", "portrait", "backdrop", "Health", "HealthBar", "healthBar", "health",
                "HealthBarsContainer", "TargetFrameContent", "TargetFrameContentMain" }) do
                local good, child = pcall(function() return frame[key] end)
                if good and not restricted(child) then visit(child, depth + 1) end
            end
            for _, method in ipairs({ "GetChildren", "GetRegions" }) do
                local children = { pcall(function() return frame[method](frame) end) }
                if children[1] then
                    for index = 2, math.min(#children, 66) do
                        if not restricted(children[index]) then visit(children[index], depth + 1) end
                    end
                end
            end
        end
        for index = 1, math.min(#focused, 8) do
            local frame = focused[index]
            for _ = 1, 6 do
                local name = invoke(frame, "GetName")
                if type(name) == "string" and name:match("^DoTDamage") then break end
                visit(frame, 0)
                frame = invoke(frame, "GetParent")
                if not frame or frame == env.UIParent then break end
            end
        end
        return best
    end
    function picker.start(key, onPick)
        picker.stop()
        if type(env.InCombatLockdown) == "function" and env.InCombatLockdown() then return false, L("Unavailable in combat.") end
        if type(env.GetMouseFoci) ~= "function" and type(env.GetMouseFocus) ~= "function" then return false, L("Mouse-frame API unavailable. Enter a path manually.") end
        fieldName, callback, ready = key, onPick, env.GetTime() + 0.2
        if not listener then
            listener = env.CreateFrame("Frame", "DoTDamageFramePicker", env.UIParent)
            label = listener:CreateFontString(nil, "OVERLAY", "GameFontNormal")
            label:SetPoint("CENTER", env.UIParent, "TOP", 0, -90)
            label:SetText("DoTDamage: " .. L("Choose an element under the cursor") .. "\n" .. L("Left-click accepts · Right-click cancels"))
            listener:SetFrameStrata("TOOLTIP")
            highlight = env.CreateFrame("Frame", "DoTDamagePickHighlight", env.UIParent, "BackdropTemplate")
            highlight:SetFrameStrata("TOOLTIP"); highlight:EnableMouse(false)
            highlight:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
            highlight:SetBackdropBorderColor(1, 0.82, 0, 1); highlight:Hide()
        end
        local ok, result = pcall(listener.RegisterEvent, listener, "GLOBAL_MOUSE_DOWN")
        if not ok or result == false then picker.stop(); return false, L("Frame picking is unsupported by this client. Enter a path manually.") end
        pcall(listener.RegisterEvent, listener, "PLAYER_REGEN_DISABLED")
        listener:SetScript("OnEvent", function(_, event, button)
            if event == "PLAYER_REGEN_DISABLED" then picker.stop(); return end
            if restricted(button) then return end
            if env.GetTime() < ready then return end
            if button == "RightButton" then picker.stop(); return end
            if button ~= "LeftButton" then return end
            local selected = choose()
            if selected then local picked = callback; picker.stop(); if picked then picked(selected.path) end end
        end)
        elapsed = 0
        listener:SetScript("OnUpdate", function(_, delta)
            elapsed = elapsed + delta; if elapsed < 0.1 then return end; elapsed = 0
            local selected = choose()
            highlight:Hide()
            if selected then
                local placed = pcall(function() highlight:ClearAllPoints(); highlight:SetAllPoints(selected.frame) end)
                if placed then highlight:Show() end
            end
            label:SetText("DoTDamage: " .. (selected and selected.path or L("Choose an element under the cursor"))
                .. "\n" .. L("Left-click accepts · Right-click cancels"))
        end)
        listener:Show(); return true
    end
    return picker
end
if type(namespace) == "table" then namespace.FramePicker = FramePicker end
return FramePicker
