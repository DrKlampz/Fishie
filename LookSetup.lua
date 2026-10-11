local ADDON_NAME, F = ...
-- Window customization (see Look.lua). Opens with /fishielook.
if not F.WinLook then return end
F.WinLook.Setup({
    title = "Fishie",
    slash = "fishielook",
    media = "Interface\\AddOns\\Fishie\\Media\\",
    db = function() return FishieDB end,
    windows = {
        { id = "main", name = "Main window", global = "FishieFrame", strip = "template", title = function(f) return f.TitleText end },
        { id = "hud", name = "On-screen HUD", global = "FishieHUD", strip = "backdrop", noScale = true },
    },
})
