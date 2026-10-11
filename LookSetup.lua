local ADDON_NAME, F = ...
-- Window customization (see Look.lua). Opens from the minimap button (Alt-click).
if not F.WinLook then return end
local function Options()
    local L = F.WinLook
    local db = function() return F.db end
    local function hud() if F.UI and F.UI.ApplyHUD then F.UI.ApplyHUD() end end
    local mmdb = function() return F.db.minimap end
    return { sections = {
        { id = "cast", title = "Casting", open = true, rows = {
            L.Koff("Right-click to cast (needs a pole in hand)", db, "doubleClick"),
            L.Choice("Cast with", db, "castClicks", { { 1, "Single click" }, { 2, "Double-click" } }),
            L.Choice("Double-click speed", db, "clickWindow", { { 0.25, "Fast (0.25s)" }, { 0.4, "Normal (0.4s)" }, { 0.6, "Slow (0.6s)" }, { 0.8, "Slower (0.8s)" } }),
            L.Choice("Hold a key while double-clicking", db, "clickMod", { { "none", "No key" }, { "shift", "Shift" }, { "ctrl", "Ctrl" }, { "alt", "Alt" } }),
            L.Koff("Right-click loots the bobber (no aiming)", db, "autoCatch"),
            L.Koff("Auto-loot while fishing", db, "autoLoot"),
            L.Note("Right-click casts; right-click again when the bobber splashes. Bind a key under Options > Key Bindings > Fishie to cast without the mouse."),
        } },
        { id = "gear", title = "Pole and lures", open = true, rows = {
            L.Koff("Equip a pole when you double-click without one", db, "autoPole"),
            L.Koff("Put a lure on the pole when it has none", db, "autoLure"),
            L.Koff("Replace a lure that is about to run out", db, "refreshLure"),
            L.Koff("Warn when the lure is about to run out", db, "warnLure"),
            L.Choice("Lure to use first", db, "lureChoice", { { "best", "Strongest" }, { "weakest", "Weakest" } }),
            L.Choice("Back to normal gear after", db, "autoReturn", { { 0, "Never" }, { 5, "5 minutes" }, { 10, "10 minutes" }, { 20, "20 minutes" } }),
        } },
        { id = "extras", title = "Sound, chat and display", rows = {
            L.Koff("Turn up effects, turn down music while fishing", db, "boostSound"),
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
        { id = "main", name = "Main window", global = "FishieFrame", strip = "template", defaultOn = true, title = function(f) return f.TitleText end },
        { id = "hud", name = "On-screen HUD", global = "FishieHUD", strip = "backdrop", noScale = true },
    },
})
