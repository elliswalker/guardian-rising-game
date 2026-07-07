---
title: Asset Review
aliases: [Character Review, Sprite Review, Design Review]
tags:
  - guardian-rising
  - pixel-art
  - production
created: 2026-07-06
updated: 2026-07-07
---

# Asset Review
← [[00 - Production Guide]] ← [[Asset Manifest]] ← [[SESSION HANDOFF]]

> Review board for the game's art. **Style: high-fidelity PixelLab Pro.** Contact sheets grouped by category; previews live in `_review/pro/`.
> **Protagonist:** the **Guardian** (rides the Sparrow). **Speaker** = camp anchor NPC.

**Legend:** ✅ shipped to `Game/assets/` · 🟡 generated in Pro (pending ship) · ⬜ not started

---

## 1 · Characters — Player & NPCs
![[sheet_characters.png]]

- **Guardian** 🟡 protagonist · **Speaker** 🟡 camp NPC · **Frame** base/defender/builder/sweeper 🟡

### Guardian on Sparrow ✅  ·  Ghost ✅
| Guardian on Sparrow | Ghost |
|---|---|
| ![[guardian_sparrow_right_4x.png]] | ![[ghost_final_right_6x.png]] |

Both shipped to `player/`.

### Super NPCs — Ghost abilities 🟡
![[sheet_supers.png]]
Titan (arc hammer) · Hunter (void bow) · Warlock (solar sword) — represent the three class supers.

---

## 2 · Enemies — full roster 🟡
![[sheet_enemies.png]]

| Faction | Units |
|---|---|
| **Vex** | Goblin ✅ · Hobgoblin · Minotaur · Harpy · Hydra |
| **Fallen** | Dreg ✅ · Vandal · **Captain** · **Shank** · Servitor |
| **Cabal** | Legionary ✅ · Phalanx · Psion · Colossus |
| **Hive** | Thrall · **Acolyte** · **Knight** · Wizard · **Ogre** (massive) |
| **Wildlife / small** | Scrap Drone · Sand Skitter · Hive Worm · **Bird** · **Critter** |

✅ = shipped · rest 🟡 generated in Pro, ready to ship. *(Bold = added this round.)*

---

## 3 · Structures & Buildings 🟡
![[sheet_structures.png]]

**Updated this round:** ➕ Moon Cliff, Mars Cliff · 🔁 War Banner (reworked to match the Battle Standard) · 🔁 Recruiting Post (Guardian-helmet icon instead of "?", flag color can vary per job) · Barricade (your update). ❌ **Military Camp removed** (no longer needed).

---

## 4 · Ship — repair progression 🟡
![[sheet_ship.png]]
Crashed → Disrepair → Mid-repair → Near-done → **Flyable** (hovering, engines lit). The campaign arc: rebuild the ship to escape.

---

## 5 · Map / Parallax — the Kingdom feel 🟡
![[sheet_map.png]]

The piece the map was missing. Layered for side-scroller depth (per [[Kingdom - Design Bible]]):
- **Far horizon** — city/mountain silhouette (slowest scroll)
- **Mid treeline** — forest silhouette strip
- **Foreground foliage** — grass/ferns that scroll *over* the front (fastest)
- **Ground tileset** — 16 seamless 32px platform tiles (grass-topped earth/rock) — the walkable terrain edge

Stack these at different scroll speeds in Godot → instant Kingdom depth.

---

## 6 · Environment / Terrain Props 🟡
![[sheet_backgrounds.png]]
The Traveler · Mars/Moon rock · trees · mesa · warship & hive silhouettes.

---

## 7 · UI ⬜
HUD · Glimmer icon · Ghost icon · Wave-alert · Game-over · Health/Light — not started.

## 8 · Projectiles & FX ⬜
Defender bullet · Harpy projectile · Hobgoblin beam · Ghost ability shockwave — not started.

---

## ⚠️ Superseded flat assets (flag to delete)
`player/speaker_on_sparrow*.png`, `player/skins/`, flat Frame — replaced by the hi-fi Guardian + Frame. Say the word to remove.

## Summary
| Category | Shipped ✅ | Generated 🟡 | Not started ⬜ |
|---|---|---|---|
| Player | Guardian-on-Sparrow, Ghost | Guardian, Speaker NPC, 4× Frame, 3× Super NPC | — |
| Enemies | Goblin, Dreg, Legionary | 20+ more | — |
| Structures | — | ~22 | — |
| Ship stages | — | 5 | — |
| Map/Parallax | — | 4 layers | day/night grades |
| Environment | — | 11 | — |
| UI / FX | — | — | all |

## Related Notes
- [[00 - Production Guide]] · [[Asset Manifest]] · [[SESSION HANDOFF]] · [[Kingdom - Design Bible]]
