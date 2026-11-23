-- Zones: which fish a zone gives, shown on the world map for the zone under the cursor. The guide is general
-- (Classic); the "You gathered here" line comes from your own log and is what you actually pulled up.
local ADDON_NAME, F = ...

local SW = "Oily Blackmouth, Firefin Snapper"   -- the two saltwater schools
local G = {
    ["Elwynn Forest"] = { 1, 10, "Raw Brilliant Smallfish, Raw Slitherskin Mackerel" },
    ["Dun Morogh"] = { 1, 10, "Raw Brilliant Smallfish, Raw Slitherskin Mackerel" },
    ["Tirisfal Glades"] = { 1, 10, "Raw Brilliant Smallfish, Raw Slitherskin Mackerel" },
    ["Durotar"] = { 1, 10, "Raw Brilliant Smallfish, Raw Slitherskin Mackerel, " .. "Oily Blackmouth" },
    ["Mulgore"] = { 1, 10, "Raw Brilliant Smallfish, Raw Slitherskin Mackerel" },
    ["Teldrassil"] = { 1, 10, "Raw Brilliant Smallfish, Raw Slitherskin Mackerel" },
    ["Westfall"] = { 10, 20, "Raw Longjaw Mud Snapper, Raw Slitherskin Mackerel, Oily Blackmouth" },
    ["Loch Modan"] = { 10, 20, "Raw Longjaw Mud Snapper, Raw Slitherskin Mackerel" },
    ["Silverpine Forest"] = { 10, 20, "Raw Longjaw Mud Snapper, Raw Bristle Whisker Catfish" },
    ["Darkshore"] = { 10, 20, "Raw Longjaw Mud Snapper, Oily Blackmouth" },
    ["The Barrens"] = { 10, 25, "Raw Longjaw Mud Snapper, Raw Bristle Whisker Catfish, Oily Blackmouth" },
    ["Redridge Mountains"] = { 15, 25, "Raw Bristle Whisker Catfish, Raw Rockscale Cod" },
    ["Ashenvale"] = { 18, 30, "Raw Bristle Whisker Catfish, Raw Rockscale Cod, Oily Blackmouth" },
    ["Duskwood"] = { 18, 30, "Raw Bristle Whisker Catfish, Raw Rockscale Cod" },
    ["Hillsbrad Foothills"] = { 20, 30, "Raw Bristle Whisker Catfish, Raw Rockscale Cod, Oily Blackmouth" },
    ["Wetlands"] = { 20, 30, "Raw Rockscale Cod, Raw Bristle Whisker Catfish, Oily Blackmouth" },
    ["Arathi Highlands"] = { 30, 40, "Raw Rockscale Cod, Raw Spotted Yellowtail" },
    ["Desolace"] = { 30, 40, "Raw Spotted Yellowtail, Raw Rockscale Cod" },
    ["Stranglethorn Vale"] = { 30, 45, "Raw Spotted Yellowtail, Raw Rockscale Cod, " .. SW },
    ["Dustwallow Marsh"] = { 35, 45, "Raw Spotted Yellowtail, Raw Rockscale Cod, Oily Blackmouth" },
    ["Swamp of Sorrows"] = { 35, 45, "Raw Spotted Yellowtail, Raw Rockscale Cod" },
    ["Tanaris"] = { 40, 50, "Raw Glossy Mightfish, Raw Spotted Yellowtail, Firefin Snapper" },
    ["Feralas"] = { 40, 50, "Raw Glossy Mightfish, Raw Spotted Yellowtail, Firefin Snapper" },
    ["The Hinterlands"] = { 40, 50, "Raw Glossy Mightfish, Raw Summer Bass" },
    ["Azshara"] = { 45, 55, "Raw Glossy Mightfish, Raw Nightfin Snapper, Oily Blackmouth" },
    ["Un'Goro Crater"] = { 48, 55, "Raw Glossy Mightfish, Raw Summer Bass" },
    ["Felwood"] = { 48, 55, "Raw Glossy Mightfish, Raw Summer Bass" },
    ["Western Plaguelands"] = { 51, 58, "Raw Glossy Mightfish, Raw Summer Bass" },
    ["Eastern Plaguelands"] = { 53, 60, "Raw Glossy Mightfish, Raw Summer Bass" },
    ["Winterspring"] = { 53, 60, "Raw Glossy Mightfish, Raw Summer Bass, Raw Nightfin Snapper" },
    ["Silithus"] = { 55, 60, "Raw Glossy Mightfish, Raw Nightfin Snapper, Stonescale Eel" },
}
F.ZONE_FISH = G

local function caught(zone)
    local list = F.Log and F.Log.ZoneList and F.Log.ZoneList(zone)
    if not list or #list == 0 then return nil end
    local parts, total = {}, 0
    for i, e in ipairs(list) do
        total = total + (e.count or 0)
        if i <= 6 then parts[#parts + 1] = ("%d %s"):format(e.count or 0, (e.name or "?"):gsub("^Raw ", "")) end
    end
    return table.concat(parts, ", "), total
end

local box
local function build()
    if box or not WorldMapFrame then return box end
    box = CreateFrame("Frame", "FishieZoneInfo", WorldMapFrame, "BackdropTemplate")
    box:SetFrameStrata("TOOLTIP")
    box:SetSize(300, 50)
    box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    box:SetBackdropColor(0.06, 0.06, 0.08, 0.9)
    box:SetBackdropBorderColor(0.35, 0.65, 0.95, 0.8)
    box.title = box:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    box.title:SetPoint("TOPLEFT", 8, -6)
    box.body = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    box.body:SetPoint("TOPLEFT", box.title, "BOTTOMLEFT", 0, -3)
    box.body:SetWidth(284)
    box.body:SetJustifyH("LEFT")
    box.body:SetSpacing(2)
    box:Hide()
    return box
end

-- the zone under the cursor (OpenMap's stitched map, or the game's own)
local function zoneUnderCursor()
    local api = _G.OpenMapAPI
    if api and api.IsStitched and api.IsStitched() then
        local u, v = api.CursorPosition()
        if u then return api.MapAt(u, v) end
    end
    local view = WorldMapFrame.GetMapID and WorldMapFrame:GetMapID()
    local sc = WorldMapFrame.ScrollContainer
    if view and sc and sc.GetNormalizedCursorPosition and C_Map and C_Map.GetMapInfoAtPosition then
        local x, y = sc:GetNormalizedCursorPosition()
        if x and y and x >= 0 and x <= 1 and y >= 0 and y <= 1 then
            local info = C_Map.GetMapInfoAtPosition(view, x, y)
            if info and info.mapID then return info.mapID end
        end
    end
    return view
end

local function nameOf(id)
    local info = id and C_Map and C_Map.GetMapInfo and C_Map.GetMapInfo(id)
    return info and info.name
end
local function pickZone()
    local ids = { zoneUnderCursor(), WorldMapFrame.GetMapID and WorldMapFrame:GetMapID(), C_Map and C_Map.GetBestMapForUnit and C_Map.GetBestMapForUnit("player") }
    for _, id in ipairs(ids) do
        local n = nameOf(id)
        if n and (G[n] or caught(n)) then return id end
    end
    return ids[1]
end
function F.ZoneDebug()
    local api = _G.OpenMapAPI
    local id = WorldMapFrame and pickZone()
    local n = nameOf(id)
    print(("|cff6ab0f5Fishie:|r zone box: %s, OpenMap %s, stitched %s, zone %s (%s), guide %s, setting %s, map shown %s"):format(
        box and "built" or "not built", api and "present" or "absent", tostring(api and api.IsStitched and api.IsStitched()),
        tostring(id), tostring(n), tostring(n and G[n] ~= nil), tostring(F.db and F.db.zoneInfo), tostring(WorldMapFrame and WorldMapFrame:IsShown())))
end

local function refresh()
    if not (F.db and F.db.zoneInfo) then if box then box:Hide() end return end
    build()
    local mapID = pickZone()
    local name = nameOf(mapID)
    local guide = name and G[name]
    local mine, total = nil, nil
    if name then mine, total = caught(name) end
    if not guide and not mine then box:Hide() return end
    box.title:SetText(guide and ("%s  |cff9a9aa0(level %d-%d)|r"):format(name, guide[1], guide[2]) or name)
    local lines = {}
    if guide then lines[#lines + 1] = "|cff6ab0f5Fish:|r " .. guide[3] end
    if mine then lines[#lines + 1] = ("|cffffd140You gathered here (%d):|r %s"):format(total, mine) end
    box.body:SetText(table.concat(lines, "\n"))
    box:SetHeight(box.title:GetStringHeight() + box.body:GetStringHeight() + 18)
    box:ClearAllPoints()
    -- sits bottom-right so it doesn't collide with Forager's box at the bottom-left
    box:SetPoint("BOTTOMRIGHT", WorldMapFrame, "BOTTOMRIGHT", -14, 14)
    box:Show()
end

local t = 0
local drv = CreateFrame("Frame")
drv:SetScript("OnUpdate", function(_, dt)
    t = t + dt
    if t < 0.15 then return end
    t = 0
    if WorldMapFrame and WorldMapFrame:IsShown() then
        local ok, err = pcall(refresh)
        if not ok and F.ReportError then F.ReportError("Zones", err) end
    elseif box then box:Hide() end
end)
