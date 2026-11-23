-- Pools: where the fish are. Fishing pools and the spots you have fished, on the world map and the minimap.
-- Pool spawn points are from ForeverDB.net (PoolData.lua); the spots you fish are learned as you cast.
local ADDON_NAME, F = ...
local P = {}
F.Pools = P
local floor, sqrt, abs = math.floor, math.sqrt, math.abs

local function Finite(v) return type(v) == "number" and v == v and v > -math.huge and v < math.huge end

-- ---------------------------------------------------------------- positions
local function PlayerPos()
    if not (C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition) then return end
    local m = C_Map.GetBestMapForUnit("player")
    if not Finite(m) or m <= 0 then return end
    local pos = C_Map.GetPlayerMapPosition(m, "player")
    if not pos or F.IsSecret(pos) then return end
    local x, y = pos.x, pos.y
    if not Finite(x) or not Finite(y) or x < 0 or x > 1 or y < 0 or y > 1 then return end
    return m, x, y
end
local sizeCache = {}
local function MapSize(m)
    local d = sizeCache[m]
    if d then return d[1], d[2] end
    if C_Map and C_Map.GetMapWorldSize then
        local w, h = C_Map.GetMapWorldSize(m)
        if Finite(w) and w > 0 and Finite(h) and h > 0 then sizeCache[m] = { w, h } return w, h end
    end
    return 1000, 1000
end

-- ---------------------------------------------------------------- your spots
-- F.db.pools[mapID] = list of { x, y, n = casts, pool = name or nil, seen = time }
local POOL_WORDS = { "school", "pool", "patch of", "wreckage", "debris", "shoal", "oil spill", "bloodsail", "swarm" }
local function poolNameUnderCursor()
    if not (GameTooltip and GameTooltip:IsShown()) then return nil end
    local fs = _G.GameTooltipTextLeft1
    local t = fs and fs:GetText()
    if type(t) ~= "string" or F.IsSecret(t) then return nil end
    local low = t:lower()
    for _, w in ipairs(POOL_WORDS) do if low:find(w, 1, true) then return t end end
end

local function Learn()
    if not (F.db and F.db.poolLearn) then return end
    local m, x, y = PlayerPos()
    if not m then return end
    local name = poolNameUnderCursor()
    if name and GetPlayerFacing then
        -- the pool is out in the water in front of you: about 18 yards that way
        local f = GetPlayerFacing()
        if Finite(f) then
            local w, h = MapSize(m)
            x = x + (-math.sin(f) * 18) / w
            y = y - (math.cos(f) * 18) / h
        end
    end
    F.db.pools = F.db.pools or {}
    local list = F.db.pools[m]
    if not list then list = {} F.db.pools[m] = list end
    local w, h = MapSize(m)
    for _, s in ipairs(list) do
        local dx, dy = (s.x - x) * w, (s.y - y) * h
        if dx * dx + dy * dy < 25 * 25 and ((s.pool ~= nil) == (name ~= nil)) then
            s.n = (s.n or 1) + 1
            s.seen = time()
            if name then s.pool = name end
            P.Changed()
            return
        end
    end
    list[#list + 1] = { x = x, y = y, n = 1, pool = name, seen = time() }
    P.Changed()
end
F.AddHook("cast", function() C_Timer.After(0.3, function() pcall(Learn) end) end)

-- ---------------------------------------------------------------- spawn points (ForeverDB.net)
local decoded, merged = {}, {}
local function decode(str, out, label, src)
    for i = 1, #str - 3, 4 do
        local x, y = tonumber(str:sub(i, i + 1), 36), tonumber(str:sub(i + 2, i + 3), 36)
        if x and y then out[#out + 1] = { x = x / 1000, y = y / 1000, pool = label, spawn = src } end
    end
end
local function Spawns(m)
    local d = F.POOLS
    if not (d and F.db and F.db.poolSpawns) then return nil end
    if decoded[m] then return decoded[m] end
    local z = d.zones[m]
    if not z then return nil end
    local list = {}
    for id, e in pairs(z.k) do
        local kind = d.kinds[id]
        local label = kind and kind.n or "Fishing pool"
        if e.f ~= "" then decode(e.f, list, label, "seen") end
        if e.c ~= "" then decode(e.c, list, label, "classic") end
    end
    decoded[m] = list
    return list
end
function P.Changed() wipe(merged) P.rev = (P.rev or 0) + 1 end
local function List(m)
    if merged[m] then return merged[m] end
    local out = {}
    local mine = F.db and F.db.pools and F.db.pools[m]
    for _, s in ipairs(mine or {}) do out[#out + 1] = s end
    local w, h = MapSize(m)
    for _, s in ipairs(Spawns(m) or {}) do
        local covered = false
        for _, n in ipairs(mine or {}) do
            local dx, dy = (n.x - s.x) * w, (n.y - s.y) * h
            if dx * dx + dy * dy < 30 * 30 then covered = true break end
        end
        if not covered then out[#out + 1] = s end
    end
    merged[m] = out
    return out
end
P.List = List

-- ---------------------------------------------------------------- pins
local ICON_POOL, ICON_SPOT = 133906, 136245   -- a fish; a fishing pole
local pool = { world = {}, mini = {} }
local used = { world = 0, mini = 0 }
local worldOverlay, miniOverlay

local function setPinSize(pin, size)
    pin:SetSize(size, size)
    local r = size * 0.1
    pin.ring:ClearAllPoints()
    pin.ring:SetPoint("TOPLEFT", -r, r)
    pin.ring:SetPoint("BOTTOMRIGHT", r, -r)
end

local function createPin(parent, kind)
    local pin = CreateFrame("Button", nil, parent)
    pin:SetFrameStrata(kind == "world" and "HIGH" or "MEDIUM")
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetAllPoints()
    pin.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    pin.ring = pin:CreateTexture(nil, "BACKGROUND")
    pin.ring:SetColorTexture(0.3, 0.6, 0.95, 1)
    pin:SetScript("OnEnter", function(self)
        local s = self.spot
        if not s then return end
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:AddLine(s.pool or "Fishing spot", 0.4, 0.7, 1)
        if s.spawn then
            GameTooltip:AddLine(s.spawn == "seen" and "|cff40ff40Seen by players in WoW Forever|r" or "|cffd0d060Classic spawn point (may differ in Forever)|r", 0.9, 0.9, 0.9)
            GameTooltip:AddLine("Data from ForeverDB.net", 0.6, 0.6, 0.6)
        else
            GameTooltip:AddLine(("You fished here %d time%s"):format(s.n or 1, (s.n or 1) == 1 and "" or "s"), 0.9, 0.9, 0.9)
        end
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return pin
end
local function acquire(kind, parent)
    used[kind] = used[kind] + 1
    local pin = pool[kind][used[kind]]
    if not pin then pin = createPin(parent, kind) pool[kind][used[kind]] = pin end
    return pin
end
local function release(kind) for i = used[kind] + 1, #pool[kind] do pool[kind][i]:Hide() end end
local function style(pin, s, size)
    pin.spot = s
    setPinSize(pin, size)
    pin.icon:SetTexture(s.pool and ICON_POOL or ICON_SPOT)
    local a = F.db.poolAlpha or 1
    if s.spawn == "classic" then a = a * 0.6 end
    pin:SetAlpha(a)
end

local function canvas()
    local sc = WorldMapFrame and WorldMapFrame.ScrollContainer
    return sc and (sc.Child or sc)
end
local function stitched()
    local api = _G.OpenMapAPI
    return api and api.IsStitched and api.IsStitched() and api.WorldFromMap and api.MapFromWorld and api or nil
end
local function ensureWorld()
    local c = canvas()
    if not c then return end
    if worldOverlay and worldOverlay:GetParent() == c then return end
    if not worldOverlay then worldOverlay = CreateFrame("Frame", nil, c) else worldOverlay:SetParent(c) worldOverlay:ClearAllPoints() end
    worldOverlay:SetAllPoints(c)
    worldOverlay:SetFrameLevel(c:GetFrameLevel() + 49)
    worldOverlay:SetFrameStrata("HIGH")
end

function P.RefreshWorld()
    ensureWorld()
    used.world = 0
    if worldOverlay and WorldMapFrame and WorldMapFrame:IsShown() and F.db.poolMap then
        local view = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
        local c = canvas()
        local w, h = c:GetWidth(), c:GetHeight()
        local scale = worldOverlay:GetEffectiveScale() / UIParent:GetEffectiveScale()
        if not scale or scale <= 0 then scale = 1 end
        local info = view and C_Map.GetMapInfo and C_Map.GetMapInfo(view)
        local far = info and info.mapType and info.mapType <= 2
        P.sizeFactor = far and 0.75 or 1
        local size = (F.db.poolSize or 14) * P.sizeFactor / math.max(scale, 0.05)
        local api = stitched()
        local sig = table.concat({ tostring(view), floor(w or 0), P.zoomGen or 0, tostring(api ~= nil), P.rev or 0, F.db.poolSize or 0,
            tostring(F.db.poolFar), tostring(F.db.poolSpawns), F.db.poolMax or 0, tostring(F.db.poolClassic) }, ":")
        if sig == P.lastSig then used.world = P.lastUsed or 0 release("world") return end
        if w and w > 0 and view and not (far and not F.db.poolFar) then
            local zones = {}
            if api then
                local have = {}
                for m in pairs(F.db.pools or {}) do have[m] = true end
                if F.POOLS and F.db.poolSpawns then for m in pairs(F.POOLS.zones) do have[m] = true end end
                for m in pairs(have) do zones[#zones + 1] = m end
            else
                zones[1] = view
            end
            local sc = WorldMapFrame.ScrollContainer
            local cs, ss = c:GetEffectiveScale(), sc:GetEffectiveScale()
            local cl, ct = c:GetLeft(), c:GetTop()
            local vl, vr, vt, vb = sc:GetLeft(), sc:GetRight(), sc:GetTop(), sc:GetBottom()
            local function inView(nx, ny)
                if not (cl and vl and cs and ss) then return true end
                local sx, sy = (cl + nx * w) * cs, (ct - ny * h) * cs
                return sx >= vl * ss - 24 and sx <= vr * ss + 24 and sy <= vt * ss + 24 and sy >= vb * ss - 24
            end
            local cell, taken, count = size * (far and 3.2 or 1.15), {}, 0
            local maxPins = (F.db.poolMax or 300) * (far and 0.33 or 1)
            for pass = 1, 3 do
                for _, m in ipairs(zones) do
                    for _, s in ipairs(List(m)) do
                        local p = not s.spawn and 1 or s.spawn == "seen" and 2 or 3
                        if p == pass and not (s.spawn == "classic" and F.db.poolClassic == false) then
                            local nx, ny = s.x, s.y
                            if api then
                                if s._h ~= view or s._m ~= m then
                                    s._h, s._m = view, m
                                    local u, v = api.WorldFromMap(m, s.x, s.y)
                                    if u then s._cx, s._cy = api.MapFromWorld(view, u, v) else s._cx, s._cy = nil, nil end
                                end
                                nx, ny = s._cx, s._cy
                            end
                            if nx and inView(nx, ny) then
                                local key = floor(nx * w / cell) * 100003 + floor(ny * h / cell)
                                if not taken[key] and count < maxPins then
                                    taken[key] = true
                                    count = count + 1
                                    local pin = acquire("world", worldOverlay)
                                    pin:SetParent(worldOverlay)
                                    style(pin, s, size)
                                    pin:ClearAllPoints()
                                    pin:SetPoint("CENTER", worldOverlay, "TOPLEFT", nx * w, -ny * h)
                                    pin:Show()
                                end
                            end
                        end
                    end
                end
            end
        end
        P.lastSig, P.lastUsed = sig, used.world
    end
    release("world")
end

-- minimap: the nearest spots, placed the way the game places its own dots
local function Radius()
    if C_Minimap and C_Minimap.GetViewRadius then
        local r = C_Minimap.GetViewRadius()
        if Finite(r) and r > 0 then return r end
    end
    local zoom = Minimap:GetZoom() or 0
    local indoors = IsIndoors and IsIndoors() or false
    local d = (indoors and { [0] = 300, 250, 200, 150, 100, 75 } or { [0] = 466.67, 400, 333.33, 266.67, 200, 133.33 })[zoom]
    return d and d / 2 or 180
end
function P.RefreshMini()
    used.mini = 0
    if Minimap and F.db and F.db.poolMini then
        local m, px, py = PlayerPos()
        if m then
            if not miniOverlay then
                miniOverlay = CreateFrame("Frame", nil, Minimap)
                miniOverlay:SetAllPoints(Minimap)
                miniOverlay:SetFrameLevel(Minimap:GetFrameLevel() + 9)
            end
            local getcv = C_CVar and C_CVar.GetCVar or GetCVar
            local rot = getcv and getcv("rotateMinimap") == "1"
            local facing = rot and GetPlayerFacing and GetPlayerFacing() or 0
            if not Finite(facing) then facing = 0 end
            local cos, sin = math.cos(facing), math.sin(facing)
            local w, h = MapSize(m)
            local radius = Radius()
            local halfW, halfH = Minimap:GetWidth() * 0.5, Minimap:GetHeight() * 0.5
            local size = F.db.poolSize or 14
            local shown = 0
            for _, s in ipairs(List(m)) do
                if shown >= 30 then break end
                if not (s.spawn == "classic" and F.db.poolClassic == false) then
                    local east, north = (s.x - px) * w, -(s.y - py) * h
                    if sqrt(east * east + north * north) <= radius * 0.96 then
                        local sx, sy = east, north
                        if rot then sx = east * cos - north * sin sy = east * sin + north * cos end
                        shown = shown + 1
                        local pin = acquire("mini", miniOverlay)
                        pin:SetParent(miniOverlay)
                        style(pin, s, size)
                        pin:ClearAllPoints()
                        pin:SetPoint("CENTER", miniOverlay, "CENTER", sx / radius * halfW, sy / radius * halfH)
                        pin:EnableMouse(false)
                        pin:Show()
                    end
                end
            end
        end
    end
    release("mini")
end

F.AddHook("loaded", function()
    local t = 0
    local drv = CreateFrame("Frame")
    drv:SetScript("OnUpdate", function(_, dt)
        t = t + dt
        if t >= 0.25 then t = 0 pcall(P.RefreshMini) end
        if worldOverlay and WorldMapFrame and WorldMapFrame:IsShown() then
            local sc = worldOverlay:GetEffectiveScale() / UIParent:GetEffectiveScale()
            if sc and sc > 0 and sc ~= P.curScale then
                P.curScale = sc
                local size = (F.db.poolSize or 14) * (P.sizeFactor or 1) / math.max(sc, 0.05)
                for i = 1, used.world do if pool.world[i] then setPinSize(pool.world[i], size) end end
                P.settleAt = GetTime() + 0.35
            elseif P.settleAt and GetTime() >= P.settleAt then
                P.settleAt = nil
                P.zoomGen = (P.zoomGen or 0) + 1
                pcall(P.RefreshWorld)
            end
        end
    end)
    local function hook()
        if not WorldMapFrame or P.hooked then return end
        P.hooked = true
        WorldMapFrame:HookScript("OnShow", function() P.rev = (P.rev or 0) + 1 pcall(P.RefreshWorld) end)
        pcall(hooksecurefunc, WorldMapFrame, "OnMapChanged", function() pcall(P.RefreshWorld) end)
        local api = _G.OpenMapAPI
        if api and api.RegisterCallback then
            local owner = {}
            local function again() if WorldMapFrame:IsShown() then pcall(P.RefreshWorld) end end
            pcall(api.RegisterCallback, owner, "OpenMap_StitchedChanged", again)
            pcall(api.RegisterCallback, owner, "OpenMap_ViewChanged", again)
        end
    end
    F.On("PLAYER_ENTERING_WORLD", function()
        if not WorldMapFrame and C_AddOns and C_AddOns.LoadAddOn then pcall(C_AddOns.LoadAddOn, "Blizzard_WorldMap") end
        hook()
        P.Changed()
    end)
end)
