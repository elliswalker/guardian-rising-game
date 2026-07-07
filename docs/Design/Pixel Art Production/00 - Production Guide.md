---
title: Pixel Art Production Guide
aliases: [PixelLab Guide, Sprite Production, Art Pipeline]
tags:
  - guardian-rising
  - pixel-art
  - production
created: 2026-07-06
---

# Pixel Art Production Guide
← [[00 - Intro]] ← [[01 - PRD]]

> **Pipeline:** PixelLab.ai (generate) → Aseprite (clean up + palette + animate) → Godot (`Game/assets/sprites/`).
> Replaces the old Midjourney workflow. MJ generates illustrations, not pixel-perfect low-res sprites — wrong tool for 14–34px units.

---

## Direction Convention — LEFT / RIGHT ONLY

This is a pure side-scroller. **Every asset ships as exactly two facings: `<name>_right.png` and `<name>_left.png`.** No north/south/front/back. Left is the horizontal mirror of right — generate one east/right-facing side view, flip it for left. (Godot can also just `flip_h` at runtime from a single sprite, but we deliver both files.) When generating characters, ignore the north/south rotations entirely.

---

## Review Preview Convention

Native sprites (16–64px) are too small to eyeball in Obsidian. **Every asset put up for review gets a 5× nearest-neighbor upscaled preview** (`<name>_5x.png`) embedded in [[Character Review]]. Ship the *native* file to `Game/assets/`; review from the 5× copy. This is the default — don't embed native-size sprites for review.

---

## The One Rule

**Consistency comes from a reused style string + a style-reference image — not from clever per-prompt wording.**

1. Generate the **Speaker** first.
2. Approve the one you like.
3. Feed it back into PixelLab as the **style reference image** for every other sprite.
4. Reuse the base style string below on every generation.

Generate the base sprite first; only *then* use PixelLab's animation/rotation feature on the approved sprite. Never prompt a walk cycle cold.

---

## Base Style String (paste into every generation)

```
16-bit pixel art game sprite, clean single-pixel outline, limited palette,
low-res readable silhouette, flat cel shading with one highlight and one shadow,
dark sci-fi fantasy tone, centered, transparent background, side-scroller /
top-down tower-defense sprite, no text, no background scenery
```

## Palette (from `design_tokens.gd`)

| Role | Hex |
|---|---|
| Base darks | `#0a0a0f` `#111118` `#1a1a24` |
| Cream / metal light | `#e8e0d0` `#b0a898` |
| Glimmer gold accent | `#f0d060` |
| Solar / Void / Arc glow | `#ff6b00` / `#7b00ff` / `#00c0ff` |
| Fallen | `#d4956a` / `#8b4513` |
| Hive | `#4a7a5a` / `#2d5a3f` |
| Cabal | `#c4522a` / `#8b3a1a` |

## In-Game Relative Scale
Keep proportions consistent in-engine (Godot scales sprites): **Ghost ≈ 16px** (half-height), **Speaker / Frame / basic enemy ≈ 32–40px**, **elites ≈ 48–56px**, **bosses larger**. Generate bigger for detail, ship native, scale down in-engine. Detailed art below ~20px softens — if a unit must be tiny and crisp, generate it small-native instead of downscaling.

## Canvas Size Tiers

Generate a tier larger than in-game, then downscale into Godot for cleaner edges. Sizes map to the relative-scale column in [[Enemy Reference]].

| In-game scale | PixelLab canvas | Units |
|---|---|---|
| 0.7–1x | 32×32 | Dreg, Thrall, Shank, Psion, Ghost |
| 1.3–1.5x | 48×48 | Vandal, Acolyte, Wizard, Speaker, Frame |
| 1.8–2.2x | 64×64 | Captain, Knight, Legionary, Phalanx, Centurion, Servitor |
| 3x (boss) | 96×96 | Ogre, Colossus |

Each prompt below = **base style string + the subject line shown.**

---

## Player Side

**Frame — buildable defender combat unit** · 32×48, front-facing static
```
a slim humanoid robotic combat frame, exposed metal skeleton and servos,
glowing gold optic eye (#f0d060), city-defender plating in cream and dark grey
(#e8e0d0 / #1a1a24), rifle held across chest, upright at-attention stance,
no organic parts
```

**Speaker — player character** · 48×48, front-facing idle · *(generate FIRST, use as style ref)*
```
a robed ceremonial figure, full ornate white-and-gold face mask with NO visible
face, long flowing ceremonial robes darker at the hem (#111118) lighter at the
chest (#b0a898), gold mask accents (#f0d060), hands clasped, unarmed, elderly
upright bearing, bell-shaped silhouette wide at hem narrow at head
```

**Ghost — companion drone** · 32×32, floating, 4-direction
```
a small floating spherical robot companion, faceted angular shell of white/cream
plates (#e8e0d0) around a single glowing central eye, thin gap of arc-blue light
between the shell segments (#00c0ff), no limbs, hovering, compact and rounded
```

**Sparrow — hover-vehicle** · 48×32 wide, side view
```
a sleek single-rider hover-speeder bike, long forward-swept chassis, no wheels,
twin glowing arc-blue thrusters at the rear (#00c0ff), cream and dark-grey plating
(#e8e0d0 / #1a1a24), low aerodynamic profile, side-on profile view
```

---

## Fallen — Earth / House of Devils *(MVP faction)*
Accent `#d4956a` / `#8b4513` + arc-blue `#00c0ff`.

**Dreg** · 32×32
```
a wiry hunched scavenger alien, ONLY TWO arms, tattered rust-brown cloth and
cracked grey armor (#8b4513), insectoid limbs, four glowing eyes, shock dagger,
cannon-fodder small
```
**Vandal** · 48×48
```
a taller upright FOUR-armed scavenger alien, House of Devils helmet with curved
horns, tattered cloak, cracked armor plating (#d4956a / #8b4513), shock rifle,
agile lean build
```
**Captain** · 64×64
```
a large elite four-armed alien commander, ornate tattered-nobility armor, embedded
glowing arc-blue shield (#00c0ff), wide imposing frame, shock blade, high-durability bulk
```
**Shank** · 32×32
```
a small floating box-shaped drone robot, twin vertical jet thrusters underneath,
no legs, single sensor eye, rust and grey chassis (#8b4513), rapid-fire arc weapon
```
**Servitor** · 64×64
```
a perfect large floating metal sphere, single huge glowing purple central eye
(#7b00ff), segmented plating, exposed circuitry, no limbs, rotating in place
```

---

## Hive — Moon / Hidden Swarm
Accent `#4a7a5a` / `#2d5a3f` + green energy. Base descriptor: *black chitin armor, exposed bone, three faint glowing-green eye dots.*

**Thrall** · 32×32
```
a skeletal crouched melee alien, black chitin skin over exposed bone, no visible
eyes only three faint glowing-green dots, clawed hands, hunched animalistic rush pose
```
**Acolyte** · 48×48
```
an upright hooded Hive infantry alien, exposed chitin and bone plating (#2d5a3f),
glowing-green weapon, upright ranged stance, taller than a thrall
```
**Knight** · 64×64
```
a massive armored Hive elite, horned helmet, tattered cape, glowing-green sigil on
its face, relic-iron black-and-green plating (#4a7a5a), large cleaver sword, imposing
```
**Wizard** · 48×48, floating
```
a floating female Hive spellcaster, long crumbling robes trailing beneath, black
chitin and bone, glowing-green magic in hands, aerial hovering pose, never grounded
```
**Ogre** · 96×96, boss
```
a giant hunched ritual beast, enormous black-chitin frame, single huge glowing-green
eye firing an energy beam, massive arms, ground-shaking bulk, biggest Hive unit
```

---

## Cabal — Mars / Red Legion
Accent `#c4522a` / `#8b3a1a` + gold. Base descriptor: *bipedal rhino-like heavy trooper, boxy armor, jump jets.*

**Legionary** · 64×64
```
a huge bipedal rhino-like alien soldier in full boxy heavy armor (#c4522a / #8b3a1a),
built-in jump jets, slug rifle and wrist blades, largest basic infantry, durable
```
**Phalanx** · 64×64
```
a heavy Cabal trooper carrying a massive tactical shield covering most of its body,
boxy red-and-grey armor (#c4522a), exposed arms as weak spot, braced defensive stance
```
**Centurion** · 64×64
```
an ornate Cabal officer, heavier armor than a legionary, embedded glowing solar
shield (#ff6b00), jetpack for hovering, sensor arrays on helmet, commander bearing
```
**Colossus** · 96×96, boss
```
an enormous boxy Cabal heavy, near-impenetrable red-and-grey armor (#8b3a1a),
massive rotary machine gun, ground-shaking stance, even bigger than a legionary
```
**Psion** · 32×32
```
a small slim bipedal psychic alien, hairless veined head, single eye with a Y-shaped
pupil, black trident creases around the eye, four fingers, shorter than a human
```
**Incendior** · 64×64
```
a standard Cabal trooper with TWO large fuel tanks strapped to its back (weak spot),
reinforced helmet, flamethrower weapon, red-and-grey armor (#c4522a), strafe thrusters
```

---

## Animation Notes
- Everything that moves in-game (all enemies, Sparrow, Ghost) → generate base sprite → approve → use PixelLab **animation / rotation** on the approved sprite.
- Enemies walk left→right along lanes: prioritize **side-view walk cycles**.
- Ghost + Servitor + Shank + Wizard **float** → idle bob loop, no walk.
- Final cleanup (stray pixels, palette snap, frame timing) happens in **Aseprite** before export.

## Status
- [ ] Speaker generated + approved as style reference
- [ ] Player side: Frame, Ghost, Sparrow
- [ ] Fallen set (Dreg, Vandal, Captain, Shank, Servitor)
- [ ] Hive set · [ ] Cabal set
- [ ] Animation pass

## Related Notes
- [[00 - Intro]]
- [[01 - PRD]]
- [[Character Reference]]
- [[Enemy Reference]]
- [[World & Lore]]
