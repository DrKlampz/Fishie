# Fishie

A fishing helper for **WoW: Forever**, in the spirit of Fishing Buddy.

- **Right-click to cast, right-click to catch.** With a pole in hand, a single right-click on the world
  casts Fishing. When the bobber splashes, right-click again and the fish is looted without aiming at the
  bobber. Both are plain right-clicks; the game needs a real click for each. Prefer a double-click to cast?
  Switch "Cast with" to double-click in Setup. With no pole in hand, a double-click equips one.
- **Automatic lures.** When your pole has no lure, the double-click applies the best one in your bags
  (Aquadynamic Fish Attractor, Flesh Eating Worm, Bright Baubles, Nightcrawlers, Shiny Bauble ...).
  Click again to cast.
- **Fishing outfit.** Put on your fishing gear, type `/fishie save`, and from then on `/fishie switch` (or
  right-click the minimap button) swaps between it and your normal gear.
- **Catch log.** Everything you fish up is counted per zone and per session, with catches per hour.
- **Sound boost.** Effects up, music and ambience down while your line is out, restored afterwards.
- **Options like Fishing Buddy:** double-click speed, an optional Shift/Ctrl/Alt to hold, strongest or weakest lure first, replace a lure that is about to run out (with a chat warning), auto-loot while fishing, go back to your normal gear after a quiet spell, a minimap button you can hide, and a key binding (Options > Key Bindings > Fishie).
- **On-screen box** (`/fishie hud`): time since your cast, lure time left and this session's catches.
- **Skill display** and a small window (`/fishie`) with session stats, catches by zone and settings.

The game needs a real click for every cast, so casting is never fully automatic.

## Commands

| Command | What it does |
|---|---|
| `/fishie` | Open the window |
| `/fishie switch` | Fishing outfit on or off |
| `/fishie save` | Remember what you're wearing as your fishing outfit |
| `/fishie stats` / `reset` | Print or reset this session |
| `/fishie doubleclick`, `lure`, `pole`, `sound`, `announce`, `refreshlure`, `warnlure`, `autoloot`, `hud` | Toggle a feature (add `on` or `off`) |
| `/fishie minimap` | Show or hide the minimap button |
| `/fishie debug` | Explain every click, cast and catch in chat |
| `/fishie probe` | Show what the game reports about your pole and lures |

## Notes

If something doesn't work, run `/fishie probe` and `/fishie debug on`, and report what they say.
