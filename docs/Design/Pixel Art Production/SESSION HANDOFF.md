---
title: SESSION HANDOFF — Pixel Art Sprint
aliases: [Handoff, Continue Here, Resume]
tags:
  - guardian-rising
  - pixel-art
  - handoff
created: 2026-07-06
---

# 🔴 SESSION HANDOFF — read this to resume on PC
← [[00 - Production Guide]] ← [[Character Review]] ← [[Asset Manifest]]

> **You (Ellis) are switching Mac → PC mid-sprint.** This note is the full state so Claude Code on the PC can pick up exactly where we left off. Everything below is synced via the iCloud vault.

---

## ⏸️ THE PENDING DECISION (answer this first)

**Commit fully to the high-fidelity PRO art style?** You saw the Pro-mode enemies (Goblin/Dreg/Legionary), loved them, and want to pivot the *whole* game to that look (anchored on the **original detailed Speaker**, not the flat Kingdom v2).

- **If YES (recommended):** (1) finish enemy roster in Pro, (2) re-anchor player on the detailed Speaker `669cdd6d`, regenerate rider/sparrow/frame/skins in hi-fi, (3) write scale into `sprite_loader.gd` `SIZES` + add a Camera2D.
- **If keep-mixed:** enemies hi-fi, player stays flat (not recommended — inconsistent).

**Scale question answered:** NOT a hard rewrite. `Game/scripts/utils/sprite_loader.gd` already has a `SIZES` tier table (small/standard/elite/heavy/floater). Changing scale = bump those constants + tune camera zoom once + adjust a few collision/speed/spawn values. Game is mostly placeholder `ColorRect`s now, so zero sunk cost.

---

## 🔌 Reconnect PixelLab on PC (do this first)

MCP was added on the Mac (local config). On PC, re-add it:

```
claude mcp add pixellab https://api.pixellab.ai/mcp -t http -H "Authorization: Bearer $PIXELLAB_TOKEN"
```

Set `PIXELLAB_TOKEN` in your shell env — the real token is kept out of this repo. Then restart Claude Code. Account: **Tier 1 (Pixel Apprentice), ~2000 generations.**

---

## ✅ Approved & shipped (in `Game/assets/sprites/`)

| Asset | Location | Style | Keep? |
|---|---|---|---|
| **Pro Goblin** | `enemies/vex/goblin_right/left.png` | hi-fi Pro | ✅ |
| **Pro Dreg** | `enemies/fallen/dreg_right/left.png` | hi-fi Pro | ✅ |
| **Pro Legionary** | `enemies/cabal/legionary_right/left.png` | hi-fi Pro | ✅ |
| **Ghost** (yours + arc-blue eye) | `player/ghost_right/left.png` + `ghost_16.png` | fits hi-fi | ✅ KEEP |
| Speaker on Sparrow + 6 skins | `player/speaker_on_sparrow*.png`, `player/skins/` | flat | ⚠️ redo in hi-fi if full commit |
| Frame base chassis | (in `_review/`) | flat | ⚠️ redo if full commit |

---

## 🎨 Style + conventions (locked)

- **Direction:** LEFT/RIGHT only. Generate east/right, mirror for left. No N/S.
- **Review previews:** embed 5× upscaled (`_5x.png`) in [[Character Review]] — native is too small to see.
- **Palette:** from `Game/scripts/autoload/design_tokens.gd` (voidblack #0a0a0f, cream #e8e0d0, glimmer #f0d060, solar #ff6b00, void #7b00ff, arc #00c0ff, faction colors).
- **Scale tiers:** `sprite_loader.gd` SIZES — small 24×48, standard 32×64, elite 40×80, heavy 56×96, floater 48×48.
- **Mode:** PIVOTING to **Pro mode** for quality (was flat/standard). Pro = 20 gens, 8-dir, ignores style params. We only use east+mirror.

---

## 🔑 PixelLab IDs (for get_character / get_object on PC)

**Anchors:**
- Original detailed Speaker (NEW hi-fi anchor): `669cdd6d-a34e-4ff7-a8e2-3f2f90a4f3b7`
- Kingdom flat Speaker v2 (old anchor): `b67b324d-595d-46ac-9665-f6e2fe73ab5b`

**Approved Pro enemies:**
- Vex Goblin PRO: `0fb7b679-9d81-476a-84f8-fd034ae1548a`
- Fallen Dreg PRO: `74f64dca-dbe6-4df5-b3e5-ddd2e9fc8e87`
- Cabal Legionary PRO: `8c8a1b4e-a088-46e4-8a8c-0c87d951bda3`

**Player-side (flat — redo if committing):**
- Frame base chassis: `56220775-8a3c-43a0-bcb1-8129b759ef04`
- Frame states: defender `4fa7f3c1-b07f-40ae-b34d-5937d08eed19`, builder `45f767d6-1103-4ee1-a1d2-07bbd59222b1`, sweeper `88ed590f-5323-4098-94f2-d2d5e575739c`
- Ghost (yours): object `45b6e641-93b1-41ba-9744-64f803f8ba5e`
- 16 Sparrow variants: `list_objects` filter tag `Sparrow`

**To delete (mediocre standard-mode Vex, replaced by Pro):**
- `ab285a8a-4e8c-425c-b5e9-669214ded03b` (goblin), `c1e31a19-db9c-48f8-add1-72ee3ec2ab2a` (hobgoblin), `34da265f-b87e-4dfd-9e89-bc75c29dcaeb` (minotaur)

---

## ▶️ NEXT STEPS (in order)

1. **Answer the pending decision** (full hi-fi commit?).
2. **Finish enemy roster in Pro:** Vex Hobgoblin, Minotaur, Harpy, Hydra · Fallen Servitor · Cabal Colossus · Hive Wizard. *(Then design-doc extras.)*
3. If committing: **re-anchor player on `669cdd6d`**, regenerate rider/sparrow/frame/skins in hi-fi (skin recolor pipeline in `_review/` still works).
4. **Set game scale:** update `sprite_loader.gd` SIZES, add Camera2D, tune collision/speed constants.
5. **Structures → Projectiles/FX → Parallax background → UI** (see [[Asset Manifest]]).
6. **Animations LAST:** each sprite → 5-row sheet (idle/walk/attack/hit/death) per `sprite_loader.gd`.

---

## 📁 Key files (all synced in vault)
- [[00 - Production Guide]] — style string, palette, size tiers, conventions
- [[Character Review]] — every asset with 5× previews + verdicts
- [[Asset Manifest]] — full checklist grounded in game scripts
- `_review/` folder — all working PNGs (skins recolor source: `sos_maskfix.png`)
- `Game/assets/sprites/` — shipped finals
- `Game/scripts/utils/sprite_loader.gd` — the scale/animation system

## Related Notes
- [[00 - Production Guide]]
- [[Character Review]]
- [[Asset Manifest]]
