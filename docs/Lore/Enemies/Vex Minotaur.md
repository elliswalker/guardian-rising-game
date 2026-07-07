---
title: Vex Minotaur
aliases: [Minotaur, Vex Heavy]
tags:
  - guardian-rising
  - lore
  - enemy
  - vex
created: 2026-06-23
---

← [[Vex]] ← [[Guardian Rising]]

# Vex Minotaur

The Minotaur is the heavy assault unit of the Vex — large, durable, and equipped with a **Void teleport** that lets it bypass short distances instantly. In Destiny this creates unpredictable close-range flanks. In Guardian Rising, the teleport functions as a wall-bypass: the Minotaur can teleport past the first wall it reaches.

## Combat Behavior

- Slow march (slower than Goblin)
- High HP — takes multiple hits to kill
- **Teleport mechanic**: when within range of a wall, teleports 30-40px past it (appears on the guardian side)
- After teleport: attacks frames directly (melee)
- Does NOT retreat on hit

## Guardian Rising Implementation Plan

The teleport is a special-case behavior:
```gdscript
# When wall is within TELEPORT_TRIGGER_DIST:
if wall_dist < TELEPORT_TRIGGER_DIST and not _teleported:
    _teleported = true
    global_position.x -= 35.0  # appears inside the wall zone
```

This makes Minotaurs the most dangerous wave unit because they bypass the entire wall system if they survive long enough to reach it.

## Guardian Rising Stats
- HP: 6
- Speed: 9 (slow but relentless)
- Teleport: once per Minotaur, triggers at 20px range from wall
- Melee damage: 2 per hit to frames/walls
- Wall attack: bypasses via teleport (doesn't damage the wall, just skips it)
- Spawns: appears in larger waves (Day 5+)

## Visual
- Color: Dark green (`0.12, 0.50, 0.30`)
- 14×28px (significantly larger than Goblin)

## Status
**Scaffolded** — implement when teleport system is ready.

## Related Notes
- [[Guardian Rising]]
- [[Enemy Reference]] — pixel art silhouette + sprite guide
- [[Vex]] — faction overview
- [[Vex Goblin]] | [[Vex Hobgoblin]] | [[Vex Harpy]] | [[Hydra]]
- [[Venus]]
