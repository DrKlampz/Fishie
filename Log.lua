-- Fishie catch log: what you catch, where, and how fast.
local ADDON_NAME, F = ...
local L = {}
F.Log = L

local session

function L.ResetSession()
    session = { start = nil, casts = 0, caught = 0, items = {}, order = {}, opened = 0, opens = {}, openOrder = {} }
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
    L.recordedSinceCast = (L.recordedSinceCast or 0) + count
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

-- Bag snapshot: the last-resort way to see a catch, if neither the loot window nor the chat
-- line was readable. Taken when a cast starts, compared shortly after it ends.
local function BagCounts()
    local out = {}
    if not (C_Container and C_Container.GetContainerItemInfo) then return nil end
    local nb = (C_Container.GetContainerNumSlots and 4) or 4
    for bag = 0, nb do
        local slots = C_Container.GetContainerNumSlots and C_Container.GetContainerNumSlots(bag) or 0
        for slot = 1, slots do
            local info = C_Container.GetContainerItemInfo(bag, slot)
            if info and info.hyperlink and not F.IsSecret(info.hyperlink) then
                local nm = info.hyperlink:match("%[(.-)%]")
                if nm then
                    local e = out[nm]
                    if not e then e = { n = 0, link = info.hyperlink, quality = info.quality } out[nm] = e end
                    e.n = e.n + (info.stackCount or 1)
                end
            end
        end
    end
    return out
end

local bagsBefore
-- The bag and chat fallbacks cannot tell a catch from anything else you picked up while the line was out. So they
-- stand down if you fought something or looted a corpse or chest since the cast: the bobber's own loot window is
-- the only thing that counts then.
L.castAt, L.combatAt = 0, 0
F.On("PLAYER_REGEN_DISABLED", function() L.combatAt = GetTime() end)
local function SomethingElseSinceCast()
    if InCombatLockdown and InCombatLockdown() then return true end
    if (L.combatAt or 0) >= (L.castAt or 0) then return true end
    if L.lastLootIsFishing == false and (L.lastLootAt or 0) >= (L.castAt or 0) then return true end
    return false
end

-- A catch lands within a few seconds of the line coming in. Anything that reaches your bags later, or while a line is out
-- (a won roll, mail, a quest reward), is not from the bobber.
local function JustReeledIn()
    if UnitChannelInfo and UnitChannelInfo("player") then return false end
    return F.lastChannelStop ~= nil and GetTime() - F.lastChannelStop < 6
end

function L.CheckBags()
    local before = bagsBefore
    bagsBefore = nil
    if not before or (L.recordedSinceCast or 0) > 0 then return end
    if not JustReeledIn() then F.Debug("bag check skipped: the line was not just reeled in") return end
    if SomethingElseSinceCast() then F.Debug("bag check skipped: combat or other loot since the cast") return end
    local after = BagCounts()
    if not after then return end
    for nm, e in pairs(after) do
        local gained = e.n - (before[nm] and before[nm].n or 0)
        if gained > 0 and gained <= 20 then
            F.Debug(("bag check: +%d %s"):format(gained, nm))
            L.Record(nm, e.link, gained, e.quality)
            if F.db.announce then F.Print(("Caught %s%s."):format(e.link or nm, gained > 1 and (" x" .. gained) or "")) end
        end
    end
    if F.UI then F.UI.Refresh() end
end

function L.OnCast()
    L.castAt = GetTime()
    L.catchCounted = false
    L.recordedSinceCast = 0
    bagsBefore = BagCounts()
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
    if session.opened > 0 then
        F.Print(("Opened this session: %d."):format(session.opened))
        for _, line in ipairs(L.OpenLines()) do F.Print("  " .. line) end
    end
    if session.caught == 0 then F.Print("Nothing caught this session yet.") return end
    F.Print(("This session: %d caught in %s (%.0f per hour), %d cast%s."):format(
        session.caught, L.FormatTime(L.Elapsed()), L.PerHour(), session.casts, session.casts == 1 and "" or "s"))
    for _, name in ipairs(session.order) do
        local s = session.items[name]
        F.Print(("  %s x%d"):format(s.link or name, s.count))
    end
end

-- Chests, crates, clams and other things you open during the session (not fish, not corpses): what each was and what
-- came out of it. A chest is a world object, a clam or crate is an item from your bags.
local lastUse            -- the bag item you last used: { link, time }
local lastTarget         -- the target of your last cast ("Opening" a chest names it): { name, time }
if hooksecurefunc then
    local function Used(bag, slot)
        local link
        if C_Container and C_Container.GetContainerItemLink then link = C_Container.GetContainerItemLink(bag, slot)
        elseif GetContainerItemLink then link = GetContainerItemLink(bag, slot) end
        if link and not F.IsSecret(link) then lastUse = { link = link, time = GetTime() } end
    end
    if C_Container and C_Container.UseContainerItem then pcall(hooksecurefunc, C_Container, "UseContainerItem", Used)
    elseif UseContainerItem then pcall(hooksecurefunc, "UseContainerItem", Used) end
end
F.On("UNIT_SPELLCAST_SENT", function(_, unit, target)
    if unit == "player" and type(target) == "string" and not F.IsSecret(target) and target ~= "" then
        lastTarget = { name = target, time = GetTime() }
    end
end)

local function SourceOf()
    if not GetLootSourceInfo then return nil end
    local ok, guid = pcall(GetLootSourceInfo, 1)
    if not ok or type(guid) ~= "string" or F.IsSecret(guid) then return nil end
    return guid:match("^(%a+)%-")
end

-- the name of what was just opened, as best the game lets us tell
local function OpenedName(kind)
    local now = GetTime()
    if kind == "Item" then
        if lastUse and now - lastUse.time < 6 then
            local nm = lastUse.link:match("%[(.-)%]")
            if nm then return nm, lastUse.link end
        end
        return "Something from your bags"
    end
    if lastTarget and now - lastTarget.time < 8 then return lastTarget.name end
    local tip = _G.GameTooltipTextLeft1
    if tip and _G.GameTooltip and GameTooltip:IsShown() then
        local t = tip:GetText()
        if t and not F.IsSecret(t) and t ~= "" then return t end
    end
    return "Chest or container"
end

function L.TrackOpen()
    if F.db.keepOpensList ~= true then return end     -- Fishie only tracks what you fish up unless this is switched on
    local kind = SourceOf()
    if kind ~= "GameObject" and kind ~= "Item" then return end
    if L.openCounted then return end
    L.openCounted = true
    local name, link = OpenedName(kind)
    session.start = session.start or Now()
    session.opened = session.opened + 1
    local o = session.opens[name]
    if not o then o = { count = 0, link = link, loot = {}, order = {} } session.opens[name] = o session.openOrder[#session.openOrder + 1] = name end
    o.count = o.count + 1
    o.link = o.link or link
    local n = GetNumLootItems and GetNumLootItems() or 0
    local gotCoin = false
    for i = 1, n do
        local ltype = GetLootSlotType and GetLootSlotType(i)
        local _, nm, qty = GetLootSlotInfo(i)
        if ltype == 2 then
            gotCoin = true   -- money: it is in the window, but the amount is a text; counted in the chat line below
        elseif nm and not F.IsSecret(nm) then
            qty = tonumber(qty) or 1
            local it = o.loot[nm]
            if not it then it = { count = 0, link = GetLootSlotLink and GetLootSlotLink(i) } o.loot[nm] = it o.order[#o.order + 1] = nm end
            it.count = it.count + qty
        end
    end
    if F.db.announce then F.Print(("Opened %s."):format(link or name)) end
    F.Debug(("opened %s (%s), %d slot(s)"):format(name, tostring(kind), n))
    if F.UI then F.UI.Refresh() end
    if F.Counter then F.Counter.Refresh() end
end
F.On("LOOT_CLOSED", function() L.openCounted = false end)

-- Lines for the session views: "Sunken Chest x3" with what they gave underneath.
function L.OpenLines(maxLines, indent)
    local out = {}
    for _, name in ipairs(session.openOrder) do
        local o = session.opens[name]
        out[#out + 1] = ("%s x%d"):format(o.link or name, o.count)
        for _, nm in ipairs(o.order) do
            if #out >= (maxLines or 99) then out[#out + 1] = "..." return out end
            local it = o.loot[nm]
            out[#out + 1] = (indent or "   ") .. ("%s x%d"):format(it.link or nm, it.count)
        end
        if #out >= (maxLines or 99) then out[#out + 1] = "..." return out end
    end
    return out
end

-- Catches are seen two ways, so one failing doesn't lose them: the loot window of a fishing
-- cast, and the "You receive loot" chat line while a fishing cast was recent.
local recent = {}   -- [itemName] = time the loot window recorded it

local function Announce(link, name, qty)
    if F.db.announce then F.Print(("Caught %s%s."):format(link or name, (qty and qty > 1) and (" x" .. qty) or "")) end
end

local lootSeen = 0
-- loot from a corpse, a bag or a chest is never a catch, whatever the fishing timer says
local function LootFromThings()
    if not GetLootSourceInfo then return false end
    local ok, guid = pcall(GetLootSourceInfo, 1)
    if not ok or type(guid) ~= "string" or F.IsSecret(guid) then return false end
    return guid:find("^Creature") or guid:find("^Vehicle") or guid:find("^Pet") or guid:find("^Item") or guid:find("^Player") and true or false
end

local function OnLoot(event)
    if event == "LOOT_OPENED" and GetTime() - lootSeen < 0.5 then return end   -- LOOT_READY already counted this window
    -- the game says whether this loot window is a fishing catch; only guess from the timer when it can't say
    local isFishing
    if IsFishingLoot then isFishing = IsFishingLoot() and true or false
    else isFishing = F.IsFishingNow and F.IsFishingNow() end
    F.Debug(("loot window opened; IsFishingLoot=%s recentCast=%s"):format(
        tostring(IsFishingLoot and IsFishingLoot()), tostring(F.IsFishingNow and F.IsFishingNow())))
    if isFishing and not (IsFishingLoot and IsFishingLoot()) and LootFromThings() then isFishing = false end
    -- a chest (a world object that is not the bobber) is not a catch either, whatever the fishing timer says
    if isFishing and IsFishingLoot and not IsFishingLoot() and SourceOf() == "GameObject" then isFishing = false end
    L.lastLootAt = GetTime()
    L.lastLootIsFishing = isFishing and true or false
    if not isFishing then bagsBefore = nil L.TrackOpen() return end
    lootSeen = (event == "LOOT_READY") and GetTime() or 0
    -- the game can send the "loot is ready" event more than once for one catch (auto-loot does):
    -- one cast is one catch, so only the first loot window after a cast counts
    if L.catchCounted and GetTime() - (L.catchCountedAt or 0) < 15 then
        F.Debug("loot event again for the same cast: not counted twice")
        return
    end
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
            L.catchCounted, L.catchCountedAt = true, GetTime()
        end
    end
    if F.UI then F.UI.Refresh() end
end
F.On("LOOT_READY", OnLoot)
F.On("LOOT_OPENED", OnLoot)
F.On("LOOT_CLOSED", function()
    if F.Cast then F.Cast.Restore() end
    if L.lastLootIsFishing == false and L.lastLootAt and GetTime() - L.lastLootAt < 10 then bagsBefore = nil return end   -- that was not a catch
    C_Timer.After(1.5, L.CheckBags)
end)
-- No loot window at all (auto-loot took it instantly): look at the bags once the line is in.
F.On("UNIT_SPELLCAST_CHANNEL_STOP", function(_, unit)
    if unit == "player" and F.IsFishingNow() and F.lastChannelStop and GetTime() - F.lastChannelStop < 1 then C_Timer.After(2.5, L.CheckBags) end
end)

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
    if L.lastLootIsFishing == false and L.lastLootAt and GetTime() - L.lastLootAt < 5 then return end   -- a corpse or chest, not the bobber
    if SomethingElseSinceCast() then return end
    if not JustReeledIn() then return end        -- not from the bobber: a won roll, a quest reward, mail
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
