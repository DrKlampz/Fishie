# Fishie

## v0.4.21
- Every piece of artwork (corners, crest, edge pattern, title banner, divider, middle emblem) can now have its own color. New "Your file" emblem slots show your own faction, race and city images from the Media folder.

## v0.4.20
- More emblems: religious, Wiccan, Pagan, Druid, Satanic and occult symbols from many faiths, and the names are tidied.
- The artwork can have a color of its own (Artwork section): corners, crest, edges, banner, divider and the middle emblem.
- The close button in the top right can be restyled (the game's X, boxed, plain, red, filled or hidden) with its own size and color.
- The game-icon emblems (faction crests, race and city icons) are removed; looks that used them show your class emblem.
- Fixed the list preview staying open after a pick; the divider under the title no longer runs through the search row.

## v0.4.19
- Emblem list: Pinnacle star, Sunburst, Crown, Crossed swords, Flame and Compass rose; the game's own race sigils and city banners (Stormwind, Orgrimmar and the rest); religious symbols (cross, Celtic cross, Star of David, crescent and star, Wheel of Dharma, yin and yang, ankh, lotus, hamsa, triquetra, torii gate).
- Pointing at an entry in the emblem, corner, crest, edge, banner and divider lists shows a small preview of it.
- The Horde and Alliance crests use the game's round PvP emblem; the title banner is centered with the title.

## v0.4.18
- Gradients: pick both colors, each end's opacity, vertical, horizontal, diagonal, middle-out or center-to-borders, over or instead of the background texture; plus a theme with its own emblem, corners, crest and edge for every talent spec, and a "My spec" automatic theme.
- Look profiles: save your look under a name and switch between saved looks at any time; every character remembers which profile it wears (Look panel, top).
- World of Warcraft flavored art, all optional: nine class themes (Warrior to Druid) with an original emblem, corner pieces, crest and colors for each class, plus a "My class (automatic art)" theme that picks yours; Blue and gold kingdom, Red and iron war camp, Moonlit grove and Plaguelands themes; new spiked corners, horn, crescent and skull crests, and an iron spike edge. The emblem in the middle of the window can also show your class or your talent tree using the game's own icons. Find them in the window options under Colors > Theme and Artwork.
- More optional artwork for the window box: ornament strips along the edges (rope, chain, pearls, runes, vine), a banner behind the title (ribbon, riveted plaque, scroll, jeweled plate), a divider with an ornament under the title, and a faint emblem in the middle of the window (compass rose, shield, laurel wreath, star, runic rings). All in the new Artwork section of the window options; the eight art themes now use them, and the crest sits above the top edge.
- New optional artwork in the window look: seven textured backgrounds (wood planks, aged paper, arcane starfield, runed slate, riveted iron, damask tapestry, dragon scales), five carved corner pieces (filigree, vines, runes, iron plates, arcane sigil), four crests for the top edge (winged, jeweled, scrollwork, crown), and eight ready-made art themes (Arcane library, Dwarven forge, Elven glade, Old tome, Runestone, Royal court, Dragonscale, Oak lodge). Pick them in the window options (Colors > Theme, Background, Border > Corner artwork and Crest). Everything is off until you choose it and syncs between your add-ons like the rest of the look.
- Removed the add-on-to-add-on theming hooks and cross-add-on names from the window look code; the shared look sync between your add-ons works the same.
- The "Pulse the flair" option now also pulses the edge finish (soft, bevel, double line and glow), not just the corner studs.

## v0.4.17
- Look sync: the first time your add-ons meet, they now all take on the same look right away instead of waiting for you to change something.

## v0.4.16
- Your custom look is now shared with your other add-ons: change colors, background, border or opacity in one and the rest follow (the newest change wins). It is on by default; untick "Sync my look with my other add-ons" in the Look window to turn it off.
- The main window now sits above the on-screen HUD instead of sharing its layer.

## v0.4.14
- New option: choose which mouse button casts and loots the bobber (right, left, middle or the side buttons). It is in the options under Mouse button.

## v0.4.13
- New: with a fishing pole equipped, music, ambience and voices are turned down (to 25% by default, your choice in the options) so the splash and fish-on sound stand out. They come back when you take the pole off.
- While your line is out, effects and master volume go all the way up and voices are silenced too.

## v0.4.12
- Fix: the splash-sound and auto-loot settings are now applied once combat ends instead of being refused by the game mid-fight.

## v0.4.11
- Fix: each catch was counted and announced twice when auto-loot was on (the game sends its loot-ready event twice). One cast now counts once. Totals recorded before this update may be too high.

## v0.4.10
- Removed the bite sound. It played when the line was cast, not when a fish bit, because the game gives add-ons no way to tell. It may come back if a reliable signal turns up.

## v0.4.9
- New: the catch counter can show only while a fishing pole is equipped (on by default). Turn it off in Setup or the Look window to show it all the time.

## v0.4.8
- Shift-click on the minimap button turns the catch counter on and off.

## v0.4.7
- Fix: the catch counter and the bite sound were not loading (they started before the rest of the add-on was ready). They load properly now.

## v0.4.6
- Small internal tweaks.

## v0.4.4
- New: right-click does nothing for the first 3 seconds after a cast, so an early click can no longer pull the line in before a fish could bite. Change the wait (or turn it off) in Setup or the Look window under "Ignore right-click for the first". Needs "Right-click loots the bobber" on.

## v0.4.3
- Fix: catching a fish with right-click often took two or three clicks. Fishie handed the click back to the game whenever a tooltip showed under the cursor, and those clicks missed. Right-click now always interacts with the bobber through the game's pick-up target, which the debug log showed was the bobber every time.
- Debug log: each catch click and each change of pick-up target is recorded.

## v0.4.2
- /fishie debug now also keeps the last 500 debug lines in the saved data (they survive a /reload). /fishie debuglog shows the latest ones.

## v0.4.1
- Fix: right-click to catch the fish sometimes did nothing, so you had to click the bobber. The right-click now decides what to do before you click instead of during it, and the game's pick-up range and facing angle are widened while the line is out (put back afterwards), since the bobber often lands further than the default range.
- /fishie debug now also says what the right-click is aimed at while fishing.

## v0.4.0
- New: a catch counter, a small box that stays on screen with this session's catches, catches per hour and your all-time total. Hover it for what you caught this session, right-click to reset. Drag it anywhere, lock it, and restyle it from the Look window.
- New: a bite sound (and "Fish on!" at the top of the screen) when a fish bites. The game gives add-ons no bite event, so this reacts when the bobber becomes clickable. Pick the sound and the volume channel in the Look window. If it stays quiet for you, turn on /fishie debug and tell me what it prints.
- /fishie counter and /fishie bite turn them on and off.

## v0.3.5
- Fix: a crash ("attempt to call a nil value" in Gear.lua) when the game had an empty bag slot.
- Fonts: the font pack now ships inside this add-on (Fonts folder), so the separate Look Fonts add-on is no longer needed, and there are about 60 more fonts to pick from under Look > Font.

## v0.3.4
- Log and error reporting improvements; /issues log.

## v0.3.3
- Shared look: background color picker, 13 new backgrounds with brightness and grain, a gold trim option, and buttons and slots stay visible on a pure black panel.

## v0.3.0
- New: window customization. Alt-click the minimap button to restyle each window separately (or all together): background textures, colors with copy/paste, opacity sliders, border styles, fonts, scale and position lock. Over 50 fonts to pick from (install the LookFonts folder for the bundled ones; SharedMedia fonts show up too). Off until you tick "Use a custom look"; unticking restores the original. All of the add-on's options now live in that same window, on an Options tab, and the window itself wears the first window's look.

## v0.2.10
- Windows no longer bleed through each other: clicking the Fishie window raises it above other addon windows.

## v0.2.9
- Fix: Fishie no longer puts your pole on by itself after combat (or any time you aren't fishing). A double right-click happens constantly while playing, and with "Equip a pole when you click without one" on, that was enough. The auto-equip now only happens in a fishing session: the fishing outfit is on, you fished within the last 10 minutes, or you've set a modifier key and are holding it. Start a session with `/fishie`, the key binding, or the HUD button.

## v0.2.4
- Right-click is no longer held after fishing: the catch binding only lives while a line is actually out, a watchdog frees it within half a second of the line coming in, and it is released after combat if the stop happened mid-fight.
- `/fishie release` gives right-click back to the game if it ever feels stuck.

## v0.2.3
- Catch is more reliable: with the line out, a right-click on the bobber uses the game's normal click, and a right-click anywhere else interacts with your soft target. Before, the second case replaced the first, so the catch only worked when the bobber happened to be your soft target.
- A click can no longer recast over a line that is waiting for a bite, and a cast started in combat can't leave right-click dead afterwards.

## v0.2.2
- Cast is now a single right-click (with a pole in hand and no line out); catching the fish is also a right-click. "Cast with: double-click" in Setup brings the old behavior back.
- Fishie's window, on-screen box and minimap button now sit on the HIGH frame strata so other windows don't cover them.
- Setup tab explains how the two right-clicks work.

## v0.2.1
- Auto catch: while your line is out, right-click loots the bobber wherever the cursor is (no aiming). Fishie turns on the game's soft-target interact for that and puts everything back when the line comes in. The game still needs your click; an addon can't press it for you. Turn off in Setup if you want normal right-click camera control while fishing.
- Catch tracking has two more ways to see a catch: LOOT_READY, and a bag check after each cast if neither the loot window nor the chat line was readable. Nothing is counted twice.

## v0.2.0
- Setup tab with many more options: double-click speed, a key to hold, strongest or weakest lure first, replace lures that are about to run out, lure warning, auto-loot while fishing, back to normal gear after 5/10/20 quiet minutes, hide the minimap button.
- On-screen fishing box (`/fishie hud`) with cast timer, lure time left and catches.
- Key binding for casting (Options > Key Bindings > Fishie); it puts a lure on first when the pole needs one.

## v0.1.1
- Catches are now counted even if the game's fishing-loot check is missing: Fishie also counts the loot window and "You receive loot" chat line for a short time after each fishing cast.
- Finding and equipping a fishing pole is more forgiving (item type text, known pole IDs, and using the pole from the bag if the equip call is ignored).
- `/fishie debug` explains every click, cast and catch in chat; `/fishie probe` shows more detail.

## v0.1.0
- First release: double right-click casting, automatic lures, fishing outfit, catch log, sound boost.
