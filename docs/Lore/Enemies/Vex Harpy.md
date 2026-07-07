---
title: Vex Harpy
aliases: [Harpy, Vex Flyer]
tags:
  - guardian-rising
  - lore
  - enemy
  - vex
created: 2026-06-23
---

← [[Vex]] ← [[Guardian Rising]]

# Vex Harpy

Harpies are the aerial unit of the Vex — small, hovering constructs that move in clusters and fire rapid low-damage shots. Their key trait: **they ignore walls entirely**, flying above the wall line and targeting frames and the ghost directly.

## Combat Behavior

- Hover at y = wall-top height (above the wall line)
- Move in packs of 2-4
- Fire rapid projectile shots at the nearest frame or ghost
- Don't attack walls (flying over them)
- Vulnerable to tower fire and Redjack attacks

## Guardian Rising Implementation Plan

Harpies require:
- `motion_mode = MOTION_MODE_FLOATING` (same as bosses)
- No collision with walls (mask excludes layer 2)
- Different y position — hover above the field
- New attack: spawns small projectiles (fast-moving, low damage)

The wall defense loop breaks for Harpies — they make the attack phase critical because they can bypass all wall investments.

## Guardian Rising Stats
- HP: 2
- Speed: 22 (fast, erratic movement)
- Projectile: 1 damage, 5.0s fire interval
- Pack size: 2-3 per wave
- Spawns: appear after Day 4

## Visual
- Color: Teal-white (`0.30, 0.80, 0.70`)
- 10×8px (wide, flat to suggest wings)
- Floats at y = 100 (above wall height)

## Status
**Scaffolded** — implement after flying unit movement system is in place.

## Related Notes
- [[Guardian Rising]]
- [[Enemy Reference]] — pixel art silhouette + sprite guide
- [[Vex]] — faction overview
- [[Vex Goblin]] | [[Vex Minotaur]] | [[Vex Hobgoblin]]
- [[Venus]]
