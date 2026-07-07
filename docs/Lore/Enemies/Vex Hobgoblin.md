---
title: Vex Hobgoblin
aliases: [Hobgoblin, Vex Sniper]
tags:
  - guardian-rising
  - lore
  - enemy
  - vex
created: 2026-06-23
---

← [[Vex]] ← [[Guardian Rising]]

# Vex Hobgoblin

Hobgoblins are the Vex ranged unit — tall, bipedal snipers that hang back from the frontline and fire sustained beams at targets. Their defining trait is a **retraction mechanic**: when damaged, they crouch into a hardened shell and become invulnerable for a few seconds before resuming fire. This forces players to interrupt their attack to break the Hobgoblin's rhythm.

## Combat Behavior

- Stays at the rear of the Vex formation (rightmost enemy position during night)
- Fires a charged beam shot at the nearest guardian/wall at intervals
- When hit: **retract** (crouched, immune) for ~2 seconds, then resume
- Does NOT charge walls — purely ranged

## Guardian Rising Implementation Plan

Unlike Dregs and Goblins, Hobgoblins need a **ranged attack** and **retract mechanic**.

- Retract state: `is_retracted = true` for `RETRACT_DURATION`; `take_damage()` ignored while retracted
- Beam attack: spawns a `beam_projectile.tscn` that travels left at high speed; damages walls and frames on contact
- Stays at x position right behind the Vex wave line; doesn't advance until wave has passed 2 walls

## Guardian Rising Stats
- HP: 3
- Speed: 0 (stationary sniper; slowly drifts left when wave advances)
- Beam damage: 2 per hit (bypasses wall armor? TBD)
- Retract duration: 2.0s
- Fire interval: 4.5s

## Visual
- Color: Dark teal/gray (`0.15, 0.55, 0.40`)
- 8×24px (taller than Goblin)
- Retracted form: 8×12px, darker color

## Status
**Scaffolded** — scene and script not yet created. Implement when ranged attack system is built.

## Related Notes
- [[Guardian Rising]]
- [[Enemy Reference]] — pixel art silhouette + sprite guide
- [[Vex]] — faction overview
- [[Vex Goblin]] | [[Vex Minotaur]] | [[Vex Harpy]]
- [[Venus]]
