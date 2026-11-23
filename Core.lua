-- Fishie: a fishing helper for WoW: Forever, in the spirit of Fishing Buddy.
-- Core.lua holds settings, shared helpers, events and the slash command.
local ADDON_NAME, F = ...
F.name = ADDON_NAME

local function IsSecret(v) return issecretvalue ~= nil and issecretvalue(v) end
F.IsSecret = IsSecret
local function Trim(s) return (tostring(s or ""):gsub("^%s+", ""):gsub("%s+$", "")) end
F.Trim = Trim

F.DEFAULTS = {
    poolNeedProf = true,      -- only show pool icons for a character that has Fishing
    poolLearn = true,         -- remember the spots and pools you fish
    poolMap = true,           -- pool and spot icons on the world map
    poolMini = true,          -- ...and on the minimap
    poolSpawns = true,        -- pool spawn points from ForeverDB.net
    poolClassic = true,       -- include Classic spawn points nobody has seen in Forever
    poolFar = false,          -- icons when zoomed out to a continent or the world
    poolSize = 14, poolMiniSize = 14, poolAlpha = 1, poolMax = 300,
    zoneInfo = true,          -- zone fish guide on the world map
    doubleClick = true,       -- double right-click in the world casts Fishing
    castButton = "BUTTON2",   -- mouse button that casts / loots: BUTTON1 left, BUTTON2 right, BUTTON3 middle, BUTTON4/5 side buttons
    castClicks = 1,           -- 1 = single right-click casts (pole in hand), 2 = double right-click
    clickWindow = 0.4,        -- seconds allowed between the two clicks
    autoLure = true,          -- put a lure on the pole before casting when it has none
    autoPole = true,          -- equip a pole (your fishing outfit) when you double-click without one
    boostSound = true,        -- turn up effects and turn down music/ambience while fishing
    muffle = true,            -- music, ambience and voices turned down while a fishing pole is equipped
    muffleLevel = 0.25,       -- how much of their normal volume is left (0 = silent)
    announce = true,          -- one line in chat for each catch
    debug = false,            -- /fishie debug: explain what Fishie sees in chat
    clickMod = "none",        -- hold shift / ctrl / alt for the double-click to count ("none" = no key)
    lureChoice = "best",      -- "best" or "weakest" lure first
    refreshLure = true,       -- put a new lure on when the old one has under a minute left
    warnLure = true,          -- chat warning when the lure is about to run out
    catchDelay = 3,           -- seconds after a cast during which right-click does nothing (fish do not bite that fast)
    catchJitter = 1.5,        -- up to this many extra random seconds added to the wait, different every cast
    autoCatch = true,         -- while the line is out, right-click loots the bobber without aiming
    autoLoot = true,          -- turn on auto-loot while fishing, then put it back
    autoReturn = 0,           -- minutes without fishing before the normal outfit comes back (0 = never)
    showHUD = false,          -- small on-screen box with the cast timer, lure and catches
    showCounter = true,       -- small always-on box with the number of fish caught
    counterPoleOnly = true,   -- counter: only show it while a fishing pole is equipped
    counterTotal = true,      -- counter: also show the all-time total
    counterRate = true,       -- counter: also show catches per hour
    counterLock = false,      -- counter: stop it being dragged
    counterPos = {},          -- where you dragged the counter
    hudPos = {},              -- where you dragged the HUD
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

---------------------------------------------------------------------------
-- What belongs to one character (its fishing outfit, the gear it normally wears, its catch log and totals)
-- is kept under FishieDB.chars[character]. Everything else (options, looks) is shared by all characters.
-- Code keeps writing F.db.outfit, F.db.fish and so on; this routes them to the character that is playing.
---------------------------------------------------------------------------
local PERCHAR = { outfit = true, normal = true, normalWeapon = true, fishing = true, fish = true, total = true }

local function CharName()
    local first, second = UnitName("player")
    if type(first) ~= "string" or first == "" or first == "Unknown" or first == _G.UNKNOWNOBJECT then return nil end
    -- some servers give characters two names; UnitName hands the last one back in the realm slot
    if type(second) == "string" and second ~= "" and not first:find(" ", 1, true) then
        local r1 = GetRealmName and GetRealmName()
        local r2 = GetNormalizedRealmName and GetNormalizedRealmName()
        if second ~= r1 and second ~= r2 then return first .. " " .. second end
    end
    return first
end

local scratch = { outfit = {}, normal = {}, fish = {}, total = 0, fishing = false }
local mineKey
local function Mine()
    local db = FishieDB
    if mineKey and db.chars and db.chars[mineKey] then return db.chars[mineKey] end
    local name = CharName()
    if not name then return scratch end
    local realm = GetRealmName and GetRealmName()
    if type(realm) == "string" and realm ~= "" then db.lastRealm = realm else realm = db.lastRealm or "" end
    local key = name .. "-" .. realm
    db.chars = db.chars or {}
    local c = db.chars[key]
    if not c then
        c = { outfit = {}, normal = {}, fish = {}, total = 0, fishing = false }
        db.chars[key] = c
        -- data saved before this was split by character goes to the first character that plays
        if not db.perCharMoved then
            db.perCharMoved = true
            for k in pairs(PERCHAR) do
                local v = rawget(db, k)
                if v ~= nil then c[k] = v rawset(db, k, nil) end
            end
        end
    end
    mineKey = key
    return c
end
F.Mine = Mine

local dbMeta = {
    __index = function(_, k) if PERCHAR[k] then return Mine()[k] end end,
    __newindex = function(t, k, v) if PERCHAR[k] then Mine()[k] = v else rawset(t, k, v) end end,
}

function F.Print(msg) print("|cff33ccffFishie:|r " .. tostring(msg)) end
local Print = F.Print

-- Debug lines go to chat and are also kept (the last 500) in the saved data, so they can be read
-- after a /reload or logout without copying them out of the chat window.
local DEBUG_KEEP = 500
function F.Debug(msg)
    if not (F.db and F.db.debug) then return end
    print("|cff888888Fishie debug:|r " .. tostring(msg))
    local log = F.db.debugLog
    if type(log) ~= "table" then log = {} F.db.debugLog = log end
    local t = (_G.date and _G.date("%H:%M:%S")) or "?"
    log[#log + 1] = ("%s +%.2f %s"):format(t, (_G.GetTime and _G.GetTime() or 0) % 1000, tostring(msg))
    if #log > DEBUG_KEEP + 50 then
        local keep = {}
        for i = #log - DEBUG_KEEP + 1, #log do keep[#keep + 1] = log[i] end
        F.db.debugLog = keep
    end
end

local reported = {}
function F.ReportError(what, err)
    if F.Issue then F.Issue("lua", what, err) end
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
        for k in pairs(PERCHAR) do
            -- a saved value from before the split stays visible until the first character claims it
            if FishieDB.perCharMoved then rawset(FishieDB, k, nil) end
        end
        setmetatable(FishieDB, dbMeta)
        pcall(Mine)
        F.Fire("loaded")
        return
    end
    for _, fn in ipairs(handlers[event] or {}) do
        local ok, err = pcall(fn, event, ...)
        if not ok then F.ReportError("Fishie (" .. event .. ")", err) end
    end
end)
frame:RegisterEvent("ADDON_LOADED")
F.On("PLAYER_LOGIN", function() if FishieDB then pcall(Mine) end end)

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
    counter = { "showCounter", "Catch counter" },
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
    elseif cmd == "zone" then
        if F.ZoneDebug then F.ZoneDebug() end
    elseif cmd == "debug" then
        local v = rest:lower()
        if v == "on" then F.db.debug = true elseif v == "off" then F.db.debug = false else F.db.debug = not F.db.debug end
        Print("Debug " .. (F.db.debug and "on: Fishie explains every click, cast and catch it sees, and keeps the last 500 lines in its saved data." or "off"))
    elseif cmd == "debuglog" then
        local log = F.db.debugLog or {}
        if rest:lower() == "clear" then F.db.debugLog = {} Print("Debug log cleared.") return end
        Print(("Debug log: %d lines kept (/fishie debuglog clear to empty it). Last 10:"):format(#log))
        for i = math.max(1, #log - 9), #log do print("  " .. log[i]) end
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
        Print("/fishie doubleclick | lure | pole | sound | announce | refreshlure | warnlure | autocatch | autoloot | hud | counter [on|off]")
        Print("/fishie minimap - show or hide the minimap button")
        Print("/fishie debug [on|off] - explain every click, cast and catch in chat (and keep the last 500 lines)")
        Print("/fishie debuglog [clear] - show the last kept debug lines")
        Print("/fishie release - give right-click back to the game if it ever feels stuck")
        Print("/fishie probe - show what the game reports about your pole and lures")
    end
end
