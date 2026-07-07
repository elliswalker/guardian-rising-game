---
title: Kingdom Series — Design Bible & Direction
aliases: [Kingdom Design Bible, Kingdom Creative Direction]
tags:
  - gaming
  - game-design
  - creative-reference
  - kingdom-series
created: 2026-06-19
---

← [[Kingdom - Systems & Mechanics Reference]]

# Kingdom Series — Design Bible & Creative Direction

> **Purpose:** This document defines what makes the Kingdom universe *feel like Kingdom*. Use it as the input reference when generating new ideas, content, systems, or settings for any Kingdom game. Any idea run through this lens should produce something that fits.

---

## The Three-Word Brief

> **Beautiful. Calm. Tense.**

These three words are the entire design mandate of the Kingdom series, articulated by creator Thomas van den Berg (noio). They must coexist simultaneously — not alternate. The beauty of a calm day makes the night feel dangerous. The tension of the night makes the calm feel precious. Remove any one of the three and the game stops being Kingdom.

Every design decision in the series — no UI text, no direct combat, reactive music, parallax forests, coop that doesn't trivialise the loop — exists to serve these three words.

---

## The Emotional Rhythm

Kingdom is built on a **push-pull cycle** that produces a very specific emotional experience:

```
DAY   →  Relief, agency, ownership, satisfaction
DUSK  →  Urgency, last-minute judgement, rising dread
NIGHT →  Tension, helplessness-adjacent anxiety, reactive decision-making
DAWN  →  Audit, assessment, resilience
```

The daylight is earned peace. The night is earned consequence. Neither is padding.

### The "Precious Calm" Principle
The daytime sections work because they are **genuinely peaceful** — not filler before combat. A player who just survived a terrifying Blood Moon and is now galloping through an autumn forest watching deer scatter while coins clink into their bag is experiencing reward. Destroy that peace (with pop-ups, timers, intrusive UI, rushed pacing) and the tension at night becomes meaningless. **Protect the calm.**

---

## The Five Core Pillars

Every mechanic, enemy, structure, and aesthetic choice in Kingdom must pass through these pillars:

### Pillar 1 — Extreme Input Minimalism
The player has one verb: **give coins**. Direction of movement and coin-toss are the complete input model. Any new idea that requires a second verb, a menu, or a dialogue choice is incompatible with the series unless it is mapped onto the coin-toss interaction.

> *"Can this be expressed as: ride to it, hold the button, spend coins?"*

If no → redesign until yes, or cut it.

### Pillar 2 — No Text in the World
Nothing in the game world is explained in written language. Icons only. Consequences only. The game teaches through action and loss, not instruction. If a player needs to read to understand a mechanic, the mechanic is not yet designed correctly.

This is not a constraint imposed on the content — it *is* the content. The moment of discovery (oh, that's what the hermit does) is a joy that written tooltips would destroy.

### Pillar 3 — The Monarch Can't Fight
The player is powerful because of what they *direct*, not because of what they *do*. The Monarch has no attack. Riding into enemies causes the mount to rear back. All offensive action is mediated through subjects the player has built and deployed. This creates strategic anxiety — you can't save yourself, only the conditions you've prepared.

Any creature or system that allows the Monarch direct offensive power fundamentally changes the feel of the game.

### Pillar 4 — The Greed Are Ancient and Impersonal
The Greed have no motivation beyond acquisition (coins, tools, the crown). They are not villains with goals. They are a force of entropy. They don't hate the Monarch — they would strip a stone the same way. This impersonality is what makes them genuinely threatening rather than narratively satisfying to defeat.

The Greed's mystery is protected at series level — they are never fully explained.

### Pillar 5 — Every Resource Has Dual Purpose
Coins recruit AND build AND pay for boats AND activate statues. Subjects hunt (income) AND defend (military). Every system has double function. This creates constant tension between competing needs for the same resource, which is where all the interesting decisions live. A mechanic that doesn't interact with or compete against the core coin economy is likely surplus.

---

## The Aesthetic System

### Visual Grammar

**Medium-resolution pixel art, painterly and impressionistic.** Not ultra-low-resolution retro pastiche. Sprites are detailed enough to be readable and characterful, limited enough to be elegant.

**The World Has Depth via Parallax:**
- Far background: sky, celestial bodies, gradients
- Mid-far: distant silhouetted horizons (mountains, skyline, tree canopy)
- Mid: slower-scrolling forest layer, individual large trees
- Near-mid: buildings, characters, terrain
- Foreground: fast-scrolling foliage overlaps

This multi-layer scroll creates perceived scale without any 3D geometry. The world feels large because the layers suggest distance.

**Color Tells the Story:**

| State | Palette | Emotional Register |
|---|---|---|
| Dawn | Warm gold, pale yellow, long shadows | Hope, renewal, safety |
| Full day | Bright green/blue, high sat, clear | Agency, abundance |
| Dusk | Orange, amber, deep red horizon | Urgency, transition |
| Night | Deep blue-purple, near-black trees | Danger, isolation |
| Blood Moon | Red sky wash on all layers | Maximum threat |
| Winter | Desaturated whites, bare silhouettes | Scarcity, endurance |

Color grading affects all parallax layers simultaneously — the world changes, not just the sky. This is what makes the cycle feel like atmosphere, not a layer toggle.

**Seasonal Visual Identity:**
- **Spring:** Fresh greens, light yellows, occasional blossom particles
- **Summer:** Peak saturation, full canopy, warmth — the "beautiful" season
- **Autumn:** Oranges, reds, falling leaf particles, reduced foliage — the "warning" season
- **Winter:** Almost monochrome whites and greys, bare tree silhouettes, snowfall particles

### Audio Grammar

**Layered adaptive stems:** The music is built from instrument stacks that fade in and out based on game state. The base ambient layer is always present. Daytime adds organic melodic instruments. Approaching night adds tonal tension. Active attacks layer in percussion and dissonance. Near-death adds chaos layers.

The player is never told the threat level by a UI element. They *feel it in the music*.

**Diegetic sound as HUD replacement:**
- Coin clinks → economy feedback
- Construction sounds → build status without progress bars
- Horse hoofbeat rhythm → speed/urgency signal
- Greed screech → proximity warning before visual appearance
- Dawn bird sounds → "you survived" confirmation

Every piece of audio information in the game replaces something that would be a HUD element in a conventional game.

---

## Setting Translation System

Kingdom can be skinned to any historical, cultural, or tonal setting without breaking — as proven by Shogun, Dead Lands, Norse Lands, and Eighties. The methodology is a **1:1 semantic swap**:

| Original Element | Shogun | Dead Lands | Eighties | Template Slot |
|---|---|---|---|---|
| Monarch on horse | Shogun/Onna-bugeisha on Kirin | Miriam on Ghost Horse | Kid on bike/van | [PROTAGONIST + VEHICLE] |
| Coin | Mon (Japanese currency) | Coins | Boombox/coins | [CURRENCY VISUAL] |
| Medieval castle | Japanese castle/torii gates | Gothic ruin | Treehouse/chain-link | [BASE AESTHETIC] |
| Stone wall | Bamboo + stone wall | Crumbling stone | Concrete barriers | [WALL MATERIAL] |
| Archer | Samurai archer | Shambling bowman | Kid with slingshot | [RANGED UNIT] |
| Builder | Craftsman | Undead laborer | Tinkerer kid | [CONSTRUCTION UNIT] |
| Farmer | Rice farmer | — | Camp cook | [ECONOMY UNIT] |
| Pikeman/Ninja | Ninja | Skeleton spearman | Biker kid | [MELEE UNIT] |
| Knight | Samurai | Armored undead | — | [HEAVY UNIT] |
| Greed | Greed (same force) | Greed (corrupted) | 80s creatures | [ANTAGONIST SKIN] |
| Forest | Bamboo forest | Dead forest | Suburb/pine woods | [WILDERNESS] |
| Hermit | Hermit | Hermit | Neighbor NPC | [SPECIALIST NPC] |
| Blood Moon | Red moon | Skull moon | Neon red sky | [ESCALATION SIGNAL] |

**The Greed remains the same ancient force in all settings.** This is non-negotiable for series coherence. The Greed predate the setting. They exist across time. Whatever monsters appear, they are an expression of the same impersonal entropy that attacks medieval kingdoms and 80s summer camps alike.

---

## The Mystery Contract

Kingdom is a game of secrets. The player discovers things; the game never announces them. This "Kingdom of Secrets" philosophy extends to lore:

- **The Greed's nature is never explained.** Where they come from, what they want beyond coins and crowns, whether they are conscious — never stated.
- **The Crown's power is never explained.** Why do they want it? The game's answer is implied, not spoken.
- **The Hermits' backgrounds are never explained.** Who are they? Why do they live alone? Why do their buildings have magical effects?

Any new content added to the Kingdom universe should preserve this opacity. The pleasure is in implication, not exposition. Add mysteries; don't solve them.

---

## Lore Anchors (Canonical Series Elements)

These facts are consistent across the series and should not be contradicted by new content:

1. **The Crown is the protagonist's identity and their most valuable possession.** Losing it ends everything.
2. **The Greed are a timeless, faceless force.** They are not a race with culture or motivation. They want coins, tools, and the Crown. That's all.
3. **The wilderness is neutral but dangerous.** It is not the Greed's domain — it is simply wild. Greed emerge *from* portals *in* the wilderness. The forest itself is also home to mounts, hermits, vagrants, and resources. The tension is navigating this dual nature.
4. **Building is resistance.** Every wall, every tower, every farm is the Monarch saying "not today." The game's narrative is architecture.
5. **Coins are willpower.** The Monarch can do nothing without coins. Running out doesn't mean you lost — it means you need to think harder before spending. Hoarding coins is cowardice; spending recklessly is suicide. The middle path is the skill.
6. **The setting changes. The threat does not.** Whether medieval, feudal Japan, or 1980s suburban America — the Greed were there first. Every DLC/spinoff is a chapter in an infinite story of the same ancient siege.

---

## How to Design for Kingdom — A Prompt Framework

When introducing a new idea into the Kingdom universe, run it through this filter:

### Step 1 — The Slot Test
> What existing Kingdom element does this replace or extend? Name the slot (mount, enemy type, unit role, building tier, currency visual, biome, etc.)

If the idea doesn't fit an existing slot and isn't a meaningful new slot with clear systemic purpose, it may not belong here.

### Step 2 — The Verb Test
> Can this be interacted with using only the existing coin-toss verb?

If not, rethink the interaction model. Kingdom doesn't add new verbs. Everything bends to the existing one.

### Step 3 — The Calm Test
> Does this idea interrupt or harm the daytime calm?

If yes, it either needs to be a night-only element, or rethought entirely. Daytime is sacred.

### Step 4 — The Text Test
> Can a player understand what this does without reading anything?

If they'd need a tooltip, the visual design of the idea isn't finished.

### Step 5 — The Economy Test
> Does this mechanic interact with or make demands on the coin economy?

If it's a free action, it's not creating meaningful decisions. Almost everything in Kingdom has a coin cost because that cost is what forces choices.

### Step 6 — The Greed Test
> If this is a new enemy or threat mechanic — does it still feel like an expression of the ancient, impersonal Greed? Or does it have a personality, a narrative goal, or specific hatred of the Monarch?

The Greed don't hate you. They consume. Stay in that lane.

### Step 7 — The Mystery Test
> Does this idea explain something that is currently mysterious? Does it give the Greed a backstory, the Crown a history, the hermits an origin?

Reduce, don't explain. Add another layer of implication instead.

---

## Designing a New Setting (Biome / Campaign)

Use this template when proposing a full biome skin:

```
SETTING NAME:
HISTORICAL/CULTURAL ANCHOR: (e.g., feudal Japan, Viking-age Scandinavia, 1950s America)
TONAL REGISTER: (e.g., folk horror, sci-fi dread, mythic epic, suburban nostalgia)
PROTAGONIST SKIN: [who is the Monarch in this world?]
VEHICLE SKIN: [what replaces the horse?]
CURRENCY VISUAL: [what do coins look like?]
BASE AESTHETIC: [what does the castle/center become?]
WALL MATERIAL: [what are barriers made of?]
WILDERNESS CHARACTER: [what kind of forest/terrain?]
UNIT ROSTER SKINS: [Archer → ?, Builder → ?, Farmer → ?, Pikeman → ?, Knight → ?]
GREED SKIN: [how do the monsters look in this cultural context?]
HERMIT EQUIVALENT: [how do specialist NPCs appear?]
MOUNT ROSTER: [what animals/vehicles serve mount roles?]
SEASONAL/LIGHTING PALETTE: [how do seasons look here?]
MUSICAL REGISTER: [what genre/instrument palette for the adaptive score?]
UNIQUE MECHANIC: [one new system that only makes sense in this setting]
MYSTERY ELEMENT: [what unanswered question does this setting add to the lore?]
```

---

## Designing a New Mechanic

```
MECHANIC NAME:
SLOT: [what does it replace or extend?]
COIN COST: [what does it cost? when?]
PLAYER INTERACTION: [how does the player trigger/use it via coin-toss?]
DAYTIME FUNCTION: [what does it do during the safe phase?]
NIGHTTIME FUNCTION: [what does it do during the threat phase?]
TRADE-OFF: [what does using this cost or sacrifice in the coin economy?]
DISCOVERY METHOD: [how does a player learn this exists without being told?]
AUDIO CUE: [what sound tells the player this worked?]
SERIES CONSISTENCY CHECK: [does this fit Beautiful/Calm/Tense? Does the Monarch remain non-combatant? Does it require a new verb?]
```

---

## Designing a New Enemy Type

```
ENEMY NAME:
GREED CLASS: [Base / Armored / Floater / Breeder / Crownstealer equivalent]
APPEARANCE: [how is the Greed's nature expressed visually in this setting?]
PRIMARY BEHAVIOUR: [what does it target first — coins, tools, walls, subjects, crown?]
SPECIAL ABILITY: [one unique threat mechanic]
BRIBEABLE? [Yes / No — Base and Armored Greed can be bribed; Floaters, Breeders, Crownstealers cannot]
COUNTER: [what building or unit type counters this most effectively?]
DISCOVERY MOMENT: [how does the player encounter this for the first time? what teaches them its ability?]
NIGHT-ONLY OR BLOOD MOON SPECIFIC?
DOES IT IGNORE WALLS? [this is the key differentiator — wall-ignoring enemies force tower upgrades, wall-respecting enemies drive wall upgrades]
```

---

## Designing a New Mount

```
MOUNT NAME:
SETTING JUSTIFICATION: [why does this animal/vehicle exist in this biome?]
ISLAND AVAILABILITY: [which island is it found on? cost in gems + coins?]
SPRINT DURATION: [how does stamina compare to baseline horse?]
GRAZE MECHANIC: [can it graze? where? does it work in winter?]
SPECIAL ABILITY: [one active ability accessible via the sprint button / hold direction]
FOREST SPEED MODIFIER: [faster or slower in dense trees?]
FIELD SPEED MODIFIER:
STRATEGIC NICHE: [what situation is this mount best in? exploration, portal assault, defense, income generation?]
WEAKNESS: [what situation is this mount bad in?]
TIER: [S/A/B/C/F — based on general utility]
```

---

## Aesthetic & Tonal Boundaries

### What Kingdom Avoids (By Design)
These elements would break the series' identity even if mechanically possible:

- Direct combat by the Monarch — removes helplessness-adjacent tension
- Dialogue, speech bubbles, or text in the world — kills the mystery
- Named antagonists with personality — Greed must remain impersonal
- UI inventory menus — breaks input minimalism
- Player-selected skill trees or class choices — removes the organic emergence of the coin economy
- Fast travel without cost — coin-gated movement informs all strategic decisions
- Explicit lore dumps or codex entries — the mystery is the product, not a puzzle to be solved
- Enemies that appear during daytime in normal gameplay — daytime calm is the emotional pivot
- Tutorial pop-ups or guided quests — learning happens through consequence

### What Kingdom Welcomes
- New biome aesthetics that preserve the semantic slot structure
- New mount abilities that create strategic trade-offs
- New enemy types that drive different defensive strategies (wall vs. tower investment)
- New building types that compete with existing coin sinks
- Seasonal variations that create new risk environments without fundamentally changing the loop
- New hermit types that unlock one specific, unusual building
- Lore implications that deepen the Greed's mystery without explaining it

---

## Per-Game Tonal Reference

| Game | Primary Emotion | Visual Reference | Audio Reference |
|---|---|---|---|
| Kingdom Classic | Loneliness, discovery | Medieval fairy tale illustration, autumn palette | Sparse acoustic, ambient silence |
| Kingdom: New Lands | Dread accumulation, isolation | Same but grander; winter as final boss aesthetically | Folk with building tension, Gordon McGladdery acoustic guitar |
| Kingdom Two Crowns | Agency, escalation, co-operative ownership | Grander, more varied (per biome); richer scroll depth | Jim Guthrie-led ambient folk; biome-specific composers |
| Kingdom Eighties | Nostalgia, childhood horror, summer-that-turned-wrong | VHS neon, suburban pines, 80s palette wash | Full synthwave, John Carpenter DNA, Andreas Hald OST |

### Eighties Specifically
Eighties earns its tonal departure because 80s suburban horror is *structurally identical* to the core Kingdom loop: childhood = the calm, the monster from the woods = the Greed, protecting home = building walls. The aesthetic is totally different; the emotional architecture is unchanged. Any new spinoff setting should pass the same test — different surface, same heartbeat.

---

## Related Notes
- [[Kingdom - Systems & Mechanics Reference]]
