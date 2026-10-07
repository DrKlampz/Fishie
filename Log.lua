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

-- Loot window opened by a fishing cast.
local function OnLoot()
    if not (IsFishingLoot and IsFishingLoot()) then return end
    local n = GetNumLootItems and GetNumLootItems() or 0
    for i = 1, n do
        local name, qty, quality
        if GetLootSlotInfo then
            local _, nm, q, a, b = GetLootSlotInfo(i)
            name, qty, quality = nm, q, b or a
        end
        local link = GetLootSlotLink and GetLootSlotLink(i)
        if name and not F.IsSecret(name) then
            L.Record(name, link, tonumber(qty) or 1, quality)
            if F.db.announce then F.Print(("Caught %s%s."):format(link or name, (qty and qty > 1) and (" x" .. qty) or "")) end
        end
    end
    if F.UI then F.UI.Refresh() end
end
F.On("LOOT_OPENED", OnLoot)
F.On("LOOT_CLOSED", function() if F.Cast then F.Cast.Restore() end end)

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
