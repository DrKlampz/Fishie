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

local function Check(parent, text, get, set)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(24, 24)
    if cb.text then cb.text:SetText("") end
    if cb.Text then cb.Text:SetText("") end
    local l = Label(cb, "GameFontHighlight", text)
    l:SetPoint("LEFT", cb, "RIGHT", 2, 1)
    cb:SetScript("OnClick", function(self) set(self:GetChecked() and true or false) end)
    cb.get = get
    return cb
end

-- A button that steps through a list of choices and shows the current one.
local function Cycle(parent, label, choices, get, set)
    local row = CreateFrame("Frame", nil, parent)
    row:SetSize(400, 24)
    local fs = Label(row, "GameFontHighlight", label)
    fs:SetPoint("LEFT", 4, 0)
    local b = Button(row, "", 110, nil)
    b:SetPoint("RIGHT", 0, 0)
    b:SetScript("OnClick", function()
        local cur, idx = get(), 1
        for i, c in ipairs(choices) do if c[1] == cur then idx = i end end
        local nxt = choices[idx % #choices + 1]
        set(nxt[1])
        b:SetText(nxt[2])
    end)
    function row.Refresh()
        local cur = get()
        for _, c in ipairs(choices) do if c[1] == cur then b:SetText(c[2]) return end end
        b:SetText(choices[1][2])
    end
    return row
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
    local function dbkey(k) return function() return F.db[k] end, function(v) F.db[k] = v end end
    local opts = {
        { "Double right-click to cast", "doubleClick" },
        { "Put a lure on the pole when it has none", "autoLure" },
        { "Replace a lure that is about to run out", "refreshLure" },
        { "Warn when the lure is about to run out", "warnLure" },
        { "Equip a pole when you double-click without one", "autoPole" },
        { "Right-click loots the bobber (no aiming)", "autoCatch" },
        { "Auto-loot while fishing", "autoLoot" },
        { "Turn up effects, turn down music while fishing", "boostSound" },
        { "Chat line for each catch", "announce" },
        { "Show the on-screen fishing box", "showHUD" },
    }
    p.rows = {}
    local y = 0
    for _, o in ipairs(opts) do
        local get, set = dbkey(o[2])
        local c = Check(p, o[1], get, function(v) set(v) if UI.ApplyHUD then UI.ApplyHUD() end end)
        c:SetPoint("TOPLEFT", 0, y)
        p.rows[#p.rows + 1] = c
        y = y - 25
    end
    local mm = Check(p, "Show the minimap button", function() return F.db.minimap.show end,
        function(v) F.db.minimap.show = v UI.UpdateMinimap() end)
    mm:SetPoint("TOPLEFT", 0, y) p.rows[#p.rows + 1] = mm
    y = y - 32

    local speed = Cycle(p, "Double-click speed", {
        { 0.25, "fast (0.25s)" }, { 0.4, "normal (0.4s)" }, { 0.6, "slow (0.6s)" }, { 0.8, "slower (0.8s)" } },
        function() return F.db.clickWindow end, function(v) F.db.clickWindow = v end)
    speed:SetPoint("TOPLEFT", 0, y) p.rows[#p.rows + 1] = speed y = y - 28
    local mod = Cycle(p, "Hold a key while double-clicking", {
        { "none", "no key" }, { "shift", "Shift" }, { "ctrl", "Ctrl" }, { "alt", "Alt" } },
        function() return F.db.clickMod end, function(v) F.db.clickMod = v end)
    mod:SetPoint("TOPLEFT", 0, y) p.rows[#p.rows + 1] = mod y = y - 28
    local lure = Cycle(p, "Lure to use first", { { "best", "strongest" }, { "weakest", "weakest" } },
        function() return F.db.lureChoice end, function(v) F.db.lureChoice = v end)
    lure:SetPoint("TOPLEFT", 0, y) p.rows[#p.rows + 1] = lure y = y - 28
    local back = Cycle(p, "Back to normal gear after", {
        { 0, "never" }, { 5, "5 minutes" }, { 10, "10 minutes" }, { 20, "20 minutes" } },
        function() return F.db.autoReturn end, function(v) F.db.autoReturn = v end)
    back:SetPoint("TOPLEFT", 0, y) p.rows[#p.rows + 1] = back y = y - 34

    local note = Label(p, "GameFontDisableSmall", "The game needs a real click for each cast, so casting is never fully automatic.\nBind a key under Options > Key Bindings > Fishie to cast without the mouse.")
    note:SetPoint("TOPLEFT", 0, y)
    note:SetWidth(400)
    function p.Refresh()
        for _, r in ipairs(p.rows) do
            if r.get then r:SetChecked(r.get() and true or false) elseif r.Refresh then r.Refresh() end
        end
    end
end

---------------------------------------------------------------------------
-- The on-screen fishing box: cast timer, lure time left and this session's catches
---------------------------------------------------------------------------
local hud
local function BuildHUD()
    if hud then return hud end
    hud = CreateFrame("Frame", "FishieHUD", UIParent, "BackdropTemplate")
    hud:SetSize(190, 74)
    hud:SetPoint("CENTER", 0, -220)
    hud:SetMovable(true)
    hud:EnableMouse(true)
    hud:RegisterForDrag("LeftButton")
    hud:SetClampedToScreen(true)
    if hud.SetBackdrop then
        hud:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 12, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        hud:SetBackdropColor(0, 0, 0, 0.6)
    end
    hud.text = Label(hud, "GameFontHighlightSmall")
    hud.text:SetPoint("TOPLEFT", 8, -8)
    hud.text:SetWidth(176)
    hud.text:SetSpacing(3)
    hud:SetScript("OnDragStart", hud.StartMoving)
    hud:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, rel, x, y = self:GetPoint()
        F.db.hudPos = { point = point, rel = rel, x = x, y = y }
    end)
    local acc = 0
    hud:SetScript("OnUpdate", function(_, dt)
        acc = acc + dt
        if acc < 0.5 then return end
        acc = 0
        local s = F.Log.Session()
        local cast = "-"
        if F.castStart and F.IsFishingNow() then cast = F.Log.FormatTime(GetTime() - F.castStart) end
        local left = F.Gear.LureTimeLeft()
        local lure = left and (left > 9000 and "on" or F.Log.FormatTime(left)) or "|cff888888none|r"
        hud.text:SetText(("|cff33ccffFishie|r\nSince cast: |cffffffff%s|r\nLure: |cffffffff%s|r\nCaught: |cffffffff%d|r  (%.0f/hr)"):format(
            cast, lure, s.caught, F.Log.PerHour()))
    end)
    local p = F.db.hudPos
    if p and p.point then
        hud:ClearAllPoints()
        hud:SetPoint(p.point, UIParent, p.rel or p.point, p.x or 0, p.y or 0)
    end
    return hud
end

function UI.ApplyHUD()
    if not F.db then return end
    if F.db.showHUD then BuildHUD():Show() elseif hud then hud:Hide() end
end
F.AddHook("loaded", function() F.On("PLAYER_LOGIN", UI.ApplyHUD) end)

local function Show(key)
    current = key
    for k, p in pairs(panels) do p:SetShown(k == key) end
    for k, b in pairs(tabs) do if k == key then b:LockHighlight() else b:UnlockHighlight() end end
    UI.Refresh()
end

local function Build()
    if frame then return end
    frame = CreateFrame("Frame", "FishieFrame", UIParent, "BasicFrameTemplateWithInset")
    frame:SetSize(440, 540)
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

function UI.UpdateMinimap()
    if F.db.minimap.show then
        MakeMinimap()
        if btn then btn:Show() end
    elseif btn then
        btn:Hide()
    end
end

F.AddHook("loaded", function() F.On("PLAYER_LOGIN", MakeMinimap) end)

function Fishie_OnAddonCompartmentClick() UI.Toggle() end
