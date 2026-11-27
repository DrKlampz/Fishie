local ADDON_NAME, F = ...
-- Window customization (see Look.lua). Opens from the minimap button (Alt-click).
if not F.WinLook then return end
local function Options()
    local L = F.WinLook
    local db = function() return F.db end
    local function hud() if F.UI and F.UI.ApplyHUD then F.UI.ApplyHUD() end end
    local function counter() if F.Counter then F.Counter.Apply() F.Counter.Refresh() end end
    local function pools() if F.Pools then F.Pools.Changed() pcall(F.Pools.RefreshWorld) pcall(F.Pools.RefreshMini) end end
    local mmdb = function() return F.db.minimap end
    return { sections = {
        { id = "cast", title = "Casting", open = true, rows = {
            L.Koff("Right-click to cast (needs a pole in hand)", db, "doubleClick"),
            L.Choice("Mouse button", db, "castButton", { { "BUTTON2", "Right button" }, { "BUTTON1", "Left button" }, { "BUTTON3", "Middle button" }, { "BUTTON4", "Side button 1 (Button 4)" }, { "BUTTON5", "Side button 2 (Button 5)" } }),
            L.Choice("Cast with", db, "castClicks", { { 1, "Single click" }, { 2, "Double-click" } }),
            L.Choice("Double-click speed", db, "clickWindow", { { 0.25, "Fast (0.25s)" }, { 0.4, "Normal (0.4s)" }, { 0.6, "Slow (0.6s)" }, { 0.8, "Slower (0.8s)" } }),
            L.Choice("Hold a key while double-clicking", db, "clickMod", { { "none", "No key" }, { "shift", "Shift" }, { "ctrl", "Ctrl" }, { "alt", "Alt" } }),
            L.Koff("Right-click loots the bobber (no aiming)", db, "autoCatch"),
            L.Choice("Ignore right-click for the first", db, "catchDelay", { { 0, "No wait" }, { 2, "2 seconds" }, { 3, "3 seconds" }, { 4, "4 seconds" }, { 5, "5 seconds" }, { 7, "7 seconds" } }),
            L.Choice("Plus a random extra wait", db, "catchJitter", { { 0, "None" }, { 1, "Up to 1 second" }, { 1.5, "Up to 1.5 seconds" }, { 2, "Up to 2 seconds" }, { 3, "Up to 3 seconds" } }),
            L.Koff("Auto-loot while fishing", db, "autoLoot"),
            L.Note("Right-click casts; right-click again when the bobber splashes. Bind a key under Options > Key Bindings > Fishie to cast without the mouse."),
        } },
        { id = "pools", title = "Pools and fishing spots", open = true, rows = {
            L.Koff("Remember the pools I fish", db, "poolLearn"),
            L.Koff("Only show them for a character that has Fishing", db, "poolNeedProf", pools),
            L.Koff("Icons on the world map", db, "poolMap", pools),
            L.Koff("Icons on the minimap", db, "poolMini", pools),
            L.Koff("Show pool spawn points from ForeverDB.net", db, "poolSpawns", pools),
            L.Koff("Also show plain open-water spots (where players fished, not pools)", db, "poolOpen", pools),
            L.Koff("Include Classic spawn points nobody has seen in Forever", db, "poolClassic", pools),
            L.Koff("Show icons when zoomed out to a continent or the world", db, "poolFar", pools),
            L.Slider("World map icon size", db, "poolSize", 4, 40, 1, "%d", pools),
            L.Slider("Minimap icon size", db, "poolMiniSize", 4, 40, 1, "%d", pools),
            L.Slider("Icon opacity", db, "poolAlpha", 0.3, 1, 0.05, "%.2f", pools),
            L.Choice("Most icons on the world map", db, "poolMax", { { 100, "100" }, { 200, "200" }, { 300, "300" }, { 600, "600" } }, pools),
        } },
        { id = "gear", title = "Pole and lures", open = true, rows = {
            L.Koff("Equip a pole when you double-click without one", db, "autoPole"),
            L.Koff("Put a lure on the pole when it has none", db, "autoLure"),
            L.Koff("Replace a lure that is about to run out", db, "refreshLure"),
            L.Koff("Warn when the lure is about to run out", db, "warnLure"),
            L.Choice("Lure to use first", db, "lureChoice", { { "best", "Strongest" }, { "weakest", "Weakest" } }),
            L.Choice("Back to normal gear after", db, "autoReturn", { { 0, "Never" }, { 5, "5 minutes" }, { 10, "10 minutes" }, { 20, "20 minutes" } }),
        } },
        { id = "counter", title = "Catch counter", open = true, rows = {
            L.Koff("Show the catch counter", db, "showCounter", counter),
            L.Koff("Counter: only with a fishing pole equipped", db, "counterPoleOnly", counter),
            L.Koff("Counter: show the all-time total", db, "counterTotal", counter),
            L.Koff("Counter: show catches per hour", db, "counterRate", counter),
            L.Koff("Also keep a list of the chests, clams and crates I open (off: only what I fish up)", db, "keepOpensList"),
            L.Koff("Counter: lock its position", db, "counterLock"),
            L.Note("Hover the counter for this session's catches; right-click it to reset the session."),
        } },
        { id = "extras", title = "Sound, chat and display", rows = {
            L.Koff("Turn up effects, turn down music while fishing", db, "boostSound"),
            L.Koff("Turn music and ambience down while a fishing pole is equipped", db, "muffle", function() if F.Cast then F.Cast.ApplyMuffle() end end),
            L.Choice("Music, ambience and voices stay at", db, "muffleLevel", { { 0, "Silent" }, { 0.1, "10%" }, { 0.25, "25%" }, { 0.5, "50%" }, { 0.75, "75%" } }, function() if F.Cast then F.Cast.ApplyMuffle() end end),
            L.Koff("Chat line for each catch", db, "announce"),
            L.Koff("Show the on-screen fishing box", db, "showHUD", hud),
            L.Koff("Show the minimap button", mmdb, "show", function() if F.UI and F.UI.UpdateMinimap then F.UI.UpdateMinimap() end end),
        } },
    } }
end

F.WinLook.Setup({
    options = Options,
    title = "Fishie",
    syncDefault = false,
    media = "Interface\\AddOns\\Fishie\\Media\\",
    db = function() return FishieDB end,
    windows = {
        { id = "main", name = "Main window", global = "FishieFrame", strip = "backdrop", hide = { "bar" }, defaultOn = true, title = function(f) return f.title end, close = function(f) return f.closeBtn end },
        { id = "hud", name = "On-screen HUD", global = "FishieHUD", strip = "backdrop", noScale = true },
        { id = "counter", name = "Catch counter", global = "FishieCounter", strip = "backdrop", noScale = true },
    },
})
