-- Fishie catch counter: a small box that stays on screen.
local ADDON_NAME, F = ...
local K = {}
F.Counter = K

local frame
local function Fmt(n) return (tostring(math.floor(n or 0)):reverse():gsub("(%d%d%d)", "%1,"):reverse():gsub("^,", "")) end

local function Build()
    if frame then return frame end
    frame = CreateFrame("Frame", "FishieCounter", UIParent, "BackdropTemplate")
    frame:SetFrameStrata("MEDIUM")
    frame:SetSize(150, 44)
    frame:SetPoint("CENTER", 0, -290)
    frame:SetMovable(true)
    frame:EnableMouse(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetClampedToScreen(true)
    if frame.SetBackdrop then
        frame:SetBackdrop({ bgFile = "Interface\\Tooltips\\UI-Tooltip-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            edgeSize = 10, insets = { left = 3, right = 3, top = 3, bottom = 3 } })
        frame:SetBackdropColor(0, 0, 0, 0.6)
    end
    if F.WinLook then F.WinLook.Attach("counter", frame) end
    frame.text = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    frame.text:SetPoint("CENTER")
    frame.text:SetJustifyH("CENTER")
    frame:SetScript("OnDragStart", function(self) if not F.db.counterLock then self:StartMoving() end end)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, rel, x, y = self:GetPoint()
        F.db.counterPos = { point = point, rel = rel, x = x, y = y }
    end)
    frame:SetScript("OnEnter", function(self)
        local s = F.Log.Session()
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:AddLine("Fishie: this session")
        if #s.order == 0 then GameTooltip:AddLine("Nothing caught yet.", 0.7, 0.7, 0.7) end
        for _, name in ipairs(s.order) do
            local it = s.items[name]
            GameTooltip:AddDoubleLine(name, "x" .. it.count, 1, 1, 1, 1, 1, 1)
        end
        if s.opened > 0 then
            GameTooltip:AddLine(" ")
            GameTooltip:AddDoubleLine("Opened", "x" .. s.opened, 0.2, 0.8, 1, 1, 1, 1)
            for _, name in ipairs(s.openOrder) do
                local o = s.opens[name]
                GameTooltip:AddDoubleLine("  " .. name, "x" .. o.count, 1, 1, 1, 1, 1, 1)
                for _, nm in ipairs(o.order) do GameTooltip:AddDoubleLine("      " .. nm, "x" .. o.loot[nm].count, 0.7, 0.7, 0.7, 0.7, 0.7, 0.7) end
            end
        end
        GameTooltip:AddLine("Right-click to reset the session count.", 0.5, 0.5, 0.5)
        GameTooltip:Show()
    end)
    frame:SetScript("OnLeave", function() GameTooltip:Hide() end)
    frame:SetScript("OnMouseUp", function(_, button)
        if button == "RightButton" then F.Log.ResetSession() K.Refresh() end
    end)
    local p = F.db.counterPos
    if p and p.point then
        frame:ClearAllPoints()
        frame:SetPoint(p.point, UIParent, p.rel or p.point, p.x or 0, p.y or 0)
    end
    return frame
end

function K.Refresh()
    if not (frame and frame:IsShown() and F.db) then return end
    local s = F.Log.Session()
    local line = ("|cff33ccffCaught|r |cffffffff%s|r"):format(Fmt(s.caught))
    if F.db.counterRate and s.caught > 0 then line = line .. ("  |cffaaaaaa(%.0f/hr)|r"):format(F.Log.PerHour()) end
    if F.db.counterTotal then line = line .. ("\n|cffaaaaaaAll time|r |cffffffff%s|r"):format(Fmt(F.db.total)) end
    frame.text:SetText(line)
    frame:SetSize(math.max(110, frame.text:GetStringWidth() + 24), frame.text:GetStringHeight() + 18)
end

local function PoleOK()
    if not F.db.counterPoleOnly then return true end
    local ok, pole = pcall(function() return F.Gear and F.Gear.EquippedPole and F.Gear.EquippedPole() end)
    return ok and pole and true or false
end

function K.Apply()
    if not F.db then return end
    if F.db.showCounter and PoleOK() then
        Build():Show()
        K.Refresh()
    elseif frame then
        frame:Hide()
    end
end

F.AddHook("loaded", function() F.On("PLAYER_LOGIN", K.Apply) end)
F.On("PLAYER_EQUIPMENT_CHANGED", function() K.Apply() end)
-- the number changes whenever a catch is recorded or the session is reset
do
    local rec, reset = F.Log.Record, F.Log.ResetSession
    F.Log.Record = function(...) rec(...) K.Refresh() end
    F.Log.ResetSession = function(...) reset(...) K.Refresh() end
end
