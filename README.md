# Fishie

A fishing helper for **WoW: Forever**, in the spirit of Fishing Buddy.

- **Double right-click to cast.** Right-click twice quickly on the world and Fishie casts Fishing. If you
  have no pole in hand, the first double-click equips one.
- **Automatic lures.** When your pole has no lure, the double-click applies the best one in your bags
  (Aquadynamic Fish Attractor, Flesh Eating Worm, Bright Baubles, Nightcrawlers, Shiny Bauble ...).
  Click again to cast.
- **Fishing outfit.** Put on your fishing gear, type `/fishie save`, and from then on `/fishie switch` (or
  right-click the minimap button) swaps between it and your normal gear.
- **Catch log.** Everything you fish up is counted per zone and per session, with catches per hour.
- **Sound boost.** Effects up, music and ambience down while your line is out, restored afterwards.
- **Skill display** and a small window (`/fishie`) with session stats, catches by zone and settings.

The game needs a real click for every cast, so casting is never fully automatic.

## Commands

| Command | What it does |
|---|---|
| `/fishie` | Open the window |
| `/fishie switch` | Fishing outfit on or off |
| `/fishie save` | Remember what you're wearing as your fishing outfit |
| `/fishie stats` / `reset` | Print or reset this session |
| `/fishie doubleclick`, `lure`, `pole`, `sound`, `announce` | Toggle a feature (add `on` or `off`) |
| `/fishie probe` | Show what the game reports about your pole and lures |

## Notes

Fishie has only been tested against a simulated game so far. If something doesn't work, run `/fishie probe`
and report what it says.
