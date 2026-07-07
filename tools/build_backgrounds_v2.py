"""Backgrounds v2 — ground-up rebuild of every planet's parallax set (#50).

Ellis verdict on v1: "the parallax layers just look terrible." This pass
rebuilds all FOUR planets (Earth included — the opening-plate collage is
retired) on the wide 960px 3-segment pipeline with three fixes the old
sets lacked:

  1. OPAQUE full-height gradient skies — no more flat scene-color bands
     bleeding through between layer bottoms and the ground line.
  2. Horizon FOG — every distance band melts into the sky color near its
     base instead of ending in a hard silhouette edge (the Kingdom look).
  3. Zone palettes from the source material (destinypedia.com/Cosmodrome,
     /Old_Russia): Cosmodrome = burnt-orange steppe under pale overcast;
     Earth = dusk blue with the Traveler over the City wall; Moon = void
     black with soulfire green; Mars = butterscotch dust.

Run from Game/:  python tools/build_backgrounds_v2.py
"""

import math
import os
import random

from PIL import Image

import gen_parallax_backgrounds as gp
import build_planet_backgrounds as bp

SEGMENTS = 3
gp.W = 320 * SEGMENTS
W = gp.W
H = gp.H
OUT = bp.OUT
LAND = bp.LAND


def seg_x(seg, frac):
    return int(320 * seg + 320 * frac)


def save(im, planet, name):
    bp.finish(im, rim=1.12, shade=1.0)
    im.save(os.path.join(OUT, planet, name))
    print("wrote", planet + "/" + name, im.size)


def fog(im, sky_bottom, start_y, max_a):
    """Melt the plate's lower half toward the sky color — atmosphere."""
    px = im.load()
    for y in range(start_y, H):
        t = (y - start_y) / max(1, H - 1 - start_y)
        a = max_a * t
        for x in range(W):
            r, g, b, al = px[x, y]
            if al == 0:
                continue
            f = a / 255.0
            px[x, y] = (round(r + (sky_bottom[0] - r) * f),
                        round(g + (sky_bottom[1] - g) * f),
                        round(b + (sky_bottom[2] - b) * f), al)


def block(im, x, top, w, color, cap=None):
    gp.rect(im, x, top, x + w - 1, H - 1, color)
    if cap:
        gp.rect(im, x - 1, top - 2, x + w, top, cap)


# ── EARTH — Last City outskirts at dusk ──────────────────────────────────────
def earth():
    random.seed(720)
    sky_top, sky_bot = (58, 74, 110), (178, 158, 148)

    # 0: sky + THE TRAVELER + high cloud bands
    im = gp.canvas()
    gp.grad_sky(im, sky_top, sky_bot)
    tx, ty, tr = 250, 52, 30
    for y in range(ty - tr - 4, ty + tr + 5):            # halo
        for x in range(tx - tr - 4, tx + tr + 5):
            d = ((x - tx) ** 2 + (y - ty) ** 2) ** 0.5
            if tr < d <= tr + 4:
                a = int(90 * (1.0 - (d - tr) / 4.0))
                gp.blend_px(im, x, y, (220, 226, 240), a)
    for y in range(ty - tr, ty + tr + 1):                # the sphere
        for x in range(tx - tr, tx + tr + 1):
            d2 = (x - tx) ** 2 + (y - ty) ** 2
            if d2 <= tr * tr:
                lit = (x - tx) - (y - ty) < 2
                v = 236 if lit else 204
                gp.px(im, x, y, (v, v, min(255, v + 10), 255))
    for i in range(14):                                  # collapse scar
        gp.px(im, tx - 10 + i, ty + tr - 6 + (i % 3), (168, 170, 184, 255))
    # broken shard drifting well below the sphere — not a hanging basket
    gp.rect(im, tx - 14, ty + tr + 12, tx - 4, ty + tr + 14, (212, 214, 226, 220))
    gp.rect(im, tx - 11, ty + tr + 15, tx - 7, ty + tr + 16, (188, 192, 206, 170))
    gp.haze_blobs(im, 46, 16, (34, 84), (150, 158, 178), 110)
    gp.haze_blobs(im, 84, 20, (28, 72), (168, 160, 158), 95)
    gp.haze_blobs(im, 112, 12, (22, 54), (192, 176, 160), 75)
    save(im, "earth", "layer_0.png")

    # 1: mountains + the City wall running the far horizon
    im = gp.canvas()
    gp.ridge_ramped(im, 112, 13, [(4, 1.0), (9, 0.5), (17, 0.25)], (96, 106, 128, 255))
    wall = bp.haze(bp.load_scaled("city_wall.png", 62), sky_bot, 0.42)
    wall_s = bp.haze(bp.load_scaled("city_wall.png", 48), sky_bot, 0.50)
    bp.paste_grounded(im, wall, seg_x(1, 0.30), 132)
    bp.paste_grounded(im, wall, seg_x(1, 0.56), 130)     # wall segments read as a line
    bp.paste_grounded(im, wall_s, seg_x(1, 0.80), 128)
    bp.paste_grounded(im, wall_s.transpose(Image.FLIP_LEFT_RIGHT), seg_x(2, 0.72), 126)
    fog(im, sky_bot, 118, 150)
    save(im, "earth", "layer_1.png")

    # 2: ruined suburb skyline — block clusters, gaps between them
    im = gp.canvas()
    gp.ridge_ramped(im, 140, 6, [(5, 1.0), (11, 0.4)], (72, 80, 98, 255))
    c, cap = (70, 78, 96, 255), (84, 92, 110, 255)
    for x, w_b, top in [(30, 10, 112), (52, 7, 124), (95, 13, 104), (150, 8, 120),
                        (365, 14, 108), (395, 9, 122), (430, 11, 116),
                        (600, 8, 126), (705, 12, 110), (735, 8, 118),
                        (870, 10, 114), (935, 7, 124)]:
        block(im, x, top, w_b, c, cap)
        if x % 3 == 0:
            ax = x + w_b // 2
            gp.rect(im, ax, top - 8, ax, top - 2, c)
            gp.px(im, ax, top - 9, (255, 96, 84, 210))
    fog(im, sky_bot, 138, 110)
    save(im, "earth", "layer_2.png")

    # 3: near rubble + dead trees
    im = gp.canvas()
    gp.ridge_ramped(im, 160, 4, [(7, 1.0), (15, 0.5)], (52, 58, 74, 255), rough=1.0)
    for x in [30, 150, 250, 390, 470, 600, 720, 850, 930]:
        hgt = random.randint(14, 22)
        gp.rect(im, x, 158 - hgt, x + 1, 158, (44, 50, 64, 255))
        for dx, dy, ln in [(-1, -hgt + 4, 4), (2, -hgt + 8, 5), (-1, -hgt + 12, 3)]:
            step = -1 if dx < 0 else 1
            for j in range(ln):
                gp.px(im, x + dx + j * step, 158 + dy - j // 2, (44, 50, 64, 255))
    fog(im, sky_bot, 158, 70)
    save(im, "earth", "layer_3.png")

    # 4: nearest band — car graveyard
    im = gp.canvas()
    gp.ridge(im, 172, 3, [(8, 1.0), (17, 0.4)], (30, 34, 46, 255), rough=1.0)
    c, hl = (30, 34, 46, 255), (22, 25, 35, 255)
    for x in [40, 190, 330, 470, 640, 800, 910]:
        gp.rect(im, x, 164, x + 25, 170, c)
        gp.rect(im, x + 5, 160, x + 19, 164, c)
        gp.rect(im, x + 7, 161, x + 11, 163, hl)
        gp.rect(im, x + 14, 161, x + 17, 163, hl)
    for x in [120, 410, 560, 730, 870]:
        for i in range(16):
            gp.px(im, x + i // 5, 170 - i, c)
        gp.rect(im, x - 3, 156, x + 5, 156, c)
    save(im, "earth", "layer_4.png")

    # fg: grass tufts + rubble + car silhouettes riding in front
    im = gp.fg_canvas()
    c = (20, 24, 33, 235)
    gp.fg_rect(im, 0, gp.FG_H - 3, W - 1, gp.FG_H - 1, c)
    for _ in range(78):
        x = random.randint(2, W - 3)
        h = random.randint(4, 9)
        for i in range(h):
            gp.fg_px(im, x + (1 if i > h - 3 else 0), gp.FG_H - 3 - i, c)
        gp.fg_px(im, x - 1, gp.FG_H - 4, c)
    for _ in range(21):
        x = random.randint(4, W - 8)
        gp.fg_rect(im, x, gp.FG_H - 7, x + random.randint(3, 6), gp.FG_H - 3, c)
    for name, x, hgt in [("pro_car_a.png", 60, 16), ("pro_car_b.png", 410, 15),
                         ("pro_car_a.png", 760, 16)]:
        car = Image.open(os.path.join(bp.GAME, "assets", "sprites", "world", name)).convert("RGBA")
        s = hgt / car.height
        car = car.resize((round(car.width * s), hgt), Image.NEAREST)
        car = bp.haze(car, (16, 19, 26), 0.82)
        im.alpha_composite(car, (x, gp.FG_H - 3 - hgt))
    save(im, "earth", "fg_0.png")


# ── COSMODROME — burnt-orange steppes of Old Russia ──────────────────────────
def cosmodrome():
    random.seed(721)
    sky_top, sky_bot = (112, 124, 142), (208, 180, 142)

    im = gp.canvas()
    gp.grad_sky(im, sky_top, sky_bot)
    gp.haze_blobs(im, 42, 18, (36, 88), (176, 178, 188), 115)
    gp.haze_blobs(im, 76, 22, (30, 78), (190, 172, 150), 100)
    gp.haze_blobs(im, 106, 14, (24, 58), (214, 190, 156), 80)
    save(im, "cosmodrome", "layer_0.png")

    # 1: rolling steppe hills — warm dry grass
    im = gp.canvas()
    gp.ridge_ramped(im, 114, 12, [(4, 1.0), (9, 0.5)], (150, 128, 86, 255))
    fog(im, sky_bot, 120, 150)
    save(im, "cosmodrome", "layer_1.png")

    # 2: the launch yards — colony ship, gantries, pipe runs on burnt grass
    im = gp.canvas()
    gp.ridge_ramped(im, 144, 5, [(5, 1.0), (10, 0.4)], (122, 100, 66, 255))
    ship = bp.haze(bp.load_scaled("cosmodrome_ship.png", 78), sky_bot, 0.32)
    gantry = bp.haze(bp.load_scaled("cosmodrome_gantry.png", 88), sky_bot, 0.38)
    gantry_s = bp.haze(bp.load_scaled("cosmodrome_gantry.png", 64), sky_bot, 0.44)
    bp.paste_grounded(im, ship, seg_x(0, 0.35), 156)
    bp.paste_grounded(im, gantry_s, seg_x(0, 0.06), 154)
    bp.paste_grounded(im, gantry, seg_x(1, 0.20), 154)
    bp.paste_grounded(im, gantry.transpose(Image.FLIP_LEFT_RIGHT), seg_x(1, 0.62), 155)
    stern = ship.transpose(Image.FLIP_LEFT_RIGHT).crop((0, 0, ship.width // 2, ship.height))
    bp.paste_grounded(im, stern, seg_x(2, 0.55), 164)
    bp.paste_grounded(im, gantry_s.transpose(Image.FLIP_LEFT_RIGHT), seg_x(2, 0.15), 154)
    for x0 in [seg_x(0, 0.7), seg_x(2, 0.05)]:            # rusted pipe runs
        gp.rect(im, x0, 138, x0 + 60, 140, (104, 78, 56, 255))
        for px_ in range(x0, x0 + 60, 12):
            gp.rect(im, px_, 140, px_ + 1, 146, (96, 72, 52, 255))
    fog(im, sky_bot, 140, 105)
    save(im, "cosmodrome", "layer_2.png")

    # 3: near bench — fence posts + debris in dead grass
    im = gp.canvas()
    gp.ridge_ramped(im, 162, 3, [(7, 1.0), (16, 0.4)], (88, 72, 48, 255), rough=1.0)
    for _ in range(15):
        x = random.randint(6, W - 7)
        gp.rect(im, x, 150, x, 161, (72, 58, 40, 255))
        gp.px(im, x, 150, (96, 78, 54, 255))
    fog(im, sky_bot, 160, 60)
    save(im, "cosmodrome", "layer_3.png")

    # 4: containers / cable spools / leaning poles — rust-dark
    im = gp.canvas()
    gp.ridge(im, 172, 3, [(8, 1.0), (19, 0.4)], (52, 44, 36, 255), rough=1.0)
    c, hl = (52, 44, 36, 255), (40, 33, 27, 255)
    for x, two_high in [(30, True), (250, False), (430, True), (585, False),
                        (660, True), (905, False)]:
        gp.rect(im, x, 160, x + 34, 171, c)
        for gx in range(x + 3, x + 34, 5):
            gp.rect(im, gx, 161, gx, 170, hl)
        if two_high:
            gp.rect(im, x + 6, 149, x + 28, 159, c)
            for gx in range(x + 9, x + 28, 5):
                gp.rect(im, gx, 150, gx, 158, hl)
    for x in [140, 350, 530, 775, 940]:
        for dy in range(-5, 6):
            half = int((25 - dy * dy) ** 0.5 * 0.55)
            gp.rect(im, x - half, 166 + dy, x + half, 166 + dy, c)
        gp.rect(im, x, 162, x, 170, hl)
    for x in [95, 205, 480, 720, 855]:
        for i in range(18):
            gp.px(im, x + i // 6, 170 - i, c)
        gp.rect(im, x - 3, 154, x + 6, 154, c)
    save(im, "cosmodrome", "layer_4.png")

    im = gp.fg_canvas()
    c = (28, 23, 20, 235)
    gp.fg_rect(im, 0, gp.FG_H - 3, W - 1, gp.FG_H - 1, c)
    for _ in range(27):
        x = random.randint(4, W - 12)
        w_p = random.randint(5, 10)
        for i in range(w_p):
            gp.fg_rect(im, x + i, gp.FG_H - 4 - i // 2, x + i, gp.FG_H - 3, c)
    for _ in range(54):
        x = random.randint(2, W - 3)
        h = random.randint(3, 7)
        for i in range(h):
            gp.fg_px(im, x, gp.FG_H - 3 - i, c)
    save(im, "cosmodrome", "fg_0.png")


# ── MOON — the Hellmouth dark ────────────────────────────────────────────────
def moon():
    random.seed(722)
    sky_top, sky_bot = (4, 4, 10), (20, 22, 36)

    im = gp.canvas()
    gp.grad_sky(im, sky_top, sky_bot)
    for _ in range(520):
        x = random.randint(0, W - 1)
        y = random.randint(28, 92)
        if random.random() < 0.5:
            gp.px(im, x, y, (32, 32, 50, 255))
    gp.stars(im, 500, [(222, 226, 236, 255), (172, 180, 202, 200), (140, 200, 160, 150)])
    save(im, "moon", "layer_0.png")

    # 1: far rim + the Hellmouth dome breathing green
    im = gp.canvas()
    gp.ridge_ramped(im, 114, 13, [(4, 1.0), (11, 0.4)], (54, 56, 74, 255))
    hx, hw = seg_x(1, 0.5), 120
    for i in range(hw):                                  # low dark dome
        y_top = 108 - int(26 * math.sin(i / hw * math.pi))
        gp.rect(im, hx - hw // 2 + i, y_top, hx - hw // 2 + i, H - 1, (40, 42, 58, 255))
    for gx_, gy in [(hx - 30, 96), (hx + 4, 88), (hx + 34, 98)]:  # soulfire vents
        gp.px(im, gx_, gy, (110, 235, 130, 200))
        gp.px(im, gx_, gy - 1, (70, 150, 90, 130))
    fog(im, sky_bot, 122, 130)
    save(im, "moon", "layer_1.png")

    # 2: bone spires + crater bowls
    im = gp.canvas()
    gp.ridge_ramped(im, 146, 5, [(5, 1.0), (14, 0.4)], (44, 46, 62, 255))

    def spire(hgt, flip=False):
        sp = bp.load_scaled("moon_spire.png", hgt)
        if flip:
            sp = sp.transpose(Image.FLIP_LEFT_RIGHT)
        return bp.haze(sp, sky_bot, 0.20)

    bp.paste_grounded(im, spire(88), seg_x(0, 0.12), 158)
    bp.paste_grounded(im, spire(58, True), seg_x(0, 0.44), 156)
    bp.paste_grounded(im, spire(74), seg_x(0, 0.70), 158)
    bp.paste_grounded(im, spire(102, True), seg_x(1, 0.16), 160)
    bp.paste_grounded(im, spire(50), seg_x(2, 0.22), 156)
    bp.paste_grounded(im, spire(82, True), seg_x(2, 0.58), 158)
    for cx_ in [seg_x(1, 0.78), seg_x(2, 0.88)]:          # crater rims
        for i in range(44):
            y_top = 150 - int(7 * math.sin(i / 44 * math.pi))
            gp.px(im, cx_ - 22 + i, y_top, (56, 58, 76, 255))
            gp.rect(im, cx_ - 22 + i, y_top + 1, cx_ - 22 + i, 152, (38, 40, 54, 255))
    fog(im, sky_bot, 142, 95)
    save(im, "moon", "layer_2.png")

    # 3: near regolith
    im = gp.canvas()
    gp.ridge_ramped(im, 162, 3, [(7, 1.0), (16, 0.5)], (34, 36, 48, 255), rough=1.0)
    for _ in range(12):
        x = random.randint(4, W - 10)
        gp.rect(im, x, 156, x + 6, 162, (28, 30, 42, 255))
        gp.px(im, x + 1, 155, (42, 44, 58, 255))
    fog(im, sky_bot, 160, 55)
    save(im, "moon", "layer_3.png")

    # 4: rib arcs + monolith slabs
    im = gp.canvas()
    gp.ridge(im, 172, 3, [(7, 1.0), (15, 0.5)], (24, 26, 36, 255), rough=1.0)
    c = (24, 26, 36, 255)
    for x, hgt, bend in [(45, 42, 9), (190, 30, 7), (330, 48, 11), (455, 36, 8),
                         (600, 44, 10), (700, 28, 6), (860, 50, 12)]:
        for i in range(hgt):
            xo = int(bend * (i / hgt) ** 2)
            gp.rect(im, x + xo, 171 - i, x + xo + 2, 171 - i, c)
        gp.px(im, x + bend, 171 - hgt - 1, (110, 220, 125, 120))
    for x, w_s, top in [(140, 9, 148), (390, 6, 154), (540, 8, 150), (935, 7, 152)]:
        gp.rect(im, x, top, x + w_s, 171, c)
        gp.rect(im, x + 2, top - 3, x + w_s - 2, top, c)
    save(im, "moon", "layer_4.png")

    im = gp.fg_canvas()
    c = (14, 15, 23, 235)
    gp.fg_rect(im, 0, gp.FG_H - 3, W - 1, gp.FG_H - 1, c)
    for _ in range(42):
        x = random.randint(3, W - 9)
        w_r = random.randint(3, 7)
        h_r = max(2, w_r - 2)
        gp.fg_rect(im, x, gp.FG_H - 3 - h_r, x + w_r, gp.FG_H - 3, c)
    for _ in range(24):
        x = random.randint(2, W - 4)
        h = random.randint(5, 10)
        for i in range(h):
            gp.fg_px(im, x + i // 4, gp.FG_H - 3 - i, c)
    save(im, "moon", "fg_0.png")


# ── MARS — Meridian Bay butterscotch ─────────────────────────────────────────
def mars():
    random.seed(723)
    sky_top, sky_bot = (150, 88, 52), (226, 176, 126)

    im = gp.canvas()
    gp.grad_sky(im, sky_top, sky_bot)
    gp.haze_blobs(im, 48, 21, (36, 92), (188, 132, 92, 255)[:3], 110)
    gp.haze_blobs(im, 82, 26, (30, 80), (172, 118, 84), 95)
    gp.haze_blobs(im, 112, 16, (24, 60), (222, 172, 126), 80)
    save(im, "mars", "layer_0.png")

    # 1: dune ridge + mesas
    im = gp.canvas()
    gp.ridge_ramped(im, 112, 11, [(4, 1.0), (8, 0.5)], (172, 116, 74, 255))
    mesa = bp.haze(bp.load_scaled("mars_mesa.png", 70), sky_bot, 0.40)
    mesa_s = bp.haze(bp.load_scaled("mars_mesa.png", 52), sky_bot, 0.48)
    bp.paste_grounded(im, mesa, seg_x(0, 0.16), 128)
    bp.paste_grounded(im, mesa_s.transpose(Image.FLIP_LEFT_RIGHT), seg_x(0, 0.70), 124)
    bp.paste_grounded(im, mesa.transpose(Image.FLIP_LEFT_RIGHT), seg_x(1, 0.46), 126)
    bp.paste_grounded(im, mesa_s, seg_x(2, 0.12), 122)
    bp.paste_grounded(im, mesa, seg_x(2, 0.62), 128)
    fog(im, sky_bot, 118, 145)
    save(im, "mars", "layer_1.png")

    # 2: warships + half-buried Golden Age ruins
    im = gp.canvas()
    gp.ridge_ramped(im, 144, 5, [(5, 1.0), (11, 0.4)], (128, 84, 58, 255))
    warship = bp.haze(bp.load_scaled("mars_warship.png", 62), sky_bot, 0.26)
    warship_s = bp.haze(bp.load_scaled("mars_warship.png", 44), sky_bot, 0.34)
    bp.paste_grounded(im, warship, seg_x(0, 0.30), 154)
    for x0, top in [(seg_x(1, 0.20), 122), (seg_x(1, 0.60), 128)]:  # buried slabs
        gp.rect(im, x0, top, x0 + 34, H - 1, (108, 72, 50, 255))
        gp.rect(im, x0, top, x0 + 34, top + 1, (128, 88, 62, 255))
        gp.rect(im, x0 + 6, top + 8, x0 + 28, top + 9, (94, 62, 44, 255))
    for x in [seg_x(1, 0.85)]:
        gp.rect(im, x, 116, x + 3, H - 1, (104, 68, 48, 255))
        gp.px(im, x + 1, 114, (168, 120, 92, 160))
    bp.paste_grounded(im, warship_s, seg_x(2, 0.12), 152)
    bp.paste_grounded(im, warship.transpose(Image.FLIP_LEFT_RIGHT), seg_x(2, 0.62), 156)
    fog(im, sky_bot, 140, 100)
    save(im, "mars", "layer_2.png")

    # 3: near dunes + pod wreckage
    im = gp.canvas()
    gp.ridge_ramped(im, 161, 4, [(8, 1.0), (19, 0.4)], (96, 60, 42, 255), rough=1.2)
    for _ in range(12):
        x = random.randint(4, W - 10)
        gp.rect(im, x, 154, x + 5, 161, (78, 50, 36, 255))
        gp.px(im, x, 154, (104, 68, 48, 255))
    fog(im, sky_bot, 158, 60)
    save(im, "mars", "layer_3.png")

    # 4: sandbag lines / crashed pods / antennas
    im = gp.canvas()
    gp.ridge(im, 172, 3, [(8, 1.0), (18, 0.4)], (56, 36, 28, 255), rough=1.2)
    c, hl = (56, 36, 28, 255), (44, 28, 23, 255)
    for x in [40, 265, 420, 610, 780, 915]:
        for row, (n, y) in enumerate([(5, 168), (4, 164), (3, 160)]):
            for i in range(n):
                gp.rect(im, x + row * 2 + i * 7, y, x + row * 2 + i * 7 + 5, y + 3, c)
                gp.px(im, x + row * 2 + i * 7 + 2, y + 1, hl)
    for px_x in [210, 520, 850]:
        gp.rect(im, px_x, 158, px_x + 16, 171, c)
        for i in range(10):
            gp.rect(im, px_x + 16 + i, 158 + i, px_x + 17 + i, 171, c)
        gp.rect(im, px_x + 4, 150, px_x + 6, 158, c)
        gp.px(im, px_x + 5, 148, (255, 160, 60, 140))
    for ax in [105, 465, 700]:
        gp.rect(im, ax, 146, ax + 1, 171, c)
        for dy in (150, 156, 162):
            gp.rect(im, ax - 4, dy, ax + 5, dy, hl)
    save(im, "mars", "layer_4.png")

    im = gp.fg_canvas()
    c = (30, 18, 15, 235)
    gp.fg_rect(im, 0, gp.FG_H - 3, W - 1, gp.FG_H - 1, c)
    for _ in range(30):
        x = random.randint(4, W - 20)
        w_d = random.randint(9, 18)
        for i in range(w_d):
            h = int((1 - abs(i - w_d / 2) / (w_d / 2)) * random.randint(3, 5))
            gp.fg_rect(im, x + i, gp.FG_H - 3 - h, x + i, gp.FG_H - 3, c)
    for _ in range(21):
        x = random.randint(2, W - 4)
        h = random.randint(4, 8)
        for i in range(h):
            gp.fg_px(im, x + (i // 3), gp.FG_H - 3 - i, c)
    save(im, "mars", "fg_0.png")


if __name__ == "__main__":
    earth()
    cosmodrome()
    moon()
    mars()
    print("done")
