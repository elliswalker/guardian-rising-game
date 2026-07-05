"""Regenerate ALL character sprites in the unified placeholder style
(transparent RGBA, chunky silhouettes, faction shape language + accent glow).

Overwrites the preexisting RGB sprites at the SAME paths and dimensions,
so no scene changes are needed. Run from Game/:
    python tools/gen_character_sprites.py
"""

import os
from PIL import Image
from sprite_style import finish

ROOT = os.path.join(os.path.dirname(__file__), "..", "assets", "sprites")

# ── faction palettes ──────────────────────────────────────────────────────────
FALLEN_ARMOR = (108, 62, 40, 255)     # rust
FALLEN_DARK  = (70, 40, 28, 255)
FALLEN_CLOTH = (52, 60, 70, 255)      # house drab
FALLEN_GLOW  = (120, 200, 255, 255)   # pale arc-blue eyes
HIVE_BONE    = (168, 170, 150, 255)
HIVE_DARK    = (60, 66, 52, 255)
HIVE_FLESH   = (92, 100, 78, 255)
HIVE_GLOW    = (120, 235, 130, 255)   # sickly green
VEX_BRASS    = (150, 118, 62, 255)
VEX_DARK     = (92, 72, 40, 255)
VEX_CORE     = (235, 235, 225, 255)   # radiolarian white
VEX_GLOW     = (255, 70, 40, 255)     # single red eye
CABAL_ARMOR  = (95, 55, 55, 255)      # dark red plate
CABAL_DARK   = (55, 35, 38, 255)
CABAL_SUIT   = (68, 74, 86, 255)      # gunmetal pressure suit
CABAL_GLOW   = (255, 190, 90, 255)    # amber visor
GUARD_CLOTH  = (70, 90, 110, 255)
GUARD_ARMOR  = (140, 150, 160, 255)
GUARD_CAPE   = (120, 90, 50, 255)
GUARD_GLOW   = (150, 220, 255, 255)


def canvas(w, h):
    return Image.new("RGBA", (w, h), (0, 0, 0, 0))


def rect(im, x0, y0, x1, y1, c):
    for y in range(max(0, y0), min(im.height, y1 + 1)):
        for x in range(max(0, x0), min(im.width, x1 + 1)):
            im.putpixel((x, y), c)


def px(im, x, y, c):
    if 0 <= x < im.width and 0 <= y < im.height:
        im.putpixel((x, y), c)


def shade(c, f):
    return (max(0, int(c[0] * f)), max(0, int(c[1] * f)), max(0, int(c[2] * f)), 255)


def save(im, *parts):
    finish(im)  # Art Direction rule 2: one light, the sky
    path = os.path.join(ROOT, *parts)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    im.save(path)
    print("wrote", os.path.relpath(path, ROOT), im.size)


# ── archetype: biped ──────────────────────────────────────────────────────────
def biped(w, h, armor, dark, glow, *, hunch=0, arms=2, head_w=None, eye_y=None,
          cloak=False, crest=False, shield=False, broad=False, stride=False):
    """Parameterized humanoid silhouette. Origin: feet at bottom row.
    stride=True poses the legs mid-step for 2-frame walk cycles (#46)."""
    im = canvas(w, h)
    cx = w // 2
    head_w = head_w or max(4, w // 3)
    head_h = max(3, h // 6)
    torso_w = (w - 2) if broad else max(5, w // 2 + 1)
    torso_top = head_h + 1 + hunch
    torso_bot = h - h // 3
    leg_top = torso_bot + 1

    # legs
    lw = max(1, torso_w // 4)
    if stride:
        # lead leg planted a pixel out front, trailing leg lifted toe-down
        rect(im, cx - torso_w // 2, leg_top, cx - torso_w // 2 + lw - 1, h - 2, dark)
        rect(im, cx - torso_w // 2 - 1, h - 1, cx - torso_w // 2 + lw - 1, h - 1, dark)
        rect(im, cx + torso_w // 2 - lw + 1, leg_top, cx + torso_w // 2, h - 3, dark)
        rect(im, cx + torso_w // 2 - lw + 2, h - 2, cx + torso_w // 2 + 1, h - 2, dark)
    else:
        rect(im, cx - torso_w // 2 + 1, leg_top, cx - torso_w // 2 + lw, h - 1, dark)
        rect(im, cx + torso_w // 2 - lw, leg_top, cx + torso_w // 2 - 1, h - 1, dark)
    # torso
    rect(im, cx - torso_w // 2, torso_top, cx + torso_w // 2 - 1, torso_bot, armor)
    rect(im, cx - torso_w // 2, torso_top, cx - torso_w // 2, torso_bot, shade(armor, 1.25))
    rect(im, cx + torso_w // 2 - 1, torso_top, cx + torso_w // 2 - 1, torso_bot, shade(armor, 0.7))
    # cloak drape behind torso
    if cloak:
        rect(im, cx - torso_w // 2 - 1, torso_top + 1, cx - torso_w // 2 - 1, h - 3, dark)
    # head
    hy = hunch
    rect(im, cx - head_w // 2, hy, cx + head_w // 2 - 1, hy + head_h, dark)
    if crest:
        rect(im, cx - 1, 0, cx, hy, shade(armor, 1.2))
    # eyes
    ey = eye_y if eye_y is not None else hy + head_h // 2
    px(im, cx - 1, ey, glow)
    px(im, cx + 1, ey, glow)
    # arms — pairs stacked down the torso (Fallen get 4)
    for i in range(arms // 2):
        ay = torso_top + 1 + i * max(2, (torso_bot - torso_top) // 2)
        rect(im, cx - torso_w // 2 - 1, ay, cx - torso_w // 2 - 1, ay + 2, shade(armor, 0.85))
        rect(im, cx + torso_w // 2, ay, cx + torso_w // 2, ay + 2, shade(armor, 0.85))
    # tower shield slab (phalanx)
    if shield:
        rect(im, 0, 2, 1, h - 1, shade(armor, 1.15))
        rect(im, 0, 2, 0, h - 1, shade(armor, 0.8))
    return im


def floater(w, h, body, dark, glow, *, eye_r=1, fins=False):
    """Round floating machine (servitor / harpy / hydra plates)."""
    im = canvas(w, h)
    cx, cy = w // 2, h // 2
    r = min(w, h) // 2 - 1
    for y in range(h):
        for x in range(w):
            d2 = (x - cx) ** 2 + (y - cy) ** 2
            if d2 <= r * r:
                f = 1.15 if (x - cx) - (y - cy) < -r // 2 else (0.75 if (x - cx) - (y - cy) > r // 2 else 1.0)
                im.putpixel((x, y), shade(body, f))
    # panel seams
    for x in range(cx - r, cx + r + 1, max(2, r // 2)):
        for y in range(cy - r, cy + r + 1):
            if (x - cx) ** 2 + (y - cy) ** 2 <= r * r:
                im.putpixel((x, y), shade(body, 0.85))
    # eye
    rect(im, cx - eye_r, cy - eye_r, cx + eye_r, cy + eye_r, dark)
    px(im, cx, cy, glow)
    if fins:
        rect(im, 0, cy - 1, 1, cy + 1, dark)
        rect(im, w - 2, cy - 1, w - 1, cy + 1, dark)
    return im


# ── player roster ─────────────────────────────────────────────────────────────
def gen_player():
    # hunter — hand-drawn detail pass (#43): hooded scout, layered cloak,
    # chest rig, knife belt. Silhouette unchanged from the biped original.
    im = canvas(18, 26)
    C1 = GUARD_CLOTH
    C2 = shade(GUARD_CLOTH, 0.62)          # cloth shade
    C3 = shade(GUARD_CLOTH, 1.3)           # cloth lit
    CAPE = GUARD_CAPE
    CAPE_D = shade(GUARD_CAPE, 0.65)
    # hood — peaked, overhanging the visor
    rect(im, 6, 0, 11, 5, C2)
    rect(im, 6, 0, 11, 0, C3)
    rect(im, 5, 2, 5, 5, C2)               # hood lip
    rect(im, 7, 3, 10, 4, (24, 30, 38, 255))  # face shadow
    px(im, 8, 3, GUARD_GLOW)               # visor glint
    px(im, 9, 3, GUARD_GLOW)
    # cloak — draped off the left shoulder, ragged hem, two-tone folds
    rect(im, 3, 6, 7, 19, CAPE)
    rect(im, 3, 6, 3, 19, shade(GUARD_CAPE, 1.2))
    rect(im, 5, 8, 5, 18, CAPE_D)          # fold line
    for hx, hy in [(3, 20), (5, 21), (7, 20)]:
        px(im, hx, hy, CAPE_D)             # ragged hem
    # torso — chest rig over cloth
    rect(im, 7, 6, 13, 14, C1)
    rect(im, 13, 6, 13, 14, C2)
    rect(im, 8, 7, 12, 7, C3)              # collar light
    rect(im, 9, 8, 9, 13, (40, 48, 58, 255))   # rig strap
    rect(im, 11, 10, 12, 11, (40, 48, 58, 255))  # chest pouch
    px(im, 11, 10, C3)
    # belt + knife
    rect(im, 7, 15, 13, 15, (30, 36, 44, 255))
    px(im, 12, 16, (180, 188, 200, 255))   # knife hilt
    # legs — wrapped boots
    rect(im, 8, 16, 9, 24, C2)
    rect(im, 11, 16, 12, 24, C2)
    rect(im, 8, 21, 9, 21, (30, 36, 44, 255))   # boot wrap
    rect(im, 11, 21, 12, 21, (30, 36, 44, 255))
    rect(im, 8, 25, 9, 25, (26, 30, 36, 255))
    rect(im, 11, 25, 12, 25, (26, 30, 36, 255))
    # right arm
    rect(im, 14, 8, 15, 14, C2)
    px(im, 14, 8, C3)
    save(im, "player", "hunter.png")

    # speaker — white mask, long robes
    im = biped(28, 28, (200, 198, 190, 255), (90, 88, 84, 255), (255, 200, 120, 255), broad=False)
    rect(im, 11, 1, 16, 6, (235, 233, 228, 255))  # white mask
    px(im, 12, 3, (40, 40, 40, 255))
    px(im, 15, 3, (40, 40, 40, 255))
    rect(im, 9, 14, 18, 27, (140, 60, 50, 255))   # red robe skirt
    save(im, "player", "speaker.png")

    im = biped(22, 34, GUARD_ARMOR, shade(GUARD_ARMOR, 0.55), (255, 150, 80, 255), broad=True)
    save(im, "player", "titan.png")

    im = biped(24, 28, (90, 70, 120, 255), (50, 40, 70, 255), (200, 160, 255, 255), cloak=True)
    save(im, "player", "warlock.png")

    # ghost — detail pass (#43): angular shell points floating off a dark
    # core seam, single cyan eye. Reads as THE Ghost at 16px.
    im = canvas(16, 16)
    SH  = (228, 232, 240, 255)   # shell lit
    SH2 = (196, 202, 214, 255)   # shell mid
    SH3 = (150, 158, 172, 255)   # shell shadow
    # core cube behind the gap
    rect(im, 6, 6, 9, 9, (52, 60, 72, 255))
    px(im, 7, 7, GUARD_GLOW)     # the eye
    px(im, 8, 7, GUARD_GLOW)
    px(im, 7, 8, (90, 160, 200, 255))
    px(im, 8, 8, (90, 160, 200, 255))
    # top shell point
    rect(im, 7, 1, 8, 1, SH)
    rect(im, 6, 2, 9, 3, SH)
    rect(im, 6, 4, 9, 4, SH2)
    # bottom shell point
    rect(im, 6, 11, 9, 11, SH2)
    rect(im, 6, 12, 9, 13, SH3)
    rect(im, 7, 14, 8, 14, SH3)
    # side shell points (slightly separated — the shell floats)
    for sx, lit in ((1, True), (12, False)):
        c_main = SH if lit else SH2
        rect(im, sx + 1, 7, sx + 3, 8, c_main)
        rect(im, sx, 6, sx + 2, 6, SH2 if lit else SH3)
        rect(im, sx, 9, sx + 2, 9, SH3)
    # corner ticks — the diamond shell corners
    for dx, dy, c_t in [(3, 3, SH), (11, 3, SH2), (3, 11, SH3), (11, 11, SH3)]:
        px(im, dx, dy, c_t)
        px(im, dx + 1, dy + 1, c_t)
    save(im, "player", "ghost.png")


# ── fallen ────────────────────────────────────────────────────────────────────
def gen_fallen():
    # dreg — detail pass (#43): hunched scavver, ether mask, docked lower
    # arms (the dreg shame), backward-bent shins. Same 12x20 canvas.
    im = canvas(12, 20)
    A1 = FALLEN_ARMOR
    A2 = shade(FALLEN_ARMOR, 0.68)
    A3 = shade(FALLEN_ARMOR, 1.28)
    CL = FALLEN_CLOTH
    # head — low, thrust forward, ether mask
    rect(im, 3, 2, 8, 5, FALLEN_DARK)
    rect(im, 3, 2, 8, 2, shade(FALLEN_DARK, 1.3))
    rect(im, 2, 4, 3, 5, FALLEN_DARK)          # snout/mask
    px(im, 4, 3, FALLEN_GLOW)                  # two ether eyes
    px(im, 6, 3, FALLEN_GLOW)
    px(im, 2, 5, (200, 220, 235, 200))         # ether vent wisp
    # hunched torso — patched armor over rags
    rect(im, 3, 6, 9, 12, A1)
    rect(im, 3, 6, 3, 12, A3)
    rect(im, 9, 6, 9, 12, A2)
    rect(im, 4, 7, 8, 7, A3)                   # shoulder plate light
    rect(im, 5, 9, 7, 10, CL)                  # rag wrap
    px(im, 6, 11, A2)                          # belt scrap
    # upper arms — long, knuckling forward
    rect(im, 1, 7, 2, 12, A2)
    rect(im, 10, 7, 11, 12, A2)
    px(im, 1, 12, FALLEN_DARK)                 # claw
    px(im, 11, 12, FALLEN_DARK)
    # docked lower-arm nubs
    px(im, 2, 13, FALLEN_DARK)
    px(im, 9, 13, FALLEN_DARK)
    base = im
    # standing pose — backward-bent legs
    im = base.copy()
    rect(im, 3, 13, 4, 16, A2)
    rect(im, 7, 13, 8, 16, A2)
    rect(im, 2, 17, 3, 19, FALLEN_DARK)        # shin kicks back
    rect(im, 8, 17, 9, 19, FALLEN_DARK)
    save(im, "enemies", "fallen", "dreg.png")
    # stride pose (#46) — scuttling step
    im = base.copy()
    rect(im, 2, 13, 3, 16, A2)                 # lead thigh forward
    rect(im, 1, 17, 2, 19, FALLEN_DARK)        # lead shin planted ahead
    rect(im, 8, 13, 9, 15, A2)                 # trailing thigh lifted
    rect(im, 9, 16, 10, 18, FALLEN_DARK)       # trailing shin toe-down
    save(im, "enemies", "fallen", "dreg_walk.png")

    im = biped(18, 26, FALLEN_CLOTH, FALLEN_DARK, FALLEN_GLOW, arms=4, cloak=True)
    rect(im, 5, 4, 12, 5, FALLEN_ARMOR)  # armored collar
    save(im, "enemies", "fallen", "vandal.png")

    im = biped(22, 34, FALLEN_ARMOR, FALLEN_DARK, FALLEN_GLOW, arms=4, cloak=True, crest=True, broad=True)
    save(im, "enemies", "fallen", "captain.png")

    # shank — hovering gun drone
    im = canvas(18, 14)
    rect(im, 4, 4, 13, 9, FALLEN_ARMOR)
    rect(im, 4, 4, 13, 4, shade(FALLEN_ARMOR, 1.25))
    rect(im, 0, 5, 3, 7, FALLEN_DARK)   # side thruster
    rect(im, 14, 5, 17, 7, FALLEN_DARK)
    rect(im, 7, 10, 10, 11, FALLEN_DARK)  # under-gun
    px(im, 8, 6, FALLEN_GLOW)
    px(im, 9, 6, FALLEN_GLOW)
    save(im, "enemies", "fallen", "shank.png")

    im = floater(28, 28, (120, 100, 130, 255), (50, 40, 60, 255), FALLEN_GLOW, eye_r=2)
    save(im, "enemies", "fallen", "servitor.png")


# ── hive ──────────────────────────────────────────────────────────────────────
def gen_hive():
    im = biped(12, 16, HIVE_BONE, HIVE_DARK, HIVE_GLOW, hunch=2)
    save(im, "enemies", "hive", "thrall.png")
    im = biped(12, 16, HIVE_BONE, HIVE_DARK, HIVE_GLOW, hunch=2, stride=True)
    save(im, "enemies", "hive", "thrall_walk.png")

    im = biped(12, 16, HIVE_FLESH, HIVE_DARK, HIVE_GLOW, hunch=2)
    rect(im, 4, 8, 7, 11, HIVE_GLOW)  # glowing volatile belly
    save(im, "enemies", "hive", "cursed_thrall.png")

    im = biped(16, 24, HIVE_FLESH, HIVE_DARK, HIVE_GLOW, cloak=True)
    save(im, "enemies", "hive", "acolyte.png")

    im = biped(22, 34, HIVE_BONE, HIVE_DARK, HIVE_GLOW, broad=True, crest=True)
    save(im, "enemies", "hive", "knight.png")

    # wizard — floating ragged robe, no legs
    im = canvas(18, 30)
    rect(im, 5, 0, 12, 5, HIVE_DARK)          # cowled head
    px(im, 7, 2, HIVE_GLOW)
    px(im, 10, 2, HIVE_GLOW)
    rect(im, 4, 6, 13, 18, HIVE_FLESH)        # torso robe
    rect(im, 4, 6, 4, 18, shade(HIVE_FLESH, 1.25))
    for i, xx in enumerate([4, 7, 10, 13]):   # tattered robe strips
        rect(im, xx, 19, xx + 1, 26 + (i % 2) * 2, HIVE_DARK)
    save(im, "enemies", "hive", "wizard.png")


# ── vex ───────────────────────────────────────────────────────────────────────
def gen_vex():
    def vex_biped(w, h, **kw):
        im = biped(w, h, VEX_BRASS, VEX_DARK, VEX_GLOW, **kw)
        # radiolarian core in the belly
        cx = w // 2
        rect(im, cx - 1, h // 2, cx, h // 2 + 1, VEX_CORE)
        return im

    save(vex_biped(14, 22), "enemies", "vex", "goblin.png")
    save(vex_biped(16, 26, cloak=True), "enemies", "vex", "hobgoblin.png")
    save(vex_biped(24, 32, broad=True, crest=True), "enemies", "vex", "minotaur.png")

    im = floater(16, 14, VEX_BRASS, VEX_DARK, VEX_GLOW, fins=True)
    save(im, "enemies", "vex", "harpy.png")

    # hydra — wide plated float
    im = canvas(30, 28)
    rect(im, 3, 8, 26, 19, VEX_BRASS)
    rect(im, 3, 8, 26, 9, shade(VEX_BRASS, 1.25))
    rect(im, 3, 18, 26, 19, shade(VEX_BRASS, 0.7))
    rect(im, 0, 10, 2, 17, VEX_DARK)    # rotating side plates
    rect(im, 27, 10, 29, 17, VEX_DARK)
    rect(im, 12, 2, 17, 7, VEX_DARK)    # head dome
    rect(im, 13, 12, 16, 15, VEX_DARK)
    px(im, 14, 13, VEX_GLOW)
    px(im, 15, 13, VEX_GLOW)
    save(im, "enemies", "vex", "hydra.png")


# ── cabal ─────────────────────────────────────────────────────────────────────
def gen_cabal():
    im = biped(18, 28, CABAL_ARMOR, CABAL_DARK, CABAL_GLOW, broad=True)
    rect(im, 4, 10, 13, 11, CABAL_SUIT)  # pressure-suit midsection
    save(im, "enemies", "cabal", "legionary.png")
    im = biped(18, 28, CABAL_ARMOR, CABAL_DARK, CABAL_GLOW, broad=True, stride=True)
    rect(im, 4, 10, 13, 11, CABAL_SUIT)
    save(im, "enemies", "cabal", "legionary_walk.png")

    # colossus — the widest thing on any battlefield, fuel tank + flame arm
    im = biped(28, 34, CABAL_ARMOR, CABAL_DARK, CABAL_GLOW, broad=True, crest=True)
    rect(im, 0, 10, 2, 22, CABAL_SUIT)          # fuel tank on the back
    rect(im, 0, 10, 2, 11, shade(CABAL_SUIT, 1.3))
    rect(im, 24, 14, 27, 17, CABAL_DARK)        # flamethrower arm
    px(im, 27, 15, (255, 120, 30, 255))         # pilot light
    save(im, "enemies", "cabal", "colossus.png")

    im = biped(22, 32, CABAL_ARMOR, CABAL_DARK, CABAL_GLOW, broad=True, crest=True)
    save(im, "enemies", "cabal", "centurion.png")

    im = biped(24, 30, CABAL_ARMOR, CABAL_DARK, CABAL_GLOW, broad=True, shield=True)
    save(im, "enemies", "cabal", "phalanx.png")

    im = biped(12, 22, CABAL_SUIT, CABAL_DARK, (200, 140, 255, 255), hunch=1)
    save(im, "enemies", "cabal", "psion.png")


if __name__ == "__main__":
    gen_player()
    gen_fallen()
    gen_hive()
    gen_vex()
    gen_cabal()
    print("done")
