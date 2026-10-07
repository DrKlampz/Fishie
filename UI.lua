-- Fishie window: session stats, catch log and settings. Plain frames, no libraries.
local ADDON_NAME, F = ...
local UI = {}
F.UI = UI

local frame, tabs, panels, current = nil, {}, {}, "session"

local function FishingSkill()
    if GetProfessions and GetProfessionInfo then
        local _, _, _, fishing = GetProfessions()
        if fishing then
            local name, _, rank, maxRank = GetProfessionInfo(fishing)
            return name, rank, maxRank
        end
    end
    if GetNumSkillLines and GetSkillLineInfo then
        for i = 1, GetNumSkillLines() do
            local name, isHeader, _, rank, _, _, maxRank = GetSkillLineInfo(i)
            if not isHeader and name and name == (F.Cast and F.Cast.SpellName() or "Fishing") then
                return name, rank, maxRank
            end
        end
    end
end
UI.FishingSkill = FishingSkill

local function Label(parent, font, text)
    local fs = parent:CreateFontString(nil, "OVERLAY", font or "GameFontHighlight")
    if text then fs:SetText(text) end
    fs:SetJustifyH("LEFT")
    return fs
end

local function Button(parent, text, w, onClick)
    local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    b:SetSize(w, 22)
    b:SetText(text)
    b:SetScript("OnClick", onClick)
    return b
end

local function Check(parent, text, key)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    if cb.text then cb.text:SetText("") end
    if cb.Text then cb.Text:SetText("") end
    local l = Label(cb, "GameFontHighlight", text)
    l:SetPoint("LEFT", cb, "RIGHT", 2, 1)
    cb:SetScript("OnClick", function(self) F.db[key] = self:GetChecked() and true or false end)
    cb.key = key
    return cb
end

local function PoleLine()
    local G = F.Gear
    local pole = G.EquippedPole()
    if not pole then return "|cffff9933No fishing pole equipped|r" end
    local line = pole
    if GetWeaponEnchantInfo then
        local has, exp = GetWeaponEnchantInfo()
        if has then line = line .. ("  |cff55ff55lure on (%s)|r"):format(exp and (math.floor(exp / 60000) .. " min") or "?")
        else
            local id = G.BestLure()
            line = line .. (id and "  |cffffd100no lure (one is ready)|r" or "  |cff888888no lure|r")
        end
    end
    return line
end

local function BuildSession(p)
    p.skill = Label(p, "GameFontNormalLarge")
    p.skill:SetPoint("TOPLEFT", 0, 0)
    p.pole = Label(p, "GameFontHighlight")
    p.pole:SetPoint("TOPLEFT", p.skill, "BOTTOMLEFT", 0, -6)
    p.pole:SetWidth(400)
    p.stats = Label(p, "GameFontHighlight")
    p.stats:SetPoint("TOPLEFT", p.pole, "BOTTOMLEFT", 0, -10)
    p.stats:SetSpacing(4)
    p.list = Label(p, "GameFontHighlightSmall")
    p.list:SetPoint("TOPLEFT", p.stats, "BOTTOMLEFT", 0, -12)
    p.list:SetWidth(400)
    p.list:SetSpacing(3)
    p.switch = Button(p, "Fishing outfit", 130, function() F.Gear.Switch() end)
    p.switch:SetPoint("BOTTOMLEFT", 0, 0)
    p.save = Button(p, "Save outfit", 100, function() F.Gear.SaveOutfit() end)
    p.save:SetPoint("LEFT", p.switch, "RIGHT", 6, 0)
    p.reset = Button(p, "Reset session", 110, function() F.Log.ResetSession() UI.Refresh() end)
    p.reset:SetPoint("LEFT", p.save, "RIGHT", 6, 0)

    function p.Refresh()
        local name, rank, maxRank = FishingSkill()
        p.skill:SetText(name and ("%s |cffffd100%d|r/%d"):format(name, rank or 0, maxRank or 0) or "Fishing")
        p.pole:SetText(PoleLine())
        local s = F.Log.Session()
        p.stats:SetText(("Time: |cffffffff%s|r\nCasts: |cffffffff%d|r\nCaught: |cffffffff%d|r   (%.0f per hour)\nAll time: |cffffffff%d|r"):format(
            F.Log.FormatTime(F.Log.Elapsed()), s.casts, s.caught, F.Log.PerHour(), F.db.total or 0))
        local lines = {}
        for i, nm in ipairs(s.order) do
            if i > 12 then lines[#lines + 1] = "..." break end
            lines[#lines + 1] = ("%s x%d"):format(s.items[nm].link or nm, s.items[nm].count)
        end
        p.list:SetText(#lines > 0 and table.concat(lines, "\n") or "|cff888888Nothing caught yet. Double right-click to cast.|r")
        p.switch:SetText(F.db.fishing and "Normal gear" or "Fishing outfit")
    end
end

local function BuildCatches(p)
    p.head = Label(p, "GameFontNormal")
    p.head:SetPoint("TOPLEFT", 0, 0)
    p.here = Label(p, "GameFontHighlightSmall")
    p.here:SetPoint("TOPLEFT", p.head, "BOTTOMLEFT", 0, -6)
    p.here:SetWidth(400)
    p.here:SetSpacing(3)
    p.zhead = Label(p, "GameFontNormal", "Best zones")
    p.zhead:SetPoint("TOPLEFT", p.here, "BOTTOMLEFT", 0, -14)
    p.zones = Label(p, "GameFontHighlightSmall")
    p.zones:SetPoint("TOPLEFT", p.zhead, "BOTTOMLEFT", 0, -6)
    p.zones:SetWidth(400)
    p.zones:SetSpacing(3)
    function p.Refresh()
        local zone = (GetRealZoneText and GetRealZoneText()) or "Unknown"
        p.head:SetText(zone)
        local list, lines = F.Log.ZoneList(zone), {}
        for i, e in ipairs(list) do
            if i > 12 then lines[#lines + 1] = "..." break end
            lines[#lines + 1] = ("%s x%d"):format(e.link or e.name, e.count)
        end
        p.here:SetText(#lines > 0 and table.concat(lines, "\n") or "|cff888888Nothing caught here yet.|r")
        local zs, zl = F.Log.Zones(), {}
        for i, z in ipairs(zs) do
            if i > 8 then break end
            zl[#zl + 1] = ("%s |cff888888(%d)|r"):format(z.zone, z.total)
        end
        p.zones:SetText(#zl > 0 and table.concat(zl, "\n") or "|cff888888No catches recorded yet.|r")
    end
end

local function BuildSetup(p)
    local opts = {
        { "Double right-click to cast", "doubleClick" },
        { "Put a lure on the pole when it has none", "autoLure" },
        { "Equip a pole when you double-click without one", "autoPole" },
        { "Turn up effects, turn down music while fishing", "boostSound" },
        { "Chat line for each catch", "announce" },
    }
    p.checks = {}
    for i, o in ipairs(opts) do
        local c = Check(p, o[1], o[2])
        c:SetPoint("TOPLEFT", 0, -(i - 1) * 28)
        p.checks[i] = c
    end
    local note = Label(p, "GameFontDisableSmall", "Double-click means two right-clicks on the world within about 0.4 seconds.\nThe game needs a real click for each cast, so there is no fully automatic casting.")
    note:SetPoint("TOPLEFT", 0, -(#opts) * 28 - 10)
    note:SetWidth(400)
    function p.Refresh()
        for _, c in ipairs(p.checks) do c:SetChecked(F.db[c.key] and true or false) end
    end
end

local function Show(key)
    current = key
    for k, p in pairs(panels) do p:SetShown(k == key) end
    for k, b in pairs(tabs) do if k == key then b:LockHighlight() else b:UnlockHighlight() end end
    UI.Refresh()
end

local function Build()
    if frame then return end
    frame = CreateFrame("Frame", "FishieFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(440, 360)
    frame:SetPoint("CENTER", 200, 0)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
    frame:SetClampedToScreen(true)
    if frame.TitleText then frame.TitleText:SetText("|cff33ccffFishie|r") end
    if UISpecialFrames then table.insert(UISpecialFrames, "FishieFrame") end

    local x = 12
    for _, t in ipairs({ { "session", "Session" }, { "catches", "Catches" }, { "setup", "Setup" } }) do
        local b = Button(frame, t[2], 90, function() Show(t[1]) end)
        b:SetPoint("TOPLEFT", x, -30)
        tabs[t[1]] = b
        x = x + 94
        local p = CreateFrame("Frame", nil, frame)
        p:SetPoint("TOPLEFT", 16, -62)
        p:SetPoint("BOTTOMRIGHT", -16, 14)
        panels[t[1]] = p
    end
    BuildSession(panels.session)
    BuildCatches(panels.catches)
    BuildSetup(panels.setup)
    frame:SetScript("OnUpdate", function(self, dt)
        self.t = (self.t or 0) + dt
        if self.t > 1 then self.t = 0 UI.Refresh() end
    end)
    Show("session")
    frame:Hide()
end

function UI.Refresh()
    if not (frame and frame:IsShown() and F.db) then return end
    local p = panels[current]
    if p and p.Refresh then p.Refresh() end
end

function UI.Toggle()
    Build()
    frame:SetShown(not frame:IsShown())
    UI.Refresh()
end

---------------------------------------------------------------------------
-- Minimap button: left-click opens the window, right-click switches outfit
---------------------------------------------------------------------------
local btn
local function Place(angle)
    local a = math.rad(angle or F.db.minimap.angle or 150)
    local r = (Minimap:GetWidth() / 2) + 5
    btn:ClearAllPoints()
    btn:SetPoint("CENTER", Minimap, "CENTER", math.cos(a) * r, math.sin(a) * r)
end

local function DragUpdate()
    local mx, my = Minimap:GetCenter()
    local scale = Minimap:GetEffectiveScale()
    local cx, cy = GetCursorPosition()
    local atan2 = math.atan2 or atan2
    local angle = math.deg(atan2(cy / scale - my, cx / scale - mx)) % 360
    F.db.minimap.angle = angle
    Place(angle)
end

local function MakeMinimap()
    if btn or not Minimap or not F.db.minimap.show then return end
    btn = CreateFrame("Button", "FishieMinimapButton", Minimap)
    btn:SetSize(31, 31)
    btn:SetFrameStrata("MEDIUM")
    btn:SetFrameLevel((Minimap:GetFrameLevel() or 1) + 8)
    btn:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    btn:RegisterForDrag("LeftButton")
    local bg = btn:CreateTexture(nil, "BACKGROUND")
    bg:SetSize(22, 22) bg:SetPoint("CENTER")
    bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(20, 20) icon:SetPoint("CENTER")
    icon:SetTexture("Interface\\Icons\\Trade_Fishing")
    local border = btn:CreateTexture(nil, "OVERLAY")
    border:SetSize(52, 52) border:SetPoint("TOPLEFT")
    border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
    btn:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight", "ADD")
    btn:SetScript("OnDragStart", function(self) self:SetScript("OnUpdate", DragUpdate) end)
    btn:SetScript("OnDragStop", function(self) self:SetScript("OnUpdate", nil) end)
    btn:SetScript("OnClick", function(_, b)
        GameTooltip:Hide()
        if b == "RightButton" then F.Gear.Switch() else UI.Toggle() end
    end)
    btn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:AddLine("|cff33ccffFishie|r")
        GameTooltip:AddLine("Left-click: window", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Right-click: fishing outfit on/off", 0.9, 0.9, 0.9)
        GameTooltip:AddLine("Drag: move this button", 0.6, 0.6, 0.6)
        GameTooltip:Show()
    end)
    btn:SetScript("OnLeave", function() GameTooltip:Hide() end)
    Place()
end

F.AddHook("loaded", function() F.On("PLAYER_LOGIN", MakeMinimap) end)

function Fishie_OnAddonCompartmentClick() UI.Toggle() end
