local Theme = {}
Theme.brandIcon = "Interface\\AddOns\\DoTDamage\\Media\\DoTDamage-Icon"
Theme.colors = { ink = { 0.20, 0.13, 0.07 }, muted = { 0.36, 0.25, 0.14 },
    gold = { 1, 0.82, 0 }, white = { 1, 1, 1 }, disabled = { 0.5, 0.5, 0.5 } }
Theme.metrics = { width = 740, height = 600, row = 28, label = 196, control = 200,
    previewLabel = 86, previewControl = 144 }
local sizes = { body = 14, small = 13, page = 17, description = 14, heading = 15,
    tab = 15, previewTitle = 16, status = 18, button = 13, input = 13, title = 14 }
local fonts = setmetatable({}, { __mode = "k" })
function Theme.typography(region, role, color, classic)
    local size = type(role) == "number" and role or sizes[role] or 14
    local path = classic and "Fonts\\FRIZQT_.TTF" or "Fonts\\ARIALN.TTF"
    local ok, applied = pcall(region.SetFont, region, path, size, "")
    if not ok or applied == false then pcall(region.SetFont, region, "Fonts\\FRIZQT_.TTF", size, "") end
    region:SetShadowOffset(classic and 1 or 0, classic and -1 or 0)
    region:SetShadowColor(0, 0, 0, classic and 1 or 0)
    local rgb = color or Theme.colors.ink; region:SetTextColor(rgb[1], rgb[2], rgb[3])
end
function Theme.font(env, name, role, color, classic)
    fonts[env] = fonts[env] or {}
    local cache = fonts[env]
    if not cache[name] then
        cache[name] = env.CreateFont("DoTDamageUIFont" .. name)
        Theme.typography(cache[name], role, color, classic)
    end
    return cache[name]
end
function Theme.box(frame, shade, alpha)
    frame:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    frame:SetBackdropColor(shade, shade, shade, alpha or 1)
    frame:SetBackdropBorderColor(0.38, 0.32, 0.18, 1)
end
function Theme.frame(env)
    local ok, frame = pcall(env.CreateFrame, "Frame", "DoTDamageSettingsWindow", env.UIParent, "PortraitFrameTemplate,BackdropTemplate")
    if not ok then frame = env.CreateFrame("Frame", "DoTDamageSettingsWindow", env.UIParent, "BackdropTemplate") end
    frame:SetSize(740, 600); frame:SetFrameStrata("DIALOG"); frame:SetClampedToScreen(true); frame:SetToplevel(true); frame:EnableMouse(true)
    if type(frame.SetTitle) == "function" then frame:SetTitle("DoTDamage") end
    if type(frame.SetPortraitToAsset) == "function" then frame:SetPortraitToAsset(Theme.brandIcon) end
    local container = frame.TitleContainer
    local title = container and container.TitleText or frame.TitleText
    if title then title:SetFontObject(Theme.font(env, "Title", "title", Theme.colors.gold, true)) end
    if not ok then
        frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
            tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 12, top = 12, bottom = 11 } })
    end
    local shade = frame:CreateTexture(nil, "BACKGROUND", nil, -8)
    shade:SetPoint("TOPLEFT", 12, -12); shade:SetPoint("BOTTOMRIGHT", -12, 12); shade:SetColorTexture(0.04, 0.03, 0.02, 0.98)
    frame:SetScale(math.min(1, (env.UIParent:GetWidth() - 24) / 740, (env.UIParent:GetHeight() - 24) / 600))
    return frame
end
function Theme.parchment(env, parent)
    local pane = env.CreateFrame("Frame", nil, parent, "BackdropTemplate")
    Theme.box(pane, 0.76); pane:SetBackdropColor(0, 0, 0, 0)
    local base = pane:CreateTexture(nil, "BORDER", nil, -1)
    base:SetAllPoints(); base:SetColorTexture(0.72, 0.53, 0.31, 1)
    local paper = pane:CreateTexture(nil, "BORDER", nil, 0)
    paper:SetPoint("TOPLEFT", 1, -1); paper:SetPoint("BOTTOMRIGHT", -1, 1)
    local atlas = false
    local atlasAvailable = false
    if env.C_Texture and type(env.C_Texture.GetAtlasInfo) == "function" then
        local ok, info = pcall(env.C_Texture.GetAtlasInfo, "QuestBG-Parchment")
        atlasAvailable = ok and type(info) == "table" and (type(env.issecretvalue) ~= "function" or not env.issecretvalue(info))
    end
    if atlasAvailable and type(paper.SetAtlas) == "function" then
        local ok, result = pcall(paper.SetAtlas, paper, "QuestBG-Parchment", false); atlas = ok and result ~= false
    end
    local path = "Interface\\AchievementFrame\\UI-Achievement-Parchment-Horizontal"
    if not atlas then paper:SetTexture(path) end
    local values = { pcall(paper.GetTexCoord, paper) }
    local valid = values[1]
    for index = 2, 9 do
        local value = values[index]
        if type(env.issecretvalue) == "function" and env.issecretvalue(value) then valid = false
        elseif type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then valid = false end
    end
    if valid then
        local top = pane:CreateTexture(nil, "BORDER", nil, 0)
        if atlas then local ok, result = pcall(top.SetAtlas, top, "QuestBG-Parchment", false); valid = ok and result ~= false
        else top:SetTexture(path) end
        if valid then
            local lx, ly = (values[2] + values[4]) / 2, (values[3] + values[5]) / 2
            local rx, ry = (values[6] + values[8]) / 2, (values[7] + values[9]) / 2
            paper:ClearAllPoints(); paper:SetPoint("TOPLEFT", pane, "LEFT", 1, 0); paper:SetPoint("BOTTOMRIGHT", -1, 1)
            paper:SetTexCoord(lx, ly, values[4], values[5], rx, ry, values[8], values[9])
            top:SetPoint("TOPLEFT", 1, -1); top:SetPoint("BOTTOMRIGHT", pane, "RIGHT", -1, 0)
            top:SetTexCoord(values[4], values[5], lx, ly, values[8], values[9], rx, ry)
        else top:Hide() end
    end
    return pane
end
local _, namespace = ...
if type(namespace) == "table" then namespace.UITheme = Theme end
return Theme
