# Fishie

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
