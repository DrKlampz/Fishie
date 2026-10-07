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

-- Choose what the button does right now: put a lure on, or cast. Returns "lure" or "cast".
function C.Prepare()
    if InCombatLockdown and InCombatLockdown() then return nil end
    local lure = F.Gear.LureMacro()
    local macro, what
    if lure then macro, what = lure, "lure" else macro, what = "/cast " .. C.SpellName(), "cast" end
    btn:SetAttribute("macrotext", macro)
    btn:RegisterForClicks(KeyDownMode() and "AnyDown" or "AnyUp")
    return what
end

local function ModHeld()
    local m = F.db and F.db.clickMod or "none"
    if m == "shift" then return IsShiftKeyDown and IsShiftKeyDown() end
    if m == "ctrl" then return IsControlKeyDown and IsControlKeyDown() end
    if m == "alt" then return IsAltKeyDown and IsAltKeyDown() end
    return true
end

-- Arm the button for the click in progress. Returns what it will do, for the log/tests.
function C.Arm()
    if InCombatLockdown and InCombatLockdown() then return nil end
    local G = F.Gear
    if not G.EquippedPole() then
        G.EnsurePole()
        return "pole"
    end
    local what = C.Prepare()
    ClearOverrideBindings(btn)
    SetOverrideBindingClick(btn, true, "BUTTON2", "FishieCastButton")
    armedAt = GetTime()
    clearTimer = clearTimer + 1
    local mine = clearTimer
    C_Timer.After(1.5, function() if mine == clearTimer then Disarm() end end)
    return what
end

-- A key bound to the button (Key Bindings > Fishie) gets the same lure-or-cast choice.
btn:SetScript("PreClick", function() C.Prepare() end)

btn:SetScript("PostClick", function()
    Disarm()
    F.Fire("clicked")
end)

-- The two clicks. WorldFrame only sees clicks that land on the 3D world, not on the UI.
function C.OnWorldDown(button)
    if button ~= "RightButton" then return end
    if not (F.db and F.db.doubleClick) then return end
    if not ModHeld() then F.Debug("modifier not held, ignoring click") return end
    local now = GetTime()
    F.Debug(("world right-click down (%.2fs after the last one)"):format(now - lastUp))
    if now - lastUp <= (F.db.clickWindow or 0.4) and not armedAt then
        local what = C.Arm()
        F.Debug("double-click: " .. tostring(what))
    end
end

function C.OnWorldUp(button)
    if button == "RightButton" then lastUp = GetTime() F.Debug("world right-click up") end
end

BINDING_HEADER_FISHIE = "Fishie"
_G["BINDING_NAME_CLICK FishieCastButton:LeftButton"] = "Cast Fishing (lure first when needed)"

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

local savedLoot
local function BoostLoot()
    if savedLoot ~= nil or not (F.db and F.db.autoLoot) or not GetCVar then return end
    savedLoot = GetCVar("autoLootDefault")
    SetVol("autoLootDefault", 1)
end
local function RestoreLoot()
    if savedLoot == nil then return end
    SetVol("autoLootDefault", savedLoot)
    savedLoot = nil
end

local function Restore()
    RestoreLoot()
    if not saved then return end
    for k, v in pairs(saved) do SetVol(k, v) end
    saved = nil
end
C.Restore = Restore

local function IsFishingChannel()
    if not UnitChannelInfo then return false end
    local name = UnitChannelInfo("player")
    if not name or F.IsSecret(name) then return false end
    return name == C.SpellName() or name == "Fishing"
end

local FISHING_SET = {}
for _, id in ipairs(FISHING_IDS) do FISHING_SET[id] = true end

-- True while a cast is out or just finished: loot in this window counts as fishing.
F.fishingUntil = 0
function F.IsFishingNow() return GetTime() < F.fishingUntil end

local function CastStarted(spellID)
    if IsFishingChannel() or (spellID and FISHING_SET[spellID]) then
        F.fishingUntil = GetTime() + 30
        F.lastFish = GetTime()
        F.castStart = GetTime()
        BoostLoot()
        Boost()
        F.Fire("cast")
        F.Debug("fishing cast started")
        return true
    end
end

F.On("UNIT_SPELLCAST_CHANNEL_START", function(_, unit, _, spellID)
    if unit ~= "player" then return end
    F.Debug("channel start " .. tostring(spellID))
    CastStarted(spellID)
end)
F.On("UNIT_SPELLCAST_SUCCEEDED", function(_, unit, _, spellID)
    if unit == "player" and spellID and FISHING_SET[spellID] and GetTime() > F.fishingUntil then
        F.Debug("fishing cast succeeded " .. tostring(spellID))
        CastStarted(spellID)
    end
end)
F.On("UNIT_SPELLCAST_CHANNEL_STOP", function(_, unit)
    if unit ~= "player" then return end
    F.Debug("channel stop")
    F.fishingUntil = math.max(F.fishingUntil, GetTime() + 15)   -- the catch arrives just after
    C_Timer.After(0.5, function() if not IsFishingChannel() then Restore() end end)
end)
F.On("PLAYER_LOGOUT", Restore)
F.On("PLAYER_ENTERING_WORLD", function() cachedName = nil end)

---------------------------------------------------------------------------
-- Housekeeping every few seconds: lure warning, and back to normal gear after a quiet spell
---------------------------------------------------------------------------
local warned = false
local function Tick()
    if F.db then
        local left = F.Gear.LureTimeLeft()
        if left and left < 60 and F.db.warnLure and not warned then
            warned = true
            F.Print("Your lure is about to run out.")
        elseif not left or left > 120 then
            warned = false
        end
        local mins = F.db.autoReturn or 0
        if mins > 0 and F.db.fishing and F.lastFish and not F.IsFishingNow()
           and GetTime() - F.lastFish > mins * 60 then
            F.lastFish = nil
            F.Debug("quiet for " .. mins .. " minutes: back to normal gear")
            F.Gear.Switch()
        end
    end
    C_Timer.After(10, Tick)
end
F.AddHook("loaded", function() C_Timer.After(10, Tick) end)
C.Tick = Tick
