---

kanban-plugin: board

---

## Backlog

- [ ] M2-07 Wall HP and destruction system
- [ ] M2-08 Add cutting/farming Glimmer generation
- [ ] M2-10 Builder job type (hammer) — Guardians build and upgrade walls
- [ ] M2-11 Farmer job type (scythe) — Guardians generate passive Glimmer
- [ ] M2-12 Tower/turret structures — Hunters occupy spots, shoot from top, knocked off by air enemies
- [ ] M2-13 Post-wave Hunter behavior — return to patrol after dusk ends
- [ ] M2-14 Ghost capture visual — orange tether stretch animation
- [ ] M3-01 Implement ability system (double-tap trigger, cooldown, Motes of Light)
- [ ] M3-02 Implement first Ghost discovery scene (Sundance — solar cave, firelight glow)
- [ ] M3-03 Implement Cayde-6 NPC call-in + Golden Gun super
- [ ] M3-04 Implement Legendary Shards currency
- [ ] M3-05 Implement Motes of Light drops from super kills
- [ ] M4-01 Full Earth level — all wall and defender tiers
- [ ] M4-02 Implement ship repair mechanic
- [ ] M4-03 Planet transition screen (Earth → Moon)
- [ ] M4-04 Save/load system


## To Do (M2 Active)

- [ ] M2-07 Wall damage and destruction (HP values TBD — see OQ-09)
- [ ] M2-10 Builder job type
- [ ] M2-11 Farmer job type
- [ ] M2-12 Tower / turret structures with Hunter occupancy slots
- [ ] M2-13 Post-wave free behavior for Hunters


## In Progress



## Needs Input (Ellis)

- [ ] OQ-01 Void Titan: Saint-14 or Zavala? (affects Ghost scene design for that character)
- [ ] OQ-02 Arc Warlock Guardian — who? (Shiro-4 for Hunter confirmed?)
- [ ] OQ-04 Sparrow unlock method — world discovery (hidden like Ghosts) or Glimmer purchase?
- [ ] OQ-05 Ghost discovery order — which element first on Earth? (Solar/Cayde feels right as Earth is Last City)
- [ ] OQ-08 Post-wave Hunter behavior — return to patrol or hold position at wall?
- [ ] OQ-09 Wall HP — how many Dreg hits before destruction?
- [ ] OQ-10 Tower occupancy — how many Hunter slots per tower tier?


## Done

- [x] Project folder created in Obsidian vault
- [x] PRD interview completed
- [x] 00 - Intro.md written
- [x] 01 - PRD.md written
- [x] Design/Ghost Abilities.md written
- [x] Design/Defense & Tower Layers.md written
- [x] Design/World & Lore.md written
- [x] Dev/Engine & Tech.md written
- [x] M1-01 Godot 4 project setup (pixel art settings, nearest-neighbor, canvas_items stretch)
- [x] M1-02 Player movement left/right on Sparrow (CharacterBody2D, SPARROW_SPEED 220)
- [x] M1-03 Earth level layout — highway, parallax background (sky, wall, debris layers)
- [x] M1-04 Ghost companion (floating, bobbing, no abilities yet)
- [x] M1-05 Ghost tether mechanic (420px snap distance, game over trigger)
- [x] M1-06 Ghost capture (Dreg grabs Ghost, carries it away, triggers tether check)
- [x] M1-07 Game over screen ("Your Light has been extinguished." red fade, new run)
- [x] M1-08 Player sprite (placeholder ColorRect)
- [x] M1-09 Ghost sprite (placeholder ColorRect, blue / orange when captured)
- [x] M1-11 Opening scene (darkness → Ghost scan → "Eyes up, Guardian." → world reveal)
- [x] M1-12 Glimmer HUD (running number, wave counter, run timer)
- [x] M1-13 Glimmer caches (40–120 Glimmer each, bobbing pickups, respawn every 25s)
- [x] M1-14 Fallen Dreg enemy (CharacterBody2D, march left, 40% chance to target Ghost)
- [x] M2-01 Wall placement (build sites as Area2D, 100 Glimmer, Space to build)
- [x] M2-02 Tier 1 wall (StaticBody2D, collision layer 2 — blocks enemies, not player)
- [x] M2-04 Wave spawning (dusk trigger, 20s wave escalation, spawn_interval 12s → 3s)
- [x] M2-05 Enemy pathfinding (Dreg marches left, stops at walls, attacks ghost)
- [x] M2-06 Defender attack AI (Hunter detects enemies in 250px range, engages, attacks on cooldown)
- [x] M2-09 Enemy Glimmer drops on death (random 20–60 Glimmer per Dreg kill)
- [x] M2-NEW Guardian NPC discovery (dormant on map, dim green, recruit for 75 ◈)
- [x] M2-NEW Encampment system (Area2D proximity detection, job creation for 150 ◈)
- [x] M2-NEW Hunter job type (PATROL → ENGAGE → REPOSITION → DEFEND state machine)
- [x] M2-NEW Guardian color coding (dim green = dormant, bright green = traveling/waiting, orange = hunter)
- [x] M2-NEW Auto-job-assignment (guardian auto-accepts pending job on arrival at camp)
- [x] M2-NEW Collision layer architecture (player = bit3/8, guardian = bit2/4, wall = bit1/2, ground = bit0/1)
- [x] Debug panel (F1 toggle, spawn Dreg button, force dusk button, ghost invincible toggle)
- [x] GameState autoload singleton (glimmer, wave, ghost state, signals)




%% kanban:settings
```
{"kanban-plugin":"board"}
```
%%
