# Devlog — Guardian Rising

> Running notes on development progress, decisions, and blockers.
> Full turn-by-turn session transcripts live in `Dev/Transcripts/`.

---

## 2026-06-19 — Session 01: Project Kickoff + M1 + M2 Guardian System

**What we built:**
- Full Godot 4 project scaffolded from scratch — no editor wiring, everything via .tscn + .gd files
- M1 complete: player on Sparrow, Ghost tether, Glimmer economy, Dreg enemies, wave escalation, game over flow, opening scene
- M2 in progress: wall building, Guardian NPC recruitment, encampment job system, Hunter AI state machine

**Key decisions made:**
- Workflow locked in: Ellis directs, Claude agents build all code and scenes. Ellis never opens the Godot editor to wire nodes.
- Guardian NPCs are found dormant on the map (Kingdom-style), not placed by the player
- Recruitment costs 75 Glimmer; Hunter jobs cost 150 Glimmer at the encampment
- Guardians auto-accept pending jobs on arrival — no manual assignment needed
- Collision layer architecture: player on bit 8, guardians on bit 4, walls on bit 2, ground on bit 1. Keeps physics interactions clean.
- Ghost capture uses horizontal-only distance check (ghost floats ~90px above ground — 3D distance never triggers)
- Area2D body_entered unreliable for player detection in some cases; switched to proximity check in _process where needed

**Bugs fixed:**
- Dregs walked through walls → set dreg.collision_mask = 3
- Player blocked by walls → walls on separate layer (bit 2), player mask = 1 (ground only)
- Guardians pushed player around → guardians skip move_and_slide() in DORMANT state; placed at y=600
- Guardian _ready() fires before player adds itself to group → lazy player reference in _check_recruit_prompt()
- Encampment Area2D couldn't detect guardians (layer 4 vs mask 1) → guardian self-triggers arrive_at_camp() on positional check
- create_tween(), clamp(), remap() return Variant in Godot 4.7 strict mode → explicit type annotations everywhere

**Milestone status:**
- M1: ✅ Complete
- M2: 🔄 In Progress (Guardian system, wall placement done; Builder/Farmer/Tower pending)

---

*See `Dev/Transcripts/Session 01 - 2026-06-19.md` for full turn-by-turn log.*
