# PRD — Guardian Rising

*Last updated: 2026-06-19*

---

## 1. Overview & Vision

Guardian Rising is an infinite 2D side-scrolling strategy/defense game in the spirit of the Kingdom Series, reskinned with the world, lore, and characters of Destiny 1. The player takes the role of **The Speaker** — the Voice of the Traveler — who rides a Sparrow left and right, manages a Glimmer economy, builds city defenses, and deploys named Guardian NPCs as ability strikes by finding and equipping their Ghosts.

> **Design decision:** The Speaker is the player character. His full-face mask means no facial animation is needed, his robes read clearly at small pixel art sizes, and his identity is flexible enough that palette swaps (mask accent + robe color) can serve as unlockable cosmetics. He is a commander, not a fighter — which matches the Kingdom-style "you direct, others do the killing" loop perfectly.

The game is designed to be sessionless — you can play for 5 minutes or 5 hours. There is no hard ending. The world can always be rebuilt.

---

## 2. Target Platform

| Target | Detail |
|--------|--------|
| Primary | Steam (Windows, macOS) |
| Secondary | Browser via Godot HTML5 export |
| Hardware target | Steam Deck — 60fps+, controller-native |
| Controls | Left / Right / Action button only |

---

## 3. Opening Scene

1. Screen is black
2. Ghost woosh sound effect
3. Blue scanning line sweeps the darkness upward, pulling the world into view (D1-style resurrection scan)
4. Text appears: **"Eyes up, Guardian."**
5. World resolves: player on Sparrow, Ghost hovering in front on the Earth highway
6. Earth palette: rust/brown/grey, rusted cars, Last City wall looming in background, parallax clouds
7. No tutorial text. The game teaches through feel.

---

## 4. Core Gameplay Loop

```
Ride → Explore → Collect Glimmer → Build Defenses → Survive Waves → Repeat
                     ↓
              Find dormant Guardian NPCs → Pay Glimmer to recruit → Walk to Encampment
                     ↓
              Create job at Encampment (Hunter / Builder / Farmer)
                     ↓
              Hunters patrol perimeter, defend walls at dusk
                     ↓
              Find elemental Ghost → Unlock Guardian ability → Next planet
```

---

## 5. Player Controls

| Input | Action |
|-------|--------|
| Left | Move left on Sparrow (or on foot) |
| Right | Move right on Sparrow (or on foot) |
| Action (tap) | Interact / recruit / build / collect |
| Action (double-tap) | Activate equipped Guardian's super ability |

**Ghost tether:** If the Ghost is captured by an enemy and carried beyond tether range, it snaps. Screen fades red → black. "Your Light has been extinguished." New run begins.

**Ghost captured state:** Sparrow disappears. Abilities unavailable. Visibility dims. Player can hobble on foot (or limp if hurt). Must chase and recapture.

---

## 6. The Ghost System

### Starter Ghost (Ghost A)
- Given at resurrection
- No special powers
- Provides Light, visibility, and Sparrow access
- Analogous to the starting horse in Kingdom Classic

### Elemental Ghosts
Found hidden in each world (glowing caves, darkness rifts, secret areas). Unlocked with **Legendary Shards + Glimmer**.

Each elemental Ghost is bonded to a specific named Guardian NPC. Finding the Ghost summons that Guardian's ability when triggered.

| Element | Visual Cue |
|---------|------------|
| Solar | Firelit cave, Ghost on fire |
| Void | Dark crevice, Ghost emitting purple void light |
| Arc | Storm-cracked ruins, Ghost crackling with electricity |

### Ghost Vulnerability
- Ghost is a physical entity in the world — enemies can target and grab it
- When grabbed, Ghost visually struggles (animation: thrashing, pulling toward player)
- Tether stretches as enemy carries Ghost away
- If tether snaps: game over

---

## 7. Guardian Roster (MVP: Solar, Void, Arc)

| Element | Class | Guardian | Ghost | Super |
|---------|-------|----------|-------|-------|
| Solar | Hunter | Cayde-6 | Sundance | Three-burst Golden Gun — kills 3 small enemies, partial damage on large |
| Solar | Titan | Lord Saladin | Isirah | Hammer of Sol — wave of fire, scorches anything it reaches |
| Solar | Warlock | Osiris | Seguira | Well of Radiance — sets ground on fire, scorches enemies that walk through |
| Arc | Hunter | Lady Efrideet | *(TBD)* | Arcstrider — 3-hit combo (2 small + 1 large palm strike) |
| Arc | Titan | Zavala | Targe | Striker Smash — single devastating slam |
| Arc | Warlock | Lord Felwinter | Felspring | Stormtrance — chain lightning through multiple enemies, trickle damage |
| Void | Hunter | Crow | Glint | Shadowshot — tether connects enemies, NPC attacks apply to all tethered |
| Void | Titan | Saint-14 | Geppetto | Sentinel Shield — ricochets up to 5 times through enemies |
| Void | Warlock | Ikora Rey | Ophiuchus | Nova Bomb — large area void explosion |

> **Future:** Stasis and Strand elements unlock additional Guardians (Exo Stranger, Crow, etc.) in post-MVP content.

### Ability Cooldown
- Time-based cooldown after each use
- Enemies killed by a super drop **Motes of Light** on the ground
- Collecting Motes reduces cooldown on the next ability

---

## 8. Sparrow Types

| Sparrow | Speed | Boost | Special |
|---------|-------|-------|---------|
| Standard | Normal | Normal | — |
| Bulky | Slow | Short | Ramming damage to enemies |
| Small | Normal | Long | Extended boost duration |
| Skimmer | Fast | Quick | No armor — high risk/reward |
| Shooting *(TBD)* | TBD | TBD | Projectile attack |

- Sparrows are discovered/unlocked in the world (similar to Ghost discovery)
- Losing Ghost = Sparrow disappears until Ghost is recaptured
- *(Open question: Sparrow unlock mechanic — same as Ghost hidden discovery, or purchased with Glimmer?)*

---

## 9. Glimmer Economy

### Currency Types

| Currency | Purpose | How Obtained |
|----------|---------|--------------|
| Glimmer | All building/upgrading/recruiting | Farming, hunting, cutting, enemy drops, caches |
| Legendary Shards | Ghost unlocks | Found in world secrets, rare enemy drops |
| Motes of Light | Reduce ability cooldown | Dropped by enemies killed with supers |

### Glimmer Generation
1. **Glimmer Caches** — glowing pickups scattered through the level (40–120 each), respawn over time
2. **Hunting** — kill animals in the area
3. **Cutting** — clear trees and obstacles
4. **Farming (Sweeper Bots)** — assign Guardians to sweep town range; passive Glimmer over time
5. **Farming (Relic)** — assign Guardians to gather spinmetal, spirit bloom, relic iron
6. **Enemy drops** — all enemy factions drop Glimmer on death

### Economy Format
- Glimmer displayed as a running gauge/number (not per-coin)
- **Hard cap: 25,000 Glimmer**
- Upgrade costs scale by tier — early walls are small spends; later tiers are significant investments

### Costs (Current Implementation)
| Action | Cost |
|--------|------|
| Recruit a Guardian | 75 ◈ |
| Build a wall | 100 ◈ |
| Create a Hunter job | 150 ◈ |

---

## 10. Guardian NPC & Encampment System

*Kingdom-style NPC hiring. Inspired directly by how Kingdom handles coin-for-peasant recruitment.*

### Discovery
- Dormant Guardians are placed throughout the level — standing still, semi-transparent green
- Player rides up within ~75px → action prompt appears: `[ SPACE ]  Recruit Guardian  —  75 ◈`
- If player has enough Glimmer and presses Space, 75 Glimmer is deducted and the Guardian activates

### Travel to Encampment
- Recruited Guardian turns solid green and walks left independently toward the Encampment
- No following — they navigate on their own using the Encampment's known x-coordinate

### Encampment
- Central base at the left edge of the level
- Player enters the zone → prompt shows current waiting Guardians and available actions
- Spend Glimmer to create a **job token** — Guardians auto-claim pending tokens on arrival
- If a Guardian arrives while a job is already queued, they claim it immediately

### Job Types

| Job | Color | Behavior |
|-----|-------|----------|
| Hunter | Orange | Patrols from encampment to furthest wall, engages enemies, repositions to walls at dusk |
| Builder | Blue *(future)* | Constructs and upgrades walls |
| Farmer | Lime *(future)* | Generates passive Glimmer |

### Hunter Behavior State Machine
```
DORMANT → (recruit) → MOVING_TO_CAMP → (arrive) → WAITING
WAITING → (job assigned) → HUNTING_PATROL
HUNTING_PATROL → (enemy detected) → HUNTING_ENGAGE → (enemy dead/gone) → HUNTING_PATROL
HUNTING_PATROL or HUNTING_ENGAGE → (dusk/wave) → REPOSITIONING → (at wall) → DEFENDING
```

### Tower / Turret (M2 Backlog)
- Hunters can occupy open spots on towers and shoot from the top
- Knocked off by air enemies or overwritten by upgrades
- Upgrade path changes occupant configuration

---

## 11. Defense Layers

| Tier | Name | Upgrade Resource |
|------|------|-----------------|
| 1 | Stick/Brick Base | — |
| 2 | Metal Reinforced | Spinmetal |
| 3 | Shield Reinforced | Spirit Bloom |

### Wall Behavior
- Enemies stop at walls and attack them
- Player and allied Guardians can move through walls freely (collision layer design)
- Walls have HP; destruction triggers fall-back to next wall line

### Alternate Structures
- **Laser Turret** — autonomous fire, no human needed
- **Missile Turret** — AoE damage, slow fire rate

---

## 12. Enemy Factions

### Earth — Fallen (House of Devils)
- **Palette:** Rust, brown, grey
- **Enemy type in use:** Dreg (CharacterBody2D, left-to-right march, targets Ghost)
- **Environment:** Highway, rusted cars, Last City wall backdrop
- **Wave cue:** Dusk falls → waves begin
- **Wave scaling:** Spawn interval decreases from 12s → 3s minimum as wave_number increases
- **Enemy types (full):** Dregs, Vandals, Shanks, Servitors, Captains
- **Access points to destroy:** Fallen drop ships, darkness rifts

### Moon — Hive
- **Palette:** Green, black — starts Archer's Point (bright night) → shifts to Crota's End darkness
- **Environment:** Craters, lantern-lit darkness, Hive structures
- **Wave cue:** Always night → Omnigul's shriek → waves begin
- **Enemy types:** Thrall, Acolytes, Knights, Wizards, Ogres
- **Access points to destroy:** Hive tombs, darkness portals

### Mars — Cabal
- **Palette:** Dusty red, military grey
- **Environment:** Open battlefield, drop pod craters, tanks in background
- **Wave cue:** Cabal brass music cue → drop pod slams into ground → waves begin
- **Enemy types:** Phalanxes, Centurions, Legionaries, Colossi, Tanks
- **Access points to destroy:** Drop pod launch sites

> **Future planets:** Venus (Vex), Dreadnaught (Taken), etc.

---

## 13. Win / Lose Conditions

### Lose — Ghost Captured
Ghost carried beyond tether range → tether snaps → screen fades red to black → **"Your Light has been extinguished."** → new run

### Soft Lose — City Overrun
Walls fall, defenders killed. Player can try to hide and rebuild if they can find Glimmer and recruits. City is not permanently lost until the Ghost is.

### Win a Planet
Destroy all enemy access points (drop ships, rifts, tombs) → enemies stop spawning → find/repair the ship → board and depart for next planet

---

## 14. Progression & Level Structure

- **Structure:** Left-to-right per planet, same as Kingdom islands
- **Layout variants:** Encampment in the middle (defend both sides) OR encampment at the edge (defend one side)
- **Verticality:** None — keeps performance lean, controls simple
- **Wave scaling:** Never-ending; waves grow in size/composition over time
- **Progression:** Infinite sandbox — no forced end state except "unlock everything"

### Planet Order (MVP)
1. Earth — Last City (tutorial energy, Fallen)
2. Moon (Hive, always night)
3. Mars (Cabal, siege warfare)

---

## 15. Visual Style

- **Art style:** Pixel art, silhouette-heavy
- **Parallax:** Multi-layer sky, mid-ground, foreground (Godot `ParallaxBackground`)
- **Color reference:** Destiny 1 palette — vibrant where rich, deeply muted where muted
- **Per-planet identity:** Each world has a distinct color language (see Enemy Factions)
- **Resolution:** Pixel-perfect scaling, nearest-neighbor filtering, designed for Steam Deck screen
- **Placeholder art:** ColorRect shapes with job-coded colors (dim green = dormant NPC, orange = hunter, blue = builder, lime = farmer)

---

## 16. Audio Direction

- **Score:** Original composition inspired by Marty O'Donnell — chiptune/bit forward, not full orchestral; full-sounding but not over the top
- **Ambient:** Mostly quiet; music carries the emotion
- **Sound design (must work without music):**
  - Fallen: servitor whirr, shank mechanical sounds, rustling
  - Hive: thrall chittering, Omnigul shriek
  - Cabal: armor clanking, drop pod impact, tank rumble
  - Environmental: wind, bushes, Ghost scan tone, Sparrow engine hum

---

## 17. Project Management

- **Tracker:** Obsidian Kanban (`03 - Kanban.md`)
- **Devlog:** `02 - Devlog.md`
- **Session Transcripts:** `Dev/Transcripts/`

### Milestones

| Milestone | Status | Scope |
|-----------|--------|-------|
| M1 | ✅ Complete | Player movement, Ghost tether, Glimmer economy, Dreg enemy, wave spawning, game over |
| M2 | 🔄 In Progress | Wall building, Guardian NPC system, encampment jobs, hunter AI |
| M3 | ⬜ Backlog | Ghost discovery scenes, Guardian super abilities, Legendary Shards |
| M4 | ⬜ Backlog | Full Earth loop, ship repair, planet transition |
| M5+ | ⬜ Backlog | Moon, Mars, additional Sparrows/Ghosts |

---

## 18. Open Questions

| # | Question | Owner |
|---|----------|-------|
| OQ-01 | Void Titan: Saint-14 or Zavala? | Ellis |
| OQ-02 | Arc Guardian characters (Hunter: Shiro-4 confirmed? Warlock: who?) | Ellis |
| OQ-03 | Glimmer cap amount | ✅ Set at 25,000 |
| OQ-04 | Sparrow unlock: world discovery or purchased? | Ellis |
| OQ-05 | Ghost ability unlock order — which element do you find first on Earth? | Ellis |
| OQ-06 | Shooting Sparrow mechanics | TBD when core loop is solid |
| OQ-07 | IP pivot plan if game goes commercial | Future |
| OQ-08 | Post-wave behavior for Hunters — return to patrol or stay at wall? | Ellis |
| OQ-09 | Wall HP values — how many hits before destruction? | Ellis |
| OQ-10 | Tower occupancy — how many Hunter slots per tower? | Ellis |

---

## 19. Scope: MVP vs. Future

### MVP
- Earth level (Fallen), full left-to-right loop
- 3 Solar Guardians (Cayde, Ana, Osiris)
- Standard + 1 alternate Sparrow
- All 3 wall tiers, all 4 defender tiers
- Hunter / Builder / Farmer job system
- Opening scene, Ghost tether, Glimmer economy
- Steam export

### Future
- Moon (Hive) + Mars (Cabal) planets
- Full 9-Guardian roster (Solar, Void, Arc)
- Stasis + Strand elements
- All Sparrow types including shooting
- Named Guardian Ghost discovery scenes (cinematics/moments)
- Tower / turret structures with Hunter occupancy
- Browser export polish
- Co-op / multiplayer (Kingdom Two Crowns model)
