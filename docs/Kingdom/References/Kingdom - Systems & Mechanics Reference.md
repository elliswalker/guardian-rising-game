---
title: Kingdom Series — Systems & Mechanics Reference
aliases: [Kingdom Mechanics, Kingdom Systems Reference]
tags:
  - gaming
  - game-design
  - kingdom-series
  - reference
created: 2026-06-19
---

← [[Kingdom - Design Bible]]

# Kingdom Series — Systems & Mechanics Reference

> **Covers:** Kingdom Classic · Kingdom: New Lands · Kingdom Two Crowns · Kingdom Eighties  
> **Purpose:** Complete reference for how the games work — loops, systems, AI, tech trees, and the developer tricks that make it all feel alive.

---

## 1. The Core Loop

Every Kingdom game runs on a single repeating heartbeat:

```
DAYTIME  →  Explore / Recruit / Build / Earn
DUSK     →  Return to safety / Last-minute decisions
NIGHTTIME →  Defend against Greed waves
DAWN     →  Count the damage / Repair / Repeat
```

This loop never changes across all four games. What changes is the *pressure* applied to it: how fast winter comes, how many portals are active, how far you've pushed outward. The loop itself is sacred.

### The Day Counter
Days are numbered continuously. Every 64 days = 1 full seasonal cycle (4 seasons × 16 days). Blood Moons and escalating Greed difficulty are tied to this counter — the world gets harder over time whether you're ready or not.

### The Stakes
The Monarch carries a Crown. Lose both crowns (New Lands / Two Crowns co-op: each player's crown) → run ends. No health bar, no lives, no continues. Everything the player has built is lost or left behind.

---

## 2. The Economy

### Coins — Primary Currency
- Everything is bought with coins: recruitment, construction, upgrades, boats, banners, hermit hire
- Coins spill from the bag on certain hits; overflow either drops on ground or falls into water (50/50 chance)
- Main income sources: hunting (rabbits 1c, deer 3c), farming (passive per day), chests in forest, berry bushes (winter forage), banker interest, boar kills

### Gems — Secondary Currency (Two Crowns only)
- Used for permanent statue unlocks and certain mount purchases
- Stored in a Gem Bank (survives between islands)
- Limited per save — each gem is precious. Statues bought with gems can be re-purchased with coins if you die and restart
- Not present in Classic or New Lands

### The Banker
- Unlocked at Tier 4 Kingdom (Town)
- Stores coins; earns 7% interest daily, capped at 8 coins/day
- Interest accumulation stops above 101 coins stored
- Withdraw 1/3 of stored coins at a time, daytime only
- Goes indoors at night — completely safe from Greed
- **Strategic role:** The Banker is a safety valve. Early game: dump excess coins in. Mid-game: withdraw to fund a major build push. Never lose coins to overflow.

### The Coin-Drop Interaction Model
The only verb in Kingdom is **give coins**. Every action in the game — recruiting, building, sailing, blessing statues, hiring hermits — is performed by holding the spend button near something. No menus, no dialogue, no item selection. If you have coins, you can do things. If you don't, you're stuck. This single mechanic creates all the strategic tension the game needs.

---

## 3. Subjects & Citizen AI

### The Recruitment Pipeline
```
Vagrant Camp → Vagrant → Peasant (1c) → Role (tool pickup)
```

Every 2 minutes, a Vagrant spawns at a camp (max 2 waiting at a time). Toss them a coin → Peasant. Peasants walk to the nearest available tool shop and pick up a tool automatically. No assignment needed from the player.

| Tool | Role | Primary Daytime Behaviour | Night Behaviour |
|---|---|---|---|
| Bow | Archer | Hunt rabbits & deer in forest | Defend outer walls, fire at Greed |
| Hammer | Builder | Construct queued buildings, repair walls | Idle near outer walls |
| Scythe | Farmer | Work assigned farm field | Return to center |
| Spear | Pikeman | Go fishing (earns 1c/fish; works in winter) | Defend outermost wall with stabs |
| Katana | Ninja (Shogun) | Lounge at dojo, go fishing | Ambush Greed from forest edge |
| Shield | Squire (K2C) / Knight (NL) | Wait at outer wall | Lead squad to push portals |

### Archers — The Backbone
Archers are the primary income source (hunting) and primary defensive force. Their accuracy from ground level is roughly 33%; from a Tower it's near 100%. The Statue of Archery eliminates all missed shots entirely — arguably the most valuable permanent buff in the game.

Archers assigned to a Squire's squad stop hunting. They follow the Squire everywhere and provide combat support for portal pushes. This means pulling Archers into a squad has an economic cost (less hunting income) — a deliberate trade-off.

### Farmers — The Economy Scaling Tool
Farmers ramp up coin income dramatically in the mid-game. A Tier 1 Farm has a limited capacity; a Tier 2 Farmhouse operates overnight (more productive, but the Farmer is exposed). The Statue of the Sithe doubles farmer slots per farm. In winter, Farmers can forage berry bushes if given a coin (1c activation).

**Design insight:** Farmers represent long-term investment vs. immediate spending. Prioritising farms early means more coins to spend later — but early game you often can't afford to. This creates natural early/mid/late game phases without any level gating.

### Pikemen (Classic/Default biome) vs. Ninjas (Shogun)
Pikemen are disposable: their spear breaks after a few stabs. They fill a defensive niche (their stab pierces multiple Greed in a line) and an economic niche (fishing income in winter). Ninjas replace this role in the Shogun biome with a stealth-ambush pattern — they sneak to the forest edge before enemies arrive, hide, then leap out. Different feel, same system slot.

### Squires & Knights — The Push Force
Squires are the only units the Monarch actively deploys offensively. Paying the Banner (4c) commands a Squire and their arrow squad to march toward the nearest portal. This is entirely player-directed — no other units move offensively without this command.

```
Shield Shop → Squire (4c) → picks up Sword from Forge → Knight
```

Knights have higher coin capacity (acts as extra HP when coins are given to them), lower chance of losing their shield, and the Lunge ability when the Statue of Knights is active. Getting a Squire promoted to Knight is a mid-game milestone.

### Hermits — The Specialists
Hermits are found in the wilderness, walk extremely slowly, and must be picked up by the Monarch (1c) and physically carried to their build site. Dropping them off triggers construction of a unique building. They're the only units who can't be made from the standard recruitment pipeline — each is a one-of-a-kind discovery.

| Hermit | Building | Effect |
|---|---|---|
| Tide (Ballista) | Mighty Ballista | Long-range piercing siege weapon; kills Floaters in one shot |
| Stable | Stable | Stores 2 mounts; converts Farmhouse to mount storage |
| Baking | Bakery | Attracts distant Vagrants with bread (4c/loaf, up to 7 loaves) |
| Valor | Armory | Adds extra Squire slot per side |
| Horns | Rally Wall | Pay 1c to call ALL troops to that wall |

Hermits kidnapped by Greed can only be recovered by destroying that island's cliff portal — a permanent loss if you sail away without them.

---

## 4. The Greed — Enemy Design

### Design Philosophy: Simple AI, Perceived Complexity
The Greed have no complex behaviour. Their intelligence is minimal:

1. Move toward nearest coin/tool on the ground
2. Attack units to knock tools loose
3. Attack walls
4. Target the Monarch (for the crown)

What creates the *perception* of difficulty and unpredictability is **quantity, timing, and escalation** — not behaviour complexity. A hundred simple enemies at the right moment feel overwhelming.

### Enemy Type Roster

**Base Greed**
- One arrow kills them
- Can be bribed: drop coins in their path → they grab coins and retreat
- This "bribe" mechanic is a critical early-game tool players must discover themselves
- They retreat at dawn (except Blood Moons)

**Armored Greed**
- Wear masks for extra HP; mask must be destroyed first
- Can still be bribed

**Floaters (Flying)**
- Appear on Blood Moons or after portal destruction
- Ignore walls entirely — airborne
- Grab subjects (up to 2) and carry them back to portals
- AoE hit knocks coins from bag and tools from subject hands
- Killed before reaching portal → drops subjects alive
- One shot from Catapult or Mighty Ballista
- **Cannot be bribed. Cannot be stopped by walls.**
- Primary threat driver for upgrading towers to floater-proof tiers

**Breeders (Heavies)**
- Extremely slow, extremely tanky
- Spawn 3–4 Greed every few seconds while alive
- Hit knocks coins from Monarch's bag
- Mount rears up near Breeders — you can't run past them easily
- Can catch and **throw catapult rocks back** at your walls and troops
- Can directly punch and destroy lower-tier walls
- Can carry a Crownstealer
- **Cannot be bribed. Never retreat.**
- Require catapult or massed knight fire to kill efficiently

**Crownstealers**
- Usually ride Breeders into battle
- Dismount when Breeder dies or crown is exposed
- Extremely fast — outruns most mounts, jumps over walls
- Always knocks the crown off on first hit regardless of coins carried
- Low health — prepped archers in towers can kill them
- The most psychologically threatening enemy in the game

### Blood Moon
Triggered by: destroying a portal, or periodically as days accumulate. Waves attack during daytime, not just at night. Wave doesn't end until enemies are killed. If a Blood Moon runs into the next night, a second wave spawns on top of the first. Proper fortification vs. overexpansion is the entire preparation problem.

### Portal Logic
- **Normal portals:** Closed during day, open at night. Attacking them opens them immediately. Destroying one triggers a Blood Moon.
- **Dock portal:** Only activates after all normal portals on that side are destroyed. Has a tentacle AoE attack. Destroying it allows Lighthouse construction.
- **Cliff portal:** The primary boss structure per island. Very high HP. In Two Crowns: must be bombed (build Iron Castle → Bomb Banner → escort workers → detonate). Destroying it triggers portal reconstruction over ~3 days; no spawning during this window, then full reset.

---

## 5. Technology Tree & Progression

### Kingdom Tier (Central Structure — Auto-Upgrades)

| Tier | Name | Cost | Unlocks |
|---|---|---|---|
| 0 | Campsite | — | Starting state |
| 1 | Campfire | 3c | Bow Shop + Hammer Shop |
| 2 | Camp | 6c | Tents (cosmetic); Scythe Shop available |
| 3 | Village | 9c | Free Tier 1 Walls both sides |
| 4 | Town | 12c | Church, Banker, Catapult Station |
| 5 | Fort | 15c (Stone Age req.) | Free Tier 3 Walls + Tier 2 Towers both sides |
| 6 | Castle | 18c | Squire shields available; Gem Bank appears |
| 7 | Iron Castle | 20c (Iron Age req.) | Free Iron Walls; Bomb Banner unlocked |

The Kingdom upgrade is the only structure that upgrades without requiring workers. Spend the coins and it just happens. Everything else requires a builder to be physically assigned.

### Age Gating — The Series' Core Progression Gate

**New Lands:** The Obelisk (found in forest, pay 7c) unlocks Stone Age. It doesn't spawn on Island 1. You must explore to find it. Stone Age → Tier 3/4 walls/towers → Castle → ship.

**Two Crowns:** Permanent mine purchases replace the Obelisk:
- **Stone Mine** (Island 2, 10c) → Stone Age unlocked permanently across all islands
- **Iron Mine** (Island 4, 20c) → Iron Age unlocked permanently across all islands

This is a major structural change: in New Lands you must discover the unlock; in Two Crowns you must spend resources at the right moment. Same gate, different problem.

### Walls

| Tier | Type | Cost | Notes |
|---|---|---|---|
| 0 | Natural (dirt/rock pile) | Free | Starting state |
| 1 | Barricade | 1c | |
| 2 | Wood Wall | 3c | |
| 3 | Stone Wall | 5c | Stone Age required |
| 4 | Castle Wall | 8c | |
| 5 | Iron Wall | 12c | Iron Age required (Two Crowns only) |

### Towers

| Tier | Type | Archers | Notes |
|---|---|---|---|
| 0 | Rock Pile | 0 | Natural feature |
| 1 | Raised Platform | 1 | 3c |
| 2 | Watchtower | 1 | 6c; archer is safe from ground attacks |
| 3 | Defense Tower | 2 | 9c; Stone Age required |
| 4 | Castle Tower | 3 | 12c; enables Hermit upgrades |
| 5 | Fortified Tower | 3 | 15c; protects from Floater abduction |
| 6 | Iron Tower | 4 | 18c; fully Floater-proof (Two Crowns only) |

Hermit buildings (Mighty Ballista, Armory) require T4+ tower as a base. They can't be built without the tower tier prerequisite being met first.

### Farms

- Stream (natural, T0) → Day Farm T1 (3c) → Farmhouse T2 (8c)
- Hermit of Stable converts a T2 Farmhouse into a Stable (8c), which stores 2 mounts

### Statues — Daily (New Lands) vs. Permanent (Two Crowns)

In New Lands, statues are found in the forest and must be activated daily (4–8c/day). Let them lapse and they go dark.

In Two Crowns, statues are unlocked once with gems and then activated once with coins — permanent for the entire reign. Gems sink into statues before anything else; they're not worth losing.

| Statue | New Lands Cost | Two Crowns Cost | Effect |
|---|---|---|---|
| Archery | 4c/day | 4 gems + 10c | Archers never miss |
| Sithe | 4c/day | 1 gem + 7c | +2 farmer slots per farm |
| Building | 8c/day | 3 gems + 9c | Increased wall max HP |
| Knights | 8c/day | 2 gems + 9c | Knights gain lunge attack |

---

## 6. Mount System

Every mount has a stamina bar. Sprinting depletes it. Grazing on grass patches refills it (white dust particles = unlimited stamina window). **Grazing is impossible in winter except on special mounts** — the Griffon and Undead Horse are the standout exceptions.

### Two Crowns Mount Roster

| Mount | Location | Cost | Speed | Special Ability | Tier |
|---|---|---|---|---|---|
| Default Horse | Start | 2c | Baseline | None | F |
| Griffon | Island 1 | 2 gems + 8c | +17.5% field, +22% forest | Blow back/stun enemies (costs stamina); can graze anywhere incl. winter | S |
| Stag | Island 2 | 1 gem + 3c | +37.5% forest (−56% field walk) | Attracts deer to follow; great hunting economy | A |
| Wild Horse | Island 3 | 1 gem + 4c | Best raw stamina pool | None | A |
| War Horse | Island 3 | 2 gems + 8c | Lower | On sprint start: all nearby troops get 10s damage immunity | B |
| Lizard/Dragon | Island 4 | 3 gems + 10c | Low (strong walk) | Fire breath (hold = fire trap on ground, permanent DoT) | B |
| Great Bear | Island 4 | 3 gems + 11c | Very low | Attacks deer & Greed while sprinting (1 arrow damage) | F |
| Unicorn | Island 5 | 4 gems + 12c | Baseline | After grazing: ejects 3 coins every ~12s | C |

**Mount strategic notes:**
- Griffon is universally regarded as the best for portal assault runs — can graze in forest, stun ability creates an escape window
- Stag severely loses speed in open fields; effectively useless in winter (no deer, can't graze)
- War Horse buff is a powerful defensive situational tool; weaker for general use
- Dragon/Lizard is S-tier in co-op (second player spams fire from safety); otherwise niche
- Unicorn shines very early (free coins from grazing); loses value as economy scales

---

## 7. Island Progression & Persistence

### New Lands
5 islands + Skull Island. Each island requires building and launching the Boat to escape before a permanent winter locks it down. Cliff portals **cannot** be permanently destroyed — escaping is the win condition. What carries over: nothing except the Monarch and the knowledge you've gained.

### Two Crowns
5 islands. Win condition per island = bomb the cliff portal. The Boat carries you forward.

**What carries between islands:**
- The Monarch's crown
- Coins currently carried in the bag
- Gems in Gem Bank
- Currently ridden mount
- Hermits auto-board the boat
- Stone Mine and Iron Mine unlocks (permanent forever once purchased)

**What does NOT carry:**
- All buildings, walls, and towers
- All recruited subjects
- All local economy infrastructure

**Decay system:** While absent from an island, walls and structures degrade slowly. Lighthouses (built at dock after destroying dock portal) provide protection windows: Wood Beacon = 10 days, Stone = 20 days, Iron = 30 days of decay protection. Returning to an island without a Lighthouse up means finding your defences depleted.

### Teleporters (Two Crowns only)
Build on a destroyed portal remnant for 8c. Pay 2c to use; 15 seconds to select destination. Two teleporters can be permanently linked for 2c/use, 70-second cooldown. Critical for late-game island management when you need to move resources or subjects quickly.

---

## 8. How the Games Differ

| Feature | Classic | New Lands | Two Crowns | Eighties |
|---|---|---|---|---|
| Win Condition | Survive (endless) | Escape all islands by boat | Bomb each cliff portal | Destroy the dimensional rift |
| Islands | 1 (continuous) | 5 + Skull | 5 | Single structured map |
| Persistence | None | None | Coins, gems, mines, mount | N/A (episodic) |
| Stone/Iron Age | Simple 4-tier | Obelisk gating | Mine gating | Same as K2C |
| Age Unlock | Shop tiers | Find Obelisk in forest | Buy Stone/Iron Mine | — |
| Seasons | None | Yes (winter permanent) | Yes (cycling) | Not primary mechanic |
| Hermits | None | 3 types | 5 types | Present |
| Co-op | No | No | Yes (2P online + local) | Yes (local only) |
| Gems | No | No | Yes | Yes |
| Currency Name | Coins | Coins | Coins | Coins / Boomboxes (thematic) |
| Statues | Simple/daily | Daily | Permanent (gem) | Permanent |
| Knights/Squires | No knights | Shield → Knight direct | Shield → Squire → Sword → Knight | K2C rules |
| Pikemen | No | Yes | Yes | Equivalent (reskin) |
| Catapults | No | Limited (2 total) | Catapult Station | Yes |
| World Shape | Linear | Linear | Looping (toroidal) | Linear episodic |
| Cliff Portal Destroy | N/A | Can't (escape instead) | Yes (bomb) | Equivalent |
| Structure | Endless survival | Multi-island sail | Multi-island bomb + sail | Episodic chapters |
| Tone | Medieval fable | Medieval fable | Medieval fable + DLC skins | 80s suburban horror |

---

## 9. Developer Tricks & Clever Design

### 1. Simple AI, Perceived Complexity
Greed AI is five lines of priority logic. The complexity players feel comes entirely from wave timing, quantity scaling, and the moment-to-moment terror of a Crownstealer moving faster than their mount. No pathfinding, no flanking, no tactical decision-making. Pure pressure simulation from dumb actors.

### 2. The Total Reskin DLC Model
Two Crowns' DLC kingdoms (Shogun, Dead Lands, Norse Lands, Eighties, etc.) are **complete asset swaps with identical underlying systems**. The code doesn't change. The medieval castle wall becomes a bamboo gate; the Archer becomes a Ninja; the coin becomes a Mon. Because the systems are airtight, they tolerate full aesthetic replacement without breaking. One codebase, radically different tonal experiences.

### 3. Procedural Generation Masking Content Limits
Each run generates a different world — resource node positions, portal locations, hermit positions, starting layout all vary. This creates the illusion of a much larger game than it actually is. A game with perhaps 40–50 distinct building types feels inexhaustible because you can never predict which combination you'll need to solve this particular island.

### 4. World Wrapping (Two Crowns)
Islands in Two Crowns loop. Ride far enough right and you wrap to the left edge. This eliminates dead-end map edges and forces a genuinely different strategic question: you can't anchor your one good wall to "the end of the world." Both edges are active threats simultaneously.

### 5. Consequence-Based Teaching
There is no tutorial. Players learn by losing. Got killed by a Crownstealer? Now you build more towers. Lost your coin bag to a Floater? Now you rush Fort-tier towers. This teaching method is only possible because the game is *beautiful and calm during the day* — it gives you enough peace to reflect on what went wrong before the next night.

### 6. The One-Verb Interface
Toss coins. That's it. No build menus, no context switching, no radial wheels. The player holds one button near a target, holds it as long as they want to spend, and releases. The entire RTS-adjacent layer of a strategy game is compressed into a single controller input. This allows the game to target zero-UI complexity while still delivering deep strategy.

### 7. Diegetic Audio as UI
There are no HUD indicators for most events. Instead:
- Enemy proximity is signalled by Greed screech sounds before they appear visually
- Construction completion has a distinct audio signature
- The coin-drop sound for each action is varied by building tier (bigger building = different pitch/weight)
- The horse's hoofbeat rhythm changes with speed, giving a physical sense of urgency
- Music layers shift in real-time from calm → tense as night approaches

The sound design replaces approximately 80% of what a traditional game UI would show as text or icons.

### 8. Staged Complexity Introduction
Each island introduces one or two new systems. Island 1 in Two Crowns: learn basic recruiting and building. Island 2: the Stone Mine permanently changes what you can build — a concrete, irreversible upgrade milestone. Island 3: Hermits (rare, must be found and carried). Island 4: Iron Mine. Island 5: final confrontation with full kit. Players are never overwhelmed because new complexity arrives at intervals tied to geographic progress.

### 9. The Day/Night Cycle as Game Clock
The series has no in-game calendar UI, no quest timers, no explicit countdown. The sun and sky ARE the timer. Warm golden light = safe. Orange dusk = decision point. Blue-black = danger. Players develop a physical intuition for time just from the colour temperature of the sky. This is atmosphere serving function.

---

## 10. Kingdom Eighties — Mechanical Specifics

### The Setting Translation Table

| Classic/K2C Concept | Eighties Equivalent |
|---|---|
| Monarch on horseback | Camp counselor on bicycle / Camper Van |
| Coin | Coin / Boombox |
| Archers | Kid subjects (equivalent roles) |
| Castle walls | Camp perimeter / suburban barriers |
| Medieval forest | Suburban America / summer camp / mall |
| Stone castle | Treehouse clubhouse |
| Greed monsters | 80s horror movie creatures |
| Crown | Crown of Creation (family heirloom) |

### Key Differences
- **Episodic structure:** Not a procedural run. Each chapter has fixed locations (Redwood Forest, Skate Park, Royal Highschool, Downtown Main Street, New Lands Mall). Story-driven, linear progression.
- **Shorter:** 3–5 hours vs. multi-session Two Crowns campaigns
- **Companion puzzle system:** Three companions (The Champ, The Tinkerer, The Wiz) have combinable abilities for environmental puzzles — a layer absent from Two Crowns
- **New player friendly:** The narrative context acts as onboarding. Eighties is designed to bring in players who wouldn't start with Two Crowns
- **Local co-op only:** No online co-op (Steam Remote Play Together counts)
- **Single continuous map:** Closer to Classic in structure; no multi-island sailing
- **Synthwave score:** Full synthwave/John Carpenter-influenced OST by Andreas Hald, replacing the folk/acoustic of classic entries

### Greed Continuity
The Greed in Eighties are the same ancient force as in all other games — not a new enemy type. The lore explicitly positions them as a cross-generational threat targeting the same family lineage across different time periods. The win condition (seal the dimensional rift) is structurally identical to bombing the cliff portal — just reskinned.

---

## Related Notes
- [[Kingdom - Design Bible]]
