-- Fishie gear: finding your pole and lures, and the fishing outfit.
local ADDON_NAME, F = ...
local G = {}
F.Gear = G

local MAINHAND = 16
local SLOTS = {}
for i = 1, 19 do if i ~= 4 and i ~= 18 then SLOTS[#SLOTS + 1] = i end end   -- not shirt, not ammo
G.SLOTS = SLOTS

-- Lures, best first. bonus = fishing skill added for 10 minutes.
G.LURES = {
    { 6533, 100 },  -- Aquadynamic Fish Attractor
    { 34861, 100 }, -- Sharpened Fish Hook
    { 7307, 75 },   -- Flesh Eating Worm
    { 6532, 75 },   -- Bright Baubles
    { 6811, 50 },   -- Aquadynamic Fish Lens
    { 6530, 50 },   -- Nightcrawlers
    { 6529, 25 },   -- Shiny Bauble
}

local function Count(itemID)
    if C_Item and C_Item.GetItemCount then return C_Item.GetItemCount(itemID) or 0 end
    return GetItemCount and GetItemCount(itemID) or 0
end

local function ClassOf(link)
    if not link then return end
    if C_Item and C_Item.GetItemInfoInstant then
        local _, _, _, _, _, classID, subID = C_Item.GetItemInfoInstant(link)
        return classID, subID
    end
    if GetItemInfoInstant then
        local _, _, _, _, _, classID, subID = GetItemInfoInstant(link)
        return classID, subID
    end
end

local function BagLinks()
    local out = {}
    local n = (NUM_BAG_SLOTS or 4)
    for bag = 0, n do
        local slots = C_Container and C_Container.GetContainerNumSlots(bag) or GetContainerNumSlots(bag)
        for slot = 1, (slots or 0) do
            local link = C_Container and C_Container.GetContainerItemLink(bag, slot) or GetContainerItemLink(bag, slot)
            if link then out[#out + 1] = link end
        end
    end
    return out
end

-- Fishing poles are weapons (class 2), subclass 20.
function G.IsPole(link)
    local c, s = ClassOf(link)
    return c == 2 and s == 20
end

function G.EquippedPole()
    local link = GetInventoryItemLink("player", MAINHAND)
    if link and G.IsPole(link) then return link end
end

function G.BagPole()
    for _, link in ipairs(BagLinks()) do
        if G.IsPole(link) then return link end
    end
end

---------------------------------------------------------------------------
-- Lures
---------------------------------------------------------------------------
-- Best lure in your bags: itemID, bonus; or nil.
function G.BestLure()
    for _, l in ipairs(G.LURES) do
        if Count(l[1]) > 0 then return l[1], l[2] end
    end
end

-- Does the pole already carry a lure or other enchant?
function G.PoleHasLure()
    if not GetWeaponEnchantInfo then return false end
    local has = GetWeaponEnchantInfo()
    return has and true or false
end

-- Macro text that applies a lure to the pole, or nil when none is needed or available.
function G.LureMacro()
    if not (F.db and F.db.autoLure) then return nil end
    if not G.EquippedPole() or G.PoleHasLure() then return nil end
    local id = G.BestLure()
    if not id then return nil end
    return ("/use item:%d\n/use %d"):format(id, MAINHAND)
end

function G.ApplyLureNow()
    local id, bonus = G.BestLure()
    if not G.EquippedPole() then F.Print("Equip a fishing pole first.") return end
    if not id then F.Print("No lures in your bags.") return end
    if G.PoleHasLure() then F.Print("Your pole already has a lure.") return end
    F.Print(("Use item %d, then click your pole (+%d fishing)."):format(id, bonus))
end

---------------------------------------------------------------------------
-- The fishing outfit
---------------------------------------------------------------------------
local function Snapshot()
    local t = {}
    for _, slot in ipairs(SLOTS) do
        local link = GetInventoryItemLink("player", slot)
        if link then t[slot] = link end
    end
    return t
end

local function Same(a, b)
    if not a or not b then return false end
    local ia = tonumber(tostring(a):match("item:(%d+)"))
    local ib = tonumber(tostring(b):match("item:(%d+)"))
    return ia ~= nil and ia == ib
end

-- Remember what you're wearing right now as the fishing outfit.
function G.SaveOutfit()
    if not G.EquippedPole() then
        F.Print("Put on your fishing pole and the gear you fish in first, then save.")
        return false
    end
    F.db.outfit = Snapshot()
    F.db.fishing = true
    F.Print("Saved what you're wearing as your fishing outfit.")
    if F.UI then F.UI.Refresh() end
    return true
end

local function Equip(link, slot)
    if EquipItemByName then EquipItemByName(link, slot) elseif C_Item and C_Item.EquipItemByName then C_Item.EquipItemByName(link, slot) end
end

local function Dress(set)
    local changed = 0
    for _, slot in ipairs(SLOTS) do
        local want = set[slot]
        if want and not Same(GetInventoryItemLink("player", slot), want) then
            Equip(want, slot)
            changed = changed + 1
        end
    end
    return changed
end
G.Dress = Dress

-- Switch between the fishing outfit and what you wore before.
function G.Switch()
    return F.AfterCombat(function()
        if F.db.fishing then
            local n = Dress(F.db.normal)
            F.db.fishing = false
            F.Print(n > 0 and "Back in your normal gear." or "Nothing to swap back to.")
        else
            if next(F.db.outfit) == nil then
                -- first time: build an outfit around the best pole we can find
                local pole = G.EquippedPole() or G.BagPole()
                if not pole then F.Print("No fishing pole found in your bags.") return end
                F.db.normal = Snapshot()
                Equip(pole, MAINHAND)
                F.db.fishing = true
                F.Print("Pole equipped. Put on your fishing gear and type /fishie save to remember it.")
            else
                F.db.normal = Snapshot()
                -- never record a pole as the "normal" main hand
                local main = F.db.normal[MAINHAND]
                if main and not G.IsPole(main) then F.db.normalWeapon = main end
                if G.EquippedPole() then F.db.normal[MAINHAND] = F.db.normalWeapon end
                Dress(F.db.outfit)
                F.db.fishing = true
                F.Print("Fishing outfit on.")
            end
        end
        if F.UI then F.UI.Refresh() end
    end)
end

-- Called before a cast: make sure there is a pole in hand.
function G.EnsurePole()
    if G.EquippedPole() then return true end
    if not (F.db and F.db.autoPole) then return false end
    local main = GetInventoryItemLink("player", MAINHAND)
    if main then F.db.normalWeapon = main end
    local pole = G.BagPole()
    if not pole then F.Print("No fishing pole to equip.") return false end
    F.AfterCombat(function()
        F.db.normal = Snapshot()
        if next(F.db.outfit) ~= nil then Dress(F.db.outfit) else Equip(pole, MAINHAND) end
        F.db.fishing = true
        if F.UI then F.UI.Refresh() end
    end)
    return false   -- the gear needs a moment; the next double-click casts
end

function G.Probe()
    local pole = G.EquippedPole()
    F.Print("Pole in hand: " .. (pole or "none"))
    F.Print("Pole in bags: " .. (G.BagPole() or "none"))
    local has, exp = false, nil
    if GetWeaponEnchantInfo then has, exp = GetWeaponEnchantInfo() end
    F.Print(("Lure on pole: %s%s"):format(tostring(has), exp and (" (" .. math.floor(exp / 60000) .. " min left)") or ""))
    local id, bonus = G.BestLure()
    F.Print("Best lure in bags: " .. (id and ("item " .. id .. " (+" .. bonus .. ")") or "none"))
    F.Print("Fishing spell: " .. tostring(F.Cast and F.Cast.SpellName() or "?"))
end
