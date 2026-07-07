# Engine & Tech

---

## Chosen Engine: Godot 4

**Why Godot 4:**
- Free and open source — no royalties, no Unity-style licensing surprises
- First-class 2D with pixel art support (integer scaling, nearest-neighbor filtering built in)
- `ParallaxBackground` node handles multi-layer scrolling out of the box
- GDScript is approachable and fast to prototype in
- Exports to Windows, macOS, Linux, and Web (HTML5)
- Active indie community with lots of Kingdom-style reference projects

## Project Folder Structure

```
guardian-rising/
  scenes/
    world/
    ui/
    enemies/
    player/
  assets/
    sprites/
    audio/
    fonts/
  scripts/
  project.godot
```

## Key Godot Features to Use

| Feature | Use Case |
|---------|----------|
| `ParallaxBackground` | Sky, mountain, city backdrop layers |
| `TileMap` | Ground terrain and platforming |
| `AnimatedSprite2D` | Guardian, Ghost, enemies, defenders |
| `CharacterBody2D` | Player movement (left/right + Sparrow) |
| `Area2D` | Attack hit zones, interact triggers |
| `CanvasLayer` | HUD / glimmer counter overlay |
| `AudioStreamPlayer` | Music + SFX |

## Collision Layer Architecture

Godot uses bitmasks for collision detection. We reserve specific bits for each category so entities only interact with what they're supposed to.

| Bitmask value | Layer name | Who is on it | Detected by |
|---------------|-----------|--------------|-------------|
| 1 (bit 0) | Ground | StaticBody2D floor, WorldBoundary | Player, Guardian, Enemy |
| 2 (bit 1) | Walls | Built wall StaticBody2Ds | Enemies (stops them) |
| 4 (bit 2) | Guardians | Allied CharacterBody2Ds | Nothing (pass-through) |
| 8 (bit 3) | Player | Player CharacterBody2D | Glimmer caches, Build sites |

**Why this matters:** Player and allied Guardians must pass through walls freely (Kingdom mechanic). Enemies must stop at walls. Player and Guardians must never physically push each other. Separating them onto non-overlapping bits achieves this without custom collision callbacks.

**Rule of thumb:** If two things shouldn't physically push each other, make sure neither has a mask bit that matches the other's layer bit.

---

## Godot 4.7 Strict Typing Notes

These return `Variant`, not the expected type — always annotate explicitly:
- `create_tween()` → `var tween: Tween = create_tween()`
- `clamp()` → use `clampf()` or `clampi()` depending on type
- `remap()` → annotate the variable receiving it

Tweens in Godot 4 are **sequential by default**. Do NOT call `set_sequential()` (removed). Use `set_parallel(true)` only when you want simultaneous property tweens.

---

## Workflow: No-Editor Wiring

All scene structure is written as `.tscn` text files. No Godot editor required to wire nodes:
- Node references use `@onready var x = $NodeName` for named children
- Cross-scene references use `get_tree().get_first_node_in_group("group_name")`
- Lazy initialization: if a cross-scene reference is needed in `_ready()`, get it on first `_process()` frame instead (scene tree is fully populated by then)
- Signals: connect in `_ready()` via `.connect()` — never rely on editor signal connections

---

## Setup Steps

1. Download Godot 4: https://godotengine.org/download
2. Create new project → 2D renderer
3. Set pixel art display: Project Settings → Rendering → Textures → default filter = Nearest
4. Set stretch mode: Project Settings → Display → Window → Stretch = canvas_items

---

*See also: [[01 - PRD]]*
