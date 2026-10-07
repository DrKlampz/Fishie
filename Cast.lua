-- Fishie casting: double right-click anywhere in the world to cast Fishing.
--
-- How it works: a secure button casts the spell. The second right-click of a double-click
-- temporarily binds the right mouse button to that secure button, so the click that is
-- already happening (its release, or press, depending on your key-down setting) is what
-- the game sees as the hardware event for the cast. The binding is removed right after.
local ADDON_NAME, F = ...
local C = {}
F.Cast = C

local FISHING_IDS = { 7620, 7731, 7732, 18248, 33095, 51294, 131474 }   -- every rank of Fishing
local cachedName

function C.SpellName()
    if cachedName then return cachedName end
    for i = #FISHING_IDS, 1, -1 do
        local id = FISHING_IDS[i]
        local known = (C_SpellBook and C_SpellBook.IsSpellKnown and C_SpellBook.IsSpellKnown(id))
            or (IsSpellKnown and IsSpellKnown(id)) or (IsPlayerSpell and IsPlayerSpell(id))
        if known then
            local name
            if C_Spell and C_Spell.GetSpellName then name = C_Spell.GetSpellName(id)
            elseif GetSpellInfo then name = GetSpellInfo(id) end
            if name and name ~= "" then cachedName = name return name end
        end
    end
    return "Fishing"
end

local btn = CreateFrame("Button", "FishieCastButton", UIParent, "SecureActionButtonTemplate")
btn:SetSize(1, 1)
btn:SetPoint("BOTTOMLEFT", -10, -10)
btn:SetAttribute("type", "macro")
btn:SetAttribute("macrotext", "/cast Fishing")

local armedAt, clearTimer = nil, 0
local lastUp = 0

local function Disarm()
    if InCombatLockdown and InCombatLockdown() then return end
    ClearOverrideBindings(btn)
    armedAt = nil
end

local function KeyDownMode()
    return GetCVar and GetCVar("ActionButtonUseKeyDown") == "1"
end

-- Arm the button for the click in progress. Returns what it will do, for the log/tests.
function C.Arm()
    if InCombatLockdown and InCombatLockdown() then return nil end
    local G = F.Gear
    if not G.EquippedPole() then
        G.EnsurePole()
        return "pole"
    end
    local lure = G.LureMacro()
    local macro, what
    if lure then macro, what = lure, "lure" else macro, what = "/cast " .. C.SpellName(), "cast" end
    btn:SetAttribute("macrotext", macro)
    btn:RegisterForClicks(KeyDownMode() and "AnyDown" or "AnyUp")
    ClearOverrideBindings(btn)
    SetOverrideBindingClick(btn, true, "BUTTON2", "FishieCastButton")
    armedAt = GetTime()
    clearTimer = clearTimer + 1
    local mine = clearTimer
    C_Timer.After(1.5, function() if mine == clearTimer then Disarm() end end)
    return what
end

btn:SetScript("PostClick", function()
    Disarm()
    F.Fire("clicked")
end)

-- The two clicks. WorldFrame only sees clicks that land on the 3D world, not on the UI.
function C.OnWorldDown(button)
    if button ~= "RightButton" then return end
    if not (F.db and F.db.doubleClick) then return end
    local now = GetTime()
    if now - lastUp <= (F.db.clickWindow or 0.4) and not armedAt then
        C.Arm()
    end
end

function C.OnWorldUp(button)
    if button == "RightButton" then lastUp = GetTime() end
end

if WorldFrame then
    WorldFrame:HookScript("OnMouseDown", function(_, button) C.OnWorldDown(button) end)
    WorldFrame:HookScript("OnMouseUp", function(_, button) C.OnWorldUp(button) end)
end

---------------------------------------------------------------------------
-- Sound: make the splash audible while fishing, put it back afterwards
---------------------------------------------------------------------------
local saved
local function SetVol(name, v)
    if SetCVar then pcall(SetCVar, name, v) end
end

local function Boost()
    if saved or not (F.db and F.db.boostSound) or not GetCVar then return end
    saved = {
        Sound_SFXVolume = GetCVar("Sound_SFXVolume"),
        Sound_MusicVolume = GetCVar("Sound_MusicVolume"),
        Sound_AmbienceVolume = GetCVar("Sound_AmbienceVolume"),
    }
    SetVol("Sound_SFXVolume", 1)
    SetVol("Sound_MusicVolume", 0)
    SetVol("Sound_AmbienceVolume", 0)
end

local function Restore()
    if not saved then return end
    for k, v in pairs(saved) do SetVol(k, v) end
    saved = nil
end
C.Restore = Restore

local function IsFishingChannel()
    if not UnitChannelInfo then return false end
    local name = UnitChannelInfo("player")
    if not name or F.IsSecret(name) then return false end
    return name == C.SpellName()
end

F.On("UNIT_SPELLCAST_CHANNEL_START", function(_, unit)
    if unit ~= "player" then return end
    if IsFishingChannel() then
        Boost()
        F.Fire("cast")
    end
end)
F.On("UNIT_SPELLCAST_CHANNEL_STOP", function(_, unit)
    if unit ~= "player" then return end
    C_Timer.After(0.5, function() if not IsFishingChannel() then Restore() end end)
end)
F.On("PLAYER_LOGOUT", Restore)
F.On("PLAYER_ENTERING_WORLD", function() cachedName = nil end)
