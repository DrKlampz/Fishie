# Fishie

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
