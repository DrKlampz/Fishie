-- Fishie: a fishing helper for WoW: Forever, in the spirit of Fishing Buddy.
-- Core.lua holds settings, shared helpers, events and the slash command.
local ADDON_NAME, F = ...
F.name = ADDON_NAME

local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) end
F.IsSecret = IsSecret
local function Trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
F.Trim = Trim

F.DEFAULTS = {
    doubleClick = true,       -- double right-click in the world casts Fishing
    castClicks = 1,           -- 1 = single right-click casts (pole in hand), 2 = double right-click
    clickWindow = 0.4,        -- seconds allowed between the two clicks
    autoLure = true,          -- put a lure on the pole before casting when it has none
    autoPole = true,          -- equip a pole (your fishing outfit) when you double-click without one
    boostSound = true,        -- turn up effects and turn down music/ambience while fishing
    announce = true,          -- one line in chat for each catch
    debug = false,            -- /fishie debug: explain what Fishie sees in chat
    clickMod = "none",        -- hold shift / ctrl / alt for the double-click to count ("none" = no key)
    lureChoice = "best",      -- "best" or "weakest" lure first
    refreshLure = true,       -- put a new lure on when the old one has under a minute left
    warnLure = true,          -- chat warning when the lure is about to run out
    autoCatch = true,         -- while the line is out, right-click loots the bobber without aiming
    autoLoot = true,          -- turn on auto-loot while fishing, then put it back
    autoReturn = 0,           -- minutes without fishing before the normal outfit comes back (0 = never)
    showHUD = false,          -- small on-screen box with the cast timer, lure and catches
    hudPos = {},              -- where you dragged the HUD
    outfit = {},              -- [slot] = item link, the gear you want on while fishing
    normal = {},              -- [slot] = item link, what you had on before switching
    fishing = false,          -- true while the fishing outfit is on
    fish = {},                -- [zone] = { [itemName] = { count = n, link = "..." } }
    total = 0,                -- fish and other items ever caught
    minimap = { show = true, angle = 150 },
}

local function Merge(dst, src)
    for k, v in pairs(src) do
        if type(v) == "table" then
            if type(dst[k]) ~= "table" then dst[k] = {} end
            if k ~= "outfit" and k ~= "normal" and k ~= "fish" then Merge(dst[k], v) end
        elseif dst[k] == nil then
            dst[k] = v
        end
    end
    return dst
end

function F.Print(msg) print("|cff33ccffFishie:|r " .. tostring(msg)) end
local Print = F.Print

function F.Debug(msg)
    if F.db and F.db.debug then print("|cff888888Fishie debug:|r " .. tostring(msg)) end
end

local reported = {}
function F.ReportError(what, err)
    if reported[what] then return end
    reported[what] = true
    Print(("|cffff5555Something went wrong in %s:|r %s"):format(what, tostring(err)))
end

-- Modules register for start-up and for game events.
local hooks, handlers = {}, {}
function F.AddHook(name, fn) hooks[name] = hooks[name] or {}; table.insert(hooks[name], fn) end
function F.Fire(name, ...)
    for _, fn in ipairs(hooks[name] or {}) do
        local ok, err = pcall(fn, ...)
        if not ok then F.ReportError("Fishie (" .. name .. ")", err) end
    end
end
local frame = CreateFrame("Frame")
function F.On(event, fn)
    handlers[event] = handlers[event] or {}
    table.insert(handlers[event], fn)
    pcall(frame.RegisterEvent, frame, event)
end
frame:SetScript("OnEvent", function(_, event, ...)
    if event == "ADDON_LOADED" then
        if (...) ~= ADDON_NAME then return end
        FishieDB = FishieDB or {}
        F.db = Merge(FishieDB, F.DEFAULTS)
        F.Fire("loaded")
        return
    end
    for _, fn in ipairs(handlers[event] or {}) do
        local ok, err = pcall(fn, event, ...)
        if not ok then F.ReportError("Fishie (" .. event .. ")", err) end
    end
end)
frame:RegisterEvent("ADDON_LOADED")

-- Things that can't change in combat wait until it ends.
local waiting = {}
function F.AfterCombat(fn)
    if InCombatLockdown and InCombatLockdown() then
        table.insert(waiting, fn)
        return false
    end
    fn()
    return true
end
F.On("PLAYER_REGEN_ENABLED", function()
    local list = waiting
    waiting = {}
    for _, fn in ipairs(list) do fn() end
end)

---------------------------------------------------------------------------
-- Slash command
---------------------------------------------------------------------------
local TOGGLES = {
    doubleclick = { "doubleClick", "Right-click to cast" },
    lure = { "autoLure", "Automatic lures" },
    pole = { "autoPole", "Equip a pole when you click without one" },
    sound = { "boostSound", "Fishing sound boost" },
    announce = { "announce", "Chat line for each catch" },
    refreshlure = { "refreshLure", "Replace a lure that is about to run out" },
    warnlure = { "warnLure", "Warn when the lure is about to run out" },
    autocatch = { "autoCatch", "Right-click loots the bobber while fishing" },
    autoloot = { "autoLoot", "Auto-loot while fishing" },
    hud = { "showHUD", "On-screen fishing box" },
}

SLASH_FISHIE1 = "/fishie"
SLASH_FISHIE2 = "/fish"
SlashCmdList.FISHIE = function(input)
    local cmd, rest = Trim(input):match("^(%S*)%s*(.-)$")
    cmd = cmd:lower()
    if cmd == "" or cmd == "show" then
        if F.UI then F.UI.Toggle() end
    elseif cmd == "switch" then
        F.Gear.Switch()
    elseif cmd == "save" then
        F.Gear.SaveOutfit()
    elseif cmd == "applylure" then
        F.Gear.ApplyLureNow()
    elseif cmd == "stats" then
        F.Log.PrintSession()
    elseif cmd == "reset" then
        F.Log.ResetSession()
        Print("Session stats reset.")
    elseif TOGGLES[cmd] then
        local key, label = TOGGLES[cmd][1], TOGGLES[cmd][2]
        local v = rest:lower()
        if v == "on" then F.db[key] = true elseif v == "off" then F.db[key] = false else F.db[key] = not F.db[key] end
        Print(label .. ": " .. (F.db[key] and "on" or "off"))
        if F.UI then F.UI.Refresh() end
    elseif cmd == "minimap" then
        F.db.minimap.show = not F.db.minimap.show
        Print("Minimap button " .. (F.db.minimap.show and "shown (reload to bring it back)." or "hidden."))
        if F.UI and F.UI.UpdateMinimap then F.UI.UpdateMinimap() end
    elseif cmd == "debug" then
        local v = rest:lower()
        if v == "on" then F.db.debug = true elseif v == "off" then F.db.debug = false else F.db.debug = not F.db.debug end
        Print("Debug " .. (F.db.debug and "on: Fishie explains every click, cast and catch it sees." or "off"))
    elseif cmd == "release" then
        if F.Cast.CatchOff then F.Cast.CatchOff() end
        if F.Cast.Release then F.Cast.Release() end
        Print("Right-click released.")
    elseif cmd == "probe" then
        F.Gear.Probe()
    else
        Print("/fishie - open the window")
        Print("/fishie switch - put on your fishing outfit, or take it off")
        Print("/fishie save - remember what you're wearing as your fishing outfit")
        Print("/fishie stats | reset - this session's catches")
        Print("/fishie applylure - put a lure on your pole now (use from a macro or button)")
        Print("/fishie doubleclick | lure | pole | sound | announce | refreshlure | warnlure | autocatch | autoloot | hud [on|off]")
        Print("/fishie minimap - show or hide the minimap button")
        Print("/fishie debug [on|off] - explain every click, cast and catch in chat")
        Print("/fishie release - give right-click back to the game if it ever feels stuck")
        Print("/fishie probe - show what the game reports about your pole and lures")
    end
end
