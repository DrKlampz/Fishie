-- Fishie catch log: what you catch, where, and how fast.
local ADDON_NAME, F = ...
local L = {}
F.Log = L

local session

function L.ResetSession()
    session = { start = nil, casts = 0, caught = 0, items = {}, order = {} }
end
L.ResetSession()

function L.Session() return session end

local function Zone()
    local z = (GetRealZoneText and GetRealZoneText()) or ""
    if z == "" then z = "Unknown" end
    return z
end

local function Now() return GetTime() end

-- Record one looted item (name, link, count, quality).
function L.Record(name, link, count, quality)
    count = count or 1
    session.start = session.start or Now()
    session.caught = session.caught + count
    local s = session.items[name]
    if not s then
        s = { count = 0, link = link, quality = quality }
        session.items[name] = s
        session.order[#session.order + 1] = name
    end
    s.count = s.count + count

    local zone = Zone()
    local z = F.db.fish[zone]
    if not z then z = {} F.db.fish[zone] = z end
    local e = z[name]
    if not e then e = { count = 0, link = link } z[name] = e end
    e.count = e.count + count
    e.link = link or e.link
    F.db.total = (F.db.total or 0) + count
end

function L.OnCast()
    session.start = session.start or Now()
    session.casts = session.casts + 1
end
F.AddHook("cast", L.OnCast)

-- Items per hour for this session.
function L.PerHour()
    if not session.start or session.caught == 0 then return 0 end
    local hours = (Now() - session.start) / 3600
    if hours <= 0 then return 0 end
    return session.caught / hours
end

function L.Elapsed()
    if not session.start then return 0 end
    return Now() - session.start
end

function L.FormatTime(sec)
    sec = math.floor(sec)
    local h, m = math.floor(sec / 3600), math.floor(sec / 60) % 60
    if h > 0 then return ("%dh %02dm"):format(h, m) end
    return ("%dm %02ds"):format(m, sec % 60)
end

function L.PrintSession()
    if session.caught == 0 then F.Print("Nothing caught this session yet.") return end
    F.Print(("This session: %d caught in %s (%.0f per hour), %d cast%s."):format(
        session.caught, L.FormatTime(L.Elapsed()), L.PerHour(), session.casts, session.casts == 1 and "" or "s"))
    for _, name in ipairs(session.order) do
        local s = session.items[name]
        F.Print(("  %s x%d"):format(s.link or name, s.count))
    end
end

-- Catches are seen two ways, so one failing doesn't lose them: the loot window of a fishing
-- cast, and the "You receive loot" chat line while a fishing cast was recent.
local recent = {}   -- [itemName] = time the loot window recorded it

local function Announce(link, name, qty)
    if F.db.announce then F.Print(("Caught %s%s."):format(link or name, (qty and qty > 1) and (" x" .. qty) or "")) end
end

local function OnLoot()
    local isFishing = (IsFishingLoot and IsFishingLoot()) or (F.IsFishingNow and F.IsFishingNow())
    F.Debug(("loot window opened; IsFishingLoot=%s recentCast=%s"):format(
        tostring(IsFishingLoot and IsFishingLoot()), tostring(F.IsFishingNow and F.IsFishingNow())))
    if not isFishing then return end
    local n = GetNumLootItems and GetNumLootItems() or 0
    for i = 1, n do
        local name, qty, quality
        if GetLootSlotInfo then
            local _, nm, q, a, b = GetLootSlotInfo(i)
            name, qty, quality = nm, q, b or a
        end
        local link = GetLootSlotLink and GetLootSlotLink(i)
        if name and not F.IsSecret(name) then
            qty = tonumber(qty) or 1
            L.Record(name, link, qty, quality)
            recent[name] = GetTime()
            Announce(link, name, qty)
        end
    end
    if F.UI then F.UI.Refresh() end
end
F.On("LOOT_OPENED", OnLoot)
F.On("LOOT_CLOSED", function() if F.Cast then F.Cast.Restore() end end)

local function Esc(s) return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")) end
local SELF_PATTERNS
local function SelfPatterns()
    if SELF_PATTERNS then return SELF_PATTERNS end
    SELF_PATTERNS = {}
    for _, g in ipairs({ "LOOT_ITEM_SELF_MULTIPLE", "LOOT_ITEM_SELF", "LOOT_ITEM_PUSHED_SELF_MULTIPLE", "LOOT_ITEM_PUSHED_SELF" }) do
        local s = _G[g]
        if type(s) == "string" then
            SELF_PATTERNS[#SELF_PATTERNS + 1] = "^" .. Esc(s):gsub("%%%%s", "(.+)"):gsub("%%%%d", "(%%d+)") .. "$"
        end
    end
    if #SELF_PATTERNS == 0 then SELF_PATTERNS = { "^You receive loot: (.+)%.$", "^You receive item: (.+)%.$" } end
    return SELF_PATTERNS
end

F.On("CHAT_MSG_LOOT", function(_, msg)
    if not msg or F.IsSecret(msg) or not (F.IsFishingNow and F.IsFishingNow()) then return end
    local link = msg:match("(|c%x+|Hitem:.-|h%[.-%]|h|r)") or msg:match("(|Hitem:.-|h%[.-%]|h)")
    if not link then return end
    local mine = false
    for _, p in ipairs(SelfPatterns()) do if msg:match(p) then mine = true break end end
    if not mine then return end
    local name = link:match("%[(.-)%]")
    local qty = tonumber(msg:match("x(%d+)")) or 1
    F.Debug(("loot chat line for %s x%d"):format(tostring(name), qty))
    if recent[name] and GetTime() - recent[name] < 5 then return end   -- the loot window already counted it
    L.Record(name, link, qty)
    recent[name] = GetTime()
    Announce(link, name, qty)
    if F.UI then F.UI.Refresh() end
end)

-- Zone totals, sorted: { { name, count, link } }
function L.ZoneList(zone)
    local out = {}
    for name, e in pairs(F.db.fish[zone] or {}) do out[#out + 1] = { name = name, count = e.count, link = e.link } end
    table.sort(out, function(a, b) if a.count ~= b.count then return a.count > b.count end return a.name < b.name end)
    return out
end

function L.Zones()
    local out = {}
    for zone, items in pairs(F.db.fish) do
        local total = 0
        for _, e in pairs(items) do total = total + e.count end
        out[#out + 1] = { zone = zone, total = total }
    end
    table.sort(out, function(a, b) if a.total ~= b.total then return a.total > b.total end return a.zone < b.zone end)
    return out
end
