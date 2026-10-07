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

-- Fishing poles are weapons (class 2), subclass 20. Fall back to the item's own type text and
-- to the known pole IDs, in case this client numbers things differently.
G.POLE_IDS = { [6256] = true, [6365] = true, [6366] = true, [6367] = true, [12225] = true,
    [19022] = true, [19970] = true, [25978] = true, [44050] = true, [45858] = true, [45991] = true,
    [45992] = true, [46337] = true, [84660] = true, [84661] = true }

local function ItemID(link)
    return tonumber(tostring(link or ""):match("item:(%d+)"))
end
G.ItemID = ItemID

function G.IsPole(link)
    if not link or F.IsSecret(link) then return false end
    local id = ItemID(link)
    if id and G.POLE_IDS[id] then return true end
    local c, s = ClassOf(link)
    if c == 2 and s == 20 then return true end
    local info = (C_Item and C_Item.GetItemInfo) or GetItemInfo
    if info then
        local ok, _, _, _, _, _, _, itemType, subType = pcall(info, link)
        if ok and type(subType) == "string" and subType:lower():find("fishing", 1, true) then return true end
        if ok and type(itemType) == "string" and itemType:lower():find("fishing", 1, true) then return true end
    end
    return false
end

function G.EquippedPole()
    local link = GetInventoryItemLink("player", MAINHAND)
    if link and G.IsPole(link) then return link end
end

-- bag, slot, link of a pole in your bags
function G.BagPole()
    local n = (NUM_BAG_SLOTS or 4)
    for bag = 0, n do
        local slots = C_Container and C_Container.GetContainerNumSlots(bag) or GetContainerNumSlots(bag)
        for slot = 1, (slots or 0) do
            local link = C_Container and C_Container.GetContainerItemLink(bag, slot) or GetContainerItemLink(bag, slot)
            if link and G.IsPole(link) then return link, bag, slot end
        end
    end
end

---------------------------------------------------------------------------
-- Lures
---------------------------------------------------------------------------
-- The lure to use from your bags: itemID, bonus; or nil. "best" or "weakest" first, by setting.
function G.BestLure()
    local weakest = F.db and F.db.lureChoice == "weakest"
    local first, last = 1, #G.LURES
    local step = 1
    if weakest then first, last, step = #G.LURES, 1, -1 end
    for i = first, last, step do
        local l = G.LURES[i]
        if Count(l[1]) > 0 then return l[1], l[2] end
    end
end

-- Seconds left on the pole's lure, or nil when there is none.
function G.LureTimeLeft()
    if not GetWeaponEnchantInfo then return nil end
    local has, exp = GetWeaponEnchantInfo()
    if not has then return nil end
    return exp and (exp / 1000) or 9999
end

-- Does the pole already carry a lure? A lure with under a minute left counts as none, when
-- replacing them is switched on.
function G.PoleHasLure()
    local left = G.LureTimeLeft()
    if not left then return false end
    if F.db and F.db.refreshLure and left < 60 then return false end
    return true
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

local function Equip(link, slot, bag, bslot)
    F.Debug(("equip %s into slot %d"):format(tostring(link), slot))
    local ok, err
    if EquipItemByName then ok, err = pcall(EquipItemByName, link, slot)
    elseif C_Item and C_Item.EquipItemByName then ok, err = pcall(C_Item.EquipItemByName, link, slot) end
    if ok == false then F.Debug("equip call failed: " .. tostring(err)) end
    -- if the game ignored that, using the item from the bag equips it the same way
    if bag and bslot then
        C_Timer.After(0.4, function()
            local now = GetInventoryItemLink("player", slot)
            if ItemID(now) ~= ItemID(link) then
                F.Debug(("still not equipped; using bag %d slot %d"):format(bag, bslot))
                local use = (C_Container and C_Container.UseContainerItem) or UseContainerItem
                if use then local ok2, e2 = pcall(use, bag, bslot) if not ok2 then F.Debug("use failed: " .. tostring(e2)) end end
            end
        end)
    end
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
                local pole, pbag, pslot = G.BagPole()
                pole = G.EquippedPole() or pole
                if not pole then F.Print("No fishing pole found in your bags.") return end
                F.db.normal = Snapshot()
                Equip(pole, MAINHAND, pbag, pslot)
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
    local pole, pbag, pslot = G.BagPole()
    if not pole then F.Print("No fishing pole to equip. (Fishie looks for any item that is a Fishing Pole in your bags.)") return false end
    F.AfterCombat(function()
        F.db.normal = Snapshot()
        if next(F.db.outfit) ~= nil then Dress(F.db.outfit) end
        if not G.EquippedPole() then Equip(pole, MAINHAND, pbag, pslot) end
        F.db.fishing = true
        if F.UI then F.UI.Refresh() end
    end)
    return false   -- the gear needs a moment; the next double-click casts
end

function G.Probe()
    local pole = G.EquippedPole()
    F.Print("Pole in hand: " .. (pole or "none"))
    F.Print("Pole in bags: " .. (G.BagPole() or "none"))
    local main = GetInventoryItemLink("player", MAINHAND)
    if main then
        local c, s = ClassOf(main)
        F.Print(("Main hand: %s  class=%s sub=%s isPole=%s"):format(main, tostring(c), tostring(s), tostring(G.IsPole(main))))
    end
    F.Print(("API: IsFishingLoot=%s EquipItemByName=%s C_Container=%s UnitChannelInfo=%s"):format(
        tostring(IsFishingLoot ~= nil), tostring(EquipItemByName ~= nil), tostring(C_Container ~= nil), tostring(UnitChannelInfo ~= nil)))
    local has, exp = false, nil
    if GetWeaponEnchantInfo then has, exp = GetWeaponEnchantInfo() end
    F.Print(("Lure on pole: %s%s"):format(tostring(has), exp and (" (" .. math.floor(exp / 60000) .. " min left)") or ""))
    local id, bonus = G.BestLure()
    F.Print("Best lure in bags: " .. (id and ("item " .. id .. " (+" .. bonus .. ")") or "none"))
    F.Print("Fishing spell: " .. tostring(F.Cast and F.Cast.SpellName() or "?"))
end
