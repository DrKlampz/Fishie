# Fishie

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
