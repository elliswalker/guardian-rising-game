---
title: Asset Manifest
aliases: [Sprite Manifest, Art Checklist, Asset List]
tags:
  - guardian-rising
  - pixel-art
  - production
created: 2026-07-06
---

# Asset Manifest
← [[00 - Production Guide]] ← [[00 - Intro]]

> Complete art checklist, grounded in the actual game entities (`scripts/world/`, `scripts/enemies/`, `scenes/`).
> **STYLE (updated 2026-07): high-fidelity PixelLab _Pro_ mode**, anchored on the detailed Speaker (`669cdd6d`). Superseded the earlier flat/Kingdom look — see [[SESSION HANDOFF]]. Conventions still apply: left/right only, palette from `design_tokens.gd`, size tiers in `sprite_loader.gd`.
> **Legend:** ⬜ todo · 🔄 generating · 👀 in review · ✅ approved+shipped · ♻️ palette-swap variant of another sprite

---

## 1 · Player Side
| Asset | Source | Status |
|---|---|---|
| Speaker (detailed concept — hi-fi anchor `669cdd6d`) | `player.gd` | ✅ anchor |
| Speaker on Sparrow (rider) + 6 mount skins | player unit | ✅ shipped (flat — redo in hi-fi if committing) |
| Ghost (companion) | `ghost.gd` | ✅ shipped (yours, arc-blue eye, `ghost_16.png`) |
| Sparrow (riderless) | `ship.gd` / vehicle | ⚠️ 16 variants saved; redo in hi-fi |

## 2 · Structures & Buildings
| Asset | Source | Status |
|---|---|---|
| Frame / Defender (base) | `defender.gd` | 🔄 |
| Tower | `tower.gd` | ⬜ (placeholder exists) |
| Wall | `wall.gd` | ⬜ |
| Build Site | `build_site.gd` | ⬜ |
| Ghost Shrine | `ghost_shrine.gd` | ⬜ |
| Glimmer Cache | `glimmer_cache.gd` | ⬜ |
| Ship / Ship Hull (crash site) | `ship.gd` | ⬜ (placeholder exists) |
| Encampment (enemy spawn) | `encampment.gd` | ⬜ |
| Attack Flag | `attack_flag.gd` | ⬜ |
| Tree / Foliage | `tree.gd` | ⬜ (placeholder exists) |
| Wildlife (deer, ambient — Kingdom calm) | `wildlife.gd` | ⬜ |
| Pickup (glimmer/motes) | `pickup.gd` | ⬜ |
| Locker | structure | ⬜ (placeholder exists) |

## 3 · Enemies *(roster from `scripts/enemies/`)*
**Vex** — accent violet `#7b00ff` / metallic
| Goblin ✅ PRO · Hobgoblin ⬜ · Minotaur ⬜ · Harpy ⬜ · Hydra ⬜ |

**Fallen** — `#d4956a`/`#8b4513` · **Cabal** — `#c4522a`/`#8b3a1a` · **Hive** — `#4a7a5a`/`#2d5a3f`
| Dreg ✅ PRO · Servitor ⬜ · Legionary ✅ PRO · Colossus ⬜ · Wizard ⬜ |

*Design-doc extras (not yet in code — build later): Vandal, Captain, Shank, Thrall, Acolyte, Knight, Ogre, Phalanx, Centurion, Psion, Incendior.*

## 4 · Projectiles & FX
| Bullet (defender) ⬜ · Harpy projectile ⬜ · Hobgoblin beam ⬜ · Ability shockwave (Ghost) ⬜ |

## 5 · Environment / Parallax Background *(Kingdom 5-layer depth, per [[Kingdom - Design Bible]])*
| Layer | Asset | Status |
|---|---|---|
| Far | Sky gradient + **The Traveler** (great sphere) + stars | ⬜ |
| Mid-far | Distant City skyline silhouette | ⬜ |
| Mid | Forest / tree canopy silhouette layer | ⬜ |
| Near-mid | The City Wall + buildings + terrain ground strip | ⬜ |
| Foreground | Fast-scroll foliage overlap | ⬜ |
| — | Day/dusk/night/blood-moon color grades (see Design Bible) | ⬜ |

## 6 · UI *(from `scenes/ui/`)*
| HUD frame ⬜ · Glimmer/coin icon ⬜ · Ghost icon ⬜ · Wave-alert banner ⬜ · Game-over art ⬜ · Health/Light indicator ⬜ |
*(Font: PressStart2P — already in `assets/fonts/`)*

## 7 · Animations *(LAST — after base sprites approved)*
- Walk cycles: all enemies + Frame/Defender (side-view left→right)
- Idle bobs: Ghost, Servitor, Wizard, Harpy (floaters), Speaker-on-Sparrow hover
- Attacks: Frame fire, enemy melee/ranged, Ghost ability
- Deaths: enemy death poof

---

## Related Notes
- [[00 - Production Guide]]
- [[Character Review]]
- [[Enemy Reference]]
- [[Kingdom - Design Bible]]
