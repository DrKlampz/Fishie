local ADDON_NAME, F = ...
-- Window customization (see Look.lua). Opens from the minimap button (Alt-click).
if not F.WinLook then return end
F.WinLook.Setup({
    title = "Fishie",
    syncDefault = false,
    media = "Interface\\AddOns\\Fishie\\Media\\",
    db = function() return FishieDB end,
    windows = {
        { id = "main", name = "Main window", global = "FishieFrame", strip = "template", defaultOn = true, title = function(f) return f.TitleText end },
        { id = "hud", name = "On-screen HUD", global = "FishieHUD", strip = "backdrop", noScale = true },
    },
})
