---
title: Hydra
aliases: [Vex Hydra, Vex Boss]
tags:
  - guardian-rising
  - lore
  - enemy
  - vex
  - boss
created: 2026-06-23
---

← [[Vex]] ← [[Guardian Rising]]

# Hydra

The Hydra is a Vex upper-caste construct — a large, floating sentinel that serves as a command node for the Vex network and as the Guardian Rising Vex boss. It defends the Vex portal on Venus.

## Destiny Lore

Hydras are among the largest non-boss Vex you encounter in standard combat. They hover just above the ground, rotating a massive shield that covers their front. The shield spins perpetually and can only be damaged when the shield's gap rotates to face you — requiring patience and precise timing rather than raw damage output.

In raid encounters, Hydras serve as gatekeepers, denying passage until their shield rotation is exploited. The spinning shield is nearly synonymous with the Hydra's identity — it's their defining tactical challenge.

## Guardian Rising Mechanics

**Shield Cycle:**
- 4.5 seconds ACTIVE (fully immune to damage)
- 1.5 seconds OPEN (vulnerable window)
- Repeats indefinitely
- Visual: shield ColorRect fades in/out to indicate active state

**Combat Behavior:**
- Hovers (MOTION_MODE_FLOATING, Godot 4)
- Slow patrol between x=650 and x=750
- Does not attack the player or frames directly — the Vex wave handles that
- On death: **crashes to the floor** (rapid y tween down), then calls `portal.break_portal()`

**Death Sequence:**
1. Shield goes dormant
2. Body drops from hover height to ground (0.35s tween)
3. Portal breaks, radiolarian fluid visual erupts from crash site
4. Body fades over 2.0s then queue_frees

## Guardian Rising Stats
- HP: 18
- Shield window: ~25% of cycle
- Move speed: 4.0 (slow drift)
- Glimmer drop: 0 (boss, not glimmer-rewarded directly — portal breaking is the reward)

## Visual
- Color: Teal-green (`0.20, 0.75, 0.50`)
- 26×24px body
- Shield overlay: semi-transparent teal that pulses when active
- Crash: position.y jumps to 148.0 on death

## Status
**Implemented** — `scripts/enemies/hydra.gd` + `scenes/enemies/hydra.tscn`

## Related Notes
- [[Guardian Rising]]
- [[Enemy Reference]] — pixel art silhouette + sprite guide
- [[Vex]] — faction overview
- [[Vex Goblin]] | [[Vex Minotaur]] | [[Vex Hobgoblin]] | [[Vex Harpy]]
- [[Venus]]
- [[Servitor]] — Fallen boss equivalent
