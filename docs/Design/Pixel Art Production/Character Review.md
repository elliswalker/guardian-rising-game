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

> Review board for the game's art. **Style: high-fidelity PixelLab Pro.** Contact sheets below are grouped by category — previews live in `_review/pro/`.
> **Protagonist change:** the player is now the **Guardian** (rides the Sparrow). The **Speaker** is now a **camp anchor NPC**, not the player.

**Legend:** ✅ approved + shipped · 🟡 generated in Pro (your selection — pending ship to `Game/assets/`) · ⬜ not started

---

## 1 · Characters — Player & NPCs
![[sheet_characters.png]]

- **Guardian** — 🟡 player protagonist (hooded, armored, has a walk anim already). Rides the Sparrow.
- **Speaker** — 🟡 camp anchor NPC (blue robe). No longer the player.
- **Frame** base + **Defender** (rifle) / **Builder** (hammer) / **Sweeper** (broom) — 🟡 modular defender units.

### Guardian on Sparrow — protagonist ✅
*PixelLab state `e92a1141` (seated rider off the Guardian) · 72×58 · self-contained rider+speeder*

| Right | Left |
|---|---|
| ![[guardian_sparrow_right_4x.png]] | ![[guardian_sparrow_left_4x.png]] |

**Status:** ✅ built + shipped → `player/guardian_on_sparrow_right.png` + `_left.png`. Hooded Guardian, cloak trailing, dynamic lean. Palette-locked to the standing Guardian.

### Ghost — companion ✅
![[ghost_final_right_6x.png]]
**Status:** ✅ shipped (`player/ghost_right.png`, `ghost_left.png`, `ghost_16.png`), arc-blue eye.

---

## 2 · Enemies — full Pro roster
![[sheet_enemies.png]]

| Faction | Units |
|---|---|
| **Vex** | Goblin ✅ · Hobgoblin 🟡 · Minotaur 🟡 · Harpy 🟡 · Hydra 🟡 |
| **Fallen** | Dreg ✅ · Vandal 🟡 · Servitor 🟡 |
| **Cabal** | Legionary ✅ · Phalanx 🟡 · Psion 🟡 · Colossus 🟡 |
| **Hive** | Thrall 🟡 · Wizard 🟡 · Worm 🟡 |
| **Other** | Scrap Drone 🟡 · Sand Skitter 🟡 |

✅ = shipped to `enemies/`. 🟡 = generated in Pro, ready to ship on your ✅.

---

## 3 · Structures & Buildings 🟡
![[sheet_structures.png]]

Canvas Tent · Granite Cliff · Watchtower · Ballista · Crashed Ship · Boulders · Shrine Altar · Glimmer Crystal · Stasis Pod · War Banner · Terminal · Signal Beacon · Portal Gate · Recruiting Post · **Military Camp** (Speaker's camp) · Barricade · Scav Watchtower · Dead Pine · Alien Portal · Battle Standard
**Status:** 🟡 generated in Pro (this is ~20 of ~50 tagged — more variants exist in PixelLab). Pending selection + ship.

---

## 4 · Environment / Parallax Background 🟡
![[sheet_backgrounds.png]]

The Traveler · Mars Rock · Moon Rock · Wasteland Bush · Thin Tree · Broad Tree · Desert Mesa · Warship Silhouette · Alien Bone · Rocket Tower · Hive Silhouette
**Status:** 🟡 generated in Pro. These are the parallax layer pieces (per [[Kingdom - Design Bible]] 5-layer depth).

---

## 5 · UI ⬜
HUD frame · Glimmer/coin icon · Ghost icon · Wave-alert banner · Game-over art · Health/Light indicator — ⬜ not started.

## 6 · Projectiles & FX ⬜
Defender bullet · Harpy projectile · Hobgoblin beam · Ghost ability shockwave — ⬜ not started.

---

## ⚠️ Superseded — flag to remove
The **flat** player-side assets are replaced by the hi-fi Guardian + Frame Worker, and the protagonist swap:
- `player/speaker_on_sparrow*.png` (flat, was Speaker-as-player)
- `player/skins/` (6 flat mount skins — the skin *concept* may carry to the Guardian later)
- flat Frame base

**Want me to delete these from `Game/assets/`?** (Say the word — the mount-skin recolor idea can be re-applied to the hi-fi Guardian-on-Sparrow when it exists.)

---

## Summary
| Category | Shipped ✅ | Generated 🟡 | Not started ⬜ |
|---|---|---|---|
| Characters | Ghost, Guardian-on-Sparrow | Guardian standing, Speaker NPC, 4× Frame | — |
| Enemies | Goblin, Dreg, Legionary | 14 more | — |
| Structures | — | ~20 (of ~50) | — |
| Environment | — | 11 | day/night grades |
| UI | — | — | all |
| Projectiles/FX | — | — | all |

## Related Notes
- [[00 - Production Guide]] · [[Asset Manifest]] · [[SESSION HANDOFF]]
- [[Character Reference]] · [[Enemy Reference]] · [[Kingdom - Design Bible]]
