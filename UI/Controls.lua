local _, namespace = ...
local Theme = namespace.UITheme
local Controls = {}
function Controls.create(env)
    local ui = {}
    local locale = namespace.UILocale.code(env)
    local labels, helps = {}, {}
    ui.L = namespace.UILocale.create(env)
    function ui.setText(widget, key, ...)
        local text = ui.L(key, ...)
        widget:SetText(text)
        if key ~= "" then labels[widget] = { key = key, args = { ... }, count = select("#", ...), rendered = text } end
    end
    function ui.optionName(item) return item.literal and item.name or ui.L(item.name) end
    function ui.tip(key) return namespace.UITooltips.text(key, namespace.UILocale.code(env)) end
    local tooltip, menu, menuScroll, menuContent, activeItems, activePick
    local menuButtons = {}
    function ui.text(parent, value, x, y, width, role, color)
        local label = parent:CreateFontString(nil, "OVERLAY")
        Theme.typography(label, role or "body", color)
        label:SetPoint("TOPLEFT", x, y); label:SetJustifyH("LEFT")
        if width then label:SetWidth(width) end
        ui.setText(label, value); return label
    end
    function ui.closeMenu() if menu then menu:Hide() end end
    function ui.hideHelp() if tooltip then tooltip:Hide() end end
    function ui.refreshLocale()
        local selected = namespace.UILocale.code(env)
        if selected == locale then return end
        locale = selected; ui.closeMenu(); ui.hideHelp()
        for widget, entry in pairs(labels) do
            if widget:GetText() == entry.rendered then
                entry.rendered = ui.L(entry.key, unpack(entry.args, 1, entry.count)); widget:SetText(entry.rendered)
            end
        end
        for widget, resolve in pairs(helps) do widget.helpBody = resolve() end
        return true
    end
    function ui.help(widget, title, body, exact, literalTitle)
        local function resolve()
            if not exact and ui.tip(title) then return ui.tip(title) end
            return type(body) == "function" and body() or namespace.UITooltips.localize(body, namespace.UILocale.code(env))
        end
        helps[widget] = resolve; widget.helpBody = resolve()
        widget:EnableMouse(true)
        widget:SetScript("OnEnter", function(self)
            if not tooltip then
                tooltip = env.CreateFrame("Frame", nil, env.UIParent, "BackdropTemplate")
                tooltip:SetFrameStrata("TOOLTIP"); tooltip:SetClampedToScreen(true); tooltip:EnableMouse(false)
                tooltip:SetWidth(276)
                tooltip:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
                    tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
                tooltip:SetBackdropColor(0.05, 0.05, 0.05, 0.96); tooltip:SetBackdropBorderColor(0.65, 0.65, 0.65, 1)
                tooltip.title = ui.text(tooltip, "", 12, -10, 252, "body", Theme.colors.gold)
                tooltip.body = ui.text(tooltip, "", 12, -32, 252, "body", Theme.colors.white)
            end
            local caption = type(title) == "function" and title() or title
            tooltip.title:SetText(literalTitle and caption or ui.L(caption)); tooltip.body:SetText(resolve())
            tooltip.body:ClearAllPoints(); tooltip.body:SetPoint("TOPLEFT", tooltip.title, "BOTTOMLEFT", 0, -6)
            tooltip:SetHeight(tooltip.title:GetStringHeight() + tooltip.body:GetStringHeight() + 28)
            local window = env.DoTDamageSettingsWindow
            tooltip:SetScale(window and window:GetScale() or 1)
            tooltip:ClearAllPoints(); tooltip:SetPoint("TOPRIGHT", self, "TOPLEFT", -8, 0); tooltip:Show()
        end)
        widget:SetScript("OnLeave", ui.hideHelp)
    end
    local function row(parent, title, y, compact)
        local frame = env.CreateFrame("Frame", nil, parent)
        frame:SetSize(compact and 230 or 396, 28); frame:SetPoint("TOPLEFT", 0, y)
        local column = compact and 86 or 196
        frame.label = ui.text(frame, title, 6, 0, column - 8, compact and "small" or "body", compact and Theme.colors.white or Theme.colors.ink)
        frame.label:ClearAllPoints(); frame.label:SetPoint("TOPLEFT", 6, -5)
        frame.label:SetWordWrap(true)
        frame:SetHeight(math.max(28, frame.label:GetStringHeight() + 8))
        return frame
    end
    ui.row = row
    function ui.button(parent, title, x, y, width, callback)
        local button = env.CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
        button:SetPoint("TOPLEFT", x, y); button:SetSize(width or 180, 22)
        button:SetNormalFontObject(Theme.font(env, "Button", "button", Theme.colors.gold, true))
        button:SetHighlightFontObject(Theme.font(env, "ButtonHover", "button", Theme.colors.white, true))
        button:SetDisabledFontObject(Theme.font(env, "ButtonDisabled", "button", Theme.colors.disabled, true))
        ui.setText(button, title); button:SetScript("OnClick", callback)
        if ui.tip(title) then ui.help(button, title, ui.tip(title)) end
        return button
    end
    function ui.heading(parent, title, callback)
        local button = env.CreateFrame("Button", nil, parent); button:SetSize(396, 28)
        local label = ui.text(button, title, 28, 0, 352, "heading")
        label:ClearAllPoints(); label:SetPoint("LEFT", 28, 0); button:SetFontString(label); ui.setText(button, title)
        button.groupKey = title
        local toggle = button:CreateTexture(nil, "ARTWORK"); toggle:SetSize(16, 16); toggle:SetPoint("LEFT", 6, 0)
        local rule = button:CreateTexture(nil, "BORDER"); rule:SetPoint("BOTTOMLEFT", 6, 0); rule:SetPoint("BOTTOMRIGHT", -6, 0)
        rule:SetHeight(1); rule:SetColorTexture(0.36, 0.24, 0.11, 0.4)
        local hover = button:CreateTexture(nil, "HIGHLIGHT"); hover:SetAllPoints()
        hover:SetTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight"); hover:SetBlendMode("ADD"); hover:SetAlpha(0.18)
        button.setExpanded = function(expanded) toggle:SetTexture("Interface\\Buttons\\UI-" .. (expanded and "Minus" or "Plus") .. "Button-UP") end
        button:SetScript("OnClick", callback); return button
    end
    function ui.tab(parent, title, x, y, callback)
        local button = env.CreateFrame("Button", nil, parent); button:SetSize(110, 28); button:SetPoint("TOPLEFT", x, y)
        local text = ui.text(button, title, 10, 0, nil, "tab", Theme.colors.white)
        text:ClearAllPoints(); text:SetPoint("LEFT", 10, 0); button:SetFontString(text); ui.setText(button, title)
        local selected = button:CreateTexture(nil, "BACKGROUND"); selected:SetHeight(2); selected:SetColorTexture(0.90, 0.73, 0.32, 1)
        selected:SetPoint("TOPLEFT", text, "BOTTOMLEFT", 0, -3)
        local highlight = button:CreateTexture(nil, "HIGHLIGHT"); highlight:SetAllPoints()
        highlight:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Tab-Highlight"); highlight:SetBlendMode("ADD"); highlight:SetAlpha(0.25)
        button.setSelected = function(value)
            selected:SetWidth(math.max(1, text:GetStringWidth())); selected:SetShown(value)
            text:SetTextColor(1, value and 0.82 or 1, value and 0 or 1)
        end
        button:SetScript("OnClick", callback); return button
    end
    function ui.check(parent, title, y, get, set)
        local frame = row(parent, title, y)
        local check = env.CreateFrame("CheckButton", nil, frame)
        check:SetSize(24, 24); check:SetPoint("LEFT", 196, 0)
        check:SetNormalTexture("Interface\\Buttons\\UI-CheckBox-Up"); check:SetPushedTexture("Interface\\Buttons\\UI-CheckBox-Down")
        check:SetHighlightTexture("Interface\\Buttons\\UI-CheckBox-Highlight", "ADD"); check:SetCheckedTexture("Interface\\Buttons\\UI-CheckBox-Check")
        check:SetScript("OnClick", function(self) if frame.enabled ~= false then set(self:GetChecked() == true) end end)
        frame.widget = check; frame.refresh = function() check:SetChecked(get() == true) end
        if ui.tip(title) then ui.help(frame, title, ui.tip(title)); ui.help(check, title, ui.tip(title)) end
        return frame
    end
    function ui.edit(parent, x, y, width, maximum)
        local edit = env.CreateFrame("EditBox", nil, parent, "BackdropTemplate")
        Theme.box(edit, 0.13); Theme.typography(edit, "input", Theme.colors.white)
        edit:SetTextInsets(6, 6, 0, 0); edit:SetAutoFocus(false); edit:SetMaxLetters(maximum or 64)
        edit:SetSize(width, 22); edit:SetPoint("TOPLEFT", x, y)
        edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        edit:SetScript("OnEnterPressed", function(self) self:ClearFocus() end); return edit
    end
    function ui.slider(parent, title, y, low, high, step, get, set, percent, compact, suffix)
        local frame = row(parent, title, y, compact)
        local factor, column, span = percent and 100 or 1, compact and 86 or 196, compact and 144 or 200
        local slider = env.CreateFrame("Slider", nil, frame); slider:SetOrientation("HORIZONTAL")
        slider:SetPoint("LEFT", column + 2, 0); slider:SetSize(span - 80, 18)
        slider:SetMinMaxValues(low * factor, high * factor); slider:SetValueStep(step * factor); slider:SetObeyStepOnDrag(true)
        local track = slider:CreateTexture(nil, "BACKGROUND"); track:SetColorTexture(0.3, 0.3, 0.32, 1)
        track:SetHeight(4); track:SetPoint("LEFT"); track:SetPoint("RIGHT")
        slider:SetThumbTexture("Interface\\Buttons\\UI-SliderBar-Button-Horizontal"); slider:GetThumbTexture():SetSize(18, 24)
        local input = ui.edit(frame, 0, 0, 48, 12); input:SetTextInsets(4, 4, 0, 0)
        input:ClearAllPoints(); input:SetPoint("LEFT", slider, "RIGHT", 6, 0)
        local unit = ui.text(frame, percent and "%" or suffix or "", 0, 0, nil, "small", compact and Theme.colors.white or Theme.colors.ink)
        unit:ClearAllPoints(); unit:SetPoint("LEFT", input, "RIGHT", 2, 0)
        local syncing = false
        local function format(value) return (string.format("%.2f", value):gsub("0+$", ""):gsub("%.$", "")) end
        local function restore() input:SetText(format(get() * factor)) end
        local function commit()
            if syncing then return end
            local literal = (input:GetText() or ""):match("^%s*(.-)%s*$"):gsub(",", ".")
            local number = literal:match("^[+-]?%d*%.?%d+$") and tonumber(literal)
            if frame.enabled == false or not number or number ~= number or math.abs(number) == math.huge then restore(); return end
            number = math.max(low * factor, math.min(high * factor, number)); number = math.floor(number * 100 + 0.5) / 100
            input:SetText(format(number))
            if math.abs(number / factor - get()) > 0.0000001 then set(number / factor) end
        end
        slider:SetScript("OnValueChanged", function(_, number)
            if syncing or frame.enabled == false then return end
            local value = math.max(low, math.min(high, low + math.floor((number / factor - low) / step + 0.5) * step))
            input:SetText(format(value * factor)); set(value)
        end)
        slider:EnableMouseWheel(true)
        slider:SetScript("OnMouseWheel", function(self, delta) if frame.enabled ~= false then self:SetValue(self:GetValue() + delta * step * factor) end end)
        input:SetScript("OnEnterPressed", function(self) commit(); self:ClearFocus() end)
        input:SetScript("OnEscapePressed", function(self) restore(); self:ClearFocus() end)
        input:SetScript("OnEditFocusLost", commit)
        input:SetScript("OnEditFocusGained", function(self) if frame.enabled == false then self:ClearFocus() else self:HighlightText() end end)
        local body = ui.tip(title)
        if body then ui.help(frame, title, body); ui.help(slider, title, body) end
        ui.help(input, function() return ui.L("%s input", ui.L(title)) end,
            function() return (ui.tip(title) and ui.tip(title) .. "\n" or "") .. ui.tip("Number input") end, true)
        frame.refresh = function()
            syncing = true; slider:SetValue(get() * factor); if not input:HasFocus() then restore() end; syncing = false
        end
        frame.widget, frame.input = slider, input; return frame
    end
    function ui.menu(owner, items, selected, pick)
        ui.hideHelp()
        if menu and menu:IsShown() and menu.owner == owner then menu:Hide(); return end
        if not menu then
            menu = env.CreateFrame("Frame", nil, env.UIParent, "BackdropTemplate"); menu:SetFrameStrata("FULLSCREEN_DIALOG")
            menu:SetClampedToScreen(true); menu:EnableMouse(true); Theme.box(menu, 0.08, 0.98)
            menuScroll = env.CreateFrame("ScrollFrame", nil, menu, "UIPanelScrollFrameTemplate")
            menuScroll:SetPoint("TOPLEFT", 1, -4); menuScroll:SetPoint("BOTTOMRIGHT", -24, 4)
            menuContent = env.CreateFrame("Frame", nil, menuScroll); menuScroll:SetScrollChild(menuContent)
            menuScroll:EnableMouseWheel(true)
            menuScroll:SetScript("OnMouseWheel", function(self, delta)
                self:SetVerticalScroll(math.max(0, math.min(math.max(0, menuContent:GetHeight() - self:GetHeight()), self:GetVerticalScroll() - delta * 20)))
            end)
            pcall(menu.RegisterEvent, menu, "GLOBAL_MOUSE_DOWN")
            menu:SetScript("OnEvent", function() if menu:IsShown() and not menu:IsMouseOver() and not menu.owner:IsMouseOver() then menu:Hide() end end)
        end
        activeItems, activePick, menu.owner = items, pick, owner
        menu:SetSize(owner:GetWidth(), math.min(12, #items) * 20 + 8)
        menuContent:SetSize(owner:GetWidth() - 24, #items * 20); menuScroll:SetSize(owner:GetWidth() - 24, menu:GetHeight() - 8)
        for index, item in ipairs(items) do
            if not menuButtons[index] then
                local slot = index
                local button = env.CreateFrame("Button", nil, menuContent); button:SetHeight(20)
                local hover = button:CreateTexture(nil, "HIGHLIGHT"); hover:SetAllPoints(); hover:SetColorTexture(1, 1, 1, 0.1)
                button.swatch = button:CreateTexture(nil, "ARTWORK"); button.swatch:SetSize(12, 12); button.swatch:SetPoint("LEFT", 8, 0)
                button.caption = ui.text(button, "", 0, 0, nil, "small", Theme.colors.white); button.caption:SetWordWrap(false)
                button:SetFontString(button.caption)
                button:SetScript("OnClick", function() local entry = activeItems[slot]; menu:Hide(); activePick(entry.id) end)
                menuButtons[index] = button
            end
            local button = menuButtons[index]; button:ClearAllPoints()
            button:SetPoint("TOPLEFT", 1, -(index - 1) * 20); button:SetPoint("RIGHT", -1, 0)
            button.swatch:SetShown(item.rgb ~= nil)
            if item.rgb then button.swatch:SetColorTexture(item.rgb[1], item.rgb[2], item.rgb[3], 1) end
            button.caption:ClearAllPoints(); button.caption:SetPoint("LEFT", item.rgb and 26 or 8, 0); button.caption:SetPoint("RIGHT", -8, 0)
            local name = ui.optionName(item)
            button:SetText(name); button.caption:SetTextColor(1, item.id == selected and 209 / 255 or 1, item.id == selected and 0 or 1)
            local detail = item.help or ui.tip("option:" .. (owner.helpContext or "") .. ":" .. tostring(item.id))
                or ui.tip("option:" .. tostring(item.id)) or item.rgb and ui.tip("Colour option") or owner.helpBody
                or ui.L("Select %s.", name)
            ui.help(button, name, detail, true, true); button:Show()
        end
        for index = #items + 1, #menuButtons do menuButtons[index]:Hide() end
        local scrollbar = menuScroll.ScrollBar
        if scrollbar then scrollbar:SetShown(#items > 12) end
        menuScroll:SetVerticalScroll(0); menu:ClearAllPoints(); menu:SetPoint("TOPLEFT", owner, "BOTTOMLEFT", 0, -2); menu:Show()
    end
    function ui.choice(parent, title, y, values, get, set)
        local frame = row(parent, title, y)
        local button = env.CreateFrame("Button", nil, frame, "BackdropTemplate"); button:SetSize(200, 22); button:SetPoint("LEFT", 196, 0)
        button.helpContext = title
        Theme.box(button, 0.13)
        local hover = button:CreateTexture(nil, "HIGHLIGHT"); hover:SetAllPoints(); hover:SetColorTexture(1, 1, 1, 0.06)
        local caption = ui.text(button, "", 8, 0, nil, "small", Theme.colors.white)
        caption:SetWordWrap(false); button:SetFontString(caption)
        local swatch = button:CreateTexture(nil, "ARTWORK"); swatch:SetSize(12, 12); swatch:SetPoint("LEFT", 8, 0)
        local arrow = ui.text(button, "v", 0, 0, nil, "small", Theme.colors.gold); arrow:ClearAllPoints(); arrow:SetPoint("RIGHT", -8, 0)
        button:SetScript("OnClick", function()
            if frame.enabled == false then return end
            ui.menu(button, type(values) == "function" and values() or values, get(), set)
        end)
        frame.refresh = function()
            local items, current = type(values) == "function" and values() or values, get()
            local selected
            for _, item in ipairs(items) do if item.id == current then selected = item; break end end
            button:SetText(selected and ui.optionName(selected) or ui.L("Select"))
            local rgb = frame.colorGetter and frame.colorGetter() or selected and selected.rgb
            swatch:SetShown(rgb ~= nil); if rgb then swatch:SetColorTexture(rgb[1], rgb[2], rgb[3], 1) end
            caption:ClearAllPoints(); caption:SetPoint("LEFT", rgb and 26 or 8, 0); caption:SetPoint("RIGHT", -20, 0)
            button:SetEnabled(#items > 0)
        end
        if ui.tip(title) then ui.help(frame, title, ui.tip(title)); ui.help(button, title, ui.tip(title)) end
        frame.widget, frame.button = button, button; return frame
    end
    return ui
end
if type(namespace) == "table" then namespace.UIControls = Controls end
return Controls
